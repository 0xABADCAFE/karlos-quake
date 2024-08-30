// ai_team.qc
//============================================================================
//   TEAM AI
//============================================================================
/*---public---*/
// $VER: ai_team.qc 1.00 Karlos'99 (23/1/2000)

// public function prototypes
float (entity observer, entity observed) AI_TeamIsEnemy;
void(entity caller, float radius, float by_sight, float by_sound) AI_TeamCallForHelp;
void() AI_TeamSetAllEnemy;
void() AI_TeamClearAllEnemy;
void() AI_TeamInit;
void(float team_id, float can_be_leader) AI_TeamJoin;
entity(float team_id) AI_TeamProperties;
void() dprint_team_stats;
void(entity whosdead, entity whodunnit) AI_TeamUpdate;
void(float team_id) AI_TeamListEnemy;

/*---private---*/

// Entities representing teams. These entities contain shared state for team members.
//
// .team         Team ID
// .netname      Team name
// .owner        Team leader
// .ammo_shells  Team size
// .ammo_nails   Enemy team bitmask
entity ai_team_army_1;
entity ai_team_army_2;
entity ai_team_army_3;
entity ai_team_knight_1;
entity ai_team_knight_2;
entity ai_team_knight_3;
entity ai_team_undead_1;
entity ai_team_undead_2;
entity ai_team_undead_3;
entity ai_team_ogre_1;
entity ai_team_ogre_2;
entity ai_team_ogre_3;


//================================================================================

/**
 * Checks if an observed entity belongs to a hostile team
 */
float (entity observer, entity observed) AI_TeamIsEnemy = {
    // two members of the same team cannot be enemies (unless zero)

    // clients are always seen as enemies to monsters (for now)
    if (observed.ai_team_id == TEAM_CLIENT) {
        return TRUE;
    }
    else if (observed.ai_team_id == TEAM_NONE) {
        return FALSE;
    }
    else if (observer.ai_team_id == observed.ai_team_id) {
        return FALSE;
    }

    return (observer.ai_team.ammo_nails & observed.ai_team_id) != 0;

};

/**
 * Check if an entity can respond to the caller
 *
 */
float(entity caller, entity who, float by_sight, float by_sound) AI_CanRespond = {
    // Ealy out chain
    if (!(who.flags & FL_MONSTER)) {
        // Not a monster
        return FALSE;
    }
    else if (who.deadflag != DEAD_NO) {
        // Dying or dead
        return FALSE;
    }
    else if (who.ai_team_id == TEAM_NONE) {
        // Has to be teamed
        return FALSE;
    }
    else if (who == caller) {
        // Logically this can only happen once so it's the least likely
        return FALSE;
    }

    // We have a candidate responder
    // Check if the caller can be seen/heard
    local float see, hear;

    if (by_sound) {
        hear = is_audible(caller, who);
    } else {
        hear = FALSE;
    }

    if (!hear) {
        if (by_sight) {
            see = is_visible(caller, who);
        } else {
            see = FALSE;
        }
    }

    if (!(see | hear)) {
        return FALSE;
    }

    if (who.enemy) {
        // If the responder is busy fighting an existing visible enemy...
        if (is_visible(who.enemy, who)) {
            return FALSE;
        }
    }
    return TRUE;
};

void(entity caller, float radius, float by_sight, float by_sound) AI_TeamCallForHelp = {
    // Use the existing .wait field for rate limiting calls to help
    if (time < self.wait) {
        return;
    }

    // Unteamed and clients never call for help
    if (!self.ai_team_id || self.ai_team_id & (TEAM_CLIENT|TEAM_NONE)) {
        return;
    }

    // Rate limit
    self.wait = time + 0.5;

    local string t_name, t_mbmr;

    if (developer & DV_SHOW_TEAM_AI) {
        t_name = caller.ai_team.netname;
        t_mbmr = ftos(caller.ai_team_pos);
        dprint6(
            caller.netname,
            " [",
            t_name,
            "/",
            t_mbmr,
            "] call for help\n"
        );
    }

    // Allow a monster to call for help from any of his team who are within
    // radius.
    // Additionally, enable sight/sound when activating team mates

    local entity head;

    head = findradius(caller.origin, radius);
    while (head) {

        if (AI_CanRespond(caller, head, by_sight, by_sound)) {

            t_name = head.ai_team.netname;
            t_mbmr = ftos(head.ai_team_pos);
            // if responder is of same team, come to help
            if (caller.ai_team_id == head.ai_team_id) {
                if (developer & DV_SHOW_TEAM_AI) {
                    dprint6(
                        head.netname,
                        " [",
                        t_name,
                        "/",
                        t_mbmr,
                        ":F] responding\n"
                    );
                }
                head.enemy = caller.enemy;
                head.think = FoundTarget;
            }
            // if responder sees caller as an enemy, come to kill...ho..ho..ho
            else if (AI_TeamIsEnemy(head, caller)) {
                if (developer & DV_SHOW_TEAM_AI) {
                    dprint6(
                        head.netname,
                        " [",
                        t_name,
                        "/",
                        t_mbmr,
                        ":E] responding\n"
                    );
                }
                head.enemy = caller;
                head.think = FoundTarget;
            }
        }

        head = head.chain;
    }
};

void() AI_TeamSetAllEnemy = {

//    ai_team_none.ammo_nails     = TEAM_ANY;
    ai_team_army_1.ammo_nails   = TEAM_ANY;
    ai_team_army_2.ammo_nails   = TEAM_ANY;
    ai_team_army_3.ammo_nails   = TEAM_ANY;
    ai_team_knight_1.ammo_nails = TEAM_ANY;
    ai_team_knight_2.ammo_nails = TEAM_ANY;
    ai_team_knight_3.ammo_nails = TEAM_ANY;
    ai_team_undead_1.ammo_nails = TEAM_ANY;
    ai_team_undead_2.ammo_nails = TEAM_ANY;
    ai_team_undead_3.ammo_nails = TEAM_ANY;
    ai_team_ogre_1.ammo_nails   = TEAM_ANY;
    ai_team_ogre_2.ammo_nails   = TEAM_ANY;
    ai_team_ogre_3.ammo_nails   = TEAM_ANY;
    dprint("All teams enemy\n");
};

void() AI_TeamClearAllEnemy = {
    ai_team_army_1.ammo_nails   = TEAM_CLIENT;
    ai_team_army_2.ammo_nails   = TEAM_CLIENT;
    ai_team_army_3.ammo_nails   = TEAM_CLIENT;
    ai_team_knight_1.ammo_nails = TEAM_CLIENT;
    ai_team_knight_2.ammo_nails = TEAM_CLIENT;
    ai_team_knight_3.ammo_nails = TEAM_CLIENT;
    ai_team_undead_1.ammo_nails = TEAM_CLIENT;
    ai_team_undead_2.ammo_nails = TEAM_CLIENT;
    ai_team_undead_3.ammo_nails = TEAM_CLIENT;
    ai_team_ogre_1.ammo_nails   = TEAM_CLIENT;
    ai_team_ogre_2.ammo_nails   = TEAM_CLIENT;
    ai_team_ogre_3.ammo_nails   = TEAM_CLIENT;
    bprint("No teams enemy\n");
};


entity(float id, float base, string name, float enemy_mask) ai_team_spawn = {
    local entity e;
    e               = spawn();
    e.classname     = "ai_team";
    e.team          = id;
    e.ai_team_class = base;
    e.netname       = name;
    e.owner         = world;
    e.ammo_shells   = 0;
    e.ammo_nails    = enemy_mask;

    //dprint3("Created team ", e.netname, "\n");
    return e;
};


//================================================================================

/**
 * Create the team database. Each team is spawned as an entity then the teams are
 * grouped by circular linking.
 */
void() ai_team_create_all = {
    ai_team_army_1   = ai_team_spawn(TEAM_ARMY_1, TEAM_ARMY_1, "army_1", TEAM_CLIENT);
    ai_team_army_2   = ai_team_spawn(TEAM_ARMY_2, TEAM_ARMY_1, "army_2", TEAM_CLIENT);
    ai_team_army_3   = ai_team_spawn(TEAM_ARMY_3, TEAM_ARMY_1, "army_3", TEAM_CLIENT);
    ai_team_knight_1 = ai_team_spawn(TEAM_KNIGHT_1, TEAM_KNIGHT_1, "knight_1", TEAM_CLIENT);
    ai_team_knight_2 = ai_team_spawn(TEAM_KNIGHT_2, TEAM_KNIGHT_1, "knight_2", TEAM_CLIENT);
    ai_team_knight_3 = ai_team_spawn(TEAM_KNIGHT_3, TEAM_KNIGHT_1, "knight_3", TEAM_CLIENT);
    ai_team_undead_1 = ai_team_spawn(TEAM_UNDEAD_1, TEAM_UNDEAD_1, "undead_1", TEAM_CLIENT);
    ai_team_undead_2 = ai_team_spawn(TEAM_UNDEAD_2, TEAM_UNDEAD_1, "undead_2", TEAM_CLIENT);
    ai_team_undead_3 = ai_team_spawn(TEAM_UNDEAD_3, TEAM_UNDEAD_1, "undead_3", TEAM_CLIENT);
    ai_team_ogre_1   = ai_team_spawn(TEAM_OGRE_1, TEAM_OGRE_1, "ogre_1", TEAM_CLIENT);
    ai_team_ogre_2   = ai_team_spawn(TEAM_OGRE_2, TEAM_OGRE_1, "ogre_2", TEAM_CLIENT);
    ai_team_ogre_3   = ai_team_spawn(TEAM_OGRE_3, TEAM_OGRE_1, "ogre_3", TEAM_CLIENT);

    // Link the teams into ringbuffers for ease of assignment
    ai_team_army_1.chain   = ai_team_army_2;
    ai_team_army_2.chain   = ai_team_army_3;
    ai_team_army_3.chain   = ai_team_army_1;

    ai_team_knight_1.chain = ai_team_knight_2;
    ai_team_knight_2.chain = ai_team_knight_3;
    ai_team_knight_3.chain = ai_team_knight_1;

    ai_team_undead_1.chain = ai_team_undead_2;
    ai_team_undead_2.chain = ai_team_undead_3;
    ai_team_undead_3.chain = ai_team_undead_1;

    ai_team_ogre_1.chain   = ai_team_ogre_2;
    ai_team_ogre_2.chain   = ai_team_ogre_3;
    ai_team_ogre_3.chain   = ai_team_ogre_1;

    ai_team_unteamed       = 0;
};

void() AI_TeamInit = {

    // Clears the monster team database
    // Should be called before any monster initialisation (eg worldspawn)

    // First, read the max team size, diffusion and tolerances
    // If the game is random, increase tolerance to non equivalent teams
    // Note, in a random game, the effect of dispersion is not signifigant
    // since the random monster switching tends to cause a large dispersion

    // team maximum size : 0 - 31
    ai_team_max_size      = map_opts & TEAM_MAX_BITS;

    // team dispersion   : 0 - 0.96875
    ai_team_spread      = (map_opts & TEAM_DISP_BITS)/1024;

    // equivalent class tolerance : 0 - 0.96875
    ai_team_tolerance_same = (map_opts & TEAM_SAME_TOL_BITS)/32768;
    ai_team_tolerance_diff = (map_opts & TEAM_DIFF_TOL_BITS)/1048576;

    if (randomgame) {
        // Inc non-equiv tolerance 50% in random game, limit to equiv tolerance
        ai_team_tolerance_diff = 1.5 * ai_team_tolerance_diff;
        if (ai_team_tolerance_diff > ai_team_tolerance_same) {
            ai_team_tolerance_diff = ai_team_tolerance_same;
        }
    }

    local string tmp;

    dprint("Monster team parameters initialized\n");
    tmp = ftos(ai_team_max_size);
    dprint3("  maximum size : ", tmp, "\n");

    tmp = ftos(100 * ai_team_spread);
    dprint3("  dispersion   : ", tmp, " %\n");

    tmp = ftos(100 * ai_team_tolerance_same);
    dprint3("  tolerance_sm : ", tmp, " %\n");

    tmp = ftos(100 * ai_team_tolerance_diff);
    dprint3("  tolerance_df : ", tmp, " %\n");

    dprint("Creating team database\n");

    ai_team_create_all();
};

//================================================================================

/**
 * This is a disgusting hack that uses the current temporary bodyque_head entity
 * to return multiple properties about the enumerated team for id that dont have
 * a dedicated entity.
 *
 * .armortype  contains the enemy team bitmask
 * .armorvalue contans the team size
 * .team       contains the team id
 * .netname    contains the team name
 * .aiment     contains the team leader entity
 *
 * Use this method and immediately assign any fields you need to locals.
 *
 * The entity is returned because we might want to change this to a dedicated
 * one later. Do not assume what the entity is.
 */
entity(float team_id) AI_TeamProperties = {

    if (team_id == TEAM_ARMY_1) {
        return ai_team_army_1;
    }
    else if (team_id == TEAM_ARMY_2) {
        return ai_team_army_2;
    }
    else if (team_id == TEAM_ARMY_3) {
        return ai_team_army_3;
    }
    else if (team_id == TEAM_KNIGHT_1) {
        return ai_team_knight_1;
    }
    else if (team_id == TEAM_KNIGHT_2) {
        return ai_team_knight_2;
    }
    else if (team_id == TEAM_KNIGHT_3) {
        return ai_team_knight_3;
    }
    else if (team_id == TEAM_UNDEAD_1) {
        return ai_team_undead_1;
    }
    else if (team_id == TEAM_UNDEAD_2) {
        return ai_team_undead_2;
    }
    else if (team_id == TEAM_UNDEAD_3) {
        return ai_team_undead_3;
    }
    else if (team_id == TEAM_OGRE_1) {
        return ai_team_ogre_1;
    }
    else if (team_id == TEAM_OGRE_2) {
        return ai_team_ogre_2;
    }
    else if (team_id == TEAM_OGRE_3) {
        return ai_team_ogre_3;
    }

    // body snatchers... we just use the next body queue entry
    // to return a "non team"
    local entity e;
    e = bodyque_head;

    e.ammo_shells  = 0;
    e.ammo_nails   = 0;
    e.owner        = world;
    e.ai_team_id   = team_id;

    if (team_id == TEAM_NONE) {
        e.netname = "unteamed";
        e.ammo_shells = ai_team_unteamed;
    }
    else if (team_id == TEAM_CLIENT) {
        e.netname    = "client";
    }
    else if (team_id == TEAM_WORLD) {
        e.netname    = "the environment";
    } else {
        e.netname    = "unknown";
    }


    return e;
};

void(float team_id) AI_TeamDump = {
    local entity e_team;
    e_team = AI_TeamProperties(team_id);
    if (e_team.ammo_shells) {
        local string tmp;
        tmp  = ftos(e_team.ammo_shells);
        dprint4(e_team.netname, " : size: ", tmp, ", enemies: ");

        tmp = ftos(e_team.ammo_nails);
        dprint4(tmp, ", leader: ", e_team.owner.netname, "\n");
    }
};

void() dprint_team_stats = {
    // prints info on the teams

    AI_TeamDump(TEAM_ARMY_1);
    AI_TeamDump(TEAM_ARMY_2);
    AI_TeamDump(TEAM_ARMY_3);
    AI_TeamDump(TEAM_KNIGHT_1);
    AI_TeamDump(TEAM_KNIGHT_2);
    AI_TeamDump(TEAM_KNIGHT_3);
    AI_TeamDump(TEAM_UNDEAD_1);
    AI_TeamDump(TEAM_UNDEAD_2);
    AI_TeamDump(TEAM_UNDEAD_3);
    AI_TeamDump(TEAM_OGRE_1);
    AI_TeamDump(TEAM_OGRE_2);
    AI_TeamDump(TEAM_OGRE_3);

    local string tmp;
    tmp = ftos(ai_team_unteamed);
    dprint3("Unteamed monsters : ", tmp, "\n");
};

//================================================================================

void(float team_id) AI_TeamListEnemy = {
    // lists all teams deemed hostile to team_id

    if ((team_id == TEAM_NONE) || (team_id == TEAM_WORLD)) {
        return;
    }

    local float id_bit, mask;
    local string tmp;
    id_bit = 1;

    local entity e_team;
    e_team  = AI_TeamProperties(team_id);
    mask    = e_team.armortype;

    dprint2(e_team.netname, " enemies : ");
    while (id_bit <= TEAM_OGRE_3) {
        if (mask & id_bit) {
            e_team = AI_TeamProperties(id_bit);
            dprint2(e_team.netname, "\n");
        }
        id_bit = id_bit * 2;
    }
};

/**
 * When a monster is killed, figure out the consequences...
 */
void(entity e_victim, entity e_killer) AI_TeamUpdate = {
    if (e_victim.ai_team_id == TEAM_NONE) {
        ai_team_unteamed = ai_team_unteamed - 1;
        return;
    }

    // Decrement the team size
    e_victim.ai_team.ammo_shells = e_victim.ai_team.ammo_shells - 1;

    // If the team leader was killed, that needs handling
    if (e_victim.ai_team.owner == e_victim) {
        dprint6(
            e_victim.ai_team.netname,
            " team leader was killed by ",
            e_killer.netname,
            " [",
            e_killer.ai_team.netname,
            "]\n"
        );
        e_victim.ai_team.owner = world;

        // TODO Regroup?
    }

    // blacklist killers team
    if (e_victim.ai_team != e_killer.ai_team) {
        if (
            e_victim.ai_team_class != e_killer.ai_team_class &&
            random() > ai_team_tolerance_diff
        ) {
            e_victim.ai_team.ammo_nails = e_victim.ai_team.ammo_nails | e_killer.ai_team_id;
        }
        else if (AI_TeamIsEnemy(e_killer, e_victim)) {
            e_victim.ai_team.ammo_nails = e_victim.ai_team.ammo_nails | e_killer.ai_team_id;
        }
        else if (random() > ai_team_tolerance_same) {
            e_victim.ai_team.ammo_nails = e_victim.ai_team.ammo_nails | e_killer.ai_team_id;
        }
    }

};

//================================================================================

/**
 * Takes a base team ID and chooses one of the alternatives, based on the
 * ai_team_spread chance. The returned ID will be one of the three teams
 * in the same group as the base.
 */
float(float base_id) AI_TeamVariation = {
    if (random() < ai_team_spread) {
        local float r;
        r = random();
        if (r < 0.333) {
            return base_id; // corresponds to TEAM_<X>_1
        }
        else if (r < 0.666) {
            return base_id * 2;  // corresponds to TEAM_<X>_2
        }
        else {
            return base_id * 4; // corresponds to TEAM_<X>_3
        }
    }
    return base_id;
};

/**
 * Adds monster (self) to the specified team
 *
 */
void(entity e_team) AI_TeamAdd = {
    e_team.ammo_shells = e_team.ammo_shells + 1; // Increase the size
    self.ai_team_pos   = e_team.ammo_shells;     // assign member ID
    self.ai_team       = e_team;
    self.ai_team_id    = e_team.team;
    self.ai_team_class = e_team.ai_team_class;
};

/**
 * Assigns a monster (self) to a team (or the unteamed team). The team parameter specifies the
 * base team ID and the code will use that or one of the siblings, based on paramters such as
 * size and dispersion.
 */
void(float team_id, float can_be_leader) AI_TeamJoin = {
    // called from monster initialisation code

    if (team_id != TEAM_NONE) {

        // Choose one of the team variations. This is determined by the dispersion settings.
        team_id = AI_TeamVariation(team_id);

        local float tries;
        local entity e_team;

        e_team = AI_TeamProperties(team_id);
        tries  = 0;

        while (tries < 3) {
            if (e_team.ammo_shells < ai_team_max_size) {
                // We can fit in here.
                AI_TeamAdd(e_team);

                // See if we can be leader...
                if (
                    can_be_leader &&
                    (e_team.owner == world || random() > 0.7)
                ) {
                    e_team.owner = self;
                }

                //dprint2("Assigned ", self.netname);
                //dprint2(" to ", e_team.netname);
                //dprint("\n");

                // Job done!
                return;

            } else {
                // Try the next team in the ring
                e_team = e_team.chain;
                tries  = tries + 1;
            }
        }
    } else {
        // Unteamed
        ai_team_unteamed   = ai_team_unteamed + 1;
        self.ai_team_pos   = ai_team_unteamed;
        self.ai_team       = world;
        self.ai_team_id    = TEAM_NONE;
        self.ai_team_class = TEAM_NONE;
    }
};

