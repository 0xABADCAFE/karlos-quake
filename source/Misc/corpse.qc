// corpse.qc
/*---public---*/
// $VER: corpse.qc 2.00 © Karlos '99 (14.7.99)
// public function prototypes
   void(string headmdl, float bodyinertia, float mindamage) corpse;
/*---private---*/

/*==============================================================================

   CORPSE.QC

      This gives a solid, pushable corpse. Call as last frame of monster death.
   Corpse can be damaged and gibletted. Aiming is not automatic.

   prototype : corpse(string headmdl, float inertia, float mindamage)

   By Karlos

   headmdl   : name of head model for gibletting
   inertia   : defines how hard the corpse is to push
   mindamage : defines how much damage the corpse can take before gibletting
               Actual value is randomly 100-200% of the value passed

   Corpse is removed after EDICT_EXPIRE has passed

   hacked variables: - no need to define values outside of this code ;)

   self.netname contains name of head model for giblets
   self.frags contains the inertia value

   self.deadflag is used to define alive/dead.

      This was added because corspes have self.health (used to define their
   damage limits) which broke the ai.qc/ai_run() routine, where the criteria
   for death was self.health <= 0 (leading to monsters attacking the corpse
   of their most recent enemy ;).
      Now, monster.qc/...monster_start() sets self.deadflag to DEAD_NO, whilst
   both corpse() and giblet() set it to DEAD_DEAD. Consequently, the ai_run()
   routine now checks a monster's deadflag instead of it's health...

==============================================================================*/

// Inflict damage to corpse

void() corpse_maim =
{
   if ((self.classname == "monster_knight" || self.classname == "monster_hell_knight") && self.deathtype == "melee")
      armour_clang(self);

   SpawnBlood (self.origin, crandom() * 20 * v_forward, 30);

   if (random() < 0.5)
      sound(self, CHAN_VOICE, "shared/corpsehit1.wav", 0.6 + random() * 0.4, ATTN_NORM);

   if (random() < 0.3)
   {
      sound(self, CHAN_BODY, "shared/corpsehit2.wav", 0.6 + random() * 0.4, ATTN_NORM);
      SpawnMeatSpray (self.origin, crandom() * 100 * v_right);
   }
};

// Destroy corpse
void() corpse_destroy =
{
   if (effectflags & FX_GORE_GIBS)
      giblet (self.netname, 2*self.health);
   else
      remove (self);
};

// corpse routine
void(string headmdl, float bodyinertia, float mindamage) corpse =
{
   self.deadflag   = DEAD_DEAD;             // used to define death
   self.ltime = time;
   self.think = SUB_Remove;
   self.nextthink = time + EDICT_EXPIRE;
   self.flags      = self.flags - (self.flags & FL_MONSTER);
   self.netname    = headmdl;
   self.inertia    = bodyinertia;

   self.velocity_x = 0;
   self.velocity_y = 0;
   setsize (self, '-16 -16 -24', '16 16 0');     // hack for now

   if (effectflags & FX_GORE_CORPSE)
   {
      // corpse gore
      self.health     = mindamage * (1 + random()); // minimum damage
      self.takedamage = DAMAGE_YES;                 // don't target automatically
      self.solid      = SOLID_BBOX;                 // Simple bounding box solidity
      self.movetype   = MOVETYPE_STEP;              // Simple pushable
      self.th_pain    = corpse_maim;
      self.th_die     = corpse_destroy;
      self.touch      = entity_push;
   }
   else
   {
      // simple dead body
      self.takedamage = DAMAGE_NO;
      self.solid      = SOLID_NOT;
      self.movetype   = MOVETYPE_NONE;
   }

   // strip all AI
   self.th_stand   = SUB_Null;
   self.th_walk    = SUB_Null;
   self.th_run     = SUB_Null;
   self.th_melee   = SUB_Null;
   self.th_missile = SUB_Null;
};
