// grunt.qc
/*---public---*/
// $VER: grunt.qc 1.8 � Karlos '99 (16/09/1999)

void() monster_army;
/*---private---*/
/*=========================================================================================

   Grunt (Soldier)

   Size                : man
   Movetype(s) / Speed : walk, run / medium
   Attackmodes         : shot
   Hit points          : 35, 20
   Attack vectors      : shotgun
                         machinegun
   Weapon dropped      : super shotgun 1/10

   Specifics..
      Enabled (prev unused) anim frames - weapon checking
      Footstep handling
      Random and context sensitive radio fx
      Drops 2-10 shells in backpack
      Prefers machinegun over long ranges
      Can straife whilst shooting

=========================================================================================*/

// Model defs...
$cd id1/models/soldier3
$origin 0 -6 24
$base base
$skin skin

// Frame defs...

// standing / idle
   $frame stand1 stand2 stand3 stand4 stand5 stand6 stand7 stand8

// death 1
   $frame death1 death2 death3 death4 death5 death6 death7 death8
   $frame death9 death10

// death 2
   $frame deathc1 deathc2 deathc3 deathc4 deathc5 deathc6 deathc7 deathc8
   $frame deathc9 deathc10 deathc11

// reload
   $frame load1 load2 load3 load4 load5 load6 load7 load8 load9 load10 load11

// pain flinch 1
   $frame pain1 pain2 pain3 pain4 pain5 pain6

// pain flinch 2
   $frame painb1 painb2 painb3 painb4 painb5 painb6 painb7 painb8 painb9 painb10
   $frame painb11 painb12 painb13 painb14

// pain flinch 3
   $frame painc1 painc2 painc3 painc4 painc5 painc6 painc7 painc8 painc9 painc10
   $frame painc11 painc12 painc13

// running / alerted
   $frame run1 run2 run3 run4 run5 run6 run7 run8

// attacking
   $frame shoot1 shoot2 shoot3 shoot4 shoot5 shoot6 shoot7 shoot8 shoot9

// prowling / idle
   $frame prowl_1 prowl_2 prowl_3 prowl_4 prowl_5 prowl_6 prowl_7 prowl_8
   $frame prowl_9 prowl_10 prowl_11 prowl_12 prowl_13 prowl_14 prowl_15 prowl_16
   $frame prowl_17 prowl_18 prowl_19 prowl_20 prowl_21 prowl_22 prowl_23 prowl_24


/*---private---*/

void() army_fire;

/*==============================================================================
   STANDING / IDLE
==============================================================================*/

void() army_stand1 = [ $stand1, army_stand2 ] {
    // a bit of radio...
    if (random() < 0.1) {
        radio_message(self, 0);
    }
    ai_stand();
};

void() army_stand2 = [ $stand2, army_stand3 ] { ai_stand(); };
void() army_stand3 = [ $stand3, army_stand4 ] { ai_stand(); };
void() army_stand4 = [ $stand4, army_stand5 ] { ai_stand(); };
void() army_stand5 = [ $stand5, army_stand6 ] { ai_stand(); };
void() army_stand6 = [ $stand6, army_stand7 ] { ai_stand(); };
void() army_stand7 = [ $stand7, army_stand8 ] { ai_stand(); };
void() army_stand8 = [ $stand8, army_stand1 ] { ai_stand(); };

/*==============================================================================
   PROWLING / IDLE / WEAPON CHECK
==============================================================================*/

void() army_walk1 = [ $prowl_1, army_walk2 ] {
    // a bit of radio...
    if (random() < 0.15) {
        radio_message(self, 0);
    }
    ai_walk(1);
};

void() army_walk2 = [ $prowl_2, army_walk3 ] { ai_walk(1); };
void() army_walk3 = [ $prowl_3, army_walk4 ] { ai_walk(1); };
void() army_walk4 = [ $prowl_4, army_walk5 ] { ai_walk(1); };
void() army_walk5 = [ $prowl_5, army_walk6 ] { ai_walk(2); };
void() army_walk6 = [ $prowl_6, army_walk7 ] {
    // growl rarely
    if (random() < 0.05) {
        sound(self, CHAN_VOICE, "soldier/idle.wav", 0.6, ATTN_NORM);
    }
    ai_walk(3);
};

void() army_walk7  = [ $prowl_7,  army_walk8  ] { ai_walk(4); };
void() army_walk8  = [ $prowl_8,  army_walk9  ] { ai_walk(4); };
void() army_walk9  = [ $prowl_9,  army_walk10 ] { ai_walk(2); };
void() army_walk10 = [ $prowl_10, army_walk11 ] { ai_walk(2); };
void() army_walk11 = [ $prowl_11, army_walk12 ] { ai_walk(2); };
void() army_walk12 = [ $prowl_12, army_walk13 ] {
    // play footstep sound
    if (pointcontents(self.origin) == CONTENT_EMPTY) {
        footfall_normal (0.5, ATTN_STATIC);
    }
    ai_walk(1);
};

void() army_walk13 = [ $prowl_13, army_walk14 ] { ai_walk(0); };
void() army_walk14 = [ $prowl_14, army_walk15 ] { ai_walk(1); };
void() army_walk15 = [ $prowl_15, army_walk16 ] { ai_walk(1); };
void() army_walk16 = [ $prowl_16, army_walk17 ] { ai_walk(1); };
void() army_walk17 = [ $prowl_17, army_walk18 ] { ai_walk(3); };
void() army_walk18 = [ $prowl_18, army_walk19 ] { ai_walk(3); };
void() army_walk19 = [ $prowl_19, army_walk20 ] { ai_walk(3); };
void() army_walk20 = [ $prowl_20, army_walk21 ] { ai_walk(3); };

// Check weapon
void() army_check1  = [ $load1, army_check2  ] { };
void() army_check2  = [ $load2, army_check3  ] { };
void() army_check3  = [ $load3, army_check4  ] { };
void() army_check4  = [ $load4, army_check5  ] { };
void() army_check5  = [ $load5, army_check6  ] { };
void() army_check6  = [ $load6, army_check7  ] { };
void() army_check7  = [ $load7, army_check8  ] { };
void() army_check8  = [ $load8, army_check9  ] { };
void() army_check9  = [ $load9, army_check10 ] { sound(self, CHAN_WEAPON, "weapons/pkup.wav", 0.75, ATTN_IDLE); };
void() army_check10 = [ $load10, army_check11] { };
void() army_check11 = [ $load11, army_walk21 ] { };
// End check weapon

void() army_walk21 = [ $prowl_21, army_check  ] { ai_walk(2); };
void() army_walk22 = [ $prowl_22, army_walk23 ] { ai_walk(1); };
void() army_walk23 = [ $prowl_23, army_walk24 ] { ai_walk(1); };
void() army_walk24 = [ $prowl_24, army_walk1  ] {
    // play footstep sound
    if (pointcontents(self.origin) == CONTENT_EMPTY) {
        footfall_normal (0.6, ATTN_STATIC);
    }
    ai_walk(1);
};

// Do weapon check at frame 21
void() army_check = {
    ai_walk(3);
    if (random() < 0.05) {
        army_check1();
    }
    else {
        army_walk22();
    }
};

/*==============================================================================
   RUNNING / ALERTED
==============================================================================*/

void() army_run1 = [ $run1, army_run2 ] {
    // play foostep sound
    if (pointcontents(self.origin) == CONTENT_EMPTY) {
        footfall_normal (0.8, ATTN_IDLE);
    }
    ai_run(11);
};

void() army_run2 = [ $run2, army_run3 ] { ai_run(15); };
void() army_run3 = [ $run3, army_run4 ] { ai_run(10); };
void() army_run4 = [ $run4, army_run5 ] {
    // play footstep sound
    if (pointcontents(self.origin) == CONTENT_EMPTY) {
        footfall_normal (0.7, ATTN_IDLE);
    }
    ai_run(10);
};

void() army_run5 = [ $run5, army_run6 ] { ai_run(8); };
void() army_run6 = [ $run6, army_run7 ] {
    if (random() < 0.07) {
        sound (self, CHAN_VOICE, "soldier/idle.wav", 0.75, ATTN_NORM);
    }
    ai_run(15);
};

void() army_run7 = [ $run7, army_run8 ] { ai_run(10); };
void() army_run8 = [ $run8, army_run1 ] {
    // a bit of radio...
    if (random() < 0.05) {
        if (random() < 0.5) {
            radio_message(self, 0);
        }
        else {
            radio_message(self, SAY_ENEMY_SIGHTED);
        }
    }
    ai_run(8);
};


/*==============================================================================
   ATTACKING
==============================================================================*/

void() army_atk1 = [ $shoot1, army_atk2 ] {
    ai_face();
    if (random() < 0.1) {
        radio_message(self, SAY_DESTROY_GREEN);
    }
};

void() army_atk2 = [ $shoot2, army_atk3 ] { ai_face(); };
void() army_atk3 = [ $shoot3, army_atk4 ] { ai_face(); };
void() army_atk4 = [ $shoot4, army_atk5 ] { ai_face(); };
void() army_atk5 = [ $shoot5, army_atk6 ] {
    ai_face();
    army_fire();
    self.effects = self.effects | (FX_FLASH & effectflags);
};

void() army_atk6 = [ $shoot6, army_atk7 ] { ai_face(); };
void() army_atk7 = [ $shoot7, army_atk8 ] { ai_face(); SUB_CheckRefire (army_atk1); };
void() army_atk8 = [ $shoot8, army_atk9 ] { ai_face(); };
void() army_atk9 = [ $shoot9, army_run1 ] { self.attack_state = AS_STRAIGHT; };

void() army_mgn;

void() army_mgn1 = [ $shoot1, army_mgn2 ] {
    ai_face();
    if (random() < 0.1) {
        radio_message(self, SAY_DESTROY_GREEN);
    }
};

void() army_mgn2  = [ $shoot2, army_mgn3  ] { ai_face(); };
void() army_mgn3  = [ $shoot3, army_mgn4  ] { ai_face(); };
void() army_mgn4  = [ $shoot4, army_mgn5  ] { ai_face(); };
void() army_mgn5  = [ $shoot5, army_mgn6  ] {
    self.effects = self.effects | (FX_FLASH & effectflags);
    army_mgn();
};

void() army_mgn6  = [ $shoot6, army_mgn7  ] { army_mgn(); };
void() army_mgn7  = [ $shoot5, army_mgn8  ] {
    self.effects = self.effects | (FX_FLASH & effectflags);
    army_mgn();
};

void() army_mgn8  = [ $shoot6, army_mgn9  ] { army_mgn(); };
void() army_mgn9  = [ $shoot5, army_mgn10 ] {
    self.effects = self.effects | (FX_FLASH & effectflags);
    army_mgn();
};

void() army_mgn10 = [ $shoot6, army_mgn11 ] { army_mgn(); };
void() army_mgn11 = [ $shoot5, army_mgn12 ] {
    self.effects = self.effects | (FX_FLASH & effectflags);
    army_mgn();
};

void() army_mgn12 = [ $shoot6, army_mgn13 ] { army_mgn(); };
void() army_mgn13 = [ $shoot5, army_mgn14 ] {
    self.effects = self.effects | (FX_FLASH & effectflags);
    army_mgn();
};

void() army_mgn14 = [ $shoot6, army_mgn15 ] { army_mgn(); };
void() army_mgn15 = [ $shoot5, army_mgn16 ] {
    self.effects = self.effects | (FX_FLASH & effectflags);
    army_mgn();
};

void() army_mgn16 = [ $shoot6, army_mgn17 ] { army_mgn(); };
void() army_mgn17 = [ $shoot5, army_mgn18 ] {
    self.effects = self.effects | (FX_FLASH & effectflags);
    army_mgn();
};

void() army_mgn18 = [ $shoot6, army_mgn19 ] { army_mgn(); };
void() army_mgn19 = [ $shoot7, army_mgn20 ] {
    ai_face();
    SUB_CheckRefire(army_mgn1);
};

void() army_mgn20 = [ $shoot8, army_mgn21 ] { };
void() army_mgn21 = [ $shoot9, army_run1  ] { self.attack_state = AS_STRAIGHT; };

/*==============================================================================
   PAIN FLINCHES
==============================================================================*/

void() army_pain1   = [ $pain1,   army_pain2   ] { };
void() army_pain2   = [ $pain2,   army_pain3   ] { };
void() army_pain3   = [ $pain3,   army_pain4   ] { };
void() army_pain4   = [ $pain4,   army_pain5   ] { };
void() army_pain5   = [ $pain5,   army_pain6   ] { };
void() army_pain6   = [ $pain6,   army_run1    ] { ai_pain(1); };

void() army_painb1  = [ $painb1,  army_painb2  ] { };
void() army_painb2  = [ $painb2,  army_painb3  ] { ai_painforward(13); };
void() army_painb3  = [ $painb3,  army_painb4  ] { ai_painforward(9); };
void() army_painb4  = [ $painb4,  army_painb5  ] { };
void() army_painb5  = [ $painb5,  army_painb6  ] { };
void() army_painb6  = [ $painb6,  army_painb7  ] { };
void() army_painb7  = [ $painb7,  army_painb8  ] { };
void() army_painb8  = [ $painb8,  army_painb9  ] { };
void() army_painb9  = [ $painb9,  army_painb10 ] { };
void() army_painb10 = [ $painb10, army_painb11 ] { };
void() army_painb11 = [ $painb11, army_painb12 ] { };
void() army_painb12 = [ $painb12, army_painb13 ] { ai_pain(2); };
void() army_painb13 = [ $painb13, army_painb14 ] { };
void() army_painb14 = [ $painb14, army_run1    ] { };

void() army_painc1  = [ $painc1,  army_painc2  ] { };
void() army_painc2  = [ $painc2,  army_painc3  ] { ai_pain(1); };
void() army_painc3  = [ $painc3,  army_painc4  ] { };
void() army_painc4  = [ $painc4,  army_painc5  ] { };
void() army_painc5  = [ $painc5,  army_painc6  ] { ai_painforward(1); };
void() army_painc6  = [ $painc6,  army_painc7  ] { ai_painforward(1); };
void() army_painc7  = [ $painc7,  army_painc8  ] { };
void() army_painc8  = [ $painc8,  army_painc9  ] { ai_pain(1); };
void() army_painc9  = [ $painc9,  army_painc10 ] { ai_painforward(4); };
void() army_painc10 = [ $painc10, army_painc11 ] { ai_painforward(3); };
void() army_painc11 = [ $painc11, army_painc12 ] { ai_painforward(6); };
void() army_painc12 = [ $painc12, army_painc13 ] { ai_painforward(8); };
void() army_painc13 = [ $painc13, army_run1    ] { };


/*===================================================================================
   DYING
===================================================================================*/

void() army_die1   = [ $death1,   army_die2   ] { };
void() army_die2   = [ $death2,   army_die3   ] { };
void() army_die3   = [ $death3,   army_die4   ] { DropBackpack(); };
void() army_die4   = [ $death4,   army_die5   ] { };
void() army_die5   = [ $death5,   army_die6   ] { };
void() army_die6   = [ $death6,   army_die7   ] { };
void() army_die7   = [ $death7,   army_die8   ] { sound(self, CHAN_BODY, "demon/dland2.wav", 1, ATTN_STATIC); };
void() army_die8   = [ $death8,   army_die9   ] { };
void() army_die9   = [ $death9,   army_die10  ] { };
void() army_die10  = [ $death10,  army_die10  ] { corpse("progs/h_guard.mdl", 6 + random() * 4, 50); };

void() army_cdie1  = [ $deathc1,  army_cdie2  ] { };
void() army_cdie2  = [ $deathc2,  army_cdie3  ] { ai_back(5); };
void() army_cdie3  = [ $deathc3,  army_cdie4  ] { DropBackpack(); ai_back(4); };
void() army_cdie4  = [ $deathc4,  army_cdie5  ] { ai_back(13); };
void() army_cdie5  = [ $deathc5,  army_cdie6  ] { ai_back(3); };
void() army_cdie6  = [ $deathc6,  army_cdie7  ] { ai_back(4); };
void() army_cdie7  = [ $deathc7,  army_cdie8  ] { };
void() army_cdie8  = [ $deathc8,  army_cdie9  ] { sound(self, CHAN_BODY, "demon/dland2.wav", 1, ATTN_STATIC); };
void() army_cdie9  = [ $deathc9,  army_cdie10 ] { };
void() army_cdie10 = [ $deathc10, army_cdie11 ] { };
void() army_cdie11 = [ $deathc11, army_cdie11 ] { corpse("progs/h_guard.mdl", 6 + random()*4, 50); };


/*==============================================================================
   PAIN
==============================================================================*/

void(entity attacker, float damage) army_pain = {
    local float r;

    if (self.pain_finished > time) {
        return;
    }

    r = random();
    if (r < 0.2) {
        self.pain_finished = time + 0.6;
        army_pain1();
        sound (self, CHAN_VOICE, "soldier/pain1.wav", 1, ATTN_NORM);
    }
    else if (r < 0.6) {
        self.pain_finished = time + 1.1;
        army_painb1();
        sound (self, CHAN_VOICE, "soldier/pain2.wav", 1, ATTN_NORM);
    }
    else {
        self.pain_finished = time + 1.1;
        army_painc1();
        sound(self, CHAN_VOICE, "soldier/pain2.wav", 1, ATTN_NORM);
    }
};




/*==============================================================================
   ATTACKING
==============================================================================*/

void() army_attack =
{
    local float enemy_range;

    enemy_range = range(self.enemy);
    if (vlen(self.enemy.velocity) > 200) {
        self.attack_state = AS_STRAIGHT;
    }
    else {
        self.attack_state = AS_SLIDING;
        if (random() < 0.5) {
            self.dodge = -10;
        }
        else {
            self.dodge = 10;
        }
    }

    // prefer shotgun at close range
    // switching to machinegun at greater distance
    if (enemy_range == RANGE_FAR) {
        self.think = army_mgn1;
    }
    else if (enemy_range == RANGE_MID) {
        if (random() < 0.2) {
            self.think = army_atk1;
        }
        else {
            self.think = army_mgn1;
        }
    }
    else if (enemy_range == RANGE_NEAR) {
        if (random() < 0.8) {
            self.think = army_atk1;
        }
        else {
            self.think = army_mgn1;
        }
    }
    else {
        self.think = army_atk1;
    }
};

void() army_fire = {
    local vector   dir;

    ai_face();
    sound(self, CHAN_WEAPON, "weapons/guncock.wav", 1, ATTN_NORM);

    // fire somewhat behind the player, so a dodging player is harder to hit

    dir = self.enemy.origin - self.enemy.velocity * 0.2;
    dir = normalize(dir - self.origin);
    FireBullets(4, dir, '0.1 0.1 0');
};

void() army_mgn = {
    local vector   dir;

    if (!visible(self.enemy)) {
        // give up if enemy is out of sight
        self.think = army_mgn19;
        return;
    }

    if (self.attack_state == AS_STRAIGHT) {
        ai_face();
    }
    else {
        ai_run(self.dodge);
    }

    // fire somewhat behind the player, so a dodging player is harder to hit
    dir = self.enemy.origin - self.enemy.velocity * 0.1;
    dir = normalize (dir - self.origin);
    fire_machine_bullet (dir, '0.1 0.1 0.1');
    self.nextthink = time + 0.1;
};

//====================================================================================
//
//   DYING
//
//====================================================================================

void() army_die = {
    // check for gib
    if (self.health < -35 && effectflags & FX_GORE_GIBS) {
        sound(self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NORM);
        giblet("progs/h_guard.mdl", self.health);
        return;
    }

    // regular death

    sound(self, CHAN_VOICE, "soldier/death1.wav", 1, ATTN_NORM);
    self.ammo_shells = 2 + rint(random() * 8);  // drop random ammo
    setsize(self, '-12 -12 -24', '12 12 12');   // not so big when dead...

    if (random() < 0.1) {
        inv_drop_item (IT_SUPER_SHOTGUN);
    }
    if (random() < 0.5) {
        army_die1();
    }
    else {
        army_cdie1();
    }
};

float() army_check_attack = {
    // Early out checks
    if (enemy_range == RANGE_FAR) {
        return FALSE;
    }

    if (time < self.attack_finished) {
        return FALSE;
    }

    local vector   spot1, spot2;
    local entity   targ;
    local float    chance;

    targ = self.enemy;

    // see if any entities are in the way of the shot
    spot1 = self.origin + self.view_ofs;
    spot2 = targ.origin + targ.view_ofs;

    traceline(spot1, spot2, FALSE, self);

    if (trace_inopen && trace_inwater) {
        return FALSE;        // sight line crossed contents
    }

    if (trace_ent != targ) {
        return FALSE;  // don't have a clear shot
    }

    if (enemy_range == RANGE_MELEE) {
        chance = 0.9;
    }
    else if (enemy_range == RANGE_NEAR) {
        chance = 0.4;
    }
    else if (enemy_range == RANGE_MID) {
        chance = 0.05;
    }
    else {
        chance = 0;
    }

    if (random () < chance) {
        self.th_missile();
        SUB_AttackFinished(1 + random());
        if (random() < 0.3) {
            self.lefty = !self.lefty;
        }
        return TRUE;
    }

    return FALSE;
};

/*==============================================================================
   QUAKED monster_army (1 0 0) (-16 -16 -24) (16 16 40) Ambush
==============================================================================*/

void() monster_army = {
    if (deathmatch) {
        remove(self);
        return;
    }

    if (randomgame && !self.switched) {
        swap_monster();
        return;
    }

    if (!grunt_cached) {
        grunt_cached = TRUE;
        monstertypes = monstertypes + 1;
        precache_model("progs/soldier.mdl");
        precache_model("progs/h_guard.mdl");
        precache_model("progs/gib1.mdl");
        precache_model("progs/gib2.mdl");
        precache_model("progs/gib3.mdl");
        precache_sound("soldier/death1.wav");
        precache_sound("soldier/idle.wav");
        precache_sound("soldier/pain1.wav");
        precache_sound("soldier/pain2.wav");
        precache_sound("weapons/guncock.wav");
        precache_sound("soldier/sight1.wav");

        // karlos extras
        // note - footsteps are precached globally in world.qc

        // random radio messages
        precache_sound("soldier/radio1.wav");
        precache_sound("soldier/radio2.wav");
        precache_sound("soldier/radio3.wav");
        precache_sound("soldier/radio4.wav");
        precache_sound("soldier/radio5.wav");

        // special radio messages
        precache_sound("soldier/radio_sight.wav");     // player sighted
        precache_sound("soldier/radio_attack.wav");    // attack instructions
        precache_sound("soldier/radio_ackn.wav");      // instructions acknowledged
        precache_sound("soldier/radio_enemydown.wav"); // player dead
    }

    precache_sound("player/udeath.wav");     // gib death - should be precached

    // Set the alerted sound, monster_init() will set up the standard alert behaviour
    self.noise        = "soldier/sight1.wav";
    self.check_attack = army_check_attack;

    monster_init("progs/soldier.mdl", '-16 -16 -24', '16 16 40', 35, 20);
    self.netname    = "a grunt";
    self.th_stand   = army_stand1;
    self.th_walk    = army_walk1;
    self.th_run     = army_run1;
    self.th_missile = army_attack;
    self.th_pain    = army_pain;
    self.th_die     = army_die;
    self.think      = monster_walk;

    AI_TeamJoin(TEAM_ARMY_1, TRUE); // can be a team leader
};
