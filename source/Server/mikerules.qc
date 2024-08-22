// mikerules.qc
/*---public---*/
// $VER: mikerules 1.04 © Mike 'XC' Childs, coded by Karlos (03/10/1999)

// public function prototypes
// lowlevel
   float (float unjamtime, float current_damage) check_weapon_jam;
   void (entity attacker, entity targ, float inflicted) apply_weapon_damage;
   void(float bitblock) decode_weapon_damagestats;
   float() encode_weapon_damagestats;
/*---private---*/

//========================================================================
//
//  check_weapon_jam(float unjamtime, float current_damage)
//
//========================================================================
float (float unjamtime, float current_damage) check_weapon_jam =
{
   // self is client
   if (mikerules && (random() < current_damage/20))
   {
      if (self.extraflags & CL_MESSAGEBIT)
         centerprint (self, "Your weapon has jammed !\n");
      sound (self, CHAN_WEAPON, "weapons/jam.wav", 1, ATTN_NORM);
      // increase jam time with skill
      self.attack_finished = time + 0.2 + (unjamtime * skill)/3;
      return TRUE;
   }
   else
      return FALSE;
};



//========================================================================
//
//   decode_weapon_damagestats(float bitblock)
//
//   decodes a 32-bit block of damage stats for a player. self is client
//   called from client/client.qc during DecodeLevelParms()
//
//========================================================================
void(float bitblock) decode_weapon_damagestats =
{
   // decode a block of 4-bit values
   self.weapon_00_damage = 0;
   self.weapon_01_damage = bitblock & MR_SHOTGUN_DAMAGE;
   self.weapon_02_damage = (bitblock & MR_SUPERSHOT_DAMAGE) / MR_SUPERSHOT_OFFSET;
   self.weapon_03_damage = (bitblock & MR_NAILGUN_DAMAGE)   / MR_NAILGUN_OFFSET;
   self.weapon_04_damage = (bitblock & MR_SUPERNAIL_DAMAGE) / MR_SUPERNAIL_OFFSET;
   self.weapon_05_damage = (bitblock & MR_GRENADE_DAMAGE)   / MR_GRENADE_OFFSET;
   self.weapon_06_damage = (bitblock & MR_ROCKET_DAMAGE)    / MR_ROCKET_OFFSET;
   self.weapon_07_damage = (bitblock & MR_THUNDER_DAMAGE)   / MR_THUNDER_OFFSET;
};


//========================================================================
//
//   bitblock = encode_weapon_damagestats()
//
//   creates a 32-bit block of damage stats for a player. self is client
//   called from client/client.qc during SetChangeParms()
//
//========================================================================
float() encode_weapon_damagestats =
{
   local float encode;
   // encode a block of 4-bit values
   // encode = rint(self.weapon_01_damage); - forget shotgun damage
   encode = 0;

   encode = encode + MR_SUPERSHOT_OFFSET * rint(self.weapon_02_damage);
   encode = encode + MR_NAILGUN_OFFSET   * rint(self.weapon_03_damage);
   encode = encode + MR_SUPERNAIL_OFFSET * rint(self.weapon_04_damage);
   encode = encode + MR_GRENADE_OFFSET   * rint(self.weapon_05_damage);
   encode = encode + MR_ROCKET_OFFSET    * rint(self.weapon_06_damage);
   encode = encode + MR_THUNDER_OFFSET   * rint(self.weapon_07_damage);
   return encode;
};


//=============================================================================
//
//   if (mikerules)
//      apply_weapon_damage(entity attacker, entity targ, float inflicted)
//
//   Handles weapon damage calculations etc. 
//   called from ai/combat.qc, during T_Damage(), only if mikerules != FALSE
//   'inflicted' is damage value calculated by T_Damage() after armour/pentagram
//   has been taken into consideration.
//
//==============================================================================
void (entity attacker, entity targ, float inflicted) apply_weapon_damage =
{
   local float weapontake, dot;
   local vector dir;

   // if damaged entity is a player, inflict some damage to current weapon...
   // weapon damage = 0 (unscathed) to 15 (knackered)

   if (targ.flags & FL_CLIENT)
   {
      // weapon should be damaged more by attacks from front, minimum is 2 %
      weapontake = (inflicted/50);

      // evaluate orientation / position of attacker relative to targ
      // calculate as in ai.qc/infront(), but make more precise definition

      makevectors (attacker.angles);
      dir = normalize (targ.origin - attacker.origin);
      dot = dir * v_forward;

      // if 'infront', increase hit points, increase relative to skill

      if (dot > 0.3)
         weapontake = weapontake * (1 + skill/3);

      // apply damage and check for overflow

      if (targ.weapon == IT_AXE)
         targ.weapon_00_damage = 0; // axe is inviolate
      else if (targ.weapon == IT_SHOTGUN)
      {
         targ.weapon_01_damage = targ.weapon_01_damage + weapontake;
         if (targ.weapon_01_damage > 15)
            targ.weapon_01_damage = 15;
      }
      else if (targ.weapon == IT_SUPER_SHOTGUN)
      {
         targ.weapon_02_damage = targ.weapon_02_damage + weapontake;
         if (targ.weapon_02_damage > 15)
            targ.weapon_02_damage = 15;
      }
      else if (targ.weapon == IT_NAILGUN)
      {
         targ.weapon_03_damage = targ.weapon_03_damage + weapontake;
         if (targ.weapon_03_damage > 15)
            targ.weapon_03_damage = 15;
      }
      else if (targ.weapon == IT_SUPER_NAILGUN)
      {
         targ.weapon_04_damage = targ.weapon_04_damage + weapontake;
         if (targ.weapon_04_damage > 15)
            targ.weapon_04_damage = 15;
      }
      else if (targ.weapon == IT_GRENADE_LAUNCHER)
      {
         targ.weapon_05_damage = targ.weapon_05_damage + weapontake;
         if (targ.weapon_05_damage > 15)
            targ.weapon_05_damage = 15;
      }
      else if (targ.weapon == IT_ROCKET_LAUNCHER)
      {
         targ.weapon_06_damage = targ.weapon_06_damage + weapontake;
         if (targ.weapon_06_damage > 15)
            targ.weapon_06_damage = 15;
      }
      else if (targ.weapon == IT_LIGHTNING)
      {
         targ.weapon_07_damage = targ.weapon_07_damage + weapontake;
         if (targ.weapon_07_damage > 15)
            targ.weapon_07_damage = 15;
      }
   }
};

void() version_mikerules =
{
   sprint(self, "mikerules 1.04 Karlos '99 (03/10/1999)\n");
};

//------------------------------------------------------------------------------------
//
// XREF system/defs.qc, defined constants / structure entries
//
// Mike Rules stuff...
//
//    We allow weapon to recieve damage as well as player.
//    The damage of the weapon, relative to it's normal state, is used to
//    calculate a reliability factor. This in turn will be used to introduce weapon jams
//    We can also then set the damage value as a health value for a weapon drop using
//    client/inventory.qc - drop_item(), such that dropped weapons inherit the damage
//    as a health value, hence no need to define extra vars for world/items.qc
//
//    External functions requiring modification / coding
//
//    client/weapons.qc/W_Attack()        - add reliability / jamming of current weapon
//    client/weapons.qc/SetCurrentAmmo    - add damage report to current ammo stats
//                                          when in easy / normal skill
//    client/client.qc/DecodeLevelParms() - add decode_weapon_damagestats()
//    client/client.qc/SetChangeParms()   - add encode_weapon_damagestats()
//    client/client.qc/SetNewParms()      - clear/default damage stats
//    client/client_extra.qc/save_client_extraparms - add MR_ENABLE to temp1 save
//    client/inventory.qc/drop_item()     - enable and add code for damge > health
//                                          inheritance
//    world/items.qc/become_pickup()      - new function needed to allow dropped
//                                          thing to be recollected after a time
//                                          (using self.think = become_pickup())
//    world/items.qc/dropped_touch()      - new function needed to define action
//                                          of dropped items on self.touch
//                                          (can't use weapon_touch() directly, too
//                                          many changes needed - not worth it)
//    world/items.qc/weapon_touch()       - need to block collection of weapons already
//                                          belonging to self
//
// Constants needed for storage
//
//    All 7 weapon stats stored in 32 bit float value (axe not included)
//    bit     <<28  <<24  <<20  <<16  <<12  <<08  <<04 <<00
//    mask  xxxx  tttt  rrrr  gggg  NNNN  nnnn  SSSS ssss
//
//
// bitmasks for damage - only integer damage part, 0-15
//
//    float MR_SHOTGUN_DAMAGE       = 15;         //  0x00 00 00 0f - ssss
//    float MR_SUPERSHOT_DAMAGE     = 240;        //  0x00 00 00 f0 - SSSS
//    float MR_NAILGUN_DAMAGE       = 3840;       //  0x00 00 0f 00 - nnnn
//    float MR_SUPERNAIL_DAMAGE     = 61440;      //  0x00 00 f0 00 - NNNN
//    float MR_GRENADE_DAMAGE       = 983040;     //  0x00 0f 00 00 - gggg
//    float MR_ROCKET_DAMAGE        = 15728640;   //  0x00 f0 00 00 - rrrr
//    float MR_THUNDER_DAMAGE       = 251658240;  //  0x0f 00 00 00 - tttt
//
//
// offsets for damage storage
//
//    float MR_SHOTGUN_OFFSET       = 1;          //  0x00 00 00 01 - bit# 00
//    float MR_SUPERSHOT_OFFSET     = 16;         //  0x00 00 00 10 - bit# 04
//    float MR_NAILGUN_OFFSET       = 256;        //  0x00 00 01 00 - bit# 08
//    float MR_SUPERNAIL_OFFSET     = 4096;       //  0x00 00 10 00 - bit# 12
//    float MR_GRENADE_OFFSET       = 65536;      //  0x00 01 00 00 - bit# 16
//    float MR_ROCKET_OFFSET        = 1048576;    //  0x00 10 00 00 - bit# 20
//    float MR_THUNDER_OFFSET       = 16777216;   //  0x01 00 00 00 - bit# 24
//
//
// flags needed
//
//    float MR_ENABLE               = 1048576;    //  Mike Rules flag, set im parm16
//
//
// additional client fields needed
//
//    used to hold the active values of weapon damage during play
//
//    .float      weapon_00_damage;    // axe damage level
//    .float      weapon_01_damage;    // shotgun damage level
//    .float      weapon_02_damage;    // super shotgun damage level
//    .float      weapon_03_damage;    // nailgun damage level
//    .float      weapon_04_damage;    // super nailgun damage level
//    .float      weapon_05_damage;    // grenade launcher damage level
//    .float      weapon_06_damage;    // rocket launcher damage level
//    .float      weapon_07_damage;    // thunderbolt damage level
//
//-----------------------------------------------------------------------------------
