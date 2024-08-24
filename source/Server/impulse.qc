// impulse.qc
/*---public---*/
// $VER: impulse.qc 1.89 � Karlos (14/04/2000)

// public function prototypes
   void() ImpulseCommands;
   void() ImpulseCommands_2;
   void() ImpulseCommands_3;

/*---private---*/
//==============================================================================
//
//   IMPULSE - MAIN FUNCTION
//      Sets up impulse commands, handles effects switches
//
//==============================================================================
void() ImpulseCommands =
{
   // These commands are only valid for a living client

   // Weapon selection...
   if (self.impulse >= 1 && self.impulse <= 8)
      W_ChangeWeapon ();
   if (self.impulse == IM_WEAPONNEXT)
      CycleWeaponCommand ();
   if (self.impulse == IM_WEAPONPREV)
      CycleWeaponReverseCommand ();

   if (self.impulse == IM_DROPWEAPON)
      drop_item (self.weapon);
   if (self.impulse == IM_THROW_GRENADE)
      W_ThrowGrenade ();

   // Cheats...
   if (self.impulse == IM_RUNECHEAT)
      RuneCheat ();
   if (self.impulse == IM_CHEATITEMS)
      CheatCommand ();
   if (self.impulse == IM_QUADCHEAT)
      QuadCheat ();
   if (self.impulse == IM_INVISCHEAT)
      InvisibilityCheat ();
   if (self.impulse == IM_PROTECTCHEAT)
      ProtectCheat ();
   if (self.impulse == IM_BIOCHEAT)
      BiosuitCheat ();

   if (self.impulse == IM_USE_INVENTORY)
      toggle_inventory();
   if (self.impulse == IM_TOGGLE_SCREENMSG)
      toggle_screenmessages();
   if (self.impulse == IM_TOGGLE_TARGET)
      toggle_lasertarget(self);
   if (self.impulse == IM_TOGGLE_TORCH)
      toggle_torch(self);
   if (self.impulse == IM_TOGGLE_GUIDEDMISSILES)
      toggle_guidedmissiles();

   // grappling hook
   if (self.impulse == IM_RELEASE_GRAPPLE)
      unhook_grapple();
   if (self.impulse == IM_GRAPPLE_EXTEND)
      extend_grapple_chain();
   if (self.impulse == IM_GRAPPLE_SHORTEN)
      shorten_grapple_chain();
   if (self.impulse == IM_GRAPPLE_HANG)
      lock_grapple_chain();

   // inventory stuff
   if (self.impulse == IM_SHOW_INVENTORY)
      list_inventory();
   if (self.impulse == IM_ACTIVATE_SUIT)
      activate_inventory_item(IT_SUIT);
   if (self.impulse == IM_ACTIVATE_QUAD)
      activate_inventory_item(IT_QUAD);
   if (self.impulse == IM_ACTIVATE_RING)
      activate_inventory_item(IT_INVISIBILITY);
   if (self.impulse == IM_ACTIVATE_PENT)
      activate_inventory_item(IT_INVULNERABILITY);

//==============================================================================
// disabled until further notice
//
//   if (self.impulse == IM_BACKUPNAME)
//      backup_client_netname();
//   if ((self.impulse >= IM_SKIN_BASE) && (self.impulse < IM_SKIN_BASE + MAX_SKINS))
//      set_skin_name (self.impulse - IM_SKIN_BASE);
//   if (self.impulse == IM_RESTORENAME)
//      restore_client_netname();
//=============================================================================
 
    // check extended commands

    ImpulseCommands_2();
    ImpulseCommands_3();
    self.impulse = 0;
};

void () ImpulseCommands_2 =
{
   // These commands can be called by living or dead clients during a game
   // Toggles...

   // client toggles
   if (self.impulse == IM_TOGGLE_NAME_TARGETS)
      toggle_show_netnames();
   if (self.impulse == IM_GENDER)
      toggle_gender();
   if (self.impulse == IM_HANDEDNESS)
      cycle_handedness ();
   if (self.impulse == IM_SKIN_PREV)
      change_client_skin(0);
   if (self.impulse == IM_SKIN_NEXT)
      change_client_skin(1);
   if (self.impulse == IM_LOAD_SKIN)
      load_client_skin();

   if (self.impulse == IM_ION_PREV)
      cycle_ion_colour(0);
   if (self.impulse == IM_ION_NEXT)
      cycle_ion_colour(1);

   if (self.impulse == IM_TOGGLE_SMOOTH_SUBENTS)
      toggle_smooth_subents();

   // camera stuff
   if (self.impulse == IM_TOGGLE_CAMERA)
      camera_toggle();
   if (self.impulse == IM_CAMERA_DOWN)
      camera_change_zmult(0);
   if (self.impulse == IM_CAMERA_UP)
      camera_change_zmult(1);
   if (self.impulse == IM_CAMERA_IN)
      camera_change_dist(0);
   if (self.impulse == IM_CAMERA_OUT)
      camera_change_dist(1);
};

void () ImpulseCommands_3 =
{
   // These commands are also valid during an intermission

   // debug : team ai
   if (self.impulse == IM_DPRINT_TEAMS)
      dprint_team_stats ();

   if (self.impulse == IM_LIST_ARMY1_ENEMY)
      list_enemy_teams(TEAM_ARMY_1);
   if (self.impulse == IM_LIST_ARMY2_ENEMY)
      list_enemy_teams(TEAM_ARMY_2);
   if (self.impulse == IM_LIST_ARMY3_ENEMY)
      list_enemy_teams(TEAM_ARMY_3);
   if (self.impulse == IM_LIST_KNIGHT1_ENEMY)
      list_enemy_teams (TEAM_KNIGHT_1);
   if (self.impulse == IM_LIST_KNIGHT2_ENEMY)
      list_enemy_teams (TEAM_KNIGHT_2);
   if (self.impulse == IM_LIST_KNIGHT3_ENEMY)
      list_enemy_teams (TEAM_KNIGHT_3);
   if (self.impulse == IM_LIST_UNDEAD1_ENEMY)
      list_enemy_teams (TEAM_UNDEAD_1);
   if (self.impulse == IM_LIST_UNDEAD2_ENEMY)
      list_enemy_teams (TEAM_UNDEAD_2); 
   if (self.impulse == IM_LIST_UNDEAD3_ENEMY)
      list_enemy_teams (TEAM_UNDEAD_3);    
   if (self.impulse == IM_LIST_OGRE1_ENEMY)
      list_enemy_teams (TEAM_OGRE_1); 
   if (self.impulse == IM_LIST_OGRE2_ENEMY)
      list_enemy_teams (TEAM_OGRE_2); 
   if (self.impulse == IM_LIST_OGRE3_ENEMY)
      list_enemy_teams (TEAM_OGRE_3);

   if (self.impulse == IM_SET_ALL_ENEMY)
      set_enemy_all();
   if (self.impulse == IM_SET_DEFAULT_ENEMY) 
      set_enemy_none();

   // debug : security
   if (self.impulse == IM_A_SERVERMASTER)
   {
      administrator = self;
      self.server_master = CL_ADMIN;
      self.server_access = CL_SERVER_ACCESS;
      sprint(self, "Your'e server master\n");
   }
   if (self.impulse == IM_NOT_A_SERVERMASTER)
   {
      self.server_master = FALSE;
      self.server_access = FALSE;
      sprint(self, "Your'e not server master\n");
   }

   // server toggles : security
   if (self.impulse == IM_SHOW_KEY)
      show_server_key();
   if (self.impulse == IM_CHECK_KEY)
      check_client_key();
   if (self.impulse == IM_TOGGLE_ADMIN_MSG)
      toggle_admin_messages();
   if (self.impulse == IM_VERSION_INFO)
      version_info();

   // server toggles : gameplay
   if (self.impulse == IM_TOGGLE_SHRAPNEL)
      toggle_shrapnel();
   if (self.impulse == IM_TOGGLE_MIKERULES)
      toggle_mikerules();
   if (self.impulse == IM_TOGGLE_RANDOMGAME)
      toggle_randomgame();

   // server toggles : lighting
   if (self.impulse == IM_CYCLE_LIGHTS)
      cycle_light_fx();
   if (self.impulse == IM_TOGGLE_FLASH)
      toggle_flash_fx();
   if (self.impulse == IM_TOGGLE_GLOW)
      toggle_glow_fx();
   if (self.impulse == IM_TOGGLE_STATIC)
      toggle_static_fx();

   // server toggles : explosions
   if (self.impulse == IM_CYCLE_EXPLODE)
      cycle_explode_fx();
   if (self.impulse == IM_TOGGLE_FASTEXP)
      toggle_fast_explode();
   if (self.impulse == IM_TOGGLE_MULTIEXP)
      toggle_multi_explode();
   if (self.impulse == IM_TOGGLE_SMARTEXP)
      toggle_smart_explode();

   // console fx
   if (self.impulse == IM_TOGGLE_GAMMA)
      toggle_con_gamma();
   if (self.impulse == IM_TOGGLE_CON_FLASH)
      toggle_con_flash();
   if (self.impulse == IM_TOGGLE_FOV)
      toggle_con_fov();

   // sound
   if (self.impulse == IM_TOGGLE_SOUND_LIMIT)
      toggle_sound_limit();
   if (self.impulse == IM_TOGGLE_SOUND_ENHANCE)
      toggle_sound_plus();

   // violence
   if (self.impulse == IM_CYCLE_VIOLENCE)
      cycle_violence();
   if (self.impulse == IM_TOGGLE_BLOOD)
      toggle_blood();
   if (self.impulse == IM_TOGGLE_GIBS)
      toggle_gibs();
   if (self.impulse == IM_TOGGLE_CORPSE)
      toggle_corpse();
};
