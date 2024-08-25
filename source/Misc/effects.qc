// effects.qc
/*---public---*/
// $VER: effects.qc 1.90 � Karlos (03/04/2000)

// public function prototypes
// gore effects
   void(vector org, vector vel)               SpawnChunk;
   void(vector org, vector vel, float damage) SpawnBlood;
   void(float damage)                         spawn_touchblood;
   void(vector org, vector vel)               SpawnMeatSpray;
   void(string headmdl, float damage)         giblet;
   void(string gibname, float damage)         throw_gib;
   void(string gibname, float damage)         throw_head;

// bubble stuff
   void() air_bubbles;
   void(float num_bubbles) DeathBubbles;

// explosions
   void() BecomeExplosion;
   void(entity source) radius_glare;

// sound effects
   void(float walkvol, float atten) footfall_normal;
   void()                           SuperDamageSound;
   void(entity src, float msgnum)   radio_message;
   void(entity src)                 random_radio;
   void(entity src)                 armour_clang;

// other fx
   void(entity who, float steps) warp_fov;
   void(vector fx_org, float min_gamma) radius_flash;

/*---private---*/

// internal prototypes
   vector(float damage) gib_velocity ;
   void() air_bubbles ;
   void() bubble_bob ;
   void() bubble_remove ;
   void() bubble_split ;
   void() DeathBubblesSpawn ;
   void() exp_fireball ;
   void() make_bubbles ;
   void() shrapnel_touch ;
   void() SpawnExplosionBubbles ;
   void(float num_bubbles) DeathBubbles ;
   void(float num_bubbles) ExplodeBubbles ;
   void(float wadevol) footfall_wade ;
   void(vector org) exp_shrapnel ;

   float MAX_EXPLOSION_SOUNDS = 3; // limit no of overall explosions

//======================================================================================
//   SpawnChunk()
//      Creates a particle spray
//======================================================================================

void(vector org, vector vel) SpawnChunk =
{
   particle (org, vel*0.02, 0, 10);
};



//======================================================================================
//   SpawnBlood()
//      Creates blood effect for injuries inflicted on monsters/player
//======================================================================================

void(vector org, vector vel, float damage) SpawnBlood =
{
   if (effectflags & FX_GORE_BLOOD)
      particle (org, vel*0.1, 73, damage*6);
};



//======================================================================================
//   spawn_touchblood
//      Creates directional blood effects for walls etc
//======================================================================================

void(float damage) spawn_touchblood =
{
   local vector   vel;
   if (!(effectflags & FX_GORE_BLOOD))
      return;
   vel = wall_velocity () * 0.2;
   SpawnBlood (self.origin + vel*0.01, vel, damage);
};



//======================================================================================
//   SpawnMeatSpray()
//      spawns a meat projectile
//======================================================================================

void(vector org, vector vel) SpawnMeatSpray =
{
   if (entity_count >= ENTITY_MAX - 15)
      return;

   local entity missile, mpuff;
   local vector   org;

   if (!(effectflags & FX_GORE_GIBS))
      return;
   missile = spawn ();
   missile.owner = self;
   missile.movetype = MOVETYPE_BOUNCE;
   missile.solid = SOLID_NOT;

   makevectors (self.angles);

   missile.velocity = vel;
   missile.velocity_z = missile.velocity_z + 250 + 50*random();

   missile.avelocity = '3000 1000 2000';

   missile.nextthink = time + 4;
   missile.think = SUB_Remove;

   setmodel (missile, "progs/zom_gib.mdl");
   setsize (missile, VEC_ZERO, VEC_ZERO);
   setorigin (missile, org);
};


//======================================================================================
//    Giblet(float damage)
//       Giblets an entity, velocity of giblets depends on damage taken
//======================================================================================

void(string headmdl, float damage) giblet =
{
   if (!(effectflags & FX_GORE_GIBS))
   {
      // should never be called if no gibs, but just in case, remove entity
      remove(self);
      return;
   }

   self.deadflag   = DEAD_DEAD;   // Is dead...
   self.th_stand   = SUB_Null;  // turn off all AI routines (it is dead, afterall ;)
   self.th_walk    = SUB_Null;
   self.th_run     = SUB_Null;
   self.th_melee   = SUB_Null;
   self.th_missile = SUB_Null;
   self.th_pain    = SUB_Null;
   self.th_die     = SUB_Null;
   self.touch      = SUB_Null;

   self.movetype   = MOVETYPE_BOUNCE; // bouncy head...
   self.takedamage = DAMAGE_NO;     // can't damage further
   self.think      = SUB_Remove;
   self.nextthink  = time + EDICT_EXPIRE * (random() + 1);
   self.solid = SOLID_NOT;          // not solid
   setsize (self, '-8 -8 -8', '8 8 8');

   sound (self, CHAN_BODY, "shared/meat.wav", 1, ATTN_NORM);
   throw_head (headmdl, damage);
   throw_gib ("progs/gib1.mdl", damage);
   throw_gib ("progs/gib2.mdl", damage);
   throw_gib ("progs/gib3.mdl", damage);
};

//--------------------------------------------------------------------------------------

vector(float damage) gib_velocity =
{
   local vector v;
   v_x = 100 * crandom();
   v_y = 100 * crandom();
   v_z = 200 + 100 * random();
   if (damage > -50)
   {
      v = v * 0.7;
   }
   else if (damage > -200)
   {
      v = v * 2;
   }
   else
      v = v * 10;
   return v;
};

//--------------------------------------------------------------------------------------

/*
void() giblet_splat =
{
    sound (self, CHAN_VOICE, "shared/splat.wav", 0.5 + 0.5*random(), ATTN_NORM);
};
*/
void(string gibname, float damage) throw_gib =
{
   if (entity_count >= ENTITY_MAX - 15)
      return;
   local entity meat;

   meat = spawn();
   meat.origin = self.origin;
   setmodel (meat, gibname);
   setsize (meat, VEC_ZERO, VEC_ZERO);
   meat.velocity = gib_velocity (damage);
   meat.movetype = MOVETYPE_BOUNCE;

   //meat.solid = SOLID_BBOX;
   meat.solid = SOLID_NOT;

   meat.avelocity_x = random()*600;
   meat.avelocity_y = random()*600;
   meat.avelocity_z = random()*600;
   meat.think = SUB_Remove;
   meat.ltime = time;
   meat.nextthink = time + 10 * (random() + 1);
   meat.frame = 0;
   meat.flags = 0;
   /*
   meat.touch = giblet_splat;
   */
};

//--------------------------------------------------------------------------------------

void(string gibname, float damage) throw_head =
{
   setmodel (self, gibname);
   self.frame = 0;
   self.view_ofs = '0 0 8';
   setsize (self, '-16 -16 0', '16 16 56');
   self.velocity = gib_velocity (damage);
   self.origin_z = self.origin_z - 24;
   self.flags = self.flags - (self.flags & FL_ONGROUND);
   self.avelocity_x = random()*600;
   self.avelocity_y = random()*600;
   self.avelocity_z = random()*600
   ;self.avelocity = crandom() * '0 600 0';
};


//======================================================================================
//   air_bubbles()
//      creates a bubble stream
//======================================================================================

void() air_bubbles =
{
   if (deathmatch)
   {
      remove (self);
      return;
   }
   precache_model ("progs/s_bubble.spr");
   self.nextthink = time + 1.5 + random();
   self.think = make_bubbles;
};


//======================================================================================
//   DeathBubbles(float num_bubbles)
//      creates bubbles when underwater entity dies
//======================================================================================

void(float num_bubbles) DeathBubbles =
{
   local entity   bubble_spawner;

   bubble_spawner = spawn();
   setorigin (bubble_spawner, self.origin);
   bubble_spawner.movetype = MOVETYPE_NONE;
   bubble_spawner.solid = SOLID_NOT;
   bubble_spawner.nextthink = time + 0.1;
   bubble_spawner.think = DeathBubblesSpawn;
   bubble_spawner.air_finished = 0;
   bubble_spawner.owner = self;
   bubble_spawner.bubble_count = num_bubbles;
   return;
};

//-----------------------------------------------------------------------------------------


void() DeathBubblesSpawn =
{
   if (entity_count >= ENTITY_MAX - 25)
      return;

   local entity   bubble;
   if (self.owner.waterlevel != 3)
      return;
   bubble = spawn();
   setmodel (bubble, "progs/s_bubble.spr");
   setorigin (bubble, self.owner.origin + '0 0 24');
   bubble.movetype = MOVETYPE_NOCLIP;
   bubble.solid = SOLID_NOT;
   bubble.velocity = '0 0 15';
   bubble.nextthink = time + 0.5;
   bubble.think = bubble_bob;
   bubble.classname = "bubble";
   bubble.frame = 0;
   bubble.cnt = 0;
   setsize (bubble, '-8 -8 -8', '8 8 8');
   self.nextthink = time + 0.1;
   self.think = DeathBubblesSpawn;
   self.air_finished = self.air_finished + 1;
   if (self.air_finished >= self.bubble_count)
      remove(self);
};

//======================================================================================
//   make_bubbles()
//      spawns a bubble
//======================================================================================

void() make_bubbles =
{
   if (entity_count >= ENTITY_MAX - 25)
      return;

   local entity   bubble;

   bubble = spawn();
   setmodel (bubble, "progs/s_bubble.spr");
   setorigin (bubble, self.origin);
   bubble.movetype = MOVETYPE_NOCLIP;
   bubble.solid = SOLID_NOT;
   bubble.velocity = '0 0 15';
   bubble.nextthink = time + 0.5;
   bubble.think = bubble_bob;
   bubble.touch = bubble_remove;
   bubble.classname = "bubble";
   bubble.frame = 0;
   bubble.cnt = 0;
   setsize (bubble, '-8 -8 -8', '8 8 8');
   self.nextthink = time + random() + 0.5;
   self.think = make_bubbles;
};

//--------------------------------------------------------------------------------------

void() bubble_split =
{
   if (entity_count >= ENTITY_MAX - 25)
      return;

   local entity   bubble;
   bubble = spawn();
   setmodel (bubble, "progs/s_bubble.spr");
   setorigin (bubble, self.origin);
   bubble.movetype = MOVETYPE_NOCLIP;
   bubble.solid = SOLID_NOT;
   bubble.velocity = self.velocity;
   bubble.nextthink = time + 0.5;
   bubble.think = bubble_bob;
   bubble.touch = bubble_remove;
   bubble.classname = "bubble";
   bubble.frame = 1;
   bubble.cnt = 11;
   setsize (bubble, '-8 -8 -8', '8 8 8');
   self.frame = 1;
};

//--------------------------------------------------------------------------------------

void() bubble_remove =
{
   if (other.classname == self.classname || other.classname == "exp_fireball")
   {
      return;
   }
   remove(self);
};

//--------------------------------------------------------------------------------------

void() bubble_bob =
{
   local float    rndx, rndy, rndz, liquid;
 
   liquid = pointcontents(self.origin + '0 0 32');

   // check environment status (in liquid ?)

   if (!(liquid == CONTENT_WATER || liquid == CONTENT_SLIME))
      remove(self);

   self.cnt = self.cnt + 1;

   if (self.cnt == 20)
      remove(self);

   if (self.cnt == 10)
   {
      // either split the bubble or halve it's size...
      if (random() > 0.5)
      {
         bubble_split();
      }
      else
         self.frame = 1;
   }

   rndx = self.velocity_x + (crandom() * 5);
   rndy = self.velocity_y + (crandom() * 5);
   rndz = self.velocity_z + (random() * 15);

   // cap component velocities

   if (fabs(rndx) > 15)
      rndx = rndx / 2;
   if (fabs(rndy) > 15)
      rndy = rndy / 2;
   if (rndz > 60)
      rndz = 50;
   
   self.velocity_x = rndx;
   self.velocity_y = rndy;
   self.velocity_z = rndz;
      
   self.nextthink = time + 0.75;
   self.think = bubble_bob;
};


//======================================================================================
//    BecomeExplosion()
//       Transforms an entity into an explosion
//          Function uses dynmiclight to ascertain if the explosion should have a
//       lighting effect or not.
//          Function distinguishes between normal and submarine explosions. Submarine
//       explosions use a different sound effect and produce bubbles.
//======================================================================================


void() s_explode1  =  [0,      s_explode2] {self.nextthink = time + (0.2 * random());};
void() s_explode2  =  [1,      s_explode3] {self.nextthink = time + (0.2 * random());};
void() s_explode3  =  [2,      s_explode4] {self.nextthink = time + (0.2 * random());};
void() s_explode4  =  [3,      s_explode5] {self.nextthink = time + (0.2 * random());};
void() s_explode5  =  [4,      s_explode6] {self.nextthink = time + (0.2 * random());};
void() s_explode6  =  [5,      SUB_Remove] {};


void() BecomeExplosion =
{
   local float i;
   // set up explosion base
   self.movetype = MOVETYPE_NOCLIP;
   self.velocity = '0 0 8';
   self.touch = SUB_Null;
   setmodel (self, "progs/s_explod.spr");
   self.solid = SOLID_NOT;
 
   // check if explosion is fast...
   if (effectflags & FX_FAST_EXP)
   {
      // fast explosion. No particles, no SVC_TEMPENTITY and only a simple muzzleflash effect
      self.effects = self.effects | (FX_FLASH & effectflags);
   }
   else
   {
      // full explosion. Spray particles and full lighting (unless disabled)
      if (!(effectflags & (FX_FLASH | FX_GLOW)))
      {
         // no lights - do particles only...
         particle (self.origin, VEC_ZERO, 75, 255);
      }
      else
      {
         WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
         WriteByte (MSG_BROADCAST, TE_EXPLOSION);
         WriteCoord (MSG_BROADCAST, self.origin_x);
         WriteCoord (MSG_BROADCAST, self.origin_y);
         WriteCoord (MSG_BROADCAST, self.origin_z);
      }
   }

   // check if explosion is smart...
   if (effectflags & FX_SMART_EXP)
   {
      // check environment...
      if (pointcontents(self.origin) == CONTENT_WATER || pointcontents(self.origin) == CONTENT_SLIME)
      {
         // underwater blast
         sound_autolimit(self, CHAN_WEAPON, "weapons/w_explode.wav", 1, ATTN_NORM, sound2_used, MAX_EXPLOSION_SOUNDS);
         // do aftershock (quiet)...
         sound (self, CHAN_BODY, "weapons/rumble.wav", 0.4, ATTN_NONE);

         if (pointcontents(self.origin + '0 0 60') == CONTENT_EMPTY)
         {
            // do splash fx here..
            sound (self, CHAN_VOICE, "boss1/out1.wav", 0.6, ATTN_NORM);
         }

         ExplodeBubbles(8 * (1 + random() ));
      }
      else
      {
         // airborne blast
         sound_autolimit(self, CHAN_WEAPON, "weapons/explode.wav", 1, ATTN_NORM, sound2_used, MAX_EXPLOSION_SOUNDS);
         // do aftershock (loud)...
         sound (self, CHAN_BODY, "weapons/rumble.wav", 0.7, ATTN_NONE);
      }
   }
   else
   {
      // no environment distinction...
      sound_autolimit(self, CHAN_WEAPON, "weapons/explode.wav", 1, ATTN_NORM, sound2_used, MAX_EXPLOSION_SOUNDS);
   }

   sound2_used = sound2_used + 1;

   // check multiframe explosion...
   if (effectflags & FX_MULTI_EXP)
   {
      exp_fireball ();
      exp_fireball ();
      exp_fireball ();
   }

   // check shrapnel explosion...
   if (shrapnel)
   {
      i = 0;
      do
      {
         exp_shrapnel (self.origin);
         exp_shrapnel (self.origin);
         exp_shrapnel (self.origin);
         exp_shrapnel (self.origin);
         i = i + 1;
      }
      while (i < 5 );
   }
   s_explode1 ();
};

//--------------------------------------------------------------------------------------


void() exp_fireball =
{
   if (entity_count >= ENTITY_MAX - 10)
      return;

   local entity explode;

   explode = spawn();
   explode.origin = self.origin + (crandom() * '24 0 0') + (crandom() * '0 24 0') + (crandom() * '0 0 24');
   explode.velocity = '0 0 40';
   setmodel (explode, "progs/s_explod.spr");
   explode.movetype = MOVETYPE_NOCLIP;
   explode.solid = SOLID_NOT;
   explode.think = s_explode1;
   explode.nextthink = time + (0.2*random());
};

//--------------------------------------------------------------------------------------

void(vector org) exp_shrapnel =
{
   if (entity_count >= ENTITY_MAX - 30)
      return;

   local vector dir;

   dir = (crandom() * '1 0 0') + (crandom() * '0 1 0') + (crandom() * '0 0 1');

   if (pointcontents(org + 20*dir) != CONTENT_SOLID)
   {
       newmis = spawn ();
       newmis.owner = self.owner;
       newmis.movetype = MOVETYPE_FLYMISSILE;
       newmis.solid = SOLID_BBOX;
       newmis.angles = vectoangles(dir);
       newmis.touch = shrapnel_touch;
       newmis.classname = "shrapnel";
       newmis.think = SUB_Remove;
       newmis.nextthink = time + 3;
       setmodel (newmis, "progs/spike.mdl");
       setsize (newmis, VEC_ZERO, VEC_ZERO);
       setorigin (newmis, org + 20*dir);
       newmis.velocity = 1400 * normalize(dir);
   }
};

//--------------------------------------------------------------------------------------

void() shrapnel_touch =
{

   local vector newdir;

   if (pointcontents(self.origin) == CONTENT_SKY)
   {
      remove(self);
      return;
   }

   if (other.solid == SOLID_TRIGGER)
      return;  // trigger field, do nothing

   if (other.health)
   {
      // will harm anything with a healt value, ie living or ungibbed corpse
      spawn_touchblood (8);
      T_Damage (other, self, self.owner, 5 * ( 1 + random() ));
      sound (other, CHAN_BODY, "shared/corpsehit1.wav", 1, ATTN_NORM);
   }

   // on average, 1/5 will give a 'tink' effect...

   if (random() < 0.2)
   {
      WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
      WriteByte (MSG_BROADCAST, TE_SPIKE);
      WriteCoord (MSG_BROADCAST, self.origin_x);
      WriteCoord (MSG_BROADCAST, self.origin_y);
      WriteCoord (MSG_BROADCAST, self.origin_z);
   }
   /*
   if (random() > 0.6)
   */
      remove(self);
   /*
   else
   {
      newdir = normalize(self.velocity);
      self.velocity = 1500*newdir;
      self.avelocity_x = 3000*random();
      self.avelocity_y = 3000*random();
      self.avelocity_z = 3000*random();
   }
   */
};

//--------------------------------------------------------------------------------------

void() SpawnExplosionBubbles =
{
   if (entity_count >= ENTITY_MAX - 30)
      return;
   local entity   bubble;
   bubble = spawn();
   setmodel (bubble, "progs/s_bubble.spr");
   setorigin (bubble, self.owner.origin + (crandom() * '16 0 0') + (crandom() * '0 16 0') + (random() * '0 0 24'));
   bubble.movetype = MOVETYPE_NOCLIP;
   bubble.solid = SOLID_NOT;
   bubble.velocity = '0 0 15';
   bubble.nextthink = time + 0.5;
   bubble.think = bubble_bob;
   bubble.classname = "bubble";
   bubble.frame = 0;
   bubble.cnt = 0;
   setsize (bubble, '-8 -8 -8', '8 8 8');
   self.nextthink = time + 0.1;
   self.think = SpawnExplosionBubbles;
   self.air_finished = self.air_finished + 1;

   if (self.air_finished >= self.bubble_count)
      remove(self);
};

//--------------------------------------------------------------------------------------

void(float num_bubbles) ExplodeBubbles =
{
   local entity   bubble_spawner;
   
   bubble_spawner = spawn();
   setorigin (bubble_spawner, self.origin);
   bubble_spawner.movetype = MOVETYPE_NONE;
   bubble_spawner.solid = SOLID_NOT;
   bubble_spawner.nextthink = time + 0.1;
   bubble_spawner.think = SpawnExplosionBubbles;
   bubble_spawner.air_finished = 0;
   bubble_spawner.owner = self;
   bubble_spawner.bubble_count = num_bubbles;
   return;
};


/*=========================================================================================

                                       SOUND EFFECTS

=========================================================================================*/

void(float walkvol, float atten) footfall_normal =
{
   // self refers to calling entity...

   local float r;
   local vector monst_feet, monst_head;

   // handle player first
   if (self.flags & FL_CLIENT)
   {
      // if not moving, no sound
      if ( vlen(self.origin - self.oldorigin) < 5)
         return;
      // check liquid level
      if (self.waterlevel > 2)
      {
         // player fully immersed, no sound..
         return;
      }
      else if (self.waterlevel > 0)
      {
         // player waist / ankle deep, slosh about...
         footfall_wade (walkvol);
         return;
      }
   }
   else if (self.flags & FL_MONSTER)
   {
      // waterlevel doesn't seem to work properly for nonsters, so
      // check the relative contents of head and feet to decide if the wade effect
      // should be used
      monst_feet = self.origin + self.mins;
      monst_head = monst_feet + 0.9*self.size;      
      if (pointcontents(monst_head) != CONTENT_EMPTY)
         return;
      else if (pointcontents(monst_feet) < CONTENT_SOLID) 
         footfall_wade (walkvol);  
   }
   // entity must be on a surface to make a step sound
   if (self.flags & FL_ONGROUND)
   {
      r = random();
      if (r < 0.33)
         sound (self, CHAN_WALK, "shared/hardstep1.wav", walkvol, atten);
      else if (r < 0.66)
         sound (self, CHAN_WALK, "shared/hardstep2.wav", walkvol, atten);
      else 
         sound (self, CHAN_WALK, "shared/hardstep3.wav", walkvol, atten);
   }
};

//--------------------------------------------------------------------------------

void(float wadevol) footfall_wade =
{
   local float r;

   if (time > self.wadetime)
   {
      self.wadetime = time + 0.8;
      r = random();
      if (r < 0.33)
         sound (self, CHAN_WALK, "shared/wade1.wav", wadevol, ATTN_STATIC);
      else if (r < 0.66)
         sound (self, CHAN_WALK, "shared/wade2.wav", wadevol, ATTN_STATIC);
      else
         sound (self, CHAN_WALK, "shared/wade3.wav", wadevol, ATTN_STATIC);
   }
};


//-----------------------------------------------------------------------------

void() SuperDamageSound =
{
   if (self.super_damage_finished > time)
   {
      if (self.super_sound < time)
      {
         self.super_sound = time + 0.5;
         sound (self, CHAN_BODY, "items/damage3.wav", 1, ATTN_NORM);
      }
   }
   return;
};

void(entity src) armour_clang =
{
   local float r;

   r = random();
   if (r < 0.3)
      sound (src, CHAN_AUX1, "weapons/armourhit1.wav", 0.7 + (0.3 * random()), ATTN_NORM);
   else if (r<0.6)
      sound (src, CHAN_AUX2, "weapons/armourhit2.wav", 0.7 + (0.3 * random()), ATTN_NORM);
   else
      sound (src, CHAN_AUX1, "weapons/armourhit3.wav", 0.7 + (0.3 * random()), ATTN_NORM);
};

//------------------------------------------------------------------------------------

//float() protection_deflect =
//{
//   // a function whuch can be called from a missiles .touch function.
//   // projectile will be deflected if target is invulnerable
//   // self is projectile, other is target
//
//   if (other.invincible_finished >= time)
//   {
//      self.velocity = self.velocity * -1.3;
//      self.angles = vectoangles(normalize(self.velocity));
//      self.owner = other;
//
//      return TRUE;
//   }
//   else
//      return FALSE;
//};

//-------------------------------------------------------------------------------------

void(entity src, float msgnum) radio_message =
{
   // plays a radio message
   // delays are set on per caller basis, to prevent over saturation of noise

   // messages are
   //    
   //    0. random (uses CHAN_AUX1)
   //    1. enemy sighted
   //    2. attack instruction
   //    3. acknowledged
   //    4. enemy killed

   if (msgnum == 0)
   {
      if (time > src.radio_inhibit_rand)
      {
         random_radio(src);
         src.radio_inhibit_rand = src.radio_inhibit_rand + 8 * (1+random());
      }
   }
   if (msgnum == 1)
   {
      if (time > src.sound_inhibit_time)
      {
         sound (src, CHAN_AUTO, "soldier/radio_sight.wav", 0.8, ATTN_IDLE);
         src.sound_inhibit_time = time + 3 * (1 + random());
      }
   }
   else if (msgnum == 2)
   {
      if (time > src.sound_inhibit_time)
      {
         sound (src, CHAN_AUTO, "soldier/radio_attack.wav", 0.7, ATTN_IDLE);
         src.sound_inhibit_time = time + 5 * (1 + random());
      }
   }
   else if (msgnum == 3)
   {
      if (time > src.sound_inhibit_time)
      {
         sound (src, CHAN_AUTO, "soldier/radio_ackn.wav", 0.8, ATTN_IDLE);
         src.sound_inhibit_time = time + 3 * (1 + random());
      }
   }
   else if (msgnum == 4)
   {
      sound (src, CHAN_AUTO, "soldier/radio_enemydown.wav", 1, ATTN_IDLE);
   }
};

//-------------------------------------------------------------------------------------

void(entity src) random_radio =
{
   // plays a random radio sound

   local float r;

   r = random();

   if (r < 0.2)
      sound (src, CHAN_AUX1, "soldier/radio1.wav", 0.5, ATTN_IDLE);

   else if (r < 0.4)
      sound (src, CHAN_AUX2, "soldier/radio2.wav", 0.5, ATTN_IDLE);

   else if (r < 0.6)
      sound (src, CHAN_AUX1, "soldier/radio3.wav", 0.5, ATTN_IDLE);

   else if (r < 0.8)
      sound (src, CHAN_AUX2, "soldier/radio4.wav", 0.5, ATTN_IDLE);

   else
      sound (src, CHAN_AUX1, "soldier/radio5.wav", 0.5, ATTN_IDLE);
};

void(entity who, float start_bright, float steps) gamma_flash =
{
};

void(entity source) radius_glare =
{
};


//====================================================================================
//
//  warp_fov() : cool function for teleports etc ;)
//
//====================================================================================
void(entity who, float steps) warp_fov =
{    
   local float fx_rate;
   local string temp_string; 

   if (!who.flags & FL_CLIENT)
      return;

   if (effectflags & FX_CON_FOV)
   {
      fx_rate = cvar("host_framerate");
      who.cur_fov = 160;
      if (fx_rate == 0 || fx_rate >= 0.1)
          who.fx_manager.cur_fov = 10;
      else
          who.fx_manager.cur_fov = rint(100 * fx_rate);
      temp_string = ftos(who.cur_fov);
      stuffcmd (who, "fov ");
      stuffcmd (who, temp_string);
      stuffcmd (who, "\n");
   }
   if (effectflags & FX_CON_GAMMA)
   {
      who.cur_gamma = 0.1;
      temp_string = ftos(who.cur_gamma);
      stuffcmd (who, "fov ");
      stuffcmd (who, temp_string);
      stuffcmd (who, "\n");
   }
   // invoke the fx manager
   if (effectflags & FX_CON_FOV || effectflags & FX_CON_GAMMA)
      who.fx_manager.nextthink = time + 0.05;
};

void(vector fx_org, float min_gamma) radius_flash =
{
   // if gamma fx turned off just return
   if (effectflags & FX_CON_GAMMA == FALSE)
      return;

   // send out a flash effect originating from inflictor
   // min_gamma sets the brightness and range of the flash

   local float    fx_radius, power;
   local entity   head;

   if (min_gamma < 0.1)
      min_gamma = 0.1;

   fx_radius = 200/min_gamma;

   head = findradius(fx_org, fx_radius);
   
   while (head)
   {
      // head must be a living client
      if (head.flags & FL_CLIENT && head.deadflag == DEAD_NO)
      {
          // calculate flash power, saturating at min_gamma
          // larger distances imply lower power

          power = vlen(head.origin - fx_org) / (2*fx_radius);
          if (power < min_gamma)
             power = min_gamma;
          if (head.cur_gamma > power)
          {
             // set client's current gamma
             head.cur_gamma = power;
             // wake up clients effect manager
             head.fx_manager.nextthink = time + 0.02;            
          }
      }
      head = head.chain;
   }
};

