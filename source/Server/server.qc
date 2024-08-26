// server.qc
/*---public---*/
// $VER: server.qc, 1.94 © Karlos (17/10/1999)

// public function prototypes
// highlevel
   void() toggle_admin_messages;
   void() show_server_key;
   void() check_client_key;

   // lighting
   void() cycle_light_fx;
   void() toggle_glow_fx;
   void() toggle_flash_fx;
   void() toggle_static_fx;

   // explosions
   void() cycle_explode_fx;
   void() toggle_fast_explode;
   void() toggle_multi_explode;
   void() toggle_smart_explode;

   // console fx
   void() toggle_con_gamma;
   void() toggle_con_flash;
   void() toggle_con_fov;

   // sound
   void() toggle_sound_limit;
   void() toggle_sound_plus;

   // violence
   void() cycle_violence;
   void() toggle_blood;
   void() toggle_gibs;
   void() toggle_corpse;

   // gameplay
   void() toggle_shrapnel;
   void() toggle_mikerules;
   void() toggle_randomgame;

// lowlevel
   void() save_server_opts;
   void() set_server_opts;
   void() default_server_opts;
   void() create_server_key;
   void(entity e) report_to_administrator;

/*---private---*/

   float(entity who) no_access;
   void(string msg_string) broadcast;
   float serverkey;


//=======================================================================================
//
//   Server Parameter save/set/def
//
//=======================================================================================

void() save_server_opts =
{
   local float settings;
   local string save_flags;

   // if dm/coop, save the settings for the NEXT game, else save current settings


   // gameplay can only be changed on the next game (no cheating ;)

   settings = GAME_REGISTERED | server_change_next_game | (FX_SAVEBITS_OFFSET * effectflags);

   save_flags = ftos(settings);
   //dprint (save_flags);
   //dprint ("\n");
   cvar_set("registered", save_flags);
};

//=======================================================================================

void() set_server_opts =
{
   local float load_reg;

   // should ONLY be called from administrators connect/spawn function...

   load_reg = cvar("registered");

   if (!(load_reg > 1))
      default_server_opts();

   // shrapnel
   shrapnel = load_reg & GAME_SHRAPNEL;

   // mikerules
   mikerules = load_reg & GAME_MIKERULES;

   // random game
   // randomgame = load_reg & GAME_RANDOM;

   // get first 8 bits of registered for gameplay settings
   server_change_next_game = load_reg & 255;

   effectflags = rint(load_reg/FX_SAVEBITS_OFFSET);
};

void() default_server_opts =
{
   // default hard coded server options
   dprint ("Using internal server defaults\n");
   effectflags = FX_LIGHTS | FX_COOL_EXP | FX_CON_FLASH | FX_SOUND_LIMIT | FX_GORE_FULLON;
   server_change_next_game = 0;
   save_server_opts();
};


//=======================================================================================
//
//   Server/Client Security
//
//=======================================================================================

void() create_server_key =
{
   // creates a random server access key. Key cannot be zero.

   while (!serverkey)
   {
      serverkey = rint(1000000 * random() * random());
   }
};

//=======================================================================================

void() show_server_key =
{
   local string temp_string;
   if (!self.server_access)
   {
      sprint (self, "You do not have server access\n");
      return;
   }
   else
   {
      temp_string = ftos(serverkey);
      sprint(self, "Current Server Key : ");
      sprint(self, temp_string);
      sprint(self, "\n");
   }
};

//=======================================================================================

void() check_client_key =
{
   local float clientkey;
   local string temp_string;

   temp_string = ftos(self.cl_color);

   clientkey = rint(cvar("_cl_color"));
   cvar_set("_cl_color", temp_string);

   if (clientkey == serverkey)
   {
      screen_message(self, "You are granted server access", MSG_INFO, TRUE);
      self.server_access = CL_SERVER_ACCESS;
   }
};

//=======================================================================================

void(entity e) report_to_administrator =
{
   if ((e != administrator) && adminmessages)
   {
      sprint (administrator, e.netname);
      sprint (administrator, " is ready...\n");
   }
   if (deathmatch || coop)
      centerprint (administrator, "You have server control\n");
};

//=======================================================================================

void() toggle_admin_messages =
{
   if (!self.server_master)
      return;
/*
   // if only 1 client, don't bother
   if (clientcount < 2)
      return;
*/
   if (!adminmessages)
   {
      adminmessages = TRUE;
      sprint (administrator, "admin messages enabled\n");
   }
   else
   {
      adminmessages = FALSE;
      sprint (administrator, "admin messages disabled\n");
   }
};

//=======================================================================================

float(entity who) no_access =
{
   if (!who.server_access)
   {
      sound (who, CHAN_AUTO, "misc/msg_warning.wav", 1, ATTN_NORM);
      sprint (who, "You do not have access to the server settings\n");
      return TRUE;
   }
   return FALSE;
};

//=======================================================================================

void(string msg_string) broadcast =
{
   sound (world, CHAN_AUTO, "misc/message2.wav", 1, ATTN_NONE);
   bprint ("server : "); bprint(msg_string); bprint("\n");
};



//=======================================================================================
//
//   Server Lighting Effects switches
//
//=======================================================================================

void() cycle_light_fx =
{
   local float lights;

   if (no_access(self))
      return;

   // get light current flags from effectflags
   lights = ((effectflags | FX_NO_LIGHTS) & FX_LIGHTS);

   if (lights == FX_LIGHTS)
   {
      lights = FX_NO_FLASH;
      broadcast ("flash effects deactivated");
   }
   else if (lights == FX_NO_FLASH)
   {
      lights = FX_NO_GLOW;
      broadcast ("glow effects deactivated");
   }
   else if (lights == FX_NO_GLOW)
   {
      lights = FX_NO_LIGHTS;
      broadcast ("all lighting effects deactivated");
   }
   else if (lights == FX_NO_LIGHTS)
   {
      lights = FX_LIGHTS;
      broadcast ("all lighting effects activated");
   }

   // strip old lighting bits
   effectflags = effectflags - (effectflags & FX_LIGHTS);

   // set new lighting bits
   effectflags = effectflags | lights;
};

void() toggle_flash_fx =
{
   if (no_access(self))
      return;

   if (effectflags & FX_FLASH)
   {
      effectflags = effectflags - FX_FLASH;
      broadcast ("flash effects disabled");
   }
   else
   {
      effectflags = effectflags | FX_FLASH;
      broadcast ("flash effects enabled");
   }
};

void() toggle_glow_fx =
{
   if (no_access(self))
      return;

   if (effectflags & FX_GLOW)
   {
      effectflags = effectflags - FX_GLOW;
      broadcast ("glow effects disabled");
   }
   else
   {
      effectflags = effectflags | FX_GLOW;
      broadcast ("glow effects enabled");
   }
};

void() toggle_static_fx =
{
   if (no_access(self))
      return;

   if (effectflags & FX_WORLDSTATIC)
   {
      effectflags = effectflags - FX_WORLDSTATIC;
      broadcast ("ambient light fx enabled");
   }
   else
   {
      effectflags = effectflags | FX_WORLDSTATIC;
      broadcast ("ambient light fx disabled");
   }
   set_light_tables(effectflags & FX_WORLDSTATIC);
};



//=======================================================================================
//
//   Server Explosion Effect switches
//
//=======================================================================================

void() cycle_explode_fx =
{
   local float exp_fx;

   if (no_access(self))
      return;

   exp_fx = effectflags & FX_EXP_BITS;
   // clear explosion settings
   effectflags = effectflags - exp_fx;

   if (exp_fx > 256)
   {
      // cool -> turbo
      effectflags = effectflags | FX_TURBO_EXP;
      broadcast ("explosions turbo");
   }

   else if (exp_fx == 0)
   {
      // normal -> cool
      effectflags = effectflags | FX_COOL_EXP;
      broadcast ("explosions cool");
   }
   else if (exp_fx == 256)
   {
      // fast -> normal
      broadcast ("explosions normal");
   }
};

void() toggle_fast_explode =
{
   if (no_access(self))
      return;

   if (effectflags & FX_FAST_EXP)
   {
      effectflags = effectflags - FX_FAST_EXP;
      broadcast ("explosions normal");
   }
   else
   {
      effectflags = effectflags | FX_FAST_EXP;
      broadcast ("explosions fast");
   }
};

void() toggle_multi_explode =
{
   if (no_access(self))
      return;

   if (effectflags & FX_MULTI_EXP)
   {
      effectflags = effectflags - FX_MULTI_EXP;
      broadcast ("multiframe explosions off");
   }
   else
   {
      effectflags = effectflags | FX_MULTI_EXP;
      broadcast ("multiframe explosions on");
   }
};

void() toggle_smart_explode =
{
   if (no_access(self))
      return;

   if (effectflags & FX_SMART_EXP)
   {
      effectflags = effectflags - FX_SMART_EXP;
      broadcast ("explosions simple");
   }
   else
   {
      effectflags = effectflags | FX_SMART_EXP;
      broadcast ("explosions smart");
   }
};



//=======================================================================================
//
//   Server Console Effects switches
//
//=======================================================================================

void() toggle_con_gamma =
{
   if (no_access(self))
      return;

   if (effectflags & FX_CON_GAMMA)
   {
      effectflags = effectflags - FX_CON_GAMMA;
      broadcast ("gamma effects disabled");
   }
   else
   {
      effectflags = effectflags | FX_CON_GAMMA;
      broadcast ("gamma effects enabled");
   }
};

//=========================================================================================

void() toggle_con_flash =
{
   if (no_access(self))
      return;

   if (effectflags & FX_CON_FLASH)
   {
      effectflags = effectflags - FX_CON_FLASH;
      broadcast ("screen flash effects disabled");
   }
   else
   {
      effectflags = effectflags | FX_CON_FLASH;
      broadcast ("screen flash effects enabled");
   }

};

//=========================================================================================

void() toggle_con_fov =
{
   if (no_access(self))
      return;

   if (effectflags & FX_CON_FOV)
   {
      effectflags = effectflags - FX_CON_FOV;
      broadcast ("field of view effects disabled");
   }
   else
   {
      effectflags = effectflags | FX_CON_FOV;
      broadcast ("field of view effects enabled");
   }
};

//=======================================================================================
//
//   Server Sound Engine switches
//
//=======================================================================================

void() toggle_sound_limit =
{
   if(no_access(self))
      return;

   if (effectflags & FX_SOUND_LIMIT)
   {
      effectflags = effectflags - FX_SOUND_LIMIT;
      broadcast ("sound limiting disabled");
   }
   else
   {
      effectflags = effectflags | FX_SOUND_LIMIT;
      broadcast ("sound limiting enabled");
   }
};

void() toggle_sound_plus =
{
   if(no_access(self))
      return;

   if (effectflags & FX_SOUND_PLUS)
   {
      effectflags = effectflags - FX_SOUND_PLUS;
      broadcast ("sound enhance disabled");
   }
   else
   {
      effectflags = effectflags | FX_SOUND_PLUS;
      broadcast ("sound enhance enabled");
   }
};


//=======================================================================================
//
//   Server Violence switches
//
//=======================================================================================

void() cycle_violence =
{
   if (no_access(self))
      return;

   if (!(effectflags & FX_GORE_BLOOD))
   {
      // clear corpse flag and set other two
      effectflags = (effectflags - (effectflags & FX_GORE_CORPSE)) | FX_GORE_NORMAL;
      broadcast ("violence normal");
   }
   else if (!(effectflags & FX_GORE_CORPSE))
   {
      // set to maximum gore
      effectflags = effectflags | FX_GORE_FULLON;
      broadcast ("violence maximum");
   }
   else if (effectflags & FX_GORE_CORPSE)
   {
      // clear all violence
      effectflags = effectflags - (effectflags & FX_GORE_FULLON);
      broadcast ("violence minimum");
   }
};

void() toggle_blood =
{
   if(no_access(self))
      return;

   if (effectflags & FX_GORE_BLOOD)
   {
      effectflags = effectflags - FX_GORE_BLOOD;
      broadcast ("blood disabled");
   }
   else
   {
      effectflags = effectflags | FX_GORE_BLOOD;
      broadcast ("blood enabled");
   }
};


void() toggle_gibs =
{
   if(no_access(self))
      return;

   if (effectflags & FX_GORE_GIBS)
   {
      effectflags = effectflags - FX_GORE_GIBS;
      broadcast ("giblets disabled");
   }
   else
   {
      effectflags = effectflags | FX_GORE_GIBS;
      broadcast ("giblets enabled");
   }
};

void() toggle_corpse =
{
   if(no_access(self))
      return;

   if (effectflags & FX_GORE_CORPSE)
   {
      effectflags = effectflags - FX_GORE_CORPSE;
      broadcast ("corpses normal");
   }
   else
   {
      effectflags = effectflags | FX_GORE_CORPSE;
      broadcast ("corpses take damage");
   }
};


//=======================================================================================
//
//   Server Gameplay switches
//
//=======================================================================================

void() toggle_shrapnel =
{
   if (no_access(self))
      return;

   if (server_change_next_game & GAME_SHRAPNEL)
   {
      server_change_next_game = server_change_next_game - GAME_SHRAPNEL;
      broadcast ("shrapnel disabled next game");
   }
   else
   {
      server_change_next_game = server_change_next_game | GAME_SHRAPNEL;
      broadcast ("shrapnel enabled next game");
   }

   save_server_opts();

};

void() toggle_mikerules =
{
   if (no_access(self))
   {
      return;
   }

   if (server_change_next_game & GAME_MIKERULES)
   {
      server_change_next_game = server_change_next_game - GAME_MIKERULES;
      broadcast ("mikerules disabled next game");
   }
   else
   {
      server_change_next_game = server_change_next_game | GAME_MIKERULES;
      broadcast ("mikerules enabled next game");
   }
   save_server_opts();
};


void() toggle_randomgame =
{
   if (no_access(self))
   {
      return;
   }

   // only change on next level
   if (server_change_next_game & GAME_RANDOM)
   {
      server_change_next_game = server_change_next_game - GAME_RANDOM;
      randomgame = FALSE;
      broadcast ("randomize disabled next game");
   }
   else
   {
      server_change_next_game = server_change_next_game | GAME_RANDOM;
      randomgame = GAME_RANDOM;
      broadcast ("randomize enabled next game");
   }

   save_server_opts();
};

//-----------------------------------------------------------------------------

