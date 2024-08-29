// target.qc

/*---public---*/
// $VER: target.qc 1.97 � Karlos (10/3/2000)

// public function prototypes
// highlevel
void(entity target_owner) inv_toggle_target;
void(entity torch_owner)  inv_toggle_torch;

// public structure extensions
.entity     laser_target_spot;        // player's laser target

/*---private---*/

// structure extensions
.float      torch_celltime;

//------------------------------------------------------------------------------------
// laser targeter functions
// targeter ent. think function

void() laser_track = {
    local vector src, trackpos;
    local entity oself;

    self.nextthink = time + 0.05;

    if (!(self.owner.flags & FL_USING_TARGET)) {
        if (self.owner.flags & FL_USING_TORCH) {
            // no target then no torch either...
            self.owner.flags = self.owner.flags - FL_USING_TORCH;
        }

        // make sure spot is not referenced by owner after removal
        self.owner.laser_target_spot = world;
        remove(self);
        return;
    }

    if (!(self.owner.health > 0)) {
        // player dead, deactivate torch/target but leave player flags alone
        // make sure spot is not referenced by owner after removal
        self.owner.laser_target_spot = world;
        remove(self);
        return;
    }

    // do torch stuff

    if (self.owner.flags & FL_USING_TORCH) {
        // wake up monsters to the light
        if (deathmatch == 0) {
            ai_radius_alert(self, self.owner, 200, TRUE, FALSE);
        }

        // player is using torch
        if (time > self.owner.torch_celltime) {
            // remove one cell every two time units
            if (self.owner.ammo_cells) {
                self.owner.ammo_cells = self.owner.ammo_cells - 1;
                if (self.owner.weapon == IT_LIGHTNING) {
                    // show cell depletion
                    oself = self;
                    self  = self.owner;
                    W_SetCurrentAmmo();
                    self  = oself;
                }

                self.owner.torch_celltime = time + 2.5;
                // do glow
                self.effects = FX_GLOW;
            }
            else {
                // out of cells...deactivate torch
                self.owner.flags = self.owner.flags - FL_USING_TORCH;
                self.effects = 0; // FX_NO_LIGHTS
            }
        }
    }
    else {
        self.effects = 0; // FX_NOLIGHTS
    }

    makevectors(self.owner.v_angle);
    self.angles = vectoangles(v_forward);

    src   = self.owner.origin + v_forward * 10;
    src_z = self.owner.absmin_z + self.owner.size_z * 0.7;

    traceline(src, src + v_forward * 4000, FALSE, self.owner);

    // calculate correct position of target

    if (trace_ent == world) {
        //setorigin(self, (0.1 * src + 0.9 * trace_endpos) );
        trackpos = 0.1 * src + 0.9 * trace_endpos;
    }
    else {
        //setorigin(self, trace_endpos);
        trackpos = trace_endpos;
    }

    // smoothing algorithm
    // if target position far from current position, move using setorigin,
    // else set a velocity based on the distance/time to nextthink

    if (
        vlen(trackpos - self.origin) > 50 ||
        (self.owner.flags & FL_SMOOTH_SUBENTS == 0)
    ) {
        setorigin(self, trackpos);
        self.velocity = VEC_ZERO;
    }
    else {
        self.velocity = (trackpos - self.origin) * 20;
    }

    if (self.owner.extraflags & CL_SHOW_TARGETS && time > self.owner.netname_delay) {
        self.owner.netname_delay = time + 1;
        if (trace_ent.deadflag != DEAD_DEAD) {
            if (trace_ent.flags & FL_CLIENT) {
                centerprint(self.owner, trace_ent.netname);
            }
            else if (
                (trace_ent.flags & FL_MONSTER) &&
                (developer & DV_SHOW_TEAM_AI)
            ) {
                local string t_name, t_mbmr;
                t_name = trace_ent.ai_team.netname;
                t_mbmr = ftos(trace_ent.teammember);
                self.owner.netname_delay = time + 2;
                dprint6 (trace_ent.netname, " [", t_name, "/", t_mbmr, "]\n");
            }
        }
    }
};

//-------------------------------------------------------------------------

void(entity torch_owner) inv_toggle_torch = {
    if (!(torch_owner.flags & FL_USING_TARGET)) {
        screen_message(torch_owner, "torch cannot be activated\nwithout laser target\n", MSG_INFO, FALSE);
        return;
    }

    // ok, we are using the target. Toggle torch flag

    sound(torch_owner, CHAN_AUTO, "misc/switch.wav", 0.75, ATTN_IDLE);

    if (torch_owner.flags & FL_USING_TORCH) {
        torch_owner.flags = torch_owner.flags - FL_USING_TORCH;
    }
    else {
        torch_owner.flags = torch_owner.flags | FL_USING_TORCH;
    }

    // Out of cells ?
    if (!torch_owner.ammo_cells) {
        // no cells - print message
        screen_message (torch_owner, "no cells for torch\n", MSG_WARN, FALSE);

        // deactivate torch if currently active
        if (torch_owner.flags & FL_USING_TORCH) {
            torch_owner.flags = torch_owner.flags - FL_USING_TORCH;
        }
    }
};

void(entity targ_owner) inv_toggle_target = {
    local entity laser_spot;

    if (targ_owner.flags & FL_USING_TARGET) {
        targ_owner.flags = targ_owner.flags - FL_USING_TARGET;
    }
    else {
        targ_owner.flags = targ_owner.flags | FL_USING_TARGET;

        laser_spot = spawn();

        // assign owner of target
        laser_spot.owner = targ_owner;

        // assign owner as owning this particular spot, so his missiles can find it
        // defined member .laser_target_spot for this...

        laser_spot.owner.laser_target_spot = laser_spot;

        laser_spot.movetype = MOVETYPE_NOCLIP;
        laser_spot.solid    = SOLID_NOT;

        setmodel(laser_spot, "progs/s_bubble.spr");

        setsize(laser_spot, VEC_ZERO, VEC_ZERO);
        setorigin(laser_spot, laser_spot.owner.origin);

        laser_spot.nextthink = time + 0.025;
        laser_spot.think     = laser_track;
    }
};

