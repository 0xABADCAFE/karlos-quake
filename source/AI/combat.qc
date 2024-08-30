// combat.qc
/*---public---*/
// $VER: combat.qc 1.82 Karlos '99 (02/10/1999)
// public function prototypes
float(entity targ, entity inflictor) CanDamage;
void(entity targ, entity attacker) Killed;
void(entity targ, entity inflictor, entity attacker, float damage) T_Damage;
void(entity inflictor, entity attacker, float damage, entity ignore) T_RadiusDamage;
void(entity attacker, float damage) T_BeamDamage;
/*---private---*/

//============================================================================
//   CanDamage
//
//   Returns true if the inflictor can directly damage the target.  Used for
//   explosions and melee attacks.
//============================================================================

float(entity targ, entity inflictor) CanDamage = {
    // bmodels need special checking because their origin is 0,0,0
    if (targ.movetype == MOVETYPE_PUSH) {
        traceline(inflictor.origin, 0.5 * (targ.absmin + targ.absmax), TRUE, self);
        if (trace_fraction == 1) {
            return TRUE;
        }
        if (trace_ent == targ) {
            return TRUE;
        }
        return FALSE;
    }

    traceline(inflictor.origin, targ.origin, TRUE, self);
    if (trace_fraction == 1) {
        return TRUE;
    }

    traceline(inflictor.origin, targ.origin + '15 15 0', TRUE, self);
    if (trace_fraction == 1) {
        return TRUE;
    }

    traceline(inflictor.origin, targ.origin + '-15 -15 0', TRUE, self);
    if (trace_fraction == 1) {
        return TRUE;
    }

    traceline(inflictor.origin, targ.origin + '-15 15 0', TRUE, self);
    if (trace_fraction == 1) {
        return TRUE;
    }

    traceline(inflictor.origin, targ.origin + '15 -15 0', TRUE, self);
    if (trace_fraction == 1) {
        return TRUE;
    }

    return FALSE;
};


//============================================================================
//   Killed
//      patched for camera...
//============================================================================

void(entity targ, entity attacker) Killed = {
    local entity oself;

    oself = self;
    self  = targ;

    if (self.health < -99) {
        self.health = -99;      // don't let sbar look bad if a player
    }

    if (self.movetype == MOVETYPE_PUSH || self.movetype == MOVETYPE_NONE) {
        // doors, triggers, etc
        self.th_die();
        self = oself;
        return;
    }

    self.enemy = attacker;

    // bump the monster counter, update the teams and set the deadflag
    if (self.flags & FL_MONSTER) {
        killed_monsters = killed_monsters + 1;
        WriteByte(MSG_ALL, SVC_KILLEDMONSTER);
        self.deadflag = DEAD_DYING;
        monster_death_use();
        AI_TeamUpdate(targ, attacker);
    }
    else if (self.flags & FL_CLIENT) {
        ClientObituary(self, attacker);
        save_client_extraparms();

        // TODO - move to an entity method
        if (attacker.classname == "monster_army" || attacker.classname == "monster_enforcer") {
            radio_message(attacker, SAY_ENEMY_DOWN);
        }
    }
    self.takedamage = DAMAGE_NO;
    self.touch      = SUB_Null;
    self.th_die();
    self = oself;
};

void(vector origin, vector dir) SpawnMeatSpray;

//===========================================================================
//   T_Damage
//
//   The damage is coming from inflictor, but get mad at attacker
//   This should be the only function that ever reduces health.
//   NEW:
//       Function handles weapon damage when mikerules enabled
//===========================================================================
void(entity targ, entity inflictor, entity attacker, float damage) T_Damage = {

    if (!targ.takedamage) {
        return;
    }

    local vector   dir;
    local entity   oldself;
    local float save, take, weapontake, dot, inithealth;

    // reduce identical species damage
    if ((targ.flags & FL_MONSTER) && (targ.classname == attacker.classname)) {
        damage = 0.5 * damage;
    }

    // used by buttons and triggers to set activator for target firing
    damage_attacker = attacker;

    // check for quad damage powerup on the attacker
    if (attacker.super_damage_finished > time) {
        damage = damage * 4;
    }

    // save damage based on the target's armor level

    save = ceil(targ.armortype * damage);
    if (save >= targ.armorvalue) {
        save = targ.armorvalue;
        targ.armortype = 0;  // lost all armor
        targ.items = targ.items - (targ.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3));
    }

    targ.armorvalue = targ.armorvalue - save;
    take = ceil(damage-save);

    // add to the damage total for clients, which will be sent as a single
    // message at the end of the frame
    // FIXME: remove after combining shotgun blasts?
    if (targ.flags & FL_CLIENT) {
        targ.dmg_take = targ.dmg_take + take;
        targ.dmg_save = targ.dmg_save + save;
        targ.dmg_inflictor = inflictor;
    }

    // figure momentum add
    if ( (inflictor != world) && (targ.movetype == MOVETYPE_WALK) ) {
        dir = targ.origin - (inflictor.absmin + inflictor.absmax) * 0.5;
        dir = normalize(dir);
        targ.velocity = targ.velocity + dir*damage*8;
    }

    // check for godmode or invincibility
    if (targ.flags & FL_GODMODE) {
        return;
    }

    if (targ.invincible_finished >= time) {
        if (targ.invincible_sound < time) {
            sound(targ, CHAN_AUTO, "items/protect3.wav", 1, ATTN_NORM);
            targ.invincible_sound = time + 2;
        }
        return;
    }

    // team play damage avoidance
    if (
        (teamplay == 1) &&
        (targ.team > 0) &&
        (targ.team == attacker.team)
    ) {
        return;
    }

    // do the damage
    inithealth  = targ.health;
    targ.health = targ.health - take;

    // handle Mikerules
    if (mikerules) {
        apply_weapon_damage(attacker, targ, take);
    }

    if (targ.health <= 0) {
        Killed(targ, attacker);
        return;
    }

    if (
        (targ.flags & FL_CLIENT) &&
        (
            (cvar("viewsize") > 110) ||
            targ.extraflags & CL_MESSAGEBIT
        )
    ) {
        // if fullscreen, print warning messages to client

        if (targ.health < 25) {
            screen_message(targ, "warning : condition critical\n", MSG_WARN, TRUE);
        }
        else if (targ.health < 40) {
            screen_message(targ, "servere injuries sustained\n", MSG_WARN, TRUE);
        }
        else if (targ.health < 50) {
            screen_message(targ, "heavy injuries sustained\n", MSG_WARN, TRUE);
        }
    }

    // react to the damage
    oldself = self;
    self    = targ;

    //##

    if ( (self.flags & FL_MONSTER) && attacker != world) {

        // get mad unless of the same class (except for soldiers)
        if (self != attacker && attacker != self.enemy) {
            //if ( (self.classname != attacker.classname)
            // || (self.classname == "monster_army" ) )

            // Karlos team ai test
            // get mad at different teams, based on ai_team_tolerance_diff...
            // and reduce the likelyhood of getting mad at an equivalent team
            // based on ai_team_tolerance_same

            if (self.ai_team_id != attacker.ai_team_id) {
                // Ok, so we are talking different teams here...
                // get mad if teams diff AND chance > ai_team_tolerance_diff
                //     OR if teams same AND chance > ai_team_tolerance_same
                if (
                    (
                        self.ai_team_class != attacker.ai_team_class &&
                        random() > ai_team_tolerance_diff
                    ) ||
                    (
                        self.ai_team_class == attacker.ai_team_class &&
                        random() > ai_team_tolerance_same
                    )
                ) {
                    if (self.enemy.classname == "player") {
                        self.oldenemy = self.enemy;
                    }
                    self.enemy = attacker;
                    FoundTarget();
                }
            }
        }
        // team assistance stuff
        if (AI_JudgeHazard(attacker) > 25 * random() || self.health <= 25) {
            AI_TeamCallForHelp(self, 700, TRUE, TRUE);
        }
    }

    if (self.th_pain) {
        self.th_pain(attacker, take);
        // nightmare mode monsters don't go into pain frames often
        if (skill_fact > 2.5) {
            self.pain_finished = time + 5;
        }
    }

    self = oldself;
};


//============================================================================
//   T_RadiusDamage
//
//   Used for explosions etc...
//============================================================================

void(entity inflictor, entity attacker, float damage, entity ignore) T_RadiusDamage = {
    local float    points;
    local entity   head;
    local vector   org;

    head = findradius(inflictor.origin, damage+40);

    while (head) {
        if (head != ignore) {
            if (head.takedamage) {
                org    = head.origin + (head.mins + head.maxs) * 0.5;
                points = 0.5 * vlen(inflictor.origin - org);
                if (points < 0) {
                    points = 0;
                }

                points = damage - points;
                if (head == attacker) {
                    points = points * 0.5;
                }

                if (points > 0) {
                    if (CanDamage(head, inflictor)) {
                        // shambler takes half damage from all explosions
                        head.deathtype = "radius_damage";
                        if (head.classname == "monster_shambler") {
                            T_Damage(head, inflictor, attacker, points * 0.5);
                        }
                        else {
                            T_Damage (head, inflictor, attacker, points);
                        }

                        if (inflictor.weapon == IT_LIGHTNING) {
                            sound(head, CHAN_BODY, "weapons/lhit.wav",0.7, ATTN_NORM);
                        }
                    }
                }
            }
        }
        head = head.chain;
    }
};


//===========================================================================
//   T_BeamDamage
//
//===========================================================================

void(entity attacker, float damage) T_BeamDamage = {
    local float    points;
    local entity   head;

    head = findradius(attacker.origin, damage+40);

    while (head) {
        if (head.takedamage) {
            points = 0.5 * vlen(attacker.origin - head.origin);
            if (points < 0) {
                points = 0;
            }

            points = damage - points;
            if (head == attacker) {
                points = points * 0.5;
            }

            if (points > 0) {
                if (CanDamage(head, attacker)) {
                    if (head.classname == "monster_shambler") {
                        T_Damage(head, attacker, attacker, points * 0.5);
                    }
                    else {
                        T_Damage(head, attacker, attacker, points);
                    }
                }
            }
        }
        head = head.chain;
    }
};

