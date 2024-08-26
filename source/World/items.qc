// items.qc
/*---public---*/
// $VER: items.qc 2.00 � Karlos '99 (24/08/1999)

float(entity e, float heal_amount, float ignore) T_Heal ;
float(float w) RankForWeapon ;
void() become_pickup ;
void() dropped_item_touch ;
void() ammo_touch ;
void() armor_touch ;
void() health_touch ;
void() BackpackTouch ;
void() Backpack_explode ;
void() DropBackpack ;
void() bound_other_ammo ;
void() key_setsounds ;
void() key_touch ;
void() item_armor1 ;
void() item_armor2 ;
void() item_armorInv ;
void() item_artifact_envirosuit ;
void() item_artifact_invisibility ;
void() item_artifact_invulnerability ;
void() item_artifact_super_damage ;
void() item_cells ;
void() item_health ;
void() item_key1 ;
void() item_key2 ;
void() item_megahealth_rot ;
void() item_rockets ;
void() item_shells ;
void() item_sigil ;
void() item_spikes ;
void() item_weapon ;
void() noclass ;
void(entity user, string use_sound, float use_item) activate_powerup;
void() powerup_touch ;
void() sigil_touch ;
void() PlaceItem ;

void() weapon_grenadelauncher ;
void() weapon_lightning ;
void() weapon_nailgun ;
void() weapon_rocketlauncher ;
void() weapon_supernailgun ;
void() weapon_supershotgun ;
void() weapon_touch ;
/*---private---*/
/*===================================================================================
                                           ITEMS
   Modified by Karlos
      Made backpacks containing rockets explosive. Only occurs if skill > 1:
      Damage potential proportional to number of rockets contained (set limit to 5)
      Damage limit inv. proportional to number of rockets (minimum 50)
      Limits set to avoid thermonuclear scale explosions in multiplayer games ;)

      Improved armour pickup code, type of armour collected is now reported
      Added DropArmour(float type) function for knights

===================================================================================*/

// needed prototypes...

/*QUAKED noclass (0 0 0) (-8 -8 -8) (8 8 8)
prints a warning message when spawned
*/
void() noclass = {
    dprint3("noclass spawned at", vtos(self.origin), "\n");
    remove(self);
};



/*===================================================================================
                                         PlaceItem

                              plants the object on the floor
===================================================================================*/
void() PlaceItem = {
    local float oldz;

    self.mdl      = self.model;     // so it can be restored on respawn
    self.flags    = FL_ITEM;      // make extra wide
    self.solid    = SOLID_TRIGGER;
    self.movetype = MOVETYPE_TOSS;
    self.velocity = VEC_ZERO;
    self.origin_z = self.origin_z + 8;
    oldz          = self.origin_z;
    if (!droptofloor()) {
        dprint5(
            "Bonus item '",
            self.classname,
            "' fell out of level at :",
            vtos(self.origin),
            "\n"
        );
        remove(self);
        return;
    }
};

/*===================================================================================
                                      StartItem

                 Sets the clipping size and plants the object on the floor
===================================================================================*/
void() StartItem = {
    self.nextthink = time + 0.2;  // items start after other solids
    self.think = PlaceItem;
};

/*=========================================================================================

                                      HEALTH BOX

=========================================================================================*/
//
// T_Heal: add health to an entity, limiting health to max_health
// "ignore" will ignore max_health limit
//
float (entity e, float heal_amount, float ignore) T_Heal = {
    if (e.health <= 0) {
        return 0;
    }

    if ((!ignore) && (e.health >= other.max_health)) {
        return 0;
    }

    heal_amount = ceil(heal_amount);
    e.health    = e.health + heal_amount;
    if ((!ignore) && (e.health >= other.max_health)) {
        e.health = other.max_health;
    }

    if (e.health > 250) {
        e.health = 250;
    }
    return 1;
};

/*QUAKED item_health (.3 .3 1) (0 0 0) (32 32 32) rotten megahealth
Health box. Normally gives 25 points.
Rotten box heals 5-10 points,
megahealth will add 100 health, then
rot you down to your maximum health limit,
one point per second.
*/

void() health_touch;
void() item_megahealth_rot;

void() item_health = {
    self.touch = health_touch;

    if (self.spawnflags & H_ROTTEN) {
        precache_model("maps/b_bh10.bsp");
        setmodel(self, "maps/b_bh10.bsp");
        self.noise     = "items/r_item1.wav";
        self.healamount = 15;
        self.healtype   = 0;
    }
    else if (self.spawnflags & H_MEGA) {
        precache_model("maps/b_bh100.bsp");
        setmodel(self, "maps/b_bh100.bsp");
        self.noise = "items/r_item2.wav";
        self.healamount = 100;
        self.healtype   = 2;
    }
    else {
        precache_model("maps/b_bh25.bsp");
        setmodel(self, "maps/b_bh25.bsp");
        self.noise      = "items/health1.wav";
        self.healamount = 25;
        self.healtype   = 1;
    }
    precache_sound(self.noise);
    setsize(self, VEC_ZERO, '32 32 56');
    StartItem();
};


void() health_touch = {
    local float amount;
    local string temp_string;

    if (other.classname != "player") {
        return;
    }
    if (self.healtype == 2) {
        // Megahealth?  Ignore max_health...
        if (mikerules) {
            // repair current weapon, by an amount dependent on class
            if (other.weapon == IT_SHOTGUN) {
                other.weapon_01_damage = 0;
            }
            else if (other.weapon == IT_SUPER_SHOTGUN) {
                other.weapon_02_damage = 0;
            }
            else if (other.weapon == IT_NAILGUN) {
                other.weapon_03_damage = 0;
            }
            else if (other.weapon == IT_SUPER_NAILGUN) {
                other.weapon_04_damage = other.weapon_04_damage * 0.25;
            }
            else if (other.weapon == IT_GRENADE_LAUNCHER) {
                other.weapon_05_damage = other.weapon_05_damage * 0.25;
            }
            else if (other.weapon == IT_ROCKET_LAUNCHER) {
                other.weapon_06_damage = other.weapon_06_damage * 0.5;
            }
            else if (other.weapon == IT_LIGHTNING) {
                other.weapon_07_damage = other.weapon_07_damage * 0.5;
            }
        }
        if (other.health >= 250) {
            return;
        }
        if (!T_Heal(other, self.healamount, 1)) {
            return;
        }
    }
    else {
        if (!T_Heal(other, self.healamount, 0)) {
            return;
        }
    }
    temp_string = ftos(self.healamount);
    sprint3(other, "You receive ", temp_string, " health\n");

    // health touch sound
    sound(other, CHAN_ITEM, self.noise, 1, ATTN_NORM);

    if (effectflags & FX_CON_FLASH) {
        stuffcmd(other, "bf\n");
    }
    self.model = string_null;
    self.solid = SOLID_NOT;

    // Megahealth = rot down the player's super health
    if (self.healtype == 2) {
        other.items    = other.items | IT_SUPERHEALTH;
        self.nextthink = time + 5;
        self.think     = item_megahealth_rot;
        self.owner     = other;
    }
    else {
        if (deathmatch != 2) {
            // deathmatch 2 is the silly old rules
            if (deathmatch) {
                self.nextthink = time + 20;
            }
            self.think = SUB_regen;
        }
    }

    activator = other;
    SUB_UseTargets();          // fire all targets / killtargets
};

void() item_megahealth_rot = {
    other = self.owner;

    if (other.health > other.max_health) {
        other.health   = other.health - 1;
        self.nextthink = time + 1;
        return;
    }

    // it is possible for a player to die and respawn between rots, so don't
    // just blindly subtract the flag off
    other.items = other.items - (other.items & IT_SUPERHEALTH);

    if (deathmatch == 1) {
        // deathmatch 2 is silly old rules
        self.nextthink = time + 20;
        self.think     = SUB_regen;
    }
};

/*=========================================================================================

                                         ARMOR

=========================================================================================*/

void() armor_touch = {
    local float type, value, bit;

    if (other.health <= 0) {
        return;
    }
    if (other.classname != "player") {
        return;
    }
    // todo - move these to properties of the collectables on spawn() ?
    if (self.netname == "light armour") {
        type  = 0.3;
        value = 100;
        bit   = IT_ARMOR1;
    }
    else if (self.netname == "medium armour") {
        type  = 0.6;
        value = 150;
        bit   = IT_ARMOR2;
    }
    else if (self.netname == "heavy armour") {
        type  = 0.8;
        value = 200;
        bit   = IT_ARMOR3;
    }
    if (other.armortype*other.armorvalue >= type * value) {
        return;
    }

    other.armortype  = type;
    other.armorvalue = value;
    other.items      = other.items - (other.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + bit;
    self.solid       = SOLID_NOT;
    self.model       = string_null;
    if (deathmatch == 1) {
        // respawn
        self.nextthink = time + 20;
        self.think     = SUB_regen;
    }

    sprint3(other, "You got the ", self.netname, "\n");

    // armor touch sound
    sound(other, CHAN_ITEM, "items/armor1.wav", 1, ATTN_NORM);
    if (effectflags & FX_CON_FLASH) {
        stuffcmd (other, "bf\n");
    }
    activator = other;
    SUB_UseTargets();          // fire all targets / killtargets
};


/*QUAKED item_armor1 (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() item_armor1 = {
    self.touch   = armor_touch;
    precache_model("progs/armor.mdl");
    setmodel(self, "progs/armor.mdl");
    self.skin    = 0;
    setsize(self, '-16 -16 0', '16 16 56');
    self.netname = "light armour";
    StartItem();
};

/*QUAKED item_armor2 (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() item_armor2 = {
    self.touch   = armor_touch;
    precache_model("progs/armor.mdl");
    setmodel(self, "progs/armor.mdl");
    self.skin    = 1;
    setsize(self, '-16 -16 0', '16 16 56');
    self.netname = "medium armour";
    StartItem();
};

/*QUAKED item_armorInv (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() item_armorInv = {
    self.touch   = armor_touch;
    precache_model("progs/armor.mdl");
    setmodel(self, "progs/armor.mdl");
    self.skin    = 2;
    setsize(self, '-16 -16 0', '16 16 56');
    self.netname = "heavy armour";
    StartItem();
};

/*=========================================================================================

                                            WEAPONS

=========================================================================================*/

void() bound_other_ammo = {
    if (other.ammo_shells > 100) {
        other.ammo_shells = 100;
    }
    if (other.ammo_nails > 200) {
        other.ammo_nails = 200;
    }
    if (other.ammo_rockets > 100) {
        other.ammo_rockets = 100;
    }
    if (other.ammo_cells > 200) {
        other.ammo_cells = 200;
    }
};


float(float w) RankForWeapon = {
    if (w == IT_LIGHTNING) {
        return 1;
    }

    if (w == IT_ROCKET_LAUNCHER) {
        return 2;
    }

    if (w == IT_SUPER_NAILGUN) {
        return 3;
    }

    if (w == IT_GRENADE_LAUNCHER) {
        return 4;
    }

    if (w == IT_SUPER_SHOTGUN) {
        return 5;
    }

    if (w == IT_NAILGUN) {
        return 6;
    }
    return 7;
};

//=========================================================================================
//                                      Deathmatch_Weapon
//
//                    Deathmatch weapon change rules for picking up a weapon
//
//                 .float      ammo_shells, ammo_nails, ammo_rockets, ammo_cells;
//=========================================================================================

void(float old_weapon, float new_weapon) Deathmatch_Weapon = {
    local float or, nr;

    // change self.weapon if desired
    or = RankForWeapon(self.weapon);
    nr = RankForWeapon(new_weapon);
    if (nr < or) {
        self.weapon = new_weapon;
    }
};

//===========================================================================
//
//   weapon_touch
//
//===========================================================================

void() weapon_touch = {
    local float hadammo, best_weapon, new_weapon, old_weapon;
    local entity stemp;
    local float leave;

    if (!(other.flags & FL_CLIENT)) {
        return;
    }

    // if the player was using his best weapon, change up to the new one if better
    stemp       = self;
    self        = other;
    best_weapon = W_BestWeapon();
    self        = stemp;

    if (deathmatch == 2 || coop || (mikerules && (self.items & other.items))) {
        leave = 1;
    }
    else {
        leave = 0;
    }

    if (self.classname == "weapon_nailgun") {
        if (leave && (other.items & IT_NAILGUN) ) {
            return;
        }
        hadammo    = other.ammo_nails;
        new_weapon = IT_NAILGUN;
        other.ammo_nails = other.ammo_nails + 30;
    }
    else if (self.classname == "weapon_supernailgun") {
        if (leave && (other.items & IT_SUPER_NAILGUN) ) {
            return;
        }
        hadammo    = other.ammo_rockets;
        new_weapon = IT_SUPER_NAILGUN;
        other.ammo_nails = other.ammo_nails + 30;
    }
    else if (self.classname == "weapon_supershotgun") {
        if (leave && (other.items & IT_SUPER_SHOTGUN) ) {
            return;
        }
        hadammo    = other.ammo_rockets;
        new_weapon = IT_SUPER_SHOTGUN;
        other.ammo_shells = other.ammo_shells + 5;
    }
    else if (self.classname == "weapon_rocketlauncher") {
        if (leave && (other.items & IT_ROCKET_LAUNCHER) ) {
            return;
        }
        hadammo    = other.ammo_rockets;
        new_weapon = IT_ROCKET_LAUNCHER;
        other.ammo_rockets = other.ammo_rockets + 5;
    }
    else if (self.classname == "weapon_grenadelauncher") {
        if (leave && (other.items & IT_GRENADE_LAUNCHER) ) {
            return;
        }
        hadammo    = other.ammo_rockets;
        new_weapon = IT_GRENADE_LAUNCHER;
        other.ammo_rockets = other.ammo_rockets + 5;
    }
    else if (self.classname == "weapon_lightning") {
        if (leave && (other.items & IT_LIGHTNING) ) {
            return;
        }
        hadammo    = other.ammo_rockets;
        new_weapon = IT_LIGHTNING;
        other.ammo_cells = other.ammo_cells + 15;
    }
    else {
        objerror("weapon_touch: unknown classname");
    }

    sprint3(other, "You got the ", self.netname, "\n");

    // weapon touch sound
    sound (other, CHAN_ITEM, "weapons/pkup.wav", 1, ATTN_NORM);
    if (effectflags & FX_CON_FLASH) {
        stuffcmd(other, "bf\n");
    }

    bound_other_ammo();

    // change to the weapon
    old_weapon  = other.items;
    other.items = other.items | new_weapon;

    stemp = self;
    self  = other;

    if (!deathmatch) {
        self.weapon = new_weapon;
    }
    else {
        Deathmatch_Weapon (old_weapon, new_weapon);
    }

    W_SetCurrentAmmo();
    self = stemp;

    if (leave) {
        return;
    }

    // remove it in single player, or setup for respawning in deathmatch
    self.model = string_null;
    self.solid = SOLID_NOT;
    if (deathmatch == 1) {
        self.nextthink = time + 30;
    }
    self.think = SUB_regen;
    activator  = other;
    SUB_UseTargets();          // fire all targets / killtargets
};


/*QUAKED weapon_supershotgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_supershotgun = {
    precache_model("progs/g_shot.mdl");
    setmodel(self, "progs/g_shot.mdl");
    self.items   = IT_SUPER_SHOTGUN;
    self.weapon  = IT_SUPER_SHOTGUN;
    self.netname = "Super Shotgun";
    self.touch   = weapon_touch;
    setsize(self, '-16 -16 0', '16 16 56');
    StartItem();
};

/*QUAKED weapon_nailgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_nailgun = {
    precache_model("progs/g_nail.mdl");
    setmodel(self, "progs/g_nail.mdl");
    self.items   = IT_NAILGUN;
    self.weapon  = IT_NAILGUN;
    self.netname = "nailgun";
    self.touch   = weapon_touch;
    setsize(self, '-16 -16 0', '16 16 56');
    StartItem();
};

/*QUAKED weapon_supernailgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_supernailgun = {
    precache_model("progs/g_nail2.mdl");
    setmodel(self, "progs/g_nail2.mdl");
    self.items   = IT_SUPER_NAILGUN;
    self.weapon  = IT_SUPER_NAILGUN;
    self.netname = "Super Nailgun";
    self.touch   = weapon_touch;
    setsize(self, '-16 -16 0', '16 16 56');
    StartItem();
};

/*QUAKED weapon_grenadelauncher (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_grenadelauncher = {
    precache_model("progs/g_rock.mdl");
    setmodel(self, "progs/g_rock.mdl");
    self.items   = IT_GRENADE_LAUNCHER;
    self.weapon  = 3;
    self.netname = "Grenade Launcher";
    self.touch   = weapon_touch;
    setsize(self, '-16 -16 0', '16 16 56');
    StartItem();
};

/*QUAKED weapon_rocketlauncher (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_rocketlauncher = {
    precache_model("progs/g_rock2.mdl");
    setmodel(self, "progs/g_rock2.mdl");
    self.items   = IT_ROCKET_LAUNCHER;
    self.weapon  = 3;
    self.netname = "Rocket Launcher";
    self.touch   = weapon_touch;
    setsize(self, '-16 -16 0', '16 16 56');
    StartItem();
};


/*QUAKED weapon_lightning (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_lightning = {
    precache_model("progs/g_light.mdl");
    setmodel(self, "progs/g_light.mdl");
    self.items   = IT_LIGHTNING;
    self.weapon  = 3;
    self.netname = "Thunderbolt";
    self.touch   = weapon_touch;
    setsize(self, '-16 -16 0', '16 16 56');
    StartItem();
};


//===============================================================================
//
//    AMMO
//
//===============================================================================

void() ammo_touch = {
    local entity   stemp;
    local float    best;

    if (other.classname != "player") {
        return;
    }

    if (other.health <= 0) {
        return;
    }

    // if the player was using his best weapon, change up to the new one if better
    stemp = self;
    self  = other;
    best  = W_BestWeapon();
    self  = stemp;

    // modifications - ammo can only be collected if the total amount after collection is not greater
    // than the maximum amount carryable (to prevent waste)...is bound_other_ammo() still needed ?

    // shotgun
    if (self.weapon == 1) {
        if (other.ammo_shells + self.aflag > 100) {
            return;
        }

        other.ammo_shells = other.ammo_shells + self.aflag;
    }

    // spikes
    else if (self.weapon == 2) {
        if (other.ammo_nails + self.aflag > 200) {
            return;
        }

        other.ammo_nails = other.ammo_nails + self.aflag;
    }

    // rockets
    else if (self.weapon == 3) {
        if (other.ammo_rockets +self.aflag > 100) {
            return;
        }

        other.ammo_rockets = other.ammo_rockets + self.aflag;
    }

    // cells
    else if (self.weapon == 4) {
        if (other.ammo_cells + self.aflag > 200) {
            return;
        }

        other.ammo_cells = other.ammo_cells + self.aflag;
    }

    bound_other_ammo();

    sprint3(other, "You got the ", self.netname, "\n");
    // ammo touch sound
    sound(other, CHAN_ITEM, "weapons/lock4.wav", 1, ATTN_NORM);
    if (effectflags & FX_CON_FLASH) {
        stuffcmd (other, "bf\n");
    }

    // change to a better weapon if appropriate
    if ( other.weapon == best ) {
        stemp       = self;
        self        = other;
        self.weapon = W_BestWeapon();
        W_SetCurrentAmmo();
        self = stemp;
    }

    // if changed current ammo, update it
    stemp = self;
    self  = other;
    W_SetCurrentAmmo();
    self  = stemp;

    // remove it in single player, or setup for respawning in deathmatch
    self.model = string_null;
    self.solid = SOLID_NOT;
    if (deathmatch == 1) {
        self.nextthink = time + 30;
    }

    self.think = SUB_regen;
    activator  = other;
    SUB_UseTargets();          // fire all targets / killtargets
};

/*QUAKED item_shells (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_shells = {
    self.touch = ammo_touch;

    if (self.spawnflags & WEAPON_BIG2) {
        precache_model("maps/b_shell1.bsp");
        setmodel(self, "maps/b_shell1.bsp");
        self.aflag = 40;
    }
    else {
        precache_model("maps/b_shell0.bsp");
        setmodel(self, "maps/b_shell0.bsp");
        self.aflag = 20;
    }
    self.weapon  = 1;
    self.netname = "shells";
    setsize(self, VEC_ZERO, '32 32 56');
    StartItem();
};

/*QUAKED item_spikes (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_spikes = {
    self.touch = ammo_touch;

    if (self.spawnflags & WEAPON_BIG2) {
        precache_model("maps/b_nail1.bsp");
        setmodel(self, "maps/b_nail1.bsp");
        self.aflag = 50;
    }
    else {
        precache_model ("maps/b_nail0.bsp");
        setmodel(self, "maps/b_nail0.bsp");
        self.aflag = 25;
    }
    self.weapon  = 2;
    self.netname = "nails";
    setsize(self, VEC_ZERO, '32 32 56');
    StartItem();
};

/*QUAKED item_rockets (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_rockets = {
    self.touch = ammo_touch;

    if (self.spawnflags & WEAPON_BIG2) {
        precache_model("maps/b_rock1.bsp");
        setmodel(self, "maps/b_rock1.bsp");
        self.aflag = 10;
    }
    else {
        precache_model("maps/b_rock0.bsp");
        setmodel(self, "maps/b_rock0.bsp");
        self.aflag = 5;
    }
    self.weapon  = 3;
    self.netname = "rockets";
    setsize(self, VEC_ZERO, '32 32 56');
    StartItem();
};


/*QUAKED item_cells (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_cells = {
    self.touch = ammo_touch;

    if (self.spawnflags & WEAPON_BIG2) {
        precache_model("maps/b_batt1.bsp");
        setmodel(self, "maps/b_batt1.bsp");
        self.aflag = 12;
    }
    else {
        precache_model("maps/b_batt0.bsp");
        setmodel(self, "maps/b_batt0.bsp");
        self.aflag = 6;
    }
    self.weapon  = 4;
    self.netname = "cells";
    setsize(self, VEC_ZERO, '32 32 56');
    StartItem();
};


/*QUAKED item_weapon (0 .5 .8) (0 0 0) (32 32 32) shotgun rocket spikes big
DO NOT USE THIS!!!! IT WILL BE REMOVED!
*/

void() item_weapon = {
    self.touch = ammo_touch;

    if (self.spawnflags & WEAPON_SHOTGUN) {
        if (self.spawnflags & WEAPON_BIG) {
            precache_model("maps/b_shell1.bsp");
            setmodel(self, "maps/b_shell1.bsp");
            self.aflag = 40;
        }
        else {
            precache_model("maps/b_shell0.bsp");
            setmodel(self, "maps/b_shell0.bsp");
            self.aflag = 20;
        }
        self.weapon  = 1;
        self.netname = "shells";
    }

    if (self.spawnflags & WEAPON_SPIKES) {
        if (self.spawnflags & WEAPON_BIG) {
            precache_model("maps/b_nail1.bsp");
            setmodel(self, "maps/b_nail1.bsp");
            self.aflag = 40;
        }
        else {
            precache_model("maps/b_nail0.bsp");
            setmodel(self, "maps/b_nail0.bsp");
            self.aflag = 20;
        }
        self.weapon  = 2;
        self.netname = "spikes";
    }

    if (self.spawnflags & WEAPON_ROCKET) {
        if (self.spawnflags & WEAPON_BIG) {
            precache_model("maps/b_rock1.bsp");
            setmodel(self, "maps/b_rock1.bsp");
            self.aflag = 10;
        }
        else {
            precache_model("maps/b_rock0.bsp");
            setmodel(self, "maps/b_rock0.bsp");
            self.aflag = 5;
        }
        self.weapon  = 3;
        self.netname = "rockets";
    }

    setsize(self, VEC_ZERO, '32 32 56');
    StartItem();
};


//===============================================================================
//
//   KEYS
//
//===============================================================================

void() key_touch = {
    local entity   stemp;
    local float    best;

    if (other.classname != "player") {
        return;
    }

    if (other.health <= 0) {
        return;
    }

    if (other.items & self.items) {
        return;
    }

    sprint3(other, "You got the ", self.netname, "\n");

    sound(other, CHAN_ITEM, self.noise, 1, ATTN_NORM);

    if (effectflags & FX_CON_FLASH) {
        stuffcmd (other, "bf\n");
    }

    other.items = other.items | self.items;

    if (!coop) {
        self.solid = SOLID_NOT;
        self.model = string_null;
    }

    activator = other;
    SUB_UseTargets();          // fire all targets / killtargets
};


void() key_setsounds = {
   if (world.worldtype == 0) {
      precache_sound ("misc/medkey.wav");
      self.noise = "misc/medkey.wav";
   }
   else if (world.worldtype == 1) {
      precache_sound ("misc/runekey.wav");
      self.noise = "misc/runekey.wav";
   }
   else if (world.worldtype == 2) {
      precache_sound2 ("misc/basekey.wav");
      self.noise = "misc/basekey.wav";
   }
};

/*QUAKED item_key1 (0 .5 .8) (-16 -16 -24) (16 16 32)
SILVER key
In order for keys to work
you MUST set your maps
worldtype to one of the
following:
0: medieval
1: metal
2: base
*/

void() item_key1 = {
    if (world.worldtype == 0) {
        precache_model("progs/w_s_key.mdl");
        setmodel(self, "progs/w_s_key.mdl");
        self.netname = "silver key";
    }
    else if (world.worldtype == 1) {
        precache_model("progs/m_s_key.mdl");
        setmodel(self, "progs/m_s_key.mdl");
        self.netname = "silver runekey";
    }
    else if (world.worldtype == 2) {
        precache_model2("progs/b_s_key.mdl");
        setmodel(self, "progs/b_s_key.mdl");
        self.netname = "silver keycard";
    }
    key_setsounds();
    self.touch = key_touch;
    self.items = IT_KEY1;
    setsize(self, '-16 -16 -24', '16 16 32');
    StartItem();
};

/*QUAKED item_key2 (0 .5 .8) (-16 -16 -24) (16 16 32)
GOLD key
In order for keys to work
you MUST set your maps
worldtype to one of the
following:
0: medieval
1: metal
2: base
*/

void() item_key2 = {
    if (world.worldtype == 0) {
        precache_model("progs/w_g_key.mdl");
        setmodel(self, "progs/w_g_key.mdl");
        self.netname = "gold key";
    }
    else if (world.worldtype == 1) {
        precache_model("progs/m_g_key.mdl");
        setmodel(self, "progs/m_g_key.mdl");
        self.netname = "gold runekey";
    }
    else if (world.worldtype == 2) {
        precache_model2("progs/b_g_key.mdl");
        setmodel(self, "progs/b_g_key.mdl");
        self.netname = "gold keycard";
    }
    key_setsounds();
    self.touch = key_touch;
    self.items = IT_KEY2;
    setsize(self, '-16 -16 -24', '16 16 32');
    StartItem();
};



/*
===============================================================================

END OF LEVEL RUNES

===============================================================================
*/

void() sigil_touch = {
    local entity stemp;
    local float  best;

    if (other.classname != "player") {
        return;
    }

    if (other.health <= 0) {
        return;
    }

    centerprint(other, "You got the rune!");

    sound(other, CHAN_ITEM, self.noise, 1, ATTN_NORM);
    if (effectflags & FX_CON_FLASH) {
        stuffcmd(other, "bf\n");
    }

    self.solid     = SOLID_NOT;
    self.model     = string_null;
    serverflags    = serverflags | (self.spawnflags & 15);
    self.classname = "";    // so rune doors won't find it
    activator      = other;
    SUB_UseTargets();          // fire all targets / killtargets
};


/*QUAKED item_sigil (0 .5 .8) (-16 -16 -24) (16 16 32) E1 E2 E3 E4
End of level sigil, pick up to end episode and return to jrstart.
*/

void() item_sigil = {
    if (!self.spawnflags) {
        objerror("no spawnflags");
    }

    precache_sound("misc/runekey.wav");
    self.noise = "misc/runekey.wav";

    if (self.spawnflags & 1) {
        precache_model("progs/end1.mdl");
        setmodel(self, "progs/end1.mdl");
    }
    if (self.spawnflags & 2) {
        precache_model2("progs/end2.mdl");
        setmodel(self, "progs/end2.mdl");
    }
    if (self.spawnflags & 4) {
        precache_model2("progs/end3.mdl");
        setmodel(self, "progs/end3.mdl");
    }
    if (self.spawnflags & 8) {
        precache_model2("progs/end4.mdl");
        setmodel(self, "progs/end4.mdl");
    }

    self.touch = sigil_touch;
    setsize(self, '-16 -16 -24', '16 16 32');
    StartItem();
};

/*
===============================================================================

POWERUPS

===============================================================================
*/

void() powerup_touch = {
    local entity   stemp;
    local float    best;

    if (other.classname != "player") {
        return;
    }

    if (other.health <= 0) {
        return;
    }

    if (other.extraflags & CL_INVENTORYBIT && (other.inventory & self.items) && (other.items & self.items)) {
        // already have it stashed and even using another !
        centerprint(other, "You cannot currently collect this item\n");
        return;
    }

    sprint3(other, "You got the ", self.netname, "\n");

    if (deathmatch) {
        self.mdl = self.model;

        if (
            (self.classname == "item_artifact_invulnerability") ||
            (self.classname == "item_artifact_invisibility")
        ) {
            self.nextthink = time + 300;
        }
        else {
            self.nextthink = time + 60;
        }

        self.think = SUB_regen;
    }
    if (effectflags & FX_CON_FLASH) {
        stuffcmd(other, "bf\n");
    }
    self.solid = SOLID_NOT;
    self.model = string_null;

    if (other.extraflags & CL_INVENTORYBIT && (!(other.inventory & self.items))) {
        // if using inventory, give priority to stashing
        // but still do any triggers...
        sound(other, CHAN_ITEM, "misc/message2.wav", 1, ATTN_NORM);
        centerprint(other, "You must activate this item\nin order to use it\n");

        other.inventory = other.inventory | self.items;
        activator       = other;
        SUB_UseTargets();
        return;
    }

    // ok, we have it, but can use another immediately...

    activate_powerup(other, self.noise, self.items);
    activator = other;
    SUB_UseTargets();          // fire all targets / killtargets
};

void(entity user, string use_sound, float use_item) activate_powerup = {
    // activates the powerup

    sound (user, CHAN_AUTO, use_sound, 1, ATTN_NORM);

    // add the powerup to the user's current item list

    // do the apropriate action
    if (use_item == IT_SUIT) {
        user.suitbreathtime   = time + 2 * (random() + 1);
        user.rad_time         = 1;
        user.radsuit_finished = time + 30;
    }
    else if (use_item == IT_INVULNERABILITY) {
        user.invincible_time     = 1;
        user.invincible_finished = time + 30;
    }
    else if (use_item == IT_INVISIBILITY) {
        user.invisible_time     = 1;
        user.invisible_finished = time + 30;
    }
    else if (use_item == IT_QUAD) {
        user.super_time            = 1;
        user.super_damage_finished = time + 30;
    }

    user.items = user.items | use_item;
};


/*QUAKED item_artifact_invulnerability (0 .5 .8) (-16 -16 -24) (16 16 32)
Player is invulnerable for 30 seconds
*/
void() item_artifact_invulnerability = {
    self.touch = powerup_touch;

    precache_model("progs/invulner.mdl");
    precache_sound("items/protect.wav");
    precache_sound("items/protect2.wav");
    precache_sound("items/protect3.wav");

    self.noise = "items/protect.wav";
    setmodel(self, "progs/invulner.mdl");
    self.netname = "Pentagram of Protection";
    self.items   = IT_INVULNERABILITY;
    setsize(self, '-16 -16 -24', '16 16 32');
    StartItem();
};

/*QUAKED item_artifact_envirosuit (0 .5 .8) (-16 -16 -24) (16 16 32)
Player takes no damage from water or slime for 30 seconds
*/
void() item_artifact_envirosuit = {
    self.touch = powerup_touch;

    precache_model("progs/suit.mdl");
    precache_sound("items/suit.wav");
    precache_sound("items/suit2.wav");
    precache_sound("shared/inhale.wav");
    precache_sound("shared/exhale.wav");
    precache_sound("shared/w_exhale.wav");

    self.noise = "items/suit.wav";
    setmodel(self, "progs/suit.mdl");
    self.netname = "Biosuit";
    self.items   = IT_SUIT;
    setsize(self, '-16 -16 -24', '16 16 32');
    StartItem();
};


/*QUAKED item_artifact_invisibility (0 .5 .8) (-16 -16 -24) (16 16 32)
Player is invisible for 30 seconds
*/
void() item_artifact_invisibility = {
    self.touch = powerup_touch;

    precache_model("progs/invisibl.mdl");
    precache_sound("items/inv1.wav");
    precache_sound("items/inv2.wav");
    precache_sound("items/inv3.wav");

    self.noise = "items/inv1.wav";
    setmodel(self, "progs/invisibl.mdl");
    self.netname = "Ring of Shadows";
    self.items   = IT_INVISIBILITY;
    setsize(self, '-16 -16 -24', '16 16 32');
    StartItem();
};


/*QUAKED item_artifact_super_damage (0 .5 .8) (-16 -16 -24) (16 16 32)
The next attack from the player will do 4x damage
*/
void() item_artifact_super_damage = {
    self.touch = powerup_touch;

    precache_model("progs/quaddama.mdl");
    precache_sound("items/damage.wav");
    precache_sound("items/damage2.wav");
    precache_sound("items/damage3.wav");

    self.noise = "items/damage.wav";
    setmodel (self, "progs/quaddama.mdl");
    self.netname = "Quad Damage";
    self.items   = IT_QUAD;
    setsize(self, '-16 -16 -24', '16 16 32');
    StartItem();
};

void(float armourtype) DropArmour = {
    local entity item;

    item            = spawn();
    item.origin     = self.origin - '0 0 24';
    item.velocity_z = 300;
    item.velocity_x = -100 + (random() * 200);
    item.velocity_y = -100 + (random() * 200);
    item.flags      = FL_ITEM;
    item.solid      = SOLID_TRIGGER;
    item.movetype   = MOVETYPE_TOSS;

    setmodel(item, "progs/armor.mdl");
    setsize(item, '-16 -16 0', '16 16 56');

    item.skin = armourtype;

    if (item.skin == 0) {
        item.netname = "light armour";
    }
    else if (item.skin == 1) {
        item.netname = "medium armour";
    }
    else {
        item.netname = "heavy armour";
    }

    item.touch     = armor_touch;
    item.nextthink = time + 120;  // remove after 2 minutes
    item.think     = SUB_Remove;
};


/*=========================================================================================

                                     PLAYER BACKPACKS

=========================================================================================*/

void() BackpackTouch = {
    local string temp_string;
    local entity stemp;
    local float  acount;

    if (other.classname != "player") {
        return;
    }

    if (other.health <= 0) {
        return;
    }

    acount = 0;
    sprint(other, "You get ");

    // put items into other inventory
    if ((self.items & IT_SUIT) && (!(other.inventory & IT_SUIT))) {
        temp_string = name_of_thing(IT_SUIT);
        sprint3(other, "the ", temp_string, ", ");
    }

    if ((self.items & IT_INVISIBILITY) && (!(other.inventory & IT_INVISIBILITY))) {
        temp_string = name_of_thing(IT_INVISIBILITY);
        sprint3(other, "the ", temp_string, ", ");
    }

    if ((self.items & IT_QUAD) && (!(other.inventory & IT_QUAD))) {
        temp_string = name_of_thing(IT_QUAD);
        sprint3(other, "the ", temp_string, ", ");
    }

    if ((self.items & IT_INVULNERABILITY) && (!(other.inventory & IT_INVULNERABILITY))) {
        temp_string = name_of_thing(IT_INVULNERABILITY);
        sprint3 (other, "the ", temp_string, ", ");
    }

    other.inventory = other.inventory | self.items;

    // add up ammo
    other.ammo_shells  = other.ammo_shells + self.ammo_shells;
    other.ammo_nails   = other.ammo_nails + self.ammo_nails;
    other.ammo_rockets = other.ammo_rockets + self.ammo_rockets;
    other.ammo_cells   = other.ammo_cells + self.ammo_cells;

    bound_other_ammo();

    if (self.ammo_shells) {
        if (acount) {
            sprint(other, ", ");
        }

        acount      = 1;
        temp_string = ftos(self.ammo_shells);
        sprint2(other, temp_string, " shells");
    }

    if (self.ammo_nails) {
        if (acount) {
            sprint(other, ", ");
        }

        acount      = 1;
        temp_string = ftos(self.ammo_nails);
        sprint2(other, temp_string, " nails");
    }

    if (self.ammo_rockets) {
        if (acount) {
            sprint(other, ", ");
        }
        acount      = 1;
        temp_string = ftos(self.ammo_rockets);
        sprint2(other, temp_string, " rockets");
    }

    if (self.ammo_cells) {
        if (acount) {
            sprint(other, ", ");
        }
        acount      = 1;
        temp_string = ftos(self.ammo_cells);
        sprint2(other, temp_string, " cells");
    }

    sprint(other, "\n");
    // backpack touch sound
    sound(other, CHAN_ITEM, "weapons/lock4.wav", 1, ATTN_NORM);
    if (effectflags & FX_CON_FLASH) {
        stuffcmd (other, "bf\n");
    }

    // remove the backpack, change self to the player
    remove(self);
    self = other;
    W_SetCurrentAmmo ();
};

void() Backpack_explode = {
    local float damagepot;

    self.takedamage = DAMAGE_NO;
    self.classname  = "explo_backpack";
    // did say self.owner
    damagepot = self.ammo_rockets * 40;
    if (damagepot > 160) {
        damagepot = 160;
    }

    T_RadiusDamage(self, self, damagepot, world);
    self.origin_z = self.origin_z + 32;
    BecomeExplosion();
};


/*===============
DropBackpack
===============*/
void() DropBackpack = {
   local entity item;

    if (!(self.ammo_shells + self.ammo_nails + self.ammo_rockets + self.ammo_cells))
        return;  // nothing in it

    item = spawn();
    item.origin = self.origin - '0 0 24';

    // EXPLOSIVE BACKPACK OWNER
    // Shouldn't set item.owner as self, since self is dead
    // and corpse may expire before backpack explodes. Use world instead
    // Set deadflag to be extra sure...

    item.owner    = world;
    item.deadflag = DEAD_DEAD;

    // player will drop weapon seperately, so we put inventory items in backpack
    if (self.inventory) {
        item.items = self.inventory;
    }

    item.netname      = "backpack";
    item.ammo_shells  = self.ammo_shells;
    item.ammo_nails   = self.ammo_nails;
    item.ammo_rockets = self.ammo_rockets;
    item.ammo_cells   = self.ammo_cells;
    item.velocity_z   = 300;
    item.velocity_x   = -100 + (random() * 200);
    item.velocity_y   = -100 + (random() * 200);
    item.flags        = FL_ITEM;
    item.solid        = SOLID_TRIGGER;
    item.movetype     = MOVETYPE_TOSS;
    setmodel(item, "progs/backpack.mdl");
    setsize(item, '-16 -16 0', '16 16 56');

    if ( (skill_fact > 1) && (item.ammo_rockets > 0) ) {
        // Make rocket containing backpacks explosive when in hard+ skill.
        // Damage potential is proportional to rockets contained
        // amd damage limit inversely proportional...

        item.health     = 50 + (100 / item.ammo_rockets);
        item.takedamage = DAMAGE_YES;
        item.th_die     = Backpack_explode;
    }

    item.touch     = BackpackTouch;
    item.nextthink = time + 120;  // remove after 2 minutes
    item.think     = SUB_Remove;
};

void () dropped_item_touch = {
    local entity dropped;

    // touch entity must be a living player...
    if (other.classname != "player" || other.health <= 0) {
        return;
    }

    // don't collect if mikerules and already have the item
    if (mikerules && (other.items & self.items)) {
        return;
    }

    dropped = self;

    // collect the thing
    other.items = other.items | dropped.items;

    if (dropped.items & IT_IS_A_WEAPON) {
        // collect weapon, and inherit its damage also
        if (dropped.items & IT_SHOTGUN) {
            other.weapon_01_damage = dropped.health;
        }
        else if (dropped.items & IT_SUPER_SHOTGUN) {
            other.weapon_02_damage = dropped.health;
        }
        else if (dropped.items & IT_NAILGUN) {
            other.weapon_03_damage = dropped.health;
        }
        else if (dropped.items & IT_SUPER_NAILGUN) {
            other.weapon_04_damage = dropped.health;
        }
        else if (dropped.items & IT_GRENADE_LAUNCHER) {
            other.weapon_05_damage = dropped.health;
        }
        else if (dropped.items & IT_ROCKET_LAUNCHER) {
            other.weapon_06_damage = dropped.health;
        }
        else if (dropped.items & IT_LIGHTNING) {
            other.weapon_07_damage = dropped.health;
        }
        sound(other, CHAN_ITEM, "weapons/pkup.wav", 1, ATTN_NORM);
    }
    remove(dropped);
    self = other;
    // pick best weapon
    self.weapon = dropped.items;
    W_SetCurrentAmmo();
};


void () become_pickup = {
    // "self" is dropped item
    self.touch     = dropped_item_touch;
    self.nextthink = time + 300;  // remove after 5 minutes
    self.think     = SUB_Remove;
};
