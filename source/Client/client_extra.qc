// client_extra.qc

/*---public---*/
// $VER: client_extra.qc 1.97 © Karlos '99 (17/10/1999)

// public function prototypes
// highlevel
void () toggle_screenmessages;
void () toggle_gender;
void () toggle_show_netnames;
void (float opt) cycle_ion_colour;
void () cycle_handedness;
void () toggle_smooth_subents;

// lowlevel
void (entity sendto, string msg_string, float msg_type, float override) screen_message;
void () save_client_extraparms;
void () default_client_extraparms;
void () set_client_extraparms;
void (entity targ, entity attacker) ClientObituary;
/*---private---*/

//==================================================================================
//
//   toggle_screenmessages()
//
//==================================================================================
void() toggle_screenmessages = {
    if ((self.extraflags & CL_MESSAGEBIT) == 0) {
        self.extraflags = self.extraflags | CL_MESSAGEBIT;
        screen_message(self, "screen messages on\n", MSG_INFO, TRUE);
    }
    else {
        self.extraflags = self.extraflags - CL_MESSAGEBIT;
        screen_message(self, "screen messages off\n", MSG_INFO, TRUE);
    }
};


//==================================================================================
//
//   toggle_gender()
//
//==================================================================================
void() toggle_gender = {
    // default is MALE
    if ((self.extraflags & CL_GENDERBIT) == 0) {
        self.extraflags = self.extraflags | CL_GENDERBIT;
        screen_message(self, "Your gender will be changed to FEMALE\nwhen you next respawn\n", MSG_INFO, FALSE);
    }
    else {
        self.extraflags = self.extraflags - CL_GENDERBIT;
        screen_message(self, "Your gender will be changed to MALE\nwhen you next respawn\n", MSG_INFO, FALSE);
    }
};

//==================================================================================
//
//   toggle_show_netnames()
//
//==================================================================================
void() toggle_show_netnames = {
    if ((self.extraflags & CL_SHOW_TARGETS) == 0) {
        self.extraflags = self.extraflags | CL_SHOW_TARGETS;
        screen_message(self, "client naming on\n", MSG_INFO, TRUE);
    }
    else {
        self.extraflags = self.extraflags - CL_SHOW_TARGETS;
        screen_message(self, "client naming off\n", MSG_INFO, TRUE);
    }
};


//==================================================================================
//
//   cycle_ion_colour(float opt)
//
//==================================================================================
void (float opt) cycle_ion_colour = {
    if (opt) {
        self.ion_colour = self.ion_colour + 512;
        if (self.ion_colour > ION_YELLOW_IDX) {
            self.ion_colour = ION_WHITE_IDX;
        }
    }
    else {
        self.ion_colour = self.ion_colour - 512;
        if (self.ion_colour < ION_WHITE_IDX) {
            self.ion_colour = ION_YELLOW_IDX;
        }
    }

    if (effectflags & FX_CON_FLASH) {
        stuffcmd (self, "bf\n");
    }

    bprint2(self.netname, " changed ion colour to ");

    if (self.ion_colour == ION_BLUE_IDX) {
        bprint("blue\n");
    }
    else if (self.ion_colour == ION_RED_IDX) {
        bprint("red\n");
    }
    else if (self.ion_colour == ION_MAGENTA_IDX) {
        bprint("magenta\n");
    }
    else if (self.ion_colour == ION_GREEN_IDX) {
        bprint("green\n");
    }
    else if (self.ion_colour == ION_CYAN_IDX) {
        bprint("cyan\n");
    }
    else if (self.ion_colour == ION_YELLOW_IDX) {
        bprint("yellow\n");
    }
    else {
        bprint("white\n");
    }
};

void () cycle_handedness = {
    if ((self.extraflags & CL_CENTREHANDED) == CL_NOHANDVIEW) {
        // none > right
        self.extraflags = self.extraflags | CL_RIGHTHANDED;
        if (!(self.flags & FL_USING_CAMERA)) {
            localcmd("r_drawviewmodel 1;scr_ofsy -4\n");
        }
        else {
            sprint(self, "Switched to right handed...\n");
        }
    }
    else if ((self.extraflags & CL_CENTREHANDED) == CL_RIGHTHANDED) {
        // right > left
        self.extraflags = (self.extraflags - CL_RIGHTHANDED) | CL_LEFTHANDED;
        if (!(self.flags & FL_USING_CAMERA)) {
            localcmd("r_drawviewmodel 1;scr_ofsy 4\n");
        }
        else {
            sprint(self, "Switched to left handed...\n");
        }
    }
    else if ((self.extraflags & CL_CENTREHANDED) == CL_LEFTHANDED) {
        // left > centre
        self.extraflags = self.extraflags | CL_CENTREHANDED;
        if (!(self.flags & FL_USING_CAMERA)) {
            localcmd("r_drawviewmodel 1;scr_ofsy 0\n");
        }
        else {
            sprint(self, "Switched to centre handed...\n");
        }
    }
    else if ((self.extraflags & CL_CENTREHANDED) == CL_CENTREHANDED)
    {
        // centre > none
        self.extraflags = self.extraflags - CL_CENTREHANDED;
        if (!(self.flags & FL_USING_CAMERA)) {
            localcmd("r_drawviewmodel 0;scr_ofsy 0\n");
        }
        else {
            sprint(self, "Removed weaponview...\n");
        }
    }
};


void () toggle_smooth_subents = {
    if (self.flags & FL_SMOOTH_SUBENTS) {
        self.flags = self.flags - FL_SMOOTH_SUBENTS;
        sprint(self, "subentity movement interpolation off\n");
    }
    else {
        self.flags = self.flags | FL_SMOOTH_SUBENTS;
        sprint(self, "subentity movement interpolation on\n");
    }
};


//==================================================================================
//
//   save_client_extraparms()
//
//==================================================================================
void() save_client_extraparms = {
    // save player stuff to 'temp1'

    local string settings;
    local float  savebits;

    // backup client extras - skin, ion colour, messaging, handedness etc...
    parm16 = self.skin | self.extraflags | self.ion_colour;

    // backup needed flags from self.flags. If dead, backup only the camera/target bits..
    if (self.health > 0) {
        savebits = self.flags & FL_SAVE_BITS; // living, so back up all bits
    }
    else {
        savebits = self.flags & (FL_USING_CAMERA | FL_USING_TARGET); // dead, so just these bits
    }

    parm16   = parm16 | savebits;
    settings = ftos(parm16);
    cvar_set("temp1", settings);
};


//==================================================================================
//
//   set_client_extraparms()
//
//==================================================================================
void() set_client_extraparms =
{
    if (!parm16) {
        parm16 = cvar("temp1");
    }

    if (!parm16) {
        default_client_extraparms();
    }

    self.skin               = parm16 & MAX_SKIN;
    self.extraflags         = parm16 & CL_SAVE_BITS;
    self.ion_colour         = parm16 & ION_BITS;
    self.gender             = parm16 & CL_GENDERBIT;
    self.flags = self.flags | (parm16 & FL_SAVE_BITS);


    // do fov stuff
    local float val;
    val = cvar("fov");

    if (val >= 80 && val <= 120) {
        self.def_fov = val;
    }
    else {
        self.def_fov = 90;
    }

    val = cvar("gamma");
    if (val >= 0.5 && val <= 1) {
        self.def_gamma = val;
    }
    else {
        self.def_gamma = 0.8;
    }

    self.cur_gamma = self.def_gamma;
    self.cur_fov   = self.def_fov;
};


//==================================================================================
//
//   default_client_extraparms()
//
//==================================================================================
void() default_client_extraparms = {
    // should only be called from set_client extraparms when no temp1
    self.gender     = 0; // MALE
    self.flags      = FL_USING_TARGET;
    self.extraflags = self.gender | CL_MESSAGEBIT | CL_CENTREHANDED;
    self.ion_colour = ION_BLUE_IDX;
    sprint(self, "You have no client prefs, using internal defaults\n");
    save_client_extraparms();
};


//============================================================================
//
//  screen_message
//
//============================================================================
void(entity sendto, string msg_string, float msg_type, float override) screen_message = {
    if (!(sendto.flags & FL_CLIENT)) {
        return;  // don't send messages to non clients !
    }

    if (msg_type == MSG_INFO) {
        sound(sendto, CHAN_ITEM, "misc/message2.wav", 1, ATTN_NORM);
    }
    else if (msg_type == MSG_WARN) {
        sound(sendto, CHAN_ITEM, "misc/msg_warning.wav", 1, ATTN_NORM);
    }
    else if (msg_type == MSG_OTHER) {
        sound(sendto, CHAN_ITEM, "misc/message.wav", 1, ATTN_NORM);
    }

    if (sendto.extraflags & CL_MESSAGEBIT || override) {
        centerprint (sendto, msg_string);
    }
    else {
        sprint(sendto, msg_string);
    }
};


//===========================================================================
//
//   ClientObituary()
//      called when a player dies
//      Fixed for player gender and new death modes
//
//===========================================================================
void(entity targ, entity attacker) ClientObituary = {

    if (targ.classname != "player") {
        return;
    }

    local float deathmessage;
    local string deathstring, deathstring2;

    deathmessage = random();      // assign random value to deathmessage

    if (attacker.classname == "teledeath") {
        // player telefragged
        if (deathmessage < 0.5) {
            bprint4(targ.netname, " got in ", attacker.netname, "'s way\n");
        }
        else {
            bprint4(targ.netname, " tried to invade ", attacker.netname, "'s personal space\n");
        }
        attacker.owner.frags = attacker.owner.frags + 1;
        return;
    }

    if (attacker.classname == "teledeath2") {
        bprint3("Satan's power deflects ", targ.netname, "'s telefrag\n");
        targ.frags = targ.frags - 1;
        return;
    }

    if (attacker.classname == "player") {
        deathstring2 = "\n";
        if (targ == attacker) {
            // Player just killed himself. Silly bugger.
            attacker.frags = attacker.frags - 1;   // lose a frag
            //bprint (targ.netname);
            // Death by water discharge - three messages

            if (targ.weapon == IT_LIGHTNING && targ.waterlevel > 1) {
                if (deathmessage < 0.33) {
                    deathstring2 = " discharge shocking\n";
                    if (!self.gender) {
                        deathstring = " found his";
                    }
                    else {
                        deathstring = " found her";
                    }
                }
                else if (deathmessage < 0.66) {
                    deathstring = " fried ";
                    if (!self.gender) {
                        deathstring2 = "himself\n";
                    }
                    else {
                        deathstring2 = "herself\n";
                    }
                }
                else {
                    deathstring = " played the ligtning rod\n";
                }
                bprint3(targ.netname, deathstring, deathstring2);
                return;
            }

            // Death by own weapon
            if (targ.weapon == IT_GRENADE_LAUNCHER) {
                // Grenade
                if (deathmessage < 0.33) {
                    deathstring = " tried to put the pin back in";
                }
                else if (deathmessage < 0.66) {
                    deathstring = "wouldn't share ";
                    if (!self.gender) {
                        deathstring2 = "his pineapple\n";
                    }
                    else {
                        deathstring2 = "her pineapple\n";
                    }
                }
                else {
                    deathstring = " tripped on ";
                    if (!self.gender) {
                        deathstring2 = "his own grenade\n";
                    }
                    else {
                        deathstring2 = "her own grenade\n";
                    }
                }
            }
            else {
                // player killed himself some other way....
                if (deathmessage < 0.33) {
                    deathstring = " became bored with life";
                }
                else if (deathmessage < 0.66) {
                    deathstring = " commited suicide";
                }
                else {
                    deathstring = " backfired";
                }
            }
            bprint3(targ.netname, deathstring, deathstring2);
            return;
        }

        // Player killed a team member. Insult gratuitously and lose a frag
        else if (
            (teamplay == 2) &&
            (targ.team > 0) &&
            (targ.team == attacker.team)
        ) {
            if (deathmessage < 0.25) {
                deathstring = " mowed down a teammate";
            }
            else if (deathmessage < 0.50) {
                deathstring = " should check ";
                if (!self.gender) {
                    deathstring2 = "his glasses\n";
                }
                else {
                    deathstring2 = "her glasses\n";
                }
            }
            else if (deathmessage < 0.75) {
                deathstring = " scored a frag for the other team";
            }
            else {
                deathstring = " lost another friend";
            }

            bprint3(attacker.netname, deathstring, deathstring2);
            attacker.frags = attacker.frags - 1;
            return;
        }
        else {
            // Player killed an opponent (those are the rules, I thought)

            attacker.frags = attacker.frags + 1;

            //-----------------------------------------------------------------------------
            if (attacker.weapon == IT_AXE) {
                if (deathmessage < 0.5) {
                    deathstring  = " was cut down to size by ";
                    deathstring2 = "\n";
                }
                else {
                    deathstring  = " was hacked to death by ";
                    deathstring2 = "'s axe\n";
                }
            }

            //-----------------------------------------------------------------------------
            else if (attacker.weapon == IT_SHOTGUN) {
                if (deathmessage < 0.5) {
                    deathstring  = " chewed on ";
                    deathstring2 = "'s boomstick\n";
                }
                else {
                    deathstring  = " was perforated by ";
                    deathstring2 = "'s shotgun\n";
                }
            }

            //----------------------------------------------------------------------------
            else if (attacker.weapon == IT_SUPER_SHOTGUN) {
                if (targ.health > -40) {
                    deathstring  = " ate 2 loads of ";
                    deathstring2 = "'s buckshot\n";
                }
                else {
                    // gibbed
                    deathstring  = " was blown away by ";
                    deathstring2 = "'s super shotgun\n";
                }
            }

            //-----------------------------------------------------------------------------
            else if (attacker.weapon == IT_NAILGUN) {
                if (deathmessage < 0.66) {
                    deathstring = " was nailed by ";
                    //deathstring2 = "\n";
                }
                else {
                    deathstring  = " became ";
                    deathstring2 = "'s latest pin-up\n";
                }
            }

            //-----------------------------------------------------------------------------
            else if (attacker.weapon == IT_SUPER_NAILGUN) {
                if (targ.health > -40) {
                    if (deathmessage < 0.5) {
                        deathstring = " was punctured by ";
                        //deathstring2 = "\n";
                    }
                    else {
                        deathstring  = " recieved his jabs from ";
                        deathstring2 = "'s super nailgun\n";
                    }
                }
                else {
                    // gibbed (likely for quad damage)
                    deathstring  = " was torn apart by ";
                    deathstring2 = "'s spikes\n";
                }
            }

            //-----------------------------------------------------------------------------
            else if (
                targ.deathtype == "radius_damage" &&
                attacker.weapon != IT_ROCKET_LAUNCHER
            ) {
                // above check is more complex since targ may have been killed
                // by a hand grenade. So, we work out that targ was killed by
                // a radius_damage event and that it wasn't from a rocket or
                // the ion end point
                if (targ.health > -40) {
                    deathstring  = " eats ";
                    deathstring2 = "'s pineapple\n";
                }
                else {
                    // gibbed
                    deathstring  = " was shredded by ";
                    deathstring2 = "'s shrapnel\n";
                }
            }

            //-----------------------------------------------------------------------------
            else if (attacker.weapon == IT_ROCKET_LAUNCHER) {
                if (targ.deathtype != "grapple") {
                    // was killed by a rocket
                    if (targ.health > -40) {
                        deathstring  = " rides ";
                        deathstring2 = "'s rocket\n";
                    }
                    else {
                        // gibbed
                        deathstring  = " was gibbed by ";
                        deathstring2 = "'s rocket\n";
                    }
                }
                else {
                    // was killed by a hook
                    deathstring  = " was gutted by ";
                    deathstring2 = "'s hook\n";
                }
            }

            //----------------------------------------------------------------------------
            else if (attacker.weapon == IT_LIGHTNING) {
                if (targ.deathtype == "discharge") {
                    // was killed by bolt
                    deathstring = " accepts ";
                    if (attacker.waterlevel > 1) {
                        deathstring2 = "'s discharge\n";
                    }
                    else {
                        deathstring2 = "'s shaft\n";
                    }
                }
                else {
                    // was killed by ion cannon
                    if (targ.health > -40) {
                        deathstring  = " was stung by ";
                        deathstring2 = "'s ion trail\n";
                    }
                    else {
                        deathstring  = " was vapourised by ";
                        deathstring2 = "'s ion stream\n";
                    }
                }
            }

            //----------------------------------------------------------------------------

            // broadcast the obituary
            bprint4(targ.netname, deathstring, attacker.netname, deathstring2);
        }
        targ.deathtype = "";
        return;
    }
    else {
        targ.frags = targ.frags - 1;

        //----------------------------------------------------------------------------
        // killed by a montser?
        if (attacker.flags & FL_MONSTER) {
            //-------------------------------------------------------------------------
            if (attacker.classname == "monster_army") {
                if (targ.deathtype = "bullet") {
                    if (deathmessage < 0.5) {
                        deathstring = " was gunned down by a Grunt";
                    }
                    else {
                        deathstring = " wasn't faster than a speeding bullet";
                    }
                }
                else {
                    if (deathmessage < 0.5) {
                        deathstring = " was blown away by a Grunt";
                    }
                    else {
                        deathstring = " died of lead poisoning";
                    }
                }
            }

            //-------------------------------------------------------------------------
            else if (attacker.classname == "monster_demon1") {
                deathstring2 = " by a Feind\n";
                if (deathmessage < 0.5) {
                    deathstring = " was eviscerated";
                }
                else {
                    deathstring = " was mutilated";
                }
            }

            //-------------------------------------------------------------------------
            else if (attacker.classname == "monster_dog") {
                if (deathmessage < 0.5) {
                    deathstring = " was mauled by Rottweiler";
                }
                else {
                    deathstring = " went to the dogs";
                }
            }

            //-------------------------------------------------------------------------
            else if (attacker.classname == "monster_dragon")
            {
                if (deathmessage < 0.5) {
                    deathstring = " was fried by a Dragon";
                }
                else {
                    deathstring = " was barbequed";
                }
            }

            //-------------------------------------------------------------------------
            else if (attacker.classname == "monster_enforcer") {
                if (targ.deathtype == "ion") {
                    if (deathmessage < 0.5) {
                        deathstring = " was ionized by an Enforcer";
                    }
                    else {
                        deathstring = " couldn't dodge the Enforcers Ion Cannon";
                    }
                }
                else
                {
                    if (deathmessage < 0.5) {
                        deathstring = " was blasted by an Enforcer";
                    }
                    else {
                        deathstring = " stared into the pretty lights of the Enforcers laser";
                    }
                }
            }

            //-------------------------------------------------------------------------
            else if (attacker.classname == "monster_fish") {
                if (deathmessage < 0.5) {
                    deathstring = " was fed to the Rotfish";
                }
                else {
                    deathstring = " fell hook, line and sinker";
                }
            }

            //-------------------------------------------------------------------------
            else if (attacker.classname == "monster_hell_knight") {
                deathstring2 = " by a Hell Knight\n";
                if (targ.deathtype == "projectile") {
                    deathstring = " was chargrilled";
                }
                else {
                    deathstring = " was slain";
                }
            }

            //-------------------------------------------------------------------------
            else if (attacker.classname == "monster_knight")
            {
                deathstring2 = " by a Knight\n";
                if (deathmessage < 0.5) {
                    deathstring = " was slashed";
                }
                else {
                    deathstring = " was run through";
                }
            }

            //-------------------------------------------------------------------------
            else if (attacker.classname == "monster_ogre")
            {
                deathstring2 = " by an Ogre\n";
                if (targ.deathtype == "radius_damage") {
                    deathstring = " was blown away";
                }
                else {
                    deathstring = " was calved";
                }
            }

            //-------------------------------------------------------------------------
            else if (attacker.classname == "monster_oldone")
            {
                if (deathmessage < 0.5) {
                    deathstring = " became one with Shub-Niggurath";
                }
                else {
                    deathstring = " failed at the last hurdle";
                }
            }

            //-------------------------------------------------------------------------
            else if (attacker.classname == "monster_shalrath") {
                if (deathmessage < 0.5) {
                    deathstring = " was exploded by a Vore";
                }
                else {
                    deathstring = " couldn't avoid the Vore's missile";
                }
            }

            //-------------------------------------------------------------------------
            else if (attacker.classname == "monster_shambler") {
                deathstring2 = " by a Shambler\n";
                if (targ.deathtype == "discharge") {
                    deathstring = " was shocked";
                }
                else {
                    deathstring = " was smashed";
                }
            }

            //-------------------------------------------------------------------------
            else if (attacker.classname == "monster_tarbaby") {
                deathstring2 = " by a Spawn\n";
                if (targ.deathtype == "radius_damage") {
                    deathstring = " was exploded";
                }
                else {
                    deathstring = " was slimed";
                }
            }

            //-------------------------------------------------------------------------
            else if (attacker.classname == "monster_vomit") {
                if (deathmessage < 0.5) {
                    deathstring = " was vomited on by a Vomitus";
                }
                else {
                    deathstring = "'s last words were 'Ick'";
                }
            }

            //-------------------------------------------------------------------------
            else if (attacker.classname == "monster_wizard") {
                if (deathmessage < 0.5) {
                    deathstring = " was scragged by a Scrag";
                }
                else {
                    deathstring = " ate a Scrag's snotball";
                }
            }

            //-------------------------------------------------------------------------
            else if (attacker.classname == "monster_zombie") {
                if (deathmessage < 0.5) {
                    deathstring = " joins the Zombies";
                }
                else {
                    deathstring = " thought that bit of meat was out of date";
                }
            }

            // broadcast the message

            targ.deathtype = "";
            bprint3(targ.netname, deathstring, deathstring2);
            return;
        }

        //============================================================================
        // tricks and traps
        if (attacker.classname == "explo_box") {
            if (deathmessage < 0.5) {
                deathstring = " never liked life anyway";
            }
            else {
                deathstring = "really couldn't cointain ";
                if (!self.gender) {
                    deathstring2 = "himself\n";
                }
                else {
                    deathstring2 = "herself\n";
                }
            }
        }

        //-------------------------------------------------------------------------
        else if (attacker.solid == SOLID_BSP && attacker != world) {
            if (deathmessage < 0.5) {
                deathstring = " felt the world closing in";
            }
            else {
                deathstring = " cracked under the pressure";
            }
        }

        //-------------------------------------------------------------------------
        else if (attacker.classname == "trap_spikeshooter") {
            if (attacker.spawnflags & SPAWNFLAG_LASER) {
                // laser trap
                if (deathmessage < 0.5) {
                    deathstring = " didn't see it coming";
                }
                else {
                    deathstring = " looked into the light";
                }
            }
            else {
                if (deathmessage < 0.5) {
                    deathstring = " was spiked";
                }
                else {
                    deathstring = " didn't see the point";
                }
            }
        }

        //-------------------------------------------------------------------------

        else if (attacker.classname == "flame") {
            if (deathmessage < 0.5) {
                deathstring = " shouldn't have played with matches";
            }
            else {
                deathstring = " was torched by an old flame";
            }
        }

        //-------------------------------------------------------------------------
        else if (attacker.classname == "fireball") {
            if (deathmessage < 0.5) {
                deathstring = " headered a lavaball";
            }
            else {
                deathstring = " ate one vindaloo too many";
            }
        }

        //-------------------------------------------------------------------------
        else if (attacker.classname == "trigger_changelevel") {
            deathstring    = " tried to sneak away";
        }

        //-------------------------------------------------------------------------
        else if (targ.watertype == -3) {
            // Water

            if (deathmessage < 0.5) {
                deathstring = " sleeps with the fishes";
            }
            else {
                deathstring = " tried to drink the place dry";
            }
        }
        else if (targ.watertype == -4) {
            // Slime
            if (deathmessage < 0.5) {
                deathstring = " dissolved";
            }
            else {
                deathstring = " can't exist on slime alone";
            }
        }
        else if (targ.watertype == -5) {
            // Lava
            if (targ.health < -15) {
                deathstring = " burst into flames";
            }
            else if (deathmessage < 0.5) {
                deathstring = " took a hot bath";
            }
            else {
                deathstring = " visits the Volcano God";
            }
        }

        //-------------------------------------------------------------------------
        // fell to their death?
        else if (targ.deathtype == "falling") {
            if (deathmessage < 0.33) {
                deathstring = " made a bad impression";
            }
            else if (deathmessage < 0.66) {
                deathstring = " cratered";
            }
            else {
                deathstring2 = " parachute\n";
                if (!self.gender) {
                    deathstring = " forgot his";
                }
                else {
                    deathstring = " forgot her";
                }
            }
        }

        //-------------------------------------------------------------------------
        else {
            // hell if I know; he's just dead!!!
            deathstring = " is no more";
        }
        // broadcast the message
        targ.deathtype = "";
        bprint3(targ.netname, deathstring, deathstring2);
    }
};

