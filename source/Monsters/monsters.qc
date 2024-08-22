// monster.qc
/*---public---*/
// monster.qc 2,00 © Karlos'99 (01/08/1999)

   void(string mdlname, vector bmin, vector bmax, float hbase, float hvar)monster_initialise;
   void() monster_use ;
   void() monster_death_use ;
   void() monster_walk ;
   void() walkmonster_start ;
   void() monster_fly ;
   void() flymonster_start ;
   void() monster_swim ;
   void() swimmonster_start ;
   void() clear_monster_caches;
/*---private---*/

/* ALL MONSTERS SHOULD BE 1 0 0 IN COLOR */

// MACRO DESCRIPTION
// name =[framenum,  nexttime, nextthink] {code}
// expands to:
// name ()
// {
//    self.frame=framenum;
//    self.nextthink = time + nexttime;
//    self.think = nextthink
//    <code>
// };


/*================================================================================

   *** Karlos : new function

   monster_initialise (modelname, bbox_min, bbox_max, health, range)

      Sets model, size and inertia
      Sets health based on an initial value + random range, scaled by skill
         Algorithm:
            health = {[base + random()*range] * [1 + skill/6]}
                     for skill = 0 - 3

      Sets deadlflag and initial think delay
      Increments no. of monsters counter...

      Special Debug
      for DV_NO_MONSTERS
      removes monster

================================================================================*/

void(string mdlname, vector bmin, vector bmax, float hbase, float hvar) monster_initialise =
{
   if (developer & DV_NO_MONSTERS)
   {
      remove(self);
      return;
   }

   // set entity properties
   self.solid = SOLID_SLIDEBOX;
   self.movetype = MOVETYPE_STEP;
   setmodel (self, mdlname);
   if (!randomgame)
      setsize (self, bmin, bmax);
   else
   {

      if (developer & DV_SHOW_MONSTER_INF)
      {
          dprint ("species count : ");
          dprint (ftos(monstertypes));
          dprint ( "\n");
      }

      if (self.classname !="monster_demon1" || self.classname !="monster_shambler" || self.classname !="monster_shalrath")
      // make all smaller monsters zombie size in random game...
      setsize (self, '-16 -16 -24', '16 16 40');
   }

   // self.inertia = inertia;

   // set deadflag
   self.deadflag  = DEAD_NO;

   // define initial health
   if (!skill_fact)
      skill_fact = cvar ("skill");
   self.health = hbase + (hvar * random());
   self.health = self.health * (1 + (skill_fact / 6));

   // set takedamage
   self.takedamage = DAMAGE_AIM;

   self.flags = FL_MONSTER;

   // spread think times so they don't all happen at same time
   self.nextthink = self.nextthink + random()*0.75;

   // bump monster count
   total_monsters = total_monsters + 1;
};


/*===========================================================================
   monster_use

      Using a monster makes it angry at the current activator
===========================================================================*/
void() monster_use =
{
   if (self.enemy)
      return;
   if (self.health <= 0)
      return;
   if (activator.items & IT_INVISIBILITY)
      return;
   if (activator.flags & FL_NOTARGET)
      return;
   if (activator.classname != "player")
      return;
   
   // delay reaction so if the monster is teleported, its sound is still heard
   self.enemy = activator;
   self.nextthink = time + 0.1;
   self.think = FoundTarget;
};

/*==========================================================================
   monster_death_use

   When a mosnter dies, it fires all of its targets with the current
   enemy as activator.
==========================================================================*/
void() monster_death_use =
{
   local entity   ent, otemp, stemp;

// fall to ground
   if (self.flags & FL_FLY)
      self.flags = self.flags - FL_FLY;
   if (self.flags & FL_SWIM)
      self.flags = self.flags - FL_SWIM;

   if (!self.target)
      return;

   activator = self.enemy;
   SUB_UseTargets ();
};


//============================================================================

void() monster_walk =
{
   self.origin_z = self.origin_z + 1;  // raise off floor a bit
   droptofloor();
   
    if ((!walkmove(0,0)) && (developer & DV_SHOW_MONSTER_ERR))
    {
       dprint3("walkmonster ",self.classname," in wall at: ");
       dprint (vtos(self.origin));
       dprint ("\n");
    }

   self.ideal_yaw = self.angles * '0 1 0';
   if (!self.yaw_speed)
      self.yaw_speed = 20;
   self.view_ofs = '0 0 25';
   self.use = monster_use;
   
   if (self.target)
   {
      self.goalentity = self.movetarget = find(world, targetname, self.target);
      self.ideal_yaw = vectoyaw(self.goalentity.origin - self.origin);

      if ((!self.movetarget) && (developer & DV_SHOW_MONSTER_ERR))
      {
         dprint ("Monster can't find target at ");
         dprint (vtos(self.origin));
         dprint ("\n");
      }

      // this used to be an objerror
      if (self.movetarget.classname == "path_corner")
         self.th_walk ();
      else
         self.pausetime = 99999999;
         self.th_stand ();
   }
   else
   {
      self.pausetime = 99999999;
      self.th_stand ();
   }

// spread think times so they don't all happen at same time
   self.nextthink = self.nextthink + random()*0.5;
};


void() walkmonster_start =
{
   self.think = monster_walk;
};

void() monster_fly =
{
   self.ideal_yaw = self.angles * '0 1 0';
   if (!self.yaw_speed)
      self.yaw_speed = 10;
   self.view_ofs = '0 0 25';
   self.use = monster_use;

   self.flags = self.flags | FL_FLY;

   if ((!walkmove(0,0)) && (developer & DV_SHOW_MONSTER_ERR))
    {
       dprint3("flymonster ",self.classname," in wall at: ");
       dprint (vtos(self.origin));
       dprint ("\n");
    }

   if (self.target)
   {
      self.goalentity = self.movetarget = find(world, targetname, self.target);

      if ((!self.movetarget) && (developer & DV_SHOW_MONSTER_ERR))
      {
         dprint ("Monster can't find target at ");
         dprint (vtos(self.origin));
         dprint ("\n");
      }

      // this used to be an objerror
      if (self.movetarget.classname == "path_corner")
         self.th_walk ();
      else
         self.pausetime = 99999999;
         self.th_stand ();
   }
   else
   {
      self.pausetime = 99999999;
      self.th_stand ();
   }
};

void() flymonster_start =
{
   self.think = monster_fly;
};


void() monster_swim =
{
   self.ideal_yaw = self.angles * '0 1 0';
   if (!self.yaw_speed)
      self.yaw_speed = 10;
   self.view_ofs = '0 0 10';
   self.use = monster_use;
   
   self.flags = self.flags | FL_SWIM;

   if (self.target)
   {
      self.goalentity = self.movetarget = find(world, targetname, self.target);

      if ((!self.movetarget) && (developer & DV_SHOW_MONSTER_ERR))
      {
         dprint ("Monster can't find target at ");
         dprint (vtos(self.origin));
         dprint ("\n");
      }

      // this used to be an objerror
      self.ideal_yaw = vectoyaw(self.goalentity.origin - self.origin);
      self.th_walk ();
   }
   else
   {
      self.pausetime = 99999999;
      self.th_stand ();
   }

// spread think times so they don't all happen at same time
   self.nextthink = self.nextthink + random()*0.5;
};

void() swimmonster_start =
{
   self.think = monster_swim;
};

void() clear_monster_caches =
{
   // resets the monster cache flags on starting a level (needed in random game)
   monstertypes = 0;

   dog_cached = FALSE;
   grunt_cached = FALSE;
   knight_cached = FALSE;
   zombie_cached = FALSE;

   ogre_cached = FALSE;
   wizard_cached = FALSE;
   fiend_cached = FALSE;
   shambler_cached = FALSE;

   hell_knight_cached = FALSE;
   enforcer_cached = FALSE;
   spawn_cached = FALSE;
   vore_cached = FALSE;
   fish_cached = FALSE;
};
