// traps.qc
/*---public---*/
// $VER: traps.qc 1.00 � Karlos (10/10/1999)
// public function prototypes
   void() misc_explobox ;
   void() misc_explobox2 ;
   void() misc_fireball ;
   void() trap_shooter ;
   void() trap_spikeshooter ;
/*---private---*/
   void(entity e) makestatic;
   void() flame_burn;
   void() fire_fly;
   void() fire_touch;
//========================================================================================
//
//    Lavaball
//
//========================================================================================
void() misc_fireball =
{
   precache_model ("progs/lavaball.mdl");
   precache_sound ("boss1/throw.wav");
   self.teamgroup = TEAM_WORLD;
   self.netname   = "a lavaball";
   self.deadflag  = DEAD_DEAD;

   self.classname = "fireball";
   self.nextthink = time + (random() * 5);
   self.think = fire_fly;
   if (!self.speed)
      self.speed == 1000;
};

void() fire_fly =
{
   local entity   fireball;
   sound (self, CHAN_WEAPON, "boss1/throw.wav", 0.75, ATTN_IDLE);
   fireball = spawn();
   fireball.solid = SOLID_TRIGGER;
   fireball.movetype = MOVETYPE_TOSS;
   fireball.velocity = '0 0 1000';
   fireball.velocity_x = (crandom() * 100);
   fireball.velocity_y = (crandom() * 100);
   fireball.velocity_z = self.speed + (random() * 200);
   fireball.classname = "fireball";
   setmodel (fireball, "progs/lavaball.mdl");
   setsize (fireball, VEC_ZERO, VEC_ZERO);
   setorigin (fireball, self.origin);
   fireball.nextthink = time + 5;
   fireball.think = SUB_Remove;
   fireball.touch = fire_touch;
   self.nextthink = time + (random() * 5) + 3;
   self.think = fire_fly;
};

void() fire_touch =
{
   sound (self, CHAN_WEAPON, "shared/frying.wav", 0.75, ATTN_IDLE);
   T_Damage (other, self, self, 20);
   remove(self);
};


//========================================================================================
//
//   Explosive Boxes
//
//========================================================================================
void() barrel_explode =
{
   self.takedamage = DAMAGE_NO;
   self.classname = "explo_box";
   // did say self.owner
   T_RadiusDamage (self, self, 160, world);
   self.origin_z = self.origin_z + 32;
   BecomeExplosion ();
};

void() misc_explobox =
{
   local float oldz;
   
   self.solid = SOLID_BBOX;
   self.movetype = MOVETYPE_STEP;
   precache_model ("maps/b_explob.bsp");
   setmodel (self, "maps/b_explob.bsp");
   precache_sound ("weapons/r_exp3.wav");
   self.health     = 25;
   self.inertia    = 7;  // actually contains inertia value...
   self.flags      = self.flags | FL_CANTPUSH;
   self.touch      = entity_push;
   self.th_die     = barrel_explode;
   self.takedamage = DAMAGE_YES;
   self.deadflag   = DEAD_DEAD; // inanimate
   self.origin_z   = self.origin_z + 2;
   oldz = self.origin_z;
   droptofloor();
   if (oldz - self.origin_z > 250)
   {
      dprint ("Explosive box fell out of level at ");
      dprint (vtos(self.origin));
      dprint ("\n");
      remove(self);
   }
   self.teamgroup = TEAM_WORLD;
   self.netname   = "an explosive box";
};

void() misc_explobox2 =
{
   local float oldz;
   
   self.solid = SOLID_BBOX;
   self.movetype = MOVETYPE_STEP;
   precache_model2 ("maps/b_exbox2.bsp");
   setmodel (self, "maps/b_exbox2.bsp");
   precache_sound ("weapons/r_exp3.wav");

   self.inertia    = 4;  // actually contains inertia value...
   self.flags      = self.flags | FL_CANTPUSH;
   self.touch      = entity_push;
   self.th_die     = barrel_explode;
   self.health     = 20;
   self.takedamage = DAMAGE_YES; // don't target automatically...
   self.deadflag   = DEAD_DEAD; // inanimate
   self.origin_z   = self.origin_z + 2;
   oldz = self.origin_z;
   droptofloor();
   if (oldz - self.origin_z > 250)
   {
      dprint ("Explosive box fell out of level at ");
      dprint (vtos(self.origin));
      dprint ("\n");
      remove(self);
   }
   self.teamgroup = TEAM_WORLD;
   self.netname   = "an explosive box";
};

//========================================================================================
//
//  Laser / Spike shooters
//
//========================================================================================

void() spikeshooter_use =
{
   // we inhibit excess noises. Only four allowed at once now...

   if (self.spawnflags & SPAWNFLAG_LASER)
   {
      sound_autolimit(self, CHAN_VOICE, "enforcer/enfire.wav", 1, ATTN_NORM, sound1_used, TRAP_SOUND_LIMIT);
      sound1_used = sound1_used + 1;

      LaunchLaser (self.origin, self.movedir);
   }
   else
   {
      sound_autolimit(self, CHAN_VOICE, "weapons/spike2.wav", 1, ATTN_NORM, sound1_used, TRAP_SOUND_LIMIT);
      sound1_used = sound1_used + 1;

      launch_spike (self.origin, self.movedir);
      newmis.velocity = self.movedir * 500;
      if (self.spawnflags & SPAWNFLAG_SUPERSPIKE)
         newmis.touch = superspike_touch;
   }
};

void() shooter_think =
{
   spikeshooter_use ();
   self.nextthink = time + self.wait;
   newmis.velocity = self.movedir * 500;
};

void() trap_spikeshooter =
{
   self.deadflag  = DEAD_DEAD;
   self.teamgroup = TEAM_WORLD;
   self.netname   = "a gun trap";

   SetMovedir ();
   self.use = spikeshooter_use;
   if (self.spawnflags & SPAWNFLAG_LASER)
   {
      precache_model2 ("progs/laser.mdl");
      
      precache_sound2 ("enforcer/enfire.wav");
      precache_sound2 ("enforcer/enfstop.wav");
   }
   else
      precache_sound ("weapons/spike2.wav");
};

void() trap_shooter =
{
   trap_spikeshooter ();
   
   if (self.wait == 0)
      self.wait = 1;
   self.nextthink = self.nextthink + self.wait + self.ltime;
   self.think = shooter_think;
};

// makestatic() patch - flames are now dangerous (and faster, too)

void(entity e) makestatic =
{
   if ((e.model == "progs/flame.mdl") || (e.model == "progs/flame2.mdl"))
   {
      e.teamgroup = TEAM_WORLD;
      e.netname   = "fire";
      e.deadflag  = DEAD_DEAD;

      // if a flame model, set a size and set attacker classname...
      // otherwise do noting - ie static !
      setsize (e, '-2 -2 0', '2 2 6');
      e.solid = SOLID_TRIGGER;
      e.touch = flame_burn;
      e.classname = "flame";
   }
};

// Flame damage - not harmful to monsters until avoidance code written
void() flame_burn =
{
   local float burndamage;

   if (other.flags & FL_CLIENT)
   {
      burndamage = 1 + rint(skill / 3);
      T_Damage (other, self, self, burndamage);
   }
};
