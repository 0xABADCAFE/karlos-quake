// smart.qc
/*---public---*/
// $VER: smart.qc 2.02 © Karlos (24/1/2000)

// public function prototypes

   vector (entity targ, float proj_speed, float t_intercept, void() shootfunc, void() too_far) smart_aim_ahead;
   void(entity targ, entity projectile, float proj_speed) smart_shoot_ahead;
   

   float(entity what) smart_judge_hazard;
   entity (entity who, float viewdist) smart_pick_new_target; 

   void(entity monster, entity startler) smart_alert;
   void(entity thing, entity initiator, float radius, float by_sight, float by_sound) smart_radius_alert;
   float(entity thing, entity to) is_visible;
   float(entity thing, entity to) is_audible;
   

/*---private---*/

//   Thanks to Mike Allan for help with brainstorming algorithm...
//   self is attackin entity
vector (entity targ, float proj_speed, float t_intercept, void() shootfunc, void() too_far) smart_aim_ahead =
{

   local vector target_velocity, predicted_target;
   local float movetime, time_of_flight, attack_time, target_dist, target_speed, predicted_target_dist;

   // calculate target distance at time of sighting...

   target_dist  = vlen (self.origin - targ.origin);
   target_speed = vlen (targ.velocity);

   if (target_dist < 200 || target_speed < 100)
   {
      // target is close or moving unpredictably
      // dprint("smart_aim_ahead() : shoot at target immediately\n");

      self.think = shootfunc;
      self.nextthink = time + 0.01;
      return targ.origin;
   }

   movetime = target_dist / proj_speed;

   if (movetime > t_intercept)
   {
      // too far away for prediction to be useful - should't happed normally
      // beacuse normal AI routine would realise this before attacking
      // but may be useful for slower projectiles
      // dprint("smart_aim_ahead() : target distant\n");

      self.think = too_far;
      self.nextthink = time + 0.01;
      return targ.origin;
   }

   // get usable components of target velocity

   target_velocity = targ.velocity;
   if (pointcontents (targ.origin) == CONTENT_EMPTY)
      target_velocity_z = 0;

   // predict target location after t_intercept;
   predicted_target = targ.origin + (target_velocity * t_intercept);
/*
   // is predicted target OK ?
   traceline (self.origin, targ.origin, TRUE, self);
   if (trace_ent != targ)
   {
      // predicted target is obscured, behave as if too far (will be a run fn usually)
      self.think = too_far;
      self.nextthink = time + 0.01;
      return targ.origin;
   }
*/
   // calculate distance of predicted target and hence, attack time
   predicted_target_dist = vlen(self.origin - predicted_target);

   time_of_flight = predicted_target_dist / proj_speed;
   attack_time    = t_intercept - time_of_flight;

   if (time_of_flight > t_intercept)
      attack_time = 0.05;

   // rotate calling entity to face predicted target...

   // self.ideal_yaw = vectoyaw(predicted_target - self.origin);

   self.think = shootfunc;
   self.nextthink = time + attack_time;

   // dprint("smart_aim_ahead() shoot at : ");
   // dprint(vtos(predicted_target));
   // dprint(" in ");
   // dprint(ftos(attack_time));
   // dprint(" from now.\n");

   return predicted_target;
};


void(entity targ, entity projectile, float proj_speed) smart_shoot_ahead =
{
   local vector   predicted_target, target_velocity, dir;
   local float t_intercept, target_dist, predicted_target_dist;

   // makevectors (self.angles);
      
   target_dist = vlen(targ.origin - projectile.origin);

   // calc aproximate time for missile to reach sighted target
   t_intercept = target_dist / proj_speed;
   
   // get the targets' velocity
   target_velocity = targ.velocity;
   if (pointcontents(targ.origin) == CONTENT_EMPTY)
      target_velocity_z = 0;

   // project the target forward in time
   predicted_target = targ.origin + target_velocity * t_intercept;

   predicted_target_dist = vlen(predicted_target - projectile.origin);

   // set projectile direction, angles and new speed

   dir = normalize(predicted_target - projectile.origin);

   projectile.velocity = dir * proj_speed * (predicted_target_dist / target_dist);
   projectile.angles = vectoangles(dir);
};

void(entity monster, entity startler) smart_alert =
{
   if (deathmatch)
      return;

   // dprint ("smart_alert()\n");
   // function to alert a monster, like monster_use, but not based on self.

   // startler must a monster or client entity
   if (!(startler.flags & (FL_MONSTER | FL_CLIENT)))
      return;
   
   // both startler and monster must be alive
   // as defined by their deadflag status

   if (startler.deadflag != DEAD_NO ||
       monster.deadflag != DEAD_NO ||
       (startler.flags & FL_NOTARGET))
      return;

   // 
   if (monster.classname == "monster_zombie" && monster.spawnflags & SPAWN_CRUCIFIED)
      return;

   // monster must not be busy already
   if (monster.enemy)
      return;

   // allow startled monster to immediately go nuts if the startler is from
   // an enemy team

   if (is_enemy_member(monster, startler))
   {
       // use this enemy
       monster.enemy        = startler; 
       monster.think        = FoundTarget;
   }
};

void(entity thing, entity initiator, float radius, float by_sight, float by_sound) smart_radius_alert =
{
   if (deathmatch)
      return;

   // function to alert monsters by seeing or hearing 'thing'
   // and allowing them to get mad at the initiator 'thing'

   local entity head;

   head = findradius(thing.origin, radius);

   while (head)
   {
      if (head.flags & FL_MONSTER)
      {
         if (by_sight & is_visible(thing, head) || by_sound & is_audible(thing, head))
         {
            smart_alert(head, initiator);
         }
      }
      head = head.chain;
   }
};

float (entity thing, entity to) is_visible =
{
   // if thing is visible to

   local float    radius, chance;

   // cant see invisible things
   if (thing.items & IT_INVISIBILITY)
      return FALSE;

   // visibility diminishes with distance
   radius = vlen(thing.origin - to.origin) / 500;
   chance = 1 / radius;
   if (chance > 1)
      chance = 1;

   traceline (to.origin, thing.origin, TRUE, to);

   // can't see through murk
   if (trace_inopen && trace_inwater)
      return FALSE;

   // cant see through walls
   if (trace_fraction != 1)
      return FALSE;

   // return if audible
   return random() < chance;
};


float (entity thing, entity to) is_audible =
{
   // if thing is audible to

   local float    radius, chance;

   radius = vlen(thing.origin - to.origin) / 700;

   chance = 1 / radius;
   if (chance > 1)
      chance = 1;

   traceline (to.origin, thing.origin, TRUE, to);  // sound not blocked by monsters

   // if sound crosses contents, lower hearing factor
   if (trace_inopen && trace_inwater)
      chance = 0.7 * chance;

   // if sound through walls. lower hearing factor;
   if (trace_fraction != 1)
      chance = 0.4 * chance;

   // return if audible
   return random() < chance;
};


float(entity what) smart_judge_hazard=
{
    // returns a value based on how dangerous 'what' is...
    // monsters

    if (what.flags & FL_MONSTER)
    {
        if (what.classname == "monster_shambler")
            return 50;
        else if (what.classname == "monster_vore")
            return 40;
        else if (what.classname == "monster_demon1")
            return 35;
        else if (what.classname == "monster_tarbaby")
            return 30;
        else if (what.classname == "monster_hell_knight")
            return 25;
        else if (what.classname == "monster_enforcer")
            return 23;
        else if (what.classname == "monster_ogre")
            return 22;
        else if (what.classname == "monster_zombie")
            return 20;
        else if (what.classname == "monster_knight")
            return 15;
        else if (what.classname == "monster_army")
            return 12;
        else if (what.classname == "monster_dog")
            return 10;
    }

    else return 0;
};


entity (entity who, float viewdist) smart_pick_new_target =
{
    // This function will allow monsters which have killed or lost their
    // existing enemies to look around their immediate vicinity for a
    // new target.

    // Function returns an entity to attack, or the world entity if no
    // target was found

    // The basic entity sweep filters a#out all those entities which are not
    // of enemy teams, and ensures that they should be visible

    // All the entities that fit these basic criteria will then be evaluated
    // in terms of how injured / dangerous / distant they are.

    // We can then pick the target which should be easiest to kill

   local entity head, best_target;

   local float target_suit, check_suit;

   if (who.deadflag)
      return world;
   
   // target should be in worse condition than self to ensure maximum
   // chance of sucess


   //dprint (who.classname);
   //dprint (" is looking for a new target\n");

   best_target = who;

   head = findradius(who.origin, viewdist);

   while (head)
   {
      if ((head.flags & (FL_CLIENT | FL_MONSTER)) && head.deadflag == DEAD_NO)
      {
          if ((is_enemy_member(who, head) == TRUE) && is_visible(head, who))
          {
              if (is_enemy_member(who, head) == FALSE)
                 dprint("AI error : non enemy flagged as hostile !\n");

              target_suit = (best_target.health / 400) + 
                            (smart_judge_hazard(best_target)/100);
              check_suit  = (head.health / 400) + 
                            (smart_judge_hazard(head)/100);
              if (check_suit < target_suit)
                  best_target = head;           
          }
      }
      head = head.chain;
   }


   if (best_target == who)
   {
       return world; 
   }
   else
   {
       //dprint("New target found : ");
       //dprint(best_target.classname);
       //dprint("\n");
       return best_target;
   }    
};


//------------------------------------------------------------------------------
