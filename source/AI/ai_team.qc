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

    if (observer.teamgroup == TEAM_ARMY_1) {
        return (team_army_1_enemy & observed.teamgroup) != 0;
    }

    if (observer.teamgroup == TEAM_ARMY_2) {
        return (team_army_2_enemy & observed.teamgroup) != 0;
    }

    if (observer.teamgroup == TEAM_ARMY_3) {
        return (team_army_3_enemy & observed.teamgroup) != 0;
    }

    if (observer.teamgroup == TEAM_KNIGHT_1) {
        return (team_knight_1_enemy & observed.teamgroup) != 0;
    }

    if (observer.teamgroup == TEAM_KNIGHT_2) {
        return (team_knight_2_enemy & observed.teamgroup) != 0;
    }

    if (observer.teamgroup == TEAM_KNIGHT_3) {
        return (team_knight_3_enemy & observed.teamgroup) != 0;
    }

    if (observer.teamgroup == TEAM_UNDEAD_1) {
        return (team_undead_1_enemy & observed.teamgroup) != 0;
    }

    if (observer.teamgroup == TEAM_UNDEAD_2) {
        return (team_undead_2_enemy & observed.teamgroup) != 0;
    }

    if (observer.teamgroup == TEAM_UNDEAD_3) {
        return (team_undead_3_enemy & observed.teamgroup) != 0;
    }

    if (observer.teamgroup == TEAM_OGRE_1) {
        return (team_ogre_1_enemy & observed.teamgroup) != 0;
    }

    if (observer.teamgroup == TEAM_OGRE_2) {
        return (team_ogre_2_enemy & observed.teamgroup) != 0;
    }

    if (observer.teamgroup == TEAM_OGRE_3) {
        return (team_ogre_3_enemy & observed.teamgroup) != 0;
    }

    return FALSE;
};

void(entity caller, float radius, float by_sight, float by_sound) team_call_for_backup =
{
    if (!self.teamgroup || self.teamgroup == TEAM_CLIENT) {
        return;
    }

    local string t_name, t_mbmr;

    if (developer & DV_SHOW_TEAM_AI) {
        t_name = name_of_team(caller.teamgroup);
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
                    t_name = name_of_team(head.teamgroup);
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
    bprint ("All teams enemy\n");
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
    bprint ("No teams enemy\n");
};
