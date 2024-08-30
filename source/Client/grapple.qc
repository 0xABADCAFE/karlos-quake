// grapple.qc

/*---public---*/
// $VER: grapple.qc 1.12 Karlos (08/10/1999) based on code by Perceli Manole

// public functions provided
// highlevel
void() inv_grapple_fire;      // launches hook
void() inv_grapple_release;   // releases hook
void() inv_grapple_retract;   // begin winching up
void() inv_grapple_extend;    // allow to drop
void() inv_grapple_lock;      // locks chain at current length
void(vector shot_dir, float shot_impulse) grapple_weapon_kick; // weaponkick effect
// public structure extensions
.float grapple;             // grappling hook flags
/*---private---*/
// functions
void (entity thing, float lifetime) allow_to_fall;

// grappling hook constants
float FL_GRAPPLE_ACTIVE     = 1;     // set if hook command is active
float FL_GRAPPLE_ATTATCHED  = 2;     // set if hook has attached
float FL_GRAPPLE_SHORTENING = 4;     // set if shrink chain is active
float FL_GRAPPLE_EXTENDING  = 8;     // set if grow chain is active
float MIN_CHAIN_LEN         = 40;    // minimum chain length
float MAX_CHAIN_LEN         = 1500;  // maximum chain length
float CHAIN_LINK_LEN        = 55;    // length between chain link origins
float GROW_RATE             = 15;    // maximum chain extend rate
float SHRINK_RATE           = -30;   // maximum chain shorten rate

float INV_CHAIN_LINK_LEN    = 0.0181818; // 1/CHAIN_LINK_LEN
float INV_GROW_RATE         = 0.0666667; // 1/GROW_RATE
float INV_INIT_VEL_SCALE    = 0.0454545;

// structure extensions
.float winch_celltime;               // used for winch motor cell draining

//--------------------------------------------------------------------
// Removes hook and detaches player
//--------------------------------------------------------------------
void () release_grapple = {
    local entity linkptr, nextptr;

    // if winching, do motor stop sound
    if (self.owner.grapple & FL_GRAPPLE_SHORTENING) {
        sound(self.owner, CHAN_AUX2, "weapons/winch_stop.wav", 1, ATTN_IDLE);
    }

    // remove all hook flags
    self.owner.grapple = 0;
    sound(self.owner, CHAN_WEAPON, "weapons/grapple_reset.wav", 1, ATTN_NORM);

    // removes hook and chain
    linkptr = self.goalentity;
    while (linkptr != world) {
        nextptr = linkptr.goalentity;
        allow_to_fall(linkptr, 1);
        linkptr = nextptr;
    }

    // allow hook head to fall
    allow_to_fall(self, 1.5);
};

void (entity thing, float lifetime) allow_to_fall = {
    thing.movetype  = MOVETYPE_BOUNCE;
    thing.touch     = SUB_Null;
    thing.think     = SUB_Remove;
    thing.nextthink = time + lifetime;
};


//--------------------------------------------------------------------
// Spawn and removes and refreshes chain links
//--------------------------------------------------------------------
void () handle_chainlinks = {
    local vector
        chainvec,        // vector of the chain
        p_self_origin,   // predicted future hook origin
        chainunit,       // vector of chain with distance of 1
        targetpos;       // position to reach

    local entity
        newlink,         // pointer to chain link being added
        currlink,        // pointer to current link being traversed
        nextlink;        // pointer to next link after current link

    local float
        chainlen,         // length of chain
        currpos,          // numeric position of currlink
        linknum,          // number of links that should exist
        linkstart;        // length from hook at which currlink starts

    // predicts hook's future position since chain links fall behind
    currpos       = vlen(self.velocity) * INV_INIT_VEL_SCALE;   // currpos used here just as an intermediate value
    p_self_origin = self.origin + normalize(self.velocity) * currpos;

    // get info about chain

    // Put 8 units back for appearances in camera view
    if ( (self.dest2_x & FL_USING_CAMERA) ) {
        makevectors(self.owner.v_angle);
        chainvec = (((self.owner.origin + '0 0 16') - v_forward * 8) - p_self_origin);
    }
    else {
        chainvec = ((self.owner.origin + '0 0 16') - p_self_origin);
    }

    chainunit = normalize(chainvec);
    chainvec  = chainvec - chainunit * 18;
    chainlen  = vlen(chainvec);

    currlink = self;
    currpos  = 0;

    // generate and refresh links
    linknum = ceil(chainlen * INV_CHAIN_LINK_LEN);
    while (currpos < linknum) {
        // add entities if chain's length grows
        if (currlink.goalentity == world) {
            newlink             = spawn();
            newlink.movetype    = MOVETYPE_NOCLIP;
            newlink.solid       = SOLID_NOT;
            setmodel(newlink, "progs/chainlink.mdl");
            setsize(newlink, VEC_ZERO, VEC_ZERO);
            newlink.goalentity  = world;
            currlink.goalentity = newlink;
        }

        currlink = currlink.goalentity;
        currpos  = currpos + 1;

        // set angles
        currlink.angles = vectoangles(chainvec);

        // fixes vectoangles round off error
        if (
            (currlink.angles_y > 0) &&
            (currlink.angles_y < 180)
        ) {
            currlink.angles = currlink.angles + '0 1 0';
        }
        // vibrates chain links on the z axis
        currlink.angles_z = currlink.angles_z + crandom() * 30;

        // set position and frames
        linkstart = (currpos - 1) * CHAIN_LINK_LEN;
        if (currpos < linknum) {
            //setorigin (currlink, p_self_origin + chainunit * (linkstart + CHAIN_LINK_LEN / 2 ));
            targetpos = p_self_origin + chainunit * (linkstart + CHAIN_LINK_LEN * 0.5 );
            //currlink.frame = 9;
        }
        else {
            //setorigin (currlink, p_self_origin + chainunit * (linkstart + (chainlen - linkstart) / 2 ));
            targetpos = p_self_origin + chainunit * (linkstart + (chainlen - linkstart) * 0.5 );
            //currlink.frame = floor((chainlen - linkstart) / CHAIN_LINK_LEN * 10);
        }

        if (vlen(targetpos - currlink.origin) < 200) {
            currlink.velocity = 10 * (targetpos - currlink.origin);
        }
        else {
            currlink.velocity = VEC_ZERO;
            setorigin(currlink, targetpos);
        }
    }

    // remove remaining entities if chain's length shrinks
    nextlink = currlink.goalentity;
    currlink.goalentity = world;
    currlink = nextlink;
    while (currlink != world) {
        nextlink = currlink.goalentity;
        remove(currlink);
        currlink = nextlink;
    }
};


//--------------------------------------------------------------------
// Hook behavior function
//--------------------------------------------------------------------
void () grapple_action = {
    local vector spray;        // for blood
    local vector chainvec;     // chain vector
    local vector velpart;      // player's velocity component moving to or away from hook
    local float chainlen;      // length of extended chain

    local vector swingangle;   // try to rotate player angles to match chainvec;

    //local float framestep;   // grow or shrink step per frame
    local float restrain_force1, restrain_force2;        // restrainment forces
    local float i1, i2;        // intermediate values

    local float growthstep;    // variable growth/shrink step, used to simulate acceleration

    self.nextthink = time + 0.1;

    // decide when to disconnect hook
    if (
        !(self.owner.grapple & FL_GRAPPLE_ACTIVE) ||
        self.owner.teleport_time > time ||
        self.owner.deadflag != DEAD_NO ||
        self.enemy.solid == SOLID_NOT
    ) {
        release_grapple();
        return;
    }

    // give some damage to entities that take damage
    if (self.enemy.takedamage) {
        if (time > self.wait) {
            self.enemy.deathtype = "grapple";
            T_Damage(self.enemy, self, self.owner, 5);

            // when hook hits live entity add blood and sounds
            if (self.enemy.solid == SOLID_SLIDEBOX) {
                // .ammo_nails flag used only here
                if (! self.ammo_nails) {
                    sound(self, CHAN_AUTO, "shambler/smack.wav", 1, ATTN_NORM);
                    self.ammo_nails = TRUE;
                }
                else {
                    sound(self, CHAN_AUTO, "blob/land1.wav", 0.8, ATTN_NORM);
                }
                spray_x = 100 * crandom();
                spray_y = 100 * crandom();
                spray_z = 100 * crandom() + 50;
                SpawnBlood(self.origin, spray, 20);
                setorigin (self, self.enemy.origin + self.enemy.mins + self.enemy.size * 0.5);
            }

            self.wait = time + 0.3;
        }
    }

    self.velocity = self.enemy.velocity;
    chainvec      = self.origin - (self.owner.origin + '0 0 16');
    chainlen      = vlen (chainvec);

    // .ammo_shells = +- amount to size
    growthstep = self.ammo_shells;

    if (self.owner.grapple & FL_GRAPPLE_EXTENDING) {
        growthstep = growthstep + 2;
        if (growthstep > GROW_RATE) {
            growthstep = GROW_RATE;
        }
    }
    else if (self.owner.grapple & FL_GRAPPLE_SHORTENING) {
        growthstep = growthstep - 4;
        if (growthstep < SHRINK_RATE) {
            growthstep = SHRINK_RATE;
        }
    }
    else {
        if (growthstep > 0) {
            growthstep = growthstep - 2; // fade from grow
            if (growthstep < 0) {
                growthstep = 0;
            }
        }
        if (growthstep < 0) {
            growthstep = growthstep + 4; // fade from shrink
            if (growthstep > 0) {
                growthstep = 0;
            }
        }
    }
    self.armorvalue = self.armorvalue + growthstep;

    if (growthstep > 0) {
        if ( (self.owner.flags & FL_ONGROUND) ) {
            self.armorvalue = chainlen;
        }
        else {
            if (self.delay < time) {
                restrain_force1 = growthstep * INV_GROW_RATE;
                self.delay = time + 0.2;
            }
        }

        if ( self.armorvalue > MAX_CHAIN_LEN ) {
            self.armorvalue = MAX_CHAIN_LEN;
        }
    }

    if (growthstep < 0) {
        // fixes not raising when directly under the hook
        if ( (self.owner.flags & FL_ONGROUND) ) {
            self.owner.flags = self.owner.flags - FL_ONGROUND;
        }

        if (self.armorvalue < MIN_CHAIN_LEN) {
            // shortest chainlenth reached. Switch off winch.
            self.armorvalue = MIN_CHAIN_LEN;
            if (self.owner.grapple & FL_GRAPPLE_SHORTENING) {
                sound(self.owner, CHAN_AUX2, "weapons/winch_stop.wav", 1, ATTN_IDLE);
                self.owner.grapple = self.owner.grapple - FL_GRAPPLE_SHORTENING;
            }
        }
        else {
            if (self.delay < time) {
                i1              = fabs(growthstep);
                i2              = fabs(SHRINK_RATE);
                restrain_force1 = i1 / i2;
                self.delay      = time + 0.2;
            }
        }
    }
    // save growth step to .ammo_shells
    self.ammo_shells = growthstep;

    // winch motor handling
    if (
        self.owner.grapple & FL_GRAPPLE_SHORTENING &&
        time > self.owner.sound_inhibit_time
    ) {
        sound (self.owner, CHAN_AUX2, "weapons/winch_motor.wav", 1, ATTN_IDLE);
        self.owner.sound_inhibit_time = time + 1;
    }

    if (
        self.owner.grapple & FL_GRAPPLE_SHORTENING &&
        time > self.owner.winch_celltime
    ) {
        // drain 5 cells a second !
        self.owner.ammo_cells = self.owner.ammo_cells - 1;
        self.owner.winch_celltime = time + 0.2;

        if (self.owner.ammo_cells < 1) {
            self.owner.ammo_cells = 1;
            screen_message(self.owner, "Cells exhausted ! Cannot power winch\n", MSG_WARN, FALSE);
            sound(self.owner, CHAN_AUX2, "weapons/winch_stop.wav", 1, ATTN_IDLE);

            // halt chain lengthening / shortening and just hang
            self.owner.grapple = self.owner.grapple - (self.owner.grapple & (FL_GRAPPLE_EXTENDING | FL_GRAPPLE_SHORTENING));
        }
    }

    // chain physics
    // if player's location is beyond the chain's reach
    if (chainlen > self.armorvalue) {
        // determine player's velocity component of chain vector
        i1 = self.owner.velocity * chainvec; // dot
        i2 = chainvec * chainvec;            // dot
        velpart = chainvec * (i1 / i2);

        // restrainment default force
        restrain_force2 = (chainlen - self.armorvalue) * 5;

        // if player's velocity heading is away from the hook
        if ((self.owner.velocity * chainvec) < 0) { // dot
            if (chainlen > self.armorvalue) {
                self.owner.velocity = self.owner.velocity - (velpart * 0.4);
            }
            // if chain has streched for 25 units
            //if (chainlen > self.armorvalue + 25)
                // remove player's velocity component moving away from hook
            // self.owner.velocity = self.owner.velocity - velpart;
            restrain_force1 = restrain_force2;
        }
        else {
            // if player's velocity heading is towards the hook
            if (vlen(velpart) < restrain_force2) {
                restrain_force1 = restrain_force2 - vlen(velpart);
            }
            else {
                restrain_force1 = 0;
            }
        }
    }
    else {
        restrain_force1 = 0;
    }

    // apply chain restrainment, gradually decellerate

    swingangle = normalize(chainvec);
    self.owner.velocity = 0.95 * (self.owner.velocity + swingangle * restrain_force1);

    handle_chainlinks();
};


//--------------------------------------------------------------------
// Hook's touch function
//--------------------------------------------------------------------
void() grapple_touch = {
    // armorvalue is used to hold current length of chain
    self.armorvalue = vlen(self.origin - (self.owner.origin + '0 0 16'));

    // flags hook as being attached to something
    self.owner.grapple = self.owner.grapple | FL_GRAPPLE_ATTATCHED;

    if (other.solid != SOLID_SLIDEBOX) {
        sound(self, CHAN_AUTO, "weapons/grapple_hit.wav", 1, ATTN_NORM);
        self.avelocity = VEC_ZERO;
        // automatically wind in if hit world
        if (other == world) {
            if (self.owner.ammo_cells > 4) {
                // initiate winch - need at least 4 cells
                sound(self.owner, CHAN_AUX2, "weapons/winch_start.wav", 1, ATTN_IDLE);
                self.owner.sound_inhibit_time = time + 1;
                self.owner.ammo_cells         = self.owner.ammo_cells - 4;
                self.owner.winch_celltime     = time + 0.5;
                self.owner.grapple            = self.owner.grapple | FL_GRAPPLE_SHORTENING;
            }
            else {
                // no cells to power winch ?
                screen_message(self.owner, "Not enough cells to power winch !\n", MSG_WARN, FALSE);
                self.owner.grapple = self.owner.grapple - (self.owner.grapple & (FL_GRAPPLE_EXTENDING | FL_GRAPPLE_SHORTENING));
            }
        }
    }

    self.velocity  = other.velocity;
    self.enemy     = other;
    self.think     = grapple_action;
    self.nextthink = time + 0.02;
    self.touch     = SUB_Null;
};


//--------------------------------------------------------------------
// Limit hook length during launch
//--------------------------------------------------------------------
void() fire_grapple = {
    // armorvalue is used to hold current length of chain
    self.armorvalue = vlen(self.origin - (self.owner.origin + '0 0 16'));

    if (
        !(self.owner.grapple & FL_GRAPPLE_ACTIVE) ||
        self.armorvalue > MAX_CHAIN_LEN  ||
        self.owner.solid == SOLID_NOT
    ) {
        release_grapple();
        return;
    }
    handle_chainlinks();
    self.nextthink = time + 0.01;
};


//--------------------------------------------------------------------
// Initiates the hook
//--------------------------------------------------------------------

void(entity grapple_owner) initialise_grapple = {
   local entity newhook;

   newhook          = spawn ();
   newhook.owner    = grapple_owner;
   newhook.movetype = MOVETYPE_FLY;
   newhook.solid    = SOLID_BBOX;
   setmodel(newhook, "progs/v_spike.mdl");
   setsize(newhook, VEC_ZERO, VEC_ZERO);

   makevectors(grapple_owner.v_angle);

   setorigin (newhook,grapple_owner.origin + (v_forward*16) + '0 0 16' );
   newhook.velocity  = 2000 * aim(grapple_owner, 2000);
   newhook.angles    = vectoangles(newhook.velocity);
   newhook.avelocity = '0 0 600';

   sound(grapple_owner, CHAN_AUTO, "weapons/grapple_fire.wav", 1, ATTN_NORM);

   // used as pointer to first chain link
   newhook.goalentity = world;

   // self.wait = 0;  // damage to ents wait cycle
   // self.ammo_shells = 0; // graded shrink/grow variable
   // self.ammo_nails = FALSE;  // initial hit flag for live ents
   // self.delay = 0; // wait cycle for chain raising/lowering sounds

   newhook.touch      = grapple_touch;
   newhook.nextthink  = time + 0.01 ;
   newhook.think      = fire_grapple;

   newhook.takedamage = DAMAGE_AIM;
   newhook.health     = 20;
   newhook.th_die     = release_grapple;
};

void(vector shot_dir, float shot_impulse) grapple_weapon_kick = {
    // simulates weaponkick impulse force when hanging. shot_impulse should be negative
    // call from weapon attack code
    if (self.grapple & FL_GRAPPLE_ATTATCHED && !(self.flags & FL_ONGROUND)) {
        self.velocity = self.velocity + shot_impulse * shot_dir;
    }
};

// called by player jump events (weapons.qc: W_WeaponFrame() )
void() check_grapple_owner_jump = {
   if ( (self.grapple & FL_GRAPPLE_ATTATCHED) ) {
      if (
          (self.flags & FL_JUMPRELEASED) && // previous jump cycle has finished
          !(self.flags & FL_ONGROUND)
      ) {
         // player not on ground
         self.grapple = 0; // let hook entity's next think know it's dead
         self.velocity_z = self.velocity_z + 200;
         sound (self, CHAN_BODY, "player/plyrjmp8.wav", 1, ATTN_NORM);
      }
   }
};

//--------------------------------------------------------------------
// Checks impulse
//--------------------------------------------------------------------

void() inv_grapple_release = {
   if (self.grapple & FL_GRAPPLE_ACTIVE) {
      // drop the hook
      self.grapple = self.grapple - (self.grapple & FL_GRAPPLE_ACTIVE);
      return;
   }
};

void() inv_grapple_fire = {
   // called from W_FireRocket() in weapons.qc
   // grapple mode must be armed, and not already using grapple
   if (!(self.flags & FL_USING_GRAPPLE)) {
      dprint("grapple with unknown activator\n");
      return;
   }

   // fire the grapple, if not active, else release it
   if (!(self.grapple & FL_GRAPPLE_ACTIVE)) {
      // set hook as active
      self.grapple = FL_GRAPPLE_ACTIVE;

      // use up a rocket
      self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;

      // do player weaponkick and enginekick
      self.punchangle_x = -2 * (!(self.flags & FL_USING_CAMERA));
      initialise_grapple(self);
      missile_enginekick_fx(self.origin - v_forward * 20, TRUE);
   }
   else {
      inv_grapple_release();
   }
};


void() inv_grapple_extend = {
    if (!(self.grapple & FL_GRAPPLE_ACTIVE)) {
        return;
    }
    if (self.grapple & FL_GRAPPLE_SHORTENING) {
        sound(self, CHAN_AUX2, "weapons/winch_stop.wav", 1, ATTN_IDLE);
    }
    // initiate chain extend
    self.grapple = self.grapple | FL_GRAPPLE_EXTENDING;
    self.grapple = self.grapple - (self.grapple & FL_GRAPPLE_SHORTENING);
};


void() inv_grapple_retract = {
    // initiate chain shorten

    if (!(self.grapple & FL_GRAPPLE_ACTIVE)) {
        return;
    }

    if (!(self.ammo_cells > 4)) {
        screen_message(self, "Not enough cells to power winch !\n", MSG_WARN, FALSE);
        return;
    }

    if (!(self.grapple & FL_GRAPPLE_SHORTENING)) {
        sound(self, CHAN_AUX2, "weapons/winch_start.wav", 1, ATTN_IDLE);
        self.sound_inhibit_time = time + 1;

        // initial winch kick needs 4 cells
        self.ammo_cells = self.ammo_cells - 4;
        self.winch_celltime = time + 0.5;
    }
    self.grapple = self.grapple | FL_GRAPPLE_SHORTENING;
    self.grapple = self.grapple - (self.grapple & FL_GRAPPLE_EXTENDING);
};

void() inv_grapple_lock = {
    if (!(self.grapple & FL_GRAPPLE_ACTIVE)) {
        return;
    }

    if (self.grapple & FL_GRAPPLE_SHORTENING) {
        sound(self, CHAN_AUX2, "weapons/winch_stop.wav", 1, ATTN_IDLE);
    }

    // halt chain lengthening / shortening and just hang
    self.grapple = self.grapple - (self.grapple & (FL_GRAPPLE_EXTENDING | FL_GRAPPLE_SHORTENING));
};

void() version_grapple = {
    sprint(self, "grapple 1.12 Karlos '99 (08/10/1999)\n");
};
