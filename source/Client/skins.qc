// skins.qc

/*---public---*/
// $VER: skins.qc 1.20 © Karlos '99 (13/09/1999)

// public function prototypes
// highlevel
   void () load_client_skin;
   void (float opt) change_client_skin;
/*---private---*/

void () load_client_skin =
{
   self.skin = (cvar("temp1") & MAX_SKIN);
   screen_message(self, "Your skin number has been reset", MSG_INFO, FALSE);
};

void (float opt) change_client_skin =
{
   local string skinnum, skinname;

   if (opt)
   {
      self.skin = self.skin + 1;
      if (self.skin > MAX_SKIN)
         self.skin = 0;
   }
   else
   {
      self.skin = self.skin - 1;
      if (self.skin < 0)
         self.skin = MAX_SKIN;
   }
   if (effectflags & FX_CON_FLASH)
      stuffcmd (self, "bf\n");

   // add 1 to skin number to look nice...(1-32 instead of 0-31)
   skinnum = ftos((self.skin + 1));

//   skinname = get_skin_name(self.skin);

   bprint4 (self.netname, " using skin ", skinnum, "\n");
};

//-----------------------------------------------------------------------

//=====================================================================================
//
// disabled until further notice...
//
// use .noise4 to hold netname
//
//void () backup_client_netname =
//{
//   self.noise4 = self.netname;
//};
//
//void () restore_client_netname =
//{
//   self.netname = self.noise4;
//   stuffcmd (self, "_cl_name ");
//   stuffcmd (self, self.netname);
//   stuffcmd (self, "\n");
//};
//
//void (float num) set_skin_name =
//{
//   local string new_name;
//
//   new_name = self.netname;
//
//   if (num == 1)
//      skin_name01 = new_name;
//   else if (num == 2)
//      skin_name02 = new_name;
//   else if (num == 3)
//      skin_name03 = new_name;
//   else if (num == 4)
//      skin_name04 = new_name;
//   else if (num == 5)
//      skin_name05 = new_name;
//   else if (num == 6)
//      skin_name06 = new_name;
//   else if (num == 7)
//      skin_name07 = new_name;
//   else if (num == 8)
//      skin_name08 = new_name;
//   else if (num == 9)
//      skin_name09 = new_name;
//   else if (num == 10)
//      skin_name10 = new_name;
//   else if (num == 11)
//      skin_name11 = new_name;
//   else if (num == 12)
//      skin_name12 = new_name;
//   else if (num == 13)
//      skin_name13 = new_name;
//   else if (num == 14)
//      skin_name14 = new_name;
//   else if (num == 15)
//      skin_name15 = new_name;
//   else if (num == 16)
//      skin_name16 = new_name;
//   else if (num == 17)
//      skin_name17 = new_name;
//   else if (num == 18)
//      skin_name18 = new_name;
//   else if (num == 19)
//      skin_name19 = new_name;
//   else if (num == 20)
//      skin_name20 = new_name;
//   else if (num == 21)
//      skin_name21 = new_name;
//   else if (num == 22)
//      skin_name22 = new_name;
//   else if (num == 23)
//      skin_name23 = new_name;
//   else if (num == 24)
//      skin_name24 = new_name;
//   else if (num == 25)
//      skin_name25 = new_name;
//   else if (num == 26)
//      skin_name26 = new_name;
//  else if (num == 27)
//      skin_name27 = new_name;
//   else if (num == 28)
//      skin_name28 = new_name;
//   else if (num == 29)
//      skin_name29 = new_name;
//   else if (num == 30)
//      skin_name30 = new_name;
//   else if (num == 31)
//      skin_name31 = new_name;
//   else if (num == 32)
//      skin_name32 = new_name;
//};
//
//string (float num) get_skin_name =
//{
//   if (num < 1 || num > 32)
//      return "<undefined>";
//
//   if (num == 1)
//    return skin_name01;
//   else if (num == 2)
//      return skin_name02;
//   else if (num == 3)
//      return skin_name03;
//   else if (num == 4)
//      return skin_name04;
//   else if (num == 5)
//     return skin_name05;
//   else if (num == 6)
//      return skin_name06;
//   else if (num == 7)
//      return skin_name07;
//   else if (num == 8)
//      return skin_name08;
//   else if (num == 9)
//      return skin_name09;
//   else if (num == 10)
//      return skin_name10;
//   else if (num == 11)
//      return skin_name11;
//   else if (num == 12)
//      return skin_name12;
//   else if (num == 13)
//      return skin_name13;
//   else if (num == 14)
//      return skin_name14;
//   else if (num == 15)
//      return skin_name15;
//   else if (num == 16)
//      return skin_name16;
//   else if (num == 17)
//      return skin_name17;
//   else if (num == 18)
//      return skin_name18;
//   else if (num == 19)
//      return skin_name19;
//   else if (num == 20)
//      return skin_name20;
//   else if (num == 21)
//      return skin_name21;
//   else if (num == 22)
//      return skin_name22;
//   else if (num == 23)
//      return skin_name23;
//   else if (num == 24)
//      return skin_name24;
//   else if (num == 25)
//      return skin_name25;
//   else if (num == 26)
//      return skin_name26;
//   else if (num == 27)
//      return skin_name27;
//   else if (num == 28)
//      return skin_name28;
//   else if (num == 29)
//      return skin_name29;
//   else if (num == 30)
//      return skin_name30;
//   else if (num == 31)
//      return skin_name31;
//   else if (num == 32)
//      return skin_name32;
//};
//
//=======================================================================================
