// inventory.qc

/*---public---*/
// $VER: inventory.qc 1.53 Karlos (22/09/1999)

// public function prototypes
// highlevel
void()                   inv_toggle;
void()                   inv_list_items;
void(float use_item)     inv_equip_item;
void(float item_dropped) inv_drop_item;
void()                   inv_prefetch;
/*---private---*/

//========================================================================
//
//   inv_toggle()
//      toggles inventory usage. self is client
//      called from impulse.qc
//========================================================================
void() inv_toggle = {
    sound(self, CHAN_AUTO, "misc/message2.wav", 1, ATTN_NORM);
    if (!(self.extraflags & CL_INVENTORYBIT)) {
        self.extraflags = self.extraflags | CL_INVENTORYBIT;
        if (self.extraflags & CL_MESSAGEBIT) {
            centerprint(self, "inventory enabled\n");
        }
        else {
            sprint(self, "inventory enabled\n");
        }
    }
    else {
        self.extraflags = self.extraflags - CL_INVENTORYBIT;
        if (self.extraflags & CL_MESSAGEBIT) {
            centerprint(self, "inventory disabled\n");
        }
        else {
            sprint(self, "inventory disabled\n");
        }
    }
};


//========================================================================
//
//   inv_list_items()
//
//========================================================================
void() inv_list_items = {
    local string inv_item1, inv_item2, inv_item3, inv_item4, inv_item5, inv_item6;
    local string inv_level;

    sprint(self, "Your items : T L ");
    if (self.inventory) {
        inv_item1 = inv_item2 = inv_item3 = inv_item4 = "- ";
        if (self.inventory & IT_SUIT) {
            inv_item1 = "B ";
        }

        if (self.inventory & IT_QUAD) {
            inv_item2 = "Q ";
        }

        if (self.inventory & IT_INVISIBILITY) {
            inv_item3 = "R ";
        }

        if (self.inventory & IT_INVULNERABILITY) {
            inv_item4 = "P ";
        }

        sprint4(self, inv_item4, inv_item3, inv_item2, inv_item1);
    }
    sprint(self, "\n");

    if (self.items & (IT_KEY1 | IT_KEY2)) {
        if (self.items & IT_KEY1) {
            inv_item5 = "Silver Key";
        }

        if (self.items & IT_KEY2) {
            inv_item6 = "Gold Key";
        }

        if ((self.items & IT_KEY1) && (self.items & IT_KEY2)) {
            inv_item5 = "Gold and Silver Keys";
            inv_item6 = "";
        }

        sprint4(self, "You have the ", inv_item5, inv_item6, "\n");
    }

    inv_level = "0";

    sprint(self, "Ammo");
    if (self.ammo_shells) {
        inv_level = ftos(self.ammo_shells);
        sprint2(self, " S:", inv_level);
    }

    if (self.ammo_nails) {
        inv_level = ftos(self.ammo_nails);
        sprint2(self, ", N:", inv_level);
    }

    if (self.ammo_rockets) {
        inv_level = ftos(self.ammo_rockets);
        sprint2(self, ", R:", inv_level);
    }

    if (self.ammo_cells) {
        inv_level = ftos(self.ammo_cells);
        sprint2(self, ", C:", inv_level);
    }

    inv_level = ftos(self.health);
    sprint2(self, "\nHealth: ", inv_level);

    // this is dumb
    if (self.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) {
        if (self.items & IT_ARMOR3) {
            inv_level = "heavy";
        }
        else if (self.items & IT_ARMOR2) {
            inv_level = "medium";
        }
        else {
            inv_level = "light";
        }

        sprint3(self, ", Armour: ", inv_level, " (");
        inv_level = ftos(self.armorvalue);
        sprint2(self, inv_level, ")");
    }

    sprint(self, "\n");
};


//========================================================================
//
//   inv_equip_item()
//
//========================================================================
void(float use_item) inv_equip_item = {
    local string item_noise;

    if (!(self.extraflags & CL_INVENTORYBIT)) {
        screen_message(self, "your backpack is sealed\n", MSG_INFO, FALSE);
        return;
    }

    if (self.inventory & use_item) {
        // check the player isn't already using the item
        if (self.items & use_item) {
            sound(self, CHAN_ITEM, "misc/message2.wav", 1, ATTN_NORM);
            sprint(self, "You are already using ");

            if (use_item == IT_SUIT) {
                sprint(self, "the Biosuit\n");
            }
            else if (use_item == IT_QUAD) {
                sprint(self, "Quad Damage\n");
            }
            else if (use_item == IT_INVISIBILITY) {
                sprint(self, "the Ring of Shadows\n");
            }
            else if (use_item == IT_INVULNERABILITY) {
                sprint(self, "the Pentagram\n");
            }
            else {
                sprint(self, "this item\n");
            }

            return;
        }
        else {
            // remove from the inventory
            self.inventory = self.inventory - use_item;

            if (use_item == IT_SUIT) {
                item_noise = "items/suit.wav";
            }
            else if (use_item == IT_QUAD) {
                item_noise = "items/damage.wav";
            }
            else if (use_item == IT_INVISIBILITY) {
                item_noise = "items/inv1.wav";
            }
            else if (use_item == IT_INVULNERABILITY) {
                item_noise = "items/protect.wav";
            }

            // activate the powerup...
            activate_powerup(self, item_noise, use_item);
        }
    }
    else {
        // ok, we don't have the item
        sprint(self, "You are not carrying ");

        if (use_item == IT_SUIT) {
            sprint(self, "the Biohazard Suit\n");
        }
        else if (use_item == IT_QUAD) {
            sprint(self, "the Quad Damage\n");
        }
        else if (use_item == IT_INVISIBILITY) {
            sprint(self, "the Ring of Shadows\n");
        }
        else if (use_item == IT_INVULNERABILITY) {
            sprint(self, "the Pentagram\n");
        }
        else {
            sprint(self, "this item\n");
        }

    }
};


//========================================================================
//
//   inv_drop_item()
//
//========================================================================
void(float item_dropped) inv_drop_item = {

    if (item_dropped == IT_AXE) {
        return;
    }

    local vector dropdir;
    local entity dropped;
    local string thing_name, thing_model;
    local float dropped_damage;

    // player has to have the item to drop it, but not so for monsters...
    if (self.items & item_dropped || self.flags & FL_MONSTER) {
        if (item_dropped & IT_IS_A_WEAPON) {
            // weapon dropping requires extra things doing - need to handle
            // damage values, esp. for mikerules. Also need to pick another weapon.
            // weapons dropped by monsters have no damage

            dropped_damage = 0;

            if (item_dropped == IT_SHOTGUN) {
                if (self.flags & FL_CLIENT) {
                    dropped_damage = self.weapon_01_damage;
                    self.weapon_01_damage = 0;
                }

                thing_model = "progs/g_shot.mdl";
            }
            else if (item_dropped == IT_SUPER_SHOTGUN) {
                if (self.flags & FL_CLIENT) {
                    dropped_damage = self.weapon_02_damage;
                    self.weapon_02_damage = 0;
                }

                thing_model = "progs/g_shot.mdl";
            }
            else if (item_dropped == IT_NAILGUN) {
                if (self.flags & FL_CLIENT) {
                    dropped_damage = self.weapon_03_damage;
                    self.weapon_03_damage = 0;
                }

                thing_model = "progs/g_nail.mdl";
            }
            else if (item_dropped == IT_SUPER_NAILGUN) {
                if (self.flags & FL_CLIENT) {
                    dropped_damage = self.weapon_04_damage;
                    self.weapon_04_damage = 0;
                }

                thing_model = "progs/g_nail2.mdl";
            }
            else if (item_dropped == IT_GRENADE_LAUNCHER) {
                if (self.flags & FL_CLIENT) {
                    dropped_damage = self.weapon_05_damage;
                    self.weapon_05_damage = 0;
                }

                thing_model = "progs/g_rock.mdl";
            }
            else if (item_dropped == IT_ROCKET_LAUNCHER) {
                if (self.flags & FL_CLIENT) {
                    inv_grapple_release();
                    dropped_damage = self.weapon_06_damage;
                    self.weapon_06_damage = 0;
                }

                thing_model = "progs/g_rock2.mdl";
            }
            else if (item_dropped == IT_LIGHTNING) {
                if (self.flags & FL_CLIENT) {
                    dropped_damage = self.weapon_07_damage;
                    self.weapon_07_damage = 0;
                }

                thing_model = "progs/g_light.mdl";
            }
        }

        // remove the item
        self.items = self.items - item_dropped;

        // clients switch weapon, pick best of rest
        if (self.flags & FL_CLIENT && item_dropped & IT_IS_A_WEAPON) {
            self.weapon = W_BestWeapon();
            W_SetCurrentAmmo();
        }

        dropped            = spawn();
        dropped.origin     = self.origin - '0 0 24';
        dropped.owner      = world;
        dropped.deadflag   = DEAD_DEAD;
        dropped.items      = item_dropped;
        dropped.netname    = name_of_thing(item_dropped);
        dropped.takedamage = DAMAGE_NO;

        if (item_dropped & IT_IS_A_WEAPON) {
            dropped.health  = dropped_damage;
        }

        // throw the item forwards, with a slight lift
        dropdir            = 300 * normalize (v_forward);
        dropped.velocity   = self.velocity + dropdir;
        dropped.velocity_z = dropped.velocity_z + 200;
        dropped.flags      = FL_ITEM;
        dropped.solid      = SOLID_TRIGGER;
        dropped.movetype   = MOVETYPE_TOSS;
        setmodel(dropped, thing_model);
        setsize(dropped, '-16 -16 0', '16 16 56');

        dropped.touch = SUB_Null;
        if (self.flags & FL_CLIENT) {
            dropped.nextthink = time + 3;
        }
        else {
            dropped.nextthink = time + 0.05;
        }
        dropped.think = become_pickup;
    }
    return;
};

void() inv_prefetch = {
    // parm1 contains inventory contents (as well as other stuff)
    // we use this function to precache the item sounds when the item itself
    // is not in the level
    precache_sound("items/suit.wav");
    precache_sound("items/suit2.wav");
    precache_sound("shared/inhale.wav");
    precache_sound("shared/exhale.wav");
    precache_sound("shared/w_exhale.wav");
    precache_sound("items/protect.wav");
    precache_sound("items/protect2.wav");
    precache_sound("items/protect3.wav");
    precache_sound("items/inv1.wav");
    precache_sound("items/inv2.wav");
    precache_sound("items/inv3.wav");
    precache_sound("items/damage.wav");
    precache_sound("items/damage2.wav");
    precache_sound("items/damage3.wav");
};
