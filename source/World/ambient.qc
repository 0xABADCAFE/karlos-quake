// ambient.qc
/*---public---*/
// $VER: ambient.qc 2.00 © Karlos'99 (01/08/1999)
// public function prototypes
   void() ambient_comp_hum ;
   void() ambient_drip ;
   void() ambient_drone ;
   void() ambient_flouro_buzz ;
   void() ambient_light_buzz ;
   void() ambient_suck_wind ;
   void() ambient_swamp1 ;
   void() ambient_swamp2 ;
   void() ambient_thunder ;
   void() func_bossgate ;
   void() func_episodegate ;
   void() func_illusionary ;
   void() func_wall ;
   void() func_wall_use ;
   void() light ;
   void(float no_anim) set_light_tables;
   void() light_flame_large_yellow ;
   void() light_flame_small_white ;
   void() light_flame_small_yellow ;
   void() light_fluoro ;
   void() light_fluorospark ;
   void() light_globe ;
   void() light_torch_small_walltorch ;
   void() light_use ;
/*---private---*/
//========================================================================================
//
//   AMBIENT : MISCELLANEOUS WORLD LIGHT/SOUND/WIND FUNCTIONS
//
//========================================================================================

// QUAKED info_null (0 0.5 0) (-4 -4 -4) (4 4 4)
// Used as a positional target for spotlights, etc.

void() info_null =
{
   remove(self);
};


// QUAKED info_notnull (0 0.5 0) (-4 -4 -4) (4 4 4)
// Used as a positional target for lightning.

void() info_notnull =
{
};

void(float no_anim) set_light_tables =
{
   // 0 normal
   lightstyle(0, "m");
   if (!no_anim)
   {
      // 1 FLICKER (first variety)
      lightstyle(1, "mmnmmommommnonmmonqnmmo");
   
      // 2 SLOW STRONG PULSE
      lightstyle(2, "abcdefghijklmnopqrstuvwxyzyxwvutsrqponmlkjihgfedcba");
   
      // 3 CANDLE (first variety)
      lightstyle(3, "mmmmmaaaaammmmmaaaaaabcdefgabcdefg");
   
      // 4 FAST STROBE
      lightstyle(4, "mamamamamama");
   
      // 5 GENTLE PULSE 1
      lightstyle(5,"jklmnopqrstuvwxyzyxwvutsrqponmlkj");
   
      // 6 FLICKER (second variety)
      lightstyle(6, "nmonqnmomnmomomno");
   
      // 7 CANDLE (second variety)
      lightstyle(7, "mmmaaaabcdefgmmmmaaaammmaamm");
   
      // 8 CANDLE (third variety)
      lightstyle(8, "mmmaaammmaaammmabcdefaaaammmmabcdefmmmaaaa");
    
      // 9 SLOW STROBE (fourth variety)
      lightstyle(9, "aaaaaaaazzzzzzzz");
   
      // 10 FLUORESCENT FLICKER
      lightstyle(10, "mmamammmmammamamaaamammma");

      // 11 SLOW PULSE NOT FADE TO BLACK
      lightstyle(11, "abcdefghijklmnopqrrqponmlkjihgfedcba");
   }
   else
   {
      // all ambient lights fixed
      lightstyle(1,  "m");
      lightstyle(2,  "m");
      lightstyle(3,  "m");
      lightstyle(4,  "m");
      lightstyle(5,  "m");
      lightstyle(6,  "m");
      lightstyle(7,  "m");
      lightstyle(8,  "m");
      lightstyle(9,  "m");
      lightstyle(10, "e");
      lightstyle(11, "m");
   }
   // styles 32-62 are assigned by the light program for switchable lights
   // 63 testing
   lightstyle(63, "a");
};

//========================================================================================

void() light_use =
{
   if (self.spawnflags & START_OFF)
   {
      lightstyle(self.style, "m");
      self.spawnflags = self.spawnflags - START_OFF;
   }
   else
   {
      lightstyle(self.style, "a");
      self.spawnflags = self.spawnflags + START_OFF;
   }
};


// QUAKED light (0 1 0) (-8 -8 -8) (8 8 8) START_OFF
// Non-displayed light.
// Default light value is 300
// Default style is 0
// If targeted, it will toggle between on or off.

void() light =
{
   if (!self.targetname)
   {  // inert light
      remove(self);
      return;
   }
   
   if (self.style >= 32)
   {
      self.use = light_use;
      if (self.spawnflags & START_OFF)
         lightstyle(self.style, "a");
      else
         lightstyle(self.style, "m");
   }
};


// QUAKED light_fluoro (0 1 0) (-8 -8 -8) (8 8 8) START_OFF
// Non-displayed light.
// Default light value is 300
// Default style is 0
// If targeted, it will toggle between on or off.
// Makes steady fluorescent humming sound

void() light_fluoro =
{
   if (self.style >= 32)
   {
      self.use = light_use;
      if (self.spawnflags & START_OFF)
         lightstyle(self.style, "a");
      else
         lightstyle(self.style, "m");
   }
   
   precache_sound ("ambience/fl_hum1.wav");
   ambientsound (self.origin, "ambience/fl_hum1.wav", 0.5, ATTN_STATIC);
};


// QUAKED light_fluorospark (0 1 0) (-8 -8 -8) (8 8 8)
// Non-displayed light.
// Default light value is 300
// Default style is 10
// Makes sparking, broken fluorescent sound

void() light_fluorospark =
{
   if (!self.style)
      self.style = 10;

   precache_sound ("ambience/buzz1.wav");
   ambientsound (self.origin, "ambience/buzz1.wav", 0.5, ATTN_STATIC);
};


// QUAKED light_globe (0 1 0) (-8 -8 -8) (8 8 8)
// Sphere globe light.
// Default light value is 300
// Default style is 0

void() light_globe =
{
   precache_model ("progs/s_light.spr");
   setmodel (self, "progs/s_light.spr");
   makestatic (self);
};

void() FireAmbient =
{
   precache_sound ("ambience/fire1.wav");
   // attenuate fast
   ambientsound (self.origin, "ambience/fire1.wav", 0.5, ATTN_STATIC);
};


// QUAKED light_torch_small_walltorch (0 .5 0) (-10 -10 -20) (10 10 20)
// Short wall torch
// Default light value is 200
// Default style is 0

void() light_torch_small_walltorch =
{
   precache_model ("progs/flame.mdl");
   setmodel (self, "progs/flame.mdl");
   FireAmbient ();
   makestatic (self);
};


// QUAKED light_flame_large_yellow (0 1 0) (-10 -10 -12) (12 12 18)
// Large yellow flame ball

void() light_flame_large_yellow =
{
   precache_model ("progs/flame2.mdl");
   setmodel (self, "progs/flame2.mdl");
   self.frame = 1;
   FireAmbient ();
   makestatic (self);
};


// QUAKED light_flame_small_yellow (0 1 0) (-8 -8 -8) (8 8 8) START_OFF
// Small yellow flame ball

void() light_flame_small_yellow =
{
   precache_model ("progs/flame2.mdl");
   setmodel (self, "progs/flame2.mdl");
   FireAmbient ();
   makestatic (self);
};


// QUAKED light_flame_small_white (0 1 0) (-10 -10 -40) (10 10 40) START_OFF
// Small white flame ball

void() light_flame_small_white =
{
   precache_model ("progs/flame2.mdl");
   setmodel (self, "progs/flame2.mdl");
   FireAmbient ();
   makestatic (self);
};

//========================================================================================
//
// QUAKED viewthing (0 .5 .8) (-8 -8 -8) (8 8 8)
// Just for the debugging level.  Don't use
//
//========================================================================================

void() viewthing =

{
   self.movetype = MOVETYPE_NONE;
   self.solid = SOLID_NOT;
   precache_model ("progs/player.mdl");
   setmodel (self, "progs/player.mdl");
};


//========================================================================================
//
//   SIMPLE BMODELS
//
//========================================================================================

void() func_wall_use =
{  // change to alternate textures
   self.frame = 1 - self.frame;
};

// QUAKED func_wall (0 .5 .8) ?
// This is just a solid wall if not inhibitted

void() func_wall =
{
   self.angles = '0 0 0';
   self.movetype = MOVETYPE_PUSH;   // so it doesn't get pushed by anything
   self.solid = SOLID_BSP;
   self.use = func_wall_use;
   setmodel (self, self.model);
};


// QUAKED func_illusionary (0 .5 .8) ?
// A simple entity that looks solid but lets you walk through it.

void() func_illusionary =

{
   self.angles = '0 0 0';
   self.movetype = MOVETYPE_NONE;
   self.solid = SOLID_NOT;
   setmodel (self, self.model);
   makestatic ();
};

// QUAKED func_episodegate (0 .5 .8) ? E1 E2 E3 E4
// This bmodel will appear if the episode has allready been completed, so players can't reenter it.

void() func_episodegate =

{
   if (!(serverflags & self.spawnflags))
      return;        // can still enter episode

   self.angles = '0 0 0';
   self.movetype = MOVETYPE_PUSH;   // so it doesn't get pushed by anything
   self.solid = SOLID_BSP;
   self.use = func_wall_use;
   setmodel (self, self.model);
};

// QUAKED func_bossgate (0 .5 .8) ?
// This bmodel appears unless players have all of the episode sigils.

void() func_bossgate =

{
   if ( (serverflags & 15) == 15)
      return;     // all episodes completed
   self.angles = '0 0 0';
   self.movetype = MOVETYPE_PUSH;   // so it doesn't get pushed by anything
   self.solid = SOLID_BSP;
   self.use = func_wall_use;
   setmodel (self, self.model);
};

//=========================================================================================

// QUAKED ambient_suck_wind (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)

void() ambient_suck_wind =
{
   precache_sound ("ambience/suck1.wav");
   ambientsound (self.origin, "ambience/suck1.wav", 1, ATTN_STATIC);
};


// QUAKED ambient_drone (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)

void() ambient_drone =
{
   precache_sound ("ambience/drone6.wav");
   ambientsound (self.origin, "ambience/drone6.wav", 0.5, ATTN_STATIC);
};


//QUAKED ambient_flouro_buzz (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)

void() ambient_flouro_buzz =
{
   precache_sound ("ambience/buzz1.wav");
   ambientsound (self.origin, "ambience/buzz1.wav", 1, ATTN_STATIC);
};


// QUAKED ambient_drip (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)

void() ambient_drip =
{
   precache_sound ("ambience/drip1.wav");
   ambientsound (self.origin, "ambience/drip1.wav", 0.5, ATTN_STATIC);
};


// QUAKED ambient_comp_hum (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)

void() ambient_comp_hum =
{
   precache_sound ("ambience/comp1.wav");
   ambientsound (self.origin, "ambience/comp1.wav", 1, ATTN_STATIC);
};


// QUAKED ambient_thunder (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)

void() ambient_thunder =
{
   precache_sound ("ambience/thunder1.wav");
   ambientsound (self.origin, "ambience/thunder1.wav", 0.5, ATTN_STATIC);
};


// QUAKED ambient_light_buzz (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)

void() ambient_light_buzz =
{
   precache_sound ("ambience/fl_hum1.wav");
   ambientsound (self.origin, "ambience/fl_hum1.wav", 0.5, ATTN_STATIC);
};


// QUAKED ambient_swamp1 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)

void() ambient_swamp1 =
{
   precache_sound ("ambience/swamp1.wav");
   ambientsound (self.origin, "ambience/swamp1.wav", 0.5, ATTN_STATIC);
};


// QUAKED ambient_swamp2 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)

void() ambient_swamp2 =
{
   precache_sound ("ambience/swamp2.wav");
   ambientsound (self.origin, "ambience/swamp2.wav", 0.5, ATTN_STATIC);
};

//============================================================================

void() noise_think =
{
   self.nextthink = time + 0.5;
   sound (self, 1, "enforcer/enfire.wav", 1, ATTN_NORM);
   sound (self, 2, "enforcer/enfstop.wav", 1, ATTN_NORM);
   sound (self, 3, "enforcer/sight1.wav", 1, ATTN_NORM);
   sound (self, 4, "enforcer/sight2.wav", 1, ATTN_NORM);
   sound (self, 5, "enforcer/sight3.wav", 1, ATTN_NORM);
   sound (self, 6, "enforcer/sight4.wav", 1, ATTN_NORM);
   sound (self, 7, "enforcer/pain1.wav", 1, ATTN_NORM);
};


// QUAKED misc_noisemaker (1 0.5 0) (-10 -10 -10) (10 10 10)
// For optimzation testing, starts a lot of sounds.

void() misc_noisemaker =

{
   precache_sound2 ("enforcer/enfire.wav");
   precache_sound2 ("enforcer/enfstop.wav");
   precache_sound2 ("enforcer/sight1.wav");
   precache_sound2 ("enforcer/sight2.wav");
   precache_sound2 ("enforcer/sight3.wav");
   precache_sound2 ("enforcer/sight4.wav");
   precache_sound2 ("enforcer/pain1.wav");
   precache_sound2 ("enforcer/pain2.wav");
   precache_sound2 ("enforcer/death1.wav");
   precache_sound2 ("enforcer/idle1.wav");

   self.nextthink = time + 0.1 + random();
   self.think = noise_think;
};
