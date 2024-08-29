// defs.qc
/*---public---*/
// $VER: defs.qc 2.00 Karlos '99 (14/07/1999)
/*---private---*/

/*==============================================================================
   SOURCE FOR GLOBALVARS_T C STRUCTURE

   Modified by Karlos

      Added EDICT_EXPIRE constant for timeout removable objects (ie corpses)
      Added dynamiclight global variable (bitmask for effects enable)
      Added CHAN_WALK, CHAN_AUX1 and CHAN_AUX2 sound channel definitions

      Added new impulse directives
         cheats
         camera functions
         skin settings...

==============================================================================*/

//
// system globals
//
entity   self;
entity   other;
entity   world;
float    time;
float    frametime;

float    force_retouch;    // force all entities to touch triggers
                           // next frame.  this is needed because
                           // non-moving things don't normally scan
                           // for triggers, and when a trigger is
                           // created (like a teleport trigger), it
                           // needs to catch everything.
                           // decremented each frame, so set to 2
                           // to guarantee everything is touched
string   mapname;

float    deathmatch;
float    coop;
float    teamplay;

float    serverflags;      // propagated from level to level, used to
                           // keep track of completed episodes

float    total_secrets;
float    total_monsters;

float    found_secrets;    // number of secrets found
float    killed_monsters;  // number of monsters killed


// spawnparms are used to encode information about clients across server
// level changes
float    parm1, parm2, parm3, parm4, parm5, parm6, parm7, parm8, parm9, parm10, parm11, parm12, parm13, parm14, parm15, parm16;

//
// global variables set by built in functions
//
vector      v_forward, v_up, v_right;  // set by makevectors()

// set by traceline / tracebox
float    trace_allsolid;
float    trace_startsolid;
float    trace_fraction;
vector   trace_endpos;
vector   trace_plane_normal;
float    trace_plane_dist;
entity   trace_ent;
float    trace_inopen;
float    trace_inwater;

entity   msg_entity;          // destination of single entity writes

//
// required prog functions
//
void()      main;                // only for testing

void()      StartFrame;

void()      PlayerPreThink;
void()      PlayerPostThink;

void()      ClientKill;
void()      ClientConnect;
void()      PutClientInServer;   // call after setting the parm1... parms
void()      ClientDisconnect;

void()      SetNewParms;         // called when a client first connects to
                                 // a server. sets parms so they can be
                                 // saved off for restarts

void()      SetChangeParms;      // call to set parms for self so they can
                                 // be saved for a level transition


//================================================
void     end_sys_globals;     // flag for structure dumping
//================================================

/*
==============================================================================

         SOURCE FOR ENTVARS_T C STRUCTURE

==============================================================================
*/

//
// system fields (*** = do not set in prog code, maintained by C code)
//
.float      modelindex;    // *** model index in the precached list
.vector     absmin, absmax;   // *** origin + mins / maxs

.float      ltime;         // local time for entity
.float      movetype;
.float      solid;

.vector     origin;        // ***
.vector     oldorigin;     // ***
.vector     velocity;
.vector     angles;
.vector     avelocity;

.vector     punchangle;    // temp angle adjust from damage or recoil

.string     classname;     // spawn function
.string     model;
.float      frame;
.float      skin;
.float      effects;

.vector     mins, maxs;    // bounding box extents reletive to origin
.vector     size;          // maxs - mins

.void()     touch;
.void()     use;
.void()     think;
.void()     blocked;       // for doors or plats, called when can't push other

.float      nextthink;
.entity     groundentity;

// stats
.float      health;
.float      frags;
.float      weapon;        // one of the IT_SHOTGUN, etc flags
.string     weaponmodel;
.float      weaponframe;
.float      currentammo;
.float      ammo_shells, ammo_nails, ammo_rockets, ammo_cells;

.float      items;         // bit flags

.float      takedamage;
.entity     chain;
.float      deadflag;

.vector     view_ofs;      // add to origin to get eye point


.float      button0;       // fire
.float      button1;       // use
.float      button2;       // jump

.float      impulse;       // weapon changes

.float      fixangle;
.vector     v_angle;       // view / targeting angle for players
.float      idealpitch;    // calculated pitch angle for lookup up slopes

.string     netname;

.entity  enemy;

.float      flags;

.float      colormap;
.float      team;

.float      max_health;    // players maximum health is stored here

.float      teleport_time; // don't back up

.float      armortype;     // save this fraction of incoming damage
.float      armorvalue;

.float      waterlevel;    // 0 = not in, 1 = feet, 2 = wast, 3 = eyes
.float      watertype;     // a contents value

.float      ideal_yaw;
.float      yaw_speed;

.entity     aiment;

.entity  goalentity;       // a movetarget or an enemy

.float      spawnflags;

.string     target;
.string     targetname;

// damage is accumulated through a frame. and sent as one single
// message, so the super shotgun doesn't generate huge messages
.float      dmg_take;
.float      dmg_save;
.entity     dmg_inflictor;

.entity     owner;      // who launched a missile
.vector     movedir;    // mostly for doors, but also used for waterjump

.string     message;    // trigger messages

.float      sounds;     // either a cd track number or sound number

.string     noise, noise1, noise2, noise3;   // contains names of wavs to play

//================================================
void     end_sys_fields;         // flag for structure dumping
//================================================

/*==============================================================================

            VARS NOT REFERENCED BY C CODE

==============================================================================*/


//
// constants
//

float FALSE                = 0;
float TRUE                 = 1;

// edict.flags
float FL_FLY               = 1;
float FL_SWIM              = 2;
float FL_CLIENT            = 8;     // set for all client edicts
float FL_INWATER           = 16;    // for enter / leave water splash
float FL_MONSTER           = 32;    // monster, monster....
float FL_GODMODE           = 64;    // player cheat
float FL_NOTARGET          = 128;   // player cheat
float FL_ITEM              = 256;   // extra wide size for bonus items
float FL_ONGROUND          = 512;   // standing on something
float FL_PARTIALGROUND     = 1024;  // not all corners are valid
float FL_WATERJUMP         = 2048;  // player jumping out of water
float FL_JUMPRELEASED      = 4096;  // for jump debouncing
float FL_CANTPUSH          = 8192;  // used to specify if an entity can push another

float ENTITY_MAX = 420; // max number of entities ?

// edict.movetype values
float MOVETYPE_NONE        = 0;  // never moves
//float  MOVETYPE_ANGLENOCLIP = 1;
//float  MOVETYPE_ANGLECLIP      = 2;
float MOVETYPE_WALK           = 3;  // players only
float MOVETYPE_STEP           = 4;  // discrete, not real time unless fall
float MOVETYPE_FLY            = 5;
float MOVETYPE_TOSS           = 6;  // gravity
float MOVETYPE_PUSH           = 7;  // no clip to world, push and crush
float MOVETYPE_NOCLIP         = 8;
float MOVETYPE_FLYMISSILE     = 9;  // fly with extra size against monsters
float MOVETYPE_BOUNCE         = 10;
float MOVETYPE_BOUNCEMISSILE  = 11; // bounce with extra size
// edict.solid values
float SOLID_NOT            = 0;  // no interaction with other objects
float SOLID_TRIGGER        = 1;  // touch on edge, but not blocking
float SOLID_BBOX           = 2;  // touch on edge, block
float SOLID_SLIDEBOX       = 3;  // touch on edge, but not an onground
float SOLID_BSP            = 4;  // bsp clip, touch on edge, block

// point content values
float CONTENT_EMPTY        = -1;
float CONTENT_SOLID        = -2;
float CONTENT_WATER        = -3;
float CONTENT_SLIME        = -4;
float CONTENT_LAVA         = -5;
float CONTENT_SKY          = -6;

// sound channels
// channel 0 never willingly overrides
// other channels (1-7) always override a playing sound on that channel
float CHAN_AUTO      = 0;
float CHAN_WEAPON    = 1;
float CHAN_VOICE     = 2;
float CHAN_ITEM      = 3;
float CHAN_BODY      = 4;
float CHAN_WALK      = 5;  // Karlos - reserved for footstep sounds
float CHAN_AUX1      = 6;  // Karlos - undefined
float CHAN_AUX2      = 7;  // Karlos - undefined

// attenuation constants
float ATTN_NONE      = 0;
float ATTN_NORM      = 1;
float ATTN_IDLE      = 2;
float ATTN_STATIC    = 3;

// range values
float RANGE_MELEE          = 0;
float RANGE_NEAR           = 1;
float RANGE_MID            = 2;
float RANGE_FAR            = 3;

// deadflag values

float DEAD_NO              = 0;
float DEAD_DYING           = 1;
float DEAD_DEAD            = 2;
float DEAD_RESPAWNABLE     = 3;

// takedamage values
float DAMAGE_NO            = 0;
float DAMAGE_YES           = 1;
float DAMAGE_AIM           = 2;

// items
float IT_AXE               = 4096;
float IT_SHOTGUN           = 1;
float IT_SUPER_SHOTGUN     = 2;
float IT_NAILGUN           = 4;
float IT_SUPER_NAILGUN     = 8;
float IT_GRENADE_LAUNCHER  = 16;
float IT_ROCKET_LAUNCHER   = 32;
float IT_LIGHTNING         = 64;
float IT_EXTRA_WEAPON      = 128;
float IT_IS_A_WEAPON       = 4351;
float IT_SHELLS            = 256;
float IT_NAILS             = 512;
float IT_ROCKETS           = 1024;
float IT_CELLS             = 2048;

float IT_ARMOR1            = 8192;
float IT_ARMOR2            = 16384;
float IT_ARMOR3            = 32768;
float IT_SUPERHEALTH       = 65536;

float IT_KEY1              = 131072;
float IT_KEY2              = 262144;

float IT_INVISIBILITY      = 524288;
float IT_INVULNERABILITY   = 1048576;
float IT_SUIT              = 2097152;
float IT_QUAD              = 4194304;
float IT_POWERUP           = 7864320; // mask for any of the powerup items
float IT_GRAPPLING_HOOK    = 8388608; // modified the rocket launcher if set

float STATE_TOP            = 0;
float STATE_BOTTOM         = 1;
float STATE_UP             = 2;
float STATE_DOWN           = 3;

vector   VEC_ZERO        = '0 0 0';
vector   VEC_HULL_MIN      = '-16 -16 -24';
vector   VEC_HULL_MAX      = '16 16 32';

vector   VEC_HULL2_MIN     = '-32 -32 -24';
vector   VEC_HULL2_MAX     = '32 32 64';

// protocol bytes
float SVC_SETVIEWPORT      = 5;  // camera
float SVC_SETVIEWANGLES    = 10; // camera
float SVC_TEMPENTITY       = 23;
float SVC_KILLEDMONSTER    = 27;
float SVC_FOUNDSECRET      = 28;
float SVC_INTERMISSION     = 30;
float SVC_FINALE           = 31;
float SVC_CDTRACK          = 32;
float SVC_SELLSCREEN       = 33;

// temporary enities
float TE_SPIKE             = 0;
float TE_SUPERSPIKE        = 1;
float TE_GUNSHOT           = 2;
float TE_EXPLOSION         = 3;
float TE_TAREXPLOSION      = 4;
float TE_LIGHTNING1        = 5;
float TE_LIGHTNING2        = 6;
float TE_WIZSPIKE          = 7;
float TE_KNIGHTSPIKE       = 8;
float TE_LIGHTNING3        = 9;
float TE_LAVASPLASH        = 10;
float TE_TELEPORT          = 11;

// update types

float UPDATE_GENERAL = 0;
float UPDATE_STATIC  = 1;
float UPDATE_BINARY  = 2;
float UPDATE_TEMP    = 3;

//-----------------------------------------------------------------------------------------

// messages
float MSG_BROADCAST  = 0;     // unreliable to all
float MSG_ONE        = 1;     // reliable to one (msg_entity)
float MSG_ALL        = 2;     // reliable to all
float MSG_INIT       = 3;     // write to the init string

//=====================================================================================
//
//    Globals
//
//=====================================================================================

float    movedist;
float    gameover;               // set when a rule exits
float    framecount;             // number of frames calculated

float    skill;                  // global skill set (integer only)

string   string_null;            // null string, nothing should be held here
float    empty_float;
entity   newmis;                 // launch_spike sets this after spawning it
entity   activator;              // the entity that activated a trigger or brush
entity   damage_attacker;        // set by T_Damage
float    intermission_running;   // moved from client.qc
float    intermission_exittime;  // moved from client.qc

/*
string   skin_name01;            // Karlos - used for defining names of
string   skin_name02;            // up to 32 player skins...
string   skin_name03;
string   skin_name04;
string   skin_name05;
string   skin_name06;
string   skin_name07;
string   skin_name08;
string   skin_name09;
string   skin_name10;
string   skin_name11;
string   skin_name12;
string   skin_name13;
string   skin_name14;
string   skin_name15;
string   skin_name16;
string   skin_name17;
string   skin_name18;
string   skin_name19;
string   skin_name20;
string   skin_name21;
string   skin_name22;
string   skin_name23;
string   skin_name24;
string   skin_name25;
string   skin_name26;
string   skin_name27;
string   skin_name28;
string   skin_name29;
string   skin_name30;
string   skin_name31;
string   skin_name32;
*/

//=====================================================================================
//
//    world fields (FIXME: make globals)
//
//=====================================================================================
.string     wad;
.string     map;
.float      worldtype;  // 0=medieval 1=metal 2=base


.string     killtarget;

//
// quakeed fields
//
.float      light_lev;     // not used by game, but parsed by light util
.float      style;


//
// monster ai
//
.void()     th_stand;
.void()     th_walk;
.void()     th_run;
.void()     th_missile;
.void()     th_melee;
.void(entity attacker, float damage)      th_pain;
.void()     th_die;

.void()     th_alerted;
.float()    check_attack;

.entity  oldenemy;      // mad at this player before taking damage

.float   speed;

.float   lefty;

.float   search_time;
.float   attack_state;

float AS_STRAIGHT    = 1;
float AS_SLIDING     = 2;
float AS_MELEE       = 3;
float AS_MISSILE     = 4;

// special radio messages for grunt / enforcer...
float SAY_ENEMY_SIGHTED = 1;
float SAY_DESTROY_GREEN = 2;
float SAY_ROGER        = 3;
float SAY_ENEMY_DOWN    = 4;

//
// player only fields
//
.float      walkframe;

.float      attack_finished;
.float      pain_finished;

.float      invincible_finished;
.float      invisible_finished;
.float      super_damage_finished;
.float      radsuit_finished;

.float      invincible_time, invincible_sound;
.float      invisible_time, invisible_sound;
.float      super_time, super_sound;
.float      rad_time;
.float      fly_sound;

.float      axhitme;

.float      show_hostile;  // set to time+0.2 whenever a client fires a
                           // weapon or takes damage.  Used to alert
                           // monsters that otherwise would let the player go

.float      jump_flag;     // player jump flag
.float      swim_flag;     // player swimming sound flag
.float      air_finished;  // when time > air_finished, start drowning
.float      bubble_count;  // keeps track of the number of bubbles
.string     deathtype;     // keeps track of how the player died

//
// object stuff
//
.string     mdl;
.vector     mangle;        // angle at start

.vector     oldorigin;     // only used by secret door

.float      t_length, t_width;


//
// doors, etc
//
.vector     dest, dest1, dest2;
.float      wait;                // time from firing to restarting
.float      delay;               // time from activation to firing
.entity     trigger_field;       // door's trigger entity
.string     noise4;

//
// monsters
//
.float      pausetime;
.entity     movetarget;


//
// doors
//
.float      aflag;
.float      dmg;        // damage done by door when hit

//
// misc
//
.float      cnt;        // misc flag

//
// subs
//
.void()     think1;
.vector     finaldest, finalangle;

//
// triggers
//
.float      count;         // for counting triggers



//
// plats / doors / buttons
//
.float      lip;
.float      state;
.vector     pos1, pos2;    // top and bottom positions
.float      height;

//
// sounds
//
.float      waitmin, waitmax;
.float      distance;
.float      volume;
.float      sound_inhibit_time;

//===========================================================================
