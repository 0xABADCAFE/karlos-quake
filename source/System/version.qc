// version.qc
/*---public---*/
// $VER: version.qc 1.82 ® Karlos (14/10/1999)
// public functions defined

void() version_info;

   // defined elsewhere

void() version_AI;
void() version_World;
void() version_Client;
void() version_Misc;
void() version_System;
void() version_Monsters;
void() version_Server;
void() version_Base;

/*---private---*/

void() version_info = {
    sprint(self, "Karlos Quake Patch 1.8 release 4 beta \nProgram Build 9:5:2000\n");
    sprint(self, "Main extensions\n");
    version_AI();
    version_World();
    version_Client();
    version_Misc();
    version_System();
    version_Monsters();
    version_Server();
    version_Base();
};
