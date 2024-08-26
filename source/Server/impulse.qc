// impulse.qc
/*---public---*/
// $VER: impulse.qc 1.89 Karlos (14/04/2000)

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
void() ImpulseCommands = {
    // These commands are only valid for a living client

    // TODO - Reorganise impulses into logical ranges to assist a depth first
    //        match for effiency.

    // Weapon selection...
    if (self.impulse >= 1 && self.impulse <= 8) {
        W_ChangeWeapon();
        return;
    }

    if (self.impulse == IM_WEAPONNEXT) {
        CycleWeaponCommand();
        return;
    }

    if (self.impulse == IM_WEAPONPREV) {
        CycleWeaponReverseCommand();
        return;
    }

    if (self.impulse == IM_TOGGLE_TORCH) {
        inv_toggle_torch(self);
        return;
    }

    if (self.impulse == IM_THROW_GRENADE) {
        W_ThrowGrenade();
        return;
    }

    if (self.impulse == IM_DROPWEAPON) {
        inv_drop_item(self.weapon);
        return;
    }

    // grappling hook
    if (self.impulse == IM_RELEASE_GRAPPLE) {
        inv_grapple_release();
        return;
    }

    if (self.impulse == IM_GRAPPLE_EXTEND) {
        inv_grapple_extend();
        return;
    }

    if (self.impulse == IM_GRAPPLE_RETRACT) {
        inv_grapple_retract();
        return;
    }

    if (self.impulse == IM_GRAPPLE_LOCK) {
        inv_grapple_lock();
        return;
    }

    if (self.impulse == IM_ACTIVATE_SUIT) {
        inv_equip_item(IT_SUIT);
        return;
    }

    if (self.impulse == IM_ACTIVATE_QUAD) {
        inv_equip_item(IT_QUAD);
        return;
    }

    if (self.impulse == IM_ACTIVATE_RING) {
        inv_equip_item(IT_INVISIBILITY);
        return;
    }

    if (self.impulse == IM_ACTIVATE_PENT) {
        inv_equip_item(IT_INVULNERABILITY);
        return;
    }

    // Cheats...
    if (self.impulse == IM_RUNECHEAT) {
        RuneCheat();
        return;
    }

    if (self.impulse == IM_CHEATITEMS) {
        CheatCommand();
        return;
    }

    if (self.impulse == IM_QUADCHEAT) {
        QuadCheat();
        return;
    }

    if (self.impulse == IM_INVISCHEAT) {
        InvisibilityCheat();
        return;
    }

    if (self.impulse == IM_PROTECTCHEAT) {
        ProtectCheat();
        return;
    }

    if (self.impulse == IM_BIOCHEAT) {
        BiosuitCheat();
    }

    if (self.impulse == IM_USE_INVENTORY) {
        inv_toggle();
        return;
    }

    if (self.impulse == IM_TOGGLE_SCREENMSG) {
        toggle_screenmessages();
        return;
    }

    if (self.impulse == IM_TOGGLE_TARGET) {
        inv_toggle_target(self);
        return;
    }

    if (self.impulse == IM_TOGGLE_GUIDEDMISSILES) {
        toggle_guidedmissiles();
        return;
    }

    // inventory stuff
    if (self.impulse == IM_SHOW_INVENTORY) {
        inv_list_items();
        return;
    }
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

void() ImpulseCommands_2 = {
    // These commands can be called by living or dead clients during a game
    // Toggles...

    // client toggles
    if (self.impulse == IM_TOGGLE_NAME_TARGETS) {
        toggle_show_netnames();
        return;
    }
    if (self.impulse == IM_GENDER) {
        toggle_gender();
        return;
    }
    if (self.impulse == IM_HANDEDNESS) {
        cycle_handedness();
        return;
    }
    if (self.impulse == IM_SKIN_PREV) {
        change_client_skin(0);
        return;
    }
    if (self.impulse == IM_SKIN_NEXT) {
        change_client_skin(1);
        return;
    }
    if (self.impulse == IM_LOAD_SKIN) {
        load_client_skin();
        return;
    }
    if (self.impulse == IM_ION_PREV) {
        cycle_ion_colour(0);
        return;
    }
    if (self.impulse == IM_ION_NEXT) {
        cycle_ion_colour(1);
        return;
    }

    if (self.impulse == IM_TOGGLE_SMOOTH_SUBENTS) {
        toggle_smooth_subents();
        return;
    }
    // camera stuff
    if (self.impulse == IM_TOGGLE_CAMERA) {
        camera_toggle();
        return;
    }
    if (self.impulse == IM_CAMERA_DOWN) {
        camera_change_zmult(0);
        return;
    }
    if (self.impulse == IM_CAMERA_UP) {
        camera_change_zmult(1);
        return;
    }
    if (self.impulse == IM_CAMERA_IN) {
        camera_change_dist(0);
        return;
    }
    if (self.impulse == IM_CAMERA_OUT) {
        camera_change_dist(1);
        return;
    }
};

void () ImpulseCommands_3 = {
    // These commands are also valid during an intermission

    // debug : team ai
    if (self.impulse == IM_DPRINT_TEAMS) {
        dprint_team_stats();
        return;
    }
    if (self.impulse == IM_LIST_ARMY1_ENEMY) {
        list_enemy_teams(TEAM_ARMY_1);
        return;
    }
    if (self.impulse == IM_LIST_ARMY2_ENEMY) {
        list_enemy_teams(TEAM_ARMY_2);
        return;
    }
    if (self.impulse == IM_LIST_ARMY3_ENEMY) {
        list_enemy_teams(TEAM_ARMY_3);
        return;
    }
    if (self.impulse == IM_LIST_KNIGHT1_ENEMY) {
        list_enemy_teams(TEAM_KNIGHT_1);
        return;
    }
    if (self.impulse == IM_LIST_KNIGHT2_ENEMY) {
        list_enemy_teams(TEAM_KNIGHT_2);
        return;
    }
    if (self.impulse == IM_LIST_KNIGHT3_ENEMY) {
        list_enemy_teams(TEAM_KNIGHT_3);
        return;
    }
    if (self.impulse == IM_LIST_UNDEAD1_ENEMY) {
        list_enemy_teams(TEAM_UNDEAD_1);
        return;
    }
    if (self.impulse == IM_LIST_UNDEAD2_ENEMY) {
        list_enemy_teams(TEAM_UNDEAD_2);
        return;
    }
    if (self.impulse == IM_LIST_UNDEAD3_ENEMY) {
        list_enemy_teams(TEAM_UNDEAD_3);
        return;
    }
    if (self.impulse == IM_LIST_OGRE1_ENEMY) {
        list_enemy_teams(TEAM_OGRE_1);
        return;
    }
    if (self.impulse == IM_LIST_OGRE2_ENEMY) {
        list_enemy_teams(TEAM_OGRE_2);
        return;
    }
    if (self.impulse == IM_LIST_OGRE3_ENEMY) {
        list_enemy_teams(TEAM_OGRE_3);
        return;
    }

    if (self.impulse == IM_SET_ALL_ENEMY) {
        set_enemy_all();
        return;
    }
    if (self.impulse == IM_SET_DEFAULT_ENEMY) {
        set_enemy_none();
        return;
    }
    // debug : security
    if (self.impulse == IM_A_SERVERMASTER) {
        administrator = self;
        self.server_master = CL_ADMIN;
        self.server_access = CL_SERVER_ACCESS;
        sprint(self, "Your'e server master\n");
        return;
    }
    if (self.impulse == IM_NOT_A_SERVERMASTER) {
        self.server_master = FALSE;
        self.server_access = FALSE;
        sprint(self, "Your'e not server master\n");
        return;
    }

    // server toggles : security
    if (self.impulse == IM_SHOW_KEY) {
        show_server_key();
        return;
    }
    if (self.impulse == IM_CHECK_KEY) {
        check_client_key();
        return;
    }
    if (self.impulse == IM_TOGGLE_ADMIN_MSG) {
        toggle_admin_messages();
        return;
    }
    if (self.impulse == IM_VERSION_INFO) {
        version_info();
        return;
    }
    // server toggles : gameplay
    if (self.impulse == IM_TOGGLE_SHRAPNEL) {
        toggle_shrapnel();
        return;
    }
    if (self.impulse == IM_TOGGLE_MIKERULES) {
        toggle_mikerules();
        return;
    }
    if (self.impulse == IM_TOGGLE_RANDOMGAME) {
        toggle_randomgame();
        return;
    }

    // server toggles : lighting
    if (self.impulse == IM_CYCLE_LIGHTS) {
        cycle_light_fx();
        return;
    }
    if (self.impulse == IM_TOGGLE_FLASH) {
        toggle_flash_fx();
        return;
    }
    if (self.impulse == IM_TOGGLE_GLOW) {
        toggle_glow_fx();
        return;
    }
    if (self.impulse == IM_TOGGLE_STATIC) {
        toggle_static_fx();
        return;
    }
    // server toggles : explosions
    if (self.impulse == IM_CYCLE_EXPLODE) {
        cycle_explode_fx();
        return;
    }
    if (self.impulse == IM_TOGGLE_FASTEXP) {
        toggle_fast_explode();
        return;
    }
    if (self.impulse == IM_TOGGLE_MULTIEXP) {
        toggle_multi_explode();
        return;
    }
    if (self.impulse == IM_TOGGLE_SMARTEXP) {
        toggle_smart_explode();
        return;
    }
    // console fx
    if (self.impulse == IM_TOGGLE_GAMMA) {
        toggle_con_gamma();
        return;
    }
    if (self.impulse == IM_TOGGLE_CON_FLASH) {
        toggle_con_flash();
        return;
    }
    if (self.impulse == IM_TOGGLE_FOV) {
        toggle_con_fov();
        return;
    }

    // sound
    if (self.impulse == IM_TOGGLE_SOUND_LIMIT) {
        toggle_sound_limit();
        return;
    }
    if (self.impulse == IM_TOGGLE_SOUND_ENHANCE) {
        toggle_sound_plus();
        return;
    }
    // violence
    if (self.impulse == IM_CYCLE_VIOLENCE) {
        cycle_violence();
        return;
    }
    if (self.impulse == IM_TOGGLE_BLOOD) {
        toggle_blood();
        return;
    }
    if (self.impulse == IM_TOGGLE_GIBS) {
        toggle_gibs();
        return;
    }
    if (self.impulse == IM_TOGGLE_CORPSE) {
        toggle_corpse();
        return;
    }
};
