# karlos-quake
## Vanilla Quake C modification
This is an old QuakeC mod written around 1998-2000 that was built on, and for, the Amiga version of Quake.

## Features
### Player modifications

 - Male and female player option, affecting model and sounds.
 - Skin selection.
 - Centre, left and right handedness first person views.
 - First and third person views with a configurable camera.
 - Options are encoded into the `temp1` console variable.
 - Named player confugrations, where the above options can be set by player name that define the value of `temp1` to set the options for the corresponding player name.

### Inventory system
 - Powerups are collected and stored for later activation at the player's choosing.
 - Immediate use or store can be toggled.
 - Weapons can be dropped.

### Weapon changes
 - Grenades can be thrown by hand while usign a different weapon.
 - In-world aim target that can optionally be used as a realtime target paint for rockets.
 - Optional torch (turns target point into a lightsource).
 - Alternative fire mode for rocket launches a grappling hook that can be lengthened and shortened
 - Alternative fire mode for thunderbolt sends a high energy particle beam.
 
### Gameplay changes
Many of the following options can be enabled or disabled for the server. These options are encoded into the `registered` console variable.

 - More challenging enemies:
     - Grunts can attack with a machine gun at longer range.
     - Enforcers can sometimes attack with a particle beam shot.
     - Ogres understand ballistic trajectories and have much better aim as a result.
     - Fiends can make more intelligent jumps.
     - Most enemies that fire projectiles are able to project enemy movement and aim at the location they expect a moving enemy to be, rather than where they were, when the projectile arrives.
     - Many enemies have secondary attack modes, e.g. the grunt can use a machine gun at longer ranges.
 - Fire damage:
     - Torches can damage player and enemies, including setting them on fire.
     - Lava balls bounce,
 - Pushable objects:
     - Some objects, e.g. explosive boxes can be pushed.
 - Explosion shrapnel:
     - Explosions can send out a 
 - Weapon damage (optional):
     - Called "mike rules" after the AB3D2 Xenium Core author that suggested it, when enabled, weapons become damaged over time which causes them to jam. 
     - Weapons in the inventory are not automatically collected, the selected weapon needs to be dropped to exchange it with one.
 - Violence options:
     - Blood can be toggled.
     - Gibs can be toggled.
     - Solid (damageable) corpses can be toggled. Solid bodies can be pushed.
 - Team AI:
     - Monsters can be assigned to teams based on cooperating classes, e.g. Grunts, Dogs and Enforcers.
     - Team members share information and coordinate attacks.
     - There are up to three different teams even for the same class group.
     - Monsters in the same team will cooperate when attacking the player or another enemy.
     - Each team has a leader. When the team leader is killed, the remaining members can regroup around a new leader or go it alone.
 
   
### Other changes
There are numerous other changes, e.g. additional sound effects, etc.

## Commands
The following console commands are defined and can be bound to keys.
