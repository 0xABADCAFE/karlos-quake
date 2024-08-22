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
// $VER: ai_team_manage.qc 1.10 © Karlos (05/02/2000)

// public function prototypes

void() ai_reset_teams;
void(float can_be_leader) ai_join_team;

void() dprint_team_stats;

void(entity whosdead, entity whodunnit) ai_update_teams;

string(float team_id) name_of_team;

void(float team_id) list_enemy_teams;

/*---private---*/

//================================================================================


void() ai_reset_teams =
{
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

    if (randomgame)
    {
        // Inc non-equiv tolerance 50% in random game, limit to equiv tolerance
        diff_class_enemy_lim = 1.5 * diff_class_enemy_lim;

        if (diff_class_enemy_lim > same_class_enemy_lim)
            diff_class_enemy_lim = same_class_enemy_lim;
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

void() dprint_team_stats =
{
    // prints info on the teams

    local string t_size, t_enemy, t_leader;

    if (team_army_1_size)
    {
        dprint ("army_1 : ");
        dprint (ftos(team_army_1_size));
        dprint (", ");
        dprint (ftos(team_army_1_enemy));
        dprint (", ");
        dprint (team_army_1_leader.netname);
        dprint ("\n");
    }
    if (team_army_2_size)
    {
        dprint ("army_2 : ");
        dprint (ftos(team_army_2_size));
        dprint (", ");
        dprint (ftos(team_army_2_enemy));
        dprint (", ");
        dprint (team_army_2_leader.netname);
        dprint ("\n");
    }
    if (team_army_3_size)
    {
        dprint ("army_3 : ");
        dprint (ftos(team_army_3_size));
        dprint (", ");
        dprint (ftos(team_army_3_enemy));
        dprint (", ");
        dprint (team_army_3_leader.netname);
        dprint ("\n");
    }
    if (team_knight_1_size)
    {
        dprint ("knight_1 : ");
        dprint (ftos(team_knight_1_size));
        dprint (", ");
        dprint (ftos(team_knight_1_enemy));
        dprint (", ");
        dprint (team_knight_1_leader.netname);
        dprint ("\n");
    }
    if (team_knight_2_size)
    {
        dprint ("knight_2 : ");
        dprint (ftos(team_knight_2_size));
        dprint (", ");
        dprint (ftos(team_knight_2_enemy));
        dprint (", ");
        dprint (team_knight_2_leader.netname);
        dprint ("\n");
    }
    if (team_knight_3_size)
    {
        dprint ("knight_3 : ");
        dprint (ftos(team_knight_3_size));
        dprint (", ");
        dprint (ftos(team_knight_3_enemy));
        dprint (", ");
        dprint (team_knight_3_leader.netname);
        dprint ("\n");
    }
    if (team_undead_1_size)
    {
        dprint ("undead_1 : ");
        dprint (ftos(team_undead_1_size));
        dprint (", ");
        dprint (ftos(team_undead_1_enemy));
        dprint (", ");
        dprint (team_undead_1_leader.netname);
        dprint ("\n");
    }
    if (team_undead_2_size)
    {
        dprint ("undead_2 : ");
        dprint (ftos(team_undead_2_size));
        dprint (", ");
        dprint (ftos(team_undead_2_enemy));
        dprint (", ");
        dprint (team_undead_2_leader.netname);
        dprint ("\n");
    }
    if (team_undead_3_size)
    {
        dprint ("undead_3 : ");
        dprint (ftos(team_undead_3_size));
        dprint (", ");
        dprint (ftos(team_undead_3_enemy));
        dprint (", ");
        dprint (team_undead_3_leader.netname);
        dprint ("\n");
    }
    if (team_ogre_1_size)
    {
        dprint ("ogre_1 : ");
        dprint (ftos(team_ogre_1_size));
        dprint (", ");
        dprint (ftos(team_ogre_1_enemy));
        dprint (", ");
        dprint (team_ogre_1_leader.netname);
        dprint ("\n");
    }
    if (team_ogre_2_size)
    {
        dprint ("ogre_2 : ");
        dprint (ftos(team_ogre_2_size));
        dprint (", ");
        dprint (ftos(team_ogre_2_enemy));
        dprint (", ");
        dprint (team_ogre_2_leader.netname);
        dprint ("\n");
    }
    if (team_ogre_3_size)
    {
        dprint ("ogre_3 : ");
        dprint (ftos(team_ogre_3_size));
        dprint (", ");
        dprint (ftos(team_ogre_3_enemy));
        dprint (", ");
        dprint (team_ogre_3_leader.netname);
        dprint ("\n");
    }
    dprint ("Unteamed monsters : ");
    dprint (ftos(team_none_size));
    dprint ("\n");
};

//================================================================================

string(float team_id) name_of_team =
{
    // attatch meaningful names to teams

    if (team_id == TEAM_NONE)
        return "unteamed";
    else if (team_id == TEAM_ARMY_1)
        return "army(1)";
    else if (team_id == TEAM_ARMY_2)
        return "army(2)";
    else if (team_id == TEAM_ARMY_3)
        return "army(3)";
    else if (team_id == TEAM_KNIGHT_1)
        return "knight(1)";
    else if (team_id == TEAM_KNIGHT_2)
        return "knight(2)";
    else if (team_id == TEAM_KNIGHT_3)
        return "knight(3)";
    else if (team_id == TEAM_UNDEAD_1)
        return "undead(1)";
    else if (team_id == TEAM_UNDEAD_2)
        return "undead(2)";
    else if (team_id == TEAM_UNDEAD_3)
        return "undead(3)";
    else if (team_id == TEAM_OGRE_1)
        return "ogre(1)";
    else if (team_id == TEAM_OGRE_2)
        return "ogre(2)";
    else if (team_id == TEAM_OGRE_3)
        return "ogre(3)";
    else if (team_id == TEAM_CLIENT)
        return "client";
    else if (team_id == TEAM_WORLD)
        return "the environment";
    else
        return "unknown team id";
};

void(float team_id) list_enemy_teams =
{
    // lists all teams deemed hostile to team_id

    local float id_bit;
    id_bit = 1;

    if ((team_id == TEAM_NONE) || (team_id == TEAM_WORLD))
        return;

    dprint(name_of_team(team_id));
    dprint(" enemies : ");

    if (team_id == TEAM_ARMY_1)
    {
        while (id_bit <= TEAM_OGRE_3)
        {
            id_bit = id_bit * 2;
            if (team_army_1_enemy & id_bit)
            {
                dprint (name_of_team(id_bit));
                dprint (", ");
            }
        }    
    }
    else if (team_id == TEAM_ARMY_2)
    {
        while (id_bit <= TEAM_OGRE_3)
        {
            id_bit = id_bit * 2;
            if (team_army_2_enemy & id_bit)
            {
                dprint (name_of_team(id_bit));
                dprint (", ");
            }
        }
    }
    else if (team_id == TEAM_ARMY_3)
    {
        while (id_bit <= TEAM_OGRE_3)
        {
            id_bit = id_bit * 2;
            if (team_army_3_enemy & id_bit)
            {
                dprint (name_of_team(id_bit));
                dprint (", ");
            }
        }
    }
    else if (team_id == TEAM_KNIGHT_1)
    {
        while (id_bit <= TEAM_OGRE_3)
        {
            id_bit = id_bit * 2;
            if (team_knight_1_enemy & id_bit)
            {
                dprint (name_of_team(id_bit));
                dprint (", ");
            }
        }
    }
    else if (team_id == TEAM_KNIGHT_2)
    {
        while (id_bit <= TEAM_OGRE_3)
        {
            id_bit = id_bit * 2;
            if (team_knight_2_enemy & id_bit)
            {
                dprint (name_of_team(id_bit));
                dprint (", ");
            }
        }
    }
    else if (team_id == TEAM_KNIGHT_3)
    {
        while (id_bit <= TEAM_OGRE_3)
        {
            id_bit = id_bit * 2;
            if (team_knight_3_enemy & id_bit)
            {
                dprint (name_of_team(id_bit));
                dprint (", ");
            }
        }
    }
    else if (team_id == TEAM_UNDEAD_1)
    {
        while (id_bit <= TEAM_OGRE_3)
        {
            id_bit = id_bit * 2;
            if (team_undead_1_enemy & id_bit)
            {
                dprint (name_of_team(id_bit));
                dprint (", ");
            }
        }
    }
    else if (team_id == TEAM_UNDEAD_2)
    {
        while (id_bit <= TEAM_OGRE_3)
        {
            id_bit = id_bit * 2;
            if (team_undead_2_enemy & id_bit)
            {
                dprint (name_of_team(id_bit));
                dprint (", ");
            }
        }
    }
    else if (team_id == TEAM_UNDEAD_3)
    {
        while (id_bit <= TEAM_OGRE_3)
        {
            id_bit = id_bit * 2;
            if (team_undead_3_enemy & id_bit)
            {
                dprint (name_of_team(id_bit));
                dprint (", ");
            }
        }
    }
    else if (team_id == TEAM_OGRE_1)
    {
        while (id_bit <= TEAM_OGRE_3)
        {
            id_bit = id_bit * 2;
            if (team_ogre_1_enemy & id_bit)
            {
                dprint (name_of_team(id_bit));
                dprint (", ");
            }
        }
    }
    else if (team_id == TEAM_OGRE_2)
    {
        while (id_bit <= TEAM_OGRE_3)
        {
            id_bit = id_bit * 2;
            if (team_ogre_2_enemy & id_bit)
            {
                dprint (name_of_team(id_bit));
                dprint (", ");
            }
        }
    }
    else if (team_id == TEAM_OGRE_3)
    {
        while (id_bit <= TEAM_OGRE_3)
        {
            id_bit = id_bit * 2;
            if (team_ogre_3_enemy & id_bit)
            {
                dprint (name_of_team(id_bit));
                dprint (", ");
            }
        }
    }
    dprint("\n");
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
    t_name = name_of_team(whodunnit.teamgroup);

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

