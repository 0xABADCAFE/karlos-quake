// fiend.qc
/*---public---*/
// $VER: fiend.qc 1.8 ? Karlos'99 (17/09/1999)

void() monster_demon1 ;
float() demon_check_melee ;
float() demon_check_jump ;
float() demon_check_attack ;
void(float side) Demon_Melee ;
void() demon_jump_touch ;
/*---private---*/
/*==============================================================================

   Fiend

   AKA                 : Demon
   Size                : man+
   Movetype(s) / Speed : run, jump / fast
   Attackmodes         : charge melee, jump attack
   Hit points          : 280, 100

   Specifics..
     Improved tracking, uses curved jump ai prediction for some obstacles,
   uses jumps in preference to running when charging to improve ground speed

==============================================================================*/

$cd id1/models/demon3
$scale   0.8
$origin 0 0 24
$base base
$skin base

$frame stand1 stand2 stand3 stand4 stand5 stand6 stand7 stand8 stand9
$frame stand10 stand11 stand12 stand13
$frame walk1 walk2 walk3 walk4 walk5 walk6 walk7 walk8
$frame run1 run2 run3 run4 run5 run6
$frame leap1 leap2 leap3 leap4 leap5 leap6 leap7 leap8 leap9 leap10
$frame leap11 leap12
$frame pain1 pain2 pain3 pain4 pain5 pain6
$frame death1 death2 death3 death4 death5 death6 death7 death8 death9
$frame attacka1 attacka2 attacka3 attacka4 attacka5 attacka6 attacka7 attacka8
$frame attacka9 attacka10 attacka11 attacka12 attacka13 attacka14 attacka15

//============================================================================

/*---private---*/

void() demon_jump_touch;
void() demon1_jump1;

void() demon1_stand1  = [ $stand1,  demon1_stand2  ] { ai_stand(); };
void() demon1_stand2  = [ $stand2,  demon1_stand3  ] { ai_stand(); };
void() demon1_stand3  = [ $stand3,  demon1_stand4  ] { ai_stand(); };
void() demon1_stand4  = [ $stand4,  demon1_stand5  ] { ai_stand(); };
void() demon1_stand5  = [ $stand5,  demon1_stand6  ] { ai_stand(); };
void() demon1_stand6  = [ $stand6,  demon1_stand7  ] { ai_stand(); };
void() demon1_stand7  = [ $stand7,  demon1_stand8  ] { ai_stand(); };
void() demon1_stand8  = [ $stand8,  demon1_stand9  ] { ai_stand(); };
void() demon1_stand9  = [ $stand9,  demon1_stand10 ] { ai_stand(); };
void() demon1_stand10 = [ $stand10, demon1_stand11 ] { ai_stand(); };
void() demon1_stand11 = [ $stand11, demon1_stand12 ] { ai_stand(); };
void() demon1_stand12 = [ $stand12, demon1_stand13 ] { ai_stand(); };
void() demon1_stand13 = [ $stand13, demon1_stand1  ] { ai_stand(); };

void() demon1_walk1 = [ $walk1, demon1_walk2 ] {
    if (random() < 0.2) {
        sound(self, CHAN_VOICE, "demon/idle1.wav", 1, ATTN_IDLE);
    }
    ai_walk(8);
};

void() demon1_walk2 = [ $walk2, demon1_walk3 ] { ai_walk(6); };
void() demon1_walk3 = [ $walk3, demon1_walk4 ] { ai_walk(6); };
void() demon1_walk4 = [ $walk4, demon1_walk5 ] { ai_walk(7); };
void() demon1_walk5 = [ $walk5, demon1_walk6 ] { ai_walk(4); };
void() demon1_walk6 = [ $walk6, demon1_walk7 ] { ai_walk(6); };
void() demon1_walk7 = [ $walk7, demon1_walk8 ] { ai_walk(10); };
void() demon1_walk8 = [ $walk8, demon1_walk1 ] { ai_walk(10); };

void() demon1_run1  = [ $run1, demon1_run2 ] {
    if (random() < 0.2) {
        sound(self, CHAN_VOICE, "demon/idle1.wav", 1, ATTN_IDLE);
    }
    ai_run(20);
};

void() demon1_run2 = [ $run2, demon1_run3 ] { ai_run(15); };
void() demon1_run3 = [ $run3, demon1_run4 ] { ai_run(36); };
void() demon1_run4 = [ $run4, demon1_run5 ] { ai_run(20); };
void() demon1_run5 = [ $run5, demon1_run6 ] { ai_run(15); };
void() demon1_run6 = [ $run6, demon1_run1 ] {
    ai_run(36);
    // if underwater, give a chance to switch to jump AI anyway
    if (self.waterlevel == 1) {
        if (random() > 0.8) {
            self.think = demon1_jump1;
        }
    }
};

void() demon1_jump1 = [ $leap1, demon1_jump2 ] { ai_face(); };
void() demon1_jump2 = [ $leap2, demon1_jump3 ] { ai_face(); };
void() demon1_jump3 = [ $leap3, demon1_jump4 ] { ai_face(); };

void() demon1_jump4 = [ $leap4, demon1_jump5 ] {
    local vector dir;
    local float dist;

    ai_face();

    self.touch = demon_jump_touch;
    makevectors(self.angles);
    self.origin_z = self.origin_z + 1;
    if (self.enemy.origin_z > self.origin_z + 40) {
        if (infront(self.enemy) || self.waterlevel == 1) {
            dir  = normalize(self.enemy.origin - self.origin);
            dist = vlen(self.enemy.origin - self.origin);
            self.velocity = dir * dist;
        }
        else {
            self.velocity = v_forward * 150;
        }
        self.velocity_z = 200 + self.enemy.origin_z - self.origin_z;
        if (self.velocity_z > 600) {
            self.velocity_z = 600;
        }
    }
    else {
        // slow forward to fall off ledge if player down
        // else normal horizontal velocity

        if (self.enemy.origin_z < self.origin_z - 30) {
            self.velocity   = v_forward * 150;
            self.velocity_z = 150 ;
        }
        else {
            self.velocity = v_forward * 600;
        }

        // check for wall in front
        traceline(self.origin - '0 0 16', (self.origin - '0 0 16') + v_forward * 150, TRUE, self);

        // attempt to jump wall or normal vel.
        if (trace_fraction < 1) {
            self.velocity   = v_forward * 110;
            self.velocity_z = 250 * (random() + 1);
        }
        else if (self.enemy.origin_z >= self.origin_z - 40) {
            self.velocity_z = 250;
        }
    }

    if (self.flags & FL_ONGROUND) {
        self.flags = self.flags - FL_ONGROUND;
    }

    /*   ai_face();
    self.touch = demon_jump_touch;
    makevectors (self.angles);
    self.origin_z = self.origin_z + 1;
    self.velocity = v_forward * 600 + '0 0 250';
    */
};

void() demon1_jump5  = [ $leap5,  demon1_jump6  ] { };
void() demon1_jump6  = [ $leap6,  demon1_jump7  ] { };
void() demon1_jump7  = [ $leap7,  demon1_jump8  ] { };
void() demon1_jump8  = [ $leap8,  demon1_jump9  ] { };
void() demon1_jump9  = [ $leap9,  demon1_jump10 ] { };
void() demon1_jump10 = [ $leap10, demon1_jump1  ] {
    self.nextthink = time + 3;
    // if three seconds pass, assume demon is stuck and jump again
};

void() demon1_jump11 = [ $leap11, demon1_jump12 ] { };
void() demon1_jump12 = [ $leap12, demon1_run1   ] { };

void() demon1_atta1  = [ $attacka1,  demon1_atta2  ] { ai_charge(4); };
void() demon1_atta2  = [ $attacka2,  demon1_atta3  ] { ai_charge(0); };
void() demon1_atta3  = [ $attacka3,  demon1_atta4  ] { ai_charge(0); };
void() demon1_atta4  = [ $attacka4,  demon1_atta5  ] { ai_charge(1); };
void() demon1_atta5  = [ $attacka5,  demon1_atta6  ] { ai_charge(2); Demon_Melee(200); };
void() demon1_atta6  = [ $attacka6,  demon1_atta7  ] { ai_charge(1); };
void() demon1_atta7  = [ $attacka7,  demon1_atta8  ] { ai_charge(6); };
void() demon1_atta8  = [ $attacka8,  demon1_atta9  ] { ai_charge(8); };
void() demon1_atta9  = [ $attacka9,  demon1_atta10 ] { ai_charge(4); };
void() demon1_atta10 = [ $attacka10, demon1_atta11 ] { ai_charge(2); };
void() demon1_atta11 = [ $attacka11, demon1_atta12 ] { Demon_Melee(-200); };
void() demon1_atta12 = [ $attacka12, demon1_atta13 ] { ai_charge(5); };
void() demon1_atta13 = [ $attacka13, demon1_atta14 ] { ai_charge(8); };
void() demon1_atta14 = [ $attacka14, demon1_atta15 ] { ai_charge(4); };
void() demon1_atta15 = [ $attacka15, demon1_run1   ] { ai_charge(4); };

void()   demon1_pain1   =[ $pain1,     demon1_pain2   ] {};
void()   demon1_pain2   =[ $pain2,     demon1_pain3   ] {};
void()   demon1_pain3   =[ $pain3,     demon1_pain4   ] {};
void()   demon1_pain4   =[ $pain4,     demon1_pain5   ] {};
void()   demon1_pain5   =[ $pain5,     demon1_pain6   ] {};
void()   demon1_pain6   =[ $pain6,     demon1_run1 ] {};

void(entity attacker, float damage) demon1_pain = {
    if (self.touch == demon_jump_touch) {
        return;
    }

    if (self.pain_finished > time) {
        return;
    }

    self.pain_finished = time + 1;
    sound(self, CHAN_VOICE, "demon/dpain1.wav", 1, ATTN_NORM);
    if (random() * 200 > damage) {
        return;     // didn't flinch
    }

    demon1_pain1();
};


void() demon1_die1 = [ $death1, demon1_die2 ] {
    sound(self, CHAN_VOICE, "demon/ddeath.wav", 1, ATTN_NORM);
};

void() demon1_die2 = [ $death2, demon1_die3 ] { };
void() demon1_die3 = [ $death3, demon1_die4 ] { };
void() demon1_die4 = [ $death4, demon1_die5 ] { };
void() demon1_die5 = [ $death5, demon1_die6 ] { };
void() demon1_die6 = [ $death6, demon1_die7 ] { };
void() demon1_die7 = [ $death7, demon1_die8 ] { };
void() demon1_die8 = [ $death8, demon1_die9 ] { };
void() demon1_die9 = [ $death9, demon1_die9 ] { corpse("progs/h_demon.mdl", 10 + random() * 8, 100); };

void() demon_die = {
    // check for gib
    if (self.health < -80 && effectflags & FX_GORE_GIBS) {
        sound (self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NORM);
        giblet ("progs/h_demon.mdl", self.health);
        return;
    }

    // regular death - modified by Karlos
    demon1_die1();
};

void() demon_melee_attack = {
   if (self.enemy.deadflag != DEAD_DEAD) {
      demon1_atta1();
   }
};

/*============================================================================
demon_check_melee

Returns TRUE if a melee attack would hit right now
============================================================================*/

float() demon_check_melee = {
    local float hdist;
    hdist = self.origin_z - self.enemy.origin_z;

    // out of reach ?
    if (hdist > 60 || hdist < -60) {
        return FALSE;
    }

    // in reach vertically - close enough ?
    else if (enemy_range == RANGE_MELEE) {
        return TRUE;
    }
    // nope..
    return FALSE;
};

/*============================================================================
demon_check_jump

============================================================================*/

float() demon_check_jump = {
    local vector dist;
    local float d;

    /*
    if (self.origin_z + self.mins_z > self.enemy.origin_z + self.enemy.mins_z
    + 0.75 * self.enemy.size_z)
        return FALSE;

    if (self.origin_z + self.maxs_z < self.enemy.origin_z + self.enemy.mins_z
    + 0.25 * self.enemy.size_z)
        return FALSE;
    */
    dist = self.enemy.origin - self.origin;

    // check vertical reach
    // refuses to jump too far ;)
    if (dist_z > 300 || dist_z < -750) {
        return FALSE;
    }

    dist_z = 0;
    d = vlen(dist);

    if (d < 100) {
        return FALSE;
    }

    if (d > 200) {
        if (random() < 0.9) {
            return FALSE;
        }
    }

    // check basic jump is OK
    return ai_test_jump();
};

/*===========================================================================
   demon_check_attack

      Added check for enemy status...
============================================================================*/

float() demon_check_attack = {
    local vector vec;

    // check slash first
    if (demon_check_melee()) {
        self.attack_state = AS_MELEE;
        return TRUE;
    }

    if (demon_check_jump()) {
        self.attack_state = AS_MISSILE;
        sound(self, CHAN_VOICE, "demon/djump.wav", 1, ATTN_NORM);
        return TRUE;
    }
    return FALSE;
};


//===========================================================================

void(float side)  Demon_Melee = {
    local float ldmg;
    local vector delta;

    ai_face();
    walkmove(self.ideal_yaw, 12);   // allow a little closing

    delta = self.enemy.origin - self.origin;

    if (vlen(delta) > 100) {
        return;
    }

    if (!CanDamage(self.enemy, self)) {
        return;
    }

    sound(self, CHAN_WEAPON, "demon/dhit2.wav", 1, ATTN_NORM);
    ldmg = 10 + 5*random();
    self.enemy.deathtype = "melee";
    T_Damage(self.enemy, self, self, ldmg);

    makevectors(self.angles);
    SpawnMeatSpray(self.origin + v_forward*16, side * v_right);
};


void() demon_jump_touch = {
    local float ldmg;

    if (other.takedamage) {
        other.deathtype = "melee";
        if (vlen(self.velocity) > 400) {
            ldmg = 40 + 10 * random();
            if (other.deadflag == DEAD_DEAD) {
                ldmg = ldmg * 3;
            }
            T_Damage(other, self, self, ldmg);
        }
    }

    if (!checkbottom(self)) {
        if (self.flags & FL_ONGROUND) {
            // jump randomly to not get hung up
            //dprint ("popjump\n");
            self.touch     = SUB_Null;
            self.think     = demon1_jump1;
            self.nextthink = time + 0.1;

    //       self.velocity_x = (random() - 0.5) * 600;
    //       self.velocity_y = (random() - 0.5) * 600;
    //       self.velocity_z = 200;
    //       self.flags = self.flags - FL_ONGROUND;
        }
        return;  // not on ground yet
    }

    self.touch     = SUB_Null;
    self.think     = demon1_jump11;
    self.nextthink = time + 0.1;
};

/*QUAKED monster_demon1 (1 0 0) (-32 -32 -24) (32 32 64) Ambush
*/

void() monster_demon1 = {
    if (deathmatch) {
        remove(self);
        return;
    }

    if (randomgame && !self.switched) {
        swap_monster();
        return;
    }

    if (!fiend_cached) {
        fiend_cached = TRUE;
        monstertypes = monstertypes + 1;
        precache_model("progs/demon.mdl");
        precache_model("progs/h_demon.mdl");
        precache_sound("demon/ddeath.wav");
        precache_sound("demon/dhit2.wav");
        precache_sound("demon/djump.wav");
        precache_sound("demon/dpain1.wav");
        precache_sound("demon/idle1.wav");
        precache_sound("demon/sight2.wav");
    }

    // Set the alerted sound, monster_init() will set up the standard alert behaviour
    self.noise        = "demon/sight2.wav";
    self.check_attack = demon_check_attack;

    monster_init("progs/demon.mdl", VEC_HULL_MIN, VEC_HULL_MAX, 280, 100);
    self.netname    = "a feind";
    self.th_stand   = demon1_stand1;
    self.th_walk    = demon1_walk1;
    self.th_run     = demon1_run1;
    self.th_die     = demon_die;
    self.th_melee   = demon_melee_attack;     // one of two attacks
    self.th_missile = demon1_jump1;        // jump attack
    self.th_pain    = demon1_pain;
    self.think      = monster_walk;

    AI_TeamJoin(TEAM_NONE, FALSE); // cannot be a team leader

};


