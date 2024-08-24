// ai.qc
//============================================================================
//   AI.QC
//
//      Modified by Karlos...
//
//      ai_run() now uses self.(old)enemy.deadflag to see if the enemy is
//   still alive or not. This change allows solid corpses to rest in peace ;)
//   Previously, a monster often continued attacking a dead advesary
//   because it was checking if self.enemy.health <= 0. Since corpses use
//   self.health to allow takedamage() and define their damage limit, an assailant
//   would think the enemy was still alive.
//      Added improved invisibility handling. Monsters remain unable to target
//   an invisible player, even if they know he is around...
//
//============================================================================
/*---public---*/
// $VER: ai.qc 2.21 � Karlos (10/02/2000)

// public function prototypes
float(float v) anglemod;
float(entity targ) range;
float(entity targ) infront;
float() FindTarget;
float() FacingIdeal;
float(entity targ) visible;
float() ai_test_jump;
void() movetarget_f;
void() path_corner;
void() t_movetarget;
void() HuntTarget;
void() FoundTarget;
void(float dist) ai_forward;
void(float dist) ai_back;
void(float dist) ai_pain;
void(float dist) ai_painforward;
void(float dist) ai_walk;
void() ai_stand;
void() ai_turn;
void(vector dest3) ChooseTurn;
void() ai_run_melee;
void() ai_run_missile;
void() ai_run_slide;
void(float dist) ai_run;

/*---private---*/

void() knight_walk1;
void() knight_bow6;
void() knight_bow1;

/*---------------------------------------------------------------------------
   .enemy
   Will be world if not currently angry at anyone.

   .movetarget
   The next path spot to walk toward.  If .enemy, ignore .movetarget.
   when an enemy is killed, the monster will try to return to it's path.

   .huntt_ime
   Set to time + something when the player is in sight, but movement straight for
   him is blocked.  This causes the monster to use wall following code for
   movement direction instead of sighting on the player.

   .ideal_yaw
   A yaw angle of the intended direction, which will be turned towards at up
   to 45 deg / state.  If the enemy is in view and hunt_time is not active,
   this will be the exact line towards the enemy.

   .pausetime
   A monster will leave it's stand state and head towards it's .movetarget when
   time > .pausetime.

   walkmove(angle, speed) primitive is all or nothing
----------------------------------------------------------------------------*/

// when a monster becomes angry at a player, that monster will be used
// as the sight target the next frame so that monsters near that one
// will wake up even if they wouldn't have noticed the player


float(float v) anglemod = {
    while (v >= 360) {
      v = v - 360;
    }
    while (v < 0) {
        v = v + 360;
    }
    return v;
};

/*==============================================================================
   MOVETARGET CODE

      The angle of the movetarget effects standing and bowing direction, but
      has no effect on movement, which allways heads to the next target.

      targetname
         must be present.  The name of this movetarget.

      target
         the next spot to move to.  If not present, stop here for good.

      pausetime
         The number of seconds to spend standing or bowing for path_stand
         or path_bow
==============================================================================*/

void() movetarget_f = {
    if (!self.targetname) {
        objerror("monster_movetarget: no targetname");
    }
    self.solid = SOLID_TRIGGER;
    self.touch = t_movetarget;
    setsize(self, '-8 -8 -8', '8 8 8');
};

/*QUAKED path_corner (0.5 0.3 0) (-8 -8 -8) (8 8 8)
Monsters will continue walking towards the next target corner.
*/
void() path_corner = { movetarget_f(); };


/*=================================================================================
   t_movetarget

      Something has bumped into a movetarget.  If it is a monster
      moving towards it, change the next destination and continue.
================================================================================*/
void() t_movetarget = {
    if (other.enemy) {
        return;     // fighting, not following a path
    }

    if (other.movetarget != self) {
        return;
    }

    local entity temp;
    temp  = self;
    self  = other;
    other = temp;

    if (self.classname == "monster_ogre") {
        sound(self, CHAN_VOICE, "ogre/ogdrag.wav", 1, ATTN_IDLE);// play chainsaw drag sound
    }

    self.goalentity = self.movetarget = find(world, targetname, other.target);
    self.ideal_yaw  = vectoyaw(self.goalentity.origin - self.origin);
    if (!self.movetarget) {
        self.pausetime = time + 999999;
        self.th_stand();
        return;
    }
};



//============================================================================

/*===============================================================================
   range

      returns the range catagorization of an entity reletive to self
      0  melee range, will become hostile even if back is turned
      1  visibility and infront, or visibility and show hostile
      2  infront and show hostile
      3  only triggered by damage
===============================================================================*/
float(entity targ) range = {
    local vector   spot1, spot2;
    local float    r;
    spot1 = self.origin + self.view_ofs;
    spot2 = targ.origin + targ.view_ofs;

    r = vlen(spot1 - spot2);
    if (r < 120) {
        return RANGE_MELEE;
    }
    if (r < 500) {
        return RANGE_NEAR;
    }
    if (r < 1600) {
        return RANGE_MID;
    }
    return RANGE_FAR;
};

/*===============================================================================
   visible
      returns 1 if the entity is visible to self, even if not infront ()
===============================================================================*/
float (entity targ) visible = {
    if (targ.items & IT_INVISIBILITY) {
        return FALSE;
    }

    local vector spot1, spot2;

    spot1 = self.origin + self.view_ofs;
    spot2 = targ.origin + targ.view_ofs;
    traceline(spot1, spot2, TRUE, self);  // see through other monsters

    if (trace_inopen && trace_inwater) {
        return FALSE;        // sight line crossed contents
    }

    if (trace_fraction == 1) {
        return TRUE;
    }

    return FALSE;
};


/*===============================================================================
   infront
      returns 1 if the entity is in front (in sight) of self
===============================================================================*/
float(entity targ) infront = {
    if (targ.items & IT_INVISIBILITY) {
        return FALSE;
    }

    makevectors(self.angles);

    local vector   vec;
    local float    dot;

    vec = normalize(targ.origin - self.origin);
    dot = vec * v_forward;

    if (dot > 0.3) {
        return TRUE;
    }
    return FALSE;
};

float() ai_test_jump = {
    // Checks that a jump will go forwards (ie not obstructed at feet)
    // Should help stop dogs/fiends getting stuck on corpses

    if (!(self.flags & FL_ONGROUND)) {
        return FALSE;
    }

    makevectors(self.angles);

    // make sure we don't trace outside the map

    traceline(self.origin, self.origin + v_forward * 32, TRUE, self);

    if (trace_fraction != 1.0) {
        return FALSE;
    }

    // check for small barriers at foot level that might stop a jump going
    // forwards
    local vector org;

    org = self.origin + v_forward * 32;

    traceline(org, org - '0 0 24', TRUE, self);

    if (trace_fraction != 1.0) {
        return FALSE;
    }
    return TRUE;
};

//============================================================================

void() HuntTarget = {
    self.goalentity = self.enemy;
    self.think      = self.th_run;
    self.ideal_yaw  = vectoyaw(self.enemy.origin - self.origin);
    self.nextthink  = time + 0.1;
    SUB_AttackFinished(1); // wait a while before first attack
};

void() FoundTarget = {
    if (self.enemy.classname == "player") {
        // let other monsters see this monster for a while
        sight_entity = self;
        sight_entity_time = time;
    }
    self.show_hostile = time + 1;    // wake up other monsters
    self.th_alerted();
    HuntTarget();
};

/*============================================================================
   FindTarget

   Self is currently not attacking anything, so try to find a target

   Returns TRUE if an enemy was sighted

   When a player fires a missile, the point of impact becomes a fakeplayer so
   that monsters that see the impact will respond as if they had seen the
   player.

   To avoid spending too much time, only a single client (or fakeclient) is
   checked each frame.  This means multi player games will have slightly
   slower noticing monsters.
=============================================================================*/
float() FindTarget = {
    local entity   client;
    local float    r;

    // if the first spawnflag bit is set, the monster will only wake up on
    // really seeing the player, not another monster getting angry

    // spawnflags & 3 is a big hack, because zombie crucified used the first
    // spawn flag prior to the ambush flag, and I forgot about it, so the second
    // spawn flag works as well
    if (sight_entity_time >= time - 0.1 && !(self.spawnflags & 3) ) {
        client = sight_entity;
        if (client.enemy == self.enemy) {
            return FALSE;
        }
    }
    else {
        client = checkclient();
        if (!client) {
            return FALSE;  // current check entity isn't in PVS
        }
    }

    if (client == self.enemy) {
        return FALSE;
    }

    if (client.flags & FL_NOTARGET) {
        return FALSE;
    }

    if (client.items & IT_INVISIBILITY) {
        return FALSE;
    }

    r = range(client);
    if (r == RANGE_FAR) {
        return FALSE;
    }

    if (!visible(client)) {
        return FALSE;
    }

    if (r == RANGE_NEAR) {
        if (client.show_hostile < time && !infront(client)) {
            return FALSE;
        }
    }
    else if (r == RANGE_MID) {
        if ( /* client.show_hostile < time || */ !infront(client)) {
            return FALSE;
        }
    }

    //
    // got one
    //
    self.enemy = client;
    if (self.enemy.classname != "player") {
        self.enemy = self.enemy.enemy;
        if (self.enemy.classname != "player") {
            self.enemy = world;
            return FALSE;
        }
    }
    FoundTarget();
    return TRUE;
};


//=============================================================================

void(float dist) ai_forward = {
    walkmove(self.angles_y, dist);
};

void(float dist) ai_back = {
    walkmove((self.angles_y + 180), dist);
};


/*=============================================================================
   ai_pain
      stagger back a bit
=============================================================================*/
void(float dist) ai_pain = {
    local float away;
    ai_back(dist);

    if (self.health < 15) {
        // panic...
        away = anglemod(vectoyaw (self.origin - self.enemy.origin) + 180*(random()- 0.5) );
        walkmove(away, dist * 2);
    }
};

/*=============================================================================
   ai_painforward
      stagger back a bit
=============================================================================*/
void(float dist) ai_painforward = {
    walkmove(self.ideal_yaw, dist);
};

/*=============================================================================
   ai_walk
      The monster is walking it's beat
=============================================================================*/
void(float dist) ai_walk =
{
    local vector      mtemp;

    movedist = dist;

    if (self.classname == "monster_dragon") {
        movetogoal(dist);
        return;
    }
    // check for noticing a player
    if (FindTarget()) {
        return;
    }
    movetogoal(dist);
};


/*==============================================================================
   ai_stand
      The monster is staying in one place for a while, with slight angle turns
==============================================================================*/
void() ai_stand = {
    if (FindTarget()) {
        return;
    }
    if (time > self.pausetime) {
        self.th_walk();
        return;
    }

    // TODO change angle slightly
};

/*=============================================================================
   ai_turn
      don't move, but turn towards ideal_yaw
=============================================================================*/
void() ai_turn = {
    if (FindTarget()) {
        return;
    }
    ChangeYaw();
};

//=============================================================================

/*=============================================================================
   ChooseTurn
=============================================================================*/
void(vector dest3) ChooseTurn = {
    local vector   dir, newdir;

    dir = self.origin - dest3;

    newdir_x = trace_plane_normal_y;
    newdir_y = 0 - trace_plane_normal_x;
    newdir_z = 0;

    if (dir * newdir > 0) {
        dir_x = 0 - trace_plane_normal_y;
        dir_y = trace_plane_normal_x;
    }
    else {
        dir_x = trace_plane_normal_y;
        dir_y = 0 - trace_plane_normal_x;
    }

    dir_z = 0;
    self.ideal_yaw = vectoyaw(dir);
};

/*=============================================================================
FacingIdeal
   Returns true if facing enemy head on
=============================================================================*/
float() FacingIdeal = {
    local float delta;

    delta = anglemod(self.angles_y - self.ideal_yaw);
    if (delta > 45 && delta < 315) {
        return FALSE;
    }
    return TRUE;
};


/*=============================================================================
   ai_run_melee
      Turn and close until within an angle to launch a melee attack
=============================================================================*/
void() ai_run_melee = {
    self.ideal_yaw = enemy_yaw;
    ChangeYaw();

    if (FacingIdeal()) {
        self.th_melee();
        self.attack_state = AS_STRAIGHT;
    }
};


/*============================================================================
   ai_run_missile
      Turn in place until within an angle to launch a missile attack
============================================================================*/
void() ai_run_missile = {
    self.ideal_yaw = enemy_yaw;
    ChangeYaw();
    if (FacingIdeal()) {
        self.th_missile();
        self.attack_state = AS_STRAIGHT;
    }
};


/*============================================================================
   ai_run_slide
      Strafe sideways, but stay at aproximately the same range
============================================================================*/
void() ai_run_slide = {
    local float ofs;

    self.ideal_yaw = enemy_yaw;
    ChangeYaw();
    if (self.lefty) {
        ofs = 90;
    }
    else {
        ofs = -90;
    }
    if (walkmove(self.ideal_yaw + ofs, movedist)) {
        return;
    }

    self.lefty = 1 - self.lefty;
    walkmove(self.ideal_yaw - ofs, movedist);
};


/*==========================================================================
   ai_run
      The monster has an enemy it is trying to kill
==========================================================================*/
void(float dist) ai_run = {
    local vector   delta;
    local float axis;
    local float direct, ang_rint, ang_floor, ang_ceil;

    movedist = dist;

    // see if the enemy is dead
    // if (self.enemy.health <= 0) // old code based on health

    if (self.enemy.deadflag != DEAD_NO) {
        self.enemy = world;

        // 1.06 FIXME: look all around for other targets

        // 1.8r4 - fixed : check for old enemy first, if that fails, look for
        // a new one based on team data. If that fails then drop down to default
        // state


        // if (self.oldenemy.health > 0) // old code based on health

        if (
            self.oldenemy.deadflag == DEAD_NO &&
            is_visible(self.oldenemy, self)
        ) {
            // Is old enemy still alive and in visible range ?
            self.enemy = self.oldenemy;
            HuntTarget();
        }
        else {
            // Couldn't see old enemy so look for a new one
            self.enemy = ai_pick_new_target(self, 500);

            // self.enemy = world;

            if (self.enemy != world) {
                // self.enemy will only be world if no target could be seen, so if
                // is different, hunt the new self.enemy...
                HuntTarget();
            }
            else {
                // no new target could be found so we
                // drop to the base behaviour state, favouring prowling over
                // standing

                if (self.movetarget) {
                    self.th_walk();
                }
                else {
                    if (random() > 0.5) {
                        self.th_stand();
                    }
                    else {
                        self.th_walk();
                    }
                }
                return;
            }
        }
    }

    self.show_hostile = time + 1;    // wake up other monsters

    // check knowledge of enemy
    enemy_vis = visible(self.enemy);
    if (enemy_vis) {
        self.search_time = time + 5;
    }

    // look for other coop players
    if (coop && self.search_time < time) {
        if (FindTarget()) {
            return;
        }
    }

    enemy_infront = infront(self.enemy);
    enemy_range   = range(self.enemy);
    enemy_yaw     = vectoyaw(self.enemy.origin - self.origin);

    if (self.attack_state == AS_MISSILE) {
        //dprint ("ai_run_missile\n");
        ai_run_missile();
        return;
    }

    if (self.attack_state == AS_MELEE) {
        //dprint ("ai_run_melee\n");
        ai_run_melee();
        return;
    }

    if (enemy_vis && self.check_attack()) {
        return; // beginning an attack
    }

    if (self.attack_state == AS_SLIDING) {
        ai_run_slide();
        return;
    }

    // head straight in
    movetogoal(dist);      // done in C code...
};
