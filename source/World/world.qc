// world.qc
/*---public---*/
// $VER: world.qc 1.85 � Karlos '99 (10/10/1999)

void() worldspawn;
void() StartFrame ;
void(entity ent) CopyToBodyQue;

/*---private---*/
void() main;
void() bodyque;
void() InitBodyQue;

/*=========================================================================================

   WORLD

      Modified by Karlos

      1) Added sound precache for new shared sounds...
      2) Defined worldspawn.deadflag as DEAD_DEAD - stops monsters
         being angry at world...
      3) Added level configuration script handling. Any level can now have a unique
         configuration file stored in maps/

=========================================================================================*/

// prototypes

//=======================================================================================
//
//   main() : used by qcc to build pak files (I dont use it)
//
//=======================================================================================
void() main = {
    dprint("main function\n");

    // these are just commands the the prog compiler to copy these files

    precache_file("progs.dat");
    precache_file("gfx.wad");
    precache_file("quake.rc");
    precache_file("default.cfg");

    precache_file("end1.bin");
    precache_file2("end2.bin");

    precache_file("demo1.dem");
    precache_file("demo2.dem");
    precache_file("demo3.dem");

    // these are all of the lumps from the cached.ls files
    precache_file("gfx/palette.lmp");
    precache_file("gfx/colormap.lmp");

    precache_file2("gfx/pop.lmp");

    precache_file("gfx/complete.lmp");
    precache_file("gfx/inter.lmp");

    precache_file("gfx/ranking.lmp");
    precache_file("gfx/vidmodes.lmp");
    precache_file("gfx/finale.lmp");
    precache_file("gfx/conback.lmp");
    precache_file("gfx/qplaque.lmp");

    precache_file("gfx/menudot1.lmp");
    precache_file("gfx/menudot2.lmp");
    precache_file("gfx/menudot3.lmp");
    precache_file("gfx/menudot4.lmp");
    precache_file("gfx/menudot5.lmp");
    precache_file("gfx/menudot6.lmp");

    precache_file("gfx/menuplyr.lmp");
    precache_file("gfx/bigbox.lmp");
    precache_file("gfx/dim_modm.lmp");
    precache_file("gfx/dim_drct.lmp");
    precache_file("gfx/dim_ipx.lmp");
    precache_file("gfx/dim_tcp.lmp");
    precache_file("gfx/dim_mult.lmp");
    precache_file("gfx/mainmenu.lmp");

    precache_file("gfx/box_tl.lmp");
    precache_file("gfx/box_tm.lmp");
    precache_file("gfx/box_tr.lmp");

    precache_file("gfx/box_ml.lmp");
    precache_file("gfx/box_mm.lmp");
    precache_file("gfx/box_mm2.lmp");
    precache_file("gfx/box_mr.lmp");

    precache_file("gfx/box_bl.lmp");
    precache_file("gfx/box_bm.lmp");
    precache_file("gfx/box_br.lmp");

    precache_file("gfx/sp_menu.lmp");
    precache_file("gfx/ttl_sgl.lmp");
    precache_file("gfx/ttl_main.lmp");
    precache_file("gfx/ttl_cstm.lmp");

    precache_file("gfx/mp_menu.lmp");

    precache_file("gfx/netmen1.lmp");
    precache_file("gfx/netmen2.lmp");
    precache_file("gfx/netmen3.lmp");
    precache_file("gfx/netmen4.lmp");
    precache_file("gfx/netmen5.lmp");

    precache_file("gfx/sell.lmp");

    precache_file("gfx/help0.lmp");
    precache_file("gfx/help1.lmp");
    precache_file("gfx/help2.lmp");
    precache_file("gfx/help3.lmp");
    precache_file("gfx/help4.lmp");
    precache_file("gfx/help5.lmp");

    precache_file("gfx/pause.lmp");
    precache_file("gfx/loading.lmp");

    precache_file("gfx/p_option.lmp");
    precache_file("gfx/p_load.lmp");
    precache_file("gfx/p_save.lmp");
    precache_file("gfx/p_multi.lmp");

    // sounds loaded by C code
    precache_sound("misc/menu1.wav");
    precache_sound("misc/menu2.wav");
    precache_sound("misc/menu3.wav");

    precache_sound("ambience/water1.wav");
    precache_sound("ambience/wind2.wav");

    // shareware
    precache_file("maps/start.bsp");
    precache_file("maps/e1m1.bsp");
    precache_file("maps/e1m2.bsp");
    precache_file("maps/e1m3.bsp");
    precache_file("maps/e1m4.bsp");
    precache_file("maps/e1m5.bsp");
    precache_file("maps/e1m6.bsp");
    precache_file("maps/e1m7.bsp");
    precache_file("maps/e1m8.bsp");

    // registered
    precache_file2("gfx/pop.lmp");

    precache_file2("maps/e2m1.bsp");
    precache_file2("maps/e2m2.bsp");
    precache_file2("maps/e2m3.bsp");
    precache_file2("maps/e2m4.bsp");
    precache_file2("maps/e2m5.bsp");
    precache_file2("maps/e2m6.bsp");
    precache_file2("maps/e2m7.bsp");

    precache_file2("maps/e3m1.bsp");
    precache_file2("maps/e3m2.bsp");
    precache_file2("maps/e3m3.bsp");
    precache_file2("maps/e3m4.bsp");
    precache_file2("maps/e3m5.bsp");
    precache_file2("maps/e3m6.bsp");
    precache_file2("maps/e3m7.bsp");

    precache_file2("maps/e4m1.bsp");
    precache_file2("maps/e4m2.bsp");
    precache_file2("maps/e4m3.bsp");
    precache_file2("maps/e4m4.bsp");
    precache_file2("maps/e4m5.bsp");
    precache_file2("maps/e4m6.bsp");
    precache_file2("maps/e4m7.bsp");
    precache_file2("maps/e4m8.bsp");

    precache_file2("maps/end.bsp");

    precache_file2("maps/dm1.bsp");
    precache_file2("maps/dm2.bsp");
    precache_file2("maps/dm3.bsp");
    precache_file2("maps/dm4.bsp");
    precache_file2("maps/dm5.bsp");
    precache_file2("maps/dm6.bsp");
};



//=======================================================================================
//   QUAKED worldspawn (0 0 0) ?
//   Only used for the world entity.
//   Set message to the level name.
//   Set sounds to the cd track to play.
//
//   World Types:
//   0: medieval
//   1: metal
//   2: base
//
//=======================================================================================

void() worldspawn = {
    local float fixed_lights, multiplayer, sp_gender;

    // set up world attributes
    lastspawn     = world;
    self.deadflag = DEAD_DEAD;             // world itself is inanimate
    self.flags    = self.flags | FL_CANTPUSH; // pushable entites should be stopped by world

    // set up world definition for team ai

    self.ai_team_id = TEAM_WORLD;

    InitBodyQue();

    // get light fx info for world

    fixed_lights = cvar("registered") & (FX_WORLDSTATIC * FX_SAVEBITS_OFFSET);

    // set random game before monster spawning
    randomgame   = cvar("registered") & GAME_RANDOM;

    // get player gender for single player - we can use this info to reduce the
    // amount of data that has to be precached
    multiplayer  = cvar("coop") + cvar("deathmatch");
    sp_gender    = cvar("temp1") & CL_GENDERBIT;

    // the area based ambient sounds MUST be the first precache_sounds
    // player precaches
    W_Precache();       // get weapon precaches

    // sounds used from C physics code
    precache_sound("demon/dland2.wav");      // landing thud
    precache_sound("misc/h2ohit1.wav");      // landing splash

    // Karlos extra sounds
    precache_sound("shared/hardstep1.wav");  // footsteps
    precache_sound("shared/hardstep2.wav");
    precache_sound("shared/hardstep3.wav");
    precache_sound("shared/wade1.wav");
    precache_sound("shared/wade2.wav");
    precache_sound("shared/wade3.wav");
    precache_sound("shared/corpsehit1.wav"); // sounds of corpses getting knackered
    precache_sound("shared/corpsehit2.wav");
    precache_sound("shared/meat.wav");       // meaty mess...
    //precache_sound ("shared/splat.wav");

    // setup precaches always needed
    precache_sound("items/itembk2.wav");     // item respawn sound
    precache_sound("misc/switch.wav");    // player torch
    precache_sound("misc/laser_activated.wav");  // guidance on
    precache_sound("misc/laser_deactivated.wav");// guidance off
    precache_sound("misc/message2.wav");         // fullscreen message sounds
    precache_sound("misc/msg_warning.wav");      // fullscreen warning sound

    // player physics sounds...
    if (multiplayer != 0) {
        dprint("Caching both sexes\n");
        // there can be > 1 client, so precache both sexes
        precache_male();
        precache_female();
    }
    else {
        // single player game, precache relevent gender only
        if (!sp_gender) {
            // player character is male
            precache_male();
        }
        else {
            // player character is female
            precache_female();
        }
    }

    inv_prefetch(); // get sounds for items not present in level
                            // but in possesion of player

    precache_sound("misc/talk.wav");         // talk
    precache_sound("player/teledth1.wav");   // telefrag
    precache_sound("misc/r_tele1.wav");      // teleport sounds
    precache_sound("misc/r_tele2.wav");
    precache_sound("misc/r_tele3.wav");
    precache_sound("misc/r_tele4.wav");
    precache_sound("misc/r_tele5.wav");
    precache_sound("weapons/lock4.wav");     // ammo pick up
    precache_sound("weapons/pkup.wav");      // weapon up
    precache_sound("items/armor1.wav");      // armor up
    precache_sound("weapons/lhit.wav");      // lightning
    precache_sound("weapons/lstart.wav");    // lightning start

    precache_sound("misc/power.wav");        //lightning for boss
    precache_sound("boss1/out1.wav");

    // player gib sounds
    precache_sound("player/gib.wav");        // player gib sound
    precache_sound("player/udeath.wav");     // player gib sound
    precache_sound("player/tornoff2.wav");   // gib sound

    // player sounds
    precache_sound("player/h2ojump.wav");    // player jumping into water
    precache_sound("player/slimbrn2.wav");   // player enter slime
    precache_sound("player/inh2o.wav");      // player enter water
    precache_sound("player/inlava.wav");     // player enter lava
    precache_sound("shared/frying.wav");     // player frying in slime etc.- karlos
    precache_sound("shared/frying2.wav");    // player frying immersed slime etc.- karlos
    precache_sound("misc/outwater.wav");     // leaving water sound

    precache_sound("misc/water1.wav");       // swimming
    precache_sound("misc/water2.wav");       // swimming

    precache_model("progs/player.mdl");      // normal player (needs precaching, it seems)
    precache_model("progs/camera.mdl");      // chase camera model
    precache_model("progs/eyes.mdl");
    precache_model("progs/h_player.mdl");
    precache_model("progs/gib1.mdl");
    precache_model("progs/gib2.mdl");
    precache_model("progs/gib3.mdl");

    precache_model("progs/s_bubble.spr"); // drowning bubbles
    precache_model("progs/s_explod.spr"); // sprite explosion

    precache_model("progs/v_axe.mdl");
    precache_model("progs/v_shot.mdl");
    precache_model("progs/v_nail.mdl");
    precache_model("progs/v_rock.mdl");
    precache_model("progs/v_shot2.mdl");
    precache_model("progs/v_nail2.mdl");
    precache_model("progs/v_rock2.mdl");

    precache_model("progs/bolt.mdl");     // for lightning gun
    precache_model("progs/bolt2.mdl");    // for lightning gun
    precache_model("progs/bolt3.mdl");    // for boss shock
    precache_model("progs/lavaball.mdl"); // for testing

    precache_model("progs/missile.mdl");
    precache_model("progs/grenade.mdl");
    precache_model("progs/spike.mdl");
    precache_model("progs/s_spike.mdl");
    precache_model("progs/backpack.mdl");
    precache_model("progs/zom_gib.mdl");
    precache_model("progs/v_light.mdl");

    // grapple
    precache_model("progs/v_spike.mdl");     // used for grapple head
    precache_model("progs/chainlink.mdl");   // chain segment

    // Mikerules
    // droppable weapons
    precache_model("progs/g_shot.mdl");
    precache_model("progs/g_nail.mdl");
    precache_model("progs/g_nail2.mdl");
    precache_model("progs/g_rock.mdl");
    precache_model("progs/g_rock2.mdl");
    precache_model("progs/g_light.mdl");

    // execute global map configuration...
    localcmd("exec maps/worldinit.cfg\n");

    // do custom map config
    localcmd("exec ");
    localcmd(self.model);
    localcmd(".cfg\n");

    developer = cvar("developer");

    // read level options from developer cvar, if present
    if (cvar("precache") > 1) {
        map_opts = rint(cvar("precache")/2);
    }
    else {
        dprint("No team data for map, using defaults\n");
        // set default map options
        // maximum team size                 16    >> 16                         = 16
        // team dispersion                   0.25  >> (0.25 * 32) * 32           = 256
        // equivalent class tolerance        0.875 >> (0.875 * 32) * 32 * 32     = 28672
        // non-equivalent class tolerance    0.1875  >> (0.1875 * 32) * 32 * 32 * 32 = 196608
        map_opts = 225552;
    }

    set_light_tables(fixed_lights);
    if (cvar("deathmatch") == 0) {
        // initialize monsters in a non-deathmatch game
        clear_monster_caches();
        AI_TeamInit();
    }

    // Handle server master stuff
    if (!clientcount) {
        clientcount = 0;
    }

    // increment as clients are added.
    // server master will be first to connect, ie when client count = 0
    sound_que_channels_allocated = 1;
    entity_count                 = 1;    // world itself occupies an edict

    spawn_world_fx_manager();

    teamplay   = cvar("teamplay");
    skill_fact = cvar("skill");      // allow non-integer values for monster stats,
                                     // projectiles etc.
    skill      = rint(skill_fact);   // integer skill, for world settings
};

//=======================================================================================
//
//   StartFrame() : called at the start of each new frame
//
//=======================================================================================

void() StartFrame = {
    handle_sound_queue();
    framecount = framecount + 1;
};


//======================================================================================
//
//   BODY QUE
//
//======================================================================================
void() bodyque = {
   // just here so spawn functions don't complain after the world
   // creates bodyques
};

void() InitBodyQue = {
    local entity e;

    bodyque_head           = spawn();
    bodyque_head.classname = "bodyque";
    bodyque_head.owner           = spawn();
    bodyque_head.owner.classname = "bodyque";
    bodyque_head.owner.owner           = spawn();
    bodyque_head.owner.owner.classname = "bodyque";
    bodyque_head.owner.owner.owner           = spawn();
    bodyque_head.owner.owner.owner.classname = "bodyque";
    bodyque_head.owner.owner.owner.owner     = bodyque_head;
};

// make a body que entry for the given ent so the ent can be
// respawned elsewhere
void(entity ent) CopyToBodyQue = {
    bodyque_head.angles     = ent.angles;
    bodyque_head.model      = ent.model;
    bodyque_head.modelindex = ent.modelindex;
    bodyque_head.frame      = ent.frame;
    bodyque_head.colormap   = ent.colormap;
    bodyque_head.skin       = ent.skin;
    bodyque_head.movetype   = ent.movetype;
    bodyque_head.velocity   = ent.velocity;
    bodyque_head.flags      = 0;
    setorigin(bodyque_head, ent.origin);
    setsize(bodyque_head, ent.mins, ent.maxs);
    bodyque_head            = bodyque_head.owner;
};
