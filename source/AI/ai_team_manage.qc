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
//============================================================================
/*---public---*/
// $VER: ai_team_manage.qc 1.10 Karlos (05/02/2000)

// public function prototypes

void() ai_reset_teams;
void(float can_be_leader) ai_join_team;

void() dprint_team_stats;

void(entity whosdead, entity whodunnit) ai_update_teams;

string(float team_id) ai_team_name;

void(float team_id) list_enemy_teams;

/*---private---*/

//================================================================================


void() ai_reset_teams = {
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


    dprint ("Monster team parameters initialized\n");

    dprint ("  maximum size: ");
    dprint (ftos(team_maxmembers));
    dprint ("\n");

    dprint ("  dispersion  : ");
    dprint (ftos(100*team_dispersion));
    dprint (" %\n");

    dprint ("  tolerance_sm: ");
    dprint (ftos(100*same_class_enemy_lim));
    dprint (" %\n");

    dprint ("  tolerance_df: ");
    dprint (ftos(100*diff_class_enemy_lim));
    dprint (" %\n");

    team_none_size   = 0;

    dprint ("Resetting team database\n");

    team_army_1_size = 0;
    team_army_2_size = 0;
    team_army_3_size = 0;
    team_army_1_enemy = TEAM_CLIENT;
    team_army_2_enemy = TEAM_CLIENT;
    team_army_3_enemy = TEAM_CLIENT;
    team_army_1_leader = world;
    team_army_2_leader = world;
    team_army_3_leader = world;

    team_knight_1_size = 0;
    team_knight_2_size = 0;
    team_knight_3_size = 0;
    team_knight_1_enemy = TEAM_CLIENT;
    team_knight_2_enemy = TEAM_CLIENT;
    team_knight_3_enemy = TEAM_CLIENT;
    team_knight_1_leader = world;
    team_knight_2_leader = world;
    team_knight_3_leader = world;

    team_undead_1_size = 0;
    team_undead_2_size = 0;
    team_undead_3_size = 0;
    team_undead_1_enemy = TEAM_CLIENT;
    team_undead_2_enemy = TEAM_CLIENT;
    team_undead_3_enemy = TEAM_CLIENT;
    team_undead_1_leader = world;
    team_undead_2_leader = world;
    team_undead_3_leader = world;

    team_ogre_1_size = 0;
    team_ogre_2_size = 0;
    team_ogre_3_size = 0;
    team_ogre_1_enemy = TEAM_CLIENT;
    team_ogre_2_enemy = TEAM_CLIENT;
    team_ogre_3_enemy = TEAM_CLIENT;
    team_ogre_1_leader = world;
    team_ogre_2_leader = world;
    team_ogre_3_leader = world;

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

    local entity e;
    e = bodyque_head;

    if (team_id == TEAM_NONE) {
        e.team       = team_id;
        e.armortype  = 0;
        e.armorvalue = team_none_size;
        e.netname    = "unteamed";
        e.aiment     = world;
    }
    else if (team_id == TEAM_ARMY_1) {
        e.team       = team_id;
        e.armortype  = team_army_1_enemy;
        e.armorvalue = team_army_1_size;
        e.netname    = "army_1";
        e.aiment     = team_army_1_leader;
    }
    else if (team_id == TEAM_ARMY_2) {
        e.team       = team_id;
        e.armortype  = team_army_2_enemy;
        e.armorvalue = team_army_2_size;
        e.netname    = "army_2";
        e.aiment     = team_army_2_leader;
    }
    else if (team_id == TEAM_ARMY_3) {
        e.team       = team_id;
        e.armortype  = team_army_3_enemy;
        e.armorvalue = team_army_3_size;
        e.netname    = "army_3";
        e.aiment     = team_army_3_leader;
    }
    else if (team_id == TEAM_KNIGHT_1) {
        e.team       = team_id;
        e.armortype  = team_knight_1_enemy;
        e.armorvalue = team_knight_1_size;
        e.netname    = "knight_1";
        e.aiment     = team_knight_1_leader;
    }
    else if (team_id == TEAM_KNIGHT_2) {
        e.team       = team_id;
        e.armortype  = team_knight_2_enemy;
        e.armorvalue = team_knight_2_size;
        e.netname    = "knight_2";
        e.aiment     = team_knight_2_leader;
    }
    else if (team_id == TEAM_KNIGHT_3) {
        e.team       = team_id;
        e.armortype  = team_knight_3_enemy;
        e.armorvalue = team_knight_3_size;
        e.netname    = "knight_3";
        e.aiment     = team_knight_3_leader;
    }
    else if (team_id == TEAM_UNDEAD_1) {
        e.team       = team_id;
        e.armortype  = team_undead_1_enemy;
        e.armorvalue = team_undead_1_size;
        e.netname    = "undead_1";
        e.aiment     = team_undead_1_leader;
    }
    else if (team_id == TEAM_UNDEAD_2) {
        e.team       = team_id;
        e.armortype  = team_undead_2_enemy;
        e.armorvalue = team_undead_2_size;
        e.netname    = "undead_2";
        e.aiment     = team_undead_2_leader;
    }
    else if (team_id == TEAM_UNDEAD_3) {
        e.team       = team_id;
        e.armortype  = team_undead_3_enemy;
        e.armorvalue = team_undead_3_size;
        e.netname    = "undead_3";
        e.aiment     = team_undead_3_leader;
    }
    else if (team_id == TEAM_OGRE_1) {
        e.team       = team_id;
        e.armortype  = team_ogre_1_enemy;
        e.armorvalue = team_ogre_1_size;
        e.netname    = "ogre_1";
        e.aiment     = team_ogre_1_leader;
    }
    else if (team_id == TEAM_OGRE_2) {
        e.team       = team_id;
        e.armortype  = team_ogre_2_enemy;
        e.armorvalue = team_ogre_2_size;
        e.netname    = "ogre_2";
        e.aiment     = team_ogre_2_leader;
    }
    else if (team_id == TEAM_OGRE_3) {
        e.team       = team_id;
        e.armortype  = team_ogre_3_enemy;
        e.armorvalue = team_ogre_3_size;
        e.netname    = "ogre_3";
        e.aiment     = team_ogre_3_leader;
    }
    else if (team_id == TEAM_CLIENT) {
        e.team       = team_id;
        e.armortype  = 0;
        e.armorvalue = 0;
        e.netname    = "client";
        e.aiment     = world;
    }
    else if (team_id == TEAM_WORLD) {
        e.team       = team_id;
        e.armortype  = 0;
        e.armorvalue = 0;
        e.netname    = "the environment";
        e.aiment     = world;
    } else {
        e.team       = -1;
        e.armortype  = 0;
        e.armorvalue = 0;
        e.netname    = "unknown";
        e.aiment     = world;
    }

    return e;
};

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
    local entity eteam;
    eteam = ai_team_properties(team_id);
    if (eteam.armorvalue) {
        local string t_size, t_enemy;
        t_size  = ftos(eteam.armorvalue);
        t_enemy = ftos(eteam.armortype);
        dprint4(eteam.netname, " : ", t_size, ", ");
        dprint4(t_enemy, ", ", eteam.aiment.netname, "\n");
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

    dprint3("Unteamed monsters : ", ftos(team_none_size), "\n");
};

//================================================================================

void(float team_id) list_enemy_teams = {
    // lists all teams deemed hostile to team_id

    if ((team_id == TEAM_NONE) || (team_id == TEAM_WORLD)) {
        return;
    }

    local float id_bit;
    id_bit = 1;

    local entity eteam;
    eteam  = ai_team_properties(team_id);

    dprint2(eteam.netname, " enemies : ");
    while (id_bit <= TEAM_OGRE_3) {
        if (eteam.armortype & id_bit) {
            dprint2(ai_team_name(id_bit), "\n");
        }
        id_bit = id_bit * 2;
    }

};


void(entity whosdead, entity whodunnit) ai_update_teams =
{
    // called when a monster is killed. We decrease the size of his team, figure
    // out which team was responsible for his death and flag them as an enemy team
    // with te exception of 'friendly' fire ;)

    // rules

    // 1. if attacker is of different class to targ, targs team will flag
    //    attackers team as an enemy if chance > diff_class_enemy_lim

    // 2. if attacker is of same class to targ, then only set as enemy if
    //    attacker had targ flagged as enemy. Otherwise, just use chance >
    //    same_enemy_class_lim probability of enemy flagging

    // 3. if attacker is from same team as targ, do not set as enemy...

    local string t_name;
    t_name = ai_team_name(whodunnit.teamgroup);

    if (whosdead.teamgroup == TEAM_NONE)
    {
        // noone even cries....
        team_none_size = team_none_size - 1;
        return;
    }

    else if (whosdead.teamgroup == TEAM_ARMY_1)
    {
        team_army_1_size = team_army_1_size - 1;
        if (team_army_1_leader == self)
        {
            if (developer & DV_SHOW_TEAM_AI)
            {
                dprint5 ("army 1 : team leader killed by ",
                         whodunnit.netname,
                         " [", t_name,"]\n");
            }

            team_army_1_leader = world;
        }
        // blacklist whodunnit's team
        if (whodunnit.teamgroup != TEAM_ARMY_1)
        {
            // apply rules (note use of multiple 'if' to speed up descision)
            if (whodunnit.teamclass != whosdead.teamclass && random() > diff_class_enemy_lim)
                team_army_1_enemy = team_army_1_enemy | whodunnit.teamgroup;
            else if (is_enemy_member(whodunnit, whosdead))
                team_army_1_enemy = team_army_1_enemy | whodunnit.teamgroup;
            else if (random() > same_class_enemy_lim)
                team_army_1_enemy = team_army_1_enemy | whodunnit.teamgroup;
        }
    }

    else if (whosdead.teamgroup == TEAM_ARMY_2)
    {
        team_army_2_size = team_army_2_size - 1;
        if (team_army_2_leader == self)
        {
            if (developer & DV_SHOW_TEAM_AI)
            {
                dprint5 ("army 2 : team leader killed by ",
                         whodunnit.netname,
                         " [", t_name,"]\n");
            }

            team_army_2_leader = world;
        }
        // blacklist whodunnit's team
        if (whodunnit.teamgroup != TEAM_ARMY_2)
        {
            // apply rules (note use of multiple 'if' to speed up descision)
            if (whodunnit.teamclass != whosdead.teamclass && random() > diff_class_enemy_lim)
                team_army_2_enemy = team_army_2_enemy | whodunnit.teamgroup;
            else if (is_enemy_member(whodunnit, whosdead))
                team_army_2_enemy = team_army_2_enemy | whodunnit.teamgroup;
            else if (random() > same_class_enemy_lim)
                team_army_2_enemy = team_army_2_enemy | whodunnit.teamgroup;
        }
    }

    else if (whosdead.teamgroup == TEAM_ARMY_3)
    {
        team_army_3_size = team_army_3_size - 1;
        if (team_army_3_leader == self)
        {
            if (developer & DV_SHOW_TEAM_AI)
            {
                dprint5 ("army 3 : team leader killed by ",
                         whodunnit.netname,
                         " [", t_name,"]\n");
            }

            team_army_3_leader = world;
        }
        // blacklist whodunnit's team
        if (whodunnit.teamgroup != TEAM_ARMY_3)
        {
            // apply rules (note use of multiple 'if' to speed up descision)
            if (whodunnit.teamclass != whosdead.teamclass && random() > diff_class_enemy_lim)
                team_army_3_enemy = team_army_3_enemy | whodunnit.teamgroup;
            else if (is_enemy_member(whodunnit, whosdead))
                team_army_3_enemy = team_army_3_enemy | whodunnit.teamgroup;
            else if (random() > same_class_enemy_lim)
                team_army_3_enemy = team_army_3_enemy | whodunnit.teamgroup;
        }
    }

    else if (whosdead.teamgroup == TEAM_KNIGHT_1)
    {
        team_knight_1_size = team_knight_1_size - 1;
        if (team_knight_1_leader == self)
        {
            if (developer & DV_SHOW_TEAM_AI)
            {
                dprint5 ("knight 1 : team leader killed by ",
                         whodunnit.netname,
                         " [", t_name,"]\n");
            }

            team_knight_1_leader = world;
        }
        // blacklist whodunnit's team
        if (whodunnit.teamgroup != TEAM_KNIGHT_1)
        {
            // apply rules (note use of multiple 'if' to speed up descision)
            if (whodunnit.teamclass != whosdead.teamclass && random() > diff_class_enemy_lim)
                team_knight_1_enemy = team_knight_1_enemy | whodunnit.teamgroup;
            else if (is_enemy_member(whodunnit, whosdead))
                team_knight_1_enemy = team_knight_1_enemy | whodunnit.teamgroup;
            else if (random() > same_class_enemy_lim)
                team_knight_1_enemy = team_knight_1_enemy | whodunnit.teamgroup;
        }
    }

    else if (whosdead.teamgroup == TEAM_KNIGHT_2)
    {
        team_knight_2_size = team_knight_2_size - 1;
        if (team_knight_2_leader == self)
        {
            if (developer & DV_SHOW_TEAM_AI)
            {
                dprint5 ("knight 2 : team leader killed by ",
                         whodunnit.netname,
                         " [", t_name,"]\n");
            }

            team_knight_2_leader = world;
        }
        // blacklist whodunnit's team
        if (whodunnit.teamgroup != TEAM_KNIGHT_2)
        {
           // apply rules (note use of multiple 'if' to speed up descision)
            if (whodunnit.teamclass != whosdead.teamclass && random() > diff_class_enemy_lim)
                team_knight_2_enemy = team_knight_2_enemy | whodunnit.teamgroup;
            else if (is_enemy_member(whodunnit, whosdead))
                team_knight_2_enemy = team_knight_2_enemy | whodunnit.teamgroup;
            else if (random() > same_class_enemy_lim)
                team_knight_2_enemy = team_knight_2_enemy | whodunnit.teamgroup;
        }
    }

    else if (whosdead.teamgroup == TEAM_KNIGHT_3)
    {
        team_knight_3_size = team_knight_3_size - 1;
        if (team_knight_3_leader == self)
        {
            if (developer & DV_SHOW_TEAM_AI)
            {
                dprint5 ("knight 3 : team leader killed by ",
                         whodunnit.netname,
                         " [", t_name,"]\n");
            }

            team_knight_3_leader = world;
        }
        // blacklist whodunnit's team
        if (whodunnit.teamgroup != TEAM_KNIGHT_3)
        {
           // apply rules (note use of multiple 'if' to speed up descision)
            if (whodunnit.teamclass != whosdead.teamclass && random() > diff_class_enemy_lim)
                team_knight_3_enemy = team_knight_3_enemy | whodunnit.teamgroup;
            else if (is_enemy_member(whodunnit, whosdead))
                team_knight_3_enemy = team_knight_3_enemy | whodunnit.teamgroup;
            else if (random() > same_class_enemy_lim)
                team_knight_3_enemy = team_knight_3_enemy | whodunnit.teamgroup;
        }
    }

    else if (whosdead.teamgroup == TEAM_UNDEAD_1)
    {
        team_undead_1_size = team_undead_1_size - 1;
        if (team_undead_1_leader == self)
        {
            if (developer & DV_SHOW_TEAM_AI)
            {
                dprint5 ("undead 1 : team leader killed by ",
                         whodunnit.netname,
                         " [", t_name,"]\n");
            }

            team_undead_1_leader = world;
        }
        // blacklist whodunnit's team
        if (whodunnit.teamgroup != TEAM_UNDEAD_1)
        {
           // apply rules (note use of multiple 'if' to speed up descision)
            if (whodunnit.teamclass != whosdead.teamclass && random() > diff_class_enemy_lim)
                team_undead_1_enemy = team_undead_1_enemy | whodunnit.teamgroup;
            else if (is_enemy_member(whodunnit, whosdead))
                team_undead_1_enemy = team_undead_1_enemy | whodunnit.teamgroup;
            else if (random() > same_class_enemy_lim)
                team_undead_1_enemy = team_undead_1_enemy | whodunnit.teamgroup;
        }
    }

    else if (whosdead.teamgroup == TEAM_UNDEAD_2)
    {
        team_undead_2_size = team_undead_2_size - 1;
        if (team_undead_2_leader == self)
        {
            if (developer & DV_SHOW_TEAM_AI)
            {
                dprint5 ("undead 2 : team leader killed by ",
                         whodunnit.netname,
                         " [", t_name,"]\n");
            }

            team_undead_2_leader = world;
        }
        // blacklist whodunnit's team
        if (whodunnit.teamgroup != TEAM_UNDEAD_2)
        {
           // apply rules (note use of multiple 'if' to speed up descision)
            if (whodunnit.teamclass != whosdead.teamclass && random() > diff_class_enemy_lim)
                team_undead_2_enemy = team_undead_2_enemy | whodunnit.teamgroup;
            else if (is_enemy_member(whodunnit, whosdead))
                team_undead_2_enemy = team_undead_2_enemy | whodunnit.teamgroup;
            else if (random() > same_class_enemy_lim)
                team_undead_2_enemy = team_undead_2_enemy | whodunnit.teamgroup;
        }
    }

    else if (whosdead.teamgroup == TEAM_UNDEAD_3)
    {
        team_undead_3_size = team_undead_3_size - 1;
        if (team_undead_3_leader == self)
        {
            if (developer & DV_SHOW_TEAM_AI)
            {
                dprint5 ("undead 3 : team leader killed by ",
                        whodunnit.netname,
                        " [", t_name,"]\n");
            }
            team_undead_3_leader = world;
        }
        // blacklist whodunnit's team
        if (whodunnit.teamgroup != TEAM_UNDEAD_3)
        {
           // apply rules (note use of multiple 'if' to speed up descision)
            if (whodunnit.teamclass != whosdead.teamclass && random() > diff_class_enemy_lim)
                team_undead_3_enemy = team_undead_3_enemy | whodunnit.teamgroup;
            else if (is_enemy_member(whodunnit, whosdead))
                team_undead_3_enemy = team_undead_3_enemy | whodunnit.teamgroup;
            else if (random() > same_class_enemy_lim)
                team_undead_3_enemy = team_undead_3_enemy | whodunnit.teamgroup;
        }
    }

    else if (whosdead.teamgroup == TEAM_OGRE_1)
    {
        team_ogre_1_size = team_ogre_1_size - 1;
        if (team_ogre_1_leader == self)
        {
            if (developer & DV_SHOW_TEAM_AI)
            {
                dprint5 ("ogre 1 : team leader killed by ",
                         whodunnit.netname,
                         " [", t_name,"]\n");
            }
            team_ogre_1_leader = world;
        }
        // blacklist whodunnit's team
        if (whodunnit.teamgroup != TEAM_OGRE_1)
        {
           // apply rules (note use of multiple 'if' to speed up descision)
            if (whodunnit.teamclass != whosdead.teamclass && random() > diff_class_enemy_lim)
                team_ogre_1_enemy = team_ogre_1_enemy | whodunnit.teamgroup;
            else if (is_enemy_member(whodunnit, whosdead))
                team_ogre_1_enemy = team_ogre_1_enemy | whodunnit.teamgroup;
            else if (random() > same_class_enemy_lim)
                team_ogre_1_enemy = team_ogre_1_enemy | whodunnit.teamgroup;
        }
    }

    else if (whosdead.teamgroup == TEAM_OGRE_2)
    {
        team_ogre_2_size = team_ogre_2_size - 1;
        if (team_ogre_2_leader == self)
        {
            if (developer & DV_SHOW_TEAM_AI)
            {
                dprint5 ("ogre 2 : team leader killed by ",
                         whodunnit.netname,
                         " [", t_name,"]\n");
            }
            team_ogre_2_leader = world;
        }
        // blacklist whodunnit's team
        if (whodunnit.teamgroup != TEAM_OGRE_2)
        {
           // apply rules (note use of multiple 'if' to speed up descision)
            if (whodunnit.teamclass != whosdead.teamclass && random() > diff_class_enemy_lim)
                team_ogre_2_enemy = team_ogre_2_enemy | whodunnit.teamgroup;
            else if (is_enemy_member(whodunnit, whosdead))
                team_ogre_2_enemy = team_ogre_2_enemy | whodunnit.teamgroup;
            else if (random() > same_class_enemy_lim)
                team_ogre_2_enemy = team_ogre_2_enemy | whodunnit.teamgroup;
        }
    }

    else if (whosdead.teamgroup == TEAM_OGRE_3)
    {
        team_ogre_3_size = team_ogre_3_size - 1;
        if (team_ogre_3_leader == self)
        {
            if (developer & DV_SHOW_TEAM_AI)
            {
                dprint5 ("ogre 3 : team leader killed by ",
                         whodunnit.netname,
                         " [", t_name,"]\n");
            }
            team_ogre_3_leader = world;
        }
        // blacklist whodunnit's team
        if (whodunnit.teamgroup != TEAM_OGRE_3)
        {
           // apply rules (note use of multiple 'if' to speed up descision)
            if (whodunnit.teamclass != whosdead.teamclass && random() > diff_class_enemy_lim)
                team_ogre_3_enemy = team_ogre_3_enemy | whodunnit.teamgroup;
            else if (is_enemy_member(whodunnit, whosdead))
                team_ogre_3_enemy = team_ogre_3_enemy | whodunnit.teamgroup;
            else if (random() > same_class_enemy_lim)
                team_ogre_3_enemy = team_ogre_3_enemy | whodunnit.teamgroup;
        }
    }

};

//================================================================================

void(float can_be_leader) ai_join_team =
{
    // called from monster initialisation code

    local float team_class, r, team_index;
    local float trygroup, numtries, joined_ok;


    // fisrt we ascertain which team class the monster is suited to

    if (self.classname == "monster_army" ||
        self.classname == "monster_enforcer" ||
        self.classname == "monster_dog")
        team_class = TEAM_ARMY_1;

    else if (self.classname == "monster_knight" ||
        self.classname == "monster_hell_knight")
        team_class = TEAM_KNIGHT_1;

    else if (self.classname == "monster_fish" ||
        self.classname == "monster_zombie" ||
        self.classname == "monster_wizard")
        team_class = TEAM_UNDEAD_1;

    else if (self.classname == "monster_ogre")
        team_class = TEAM_OGRE_1;

    else
    {
        // no team class
        team_none_size = team_none_size + 1;
        self.teamgroup = TEAM_NONE;
        return;
    }

    // now we randomly pick one of the three suitable teams

    // This should allow for reasonably well spread teams

    // Each team can have a maximum of 12 members
    // If a monster can't fit into the selected team, the others are
    // tried cyclically until a vacancy is found.
    // If all are full, the monster is assigned to TEAM_NONE

    // Each time a monster joins a team, he is checked for leadership
    // suitability

    // If suitable, he is assigned the team leader there isn't one
    // already. If there is, a random() > 0.7 chance is used that he
    // will usurp the existing team leader. This should help prevent
    // all team leaders being too close to the start of the map...

    if (random() < team_dispersion)
    {
        r = random();
        if (r < 0.33)
            team_index = 1;    // corresponds to TEAM_<X>_1
        else if (r < 0.66)
            team_index = 2;    // corresponds to TEAM_<X>_2
        else
            team_index = 4;    // corresponds to TEAM_<X>_3
    }
    else
        team_index = 1;

    numtries = 0;
    joined_ok = FALSE;
    trygroup = team_class * team_index;

    self.teamclass = team_class;

//----------------------------------------------------------------------
    if (team_class == TEAM_ARMY_1)
    {
        while (!joined_ok)
        {
            if (trygroup == TEAM_ARMY_1 && numtries < 3)
            {
                if (team_army_1_size < team_maxmembers)
                {
                    if (can_be_leader &&
                        (team_army_1_leader == world ||
                         random() > 0.7))
                    team_army_1_leader = self;
                    self.teamgroup = TEAM_ARMY_1;
                    team_army_1_size = team_army_1_size + 1;
                    self.teammember = team_army_1_size;
                    joined_ok = TRUE;
                }
                else
                {
                    numtries = numtries + 1;
                    trygroup = TEAM_ARMY_2;
                }
            }

            if (trygroup == TEAM_ARMY_2 && numtries < 3)
            {
                if (team_army_2_size < team_maxmembers)
                {
                    if (can_be_leader &&
                        (team_army_2_leader == world ||
                         random() > 0.7))
                        team_army_2_leader = self;
                    self.teamgroup = TEAM_ARMY_2;
                    team_army_2_size = team_army_2_size + 1;
                    self.teammember = team_army_2_size;
                    joined_ok = TRUE;
                }
                else
                {
                    numtries = numtries + 1;
                    trygroup = TEAM_ARMY_3;
                }
            }

            if (trygroup == TEAM_ARMY_3 && numtries < 3)
            {
                if (team_army_3_size < team_maxmembers)
                {
                    if (can_be_leader &&
                        (team_army_3_leader == world ||
                         random() > 0.7))
                        team_army_3_leader = self;
                    self.teamgroup = TEAM_ARMY_3;
                    team_army_3_size = team_army_3_size + 1;
                    self.teammember = team_army_3_size;
                    joined_ok = TRUE;
                }
                else
                {
                    numtries = numtries + 1;
                    trygroup = TEAM_ARMY_1;
                }
            }

            if (numtries >= 3)
            {
                if (developer & DV_SHOW_TEAM_AI)
                    dprint2 (self.netname," could not be teamed\n");
                self.teamgroup = TEAM_NONE;
                joined_ok = TRUE;
                team_none_size = team_none_size+1;
            }
        }
    }
    //----------------------------------------------------------------------------
    else if (team_class == TEAM_KNIGHT_1)
    {
        while (!joined_ok)
        {
            if (trygroup == TEAM_KNIGHT_1 && numtries < 3)
            {
                if (team_knight_1_size < team_maxmembers)
                {
                    if (can_be_leader &&
                        (team_knight_1_leader == world ||
                         random() > 0.7))
                    team_knight_1_leader = self;
                    self.teamgroup = TEAM_KNIGHT_1;
                    team_knight_1_size = team_knight_1_size + 1;
                    self.teammember = team_knight_1_size;
                    joined_ok = TRUE;
                }
                else
                {
                    numtries = numtries + 1;
                    trygroup = TEAM_KNIGHT_2;
                }
            }

            if (trygroup == TEAM_KNIGHT_2 && numtries < 3)
            {
                if (team_knight_2_size < team_maxmembers)
                {
                    if (can_be_leader &&
                        (team_knight_2_leader == world ||
                         random() > 0.7))
                        team_knight_2_leader = self;
                    self.teamgroup = TEAM_KNIGHT_2;
                    team_knight_2_size = team_knight_2_size + 1;
                    self.teammember = team_knight_2_size;
                    joined_ok = TRUE;
                }
                else
                {
                    numtries = numtries + 1;
                    trygroup = TEAM_KNIGHT_3;
                }
            }

            if (trygroup == TEAM_KNIGHT_3 && numtries < 3)
            {
                if (team_knight_3_size < team_maxmembers)
                {
                    if (can_be_leader &&
                        (team_knight_3_leader == world ||
                         random() > 0.7))
                        team_knight_3_leader = self;
                    self.teamgroup = TEAM_KNIGHT_3;
                    team_knight_3_size = team_knight_3_size + 1;
                    self.teammember = team_knight_3_size;
                    joined_ok = TRUE;
                }
                else
                {
                    numtries = numtries + 1;
                    trygroup = TEAM_KNIGHT_1;
                }
            }

            if (numtries >= 3)
            {
                if (developer & DV_SHOW_TEAM_AI)
                    dprint2 (self.netname," could not be teamed\n");
                self.teamgroup = TEAM_NONE;
                joined_ok = TRUE;
                team_none_size = team_none_size+1;
            }
        }
    }
    //----------------------------------------------------------------------------
    else if (team_class == TEAM_UNDEAD_1)
    {
        while (!joined_ok)
        {
            if (trygroup == TEAM_UNDEAD_1 && numtries < 3)
            {
                if (team_undead_1_size < team_maxmembers)
                {
                    if (can_be_leader &&
                        (team_undead_1_leader == world ||
                         random() > 0.7))
                    team_undead_1_leader = self;
                    self.teamgroup = TEAM_UNDEAD_1;
                    team_undead_1_size = team_undead_1_size + 1;
                    self.teammember = team_undead_1_size;
                    joined_ok = TRUE;
                }
                else
                {
                    numtries = numtries + 1;
                    trygroup = TEAM_UNDEAD_2;
                }
            }

            if (trygroup == TEAM_UNDEAD_2 && numtries < 3)
            {
                if (team_undead_2_size < team_maxmembers)
                {
                    if (can_be_leader &&
                        (team_undead_2_leader == world ||
                         random() > 0.7))
                        team_undead_2_leader = self;
                    self.teamgroup = TEAM_UNDEAD_2;
                    team_undead_2_size = team_undead_2_size + 1;
                    self.teammember = team_undead_2_size;
                    joined_ok = TRUE;
                }
                else
                {
                    numtries = numtries + 1;
                    trygroup = TEAM_UNDEAD_3;
                }
            }

            if (trygroup == TEAM_UNDEAD_3 && numtries < 3)
            {
                if (team_undead_3_size < team_maxmembers)
                {
                    if (can_be_leader &&
                        (team_undead_3_leader == world ||
                         random() > 0.7))
                         team_undead_3_leader = self;
                    self.teamgroup = TEAM_UNDEAD_3;
                    team_undead_3_size = team_undead_3_size + 1;
                    self.teammember = team_undead_3_size;
                    joined_ok = TRUE;
                }
                else
                {
                    numtries = numtries + 1;
                    trygroup = TEAM_UNDEAD_1;
                }
            }

            if (numtries >= 3)
            {
                if (developer & DV_SHOW_TEAM_AI)
                    dprint2 (self.netname," could not be teamed\n");
                self.teamgroup = TEAM_NONE;
                joined_ok = TRUE;
                team_none_size = team_none_size+1;
            }
        }
    }
    //----------------------------------------------------------------------------
    else if (team_class == TEAM_OGRE_1)
    {
        while (!joined_ok)
        {
            if (trygroup == TEAM_OGRE_1 && numtries < 3)
            {
                if (team_ogre_1_size < team_maxmembers)
                {
                    if (can_be_leader &&
                        (team_ogre_1_leader == world ||
                         random() > 0.7))
                    team_ogre_1_leader = self;
                    self.teamgroup = TEAM_OGRE_1;
                    team_ogre_1_size = team_ogre_1_size + 1;
                    self.teammember = team_ogre_1_size;
                    joined_ok = TRUE;
                }
                else
                {
                    numtries = numtries + 1;
                    trygroup = TEAM_OGRE_2;
                }
            }

            if (trygroup == TEAM_OGRE_2 && numtries < 3)
            {
                if (team_ogre_2_size < team_maxmembers)
                {
                    if (can_be_leader &&
                        (team_ogre_2_leader == world ||
                         random() > 0.7))
                        team_ogre_2_leader = self;
                    self.teamgroup = TEAM_OGRE_2;
                    team_ogre_2_size = team_ogre_2_size + 1;
                    self.teammember = team_ogre_2_size;
                    joined_ok = TRUE;
                }
                else
                {
                    numtries = numtries + 1;
                    trygroup = TEAM_OGRE_3;
                }
            }

            if (trygroup == TEAM_OGRE_3 && numtries < 3)
            {
                if (team_ogre_3_size < team_maxmembers)
                {
                    if (can_be_leader &&
                        (team_ogre_3_leader == world ||
                         random() > 0.7))
                        team_ogre_3_leader = self;
                    self.teamgroup = TEAM_OGRE_3;
                    team_ogre_3_size = team_ogre_3_size + 1;
                    self.teammember = team_ogre_3_size;
                    joined_ok = TRUE;
                }
                else
                {
                    numtries = numtries + 1;
                    trygroup = TEAM_OGRE_1;
                }
            }

            if (numtries >= 3)
            {
                if (developer & DV_SHOW_TEAM_AI)
                    dprint2 (self.netname," could not be teamed\n");
                self.teamgroup = TEAM_NONE;
                joined_ok = TRUE;
                team_none_size = team_none_size+1;
                self.teammember = team_none_size;
            }
        }
    }
};

