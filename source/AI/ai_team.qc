// ai_team.qc
//============================================================================
//   TEAM AI
//============================================================================
/*---public---*/
// $VER: ai_team.qc 1.00 Karlos'99 (23/1/2000)

// public function prototypes
float (entity observer, entity observed) is_enemy_member;
void(entity caller, float radius, float by_sight, float by_sound) team_call_for_backup;
void() set_enemy_all;
void() set_enemy_none;
void() ai_team_init;
void(float team_id, float can_be_leader) ai_team_join;
entity(float team_id) ai_team_properties;
void() dprint_team_stats;
void(entity whosdead, entity whodunnit) ai_team_update;
string(float team_id) ai_team_name;
void(float team_id) list_enemy_teams;

/*---private---*/
//================================================================================

// TODO Consider making the teams actual entities as this would allow reference sharing of state

float (entity observer, entity observed) is_enemy_member = {
    // two members of the same team cannot be enemies (unless zero)

    if (observer.teamgroup == observed.teamgroup) {
        return FALSE;
    }

    // clients are always seen as enemies to monsters (for now)
    if (observed.teamgroup == TEAM_CLIENT) {
        return TRUE;
    }

    return (observer.ai_team.ammo_nails & observed.teamgroup) != 0;

};

void(entity caller, float radius, float by_sight, float by_sound) team_call_for_backup =
{
    if (!self.teamgroup || self.teamgroup == TEAM_CLIENT) {
        return;
    }

    local string t_name, t_mbmr;

    if (developer & DV_SHOW_TEAM_AI) {
        t_name = ai_team_name(caller.teamgroup);
        t_mbmr = ftos(caller.teammember);
        dprint6 (caller.netname, " [",t_name, "/",t_mbmr,"] has called for assistance\n");
    }

    // allow a monster to call for help from any of his team who are within
    // radius.
    // Additionally, enable sight/sound when activating team mates

    local entity head;

    head = findradius(caller.origin, radius);
    while (head) {
        // first of all, head must be a living monster
        if (head.flags & FL_MONSTER && head.deadflag == DEAD_NO && head != caller) {
            // is caller visible or audible to head ?
            if (by_sight & is_visible(caller, head) || by_sound & is_audible(caller, head)) {
                // if head already has an enemy, switch if head cannot see
                // his current enemy....

                if (!head.enemy || !is_visible(head.enemy, head)) {
                    t_name = ai_team_name(head.teamgroup);
                    t_mbmr = ftos(head.teammember);
                    // if head is of same team, come to help
                    if (caller.teamgroup == head.teamgroup) {
                        if (developer & DV_SHOW_TEAM_AI) {
                            dprint6(
                                head.netname,
                                " [",
                                t_name,
                                "/",
                                t_mbmr,
                                ": friend] responding\n"
                            );
                        }
                        head.enemy = caller.enemy;
                        head.think = FoundTarget;
                    }
                    // if head sees caller as an enemy, come to kill...ho..ho..ho
                    else if (is_enemy_member(head, caller)) {
                        if (developer & DV_SHOW_TEAM_AI) {
                            dprint6(
                                head.netname,
                                " [",
                                t_name,
                                "/",
                                t_mbmr,
                                ": enemy] responding\n"
                            );
                        }
                        head.enemy = caller;
                        head.think = FoundTarget;
                    }
                }
            }
        }
        head = head.chain;
    }
};

void() set_enemy_all = {
    team_army_1_enemy   = TEAM_ANY;
    team_army_2_enemy   = TEAM_ANY;
    team_army_3_enemy   = TEAM_ANY;
    team_knight_1_enemy = TEAM_ANY;
    team_knight_2_enemy = TEAM_ANY;
    team_knight_3_enemy = TEAM_ANY;
    team_undead_1_enemy = TEAM_ANY;
    team_undead_2_enemy = TEAM_ANY;
    team_undead_3_enemy = TEAM_ANY;
    team_ogre_1_enemy   = TEAM_ANY;
    team_ogre_2_enemy   = TEAM_ANY;
    team_ogre_3_enemy   = TEAM_ANY;
    bprint("All teams enemy\n");
};

void() set_enemy_none = {
    team_army_1_enemy   = TEAM_CLIENT;
    team_army_2_enemy   = TEAM_CLIENT;
    team_army_3_enemy   = TEAM_CLIENT;
    team_knight_1_enemy = TEAM_CLIENT;
    team_knight_2_enemy = TEAM_CLIENT;
    team_knight_3_enemy = TEAM_CLIENT;
    team_undead_1_enemy = TEAM_CLIENT;
    team_undead_2_enemy = TEAM_CLIENT;
    team_undead_3_enemy = TEAM_CLIENT;
    team_ogre_1_enemy   = TEAM_CLIENT;
    team_ogre_2_enemy   = TEAM_CLIENT;
    team_ogre_3_enemy   = TEAM_CLIENT;
    bprint("No teams enemy\n");
};

// ai_team_manage.qc
//============================================================================
//
//   TEAM AI
//
//       This file contains the functions needed to set up and maintain the
//    monster team database. It handles the assignment of monsters to teams
//    and updates the database about the friend / foe relationship of all
//    the monster teams.
//
//    TODO - Each team should be an entity as this will dramatically simplify
//           handling of state. However, 12 is a considerable number to
//           reserve and depletes the pool of available entities.
//
//           makestatic
//
//============================================================================
/*---public---*/
// $VER: ai_team_manage.qc 1.10 Karlos (05/02/2000)

// public function prototypes


/*---private---*/

// Entities representing teams. These entities are made static after spawn
//
// .team         Team ID
// .netname      Team name
// .owner        Team leader
// .ammo_shells  Team size
// .ammo_nails   Enemy team bitmask


entity ai_team_none;
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

entity(float id, float base, string name, float enemy_mask) ai_team_spawn = {
    local entity e;
    e             = spawn();
    e.classname   = "ai_team";
    e.team        = id;
    e.teamclass   = base;
    e.netname     = name;
    e.owner       = world;
    e.ammo_shells = 0;
    e.ammo_nails  = enemy_mask;

    // Make the entity static as it's just a data container
    //makestatic(e);

    dprint3("Created team ", e.netname, "\n");

    return e;
};


//================================================================================

void() ai_team_create_all = {
    ai_team_none     = ai_team_spawn(TEAM_NONE, TEAM_NONE, "unteamed", TEAM_CLIENT);
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
};

void() ai_team_init = {

    // Clears the monster team database
    // Should be called before any monster initialisation (eg worldspawn)

    // First, read the max team size, diffusion and tolerances
    // If the game is random, increase tolerance to non equivalent teams
    // Note, in a random game, the effect of dispersion is not signifigant
    // since the random monster switching tends to cause a large dispersion

    // team maximum size : 0 - 31
    team_maxmembers      = map_opts & TEAM_MAX_BITS;

    // team dispersion   : 0 - 0.96875
    team_dispersion      = (map_opts & TEAM_DISP_BITS)/1024;

    // equivalent class tolerance : 0 - 0.96875
    same_class_enemy_lim = (map_opts & TEAM_SAME_TOL_BITS)/32768;
    diff_class_enemy_lim = (map_opts & TEAM_DIFF_TOL_BITS)/1048576;

    if (randomgame) {
        // Inc non-equiv tolerance 50% in random game, limit to equiv tolerance
        diff_class_enemy_lim = 1.5 * diff_class_enemy_lim;
        if (diff_class_enemy_lim > same_class_enemy_lim) {
            diff_class_enemy_lim = same_class_enemy_lim;
        }
    }

    local string tmp;

    dprint("Monster team parameters initialized\n");
    tmp = ftos(team_maxmembers);
    dprint3("  maximum size : ", tmp, "\n");

    tmp = ftos(100 * team_dispersion);
    dprint3("  dispersion   : ", tmp, " %\n");

    tmp = ftos(100 * same_class_enemy_lim);
    dprint3("  tolerance_sm : ", tmp, " %\n");

    tmp = ftos(100 * diff_class_enemy_lim);
    dprint3("  tolerance_df : ", tmp, " %\n");


    dprint("Resetting team database\n");

    ai_team_create_all();

    // TODO - this is all going away
    team_none_size     = 0;
    team_army_1_size   = 0;
    team_army_2_size   = 0;
    team_army_3_size   = 0;
    team_army_1_enemy  = TEAM_CLIENT;
    team_army_2_enemy  = TEAM_CLIENT;
    team_army_3_enemy  = TEAM_CLIENT;
    team_army_1_leader = world;
    team_army_2_leader = world;
    team_army_3_leader = world;

    team_knight_1_size   = 0;
    team_knight_2_size   = 0;
    team_knight_3_size   = 0;
    team_knight_1_enemy  = TEAM_CLIENT;
    team_knight_2_enemy  = TEAM_CLIENT;
    team_knight_3_enemy  = TEAM_CLIENT;
    team_knight_1_leader = world;
    team_knight_2_leader = world;
    team_knight_3_leader = world;

    team_undead_1_size   = 0;
    team_undead_2_size   = 0;
    team_undead_3_size   = 0;
    team_undead_1_enemy  = TEAM_CLIENT;
    team_undead_2_enemy  = TEAM_CLIENT;
    team_undead_3_enemy  = TEAM_CLIENT;
    team_undead_1_leader = world;
    team_undead_2_leader = world;
    team_undead_3_leader = world;

    team_ogre_1_size     = 0;
    team_ogre_2_size     = 0;
    team_ogre_3_size     = 0;
    team_ogre_1_enemy    = TEAM_CLIENT;
    team_ogre_2_enemy    = TEAM_CLIENT;
    team_ogre_3_enemy    = TEAM_CLIENT;
    team_ogre_1_leader   = world;
    team_ogre_2_leader   = world;
    team_ogre_3_leader   = world;

};

//================================================================================

/**
 * This is a disgusting hack that uses the current temporary bodyque_head entity
 * to return multiple properties about the enumerated team.
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
entity(float team_id) ai_team_properties = {

    if (team_id == TEAM_NONE) {
        return ai_team_none;
    }
    else if (team_id == TEAM_ARMY_1) {
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

    if (team_id == TEAM_CLIENT) {
        e.team       = team_id;
        e.netname    = "client";
    }
    else if (team_id == TEAM_WORLD) {
        e.team       = team_id;
        e.netname    = "the environment";
    } else {
        e.team         = -1;
        e.netname      = "unknown";
    }

    e.ammo_shells  = 0;
    e.ammo_nails   = 0;
    e.owner        = world;

    return e;
};

// TODO this can go away
string(float team_id) ai_team_name = {
    // attatch meaningful names to teams

    if (team_id == TEAM_NONE) {
        return "unteamed";
    }
    else if (team_id == TEAM_ARMY_1) {
        return "army_1";
    }
    else if (team_id == TEAM_ARMY_2) {
        return "army_2";
    }
    else if (team_id == TEAM_ARMY_3) {
        return "army_3";
    }
    else if (team_id == TEAM_KNIGHT_1) {
        return "knight_1";
    }
    else if (team_id == TEAM_KNIGHT_2) {
        return "knight_2";
    }
    else if (team_id == TEAM_KNIGHT_3) {
        return "knight_3";
    }
    else if (team_id == TEAM_UNDEAD_1) {
        return "undead_1";
    }
    else if (team_id == TEAM_UNDEAD_2) {
        return "undead_2";
    }
    else if (team_id == TEAM_UNDEAD_3) {
        return "undead_3";
    }
    else if (team_id == TEAM_OGRE_1) {
        return "ogre_1";
    }
    else if (team_id == TEAM_OGRE_2) {
        return "ogre_2";
    }
    else if (team_id == TEAM_OGRE_3) {
        return "ogre_3";
    }
    else if (team_id == TEAM_CLIENT) {
        return "client";
    }
    else if (team_id == TEAM_WORLD) {
        return "the environment";
    }

    return "unknown team id";
};


void(float team_id) dprint_team = {
    local entity e_team;
    e_team = ai_team_properties(team_id);
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

    dprint_team(TEAM_ARMY_1);
    dprint_team(TEAM_ARMY_2);
    dprint_team(TEAM_ARMY_3);
    dprint_team(TEAM_KNIGHT_1);
    dprint_team(TEAM_KNIGHT_2);
    dprint_team(TEAM_KNIGHT_3);
    dprint_team(TEAM_UNDEAD_1);
    dprint_team(TEAM_UNDEAD_2);
    dprint_team(TEAM_UNDEAD_3);
    dprint_team(TEAM_OGRE_1);
    dprint_team(TEAM_OGRE_2);
    dprint_team(TEAM_OGRE_3);

    local string tmp;
    tmp = ftos(team_none_size);
    dprint3("Unteamed monsters : ", tmp, "\n");
};

//================================================================================

void(float team_id) list_enemy_teams = {
    // lists all teams deemed hostile to team_id

    if ((team_id == TEAM_NONE) || (team_id == TEAM_WORLD)) {
        return;
    }

    local float id_bit;
    local string tmp;
    id_bit = 1;

    local entity e_team;
    e_team  = ai_team_properties(team_id);

    dprint2(e_team.netname, " enemies : ");
    while (id_bit <= TEAM_OGRE_3) {
        if (e_team.armortype & id_bit) {
            tmp = ai_team_name(id_bit);
            dprint2(tmp, "\n");
        }
        id_bit = id_bit * 2;
    }

};

/**
 * When a monster is killed, figure out the consequences...
 */
void(entity e_victim, entity e_killer) ai_team_update = {
    if (e_victim.ai_team == ai_team_none) {
        ai_team_none.ammo_shells = ai_team_none.ammo_shells - 1;
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
    }

    // blacklist killers team
    if (e_victim.ai_team != e_killer.ai_team) {
        if (
            e_victim.teamclass != e_killer.teamclass &&
            random() > diff_class_enemy_lim
        ) {
            e_victim.ai_team.ammo_nails = e_victim.ai_team.ammo_nails | e_killer.teamgroup;
        }
        else if (is_enemy_member(e_killer, e_victim)) {
            e_victim.ai_team.ammo_nails = e_victim.ai_team.ammo_nails | e_killer.teamgroup;
        }
        else if (random() > same_class_enemy_lim) {
            e_victim.ai_team.ammo_nails = e_victim.ai_team.ammo_nails | e_killer.teamgroup;
        }
    }

};

//================================================================================

/**
 * Takes a base team ID and chooses one of the alternatives, based on the
 * team_dispersion chance. The returned ID will be one of the three teams
 * in the same group as the base.
 */
float(float base_id) ai_team_vary = {
    if (random() < team_dispersion) {
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

void(entity e_team) ai_team_add = {
    e_team.ammo_shells = e_team.ammo_shells + 1;
    self.teammember    = e_team.ammo_shells;
    self.ai_team       = e_team;
    self.teamgroup     = e_team.team;
    self.teamclass     = e_team.teamclass;
};

/**
 * Assigns a monster to a team (or the unteamed team)
 */
void(float team_id, float can_be_leader) ai_team_join = {
    // called from monster initialisation code

    if (team_id != TEAM_NONE) {

        // Choose one of the team variations. This is determined by the dispersion settings.
        team_id = ai_team_vary(team_id);

        local float tries;
        local entity e_team;

        e_team = ai_team_properties(team_id);
        tries  = 0;

        while (tries < 3) {
            if (e_team.ammo_shells < team_maxmembers) {
                // We can fit in here.
                ai_team_add(e_team);

                // See if we can be leader...
                if (
                    can_be_leader &&
                    (e_team.owner == world || random() > 0.7)
                ) {
                    e_team.owner = self;
                }

                dprint2("Assigned ", self.netname);
                dprint2(" to ", e_team.netname);
                dprint("\n");


                // Job done!
                return;

            } else {
                // Try the next team in the ring
                e_team = e_team.chain;
                tries  = tries + 1;
            }
        }
    }

    // Add to the unteamed team
    ai_team_add(ai_team_none);
};

