// weapons.qc
//=========================================================================================
//
//   WEAPONS
//      Modifications
//
//      Added axe sounds for hitting meat/metal, alive or otherwise... (ick)
//      Moved ImpulseCommands() to seperate file (impulse.qc)
//
//      Added weapon viewmodel check for camera view
//      Removed weaponkick while in camera view
//      Added support for guided missiles, using player's laser target
//         targeting should be unique to each client in multiplayer,
//         since missile tracks only the target that belongs to the same
//         owner that it does...
//
//      Added low ammo warnings
//      Added support for grappling hook, uses rocket launcher
//      Added reliability check for mikerules game
//
//=========================================================================================

/*---public---*/
// $VER: weapons.qc 2.18 Karlos '00 (22/1/2000)

// public function protoypes
// highlevel
void() W_Precache;
void() W_WeaponFrame;
void() W_SetCurrentAmmo;
void() W_Attack;
void() W_FireAxe;
void() W_FireShotgun;
void() W_FireSuperShotgun;
void(float ox) W_FireSpikes;
void() W_FireSuperSpikes;
void() W_FireGrenade;
void() W_ThrowGrenade;
void() W_FireRocket;
void() W_FireLightning;
void() W_Fire_Ion;
void() W_ChangeWeapon;
float() W_BestWeapon;
void() CycleWeaponCommand;
void() CycleWeaponReverseCommand;
void() toggle_guidedmissiles;

// lowlevel
void(float shotcount, vector dir, vector spread) FireBullets;
void(vector dir, vector spread) fire_machine_bullet;
void(float beam_energy, vector org, vector direction, entity whofired) ion_stream;
void() T_MissileTouch;
void(vector org, float dovisuals) missile_enginekick_fx;
void(vector p1, vector p2, entity from, float damage) LightningDamage;
void(vector org, vector dir) launch_spike;
void() spike_touch;
void() superspike_touch;
/*---private---*/

void(float damage, vector dir) TraceAttack;
void() ClearMultiDamage ;
void() ApplyMultiDamage ;
void(entity hit, float damage) AddMultiDamage;
void(float warn_limit) check_low_ammo;

void() missile_enginekick;
void() launch_rocket;
void() track_target;
void() ProjectileBurn;
void() GrenadeExplode;
void() GrenadeTouch;
float() W_CheckNoAmmo ;
float(entity targ) target_infront;

//========================================================================================

void(float warn_limit) check_low_ammo = {
    if (
        self.extraflags & CL_MESSAGEBIT &&
        ((self.currentammo == warn_limit) || (self.currentammo == warn_limit - 1))
    ) {
        sound(self, CHAN_AUTO, "misc/msg_warning.wav", 1, ATTN_NORM);
        centerprint(self, "low ammo warning\n");
    }
};

void() W_Precache = {
    // axe sounds
    precache_sound("weapons/ax1.wav");          // axe swooshes
    precache_sound("weapons/ax2.wav");
    precache_sound("weapons/ax3.wav");
    precache_sound("player/axhit1.wav");        // axe hit player
    precache_sound("player/axhit2.wav");        // axe hit world
    precache_sound("zombie/z_hit.wav");         // axe hit other meat
    precache_sound("weapons/armourhit1.wav");   // axe hit armour 1
    precache_sound("weapons/armourhit2.wav");   // axe hit armour 2
    precache_sound("weapons/armourhit3.wav");   // axe hit armour 3

    precache_sound("weapons/ion_cannon.wav");    // new gun
    precache_sound("weapons/rocket_reload.wav"); // new firing fx
    precache_sound("weapons/rocket.wav");        // rocket engine
    precache_sound("weapons/jam.wav");           // Weapon jam for Mikerules
    precache_sound("weapons/machinegun1.wav");
    precache_sound("weapons/machinegun2.wav");
    precache_sound("weapons/machinegun3.wav");

    // explosion sounds
    precache_sound("weapons/r_exp3.wav");       // used in c code
    precache_sound("weapons/explode.wav");      // karlos - air explosion
    precache_sound("weapons/w_explode.wav");    // karlos - underwater explosion
    precache_sound("weapons/rumble.wav");       // karlos - unattenuated rumble

    // ricochet sounds
    precache_sound("weapons/ric1.wav");         // ricochet (used in c code)
    precache_sound("weapons/ric2.wav");         // ricochet (used in c code)
    precache_sound("weapons/ric3.wav");         // ricochet (used in c code)
    precache_sound("weapons/tink1.wav");        // spikes tink (used in c code)

    // grenade bounce noises
    precache_sound("weapons/bounce1.wav");      // grenade bounce new
    precache_sound("weapons/bounce2.wav");      // grenade bounce extra
    precache_sound("weapons/bounce3.wav");      // grenade bounce extra

    precache_sound("weapons/grenade.wav");      // grenade launcher

    precache_sound("weapons/rocket1i.wav");     // spike gun
    precache_sound("weapons/guncock.wav");      // player shotgun
    precache_sound("weapons/spike2.wav");       // super spikes
    precache_sound("weapons/supershot.wav");    // super shotgun

    // temporary grappling hook noises
    precache_sound("shambler/smack.wav");
    precache_sound("blob/land1.wav");

    // final grapple sounds
    precache_sound("weapons/grapple_fire.wav");
    precache_sound("weapons/grapple_reset.wav");
    precache_sound("weapons/grapple_hit.wav");
    precache_sound("weapons/winch_start.wav");
    precache_sound("weapons/winch_motor.wav");
    precache_sound ("weapons/winch_stop.wav");
};

/*================
W_FireAxe
================*/
void() W_FireAxe = {
    local vector   source;
    local vector   org;

    local float    rvol;
    local float    r;

    makevectors(self.v_angle);
    source = self.origin + '0 0 16';
    traceline(source, source + v_forward*64, FALSE, self);
    if (trace_fraction == 1.0) {
        return;
    }
    org = trace_endpos - v_forward*4;

    if (trace_ent.takedamage) {
        trace_ent.axhitme   = 1;
        trace_ent.deathtype = "melee";
        sound(trace_ent, CHAN_AUX1, "zombie/z_hit.wav", 0.7 + (0.3 * random()), ATTN_NORM);
        SpawnBlood(org, VEC_ZERO, 20);
        T_Damage(trace_ent, self, self, 20);
    }
    else {
        // hit wall
        sound(self, CHAN_AUX1, "player/axhit2.wav", 0.7 + (0.3 * random()), ATTN_NORM);
        Net_TempEntity(org, TE_GUNSHOT);
    }
};

/*==============================================================================
   MULTI-DAMAGE
      Collects multiple small damages into a single damage
==============================================================================*/

void() ClearMultiDamage = {
    multi_ent    = world;
    multi_damage = 0;
};

void() ApplyMultiDamage = {
    if (!multi_ent) {
        return;
    }
    multi_ent.deathtype = "shot";
    T_Damage(multi_ent, self, self, multi_damage);
};

void(entity hit, float damage) AddMultiDamage = {
    if (!hit) {
        return;
    }
    if (hit != multi_ent) {
        ApplyMultiDamage();
        multi_damage = damage;
        multi_ent    = hit;
    }
    else {
        multi_damage = multi_damage + damage;
    }
};

/*==============================================================================

   BULLETS

==============================================================================*/

// TraceAttack -----------------------------------------------------------------
void(float damage, vector dir) TraceAttack = {
    local vector vel, org;

    vel = normalize(dir + v_up * crandom() + v_right * crandom());
    vel = vel + 2 * trace_plane_normal;
    vel = vel * 200;
    org = trace_endpos - dir*4;

    if (trace_ent.takedamage) {
        SpawnBlood(org, vel * 0.2, damage);
        AddMultiDamage(trace_ent, damage);
    }
    else {
        Net_TempEntity(org, TE_GUNSHOT);
    }
};

/*==============================================================================
   FireBullets

Used by shotgun, super shotgun, and enemy soldier firing
Go to the trouble of combining multiple pellets into a single damage call.
==============================================================================*/

void(float shotcount, vector dir, vector spread) FireBullets = {
    local vector direction;
    local vector src;

    makevectors(self.v_angle);

    src   = self.origin + v_forward*10;
    src_z = self.absmin_z + self.size_z * 0.7;

    ClearMultiDamage();
    while (shotcount > 0) {
        direction = dir + crandom() * spread_x * v_right + crandom() * spread_y * v_up;
        traceline(src, src + direction * 2048, FALSE, self);
        if (trace_fraction != 1.0) {
            TraceAttack(4, direction);
        }

        shotcount = shotcount - 1;
    }

    ApplyMultiDamage();
};

// fire_machine_bullet----------------------------------------------------------

void(vector dir, vector spread) fire_machine_bullet = {
    local vector direction, hitpoint, src;
    local float rsnd;

    // play a machinegun sound
    rsnd = random();
    if (rsnd < 0.3) {
        sound(self, CHAN_WEAPON, "weapons/machinegun1.wav", 1, ATTN_NORM);
    }
    else if (rsnd < 0.6) {
        sound(self, CHAN_WEAPON, "weapons/machinegun2.wav", 1, ATTN_NORM);
    }
    else {
        sound(self, CHAN_WEAPON, "weapons/machinegun3.wav", 1, ATTN_NORM);
    }

    makevectors(self.v_angle);
    src   = self.origin + v_forward*10;
    src_z = self.absmin_z + self.size_z * 0.7;

    direction = dir + crandom() * spread_x * v_right + crandom() * spread_y*v_up;
    traceline(src, src + direction * 2048, FALSE, self);

    if (trace_ent.takedamage) {
        trace_ent.deathtype = "bullet";
        SpawnBlood(trace_ent.origin, vrandom(4), 5);
        T_Damage(trace_ent, self, self, 2);
    }
    else {
        hitpoint = trace_endpos - direction * 4;
        Net_TempEntity(hitpoint, TE_SPIKE);
        //WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
        //WriteByte(MSG_BROADCAST, TE_SPIKE);
        //WriteCoord(MSG_BROADCAST, hitpoint_x);
        //WriteCoord(MSG_BROADCAST, hitpoint_y);
        //WriteCoord(MSG_BROADCAST, hitpoint_z);
    }
};


// W_FireShotgun-------------------------------------------------------------
void() W_FireShotgun =
{
    local vector dir;

    sound(self, CHAN_WEAPON, "weapons/guncock.wav", 1, ATTN_NORM);

    self.punchangle_x = -2 * (!(self.flags & FL_USING_CAMERA));
    self.currentammo  = self.ammo_shells = self.ammo_shells - 1;
    dir = aim(self, 100000);
    FireBullets(8, dir, '0.04 0.04 0');

    grapple_weapon_kick(dir, -10);
};


// W_FireSuperShotgun -------------------------------------------------------
void() W_FireSuperShotgun = {
    local vector dir;

    if (self.currentammo == 1) {
        W_FireShotgun();
        return;
    }

    sound(self, CHAN_WEAPON, "weapons/supershot.wav", 1, ATTN_NORM);

    self.punchangle_x = -4 * (!(self.flags & FL_USING_CAMERA));
    self.currentammo  = self.ammo_shells = self.ammo_shells - 2;
    dir = aim(self, 100000);
    FireBullets(18, dir, '0.14 0.08 0');

    if (deathmatch == 0) {
        AI_RadiusAlert(self, self, 400, FALSE, TRUE);
    }

    grapple_weapon_kick(dir, -30);
};

void() ProjectileBurn = {
    sound(self, CHAN_VOICE, "player/slimbrn2.wav", 1, ATTN_NORM);
    self.velocity  = VEC_ZERO;
    self.think     = SUB_Remove;
    self.nextthink = time + 1;
};

/*==============================================================================

   ROCKETS

==============================================================================*/

void() toggle_guidedmissiles = {
    if (!(self.flags & FL_USING_TARGET)) {
        sound(self, CHAN_ITEM, "misc/message2.wav", 1, ATTN_NORM);
        centerprint(self, "laser must be armed first\n");
        return;
    }
    else {
        if (self.flags & FL_USING_GUIDE) {
            sound(self, CHAN_ITEM, "misc/laser_deactivated.wav", 0.75, ATTN_NORM);
            self.flags = self.flags - FL_USING_GUIDE;
            centerprint(self, "laser guidance system deactivated\n");
        }
        else {
            sound(self, CHAN_ITEM, "misc/laser_activated.wav", 0.75, ATTN_NORM);
            self.flags = self.flags | FL_USING_GUIDE;
            centerprint(self, "laser guidance system activated\n");
        }
    }
};

void() T_MissileTouch = {
    local float damg;

    if (other == self.owner) {
        return;     // don't explode on owner
    }

    if (pointcontents(self.origin) == CONTENT_SKY) {
        remove(self);
        return;
    }

    if (pointcontents(self.origin) == CONTENT_LAVA) {
        ProjectileBurn();
        return;
    }

    damg = 100 + random()*20;

    // wake up monsters who see or hear it

    if (other.health) {
        other.deathtype = "radius_damage";
        if (other.classname == "monster_shambler") {
            damg = damg * 0.5;   // mostly immune
        }
        T_Damage(other, self, self.owner, damg );
    }

    // don't do radius damage to the other, because all the damage
    // was done in the impact
    T_RadiusDamage(self, self.owner, 120, other);
    if (deathmatch == 0) {
        AI_RadiusAlert(self, self.owner, 1000, TRUE, TRUE);
    }

    self.origin = self.origin - 8*normalize(self.velocity);
    BecomeExplosion();
};



// W_FireRocket ---------------------------------------------------------------
void() launch_rocket =
{
    local entity missile, mpuff;
    local vector dir;

    sound(self, CHAN_WEAPON, "weapons/rocket_reload.wav", 1, ATTN_NORM);

    self.currentammo  = self.ammo_rockets = self.ammo_rockets - 1;
    self.punchangle_x = -2 * (!(self.flags & FL_USING_CAMERA));
    missile           = spawn ();
    missile.owner     = self;
    missile.movetype  = MOVETYPE_FLYMISSILE;
    missile.solid     = SOLID_BBOX;
    missile.classname = "missile";

    makevectors(self.v_angle);
    missile.velocity = dir = aim(self, 1000);

    if ((self.flags & FL_USING_TARGET) && (self.flags & FL_USING_GUIDE)) {
        // guided - initial velocity is less
        // behaves like grenade untile engine kicks...

        missile.movetype   = MOVETYPE_BOUNCE;
        missile.velocity   = missile.velocity * 300;
        missile.velocity_z = missile.velocity_z + 200;
        missile.angles     = vectoangles(missile.velocity);
        missile.touch      = GrenadeTouch;
        missile.nextthink  = time + 0.5;
        missile.think      = missile_enginekick;

        setmodel(missile, "progs/grenade.mdl");
        setsize(missile, VEC_ZERO, VEC_ZERO);
        setorigin(missile, self.origin + v_forward * 8 + '0 0 16');

        grapple_weapon_kick(dir, -15);
    }
    else {
        // dumb but fast
        missile.velocity  = missile.velocity * 1000;
        missile.angles    = vectoangles(missile.velocity);
        missile.touch     = T_MissileTouch;
        missile.nextthink = time + 5;
        missile.think     = SUB_Remove;

        // Quick nolights patch - use grenade model if lights turned off...
        if (
            (effectflags & FX_LIGHTS) == FX_NO_GLOW ||
            (effectflags & FX_LIGHTS) == FX_NO_LIGHTS
        ) {
            setmodel(missile, "progs/grenade.mdl");
        }
        else {
            setmodel(missile, "progs/missile.mdl");
        }

        // do launch effect
        setsize(missile, VEC_ZERO, VEC_ZERO);
        setorigin(missile, self.origin + v_forward * 8 + '0 0 16');

        // do e_kick behind player
        missile_enginekick_fx(self.origin - v_forward * 20, TRUE);
        grapple_weapon_kick (dir, -45);
    }
};

void() W_FireRocket = {
    if (self.flags & FL_USING_GRAPPLE) {
        inv_grapple_fire();
    }
    else {
        launch_rocket();
    }
};

// missile engine effects.....
void() enginekick1  =  [0, enginekick2] { self.nextthink = time + 0.05; };
void() enginekick2  =  [1, enginekick3] {
    self.effects   = self.effects | (FX_FLASH & effectflags);
    self.nextthink = time + 0.05;
};

void() enginekick3  =  [2, enginekick4] {
    self.effects   = self.effects | (FX_FLASH & effectflags);
    self.nextthink = time + 0.1;
};

void() enginekick4  =  [3, enginekick5] { self.nextthink = time + 0.1; };
void() enginekick5  =  [4, enginekick6] { self.nextthink = time + 0.05; };
void() enginekick6  =  [5, enginekick7] { self.nextthink = time + 0.05; };
void() enginekick7  =  [0, enginekick8] {
    setmodel(self, "");
    self.nextthink = time + 0.1;
};

void() enginekick8  =  [0, SUB_Remove]{ };
void(float num_bubbles) ExplodeBubbles;


void(vector org, float dovisuals) missile_enginekick_fx = {
    // create a temprary explosion like entity to simulate engine ignition
    // and use it to play the rocket sound...

    local entity e_kick;

    e_kick          = spawn();
    e_kick.movetype = MOVETYPE_NOCLIP;
    e_kick.solid    = SOLID_NOT;
    e_kick.touch    = SUB_Null;

    // slowly rises
    e_kick.velocity = '0 0 20';

    setorigin(e_kick, org);
    setsize(e_kick, VEC_ZERO, VEC_ZERO);
    setmodel(e_kick, "progs/s_explod.spr");

    e_kick.nextthink = time + 0.05;
    e_kick.think     = enginekick1;
    sound (e_kick, CHAN_BODY, "weapons/rocket.wav", 1, ATTN_NORM);

    if (dovisuals) {
        // maybe whole function will be effect flag dependent...
        if (!(effectflags & FX_FAST_EXP)) {
            particle(e_kick.origin, VEC_ZERO, 75, 255);
        }
        if (effectflags & FX_SMART_EXP) {
            local float c;
            c = pointcontents(e_kick.origin);
            if (
                c == CONTENT_WATER ||
                c == CONTENT_SLIME
            ) {
                ExplodeBubbles(4);
            }
        }
    }
};


void () missile_enginekick = {
    missile_enginekick_fx(self.origin, TRUE);

    self.movetype = MOVETYPE_FLYMISSILE;

    if (effectflags & FX_GLOW) {
        setmodel (self, "progs/missile.mdl");
    }
    makevectors(self.owner.v_angle);
    self.velocity  = aim(self.owner, 1000);
    self.velocity  = self.velocity * 500;
    self.angles    = vectoangles(self.velocity);
    self.touch     = T_MissileTouch;
    self.nextthink = time + 0.1;
    self.think     = track_target;

    if (self.flags & FL_ONGROUND) {
        self.flags = self.flags - FL_ONGROUND;
    }
};

float(entity targ) target_infront = {
    local vector   vec;
    local float    dot;

    makevectors(self.angles);
    vec = normalize(targ.origin - self.origin);
    dot = vec * v_forward;

    if (dot > 0.4) {
        // raise this number for more specific infront
        return TRUE;
    }
    return FALSE;
};


void() track_target = {
    local vector dir, vtemp;

    if (
        !((self.owner.flags & FL_USING_TARGET) &&
        (self.owner.flags & FL_USING_GUIDE))
    ) {
        self.enemy     = world;
        self.nextthink = time + 5;
        self.think     = SUB_Remove;
    }
    else {
        if (target_infront(self.owner.laser_target_spot)) {
            self.enemy = self.owner.laser_target_spot;
        }
        else {
            self.enemy = world;
        }

        if (self.enemy != world) {
            // smoothly change direction
            vtemp          = self.enemy.origin;
            dir            = normalize(vtemp - self.origin);
            self.velocity  = (0.5 * self.velocity) + (dir * 400);
            self.angles    = vectoangles(self.velocity);
            self.nextthink = time + 0.1;
            self.think     = track_target;
        }
    }
};


/*===============================================================================

   LIGHTNING

===============================================================================*/

// LightningDamage--------------------------------------------------------------
void(vector p1, vector p2, entity from, float damage) LightningDamage = {
    local entity e1, e2;
    local vector f;

    f = p2 - p1;
    normalize(f);
    f_x = 0 - f_y;
    f_y = f_x;
    f_z = 0;
    f   = f*16;
    e1  = e2 = world;

    traceline(p1, p2, FALSE, self);
    if (trace_ent.takedamage) {
        particle(trace_endpos, '0 0 100', 225, damage*4);
        trace_ent.deathtype = "discharge";
        T_Damage(trace_ent, from, from, damage);
        if (self.classname == "player") {
            if (other.classname == "player") {
                trace_ent.velocity_z = trace_ent.velocity_z + 400;
            }
        }
    }
    e1 = trace_ent;

    traceline(p1 + f, p2 + f, FALSE, self);
    if (trace_ent != e1 && trace_ent.takedamage) {
        particle(trace_endpos, '0 0 100', 225, damage*4);
        T_Damage(trace_ent, from, from, damage);
    }

    e2 = trace_ent;
    traceline(p1 - f, p2 - f, FALSE, self);
    if (trace_ent != e1 && trace_ent != e2 && trace_ent.takedamage) {
        particle(trace_endpos, '0 0 100', 225, damage*4);
        T_Damage(trace_ent, from, from, damage);
    }
};


void() W_FireLightning = {
    local vector org;
    local float  cells;

    if (self.ammo_cells < 2) {
        self.weapon = W_BestWeapon();
        W_SetCurrentAmmo();
        return;
    }

    // explode if under water
    if (self.waterlevel > 1) {
        cells           = self.ammo_cells;
        self.ammo_cells = 0;
        W_SetCurrentAmmo();

        // big flash effect
        radius_flash(self.origin, 0.1);

        sound (self, CHAN_WEAPON, "weapons/w_explode.wav", 1, ATTN_NORM);
        T_RadiusDamage (self, self, 35*cells, world);
        return;
    }

    if (self.t_width < time) {
        sound(self, CHAN_WEAPON, "weapons/lhit.wav", 1, ATTN_NORM);
        self.t_width     = time + 0.4;
        self.currentammo = self.ammo_cells = self.ammo_cells - 2;
    }
    self.punchangle_x = -2 * (!(self.flags & FL_USING_CAMERA));

    check_low_ammo(30);

    org = self.origin + '0 0 16';

    traceline(org, org + v_forward*600, TRUE, self);

    WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
    WriteByte(MSG_BROADCAST, TE_LIGHTNING2);
    WriteEntity(MSG_BROADCAST, self);
    WriteCoord(MSG_BROADCAST, org_x);
    WriteCoord(MSG_BROADCAST, org_y);
    WriteCoord(MSG_BROADCAST, org_z);
    WriteCoord(MSG_BROADCAST, trace_endpos_x);
    WriteCoord(MSG_BROADCAST, trace_endpos_y);
    WriteCoord(MSG_BROADCAST, trace_endpos_z);

    LightningDamage(self.origin, trace_endpos + v_forward * 4, self, 30);
};

//=============================================================================

//##

void(vector loc, vector dir, float rgb, float ramp) draw_ions = {
    local vector vel;
    local float ion_count;

    vel       = vrandom(2);
    ion_count = rint(8 + 8 * random());
     // core particles
    particle(loc, 5 * dir, 15, 6);
    // colour particles
    particle(loc, vel, rgb + (ion_count * ramp), ion_count);
};

void() ion_end = {
    T_RadiusDamage(self, self.owner, 30, self.owner);
    if (deathmatch == 0) {
        AI_RadiusAlert(self, self.owner, 250, TRUE, FALSE);
    }
    sound (self, CHAN_WEAPON, "shared/frying.wav", 1, ATTN_NORM);
    remove(self);
};


void(float beam_energy, vector org, vector direction, entity whofired) ion_stream = {
    local vector loc, to, dir;
    local float beam_dist, beam_length;
    local entity s;

    traceline(org, org + 4000 * direction, TRUE, self);

    to  = 0.1 * org + 0.9 * trace_endpos;
    dir = normalize(to - org);

    // do teleport style flash at end point
    Net_TempEntity(to, TE_TELEPORT);
    //WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
    //WriteByte(MSG_BROADCAST, TE_TELEPORT);
    //WriteCoord(MSG_BROADCAST, to_x);
    //WriteCoord(MSG_BROADCAST, to_y);
    //WriteCoord(MSG_BROADCAST, to_z);

    radius_flash(to, 0.4);

    s           = spawn ();
    s.origin    = to;
    s.owner     = whofired;
    s.think     = ion_end;
    s.nextthink = time + 0.01;

    to = to + 100 * dir;

    beam_length = vlen(to - org);
    if (beam_length > 3000) {
        beam_length = 3000;
    }

    // give user a big back-kick
    if (self.flags & FL_ONGROUND) {
        self.flags = self.flags - (self.flags & FL_ONGROUND);
        self.velocity_z = self.velocity_z + 16;
    }
    self.velocity = self.velocity + (-50 * dir);

    sound(self, CHAN_WEAPON, "weapons/ion_cannon.wav", 1, ATTN_NORM);
    beam_dist = 50;     // initial beam distance

    // Set up the beam colour
    local float rgb, ramp;
    if (self.ion_colour == ION_CYAN_IDX) {
        rgb  = ION_CYAN;
        ramp = 1;
    }
    else if (self.ion_colour == ION_RED_IDX) {
        rgb  = ION_RED;
        ramp = 1;
    }
    else if (self.ion_colour == ION_GREEN_IDX) {
        rgb  = ION_GREEN;
        ramp = 1;
    }
    else if (self.ion_colour == ION_YELLOW_IDX) {
        rgb  = ION_YELLOW;
        ramp = -1;
    }
    else if (self.ion_colour == ION_MAGENTA_IDX) {
        rgb  = ION_MAGENTA;
        ramp = -1;
    }
    else if (self.ion_colour == ION_BLUE_IDX) {
        rgb  = ION_BLUE;
        ramp = -1;
    }
    else {
        // just use white
        rgb  = ION_WHITE;
        ramp = 1;
    }

    while (beam_dist < beam_length) {
        loc = org + (beam_dist * dir);
        draw_ions(loc, dir, rgb, ramp);
        beam_dist = beam_dist + 125;

        traceline(org, to, FALSE, self);
        if (trace_ent != self && trace_ent.takedamage && beam_energy > 1) {
            trace_ent.deathtype = "ion";

            // players only get half damage from a monsters ion cannon
            if (trace_ent.flags & FL_CLIENT && self.flags & FL_MONSTER) {
                T_Damage(trace_ent, self, self, (0.15 * beam_energy));
            }
            else {
                T_Damage(trace_ent, self, self, (0.5 * beam_energy));
            }

            // Damaged targets absorb a fraction of the energy
            beam_energy = 0.5 * beam_energy;
            if (trace_ent.flags & (FL_MONSTER | FL_CLIENT)) {
                trace_ent.effects    = trace_ent.effects | (FX_FLASH & effectflags);

                // give em a right big kick !
                trace_ent.flags      = trace_ent.flags - (trace_ent.flags & FL_ONGROUND);
                trace_ent.velocity_z = trace_ent.velocity_z + 20;
                trace_ent.velocity   = (0.5 * trace_ent.velocity) + 3 * beam_energy * dir;
            }
        }
    }
};

void() W_Fire_Ion = {
    local float beam_energy;

    if (self.ammo_cells < 10) {
        self.flags  = self.flags - (self.flags & FL_USING_ION);
        self.weapon = W_BestWeapon();
        W_SetCurrentAmmo();
        return;
    }

    self.currentammo  = self.ammo_cells = self.ammo_cells - 10;
    beam_energy       = 200 + 50 * random();
    self.punchangle_x = -5 * (!(self.flags & FL_USING_CAMERA));
    makevectors(self.v_angle);
    ion_stream(beam_energy, self.origin + '0 0 16', v_forward, self);
};


//=============================================================================

void() GrenadeExplode = {
    T_RadiusDamage(self, self.owner, 120, world);

    // wake up monsters
    if (deathmatch == 0) {
        AI_RadiusAlert(self, self.owner, 800, TRUE, TRUE);
    }
    BecomeExplosion();
};

void() GrenadeTouch = {
    local float r;

    if (other == self.owner) {
        return;     // don't explode on owner
    }

    r = pointcontents(self.origin);

    if (r == CONTENT_LAVA) {
        ProjectileBurn();
        return;
    }

    if (other.takedamage == DAMAGE_AIM) {
        GrenadeExplode();
        return;
    }

    if (
        r == CONTENT_WATER ||
        r == CONTENT_SLIME
    ) {
        sound(self, CHAN_VOICE, "weapons/bounce1.wav", 0.5 + (0.5 * random()), ATTN_IDLE);
    }
    else {
        // wake up monsters to grenade
        if (deathmatch == 0) {
            AI_RadiusAlert(self, self.owner, 400, TRUE, TRUE);
        }

        r = random(); // random bounce sounds
        if (r < 0.4) {
            sound(self, CHAN_VOICE, "weapons/bounce1.wav", 0.6 + (0.3 * random()), ATTN_NORM);
        }
        else if (r < 0.7) {
            sound(self, CHAN_BODY, "weapons/bounce2.wav", 0.6 + (0.3 * random()), ATTN_NORM);
        }
        else {
            sound(self, CHAN_WEAPON, "weapons/bounce3.wav", 0.6 + (0.3 * random()), ATTN_NORM);
        }
    }

    if (self.velocity == VEC_ZERO) {
        self.avelocity = VEC_ZERO;
    }
};

// W_FireGrenade ---------------------------------------------------------------
void() W_FireGrenade = {
    local entity missile;
    self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;

    sound(self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);

    self.punchangle_x = -2 * (!(self.flags & FL_USING_CAMERA));

    missile           = spawn ();
    missile.owner     = self;
    missile.movetype  = MOVETYPE_BOUNCE;
    missile.solid     = SOLID_BBOX;
    missile.classname = "grenade";
    missile.flags     = missile.flags | FL_CANTPUSH;
    // set missile speed

    makevectors (self.v_angle);

    if (self.v_angle_x) {
        missile.velocity = v_forward * 600 + v_up * 200 + crandom() * v_right * 10 + crandom()*v_up*10;
    }
    else {
        missile.velocity = aim(self, 10000);
        missile.velocity = missile.velocity * 600;
        missile.velocity_z = 200;
    }

    missile.avelocity = '300 300 300';
    missile.angles    = vectoangles(missile.velocity);
    missile.touch     = GrenadeTouch;

    // set missile duration
    missile.nextthink = time + 2.5;
    missile.think     = GrenadeExplode;

    setmodel(missile, "progs/grenade.mdl");
    setsize(missile, VEC_ZERO, VEC_ZERO);
    setorigin(missile, self.origin);

    grapple_weapon_kick(aim(self, 1000), -10);
};

void() W_ThrowGrenade = {
    local entity missile;
    local float r;

    if (
        (self.ammo_rockets == 0) ||
        time < self.hand_grenade_time
    ) {
        return;
    }

    if (self.flags & FL_USING_CAMERA) {
        if ((self.extraflags & CL_CENTREHANDED) == CL_LEFTHANDED) {
            player_gren_lf1();
        }
        else {
            player_gren_rt1();
        }
    }

    self.ammo_rockets      = self.ammo_rockets - 1;
    self.hand_grenade_time = time + 1.2;

    r = random();
    if (r < 0.33) {
        self.noise = "weapons/ax1.wav";
    }
    else if (r < 0.66) {
        self.noise = "weapons/ax2.wav";
    }
    else {
        self.noise = "weapons/ax3.wav";
    }

    sound(self, CHAN_WEAPON, self.noise, 1, ATTN_NORM);

    // do throw effort noise

    r = random();

    if (!self.gender) {
        if (r < 0.6) {
            self.noise = "player/land.wav";
        }
        else {
            self.noise = "player/plyrjmp8.wav";
        }
    }
    else {
        if (r < 0.6) {
            self.noise = "f_player/land.wav";
        }
        else {
            self.noise = "f_player/plyrjmp8.wav";
        }
    }

    sound(self, CHAN_VOICE, self.noise, 0.6, ATTN_NORM);

    self.punchangle_x = -1 * (!(self.flags & FL_USING_CAMERA));

    missile           = spawn();
    missile.owner     = self;
    missile.movetype  = MOVETYPE_BOUNCE;
    missile.solid     = SOLID_BBOX;
    missile.classname = "grenade";
    missile.flags     = missile.flags | FL_CANTPUSH;
    // set missile speed

    makevectors(self.v_angle);

    if (self.v_angle_x) {
        missile.velocity = v_forward * (400 + 100*random());
        missile.velocity = missile.velocity + v_up * (140 + 40 * random());
        missile.velocity = missile.velocity + v_right * (50 * crandom());
    }
    else {
        missile.velocity = aim(self, 5000);
        missile.velocity = missile.velocity * (400 + 100 * random());
        missile.velocity_z = 100 + random() * 75;
    }

    missile.avelocity = '400 400 400';
    missile.angles    = vectoangles(missile.velocity);

    // all projectiles should have at least their owner's velocity at the
    // time of launch - what with relativity, n' all that ;)

    missile.velocity = missile.velocity + 0.1*self.velocity;
    missile.touch    = GrenadeTouch;

    // set missile duration
    missile.nextthink = time + 2.5;
    missile.think     = GrenadeExplode;

    setmodel(missile, "progs/grenade.mdl");
    setsize(missile, VEC_ZERO, VEC_ZERO);

    if ((self.extraflags & CL_CENTREHANDED) == CL_LEFTHANDED) {
        r = 10;
    }
    else {
        r = -10;
    }

    setorigin(missile, self.origin + v_up * 10 + v_right * r);

    grapple_weapon_kick (aim(self, 1000), -4);
};

//=============================================================================


/*=============================================================================
   launch_spike

      Used for both player, hellknight and scragg
=============================================================================*/
void(vector org, vector dir) launch_spike = {
    newmis           = spawn ();
    newmis.owner     = self;
    newmis.movetype  = MOVETYPE_FLYMISSILE;
    newmis.solid     = SOLID_BBOX;
    newmis.angles    = vectoangles(dir);
    newmis.touch     = spike_touch;
    newmis.classname = "spike";
    newmis.think     = SUB_Remove;
    newmis.nextthink = time + 4;

    setmodel(newmis, "progs/spike.mdl");
    setsize(newmis, VEC_ZERO, VEC_ZERO);
    setorigin(newmis, org);
    newmis.velocity = dir * 1000;
};

void() W_FireSuperSpikes = {
    local vector   dir;
    local entity   old;

    sound(self, CHAN_WEAPON, "weapons/spike2.wav", 1, ATTN_NORM);
    self.attack_finished = time + 0.2;
    self.currentammo     = self.ammo_nails = self.ammo_nails - 2;
    dir                  = aim(self, 1000);
    launch_spike(self.origin + '0 0 16', dir);

    newmis.touch = superspike_touch;
    setmodel(newmis, "progs/s_spike.mdl");
    setsize(newmis, VEC_ZERO, VEC_ZERO);
    self.punchangle_x = -2 * (!(self.flags & FL_USING_CAMERA));

    grapple_weapon_kick(dir, -10);
};

void(float ox) W_FireSpikes = {
    local vector   dir;
    local entity   old;

    check_low_ammo(20);

    makevectors (self.v_angle);

    if (self.ammo_nails >= 2 && self.weapon == IT_SUPER_NAILGUN) {
        W_FireSuperSpikes();
        return;
    }

    if (self.ammo_nails < 1) {
        self.weapon = W_BestWeapon ();
        W_SetCurrentAmmo();
        return;
    }

    sound(self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
    self.attack_finished = time + 0.2;
    self.currentammo     = self.ammo_nails = self.ammo_nails - 1;
    dir                  = aim(self, 1000);
    launch_spike(self.origin + '0 0 16' + v_right*ox, dir);

    self.punchangle_x = -2 * (!(self.flags & FL_USING_CAMERA));
    grapple_weapon_kick (dir, -5);
};

void() spike_touch = {
    local float rand;
    if (other == self.owner) {
        return;
    }

    if (other.solid == SOLID_TRIGGER) {
        return;  // trigger field, do nothing
    }

    if (pointcontents(self.origin) == CONTENT_SKY) {
        remove(self);
        return;
    }

    // hit something that bleeds
    if (other.takedamage) {
        spawn_touchblood(9);
        other.deathtype = "projectile";
        T_Damage(other, self, self.owner, 9);
    }
    else {
        WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);

        if (self.classname == "wizspike") {
            WriteByte(MSG_BROADCAST, TE_WIZSPIKE);
        }
        else if (self.classname == "knightspike") {
            WriteByte(MSG_BROADCAST, TE_KNIGHTSPIKE);
        }
        else {
            WriteByte(MSG_BROADCAST, TE_SPIKE);
        }

        WriteCoord(MSG_BROADCAST, self.origin_x);
        WriteCoord(MSG_BROADCAST, self.origin_y);
        WriteCoord(MSG_BROADCAST, self.origin_z);
    }
    if (deathmatch == 0) {
        AI_RadiusAlert(self, self.owner, 100, FALSE, TRUE);
    }
    remove(self);
};

void() superspike_touch = {
    local float rand;
    if (other == self.owner) {
        return;
    }

    if (other.solid == SOLID_TRIGGER) {
        return;  // trigger field, do nothing
    }

    if (pointcontents(self.origin) == CONTENT_SKY) {
        remove(self);
        return;
    }

    // hit something that bleeds
    if (other.takedamage) {
        spawn_touchblood(18);
        other.deathtype = "projectile";
        T_Damage(other, self, self.owner, 18);
    }
    else {
        Net_TempEntity(self.origin, TE_SUPERSPIKE);
    }
    if (deathmatch == 0) {
        AI_RadiusAlert(self, self.owner, 100, FALSE, TRUE);
    }

    remove(self);
};


/*===============================================================================

   PLAYER WEAPON USE

===============================================================================*/

void() W_SetCurrentAmmo = {
    local float weapon_damage;
    local string screenmessage, ammocount, reliability;

    player_run();    // get out of any weapon firing states
    self.items = self.items - ( self.items & (IT_SHELLS | IT_NAILS | IT_ROCKETS | IT_CELLS) );

    if (self.weapon == IT_AXE) {
        weapon_damage    = 0;
        self.currentammo = 0;
        self.weaponmodel = "progs/v_axe.mdl";
        self.weaponframe = 0;
        screenmessage    = "axe selected\n";
    }
    else if (self.weapon == IT_SHOTGUN) {
        weapon_damage    = self.weapon_01_damage;
        self.currentammo = self.ammo_shells;
        self.weaponmodel = "progs/v_shot.mdl";
        self.weaponframe = 0;
        self.items       = self.items | IT_SHELLS;
        screenmessage    = "shotgun selected\n";
    }
    else if (self.weapon == IT_SUPER_SHOTGUN) {
        weapon_damage    = self.weapon_02_damage;
        self.currentammo = self.ammo_shells;
        self.weaponmodel = "progs/v_shot2.mdl";
        self.weaponframe = 0;
        self.items       = self.items | IT_SHELLS;
        screenmessage    = "super shotgun selected\n";
    }
    else if (self.weapon == IT_NAILGUN) {
        weapon_damage    = self.weapon_03_damage;
        self.currentammo = self.ammo_nails;
        self.weaponmodel = "progs/v_nail.mdl";
        self.weaponframe = 0;
        self.items       = self.items | IT_NAILS;
        screenmessage    = "nailgun selected\n";
    }
    else if (self.weapon == IT_SUPER_NAILGUN) {
        weapon_damage    = self.weapon_04_damage;
        self.currentammo = self.ammo_nails;
        self.weaponmodel = "progs/v_nail2.mdl";
        self.weaponframe = 0;
        self.items       = self.items | IT_NAILS;
        screenmessage    = "super nailgun selected\n";
    }
    else if (self.weapon == IT_GRENADE_LAUNCHER) {
        weapon_damage    = self.weapon_05_damage;
        self.currentammo = self.ammo_rockets;
        self.weaponmodel = "progs/v_rock.mdl";
        self.weaponframe = 0;
        self.items       = self.items | IT_ROCKETS;
        screenmessage    = "grenade launcher selected\n";
    }
    else if (self.weapon == IT_ROCKET_LAUNCHER) {
        weapon_damage    = self.weapon_06_damage;
        self.currentammo = self.ammo_rockets;
        self.weaponmodel = "progs/v_rock2.mdl";
        self.weaponframe = 0;
        self.items       = self.items | IT_ROCKETS;
        if (self.flags & FL_USING_GRAPPLE) {
            screenmessage = "grappling hook selected\n";
        }
        else {
            screenmessage = "rocket launcher selected\n";
        }
    }
    else if (self.weapon == IT_LIGHTNING) {
        weapon_damage    = self.weapon_07_damage;
        self.currentammo = self.ammo_cells;
        self.weaponmodel = "progs/v_light.mdl";
        self.weaponframe = 0;
        self.items       = self.items | IT_CELLS;
        if (self.flags & FL_USING_ION) {
            screenmessage = "ion cannon selected\n";
        }
        else {
            screenmessage = "thunderbolt selected\n";
        }
    }
    else {
        self.currentammo = 0;
        self.weaponmodel = "";
        self.weaponframe = 0;
    }

    if (
        ( (cvar("viewsize") > 110) || self.extraflags & CL_MESSAGEBIT) &&
        (self.noise4 != screenmessage)
    ) {
        // do fullscreen message when
        // 1) viewsize too big to see info bar - always
        // 2) player is using fullscreenmessage flag - optional

        centerprint (self, screenmessage);

        if (self.currentammo) {
            ammocount = ftos(self.currentammo);
            sprint2(self, "current ammo : ", ammocount);
        }

        if (mikerules && skill < 2 && self.weapon != IT_AXE) {
            // print weapon efficiency in easy - normal skill
            reliability = ftos(100 - 5 * weapon_damage); // in percent
            sprint3(self, ", oe : ", reliability, " %");
        }
        sprint(self, "\n");
        // store old message to avoid repeats.
        // use self.noise4, which is unused for player entities
        self.noise4 = screenmessage;
    }

    // disable model in chase view
    if (self.flags & FL_USING_CAMERA) {
        self.weaponmodel = "";
    }
};

float() W_BestWeapon = {
    local float it;

    it = self.items;
    if (self.waterlevel <= 1 && self.ammo_cells >= 2 && (it & IT_LIGHTNING) ) {
        return IT_LIGHTNING;
    }

    if (self.ammo_nails >= 2 && (it & IT_SUPER_NAILGUN) ) {
        return IT_SUPER_NAILGUN;
    }

    if (self.ammo_shells >= 2 && (it & IT_SUPER_SHOTGUN) ) {
        return IT_SUPER_SHOTGUN;
    }

    if (self.ammo_nails >= 1 && (it & IT_NAILGUN) ) {
        return IT_NAILGUN;
    }

    if (self.ammo_shells >= 1 && (it & IT_SHOTGUN) ) {
        return IT_SHOTGUN;
    }
    return IT_AXE;
};

float() W_CheckNoAmmo = {
    if (self.currentammo > 0) {
        return TRUE;
    }

    if (self.weapon == IT_AXE) {
        return TRUE;
    }

    self.weapon = W_BestWeapon();

    W_SetCurrentAmmo();

    // drop the weapon down
    return FALSE;
};

//===========================================================================
//
//   W_Attack : An attack impulse can be triggered now
//
//===========================================================================

void() W_Attack = {
    local float r;

    if (!W_CheckNoAmmo()) {
        return;
    }

    makevectors(self.v_angle);         // calculate forward angle for velocity
    self.show_hostile = time + 1.5;     // wake monsters up

    if (self.weapon == IT_AXE) {
        // use random axe sounds (1 of 3)

        r = random();
        if (r < 0.33) {
            self.noise = "weapons/ax1.wav";
        }
        else if (r < 0.66) {
            self.noise = "weapons/ax2.wav";
        }
        else {
            self.noise = "weapons/ax3.wav";
        }

        sound(self, CHAN_WEAPON, self.noise, 0.6 + (0.4 * random()), ATTN_NORM);


        // use random axe anim (1 of 4)

        r = random();
        if (r < 0.25) {
            player_axe1();
        }
        else if (r < 0.5) {
            player_axeb1();
        }
        else if (r < 0.75) {
            player_axec1();
        }
        else {
            player_axed1();
        }

        self.attack_finished = time + 0.5;
    }
    else if (self.weapon == IT_SHOTGUN) {
        if (check_weapon_jam(0.5, self.weapon_01_damage)) {
            return;
        }

        player_shot1();
        W_FireShotgun();
        check_low_ammo(20);
        self.attack_finished = time + 0.5;
    }
    else if (self.weapon == IT_SUPER_SHOTGUN) {
        if (check_weapon_jam(0.7, self.weapon_02_damage)) {
            return;
        }

        player_shot1();
        W_FireSuperShotgun();
        check_low_ammo(20);
        self.attack_finished = time + 0.7;
    }
    else if (self.weapon == IT_NAILGUN) {
        if (check_weapon_jam(0.5, self.weapon_03_damage)) {
            return;
        }

        player_nail1();
    }
    else if (self.weapon == IT_SUPER_NAILGUN) {
        if (check_weapon_jam(0.5, self.weapon_04_damage)) {
            return;
        }

        player_nail1();
    }
    else if (self.weapon == IT_GRENADE_LAUNCHER) {
        if (check_weapon_jam(0.6, self.weapon_05_damage)) {
            return;
        }

        player_rocket1();
        W_FireGrenade();
        check_low_ammo(10);
        self.attack_finished = time + 0.6;
    }
    else if (self.weapon == IT_ROCKET_LAUNCHER) {
        if (check_weapon_jam(0.8, self.weapon_06_damage)) {
            return;
        }

        player_rocket1();
        W_FireRocket();
        check_low_ammo(10);
        self.attack_finished = time + 0.8;
    }
    else if (self.weapon == IT_LIGHTNING) {
        if (check_weapon_jam(0.7, self.weapon_07_damage)) {
            return;
        }

        if (self.flags & FL_USING_ION) {
            // ion cannon
            player_ion1();
            W_Fire_Ion();
            check_low_ammo(48);
            self.attack_finished = time + 1;
        }
        else {
            // thunderbolt
            player_light1();
            self.attack_finished = time + 0.2;
            radius_flash(self.origin, 0.3);
            sound (self, CHAN_AUTO, "weapons/lstart.wav", 1, ATTN_NORM);
        }
    }
};


// W_ChangeWeapon -----------------------------------------------------------
void() W_ChangeWeapon = {
    local float it, am, fl;

    it = self.items;
    am = 0;

    if (self.impulse == 1) {
        fl = IT_AXE;
    }
    else if (self.impulse == 2) {
        fl = IT_SHOTGUN;
        if (self.ammo_shells < 1) {
            am = 1;
        }
    }
    else if (self.impulse == 3) {
        fl = IT_SUPER_SHOTGUN;
        if (self.ammo_shells < 2) {
            am = 1;
        }
    }
    else if (self.impulse == 4) {
        fl = IT_NAILGUN;
        if (self.ammo_nails < 1) {
            am = 1;
        }
    }
    else if (self.impulse == 5) {
        fl = IT_SUPER_NAILGUN;
        if (self.ammo_nails < 2) {
            am = 1;
        }
    }
    else if (self.impulse == 6) {
        fl = IT_GRENADE_LAUNCHER;
        if (self.ammo_rockets < 1) {
            am = 1;
        }
    }
    else if (self.impulse == 7) {
        // toggle grapple modes - only if last weapon was rocket or grapple already
        if (self.weapon == IT_ROCKET_LAUNCHER) {
            if (self.flags & FL_USING_GRAPPLE) {
                self.flags = self.flags - FL_USING_GRAPPLE;
                if ( (!(self.extraflags & CL_MESSAGEBIT)) && cvar("viewsize") < 120) {
                    sprint(self, "Rocket Launcher\n");
                }
            }
            else {
                self.flags = self.flags | FL_USING_GRAPPLE;
                if ( (!(self.extraflags & CL_MESSAGEBIT)) && cvar("viewsize") < 120) {
                    sprint(self, "Grappling Hook\n");
                }
            }
        }

        fl = IT_ROCKET_LAUNCHER;
        if (self.ammo_rockets < 1) {
            am = 1;
        }
    }
    else if (self.impulse == 8) {
        // toggle lighting / ion cannon modes
        if (self.weapon == IT_LIGHTNING) {
            if (self.flags & FL_USING_ION) {
                self.flags = self.flags - FL_USING_ION;
                if ( (!(self.extraflags & CL_MESSAGEBIT)) && cvar("viewsize") < 120) {
                    sprint(self, "Thunderbolt\n");
                }
            }
            else {
                self.flags = self.flags | FL_USING_ION;
                if ( (!(self.extraflags & CL_MESSAGEBIT)) && cvar("viewsize") < 120) {
                    sprint(self, "Ion Cannon\n");
                }
            }
        }

        fl = IT_LIGHTNING;
        if (self.ammo_cells < 1) {
            am = 1;
        }
    }

    self.impulse = 0;
    if (!(self.items & fl)) {
        // don't have the weapon or the ammo
        sprint(self, "no weapon.\n");
        return;
    }

    if (am) {
        // don't have the ammo
        sprint(self, "no ammo for this weapon.\n");
        return;
    }

    // set weapon, set ammo
    self.weapon = fl;
    W_SetCurrentAmmo();
};


//============================================================================
//
//   CycleWeaponCommand : Go to the next weapon with ammo
//
//============================================================================
void() CycleWeaponCommand = {
    local float it, am;

    it = self.items;
    self.impulse = 0;

    while (1)
    {
        am = 0;

        if (self.weapon == IT_LIGHTNING)
        {
            self.weapon = IT_AXE;
        }
        else if (self.weapon == IT_AXE)
        {
            self.weapon = IT_SHOTGUN;
            if (self.ammo_shells < 1)
                am = 1;
        }
        else if (self.weapon == IT_SHOTGUN)
        {
            self.weapon = IT_SUPER_SHOTGUN;
            if (self.ammo_shells < 2)
                am = 1;
        }
        else if (self.weapon == IT_SUPER_SHOTGUN)
        {
            self.weapon = IT_NAILGUN;
            if (self.ammo_nails < 1)
                am = 1;
        }
        else if (self.weapon == IT_NAILGUN)
        {
            self.weapon = IT_SUPER_NAILGUN;
            if (self.ammo_nails < 2)
                am = 1;
        }
        else if (self.weapon == IT_SUPER_NAILGUN)
        {
            self.weapon = IT_GRENADE_LAUNCHER;
            if (self.ammo_rockets < 1)
                am = 1;
        }
        else if (self.weapon == IT_GRENADE_LAUNCHER)
        {
            self.weapon = IT_ROCKET_LAUNCHER;
            if (self.ammo_rockets < 1)
                am = 1;
        }
        else if (self.weapon == IT_ROCKET_LAUNCHER)
        {
            self.weapon = IT_LIGHTNING;
            if (self.ammo_cells < 1)
                am = 1;
        }

        if ( (it & self.weapon) && am == 0)
        {
            W_SetCurrentAmmo ();
            return;
        }
    }
};

//==========================================================================
//
//   CycleWeaponReverseCommand : Go to the prev weapon with ammo
//
//==========================================================================
void() CycleWeaponReverseCommand = {
    local float it, am;

    it           = self.items;
    self.impulse = 0;

    while (1) {
        am = 0;

        if (self.weapon == IT_LIGHTNING) {
            self.weapon = IT_ROCKET_LAUNCHER;
            if (self.ammo_rockets < 1) {
                am = 1;
            }
        }
        else if (self.weapon == IT_ROCKET_LAUNCHER) {
            self.weapon = IT_GRENADE_LAUNCHER;
            if (self.ammo_rockets < 1) {
                am = 1;
            }
        }
        else if (self.weapon == IT_GRENADE_LAUNCHER) {
            self.weapon = IT_SUPER_NAILGUN;
            if (self.ammo_nails < 2) {
                am = 1;
            }
        }
        else if (self.weapon == IT_SUPER_NAILGUN) {
            self.weapon = IT_NAILGUN;
            if (self.ammo_nails < 1) {
                am = 1;
            }
        }
        else if (self.weapon == IT_NAILGUN) {
            self.weapon = IT_SUPER_SHOTGUN;
            if (self.ammo_shells < 2) {
                am = 1;
            }
        }
        else if (self.weapon == IT_SUPER_SHOTGUN) {
            self.weapon = IT_SHOTGUN;
            if (self.ammo_shells < 1) {
                am = 1;
            }
        }
        else if (self.weapon == IT_SHOTGUN) {
            self.weapon = IT_AXE;
        }
        else if (self.weapon == IT_AXE) {
            self.weapon = IT_LIGHTNING;
            if (self.ammo_cells < 1) {
                am = 1;
            }
        }

        if ( (it & self.weapon) && am == 0) {
            W_SetCurrentAmmo ();
            return;
        }
    }
};


//==============================================================================
//
//   W_WeaponFrame : Called every frame so impulse events can be handled
//
//==============================================================================
void() W_WeaponFrame =
{
    if (time < self.attack_finished) {
        return;
    }

    ImpulseCommands();
    self.impulse = 0;

    // check for attack
    if (self.button0) {
        SuperDamageSound();
        W_Attack();
    }
};

void() version_weapons = {
    sprint(self, "weapons 2.18 Karlos '99 (22/1/2000)\n");
};
