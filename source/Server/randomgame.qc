// randomgame.qc
/*---public---*/
// $VER: randomgame 0.01 © Karlos (08/11/1999)

// public function prototypes
// lowlevel
   void() swap_monster;

   float monstertypes;
/*---private---*/

void(float pick_any) choose_equivalent_monster =
{
   local float rndm;

   // if pick_any is TRUE, then selection will be totally random within the range
   // otherwise it will depend on whether the monster type is already cached
   // always use original monster class as a fall back

   rndm = random();

   self.switched = TRUE; // declare monster as switched

   //----------------------------------------------------------------------------
   // Rottweiler : zombie/grunt
   if (self.classname == "monster_dog")
   {
      if (rndm < 0.33 * (pick_any | zombie_cached))
      {
         self.classname = "monster_zombie";
         monster_zombie();
      }
      else if (rndm < 0.66 * (pick_any | grunt_cached))
      {
         self.classname = "monster_grunt";
         monster_army();
      }
      else
      {
         monster_dog();
      }
   }

   //----------------------------------------------------------------------------
   // Grunt : zombie/knight/enforcer
   else if (self.classname == "monster_army")
   {
      if (rndm < 0.25 * (pick_any | knight_cached))
      {
         self.classname = "monster_knight";
         monster_knight();
      }

      else if (rndm < 0.5 * (pick_any | zombie_cached))
      {
         self.classname = "monster_zombie";
         monster_zombie();
      }                      
      else if (rndm < 0.75 * (pick_any | enforcer_cached))
      {
         self.classname = "monster_enforcer";
         monster_enforcer();
      }
      else
      {
         monster_army();
      }
   }

   //----------------------------------------------------------------------------
   // enforcer : knight / ogre / hell_knight
   else if (self.classname == "monster_enforcer")
   {
      if (rndm < 0.25 * (pick_any | knight_cached))
      {
         self.classname = "monster_knight";
         monster_knight();
      }

      else if (rndm < 0.5 * (pick_any | ogre_cached))
      {
         self.classname = "monster_ogre";
         monster_ogre();
      }
      else if (rndm < 0.75 * (pick_any | hell_knight_cached))
      {
         self.classname = "monster_hell_knight";
         monster_hell_knight();
      }
      else
      {
         monster_enforcer();
      }
   }


   //----------------------------------------------------------------------------
   // zombie : knight/rottweiler/grunt
   else if (self.classname == "monster_zombie")
   {
      if (rndm < 0.25 * (pick_any | knight_cached))
      {
         self.classname = "monster_knight";
         monster_knight();
      }
      else if (rndm < 0.5 * (pick_any | dog_cached))
      {
         self.classname = "monster_dog";
         monster_dog();
      }
      else if (rndm < 0.75 * (pick_any | grunt_cached))
      {
         self.classname = "monster_army";
         monster_army();
      }
      else
      {
         monster_zombie();
      }
   }

   //----------------------------------------------------------------------------
   // knight : zombie/grunt/hell_knight
   else if (self.classname == "monster_knight")
   {
      if (rndm < 0.25 * (pick_any | zombie_cached))
      {
         self.classname = "monster_zombie";
         monster_zombie();
      }
      else if (rndm < 0.5 * (pick_any | grunt_cached))
      {
         self.classname = "monster_army";
         monster_army();
      }
      else if (rndm < 0.75 * (pick_any | hell_knight_cached))
      {
         self.classname = "monster_hell_knight";
         monster_hell_knight();
      }
      else
      {
         monster_knight();
      }
   }

   //----------------------------------------------------------------------------
   // hellknight : enforcer/ogre/fiend
   else if (self.classname == "monster_hell_knight")
   {
      if (rndm < 0.25 * (pick_any | enforcer_cached))
      {
         self.classname = "monster_enforcer";
         monster_enforcer();
      }
      else if (rndm < 0.5 * (pick_any | ogre_cached))
      {
         self.classname = "monster_ogre";
         monster_ogre();
      }
      else if (rndm < 0.75 * (pick_any | fiend_cached))
      {
         self.classname = "monster_demon1";
         monster_demon1();
      }
      else
      {
         monster_hell_knight();
      }
   }

   //----------------------------------------------------------------------------
   // ogre : enforcer/hellknight
   else if (self.classname == "monster_ogre")
   {
      if (rndm < 0.33 * (pick_any | enforcer_cached))
      {
         self.classname = "monster_enforcer";
         monster_enforcer();
      }
      else if (rndm < 0.66 * (pick_any | hell_knight_cached))
      {
         self.classname = "monster_hell_knight";
         monster_hell_knight();
      }
      else
      {
         monster_ogre();
      }

   }

   //----------------------------------------------------------------------
   // fiend : vore / hell_knight / shambler
   else if (self.classname == "monster_demon1")
   {
      if (rndm < 0.25 * (pick_any | vore_cached))
      {
         self.classname = "monster_shalrath";
         monster_shalrath();
      }
      else if (rndm < 0.5 * (pick_any | hell_knight_cached))
      {
         self.classname = "monster_hell_knight";
         monster_hell_knight();
      }
      else if (rndm < 0.75 * (pick_any | shambler_cached))
      {
         self.classname = "monster_shambler";
         monster_shambler();
      }
      else
      {
         monster_demon1();
      }
   }

   //-----------------------------------------------------------------------------
   // shambler : fiend / vore
   else if (self.classname == "monster_shambler")
   {
      if (rndm < 0.33 * (pick_any | fiend_cached))
      {
         self.classname = "monster_demon1";
         monster_demon1();
      }
      else if (rndm < 0.66 * (pick_any | vore_cached))
      {
         self.classname = "monster_shalrath";
         monster_shalrath();
      }
      else
      {
         monster_shambler();
      }
   }

   //----------------------------------------------------------------------------
   // vore : fiend / shambler
   else if (self.classname == "monster_shalrath")
   {
      if (rndm < 0.33 * (pick_any | fiend_cached))
      {
         self.classname = "monster_demon1";
         monster_demon1();
      }
      else if (rndm < 0.66 * (pick_any | shambler_cached))
      {
         self.classname = "monster_shambler";
         monster_shambler();
      }
      else
      {
         monster_shalrath();
      }
   }

   //---------------------------------------------------------------------------
   // spawn : zombie / scragg
   else if (self.classname == "monster_tarbaby")
   {
      if (rndm < 0.33 * (pick_any | zombie_cached))
      {
         self.classname = "monster_zombie";
         monster_zombie();
      }
      else if (rndm < 0.66 * (pick_any | wizard_cached))
      {
         self.classname = "monster_wizard";
         self.origin = self.origin + '0 0 40';
         monster_wizard();
      }
      else
      {
         monster_tarbaby();
      }
   }

   //---------------------------------------------------------------------
   // scragg : grunt / zombie / spawn
   else if (self.classname == "monster_wizard")
   {
      if (rndm < 0.25 * (pick_any | grunt_cached))
      {
         self.classname = "monster_army";
         monster_army();
      }
      else if (rndm < 0.5 * (pick_any | zombie_cached))
      {
         self.classname = "monster_zombie";
         monster_zombie();
      }
      else if (rndm < 0.75 * (pick_any | spawn_cached))
      {
         self.classname = "monster_tarbaby";
         monster_tarbaby();
      }
      else
      {
         monster_wizard();
      }
   }
};

//======================================================================================

void() swap_monster =
{
   // check monster hasn't already been switched
   // need to limit the number of monster types in levels to prevent overflow
   if (!self.switched)
   {
      if (monstertypes < MAX_MONSTER_TYPES)
      {
         // pick a new equivalent class (may result in a new class)
         choose_equivalent_monster(TRUE);
      }
      else
      {
         // pick a monster from those already cached
         choose_equivalent_monster(FALSE);
      }
   }
   else
      return;
};



/*
void() swap_ammo =
{
   // check monster hasn't already been switched
   if (!self.switched)
      choose_equivalent_monster();
   else
      return;
};
*/
