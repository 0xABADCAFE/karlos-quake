// camera.qc

/*---public---*/
// $VER: camera.qc 1.74 © Karlos '00 (22/1/2000)

// public function prototypes
// highlevel
   void()                                toggle_camera;
   void(float opt)                       camera_change_zmult;
   void(float opt)                       camera_change_dist;

// lowlevel
   void() initialise_camera;
   void(entity msg_ent, entity view_ent) set_viewport;

/*---private---*/

// private functions
   void() camera_trackowner;
   void() cam_deathview;

void(entity msg_ent, entity view_ent) set_viewport = 
{
   msg_entity = msg_ent;                          // target of message
   WriteByte (MSG_ONE, SVC_SETVIEWPORT);
   WriteEntity (MSG_ONE, view_ent);               // view port
};

//-------------------------------------------------------------------------

// Resets weapon model after changing view
// called by chase cam or player entities

void(entity player_ent) switch_weaponviewmodel =
{
   local entity e;

   e = self;
   self = player_ent;
   if (self.flags & FL_USING_CAMERA)
   {
       // disable handedness view offset in camera mode
       self.weaponmodel = "";
       localcmd("scr_ofsy 0\n");
   }
   else
   {
       // re-enable handedness view offset when not in camera mode
       if ((self.extraflags & CL_CENTREHANDED) == CL_NOHANDVIEW)        
           localcmd("scr_ofsy 0\n");
       else if ((self.extraflags & CL_CENTREHANDED) == CL_RIGHTHANDED)
           localcmd("scr_ofsy -5\n");
       else if ((self.extraflags & CL_CENTREHANDED) == CL_LEFTHANDED)
           localcmd("scr_ofsy 5\n");
       else
           localcmd("scr_ofsy 0\n");
       W_SetCurrentAmmo ();
   }
   self = e;
};

//-------------------------------------------------------------------------

// called either by player or chase cam entities (to restart)
// vpos:
// '0 0 0' = start from player
// (else use as cam origin)

void(entity camera_owner, vector vpos) start_chase =
{
   sprint (camera_owner, "camera mode\n");
   local entity   chase_cam;
   chase_cam = spawn();
   chase_cam.owner = camera_owner;

   // turn on bit-flag
   chase_cam.owner.flags = chase_cam.owner.flags | FL_USING_CAMERA;

   chase_cam.solid = SOLID_NOT;
   chase_cam.movetype = MOVETYPE_FLY;


   chase_cam.angles = chase_cam.owner.angles;

   setmodel (chase_cam, "progs/camera.mdl");
   setsize (chase_cam, '0 0 0', '0 0 0');

   if (vpos == '0 0 0')
      setorigin(chase_cam, chase_cam.owner.origin + '0 0 22' );
   else
      setorigin(chase_cam, vpos );

   chase_cam.classname = "chase_cam";

   chase_cam.nextthink = time + 0.1;
   chase_cam.think = camera_trackowner;

   chase_cam.skin = 1;

   // let track function handle the remote view
   // part, start with "temp. disabled" flag set

   switch_weaponviewmodel(camera_owner);

   // distance clipping
   chase_cam.ammo_shells = camera_owner.dest2_y / 3;

};

//-------------------------------------------------------------------------

// secondary think for cam entities

void() reactivate_chase =
{
   self.nextthink = time + 0.1;

   //if (self.owner.health <= 0)
   if (self.owner.solid == SOLID_NOT)
   {
      //owner died in water, reset flag for respawn
      self.owner.flags = self.owner.flags | FL_USING_CAMERA;
      remove(self);
      return;
   }

   if (self.owner.waterlevel)
      return;

   self.owner.flags = self.owner.flags | FL_USING_CAMERA;
   switch_weaponviewmodel(self.owner);

   self.skin = 1; // flag temp. disabled flag so track function
                  // will reset remote view
   self.solid = SOLID_NOT;
   self.movetype = MOVETYPE_FLY;
   setmodel (self, "progs/camera.mdl");
   setsize (self, '0 0 0', '0 0 0');
   setorigin( self, self.owner.origin);
   self.ammo_shells = self.owner.dest2_y / 3; // distance clipping
   self.think = camera_trackowner;
};

//-------------------------------------------------------------------------

// called only by chase cam entities
// opt values
// TRUE = remove completely
// FALSE = remove view but keep alive with reactivate_chase();

void( float opt ) remove_camera =
{
   // turn off bit-flag
   self.owner.flags = self.owner.flags - (self.owner.flags & FL_USING_CAMERA);

   // set view-point back to normal
   set_viewport(self.owner, self.owner);


   setmodel(self, "" );
   self.velocity = '0 0 0';

   self.owner.view_ofs_z = 22;

   switch_weaponviewmodel(self.owner);

   if ( !opt )
   {
      self.nextthink = time + 0.1;
      self.think = reactivate_chase;
   }
   else
      remove(self);

};

void () cam_deathview =
{
   self.nextthink = time + 0.1;

   if (self.owner.solid != SOLID_NOT)
   {
      remove( self);
      return;
   }

   traceline( self.owner.origin, self.origin, TRUE, self.owner);
   if (trace_inwater)
   {
      set_viewport( self.owner, self.owner);
      self.owner.health = -1;
      remove( self);
      return;
   }
   if (trace_fraction < 1)
   {
      setorigin( self, trace_endpos - self.dest * 8);
      self.velocity = '0 0 0';
   }

   if (self.velocity != '0 0 0')
   {
      traceline( self.origin, self.origin + self.dest * 20, TRUE, self.owner);
      if (trace_fraction < 1 || trace_inwater ||
          vlen( self.origin - self.owner.origin) > 200)
         self.velocity = '0 0 0';
   }

};

//-------------------------------------------------------------------------

/*
   main think function for cam entities
      self.ammo_shells = distance clipping
      self.ammo_nails = hang-up flag
      self.dmg = lifts fix
      self.frags = lifts fix
      self.ammo_cells = lifts fix
      self.dest = deathview vector to save 'v_forward' of fade direction
      self.skin = close proximity temporary disableing

      .v_angle_x:
      78.8 (max down aim)
      -68.9 (max up aim)
*/


void() camera_trackowner =
{
   local vector vtmp1, vtmp2;
   local vector owner_vec, goal, dir;
   local float  dist, cap, f_f;

   self.nextthink = time + 0.1;

   // check if player toggled
   if (!(self.owner.flags & FL_USING_CAMERA))
   {
      remove_camera( TRUE );
      return;
   }

   if (self.owner.solid == SOLID_NOT)
   {
      if (intermission_running)
      {
         set_viewport( self.owner, self.owner);
         remove( self );
      }
      else
      {  // deathview
         self.velocity = '0 0 0' - normalize( self.owner.origin - self.origin) * 20;
         self.angles = vectoangles( self.velocity);
         makevectors( self.angles);
         self.dest = v_forward; // save forward direction, used in cam_deathview
         self.think = cam_deathview;
         if (self.skin) // temp disable flag is set
         {
            self.owner.view_ofs_z = -1;
            set_viewport(self.owner, self);
         }
      }
      return;
   }


   if (self.owner.waterlevel)
   {
      remove_camera(FALSE);
      return;
   }

   owner_vec = self.owner.origin + '0 0 22';

   // get player velocity relative to player's
   // current yaw
   // f_f (based on running calcs (maxspeed = 400)
   //  (back ~= 640, forward ~= 0)
   dir_y = self.owner.v_angle_y;
   makevectors( dir );

   f_f = vlen( (v_forward * 320) - self.owner.velocity );

   // held for use after second makevectors call for
   // pulling forward on a down aim
   dir = v_forward;

   // increment fade-back variable
   self.ammo_shells = self.ammo_shells + 4.5;
   if (self.ammo_shells > self.owner.dest2_y)
      self.ammo_shells = self.owner.dest2_y;

   makevectors( self.owner.v_angle );

   // set spot before clipping
   //.v_angle_x:
   // 78.8 (max down aim)
   // -68.9 (max up aim)

   goal = owner_vec - (v_forward * self.ammo_shells);
   goal_z = goal_z + 14 + (self.ammo_shells * self.owner.dest2_z);

   // adjust initial goal

   if (self.owner.v_angle_x > 0)
   {
      // pull forward
      cap = self.owner.v_angle_x;
      if (cap > 56) cap = 56;
      goal = goal + dir * cap;

      // pull down
      goal_z = goal_z - (self.owner.v_angle_x * (self.ammo_shells * 0.01));
      cap = self.owner.origin_z + 28;
      if (goal_z < cap)
         goal_z = cap;
   }

   // increase height if getting under the player
   if (goal_z < owner_vec_z)
   {
      vtmp1 = goal; vtmp1_z = 0;
      vtmp2 = owner_vec; vtmp2_z = 0;
      cap = vlen( vtmp1 - vtmp2 );
      if (cap < 100)
      {
         goal_z = goal_z + ((100 - cap) * 0.6);
         if ( goal_z > owner_vec_z )
            goal_z = owner_vec_z;
      }
   }


   // clip for brushes

   traceline (owner_vec, goal, FALSE, self.owner);

   // pull a little forward, avoids most hang-ups along walls
   goal = trace_endpos + ( v_forward * 2 );

   // clip fade-back variable
   traceline( owner_vec, owner_vec - (v_forward * self.ammo_shells), FALSE, self.owner);
   if (trace_fraction < 1)
   {
      self.ammo_shells = vlen(trace_endpos - owner_vec);
      cap = fabs( self.owner.v_angle_x ) - 10;
      if (cap > 0)
         self.ammo_shells = self.ammo_shells + cap;
   }

   traceline (self.origin, goal, FALSE, self.owner );
   if (trace_fraction < 1)
   {
      // half it if blocked
      dir = normalize(goal - owner_vec);
      dist = vlen(goal - owner_vec) * 0.5;
      goal =  owner_vec + dir * dist;
   }

   // pad for floors and ceilings
   traceline (goal, goal + '0 0 6', FALSE, self.owner );
   if (trace_fraction < 1 ) goal = trace_endpos - '0 0 6';
   else
   {
      traceline (goal, goal - '0 0 6', FALSE, self.owner );
      if (trace_fraction < 1 ) goal = trace_endpos + '0 0 6';
   }

   self.angles = self.owner.angles;

   traceline (self.origin, owner_vec, FALSE, self.owner );
   if (trace_fraction < 1)
   {
      // vtmp1_z:  0 = LOS to head
      //          -1 = LOS to feet, but not head
      //          -2 = no LOS
      traceline (self.origin, self.owner.origin - '0 0 24', FALSE, self.owner );
      if (trace_fraction == 1)
         vtmp1_z = -1;
      else
         vtmp1_z = -2;
   }
   else
      vtmp1_z = 0;
   if (vtmp1_z > -2)
   {
      dir = normalize(goal - self.origin);
      dist = vlen(goal - self.origin);

      cap = dist * 0.16;

      if (cap > 5.2)
         self.velocity = dir * dist * 5.2;
      else if (cap > 1)
         self.velocity = dir * dist * cap;
      else
         self.velocity = dir * dist;

      if (vtmp1_z == -1)
      {
         self.velocity_z = self.velocity_z - 400;
      }

      // tighten up if owner running backwards
      if (f_f > 560)
      {
         cap = self.velocity_z;
         self.velocity = self.velocity * 2;
         self.velocity_z = cap;
      }

      if (! self.owner.velocity_z)
      {
         // rising/lowering lifts fix,
         // quick and dirty hack, player.velocity_z stays at zero when
         // moving on a lift, so check through an alternate route for the
         // condition and amplify the current z velocity.
         if (self.owner.origin_z != self.frags)
            //if (self.dmg &&  (self.owner.flags & FL_ONGROUND))
            // avoid landing on ground events that can happen between thinks
            // wierd setup here with the .impulse var, forces a skip forfirst occurance,
            // avoids logic catching vel_z same/org_z dif. instance thathappens when player
            // transitions between sloping to level ground while running,(also took care
            // of the same type of thing for landing after a jump)
               if (self.ammo_cells)
                  self.velocity_z = self.velocity_z * 3;
               else
                  self.ammo_cells = TRUE;
      }
      else if (self.ammo_cells)
         self.ammo_cells = FALSE;

      // try to avoid hangups common to ceiling clips when player
      // is running
      if(self.oldorigin == self.origin)
      {
         if( dist > 16 )
         {
            self.ammo_nails = self.ammo_nails + 1;
            if( self.ammo_nails > 2 )
            {
               self.ammo_nails = 0;
               self.velocity = '0 0 0';
               setorigin( self, goal );
            }
         }
         else
            self.ammo_nails = 0;
      }
   }
   else
   {
      self.velocity = '0 0 0';
      setorigin( self, goal );
   }

   if (!self.skin)
   // .skin is 1 if in a temp disable state
   {
      if (vlen(self.owner.origin - self.origin) < 30)
      {
         self.skin = 1;
         self.owner.view_ofs_z = 22;
         set_viewport( self.owner, self.owner);
      }
   }
   else
   {
      if (vlen(self.owner.origin - self.origin) > 39)
      {
         self.skin = 0;
         self.owner.view_ofs_z = -1;
         set_viewport(self.owner, self);
      }
   }


   // hacks (only) section :-)

   // keep flag clear so internal C won't drop movement checks
   if (self.flags & FL_ONGROUND)
      self.flags = self.flags - FL_ONGROUND;

   self.oldorigin = self.origin; // cam hang-up hack
   self.frags = self.owner.origin_z; // 'on lift' hack
   self.dmg = self.owner.flags & FL_ONGROUND; // 'on lift' hack
};

//-------------------------------------------------------------------------

// called by player only
// self is calling entity

void() toggle_camera =
{
   if (self.waterlevel)
      return;

   if (self.flags & FL_USING_CAMERA)
   {
      // will be noticed by next think
      // of player's chase camera entity
      self.flags = self.flags - FL_USING_CAMERA;
   }
   else
      start_chase(self, '0 0 0');

};


//------------------------------------------------------------------------------

void() camera_start =
{
   if (self.owner.flags & FL_USING_CAMERA)
      start_chase(self.owner, '0 0 0');

   if (self.owner.flags & FL_USING_TARGET)
   {
      self.owner.flags = self.owner.flags - FL_USING_TARGET;
      toggle_lasertarget(self.owner);
   }

   remove(self);
};

//-------------------------------------------------------------------------

void() initialise_camera =
{
   local entity e;

   e = spawn();
   e.owner = self;
   e.nextthink = time + 0.2;
   e.think = camera_start;
};


// opt:
// 0 = minus
// 1 = plus

void(float opt) camera_change_dist =
{
   local string val;

   if (!opt)
   {
      self.dest2_y = self.dest2_y - 2;
      if (self.dest2_y < 10)
         self.dest2_y = 10;
   }
   if (opt == 1)
      self.dest2_y = self.dest2_y + 2;

   val = ftos(self.dest2_y);

   sprint(self, "camera distance : ");
   sprint(self, val);
   sprint(self, "\n");
};


//-------------------------------------------------------------------------

// opt:
// 0 = decrement
// 1 = increment

void(float opt) camera_change_zmult =
{
   local float ofs;
   local string val;

   if (!opt)
   {
      self.dest2_z = self.dest2_z - 0.02;
      if (self.dest2_z < -0.2)
         self.dest2_z = -0.2;
   }
   else
      self.dest2_z = self.dest2_z + 0.02;

   sprint(self, "camera vertical offset : " );

   // convert and strip for display

   ofs = self.dest2_z * 50;
   ofs = rint(ofs);
   val = ftos(ofs);

   sprint(self, val);
   sprint(self, "\n");
};
