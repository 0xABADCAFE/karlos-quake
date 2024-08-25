// client.qc

/*---public---*/
// $VER: client.qc 1.85 Karlos (11/10/1999)

// public function prototypes
// highlevel
entity() FindIntermission;
void()   GotoNextMap;
void()   ExitIntermission;
void()   IntermissionThink;
void()   execute_changelevel;
void()   changelevel_touch;
void()   trigger_changelevel;
void()   respawn;
float(vector v) CheckSpawnPoint;
entity() SelectSpawnPoint;
void()   NextLevel;
void()   CheckRules;
void()   PlayerDeathThink;
void()   PlayerJump;
void()   WaterMove;
void()   CheckWaterJump;
void()   CheckPowerups;

void()   player_set_weapon_view;

/*---private---*/

.float  dmgtime;
.string breath;
string  nextmap;

/**
 * Sets the player weapon view
 */
void() player_set_weapon_view = {
    if ((self.extraflags & CL_CENTREHANDED) == CL_NOHANDVIEW) {
        localcmd("r_drawviewmodel 0;scr_ofsy 0\n");
    }
    else if ((self.extraflags & CL_CENTREHANDED) == CL_RIGHTHANDED) {
        localcmd("r_drawviewmodel 1;scr_ofsy -4\n");
    }
    else if ((self.extraflags & CL_CENTREHANDED) == CL_LEFTHANDED) {
        localcmd("r_drawviewmodel 1;scr_ofsy 4\n");
    }
    else {
        localcmd("r_drawviewmodel 1;scr_ofsy 0\n");
    }
};

//=============================================================================
//
//   LEVEL CHANGING / INTERMISSION (AKA Diabolical Script ;)
//
//=============================================================================


/*QUAKED info_intermission (1 0.5 0.5) (-16 -16 -16) (16 16 16)
This is the camera point for the intermission.
Use mangle instead of angle, so you can set pitch or roll as well as yaw.  'pitch roll yaw'
*/

void() info_intermission = {

};

//===========================================================================
//
//   Parameter stuff
//
//===========================================================================

void() SetChangeParms = {
    if (self.health <= 0) {
        SetNewParms();
        return;
    }

    // remove all items except weapons
    self.items = self.items & IT_IS_A_WEAPON;

    // cap super health
    if (self.health > 100) {
        self.health = 100;
    }
    else if (self.health < 50) {
        self.health = 50;
    }

    parm1 = self.items | self.inventory;
    parm2 = self.health;
    parm3 = self.armorvalue;
    if (self.ammo_shells < 25) {
        parm4 = 25;
    }
    else {
        parm4 = self.ammo_shells;
    }

    parm5  = self.ammo_nails;
    parm6  = self.ammo_rockets;
    parm7  = self.ammo_cells;
    parm8  = self.weapon;
    parm9  = self.armortype * 100;
    parm14 = encode_weapon_damagestats();
    parm15 = self.server_master | self.server_access;

    // camera and targeter variables
    parm12 = self.dest2_y; // cam distance
    parm13 = self.dest2_z; // cam height

    // backup all the extra server/client stuff#
    save_client_extraparms();
    if (self.server_master) {
        save_server_opts();
    }
};

//---------------------------------------------------------------------------

void() SetNewParms = {
    parm1 = IT_SHOTGUN | IT_AXE; // nothing in inventory
    parm2 = 100;
    parm3 = 0;
    parm4 = 25;
    parm5 = 0;
    parm6 = 5;  // five rocket/grenades, since we now can throw by hand
    parm7 = 20; // cells for torch
    parm8 = 1;
    parm9 = 0;

    // camera only reset if zeroed  (so DM/COOP respawns don't reset)
    if (!parm12) {
        parm12 = 100; // dist - cam distance
    }

    if (!parm13) {
        parm13 = 0.10; //zmult - cam height offset
    }

    // default client parms
    parm14 = 0; // Mike Rules - No damages

    // does client have server access ?
    if (self.server_master) {
        parm15 = CL_ADMIN | CL_SERVER_ACCESS;
        set_server_opts();
    }

    //set_client_extraparms();
};

//---------------------------------------------------------------------------

void() DecodeLevelParms = {
    if (serverflags) {
        if (world.model == "maps/start.bsp") {
            // take away all stuff on starting new episode
            SetNewParms();
        }
    }

    self.items        = parm1 & IT_IS_A_WEAPON;
    self.inventory    = parm1 & IT_POWERUP;
    self.health       = parm2;
    self.armorvalue   = parm3;
    self.ammo_shells  = parm4;
    self.ammo_nails   = parm5;
    self.ammo_rockets = parm6;
    self.ammo_cells   = parm7;

    // make allowances for player torch
    if (self.ammo_cells < 15) {
        self.ammo_cells = 15;
    }
    self.weapon    = parm8;
    self.armortype = parm9 * 0.01;

    // get client/server parms
    set_client_extraparms();

    // camera distance / offsets
    if (!self.dest2_y) {
        self.dest2_y = parm12;
    }

    if (!self.dest2_z) {
        self.dest2_z = parm13;
    }

    // we keep server master as first bit of inventory
    // but, check it isn't already set (else no master for new game)
    // also, check on a per-client basis if client has server rights
    // and force it if need be...

    // server access ?
    if (!self.server_access) {
        self.server_access = parm15 & CL_SERVER_ACCESS;
    }

    // server master ?
    if (!self.server_master) {
        self.server_master = parm15 & CL_ADMIN;
    }

    // if server master then set server options
    if (self.server_master) {
        set_server_opts();
    }

    if (mikerules) {
        decode_weapon_damagestats(parm14);
    }
};


//===========================================================================
//
//   FindIntermission : Returns the entity to view from
//
//===========================================================================

entity() FindIntermission = {
    local entity spot;
    local float  cyc;

    // look for info_intermission first
    spot = find (world, classname, "info_intermission");
    if (spot) {  // pick a random one
        cyc = random() * 4;
        while (cyc > 1) {
            spot = find(spot, classname, "info_intermission");
            if (!spot) {
                spot = find(spot, classname, "info_intermission");
            }
            cyc = cyc - 1;
        }
        return spot;
    }

    // then look for the start position
    spot = find(world, classname, "info_player_start");
    if (spot) {
        return spot;
    }

    // testinfo_player_start is only found in regioned levels
    spot = find(world, classname, "testplayerstart");
    if (spot) {
        return spot;
    }
    objerror("FindIntermission: no spot");
};


//---------------------------------------------------------------------------

void() GotoNextMap = {
    if (cvar("samelevel")) {
        // if samelevel is set, stay on same level
        changelevel(mapname);
    }
    else {
        changelevel(nextmap);
    }
};


//---------------------------------------------------------------------------

void() ExitIntermission = {
    // skip any text in deathmatch
    if (deathmatch) {
        GotoNextMap();
        return;
    }

    intermission_exittime = time + 1;
    intermission_running  = intermission_running + 1;

    //
    // run some text if at the end of an episode
    //
    if (intermission_running == 2) {
        if (world.model == "maps/e1m7.bsp") {
            WriteByte(MSG_ALL, SVC_CDTRACK);
            WriteByte(MSG_ALL, 2);
            WriteByte(MSG_ALL, 3);
            if (!cvar("registered")) {
                WriteByte(MSG_ALL, SVC_FINALE);
                WriteString(
                    MSG_ALL,
                    "As the corpse of the monstrous entity\nChthon sinks back into the lava whence\nit rose, you grip the Rune of Earth\nMagic tightly. Now that you have\nconquered the Dimension of the Doomed,\nrealm of Earth Magic, you are ready to\ncomplete your task in the other three\nhaunted lands of Quake. Or are you? If\nyou don't register Quake, you'll never\nknow what awaits you in the Realm of\nBlack Magic, the Netherworld, and the\nElder World!"
                );
            }
            else {
                WriteByte(MSG_ALL, SVC_FINALE);
                WriteString(
                    MSG_ALL,
                    "As the corpse of the monstrous entity\nChthon sinks back into the lava whence\nit rose, you grip the Rune of Earth\nMagic tightly. Now that you have\nconquered the Dimension of the Doomed,\nrealm of Earth Magic, you are ready to\ncomplete your task. A Rune of magic\npower lies at the end of each haunted\nland of Quake. Go forth, seek the\ntotality of the four Runes!"
                );
            }
            return;
        }
        else if (world.model == "maps/e2m6.bsp") {
            WriteByte(MSG_ALL, SVC_CDTRACK);
            WriteByte(MSG_ALL, 2);
            WriteByte(MSG_ALL, 3);
            WriteByte(MSG_ALL, SVC_FINALE);
            WriteString(
                MSG_ALL,
                "The Rune of Black Magic throbs evilly in\nyour hand and whispers dark thoughts\ninto your brain. You learn the inmost\nlore of the Hell-Mother; Shub-Niggurath!\nYou now know that she is behind all the\nterrible plotting which has led to so\nmuch death and horror. But she is not\ninviolate! Armed with this Rune, you\nrealize that once all four Runes are\ncombined, the gate to Shub-Niggurath's\nPit will open, and you can face the\nWitch-Goddess herself in her frightful\notherworld cathedral."
            );
            return;
        }
        else if (world.model == "maps/e3m6.bsp") {
            WriteByte(MSG_ALL, SVC_CDTRACK);
            WriteByte(MSG_ALL, 2);
            WriteByte(MSG_ALL, 3);
            WriteByte(MSG_ALL, SVC_FINALE);
            WriteString(
                MSG_ALL,
                "The charred viscera of diabolic horrors\nbubble viscously as you seize the Rune\nof Hell Magic. Its heat scorches your\nhand, and its terrible secrets blight\nyour mind. Gathering the shreds of your\ncourage, you shake the devil's shackles\nfrom your soul, and become ever more\nhard and determined to destroy the\nhideous creatures whose mere existence\nthreatens the souls and psyches of all\nthe population of Earth."
            );
            return;
        }
        else if (world.model == "maps/e4m7.bsp") {
            WriteByte(MSG_ALL, SVC_CDTRACK);
            WriteByte(MSG_ALL, 2);
            WriteByte(MSG_ALL, 3);
            WriteByte(MSG_ALL, SVC_FINALE);
            WriteString(
                MSG_ALL,
                "Despite the awful might of the Elder\nWorld, you have achieved the Rune of\nElder Magic, capstone of all types of\narcane wisdom. Beyond good and evil,\nbeyond life and death, the Rune\npulsates, heavy with import. Patient and\npotent, the Elder Being Shub-Niggurath\nweaves her dire plans to clear off all\nlife from the Earth, and bring her own\nfoul offspring to our world! For all the\ndwellers in these nightmare dimensions\nare her descendants! Once all Runes of\nmagic power are united, the energy\nbehind them will blast open the Gateway\nto Shub-Niggurath, and you can travel\nthere to foil the Hell-Mother's plots\nin person."
            );
            return;
        }

        GotoNextMap();
    }

    if (intermission_running == 3) {
        if (!cvar("registered")) {
            // shareware episode has been completed, go to sell screen
            WriteByte(MSG_ALL, SVC_SELLSCREEN);
            return;
        }

        if ((serverflags & 15) == 15) {
            WriteByte(MSG_ALL, SVC_FINALE);
            WriteString(
                MSG_ALL,
                "Now, you have all four Runes. You sense\ntremendous invisible forces moving to\nunseal ancient barriers. Shub-Niggurath\nhad hoped to use the Runes Herself to\nclear off the Earth, but now instead,\nyou will use them to enter her home and\nconfront her as an avatar of avenging\nEarth-life. If you defeat her, you will\nbe remembered forever as the savior of\nthe planet. If she conquers, it will be\nas if you had never been born."
            );
            return;
        }
    }

    GotoNextMap();
};


//===========================================================================
//
//  IntermissionThink : When the player presses attack or jump, change to the next level
//
//===========================================================================

void() IntermissionThink = {
    // Allow access to extended command set, allowing only those
    // valid during an intermission

    ImpulseCommands_3();
    self.impulse = 0;

    if (time < intermission_exittime) {
        return;
    }
    if (!self.button0 && !self.button1 && !self.button2) {
        return;
    }
    ExitIntermission();
};

//---------------------------------------------------------------------------

void() execute_changelevel = {
    local entity pos;

    intermission_running = 1;

    // enforce a wait time before allowing changelevel
    if (deathmatch) {
        intermission_exittime = time + 5;
    }
    else {
        intermission_exittime = time + 2;
    }

    WriteByte(MSG_ALL, SVC_CDTRACK);
    WriteByte(MSG_ALL, 3);
    WriteByte(MSG_ALL, 3);
    pos   = FindIntermission ();
    other = find (world, classname, "player");
    while (other != world) {
        other.view_ofs   = VEC_ZERO;
        other.angles     = other.v_angle = pos.mangle;
        other.fixangle   = TRUE;     // turn this way immediately
        other.nextthink  = time + 0.5;
        other.takedamage = DAMAGE_NO;
        other.solid      = SOLID_NOT;
        other.movetype   = MOVETYPE_NONE;
        other.modelindex = 0;
        setorigin(other, pos.origin);
        other = find(other, classname, "player");
    }

    WriteByte(MSG_ALL, SVC_INTERMISSION);
};

//---------------------------------------------------------------------------

void() changelevel_touch = {
    local entity pos;

    if (other.classname != "player") {
        return;
    }

    if (
        (cvar("noexit") == 1) ||
        ((cvar("noexit") == 2) && (mapname != "start"))
    ) {
        T_Damage(other, self, self, 50000);
        return;
    }

    if (coop || deathmatch) {
        bprint2(other.netname, " exited the level\n");
    }

    nextmap = self.map;
    SUB_UseTargets();

    if (
        (self.spawnflags & 1) &&
        (deathmatch == 0)
    ) {
        // NO_INTERMISSION
        GotoNextMap();
        return;
    }

    self.touch = SUB_Null;

    // we can't move people right now, because touch functions are called
    // in the middle of C movement code, so set a think time to do it
    self.think     = execute_changelevel;
    self.nextthink = time + 0.1;
};

//---------------------------------------------------------------------------


/*
   QUAKED trigger_changelevel (0.5 0.5 0.5) ? NO_INTERMISSION
   When the player touches this, he gets sent to the map listed in the "map" variable.  Unless
the NO_INTERMISSION flag is set, the view will go to the info_intermission spot and
display stats.
*/

void() trigger_changelevel = {
   if (!self.map) {
      objerror("chagnelevel trigger doesn't have map");
   }

   InitTrigger();
   self.touch = changelevel_touch;
};


//=============================================================================
//
//   PLAYER GAME EDGE FUNCTIONS
//
//=============================================================================

// called by ClientKill and DeadThink
void() respawn = {
    save_client_extraparms();
    if (coop) {
        // make a copy of the dead body for appearances sake
        CopyToBodyQue(self);

        // get the spawn parms as they were at level start
        setspawnparms(self);

        // respawn
        PutClientInServer();
    }
    else if (deathmatch) {
        // make a copy of the dead body for appearances sake
        CopyToBodyQue(self);

        // set default spawn parms
        SetNewParms();

        // respawn
        PutClientInServer();
    }
    else {
        // restart the entire server
        // must be a single player game
        // we need to save any changes made to the server environment
        // prior to restarting
        save_server_opts();
        localcmd("restart\n");
    }
};


//===========================================================================
//
//   ClientKill : Player entered the suicide command
//
//===========================================================================

void() ClientKill = {
    bprint2(self.netname, " suicides");
    set_suicide_frame();
    self.modelindex = self.index_player;
    self.frags      = self.frags - 2;  // extra penalty
    respawn();
};

//============================================================================
//
//   CheckSpawnPoint
//
//============================================================================

float(vector v) CheckSpawnPoint = {
    return FALSE;
};

//===========================================================================
//
//   SelectSpawnPoint : Returns the entity to spawn at
//
//===========================================================================

entity() SelectSpawnPoint = {
    local entity spot;
    local entity thing;
    local float  pcount;

    // testinfo_player_start is only found in regioned levels
    spot = find(world, classname, "testplayerstart");
    if (spot) {
        return spot;
    }

    // choose a info_player_deathmatch point
    if (coop) {
        lastspawn = find(lastspawn, classname, "info_player_coop");
        if (lastspawn == world) {
            lastspawn = find(lastspawn, classname, "info_player_start");
        }

        if (lastspawn != world) {
            return lastspawn;
        }
    }
    else if (deathmatch) {
        spot = lastspawn;
        while (1) {
            spot = find(spot, classname, "info_player_deathmatch");
            if (spot != world) {
                if (spot == lastspawn) {
                    return lastspawn;
                }

                pcount = 0;
                thing  = findradius(spot.origin, 32);
                while (thing) {
                    if (thing.classname == "player") {
                        pcount = pcount + 1;
                    }
                    thing = thing.chain;
                }

                if (pcount == 0) {
                    lastspawn = spot;
                    return spot;
                }
            }
        }
    }

    if (serverflags) {
        // return with a rune to start
        spot = find(world, classname, "info_player_start2");
        if (spot) {
            return spot;
        }
    }

    spot = find (world, classname, "info_player_start");
    if (!spot) {
        error("PutClientInServer: no info_player_start on level");
    }

    return spot;
};


//===========================================================================
//
//  PutClientInServer :  called each time a player is spawned
//
//===========================================================================

void() PutClientInServer = {
    local entity spot;

    spot = SelectSpawnPoint();

    self.classname             = "player";
    self.health                = 100;
    self.takedamage            = DAMAGE_AIM;
    self.solid                 = SOLID_SLIDEBOX;
    self.movetype              = MOVETYPE_WALK;
    self.show_hostile          = 0;
    self.max_health            = 100;
    self.flags                 = FL_CLIENT;
    self.air_finished          = time + 12;
    self.dmg                   = 2;        // initial water damage
    self.super_damage_finished = 0;
    self.radsuit_finished      = 0;
    self.invisible_finished    = 0;
    self.invincible_finished   = 0;
    self.effects               = 0;
    self.invincible_time       = 0;

    DecodeLevelParms();
    W_SetCurrentAmmo();

    self.attack_finished = time;
    self.th_pain         = player_pain;
    self.th_die          = PlayerDie;
    self.deadflag        = DEAD_NO;

    // paustime is set by teleporters to keep the player from moving a while
    self.pausetime = 0;

    // spot = SelectSpawnPoint();

    self.origin   = spot.origin + '0 0 1';
    self.angles   = spot.angles;
    self.fixangle = TRUE;      // turn this way immediately

    // oh, this is a hack!
    setmodel (self, "progs/eyes.mdl");
    modelindex_eyes = self.modelindex;

    if (!self.gender) {
        setmodel(self, "progs/player.mdl");
    }
    else {
        setmodel(self, "progs/f_player.mdl");
    }

    self.index_player = self.modelindex;
    setsize(self, VEC_HULL_MIN, VEC_HULL_MAX);
    self.view_ofs = '0 0 22';

    // set handedness
    player_set_weapon_view();
    player_stand1();

    if (!self.cl_color) {
        self.cl_color = cvar("_cl_color");
    }
    self.teamgroup = TEAM_CLIENT; // used for monster team ai

    if (deathmatch || coop) {
        makevectors(self.angles);
        spawn_tfog (self.origin + v_forward*20);
    }

    spawn_fx_manager (self);
    spawn_tdeath (self.origin, self);

    initialise_camera();

    if (self.server_master) {
        administrator = self;
        self.server_access = CL_SERVER_ACCESS;
    }
    else {
        report_to_administrator(self);
    }
};


//=============================================================================
//
//   QUAKED FUNCTIONS
//
//=============================================================================


/*QUAKED info_player_start (1 0 0) (-16 -16 -24) (16 16 24)
The normal starting point for a level.
*/
void() info_player_start = {};


/*QUAKED info_player_start2 (1 0 0) (-16 -16 -24) (16 16 24)
Only used on start map for the return point from an episode.
*/
void() info_player_start2 = {};


// saved out by quaked in region mode

void() testplayerstart = {};

/*QUAKED info_player_deathmatch (1 0 1) (-16 -16 -24) (16 16 24)
potential spawning position for deathmatch games
*/
void() info_player_deathmatch = {};

/*QUAKED info_player_coop (1 0 1) (-16 -16 -24) (16 16 24)
potential spawning position for coop games
*/
void() info_player_coop = {};

//==============================================================================
//
//   RULES
//
//==============================================================================

// go to the next level for deathmatch
// only called if a time or frag limit has expired

void() NextLevel = {
    local entity o;

    if (mapname == "start") {
        if (!cvar("registered")) {
            mapname = "e1m1";
        }
        else if (!(serverflags & 1)) {
            mapname = "e1m1";
            serverflags = serverflags | 1;
        }
        else if (!(serverflags & 2)) {
            mapname = "e2m1";
            serverflags = serverflags | 2;
        }
        else if (!(serverflags & 4)) {
            mapname = "e3m1";
            serverflags = serverflags | 4;
        }
        else if (!(serverflags & 8)) {
            mapname = "e4m1";
            serverflags = serverflags - 7;
        }

        o     = spawn();
        o.map = mapname;
    }
    else {
        // find a trigger changelevel
        o = find(world, classname, "trigger_changelevel");

        // go back to start if no trigger_changelevel
        if (!o) {
            mapname = "start";
            o       = spawn();
            o.map   = mapname;
        }
    }

    nextmap  = o.map;
    gameover = TRUE;

    if (o.nextthink < time) {
        o.think = execute_changelevel;
        o.nextthink = time + 0.1;
    }
};


//===========================================================================
//
//  CheckRules : Exit deathmatch games upon conditions
//
//===========================================================================

void() CheckRules = {
    local float    timelimit;
    local float    fraglimit;

    if (gameover) {
        // someone else quit the game already
        return;
    }

    timelimit = cvar("timelimit") * 60;
    fraglimit = cvar("fraglimit");

    if (timelimit && time >= timelimit) {
        NextLevel();
        return;
    }

    if (fraglimit && self.frags >= fraglimit) {
        NextLevel();
        return;
    }
};


//============================================================================
//
//   PlayerDeathThink
//
//============================================================================

void() PlayerDeathThink = {
    local entity   old_self;
    local float    forward;

    if ((self.flags & FL_ONGROUND)) {
        forward = vlen (self.velocity);
        forward = forward - 20;
        if (forward <= 0) {
            self.velocity = VEC_ZERO;
        }
        else {
            self.velocity = forward * normalize(self.velocity);
        }
    }

    // wait for all buttons released
    if (self.deadflag == DEAD_DEAD) {
        if (self.button2 || self.button1 || self.button0) {
            return;
        }
        self.deadflag = DEAD_RESPAWNABLE;
        return;
    }

    // Allow access to extended command set - all commands except game controls
    // are available

    ImpulseCommands_2();
    ImpulseCommands_3();
    self.impulse = 0;

    // wait for any button down
    if (!self.button2 && !self.button1 && !self.button0) {
        return;
    }

    self.button0 = 0;
    self.button1 = 0;
    self.button2 = 0;

    // re initialise the fx_manager and camera entites
    self.fx_manager.think = fx_manager_remove;

    // camera viewport needs switching to respawned player...
    // Does not matter in single player, since whole server is restarted
    if (deathmatch || coop) {
        if (self.flags & FL_USING_CAMERA) {
            set_viewport(self, self);
        }
    }
    respawn();
};


//---------------------------------------------------------------------------

void() PlayerJump = {
    local vector start, end;

    if (self.flags & FL_WATERJUMP) {
        return;
    }

    if (self.waterlevel >= 2) {
        if (self.watertype == CONTENT_WATER) {
            self.velocity_z = 100;
        }
        else if (self.watertype == CONTENT_SLIME) {
            self.velocity_z = 80;
        }
        else {
            self.velocity_z = 50;
        }

        // play swiming sound
        if (self.swim_flag < time) {
            self.swim_flag = time + 1;
            if (random() < 0.5) {
                sound(self, CHAN_BODY, "misc/water1.wav", 1, ATTN_NORM);
            }
            else {
                sound(self, CHAN_BODY, "misc/water2.wav", 1, ATTN_NORM);
            }
        }

        return;
    }

    if (!(self.flags & FL_ONGROUND)) {
        return;
    }

    if ( !(self.flags & FL_JUMPRELEASED) ) {
        return;     // don't pogo stick
    }

    self.flags   = self.flags - (self.flags & FL_JUMPRELEASED);
    self.flags   = self.flags - FL_ONGROUND; // don't stairwalk
    self.button2 = 0;

    // player jumping sound
    if (!self.gender) {
        sound(self, CHAN_VOICE, "player/plyrjmp8.wav", 1, ATTN_NORM);
    }
    else {
        sound (self, CHAN_VOICE, "f_player/plyrjmp8.wav", 1, ATTN_NORM);
    }
    self.velocity_z = self.velocity_z + 270;
};


//============================================================================
//
//   WaterMove
//
//============================================================================

void() WaterMove = {
    if (self.movetype == MOVETYPE_NOCLIP) {
        return;
    }

    if (self.health < 0) {
        return;
    }

    if (self.waterlevel != 3) {
        if (self.air_finished < time) {
            if (!self.gender) {
                sound(self, CHAN_VOICE, "player/gasp2.wav", 1, ATTN_NORM);
            }
            else {
                sound(self, CHAN_VOICE, "f_player/gasp2.wav", 1, ATTN_NORM);
            }
        }
        else if (self.air_finished < time + 9) {
            if (!self.gender) {
                sound(self, CHAN_VOICE, "player/gasp1.wav", 1, ATTN_NORM);
            }
            else {
                sound(self, CHAN_VOICE, "f_player/gasp1.wav", 1, ATTN_NORM);
            }
        }
        self.air_finished = time + 12;
        self.dmg = 2;
    }
    else if (self.air_finished < time) {
        // drown!
        if (self.pain_finished < time) {
            self.dmg = self.dmg + 2;
            if (self.dmg > 15) {
                self.dmg = 10;
            }
            self.deathtype = "drowning";
            T_Damage(self, world, world, self.dmg);
            self.pain_finished = time + 1;
        }
    }

    if (!self.waterlevel) {
        if (self.flags & FL_INWATER) {
            // play leave water sound
            sound(self, CHAN_BODY, "misc/outwater.wav", 1, ATTN_NORM);
            self.flags = self.flags - FL_INWATER;
        }
        return;
    }

    if (self.watertype == CONTENT_LAVA) {
        // do damage
        if (self.dmgtime < time) {
            if (self.burntime < time) {
                particle (self.origin, (crandom() * '40 40 10') + '0 0 100', 110, 20);
                self.burntime = time + 0.7;
                if (self.waterlevel < 3) {
                    sound(self, CHAN_AUX1, "shared/frying.wav", 1, ATTN_NORM);
                }
                else {
                    sound(self, CHAN_WALK, "shared/frying2.wav", 1, ATTN_NORM);
                }
            }

            if (self.radsuit_finished > time) {
                self.dmgtime = time + 1;
            }
            else {
                self.dmgtime = time + 0.2;
            }
            self.deathtype = "lava";
            T_Damage(self, world, world, 10 * self.waterlevel);
        }
    }
    else if (self.watertype == CONTENT_SLIME) {  // do damage
        particle(self.origin, (crandom() * '10 0 0') + (crandom()*'0 10 0') + '0 0 20', 12, 20);
        if (self.burntime < time) {
            self.burntime = time + 0.7;
            if (self.waterlevel < 3) {
                sound(self, CHAN_AUX1, "shared/frying.wav", 1, ATTN_NORM);
            }
            else {
                sound(self, CHAN_WALK, "shared/frying2.wav", 1, ATTN_NORM);
            }
        }
        if (self.dmgtime < time && self.radsuit_finished < time) {
            self.dmgtime = time + 1;
            self.deathtype = "slime";
            T_Damage(self, world, world, 4*self.waterlevel);
        }
    }

    if ( !(self.flags & FL_INWATER) ) {

        // player enter water sound

        self.wadetime = time + 0.8; // will set the next sloosh noise

        if (self.watertype == CONTENT_LAVA) {
            sound(self, CHAN_BODY, "player/inlava.wav", 1, ATTN_NORM);
        }
        if (self.watertype == CONTENT_WATER) {
            sound(self, CHAN_BODY, "player/inh2o.wav", 1, ATTN_NORM);
        }
        if (self.watertype == CONTENT_SLIME) {
            sound(self, CHAN_BODY, "player/slimbrn2.wav", 1, ATTN_NORM);
        }
        self.flags = self.flags + FL_INWATER;
        self.dmgtime = 0;
    }

    if (! (self.flags & FL_WATERJUMP) ) {
        self.velocity = self.velocity - 0.8 * self.waterlevel * frametime * self.velocity;
    }
};

//---------------------------------------------------------------------------

void() CheckWaterJump = {
    local vector start, end;

    // check for a jump-out-of-water
    makevectors(self.angles);
    start       = self.origin;
    start_z     = start_z + 8;
    v_forward_z = 0;
    normalize(v_forward);
    end = start + v_forward*24;
    traceline(start, end, TRUE, self);
    if (trace_fraction < 1) {
        // solid at waist
        start_z      = start_z + self.maxs_z - 8;
        end          = start + v_forward*24;
        self.movedir = trace_plane_normal * -50;
        traceline (start, end, TRUE, self);
        if (trace_fraction == 1) {
            // open at eye level
            self.flags         = self.flags | FL_WATERJUMP;
            self.velocity_z    = 225;
            self.flags         = self.flags - (self.flags & FL_JUMPRELEASED);
            self.teleport_time = time + 2;   // safety net
            return;
        }
    }
};


//===========================================================================
//
//   PlayerPreThink : Called every frame before physics are run
//
//===========================================================================

void() PlayerPreThink = {
    local float mspeed, aspeed;
    local float r;

    if (intermission_running) {
        IntermissionThink();   // otherwise a button could be missed between
        return;              // the think tics
    }

    if (self.view_ofs == VEC_ZERO) {
        return;     // intermission or finale
    }

    makevectors(self.v_angle);      // is this still used

    CheckRules();
    WaterMove();

    if (self.waterlevel == 2) {
        CheckWaterJump();
    }

    if (self.deadflag >= DEAD_DEAD) {
        PlayerDeathThink();
        return;
    }

    if (self.deadflag == DEAD_DYING) {
        return;  // dying, so do nothing
    }

    if (self.button2) {
        PlayerJump();
    }
    else {
        self.flags = self.flags | FL_JUMPRELEASED;
    }

    // teleporters can force a non-moving pause time
    if (time < self.pausetime) {
        self.velocity = VEC_ZERO;
    }

    if (
        time > self.attack_finished &&
        self.currentammo == 0 &&
        self.weapon != IT_AXE
    ) {
        self.weapon = W_BestWeapon();
        W_SetCurrentAmmo();
    }
};


//===========================================================================
//
//   CheckPowerups : Check for turning off powerups
//
//===========================================================================

void() CheckPowerups = {
    if (self.health <= 0) {
        return;
    }
    // invisibility
    if (self.invisible_finished) {
        // sound and screen flash when items starts to run out
        if (self.invisible_sound < time) {
            sound(self, CHAN_AUTO, "items/inv3.wav", 0.5, ATTN_IDLE);
            self.invisible_sound = time + ((random() * 3) + 1);
        }

        if (self.invisible_finished < time + 3) {
            if (self.invisible_time == 1) {
                sprint(self, "Ring of Shadows magic is fading\n");
                stuffcmd(self, "bf\n");
                sound(self, CHAN_AUTO, "items/inv2.wav", 1, ATTN_NORM);
                self.invisible_time = time + 1;
            }

            if (self.invisible_time < time) {
                self.invisible_time = time + 1;
                stuffcmd (self, "bf\n");
            }
        }

        if (self.invisible_finished < time) {
            // just stopped
            self.items              = self.items - IT_INVISIBILITY;
            self.invisible_finished = 0;
            self.invisible_time     = 0;
        }

        // use the eyes
        self.frame = 0;
        self.modelindex = modelindex_eyes;
    }
    else {
        self.modelindex = self.index_player;   // don't use eyes
    }

    // invincibility
    if (self.invincible_finished) {
        // sound and screen flash when items starts to run out
        if (self.invincible_finished < time + 3) {
            if (self.invincible_time == 1) {
                sprint(self, "Protection is almost burned out\n");
                stuffcmd(self, "bf\n");
                sound(self, CHAN_AUTO, "items/protect2.wav", 1, ATTN_NORM);
                self.invincible_time = time + 1;
            }

            if (self.invincible_time < time) {
                self.invincible_time = time + 1;
                stuffcmd(self, "bf\n");
            }
        }

        if (self.invincible_finished < time) {
            // just stopped
            self.items               = self.items - IT_INVULNERABILITY;
            self.invincible_time     = 0;
            self.invincible_finished = 0;
        }
        if (self.invincible_finished > time) {
            self.effects = self.effects | (FX_GLOW & effectflags);
        }
        else {
            self.effects = self.effects - (self.effects & FX_GLOW);
        }
    }

    // super damage
    if (self.super_damage_finished) {

        // sound and screen flash when items starts to run out

        if (self.super_damage_finished < time + 3) {
            if (self.super_time == 1) {
                sprint(self, "Quad Damage is wearing off\n");
                stuffcmd(self, "bf\n");
                sound(self, CHAN_AUTO, "items/damage2.wav", 1, ATTN_NORM);
                self.super_time = time + 1;
            }

            if (self.super_time < time) {
                self.super_time = time + 1;
                stuffcmd(self, "bf\n");
            }
        }

        if (self.super_damage_finished < time) {
            // just stopped
            self.items = self.items - IT_QUAD;
            self.super_damage_finished = 0;
            self.super_time = 0;
        }
        if (self.super_damage_finished > time) {
            self.effects = self.effects | (FX_GLOW & effectflags);
        }
        else {
            self.effects = self.effects - (self.effects & FX_GLOW);
        }
    }

    // suit
    if (self.radsuit_finished) {
        self.air_finished = time + 12;      // don't drown

        // sound and screen flash when items starts to run out
        if (self.radsuit_finished < time + 3) {
            if (self.rad_time == 1) {
                sprint(self, "Air supply in Biosuit expiring\n");
                stuffcmd(self, "bf\n");
                sound(self, CHAN_AUTO, "items/suit2.wav", 1, ATTN_NORM);
                self.rad_time = time + 1;
            }

            if (self.rad_time < time) {
                self.rad_time = time + 1;
                stuffcmd (self, "bf\n");
            }
        }

        if (self.radsuit_finished < time) {
            // just stopped
            self.items = self.items - IT_SUIT;
            self.rad_time = 0;
            self.radsuit_finished = 0;
        }
    }

    if (self.items & IT_SUIT) {
        if (time > self.suitbreathtime) {
            self.suitbreathtime = time + 2 + random();
            if (self.breath == "shared/inhale.wav") {
                if (self.waterlevel > 2) {
                    self.breath = "shared/w_exhale.wav";
                    DeathBubbles(2);
                }
                else {
                    self.breath = "shared/exhale.wav";
                }
            }
            else {
                self.breath = "shared/inhale.wav";
            }
            sound(self, CHAN_VOICE, self.breath, 1, ATTN_NORM);
        }
    }

};

//===========================================================================
//
//   PlayerPostThink : Called every frame after physics are run
//
//===========================================================================

void() PlayerPostThink = {
    local float mspeed, aspeed, r, falldist;

    if (self.view_ofs == VEC_ZERO) {
        return;     // intermission or finale
    }

    if (self.deadflag) {
        return;
    }

    // do weapon stuff
    W_WeaponFrame();

    // check to see if player landed and play landing sound
    if (
        (self.jump_flag < -300) &&
        (self.flags & FL_ONGROUND) &&
        (self.health > 0)
    ) {
        if (self.watertype == CONTENT_WATER) {
            sound(self, CHAN_BODY, "player/h2ojump.wav", 1, ATTN_NORM);
        }
        else if (self.jump_flag < -650) {
            falldist = (fabs(self.jump_flag)) * 0.02;
            self.deathtype = "falling";
            T_Damage(self, world, world, falldist);
            particle(self.origin, '0 0 5', 8, 25);
            sound(self, CHAN_BODY, "demon/dland2.wav", 1, ATTN_NORM);
            if (self.health > 0) {
                if (!self.gender) {
                    sound(self, CHAN_VOICE, "player/land2.wav", 1, ATTN_NORM);
                }
                else {
                    sound(self, CHAN_VOICE, "f_player/land2.wav", 1, ATTN_NORM);
                }
            }
            else {
                DeathSound();
            }
        }
        else {
            sound(self, CHAN_BODY, "demon/dland2.wav", 0.5, ATTN_NORM);
            if (!self.gender) {
                sound(self, CHAN_VOICE, "player/land.wav", 1, ATTN_NORM);
            }
            else {
                sound(self, CHAN_VOICE, "f_player/land.wav", 1, ATTN_NORM);
            }
        }

        self.jump_flag = 0;
    }

    if (!(self.flags & FL_ONGROUND)) {
        self.jump_flag = self.velocity_z;
    }

    CheckPowerups();
};


//===========================================================================
//
//   ClientConnect : called when a player connects to a server
//
//===========================================================================

void() ClientConnect = {

    // individual player preferences - each name can have unique prefs
    //stuffcmd(self, "exec players/");
    //stuffcmd(self, self.netname);
    //stuffcmd(self, ".cfg\n");

    bprint2(self.netname, " has entered the game\n");

    if (clientcount == 0) {
        create_server_key();
        self.server_master = CL_ADMIN;
        self.server_access = CL_SERVER_ACCESS;
        set_server_opts();
    }

    // get the client's config data

    self.cl_color = cvar("_cl_color");
    set_client_extraparms();
    clientcount = clientcount + 1;

    // a client connecting during an intermission can cause problems
    if (intermission_running) {
        ExitIntermission();
    }
};


//===========================================================================
//
//   ClientDisconnect :  called when a player disconnects from a server
//
//===========================================================================

void() ClientDisconnect = {
    local string score;

    if (gameover) {
        // if the level end trigger has been activated, just return
        // since they aren't *really* leaving
        return;
    }
    clientcount = clientcount - 1;
    score       = ftos(self.frags);

    // let everyone else know
    bprint4(self.netname, " left the game with ", score, " frags\n");
    sound(self, CHAN_BODY, "player/tornoff2.wav", 1, ATTN_NONE);
    set_suicide_frame();
};
