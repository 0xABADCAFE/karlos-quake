// enforcer.qc
/*---public---*/
// $VER: enforcer.qc 2.12 � Karlos '99 (15/11/1999), original 1.06 by id software

void() Laser_Touch;
void(vector org, vector vec) LaunchLaser;
void() monster_enforcer;
/*---private---*/

void() enf_ion1;
void() enf_atk1;

/*=========================================================================================

   ENFORCER (human)

   Size                : man
   Movetype(s) / Speed : walk, run / slow
   Attackmodes         : projectile, beam
   Attackvectors       : laserbolt, ion cannon
   Hit points          : 80, 40

   Specifics..
      Uses new ai_predict_aim() ai for speculative targeting based on opponents velocity
      and position.
      Projectile speed sensitive to skill setting
      Footstep handling
      Random and context sensitive radio fx

=========================================================================================*/

$cd id1/models/enforcer
$origin 0 -6 24
$base base
$skin skin

$frame stand1 stand2 stand3 stand4 stand5 stand6 stand7
$frame walk1 walk2 walk3 walk4 walk5 walk6 walk7 walk8 walk9 walk10
$frame walk11 walk12 walk13 walk14 walk15 walk16
$frame run1 run2 run3 run4 run5 run6 run7 run8
$frame attack1 attack2 attack3 attack4 attack5 attack6
$frame attack7 attack8 attack9 attack10
$frame death1 death2 death3 death4 death5 death6 death7 death8
$frame death9 death10 death11 death12 death13 death14
$frame fdeath1 fdeath2 fdeath3 fdeath4 fdeath5 fdeath6 fdeath7 fdeath8
$frame fdeath9 fdeath10 fdeath11
$frame paina1 paina2 paina3 paina4
$frame painb1 painb2 painb3 painb4 painb5
$frame painc1 painc2 painc3 painc4 painc5 painc6 painc7 painc8
$frame paind1 paind2 paind3 paind4 paind5 paind6 paind7 paind8
$frame paind9 paind10 paind11 paind12 paind13 paind14 paind15 paind16
$frame paind17 paind18 paind19

/*==============================================================================
   CODE : PROJECTILE
==============================================================================*/

void() Laser_Touch = {
    local vector org;

    if (other == self.owner) {
        return;     // don't explode on owner
    }

    if (pointcontents(self.origin) == CONTENT_SKY) {
        remove(self);
        return;
    }

    sound(self, CHAN_WEAPON, "enforcer/enfstop.wav", 1, ATTN_STATIC);
    org = self.origin - 8*normalize(self.velocity);

    if (other.health) {
        SpawnBlood(org, self.velocity*0.2, 10);
        T_Damage(other, self, self.owner, 8 * (1 + random()) );
    }
    else {
        WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
        WriteByte(MSG_BROADCAST, TE_GUNSHOT);
        WriteCoord(MSG_BROADCAST, org_x);
        WriteCoord(MSG_BROADCAST, org_y);
        WriteCoord(MSG_BROADCAST, org_z);
    }
    remove(self);
};


/*==============================================================================
   CODE : PROJECTILE LAUNCH
==============================================================================*/

void(vector org, vector tovec) LaunchLaser = {
    local vector vec;

    if (self.classname == "monster_enforcer") {
        sound(self, CHAN_WEAPON, "enforcer/enfire.wav", 1, ATTN_NORM);
    }

    vec = normalize(tovec);

    newmis          = spawn();
    newmis.owner    = self;
    newmis.movetype = MOVETYPE_FLY;
    newmis.solid    = SOLID_BBOX;
    newmis.effects  = (FX_GLOW & effectflags);

    setmodel(newmis, "progs/laser.mdl");
    setsize(newmis, VEC_ZERO, VEC_ZERO);
    setorigin(newmis, org);

    newmis.velocity  = vec * (700 + skill * 200);
    newmis.angles    = vectoangles(newmis.velocity);
    newmis.nextthink = time + 5;
    newmis.think     = SUB_Remove;
    newmis.touch     = Laser_Touch;
};

/*---private---*/

/*==============================================================================
   CODE : ATTACKING
==============================================================================*/
void() enf_run2;

void() targ_too_far = {
    if (random() < 0.6) {
        self.think     = enf_run2;
        self.nextthink = time + 0.1;
    }
    else {
        self.think     = enf_ion1;
        self.nextthink = time + 0.25;
    }
};

void() enf_shoot_ahead = {
   local vector org;

   self.effects = self.effects | (FX_FLASH & effectflags);
   makevectors(self.angles);
   org = self.origin + v_forward * 30 + v_right * 8.5 + '0 0 16';
   LaunchLaser(org, self.futuretarget - self.origin);
   self.think     = self.nextaction;
   self.nextthink = time + 0.01;
};

//===================================================================================
//
// PRIMARY ATTACK MODE : laserbolt
//
//===================================================================================
void() enf_fire_laser = {
    local float tmp;

    tmp = vlen(self.origin - self.enemy.origin);

    // use ai_predict_aim(), basing intercept time on distance
    // if closeish, use intercept of 0.5 time units
    // else use intercept of about 0.75 units

    if (tmp < 2000) {
        tmp = 0.5;
    }
    else {
        tmp = 0.75;
    }
    self.futuretarget = ai_predict_aim(self.enemy, 700 + skill * 200, tmp, enf_shoot_ahead, targ_too_far);

};

//====================================================================================
//
// SECONDARY ATTACK MODE : ion
//
//====================================================================================
void() enf_fire_ion = {
    local vector org, dir;
    makevectors(self.angles);
    org = self.origin + v_forward * 30 + v_right * 8.5 + '0 0 16';
    dir = self.enemy.origin - self.enemy.velocity*0.2;
    dir = normalize (dir - self.origin);
    ion_stream(100 + 75 * random(), org, dir, self);
};

//====================================================================================
//
// CHOOSE ATTACK
//
//====================================================================================
float(entity what) high_hazard = {
    // decide if enemy deserves ion cannon automatically
    if (
        what.classname == "monster_zombie"   ||
        what.classname == "monster_demon1"   ||
        what.classname == "monster_shambler" ||
        what.classname == "monster_tarbaby"  ||
        what.classname == "monster_hell_knight" ||
        what.classname == "monster_shalrath"
    ) {
        return TRUE;
    }
    else {
        return FALSE;
    }
};

void() enf_attack = {
    local float dist, enemy_speed;

    // use ion cannon occasionally, especially with difficult enemies
    dist        = vlen(self.origin - self.enemy.origin);
    enemy_speed = vlen(self.enemy.velocity);

    if (
        (enemy_speed < 200 && dist > 1500) ||
        high_hazard(self.enemy) ||
        random() < 0.2
    ) {
        self.think = enf_ion1;
    }
    else {
        self.think = enf_atk1;
    }
    self.nextthink = time + 0.01;
};

/*==============================================================================
   BEHAVIOUR: STANDING / IDLE
==============================================================================*/

void() enf_stand1 = [ $stand1, enf_stand2 ] {
    // a bit of radio...
    if (random() < 0.1) {
        if (random() < 0.6) {
            radio_message(self, 0);
        }
        else {
            radio_message(self, SAY_DESTROY_GREEN);
        }
    }
    ai_stand();
};

void() enf_stand2 = [ $stand2, enf_stand3 ] { ai_stand(); };
void() enf_stand3 = [ $stand3, enf_stand4 ] { ai_stand(); };
void() enf_stand4 = [ $stand4, enf_stand5 ] { ai_stand(); };
void() enf_stand5 = [ $stand5, enf_stand6 ] { ai_stand(); };
void() enf_stand6 = [ $stand6, enf_stand7 ] { ai_stand(); };
void() enf_stand7 = [ $stand7, enf_stand1 ] { ai_stand(); };

/*==============================================================================
   BEHAVIOUR:PROWLING / IDLE
==============================================================================*/

void() enf_walk1 = [ $walk1 , enf_walk2 ] {
    if (random() < 0.2) {
        sound(self, CHAN_VOICE, "enforcer/idle1.wav", 1, ATTN_IDLE);
    }
    // a bit of radio...
    if (random() < 0.1) {
        radio_message(self, 0);
    }
    ai_walk(2);
};

void() enf_walk2 = [ $walk2, enf_walk3 ] { ai_walk(4); };
void() enf_walk3 = [ $walk3, enf_walk4 ] { ai_walk(4); };
void() enf_walk4 = [ $walk4, enf_walk5 ] { ai_walk(3); };
void() enf_walk5 = [ $walk5, enf_walk6 ] { ai_walk(1); };
void() enf_walk6 = [ $walk6, enf_walk7 ] { ai_walk(2); };
void() enf_walk7 = [ $walk7, enf_walk8 ] {
    // play footstepsound
    if (pointcontents(self.origin) == CONTENT_EMPTY) {
        footfall_normal(0.6, ATTN_STATIC);
    }
    ai_walk(2);
};
void() enf_walk8  = [ $walk8, enf_walk9   ] { ai_walk(1); };
void() enf_walk9  = [ $walk9, enf_walk10  ] { ai_walk(2); };
void() enf_walk10 = [ $walk10, enf_walk11 ] { ai_walk(4); };
void() enf_walk11 = [ $walk11, enf_walk12 ] { ai_walk(4); };
void() enf_walk12 = [ $walk12, enf_walk13 ] { ai_walk(1); };
void() enf_walk13 = [ $walk13, enf_walk14 ] { ai_walk(2); };
void() enf_walk14 = [ $walk14, enf_walk15 ] { ai_walk(3); };
void() enf_walk15 = [ $walk15, enf_walk16 ] { ai_walk(4); };
void() enf_walk16 = [ $walk16, enf_walk1  ] {
    // play footstepsound
    if (pointcontents(self.origin) == CONTENT_EMPTY) {
        footfall_normal (0.6, ATTN_STATIC);
    }
    ai_walk(2);
};

void() enf_run1 = [ $run1  , enf_run2 ] {
    local float r;

    if (random() < 0.2) {
        r = random();
        if (r < 0.6) {
            sound(self, CHAN_VOICE, "enforcer/idle1.wav", 1, ATTN_IDLE);
        }
        else if (r < 0.8) {
            radio_message(self, SAY_DESTROY_GREEN);
        }
        else {
            radio_message(self, SAY_ROGER);
        }
    }
    ai_run(18);
};


/*==============================================================================
   BEHAVIOUR: ALERTED
==============================================================================*/

void() enf_run2 = [ $run2, enf_run3 ] {
    if (random() < 0.1) {
        radio_message(self, SAY_ENEMY_SIGHTED);
    }
    ai_run(14);
};

void() enf_run3 = [ $run3, enf_run4 ] { ai_run(7); };
void() enf_run4 = [ $run4, enf_run5 ] { ai_run(12); };
void() enf_run5 = [ $run5, enf_run6 ] {
    // play footstepsound
    if (pointcontents(self.origin) == CONTENT_EMPTY) {
        footfall_normal(0.8, ATTN_IDLE);
    }
    ai_run(14);
};

void() enf_run6 = [ $run6, enf_run7 ] { ai_run(14); };
void() enf_run7 = [ $run7, enf_run8 ] { ai_run(7); };
void() enf_run8 = [ $run8, enf_run1 ] {
    // play footstepsound
    if (pointcontents(self.origin) == CONTENT_EMPTY) {
        footfall_normal (0.9, ATTN_IDLE);
    }
    ai_run(11);
};


/*==============================================================================
   BEHAVIOUR: ATTACKING
==============================================================================*/

void() enf_atk1  = [ $attack1, enf_atk2  ] { ai_face(); };
void() enf_atk2  = [ $attack2, enf_atk3  ] { ai_face(); };
void() enf_atk3  = [ $attack3, enf_atk4  ] { ai_face(); };
void() enf_atk4  = [ $attack4, enf_atk5  ] { ai_face(); };
void() enf_atk5  = [ $attack5, enf_atk6  ] {
    self.nextaction = enf_atk6;
    enf_fire_laser();
};

void() enf_atk6  = [ $attack6, enf_atk7  ] { ai_face(); };
void() enf_atk7  = [ $attack7, enf_atk8  ] { ai_face(); };
void() enf_atk8  = [ $attack8, enf_atk9  ] { ai_face(); };
void() enf_atk9  = [ $attack5, enf_atk10 ] { ai_face(); };
void() enf_atk10 = [ $attack6, enf_atk11 ] {
    self.nextaction = enf_atk11;
    enf_fire_laser();
};

void() enf_atk11 = [ $attack7, enf_atk12 ] { ai_face(); };
void() enf_atk12 = [ $attack8, enf_atk13 ] { ai_face(); };
void() enf_atk13 = [ $attack9, enf_atk14 ] { ai_face(); };
void() enf_atk14 = [ $attack10, enf_run1 ] {
    ai_face();
    SUB_CheckRefire(enf_atk1);
};

void() enf_ion1  = [ $attack1,  enf_ion2  ] { ai_face(); };
void() enf_ion2  = [ $attack2,  enf_ion3  ] { ai_face(); };
void() enf_ion3  = [ $attack3,  enf_ion4  ] { ai_face(); };
void() enf_ion4  = [ $attack4,  enf_ion5  ] { ai_face(); };
void() enf_ion5  = [ $attack5,  enf_ion6  ] {
    ai_face();
    enf_fire_ion(); // Have it!
};

void() enf_ion6  = [ $attack6,  enf_ion7  ] { ai_face(); };
void() enf_ion7  = [ $attack7,  enf_ion8  ] { ai_face(); };
void() enf_ion8  = [ $attack8,  enf_ion9  ] { ai_face(); };
void() enf_ion9  = [ $attack9,  enf_ion10 ] { ai_face(); };
void() enf_ion10 = [ $attack10, enf_run1  ] {
    ai_face();
    SUB_CheckRefire(enf_attack);
};


/*==============================================================================
   BEHAVIOUR: PAIN FLINCHES
==============================================================================*/

void() enf_paina1 = [ $paina1, enf_paina2 ] { };
void() enf_paina2 = [ $paina2, enf_paina3 ] { };
void() enf_paina3 = [ $paina3, enf_paina4 ] { };
void() enf_paina4 = [ $paina4, enf_run1   ] { };

void() enf_painb1 = [ $painb1, enf_painb2 ] { };
void() enf_painb2 = [ $painb2, enf_painb3 ] { };
void() enf_painb3 = [ $painb3, enf_painb4 ] { };
void() enf_painb4 = [ $painb4, enf_painb5 ] { };
void() enf_painb5 = [ $painb5, enf_run1   ] { };

void() enf_painc1 = [ $painc1, enf_painc2 ] { };
void() enf_painc2 = [ $painc2, enf_painc3 ] { };
void() enf_painc3 = [ $painc3, enf_painc4 ] { };
void() enf_painc4 = [ $painc4, enf_painc5 ] { };
void() enf_painc5 = [ $painc5, enf_painc6 ] { };
void() enf_painc6 = [ $painc6, enf_painc7 ] { };
void() enf_painc7 = [ $painc7, enf_painc8 ] { };
void() enf_painc8 = [ $painc8, enf_run1   ] { };

void() enf_paind1  = [ $paind1,  enf_paind2  ] { };
void() enf_paind2  = [ $paind2,  enf_paind3  ] { };
void() enf_paind3  = [ $paind3,  enf_paind4  ] { };
void() enf_paind4  = [ $paind4,  enf_paind5  ] { ai_painforward(2); };
void() enf_paind5  = [ $paind5,  enf_paind6  ] { ai_painforward(1); };
void() enf_paind6  = [ $paind6,  enf_paind7  ] { };
void() enf_paind7  = [ $paind7,  enf_paind8  ] { };
void() enf_paind8  = [ $paind8,  enf_paind9  ] { };
void() enf_paind9  = [ $paind9,  enf_paind10 ] { };
void() enf_paind10 = [ $paind10, enf_paind11 ] { };
void() enf_paind11 = [ $paind11, enf_paind12 ] { ai_painforward(1); };
void() enf_paind12 = [ $paind12, enf_paind13 ] { ai_painforward(1); };
void() enf_paind13 = [ $paind13, enf_paind14 ] { ai_painforward(1); };
void() enf_paind14 = [ $paind14, enf_paind15 ] { };
void() enf_paind15 = [ $paind15, enf_paind16 ] { };
void() enf_paind16 = [ $paind16, enf_paind17 ] { ai_pain(1); };
void() enf_paind17 = [ $paind17, enf_paind18 ] { ai_pain(1); };
void() enf_paind18 = [ $paind18, enf_paind19 ] { };
void() enf_paind19 = [ $paind19, enf_run1    ] { };

/*==============================================================================
   CODE : PAIN FLINCHES
==============================================================================*/

void(entity attacker, float damage) enf_pain = {
    if (self.pain_finished > time) {
        return;
    }

    local float r;

    r = random();

    if (r < 0.5) {
        self.noise = "enforcer/pain1.wav";
    }
    else {
        self.noise = "enforcer/pain2.wav";
    }

    sound(self, CHAN_VOICE, self.noise, 1, ATTN_NORM);

    if (r < 0.2) {
        self.pain_finished = time + 1;
        enf_paina1();
    }
    else if (r < 0.4) {
        self.pain_finished = time + 1;
        enf_painb1();
    }
    else if (r < 0.7) {
        self.pain_finished = time + 1;
        enf_painc1();
    }
    else {
        self.pain_finished = time + 2;
        enf_paind1();
    }
};


/*==============================================================================
   BEHAVIOUR: DYING
==============================================================================*/

void() enf_die1  = [ $death1,  enf_die2  ] { };
void() enf_die2  = [ $death2,  enf_die3  ] { };
void() enf_die3  = [ $death3,  enf_die4  ] { DropBackpack(); };
void() enf_die4  = [ $death4,  enf_die5  ] { ai_forward(14); };
void() enf_die5  = [ $death5,  enf_die6  ] { ai_forward(2); };
void() enf_die6  = [ $death6,  enf_die7  ] { };
void() enf_die7  = [ $death7,  enf_die8  ] { };
void() enf_die8  = [ $death8,  enf_die9  ] { };
void() enf_die9  = [ $death9,  enf_die10 ] { ai_forward(3); };
void() enf_die10 = [ $death10, enf_die11 ] { ai_forward(5); };
void() enf_die11 = [ $death11, enf_die12 ] { ai_forward(5); };
void() enf_die12 = [ $death12, enf_die13 ] { ai_forward(5); };
void() enf_die13 = [ $death13, enf_die14 ] { };
void() enf_die14 = [ $death14, enf_die14 ] { corpse("progs/h_mega.mdl", 10 + random() * 3, 80); };

void() enf_fdie1  = [ $fdeath1,  enf_fdie2  ] { };
void() enf_fdie2  = [ $fdeath2,  enf_fdie3  ] { };
void() enf_fdie3  = [ $fdeath3,  enf_fdie4  ] { DropBackpack(); };
void() enf_fdie4  = [ $fdeath4,  enf_fdie5  ] { };
void() enf_fdie5  = [ $fdeath5,  enf_fdie6  ] { };
void() enf_fdie6  = [ $fdeath6,  enf_fdie7  ] { };
void() enf_fdie7  = [ $fdeath7,  enf_fdie8  ] { };
void() enf_fdie8  = [ $fdeath8,  enf_fdie9  ] { };
void() enf_fdie9  = [ $fdeath9,  enf_fdie10 ] { };
void() enf_fdie10 = [ $fdeath10, enf_fdie11 ] { };
void() enf_fdie11 = [ $fdeath11, enf_fdie11 ] { corpse("progs/h_mega.mdl", 10 + random() * 3, 80); };

/*==============================================================================
   CODE: DYING
==============================================================================*/

void() enf_die = {
    // check for gib
    if (self.health < -35 && effectflags & FX_GORE_GIBS) {
        sound(self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NORM);
        giblet("progs/h_mega.mdl", self.health);
        return;
    }

    sound(self, CHAN_VOICE, "enforcer/death1.wav", 1, ATTN_NORM);

    self.ammo_cells = 2 + rint(random() * 8);   // drop random ammo
    setsize(self, '-12 -12 -24', '12 12 0');    // not so big when dead...

    if (random() < 0.05) {
        inv_drop_item(IT_LIGHTNING);
    }
    if (random() > 0.5) {
        enf_die1();
    }
    else {
        enf_fdie1();
    }
};

void() enf_alerted = {
    local float rsnd;
    local string my_noise;
    rsnd = rint(random() * 3);
    if (rsnd == 1) {
        my_noise = "enforcer/sight1.wav";
    }
    else if (rsnd == 2) {
        my_noise = "enforcer/sight2.wav";
    }
    else if (rsnd == 0) {
        my_noise = "enforcer/sight3.wav";
    }
    else {
        my_noise = "enforcer/sight4.wav";
    }
    sound(self, CHAN_VOICE, my_noise, 1, ATTN_NORM);
};

/*---endprivate---*/

void() monster_enforcer = {
    if (deathmatch) {
        remove(self);
        return;
    }

    if (randomgame && !self.switched) {
        swap_monster();
        return;
    }

    if (!enforcer_cached) {
        enforcer_cached = TRUE;
        monstertypes    = monstertypes + 1;
        precache_model2("progs/enforcer.mdl");
        precache_model2("progs/h_mega.mdl");
        precache_model2("progs/laser.mdl");
        precache_sound("soldier/radio1.wav");
        precache_sound("soldier/radio2.wav");
        precache_sound("soldier/radio3.wav");
        precache_sound("soldier/radio4.wav");
        precache_sound("soldier/radio5.wav");
        precache_sound("soldier/radio_sight.wav");     // player sighted
        precache_sound("soldier/radio_attack.wav");    // attack instructions
        precache_sound("soldier/radio_ackn.wav");      // instructions acknowledged
        precache_sound("soldier/radio_enemydown.wav"); // player dead
        precache_sound2("enforcer/death1.wav");
        precache_sound2("enforcer/enfire.wav");
        precache_sound2("enforcer/enfstop.wav");
        precache_sound2("enforcer/idle1.wav");
        precache_sound2("enforcer/pain1.wav");
        precache_sound2("enforcer/pain2.wav");
        precache_sound2("enforcer/sight1.wav");
        precache_sound2("enforcer/sight2.wav");
        precache_sound2("enforcer/sight3.wav");
        precache_sound2("enforcer/sight4.wav");
    }

    self.th_alerted = enf_alerted;

    monster_init("progs/enforcer.mdl", '-16 -16 -24', '16 16 40', 80, 40);
    self.netname     = "an Enforcer";
    self.th_stand    = enf_stand1;
    self.th_walk     = enf_walk1;
    self.th_run      = enf_run1;
    self.th_pain     = enf_pain;
    self.th_die      = enf_die;
    self.th_missile  = enf_attack;
    self.ion_colour  = 512 * rint (random()*7);
    self.think       = monster_walk;
    self.cell_charge = 20;

    ai_team_join(TEAM_ARMY_1, TRUE); // can be a team leader
};
