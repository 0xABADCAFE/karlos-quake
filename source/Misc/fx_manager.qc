// fx_manager.qc

/*---public---*/
// $VER: fx_manager.qc 1.02 © Karlos (28/03/2000)

// public function prototypes
// highlevel

// lowlevel
void () spawn_world_fx_manager;
void () world_fx_manager_think;
void (entity for_whom) spawn_fx_manager;
void () fx_manager_remove;
void () fx_manager_think;

/*---private---*/

void () fx_manager_remove = {
    local string tmp_str;

    tmp_str = ftos(self.owner.def_gamma);

    stuffcmd(self.owner, "gamma ");
    stuffcmd(self.owner, tmp_str);
    stuffcmd(self.owner, "\n");

    tmp_str = ftos(self.owner.def_fov);

    stuffcmd(self.owner, "fov ");
    stuffcmd(self.owner, tmp_str);
    stuffcmd(self.owner, "\n");

    sprint (self.owner, "fx_manager : removed\n");

    remove(self);
};

void () fx_manager_think = {
    // Needs to check if fade is needed for teleports etc.

    local string tmp_str;

    // check the gamma status
    if (effectflags & FX_CON_GAMMA) {
        if (self.owner.cur_gamma < self.def_gamma) {
            self.owner.cur_gamma = self.owner.cur_gamma + 0.1;

            if (fabs(self.owner.cur_gamma - self.def_gamma) < 0.2) {
                self.owner.cur_gamma = self.def_gamma;
            }

            tmp_str = ftos(self.owner.cur_gamma);
            stuffcmd(self.owner, "gamma ");
            stuffcmd(self.owner, tmp_str);
            stuffcmd(self.owner, ";");
        }
        else if (self.owner.cur_gamma > self.def_gamma) {
            self.owner.cur_gamma = self.owner.cur_gamma - 0.1;

            if (fabs(self.owner.cur_gamma - self.def_gamma) < 0.2) {
                self.owner.cur_gamma = self.def_gamma;
            }

            tmp_str = ftos(self.owner.cur_gamma);
            stuffcmd(self.owner, "gamma ");
            stuffcmd(self.owner, tmp_str);
            stuffcmd(self.owner, ";");
        }
    }
    // check the fov status

    if (effectflags & FX_CON_FOV) {
        if (self.owner.cur_fov < self.def_fov) {
            self.owner.cur_fov = self.owner.cur_fov + self.cur_fov;

            if (fabs(self.owner.cur_fov - self.def_fov) < 2) {
                self.owner.cur_fov = self.def_fov;
            }

            tmp_str = ftos(self.owner.cur_fov);
            stuffcmd(self.owner, "fov ");
            stuffcmd(self.owner, tmp_str);
            stuffcmd(self.owner, ";");
        }
        else if (self.owner.cur_fov > self.def_fov) {
            self.owner.cur_fov = self.owner.cur_fov - self.cur_fov;

            if (fabs(self.owner.cur_fov - self.def_fov) < 2) {
                self.owner.cur_fov = self.def_fov;
            }

            tmp_str = ftos(self.owner.cur_fov);
            stuffcmd(self.owner, "fov ");
            stuffcmd(self.owner, tmp_str);
            stuffcmd(self.owner, ";");
        }
    }

    if (
        self.owner.cur_fov != self.def_fov ||
        self.owner.cur_gamma != self.def_gamma
    ) {
        stuffcmd(self.owner, "wait\n");
        self.nextthink = time + 0.01;
    }
    else {
        //sprint (self.owner, "fx_manager : job complete\n");
        self.nextthink = time + 60000;
    }
    self.think     = fx_manager_think;
};

void (entity for_whom) spawn_fx_manager = {
    local entity manager;

    // spawn an effect manager entity for the named client

    // ret if calling entity is not a client or already has an effect manager
    if (for_whom.flags & FL_CLIENT == 0) {
        return;
    }

    manager = spawn();

    manager.owner       = for_whom;
    for_whom.fx_manager = manager;
    manager.def_fov     = for_whom.def_fov;
    manager.def_gamma   = for_whom.def_gamma;
    manager.cur_fov     = 5; // default fov change size
    manager.think       = fx_manager_think;
    manager.nextthink   = time + 60000;
    //sprint (manager.owner, "fx_manager : initialized\n");
};

//================================================================================
//
//    World Effects Manager code
//
//    Contains special fx routines assigned to the world. A manager is spawned,
//    with the owners set to the world entity.
//
//===============================================================================

void () world_fx_thunder = {
    // Thunder effect. Called as think from lightning after a delay time
    // Sounds are played via the world itself rather than the manager

    sound(world, CHAN_ITEM, "spot_fx/thunder.wav", 1 - self.ammo_cells, ATTN_NONE);

    if (random() > 0.5) {
        sound(world, CHAN_BODY, "spot_fx/thunder.wav", (1 - self.ammo_cells) * 0.5, ATTN_NONE);
    }
    self.think     = world_fx_manager_think;
    self.nextthink = time + 2 + random() * 30;
};

void () world_fx_lightning = {
    // lightning effect
    // Works by issuing gamma flash effects to each client's fx manager

   local string temp_string;
   local entity head;
   if (effectflags & FX_CON_GAMMA) {
       self.ammo_cells = 0.1+random() * 0.5;
       head = findradius(world.origin, 10000);
       while (head) {
           if (head.flags & FL_CLIENT && head.deadflag == DEAD_NO) {
               head.cur_gamma = self.ammo_cells;
               temp_string = ftos(head.cur_gamma);
               stuffcmd(head, "gamma ");
               stuffcmd(head, temp_string);
               stuffcmd(head, ";wait;gamma 0.6;wait;gamma ");
               stuffcmd(head, temp_string);
               stuffcmd(head, "\n");
               // wake up clients fx manager
               head.fx_manager.nextthink = time + 0.02;
           }
           head = head.chain;
       }
       // set a related delay before the thunderclap
       self.nextthink = time + 3 * (self.ammo_cells - 0.1) + 0.02;
       self.think     = world_fx_thunder;
   }
};

void () world_fx_spotsound = {
    local float fx_choice;
    fx_choice = random();
    if (fx_choice < 0.25) {
       sound(self, CHAN_WEAPON, "spot_fx/evil_00.wav", 0.7 + (0.3 * random()), ATTN_NONE);
    }
    else if (fx_choice < 0.5) {
       sound(self, CHAN_ITEM, "spot_fx/evil_01.wav", 0.7 + (0.3 * random()), ATTN_NONE);
    }
    else if (fx_choice < 0.75) {
       sound(self, CHAN_WALK, "spot_fx/evil_02.wav", 0.6 + (0.4 * random()), ATTN_NONE);
    }
    else {
       sound(self, CHAN_AUX1, "spot_fx/evil_03.wav", 0.6 + (0.4 * random()), ATTN_NONE);
    }
};

void () world_fx_manager_think =
{
    local float fx_choice;
    fx_choice = random();

    if (fx_choice < 0.1) {
       // lightning flash
       world_fx_lightning();
    }
    else if (fx_choice < 0.8) {
        // do a spot sound
        world_fx_spotsound();
        self.think     = world_fx_manager_think;
        self.nextthink = time + 2 + random() * 10;
    }
    else {
        sound(world, CHAN_WALK, "spot_fx/thunder_dist.wav", 0.6 + 0.4 * random(), ATTN_NONE);
        // do nothing and set up next cycle
        self.think     = world_fx_manager_think;
        self.nextthink = time + 5 + random()*20;
    }
};

void () spawn_world_fx_manager = {
    local entity manager;

    // spawn an effect manager entity for the named client
    // ret if calling entity is not a client or already has an effect manager

    manager = spawn();
    precache_sound("spot_fx/thunder.wav");
    precache_sound("spot_fx/thunder_dist.wav");
    precache_sound("spot_fx/evil_00.wav");
    precache_sound("spot_fx/evil_01.wav");
    precache_sound("spot_fx/evil_02.wav");
    precache_sound("spot_fx/evil_03.wav");
    manager.owner     = world;
    world.fx_manager  = manager;
    manager.think     = world_fx_manager_think;
    manager.nextthink = time + 2 + random()*10;
    //dprint ("world_fx_manager : initialized\n");
};
