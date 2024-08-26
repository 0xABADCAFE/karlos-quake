// cheats.qc
/*---public---*/
// $VER: cheats.qc 1.00 © Karlos '99 (19/07/1999)
// public function prototypes
void() BiosuitCheat;
void() CheatCommand;
void() InvisibilityCheat;
void() ProtectCheat;
void() QuadCheat;
void() RuneCheat;
/*---private---*/


/*===========================================================================

   INVENTORY CHEAT

===========================================================================*/
void() CheatCommand = {
    if (deathmatch || coop) {
        if (adminmessages) {
            sound(administrator, CHAN_AUTO, "misc/msg_warning.wav", 1, ATTN_NORM);
            sprint2(administrator, self.netname, " tried give_all\n");
        }
        return;
    }

    self.ammo_rockets = 100;
    self.ammo_nails   = 200;
    self.ammo_shells  = 100;
    self.items = self.items |
        IT_AXE |
        IT_SHOTGUN |
        IT_SUPER_SHOTGUN |
        IT_NAILGUN |
        IT_SUPER_NAILGUN |
        IT_GRENADE_LAUNCHER |
        IT_ROCKET_LAUNCHER |
        IT_KEY1 | IT_KEY2;

    self.ammo_cells = 200;
    self.items      = self.items | IT_LIGHTNING;
    self.weapon     = IT_ROCKET_LAUNCHER;
    self.impulse    = 0;
    self.inventory  = IT_SUIT | IT_QUAD | IT_INVISIBILITY | IT_INVULNERABILITY;

    W_SetCurrentAmmo ();
};

/*===========================================================================

   Quad Damage Cheat

===========================================================================*/
void() QuadCheat = {
    if (deathmatch || coop) {
        if (adminmessages) {
            sprint2(administrator, self.netname, " tried give_quad\n");
        }
        return;
    }
    self.super_time = 1;
    self.super_damage_finished = time + 30;
    self.items = self.items | IT_QUAD;
    sprint(self, "quad damage cheat...\n");
};

/*===========================================================================

   Invisibility Cheat

===========================================================================*/
void() InvisibilityCheat = {
    if (deathmatch || coop) {
        if (adminmessages) {
            sprint2(administrator, self.netname, " tried give_ring\n");
        }
        return;
    }
    self.invisible_time = 1;
    self.invisible_finished = time + 30;
    self.items = self.items | IT_INVISIBILITY;
    sprint(self, "invisibility cheat...\n");
};

/*===========================================================================

   Protection Cheat

===========================================================================*/
void() ProtectCheat = {
    if (deathmatch || coop) {
        if (adminmessages) {
            sprint2(administrator,  self.netname, " tried give_pent\n");
        }
        return;
    }

    self.invincible_time = 1;
    self.invincible_finished = time + 30;
    self.items = self.items | IT_INVULNERABILITY;
    sprint(self, "invulnerability cheat...\n");
};

/*==========================================================================

   Biosuit Cheat

===========================================================================*/
void() BiosuitCheat = {
    if (deathmatch || coop) {
        if (adminmessages) {
            sprint2(administrator, self.netname, " tried give_suit\n");
        }
        return;
    }
    self.rad_time = 1;
    self.radsuit_finished = time + 30;
    self.items = self.items | IT_SUIT;
    sprint(self, "biosuit cheat...\n");
};


/*============================================================================

   Rune Cheat

   Just for development

============================================================================*/
void() RuneCheat = {
    serverflags = serverflags * 2 + 1;
    sprint(self, "rune cheat...\n");
};

