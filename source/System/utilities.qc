// utilitis.qc
/*---public---*/
// $VER: utilities.qc 1.52 © Karlos (04/10/1999)
// contains some handy maths and other functions not defined in QuakeC

// public function prototypes
float(vector from, vector onto) vdotprod;
float()                         crandom;
vector()                        wall_velocity;
string (float thing)            name_of_thing;
vector(float length)            vrandom;
void()                          entity_push;

// sound que stuff
void(entity e, float e_chan, string e_sound, float e_vol, float e_attn, float used, float max) sound_autolimit;
float sound1_used;
float sound2_used;
float sound3_used;
float sound4_used;

/*---private---*/

void() handle_sound_queue;
float sound_que_channels_allocated;
float sound_que_deallocate_time;
float SOUND_QUEUE_TIME = 0.02;
float MAX_QUEUED_SOUNDS = 16;

//======================================================================================
//
//   crandom() : returns a random float value from -1 to +1
//
//======================================================================================
float() crandom = {
    return 2*(random() - 0.5);
};


//======================================================================================
//
//   vrandom(float length) : returns a random vector of specified length
//
//======================================================================================
vector(float length) vrandom = {
    local vector v;
    v_x = crandom();
    v_y = crandom();
    v_z = crandom();
    return length * normalize(v);
};


//======================================================================================
//
//   vdotprod() : returns float dot product of vector AB . CD
//
//======================================================================================
float (vector from, vector onto) vdotprod = {
    return from_x * onto_x + from_y * onto_y + from_z * onto_z;
};


//======================================================================================
//
//   wall_velocity() : returns a vector for particles eminating from a surface
//
//======================================================================================
vector() wall_velocity = {
    local vector   vel;

    vel = normalize(self.velocity);
    vel = normalize(vel + v_up * (random() - 0.5) + v_right * (random() - 0.5));
    vel = vel + 2 * trace_plane_normal;
    vel = vel * 200;
    return vel;
};


//======================================================================================
//
//   sqrt(float sqr) : returns the float (positive) square root of the argument
//
//======================================================================================
//
//float(float sqr) sqrt =
//{
//   local float apr;
//   local float apr2;
//
//   if (num < 0.001)
//      return 0;
//
//   if (num>1)
//   {
//      apr = num;
//   }
//   else
//   {
//      apr = 1;
//   }
//
//   apr2 = apr * apr;
//
//   do
//   {
//      apr = (num + apr2) / (2 * apr);
//      apr2 = apr * apr;
//   } while ((fabs(apr2) - num) > (num * 0.001));
//   return apr;
//};

//======================================================================================
//
//   entity_push() : used for pushing things around
//
//======================================================================================
void() entity_push = {
    if (other.flags & FL_CANTPUSH) {
        // anything can push unless specified otherwise
        return;
    }
    if (other.movetype == MOVETYPE_FLYMISSILE) {
        self.velocity_x = other.velocity_x/(self.inertia*3);
        self.velocity_y = other.velocity_y/(self.inertia*3);
    }
    else {
        self.velocity_x = other.velocity_x/self.inertia;
        self.velocity_y = other.velocity_y/self.inertia;
    }
    if (self.flags & FL_ONGROUND) {
        self.flags = self.flags - FL_ONGROUND;
    }
    // try to allow clients/monsters standing on entity to walk
    // logic :: IF (other is client or monster) and (other not on ground) THEN >>>
    //          >>> set other on ground

    if ((other.flags & (FL_CLIENT | FL_MONSTER)) && (!(other.flags & FL_ONGROUND))) {
        other.flags = other.flags | FL_ONGROUND;
    }
};


//======================================================================================
//
//   name_of_thing() : returns the string name of am item
//
//======================================================================================
string (float thing) name_of_thing = {
    // returns the name of 'thing'

    if (thing == IT_AXE) {
        return "Axe";
    }
    else if (thing == IT_SHOTGUN) {
        return "Shotgun";
    }
    else if (thing == IT_SUPER_SHOTGUN) {
        return "Super Shotgun";
    }
    else if (thing == IT_NAILGUN) {
        return "Nailgun";
    }
    else if (thing == IT_SUPER_NAILGUN) {
        return "Super Nailgun";
    }
    else if (thing == IT_GRENADE_LAUNCHER) {
        return "Grenade Launcher";
    }
    else if (thing == IT_ROCKET_LAUNCHER) {
        return "Rocket Launcher";
    }
    else if (thing == IT_LIGHTNING) {
        return "Thunderbolt";
    }
    else if (thing == IT_EXTRA_WEAPON) {
        return "<undefined weapon>";
    }
    else if (thing == IT_SHELLS) {
        return "shells";
    }
    else if (thing == IT_NAILS) {
        return "nails";
    }
    else if (thing == IT_ROCKETS) {
        return "rockets";
    }
    else if (thing == IT_CELLS) {
        return "cells";
    }
    else if (thing == IT_ARMOR1) {
        return "Light Armour";
    }
    else if (thing == IT_ARMOR2) {
        return "Medium Armour";
    }
    else if (thing == IT_ARMOR3) {
        return "Heavy Armour";
    }
    else if (thing == IT_SUPERHEALTH) {
        return "Megahealth";
    }
    else if (thing == IT_KEY1) {
        return "Silver Key";
    }
    else if (thing == IT_KEY2) {
        return "Gold Key";
    }
    else if (thing == IT_INVISIBILITY) {
        return "Ring of Shadows";
    }
    else if (thing == IT_INVULNERABILITY) {
        return "Pentagram of Protection";
    }
    else if (thing == IT_SUIT) {
        return "Biohazard Suit";
    }
    else if (thing == IT_QUAD) {
        return "Quad Damage";
    }
    return "Thingy";
};


//======================================================================================
//
//   thing_to_model() : returns the string modelname of a thing, currently unused
//
//======================================================================================
//
//string (float thing) thing_to_model =
//{
//   // returns the model of 'thing'
//
//   if (thing == IT_AXE)
//      return "";
//   else if (thing == IT_SHOTGUN)
//      return ""
//   else if (thing == IT_SUPER_SHOTGUN)
//      return "progs/g_shot.mdl";
//   else if (thing == IT_NAILGUN)
//      return "progs/g_nail.mdl";
//   else if (thing == IT_SUPER_NAILGUN)
//      return "progs/g_nail2.mdl";
//   else if (thing == IT_GRENADE_LAUNCHER)
//      return "progs/g_rock.mdl";
//   else if (thing == IT_ROCKET_LAUNCHER)
//      return "progs/g_rock2.mdl";
//   else if (thing == IT_LIGHTNING)
//      return "progs/g_light.mdl";
//   else if (thing == IT_EXTRA_WEAPON)
//      return "";
//   else if (thing == IT_SHELLS)
//      return "maps/b_shell1.bsp";
//   else if (thing == IT_NAILS)
//      return "nails";
//   else if (thing == IT_ROCKETS)
//      return "rockets";
//   else if (thing == IT_CELLS)
//      return "cells";
//   else if (thing == IT_ARMOR1)
//      return "progs/armor.mdl";
//   else if (thing == IT_ARMOR2)
//      return "progs/armor.mdl";
//   else if (thing == IT_ARMOR3)
//      return "progs/armor.mdl";
//   else if (thing == IT_SUPERHEALTH)
//      return "maps/b_bh100.bsp";
//   else if (thing == IT_KEY1)
//      return "Silver Key";
//   else if (thing == IT_KEY2)
//      return "Gold Key";
//   else if (thing == IT_INVISIBILITY)
//      return "Ring of Shadows";
//   else if (thing == IT_INVULNERABILITY)
//      return "Pentagram of Protection";
//   else if (thing == IT_SUIT)
//      return "Biohazard Suit";
//   else if (thing == IT_QUAD)
//      return "Quad Damage";
//};
//




//======================================================================================
//
//   SOUND QUEUE FUNCTIONS
//
//======================================================================================

void(entity e, float e_chan, string e_sound, float e_vol, float e_attn, float used, float max) sound_autolimit = {
    local float scale_fact;

    if (!(effectflags & FX_SOUND_LIMIT)) {
        sound(e, e_chan, e_sound, e_vol, e_attn);
        return;
    }

    // if too mant sounds to be started already, just skip (at discretion of calling entity)
    if (used > max) {
        return;
    }
    else {
        scale_fact = e_vol / (1 + used);
        sound(e, e_chan, e_sound, scale_fact, e_attn);

        if (sound_que_channels_allocated < MAX_QUEUED_SOUNDS) {
            sound_que_channels_allocated = sound_que_channels_allocated + 1;
        }
        // sound_que_channels_allocated can be used by the calling entity to
        // prescaleounds based on a 'global' number of recently used sounds
    }
};

//======================================================================================

void() handle_sound_queue = {
    if (!(effectflags & FX_SOUND_LIMIT)) {
        return;
    }
    // called every frame from StartFrame()

    // clear the per-frame sound counters...
    sound1_used = sound2_used = sound3_used = sound4_used = 0;

    // handle the total qued channel allocation, deallocating a channel automatically
    // after intervals of SOUND_QUEUE_TIME, and only if > 1 channel in use...

    if (time > sound_que_deallocate_time && sound_que_channels_allocated > 1) {
        sound_que_deallocate_time    = time + SOUND_QUEUE_TIME;
        sound_que_channels_allocated = sound_que_channels_allocated - 1;
    }
};

