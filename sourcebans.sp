#pragma semicolon 1
#pragma newdecls required

#include <sourcebans>

#undef REQUIRE_PLUGIN
#include <adminmenu>
#include <geoip>

#define Prefix "[\x02SourceBans\x01]  "
#define DISABLE_ADDBAN		1
#define DISABLE_UNBAN		2


enum State
{
	ConfigStateNone = 0,
	ConfigStateConfig,
	ConfigStateReasons,
	ConfigStateHacking
}

int g_BanTarget[MAXPLAYERS+1] = {-1, ...};
int g_BanTime[MAXPLAYERS+1] = {-1, ...};

State ConfigState;
Handle ConfigParser;

Handle hTopMenu = INVALID_HANDLE;

char ServerIp[24];

/* Admin Stuff*/
AdminCachePart loadPart;
bool loadAdmins;
bool loadGroups;
int curLoading=0;
AdminFlag g_FlagLetters[26];

/* Admin KeyValues */
char groupsLoc[128];
char adminsLoc[128];
char overridesLoc[128];

/* Cvar handle*/
Handle CvarHostIp;

/* Database handle */
Handle g_hDatabase;
Handle g_hSQLite;

/* Menu file globals */
Handle ReasonMenuHandle;
Handle HackingMenuHandle;

/* Datapack and Timer handles */
Handle PlayerRecheck[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};
Handle PlayerDataPack[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};

/* Player ban check status */
bool PlayerStatus[MAXPLAYERS + 1];

/* Log Stuff */
char logFile[128];

/* Own Chat Reason */
int g_ownReasons[MAXPLAYERS+1] = {false, ...};

bool g_bLateLoaded;
bool g_bConnecting = false;

int g_iServerId = -1;

/* Ban Type */
g_iBanType[MAXPLAYERS+1];

public Plugin myinfo =
{
	name		= "SourceBans - [CG] Community Edition",
	author		= "SourceBans Development Team, Sarabveer(VEER™), Kyle",
	description	= "Advanced ban management for the Source engine",
	version		= "2.0+dev-5",
	url			= "http://steamcommunity.com/id/_xQy_/"
};


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("sourcebans");
	CreateNative("SBBanPlayer", Native_SBBanPlayer);
	CreateNative("SBAddBan", Native_SBAddBan);
	g_bLateLoaded = late;

	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("plugin.basecommands");
	LoadTranslations("sourcebans.phrases");
	LoadTranslations("basebans.phrases");

	loadAdmins = loadGroups = false;
	
	CvarHostIp = FindConVar("hostip");

	RegServerCmd("Server_Rehash", Server_Rehash, "Reload SQL admins");

	RegAdminCmd("sm_ban", CommandBan, ADMFLAG_BAN, "sm_ban <#userid|name> <minutes|0> [reason]", "sourcebans");
	RegAdminCmd("sb_reload", _CmdReload, ADMFLAG_RCON, "Reload sourcebans config and ban reason menu options", "sourcebans");

	RegConsoleCmd("say", ChatHook);
	RegConsoleCmd("say_team", ChatHook);

	if((ReasonMenuHandle = CreateMenu(ReasonSelected)) != INVALID_HANDLE)
	{
		SetMenuPagination(ReasonMenuHandle, 8);
		SetMenuExitBackButton(ReasonMenuHandle, true);
	}

	if((HackingMenuHandle = CreateMenu(HackingSelected)) != INVALID_HANDLE)
	{
		SetMenuPagination(HackingMenuHandle, 8);
		SetMenuExitBackButton(HackingMenuHandle, true);
	}
	
	g_FlagLetters['a'-'a'] = Admin_Reservation;
	g_FlagLetters['b'-'a'] = Admin_Generic;
	g_FlagLetters['c'-'a'] = Admin_Kick;
	g_FlagLetters['d'-'a'] = Admin_Ban;
	g_FlagLetters['e'-'a'] = Admin_Unban;
	g_FlagLetters['f'-'a'] = Admin_Slay;
	g_FlagLetters['g'-'a'] = Admin_Changemap;
	g_FlagLetters['h'-'a'] = Admin_Convars;
	g_FlagLetters['i'-'a'] = Admin_Config;
	g_FlagLetters['j'-'a'] = Admin_Chat;
	g_FlagLetters['k'-'a'] = Admin_Vote;
	g_FlagLetters['l'-'a'] = Admin_Password;
	g_FlagLetters['m'-'a'] = Admin_RCON;
	g_FlagLetters['n'-'a'] = Admin_Cheats;
	g_FlagLetters['o'-'a'] = Admin_Custom1;
	g_FlagLetters['p'-'a'] = Admin_Custom2;
	g_FlagLetters['q'-'a'] = Admin_Custom3;
	g_FlagLetters['r'-'a'] = Admin_Custom4;
	g_FlagLetters['s'-'a'] = Admin_Custom5;
	g_FlagLetters['t'-'a'] = Admin_Custom6;
	g_FlagLetters['z'-'a'] = Admin_Root;

	BuildPath(Path_SM, logFile, 128, "logs/sourcebans.log");
	g_bConnecting = true;


	SQL_TConnect(GotDatabase, "csgo");
	
	BuildPath(Path_SM , groupsLoc, 128,"configs/admin_groups.cfg");
	
	BuildPath(Path_SM, adminsLoc, 128,"configs/admins.cfg");
	
	BuildPath(Path_SM, overridesLoc, 128,"configs/sourcebans/overrides_backup.cfg");
	
	InitializeBackupDB();
	
	// This timer is what processes the SQLite queue when the database is unavailable
	CreateTimer(180.0, ProcessQueue);
	
	if(g_bLateLoaded)
	{
		char auth[32];
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientConnected(i) && !IsFakeClient(i))
				PlayerStatus[i] = false;

			if(IsClientInGame(i) && IsClientAuthorized(i) && !IsFakeClient(i) && GetClientAuthId(i, AuthId_Steam2, auth, 32, true))
				OnClientAuthorized(i, auth);
		}
	}
}

public void OnAllPluginsLoaded()
{
	Handle topmenu;

	if(LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
}

public void OnMapStart()
{
	ResetSettings();
}

public void OnMapEnd()
{
	for(int i = 0; i <= MaxClients; i++)
	{
		if(PlayerDataPack[i] != INVALID_HANDLE)
		{
			CloseHandle(PlayerDataPack[i]);
			PlayerDataPack[i] = INVALID_HANDLE;
		}
	}
}

public Action OnClientPreAdminCheck(int client)
{
	if(!g_hDatabase)
		return Plugin_Continue;
	
	if(GetUserAdmin(client) != INVALID_ADMIN_ID)
		return Plugin_Continue;
	
	if(curLoading > 0)
		return Plugin_Handled;

	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	if(PlayerRecheck[client] != INVALID_HANDLE)
	{
		KillTimer(PlayerRecheck[client]);
		PlayerRecheck[client] = INVALID_HANDLE;
	}
	g_ownReasons[client] = false;
	g_iBanType[client] = 0;
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
	PlayerStatus[client] = false;
	return true;
}

public void OnClientAuthorized(int client, const char[] auth)
{
	if(auth[0] == 'B' || auth[9] == 'L' || auth[0] == 'G' || g_hDatabase == INVALID_HANDLE)
	{
		PlayerStatus[client] = true;
		return;
	}

	char m_szQuery[512], ip[16];
	GetClientIP(client, ip, 16);
	FormatEx(m_szQuery, 512, "SELECT bid, ends, length, reason, sid, btype FROM sb_bans WHERE ((type = 0 AND authid REGEXP '^STEAM_[0-9]:%s$') OR (type = 1 AND ip = '%s')) AND (length = '0' OR ends > UNIX_TIMESTAMP()) AND (RemoveType IS NULL)", auth[8], ip);
	SQL_TQuery(g_hDatabase, VerifyBan, m_szQuery, GetClientUserId(client), DBPrio_High);
}

public void OnRebuildAdminCache(AdminCachePart part)
{
	loadPart = part;
	switch(loadPart)
	{
		case AdminCache_Groups:
			loadGroups = true;
		case AdminCache_Admins:
			loadAdmins = true;
	}
	if(g_hDatabase == INVALID_HANDLE) {
		if(!g_bConnecting) {
			g_bConnecting = true;
			SQL_TConnect(GotDatabase,"sourcebans");
		}
	}
	else {
		LoadAdminsAndGroups();
	}
}

public Action ChatHook(int client, int args)
{
	if(g_ownReasons[client])
	{
		char reason[512];
		GetCmdArgString(reason, 512);
		StripQuotes(reason);
		
		g_ownReasons[client] = false;

		PrepareBan(client, g_BanTarget[client], g_BanTime[client], reason, 512);

		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action _CmdReload(int client, int args)
{
	ResetSettings();
	return Plugin_Handled;
}

public Action CommandBan(int client, int args)
{
	if(args < 2)
	{
		PrintToChat(client, "%s \x04用法\x01: sm_ban <#userid或者名字> <时间(分钟)|0为永久> [原因]", Prefix);
		return Plugin_Handled;
	}

	int admin = client;

	char buffer[64];
	GetCmdArg(1, buffer, 64);
	int target = FindTarget(client, buffer, true);
	if(target == -1)
	{
		PrintToChat(client, "%s \x04目标无效", Prefix);
		return Plugin_Handled;
	}


	GetCmdArg(2, buffer, 64);
	int time = StringToInt(buffer);
	if(!time && client && !(CheckCommandAccess(client, "sm_unban", ADMFLAG_UNBAN|ADMFLAG_ROOT)))
	{
		PrintToChat(client, "%s \x05你没有永久封禁的权限", Prefix);
		return Plugin_Handled;
	}

	char reason[128];
	if(args >= 3)
	{
		for(int i=3; i <= args; i++)
		{
			GetCmdArg(i, buffer, 64);
			Format(reason, 64, "%s %s", reason, buffer);
		}
	}
	else
	{
		reason[0] = '\0';
	}
	
	g_BanTarget[client] = target;
	g_BanTime[client] = time;
	
	if(!PlayerStatus[target])
	{
		PrintToChat(admin, "%s \x05封禁正在验证中,请稍后再试...", Prefix);
		return Plugin_Handled;
	}

	CreateBan(client, target, time, reason);

	return Plugin_Handled;
}

public Action Server_Rehash(int args)
{
	DumpAdminCache(AdminCache_Groups,true);
	DumpAdminCache(AdminCache_Overrides, true);
	return Plugin_Handled;
}

public void OnAdminMenuReady(Handle topmenu)
{
	if(topmenu == hTopMenu)
		return;

	hTopMenu = topmenu;
	
	TopMenuObject player_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_PLAYERCOMMANDS);

	if(player_commands != INVALID_TOPMENUOBJECT)
		AddToTopMenu(hTopMenu, "sm_ban", TopMenuObject_Item, AdminMenu_Ban,	player_commands, "sm_ban", ADMFLAG_BAN);
}

public void AdminMenu_Ban(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	g_ownReasons[param] = false;
	

	if(action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "Ban player", param);
	}
	else if(action == TopMenuAction_SelectOption)
	{
		DisplayBanTargetMenu(param);
	}
}

public int ReasonSelected(Handle menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		char info[128];
		char key[128];
		GetMenuItem(menu, param2, key, 128, _, info, 128);
			
		if(StrEqual("Hacking", key))
		{
			DisplayMenu(HackingMenuHandle, param1, MENU_TIME_FOREVER);
			return;
		}
		if(StrEqual("Own Reason", key))
		{
			g_ownReasons[param1] = true;
			PrintToChat(param1, "%s 请按Y输入理由，若无理由或省略理由请输入!noreason", Prefix);
			return;
		}
		if(g_BanTarget[param1] != -1 && g_BanTime[param1] != -1)
		{
			PrepareBan(param1, g_BanTarget[param1], g_BanTime[param1], info, 128);
		}
	}
	else if(action == MenuAction_Cancel && param2 == MenuCancel_Disconnected)
	{
		if(PlayerDataPack[param1] != INVALID_HANDLE)
		{
			CloseHandle(PlayerDataPack[param1]);
			PlayerDataPack[param1] = INVALID_HANDLE;
		}

	}
	else if(action == MenuAction_Cancel)
	{
		DisplayBanTimeMenu(param1);
	}
}

public int HackingSelected(Handle menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		char info[128];
		char key[128];
		GetMenuItem(menu, param2, key, 128, _, info, 128);
		
		if(g_BanTarget[param1] != -1 && g_BanTime[param1] != -1)
			PrepareBan(param1, g_BanTarget[param1], g_BanTime[param1], info, 128);
		
	} else if(action == MenuAction_Cancel && param2 == MenuCancel_Disconnected) {

		Handle Pack = PlayerDataPack[param1];

		if(Pack != INVALID_HANDLE)
		{
			ReadPackCell(Pack); // admin index
			ReadPackCell(Pack); // target index
			ReadPackCell(Pack); // admin userid
			ReadPackCell(Pack); // target userid
			ReadPackCell(Pack); // time
			Handle ReasonPack = view_as<Handle>(ReadPackCell(Pack));

			if(ReasonPack != INVALID_HANDLE)
			{
				CloseHandle(ReasonPack);
			}

			CloseHandle(Pack);
			PlayerDataPack[param1] = INVALID_HANDLE;
		}
	}
	else if(action == MenuAction_Cancel)
	{
		DisplayMenu(ReasonMenuHandle, param1, MENU_TIME_FOREVER);
	}
}

public int MenuHandler_BanPlayerList(Handle menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if(action == MenuAction_Select)
	{
		char info[32], name[32];
		int userid, target;
		
		GetMenuItem(menu, param2, info, 32, _, name, 32);
		userid = StringToInt(info);

		if((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "%s%t", Prefix, "Player no longer available");
		}
		else if(!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "%s%t", Prefix, "Unable to target");
		}
		else
		{
			g_BanTarget[param1] = target;
			DisplayBanTimeMenu(param1);
		}
	}
}

public int MenuHandler_BanTimeList(Handle menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if(action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menu, param2, info, 32);
		g_BanTime[param1] = StringToInt(info);
		
		Handle btypeMenu = CreateMenu(MenuHandler_BanType);
		SetMenuTitle(btypeMenu, "选择封禁类型:\n ");
		AddMenuItem(btypeMenu, "0", "模式封禁");
		AddMenuItem(btypeMenu, "1", "单服封禁");
		AddMenuItem(btypeMenu, "2", "全服封禁", (GetUserFlagBits(param1) & ADMFLAG_CONVARS) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		SetMenuExitButton(btypeMenu, false);
		DisplayMenu(btypeMenu, param1, MENU_TIME_FOREVER);
		//DisplayMenu(ReasonMenuHandle, param1, MENU_TIME_FOREVER);
	}
}

public int MenuHandler_BanType(Handle menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if(action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menu, param2, info, 32);
		g_iBanType[param1] = StringToInt(info);
		DisplayMenu(ReasonMenuHandle, param1, MENU_TIME_FOREVER);
	}
}

stock void DisplayBanTargetMenu(int client)
{
	Handle menu = CreateMenu(MenuHandler_BanPlayerList);
	
	char title[100];
	Format(title, 100, "%T:", "Ban player", client);
	
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu(menu, 					// Add clients to our menu
			client, 				// The client that called the display
			false, 					// We want to see people connecting
			false);					// And dead people

	DisplayMenu(menu, client, MENU_TIME_FOREVER);		// Show the menu to the client FOREVER!
}

stock void DisplayBanTimeMenu(int client)
{
	Handle menu = CreateMenu(MenuHandler_BanTimeList);
	
	char title[100];
	Format(title, 100, "%T:", "Ban player", client);

	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);

	AddMenuItem(menu, "0", "永久封禁", CheckCommandAccess(client, "sm_unban", ADMFLAG_UNBAN|ADMFLAG_ROOT) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	AddMenuItem(menu, "10", "10分钟");
	AddMenuItem(menu, "30", "30分钟");
	AddMenuItem(menu, "60", "60分钟");
	AddMenuItem(menu, "1440", "24小时");
	AddMenuItem(menu, "4320", "72小时");

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

stock void ResetMenu()
{
	if(ReasonMenuHandle != INVALID_HANDLE)
	{
		RemoveAllMenuItems(ReasonMenuHandle);
	}
}

public void GotDatabase(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogToFile(logFile, "Database failure: %s.", error);
		g_bConnecting = false;
		return;
	}

	g_hDatabase = hndl;

	SQL_SetCharset(g_hDatabase, "utf8");

	InsertServerInfo();
	
	g_bConnecting = false;
}

public void VerifyInsert(Handle owner, Handle hndl, const char[] error, any dataPack)
{
	if(dataPack == INVALID_HANDLE)
	{
		LogToFile(logFile, "Ban Failed: %s", error);
		return;
	}

	if(hndl == INVALID_HANDLE || error[0])
	{
		LogToFile(logFile, "Verify Insert Query Failed: %s", error);
		int admin = ReadPackCell(dataPack);
		ReadPackCell(dataPack); // target
		ReadPackCell(dataPack); // admin userid
		ReadPackCell(dataPack); // target userid
		int time = ReadPackCell(dataPack);
		Handle reasonPack = view_as<Handle>(ReadPackCell(dataPack));
		char reason[128];
		ReadPackString(reasonPack, reason, 128);
		char name[50];
		ReadPackString(dataPack, name, 50);
		char auth[30];
		ReadPackString(dataPack, auth, 30);
		char ip[20];
		ReadPackString(dataPack, ip, 20);
		char adminAuth[30];
		ReadPackString(dataPack, adminAuth, 30);
		char adminIp[20];
		ReadPackString(dataPack, adminIp, 20);
		ResetPack(dataPack);
		ResetPack(reasonPack);

		PlayerDataPack[admin] = INVALID_HANDLE;
		UTIL_InsertTempBan(time, name, auth, ip, reason, adminAuth, adminIp, view_as<Handle>(dataPack));
		return;
	}

	int admin = ReadPackCell(dataPack);
	int client = ReadPackCell(dataPack);
	
	if(!IsClientConnected(client) || IsFakeClient(client))
		return;

	ReadPackCell(dataPack); // admin userid
	int UserId = ReadPackCell(dataPack);
	int time = ReadPackCell(dataPack);
	Handle ReasonPack = view_as<Handle>(ReadPackCell(dataPack));

	char Name[128], Reason[128];

	ReadPackString(dataPack, Name, 128);
	ReadPackString(ReasonPack, Reason, 128);

	if(!time)
	{
		if(Reason[0] == '\0')
		{
			ShowActivityEx(admin, "[SourceBans]", "%t", "Permabanned player", Name);
		} else {
			ShowActivityEx(admin, "[SourceBans]", "%t","Permabanned player reason", Name, Reason);
		}
	} else {
		if(Reason[0] == '\0')
		{
			ShowActivityEx(admin, "[SourceBans]", "%t", "Banned player", Name, time);
		} else {
			ShowActivityEx(admin, "[SourceBans]", "%t", "Banned player reason", Name, time, Reason);
		}
	}

	LogAction(admin, client, "\"%L\" banned \"%L\" (minutes \"%d\") (reason \"%s\")", admin, client, time, Reason);

	if(PlayerDataPack[admin] != INVALID_HANDLE)
	{
		CloseHandle(PlayerDataPack[admin]);
		CloseHandle(ReasonPack);
		PlayerDataPack[admin] = INVALID_HANDLE;
	}

	char Expired[128];
	char KickMsg[256];
	
	if(time != 0)
		FormatTime(Expired, 128, "%Y.%m.%d %H:%M:%S", GetTime()+time);
	else
		FormatEx(Expired, 128, "永久封禁");
	
	char bantype[32];
	strcopy(bantype, 32, "全服封禁");
	if(FindPluginByFile("ct.smx")) strcopy(bantype, 32, "匪镇谍影封禁");
	if(FindPluginByFile("mg_stats.smx")) strcopy(bantype, 32, "娱乐休闲封禁");
	if(FindPluginByFile("sm_hosties.smx")) strcopy(bantype, 32, "越狱搞基封禁");
	if(FindPluginByFile("zombiereloaded.smx")) strcopy(bantype, 32, "僵尸逃跑封禁");
	if(FindPluginByFile("deathmatch.smx") || FindPluginByFile("public_ext.smx") || FindPluginByFile("warmod.smx")) strcopy(bantype, 32, "竞技模式封禁");
	if(FindPluginByFile("KZTimerGlobal.smx")) strcopy(bantype, 32, "KZ跳跃封禁");
	FormatEx(KickMsg, 256, "你已被: %s[原因:%s][到期时间:%s]  请登陆 https://csgogamers.com/banned/ 查看详细信息", bantype, Reason, Expired);
	
	// Kick player
	if(GetClientUserId(client) == UserId)
		KickClient(client, KickMsg);
}

public void SelectAddbanCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	int admin, minutes;
	char adminAuth[30], adminIp[30], authid[20], banReason[256], m_szQuery[512], reason[128], nickName[32];
	ResetPack(data);
	admin = ReadPackCell(data);
	minutes = ReadPackCell(data);
	ReadPackString(data, reason,    128);
	ReadPackString(data, authid,    20);
	ReadPackString(data, adminAuth, 30);
	ReadPackString(data, adminIp,   30);
	ReadPackString(data, nickName,	32);
	SQL_EscapeString(g_hDatabase, reason, banReason, 256);
	
	if(error[0])
	{
		LogToFile(logFile, "Add Ban Select Query Failed: %s", error);
		if(admin && IsClientInGame(admin))
			PrintToChat(admin, "%s 封禁 %s[%s] 失败", Prefix, nickName, authid);

		return;
	}

	if(SQL_GetRowCount(hndl))
	{
		if(admin && IsClientInGame(admin))
			PrintToChat(admin, "%s %s[%s]已经被封禁.", Prefix, nickName, authid);

		return;
	}

	char bantype[32];
	strcopy(bantype, 32, "全服封禁");
	if(FindPluginByFile("ct.smx")) strcopy(bantype, 32, "匪镇谍影封禁");
	if(FindPluginByFile("mg_stats.smx")) strcopy(bantype, 32, "娱乐休闲封禁");
	if(FindPluginByFile("sm_hosties.smx")) strcopy(bantype, 32, "越狱搞基封禁");
	if(FindPluginByFile("zombiereloaded.smx")) strcopy(bantype, 32, "僵尸逃跑封禁");
	if(FindPluginByFile("deathmatch.smx") || FindPluginByFile("public_ext.smx") || FindPluginByFile("warmod.smx")) strcopy(bantype, 32, "竞技模式封禁");
	if(FindPluginByFile("KZTimerGlobal.smx")) strcopy(bantype, 32, "KZ跳跃封禁");

	FormatEx(m_szQuery, 512, "INSERT INTO sb_bans (authid, name, created, ends, length, reason, aid, adminIp, sid, btype, country) VALUES \
						('%s', '%s', UNIX_TIMESTAMP(), UNIX_TIMESTAMP() + %d, %d, '%s', (SELECT aid FROM sb_admins WHERE authid = '%s' OR authid REGEXP '^STEAM_[0-9]:%s$'), '%s', \
						%d, '%s', 'cn')",
						authid, nickName, (minutes*60), (minutes*60), banReason, adminAuth, adminAuth[8], adminIp, g_iServerId, bantype);

	SQL_TQuery(g_hDatabase, InsertAddbanCallback, m_szQuery, data, DBPrio_High);
}

public void InsertAddbanCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	int admin, minutes;
	char adminAuth[30], adminIp[30], authid[20], reason[128], nickName[32];
	ResetPack(data);
	admin = ReadPackCell(data);
	minutes = ReadPackCell(data);
	ReadPackString(data, reason,    128);
	ReadPackString(data, authid,    20);
	ReadPackString(data, adminAuth, 30);
	ReadPackString(data, adminIp,   30);
	ReadPackString(data, nickName,	32);
	CloseHandle(data);

	if(error[0] != '\0')
	{
		LogToFile(logFile, "Add Ban Insert Query Failed: %s", error);
		if(admin && IsClientInGame(admin))
		{
			PrintToChat(admin, "%s 封禁失败[AddBan]", Prefix);
		}
		return;
	}

	LogAction(admin, -1, "\"%L\" added ban (minutes \"%i\") (id \"%s\") (reason \"%s\")", admin, minutes, authid, reason);
	if(admin && IsClientInGame(admin))
	{
		PrintToChat(admin, "%s 封禁%s[%s]成功", Prefix, nickName, authid);
	}
}

public void SQLCallback_CheckAdminLog(Handle owner, Handle hndl, const char[] error, any unused)
{
	if(hndl==INVALID_HANDLE)
	{
		LogToFile(logFile, "INSERT Admin Log to Database Failed! Error: %s", error);
		return;
	}
}

public void ProcessQueueCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogToFile(logFile, "Failed to retrieve queued bans from sqlite database, %s", error);
		return;
	}

	char auth[30];
	int time;
	int startTime;
	char reason[128];
	char name[128];
	char ip[20];
	char adminAuth[30];
	char adminIp[20];
	char query[1024];
	char banName[128];
	char banReason[256];
	while(SQL_MoreRows(hndl))
	{
		if(!SQL_FetchRow(hndl))
			continue;

		SQL_FetchString(hndl, 0, auth, 30);
		time = SQL_FetchInt(hndl, 1);
		startTime = SQL_FetchInt(hndl, 2);
		SQL_FetchString(hndl, 3, reason, 128);
		SQL_FetchString(hndl, 4, name, 128);
		SQL_FetchString(hndl, 5, ip, 20);
		SQL_FetchString(hndl, 6, adminAuth, 30);
		SQL_FetchString(hndl, 7, adminIp, 20);
		SQL_EscapeString(g_hSQLite, name, banName, 128);
		SQL_EscapeString(g_hSQLite, reason, banReason, 256);
		
		char country[4];
		GeoipCode2(ip, country);
		char bantype[32];
		strcopy(bantype, 32, "全服封禁");
		if(FindPluginByFile("ct.smx")) strcopy(bantype, 32, "匪镇谍影封禁");
		if(FindPluginByFile("mg_stats.smx")) strcopy(bantype, 32, "娱乐休闲封禁");
		if(FindPluginByFile("sm_hosties.smx")) strcopy(bantype, 32, "越狱搞基封禁");
		if(FindPluginByFile("zombiereloaded.smx")) strcopy(bantype, 32, "僵尸逃跑封禁");
		if(FindPluginByFile("deathmatch.smx") || FindPluginByFile("public_ext.smx") || FindPluginByFile("warmod.smx")) strcopy(bantype, 32, "竞技模式封禁");
		if(FindPluginByFile("KZTimerGlobal.smx")) strcopy(bantype, 32, "KZ跳跃封禁");

		if(startTime + time * 60 > GetTime() || time == 0)
		{
			FormatEx(query, 1024,
						"INSERT INTO sb_bans (ip, authid, name, created, ends, length, reason, aid, adminIp, sid, btype, country) VALUES  \
						('%s', '%s', '%s', %d, %d, %d, '%s', (SELECT aid FROM sb_admins WHERE authid = '%s' OR authid REGEXP '^STEAM_[0-9]:%s$'), '%s', \
						%d, '%s', '%s')",
						ip, auth, banName, startTime, startTime + time * 60, time * 60, banReason, adminAuth, adminAuth[8], adminIp, g_iServerId, bantype, country);
			Handle authPack = CreateDataPack();
			WritePackString(authPack, auth);
			ResetPack(authPack);
			SQL_TQuery(g_hDatabase, AddedFromSQLiteCallback, query, authPack);
		} else {
			FormatEx(query, 1024, "DELETE FROM queue WHERE steam_id = '%s'", auth);
			SQL_TQuery(g_hSQLite, ErrorCheckCallback, query);
		}
	}

	CreateTimer(180.0, ProcessQueue);
}

public void AddedFromSQLiteCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	char buffer[512];
	char auth[40];
	ReadPackString(data, auth, 40);
	if(error[0] == '\0')
	{
		FormatEx(buffer, 512, "DELETE FROM queue WHERE steam_id = '%s'", auth);
		SQL_TQuery(g_hSQLite, ErrorCheckCallback, buffer);

		RemoveBan(auth, BANFLAG_AUTHID);
		
	}
	else
	{
		FormatEx(buffer, 512, "banid 3 %s", auth);
		ServerCommand(buffer);
	}
	CloseHandle(data);
}

void LoadAdminsAndGroups()
{
	char query[1024];

	if(loadGroups)
	{
		FormatEx(query,1024,"SELECT name, flags, immunity, groups_immune FROM sb_srvgroups ORDER BY id");
		curLoading++;
		SQL_TQuery(g_hDatabase,GroupsDone,query);
		loadGroups = false;
	}

	if(loadAdmins)
	{
		FormatEx(query,1024,"SELECT authid, srv_password, (SELECT name FROM sb_srvgroups WHERE name = srv_group AND flags != '') AS srv_group, srv_flags, user, immunity FROM sb_admins_servers_groups AS asg LEFT JOIN sb_admins AS a ON a.aid = asg.admin_id WHERE server_id = %d OR srv_group_id = ANY (SELECT group_id FROM sb_servers_groups WHERE server_id = %d) GROUP BY aid, authid, srv_password, srv_group, srv_flags, user", g_iServerId, g_iServerId);
		curLoading++;
		SQL_TQuery(g_hDatabase,AdminsDone,query);
		loadAdmins = false;
	}
}

public void ServerInfoCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if(error[0] || hndl	== INVALID_HANDLE)
	{
		LogToFile(logFile, "Server Select Query Failed: %s", error);
		return;
	}
	
	if(SQL_FetchRow(hndl))
		g_iServerId = SQL_FetchInt(hndl, 0);
	
	LoadAdminsAndGroups();
}

public void ErrorCheckCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if(error[0])
	{
		LogToFile(logFile, "Query Failed: %s", error);
	}
}

public void VerifyBan(Handle owner, Handle hndl, const char[] error, any userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!client)
		return;

	if(hndl == INVALID_HANDLE)
	{
		LogToFile(logFile, "Verify Ban Query Failed: %s", error);
		PlayerRecheck[client] = CreateTimer(30.0, ClientRecheck, client);
		return;
	}
	char clientName[128];
	char clientAuth[128];
	char clientIp[128];
	GetClientIP(client, clientIp, 128);
	GetClientAuthId(client, AuthId_Steam2, clientAuth, 128, true);
	GetClientName(client, clientName, 128);
	if(SQL_GetRowCount(hndl) && SQL_FetchRow(hndl))
	{
		char buffer[40];
		char Name[128];
		char m_szQuery[512];
		char KickMsg[256];
		char Reason[128];
		char Expired[128];
		char bType[32];
		char bantype[32];
		if(FindPluginByFile("ct.smx")) strcopy(bantype, 32, "匪镇谍影封禁");
		if(FindPluginByFile("mg_stats.smx")) strcopy(bantype, 32, "娱乐休闲封禁");
		if(FindPluginByFile("sm_hosties.smx")) strcopy(bantype, 32, "越狱搞基封禁");
		if(FindPluginByFile("zombiereloaded.smx")) strcopy(bantype, 32, "僵尸逃跑封禁");
		if(FindPluginByFile("deathmatch.smx") || FindPluginByFile("public_ext.smx") || FindPluginByFile("warmod.smx")) strcopy(bantype, 32, "竞技模式封禁");
		if(FindPluginByFile("KZTimerGlobal.smx")) strcopy(bantype, 32, "KZ跳跃封禁");
		
		int StartTime = SQL_FetchInt(hndl, 1);
		int Length = SQL_FetchInt(hndl, 2);
		SQL_FetchString(hndl, 3, Reason, 128);
		int sid = SQL_FetchInt(hndl, 4);
		SQL_FetchString(hndl, 5, bType, 32);
		if(StrEqual(bType, "全服封禁") || StrEqual(bType, bantype) || (StrEqual(bType, "单服封禁") && sid == g_iServerId))
		{
			SQL_EscapeString(g_hDatabase, clientName, Name, 128);
			FormatEx(m_szQuery, 512, "INSERT INTO sb_banlog VALUES (%d, UNIX_TIMESTAMP(), '%s', '%s', %d)", g_iServerId, Name, clientAuth[8], clientIp, SQL_FetchInt(hndl, 0));
			SQL_TQuery(g_hDatabase, ErrorCheckCallback, m_szQuery, client, DBPrio_High);
			FormatEx(buffer, 40, "banid 2 %s", clientAuth);
			ServerCommand(buffer);
			if(Length != 0)
				FormatTime(Expired, 128, "%Y.%m.%d %H:%M:%S", StartTime+Length);
			else
				FormatEx(Expired, 128, "永久封禁");
			FormatEx(KickMsg, 256, "你已被: %s[原因:%s][到期时间:%s]  请登陆 https://csgogamers.com/banned/ 查看详细信息", bType, Reason, Expired);
			KickClient(client, KickMsg);
		}
		return;
	}

	PlayerStatus[client] = true;
}

public void AdminsDone(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		--curLoading;
		CheckLoadAdmins();
		LogToFile(logFile, "Failed to retrieve admins from the database, %s", error);
		return;
	}
	char authType[] = "steam";
	char identity[66];
	char password[66];
	char groups[256];
	char flags[32];
	char name[66];
	int admCount=0;
	int Immunity=0;
	AdminId curAdm = INVALID_ADMIN_ID;
	Handle adminsKV = CreateKeyValues("Admins");
	while(SQL_FetchRow(hndl))
	{
		if(SQL_IsFieldNull(hndl, 0))
			continue;  // Sometimes some rows return NULL due to some setups

		SQL_FetchString(hndl,0,identity,66);
		SQL_FetchString(hndl,1,password,66);
		SQL_FetchString(hndl,2,groups,256);
		SQL_FetchString(hndl,3,flags,32);
		SQL_FetchString(hndl,4,name,66);

		Immunity = SQL_FetchInt(hndl,5);
		
		TrimString(name);
		TrimString(identity);
		TrimString(groups);
		TrimString(flags);


		KvJumpToKey(adminsKV, name, true);
		
		KvSetString(adminsKV, "auth", authType);
		KvSetString(adminsKV, "identity", identity);
		
		if(strlen(flags) > 0)
			KvSetString(adminsKV, "flags", flags);
		
		if(strlen(groups) > 0)
			KvSetString(adminsKV, "group", groups);
	
		if(strlen(password) > 0)
			KvSetString(adminsKV, "password", password);
		
		if(Immunity > 0)
			KvSetNum(adminsKV, "immunity", Immunity);
		
		KvRewind(adminsKV);

		if((curAdm = FindAdminByIdentity(authType, identity)) == INVALID_ADMIN_ID)
		{
			curAdm = CreateAdmin(name);
			if(!BindAdminIdentity(curAdm, authType, identity))
			{
				LogToFile(logFile, "Unable to bind admin %s to identity %s", name, identity);
				RemoveAdmin(curAdm);
				continue;
			}
		}
		
		int curPos = 0;
		GroupId curGrp = INVALID_GROUP_ID;
		int numGroups;
		char iterGroupName[128];
		
		if(strcmp(groups[curPos], "") != 0)
		{
			curGrp = FindAdmGroup(groups[curPos]);
			if(curGrp == INVALID_GROUP_ID)
			{
				LogToFile(logFile, "Unknown group \"%s\"",groups[curPos]);
			}
			else
			{
				numGroups = GetAdminGroupCount(curAdm);
				for(int i = 0; i < numGroups; i++)
				{
					GetAdminGroup(curAdm, i, iterGroupName, 128);
					if(StrEqual(iterGroupName, groups[curPos]))
					{
						numGroups = -2;
						break;
					}
				}

				if(numGroups != -2 && !AdminInheritGroup(curAdm,curGrp))
				{
					LogToFile(logFile, "Unable to inherit group \"%s\"",groups[curPos]);
				}

				if(GetAdminImmunityLevel(curAdm) < Immunity)
				{
					SetAdminImmunityLevel(curAdm, Immunity);
				}
			}
		}
		
		if(strlen(password) > 0)
			SetAdminPassword(curAdm, password);
        
		for (int i = 0; i < strlen(flags); ++i)
		{
			if(flags[i] < 'a' || flags[i] > 'z')
				continue;
				
			if(g_FlagLetters[flags[i] - 'a'] < Admin_Reservation)
				continue;
				
			SetAdminFlag(curAdm, g_FlagLetters[flags[i] - 'a'], true);
		}
		
		if(GetAdminImmunityLevel(curAdm) < Immunity)
		{
			SetAdminImmunityLevel(curAdm, Immunity);
		}

		++admCount;
	}
	
	KeyValuesToFile(adminsKV, adminsLoc);
	CloseHandle(adminsKV);
	
	--curLoading;
	CheckLoadAdmins();
}

public void GroupsDone(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		curLoading--;
		CheckLoadAdmins();
		LogToFile(logFile, "Failed to retrieve groups from the database, %s",error);
		return;
	}
	
	char grpName[128], immuneGrpName[128];
	char grpFlags[32];
	int Immunity;
	int grpCount = 0;
	Handle groupsKV = CreateKeyValues("Groups");
	
	GroupId curGrp = INVALID_GROUP_ID;
	while(SQL_MoreRows(hndl))
	{
		SQL_FetchRow(hndl);
		if(SQL_IsFieldNull(hndl, 0))
			continue;
		SQL_FetchString(hndl,0,grpName,128);
		SQL_FetchString(hndl,1,grpFlags,32);
		Immunity = SQL_FetchInt(hndl,2);
		SQL_FetchString(hndl,3,immuneGrpName,128);

 		TrimString(grpName);
		TrimString(grpFlags);
		TrimString(immuneGrpName);

		if(!strlen(grpName))
			continue;
		
		curGrp = CreateAdmGroup(grpName);

		KvJumpToKey(groupsKV, grpName, true);
		if(strlen(grpFlags) > 0)
			KvSetString(groupsKV, "flags", grpFlags);
		if(Immunity > 0)
			KvSetNum(groupsKV, "immunity", Immunity);
		
		KvRewind(groupsKV);
		
		if(curGrp == INVALID_GROUP_ID)
		{
			curGrp = FindAdmGroup(grpName);
		}
        
		for(int i = 0; i < strlen(grpFlags); ++i)
		{
			if(grpFlags[i] < 'a' || grpFlags[i] > 'z')
				continue;
				
			if(g_FlagLetters[grpFlags[i] - 'a'] < Admin_Reservation)
				continue;
				
			SetAdmGroupAddFlag(curGrp, g_FlagLetters[grpFlags[i] - 'a'], true);
		}

		if(Immunity > 0)
		{
			SetAdmGroupImmunityLevel(curGrp, Immunity);
		}
		
		grpCount++;
	}
	
	--curLoading;
	KeyValuesToFile(groupsKV, groupsLoc);
	CloseHandle(groupsKV);
}

// TIMER CALL BACKS //
public Action ClientRecheck(Handle timer, int client)
{
	char Authid[128];
	if(!PlayerStatus[client] && IsClientConnected(client) && GetClientAuthId(client, AuthId_Steam2, Authid, 128))
	{
		OnClientAuthorized(client, Authid);
	}

	PlayerRecheck[client] =  INVALID_HANDLE;
	return Plugin_Stop;
}

public Action ProcessQueue(Handle timer)
{
	char buffer[512];
	Format(buffer, 512, "SELECT steam_id, time, start_time, reason, name, ip, admin_id, admin_ip FROM queue");
	SQL_TQuery(g_hSQLite, ProcessQueueCallback, buffer);
}

// PARSER //
static void InitializeConfigParser()
{
	if(ConfigParser == INVALID_HANDLE)
	{
		ConfigParser = SMC_CreateParser();
		SMC_SetReaders(ConfigParser, ReadConfig_NewSection, ReadConfig_KeyValue, ReadConfig_EndSection);
	}
}

static void InternalReadConfig(const char[] path)
{
	ConfigState = ConfigStateNone;

	SMCError err = SMC_ParseFile(ConfigParser, path);

	if(err != SMCError_Okay)
	{
		char buffer[128];
		if(SMC_GetErrorString(err, buffer, 128))
		{
			PrintToServer(buffer);
		} else {
			PrintToServer("Fatal parse error");
		}
	}
}

public SMCResult ReadConfig_NewSection(Handle smc, const char[] name, bool opt_quotes)
{
	if(name[0])
	{
		if(strcmp("Config", name, false) == 0)
		{
			ConfigState = ConfigStateConfig;
		} else if(strcmp("BanReasons", name, false) == 0) {
			ConfigState = ConfigStateReasons;
		} else if(strcmp("HackingReasons", name, false) == 0) {
			ConfigState = ConfigStateHacking;
		}
	}
	return SMCParse_Continue;
}

public SMCResult ReadConfig_KeyValue(Handle smc, const char[] key, const char[] value, bool key_quotes, bool value_quotes)
{
	if(!key[0])
		return SMCParse_Continue;

	switch(ConfigState)
	{
		case ConfigStateReasons:
		{
			if(ReasonMenuHandle != INVALID_HANDLE)
			{
				AddMenuItem(ReasonMenuHandle, key, value);
			}
		}
		case ConfigStateHacking:
		{
			if(HackingMenuHandle != INVALID_HANDLE)
			{
				AddMenuItem(HackingMenuHandle, key, value);
			}
		}
	}
	return SMCParse_Continue;
}

public SMCResult ReadConfig_EndSection(Handle smc)
{
	return SMCParse_Continue;
}

public int Native_SBBanPlayer(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int target = GetNativeCell(2);
	int time = GetNativeCell(3);
	char reason[128];
	GetNativeString(4, reason, 128);

	if(reason[0] == '\0')
		strcopy(reason, 128, "Banned by SourceBans");
	
	if(client && IsClientInGame(client))
	{
		AdminId aid = GetUserAdmin(client);
		if(aid == INVALID_ADMIN_ID)
		{
			ThrowNativeError(1, "Ban Error: Player is not an admin.");
			return 0;
		}

		if(!GetAdminFlag(aid, Admin_Ban))
		{
			ThrowNativeError(2, "Ban Error: Player does not have BAN flag.");
			return 0;
		}
	}

	PrepareBan(client, target, time, reason, 128);
	return true;
}

public int Native_SBAddBan(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int time = GetNativeCell(2);
	char authid[32], nickName[64], reason[128];
	GetNativeString(3, authid, 32);
	GetNativeString(4, nickName, 32);
	GetNativeString(5, reason, 128);

	char adminIp[24], adminAuth[128];
	if(!client)
	{
		strcopy(adminAuth, 128, "STEAM_ID_SERVER");
		strcopy(adminIp, 24, ServerIp);
	} else {
		GetClientIP(client, adminIp, 24);
		GetClientAuthId(client, AuthId_Steam2, adminAuth, 128, true);
	}

	Handle dataPack = CreateDataPack();
	WritePackCell(dataPack, client);
	WritePackCell(dataPack, time);
	WritePackString(dataPack, reason);
	WritePackString(dataPack, authid);
	WritePackString(dataPack, adminAuth);
	WritePackString(dataPack, adminIp);
	WritePackString(dataPack, nickName);

	char Query[256];
	FormatEx(Query, 256, "SELECT bid FROM sb_bans WHERE type = 0 AND authid = '%s' AND (length = 0 OR ends > UNIX_TIMESTAMP()) AND RemoveType IS NULL", authid);
	SQL_TQuery(g_hDatabase, SelectAddbanCallback, Query, dataPack, DBPrio_High);
}

public void InitializeBackupDB()
{
	char error[255];
	g_hSQLite = SQLite_UseDatabase("sourcebans-queue", error, 255);
	if(g_hSQLite == INVALID_HANDLE)
		SetFailState(error);

	SQL_LockDatabase(g_hSQLite);
	SQL_FastQuery(g_hSQLite, "CREATE TABLE IF NOT EXISTS queue (steam_id TEXT PRIMARY KEY ON CONFLICT REPLACE, time INTEGER, start_time INTEGER, reason TEXT, name TEXT, ip TEXT, admin_id TEXT, admin_ip TEXT);");
	SQL_UnlockDatabase(g_hSQLite);
}

public bool CreateBan(int client, int target, int time, char[] reason)
{
	char adminIp[24], adminAuth[128];
	int admin = client;

	if(!admin)
	{
		if(reason[0] == '\0')
		{
			PrintToServer("%s%T", Prefix, "Include Reason", LANG_SERVER);
			return false;
		}

		// setup dummy adminAuth and adminIp for server
		strcopy(adminAuth, 128, "STEAM_ID_SERVER");
		strcopy(adminIp, 24, ServerIp);
	} else {
		GetClientIP(admin, adminIp, 24);
		GetClientAuthId(admin, AuthId_Steam2, adminAuth, 128, true);
	}


	char ip[24], auth[128], name[128];

	GetClientName(target, name, 128);
	GetClientIP(target, ip, 24);
	if(!GetClientAuthId(target, AuthId_Steam2, auth, 128, true))
		return false;

	int userid = admin ? GetClientUserId(admin) : 0;

	Handle dataPack = CreateDataPack();
	Handle reasonPack = CreateDataPack();
	WritePackString(reasonPack, reason);

	WritePackCell(dataPack, admin);
	WritePackCell(dataPack, target);
	WritePackCell(dataPack, userid);
	WritePackCell(dataPack, GetClientUserId(target));
	WritePackCell(dataPack, time);
	WritePackCell(dataPack, view_as<int>(reasonPack));
	WritePackString(dataPack, name);
	WritePackString(dataPack, auth);
	WritePackString(dataPack, ip);
	WritePackString(dataPack, adminAuth);
	WritePackString(dataPack, adminIp);

	ResetPack(dataPack);
	ResetPack(reasonPack);

	if(reason[0] != '\0')
	{
		if(g_hDatabase != INVALID_HANDLE)
		{
			UTIL_InsertBan(time, name, auth, ip, reason, adminAuth, adminIp, dataPack);
		} else
		{
			UTIL_InsertTempBan(time, name, auth, ip, reason, adminAuth, adminIp, dataPack);
		}
	}
	else
	{
		PlayerDataPack[admin] = dataPack;
		DisplayMenu(ReasonMenuHandle, admin, MENU_TIME_FOREVER);
		PrintToChat(admin, "%s %t", Prefix, "Check Menu");
	}
	
	return true;
}

stock void UTIL_InsertBan(int time, const char[] Name, const char[] Authid, const char[] Ip, const char[] Reason, const char[] AdminAuthid, const char[] AdminIp, Handle Pack)
{
	char banName[128], banReason[256], m_szQuery[1024], country[4], bantype[32];
	SQL_EscapeString(g_hDatabase, Name, banName, 128);
	SQL_EscapeString(g_hDatabase, Reason, banReason, 256);
	GeoipCode2(Ip, country);
	int admin = FindClientBySteamId(AdminAuthid);
	switch(g_iBanType[admin])
	{
		case 0:
		{
			if(FindPluginByFile("ct.smx")) strcopy(bantype, 32, "匪镇谍影封禁");
			if(FindPluginByFile("mg_stats.smx")) strcopy(bantype, 32, "娱乐休闲封禁");
			if(FindPluginByFile("sm_hosties.smx")) strcopy(bantype, 32, "越狱搞基封禁");
			if(FindPluginByFile("zombiereloaded.smx")) strcopy(bantype, 32, "僵尸逃跑封禁");
			if(FindPluginByFile("deathmatch.smx") || FindPluginByFile("public_ext.smx") || FindPluginByFile("warmod.smx")) strcopy(bantype, 32, "竞技模式封禁");
			if(FindPluginByFile("KZTimerGlobal.smx")) strcopy(bantype, 32, "KZ跳跃封禁");
		}
		case 1:
		{
			strcopy(bantype, 32, "单服封禁");
		}
		case 2:
		{
			strcopy(bantype, 32, "全服封禁");
		}
	}
	
	FormatEx(m_szQuery, 1024, "INSERT INTO sb_bans (ip, authid, name, created, ends, length, reason, aid, adminIp, sid, btype, country) VALUES \
						('%s', '%s', '%s', UNIX_TIMESTAMP(), UNIX_TIMESTAMP() + %d, %d, '%s', IFNULL((SELECT aid FROM sb_admins WHERE authid = '%s' OR authid REGEXP '^STEAM_[0-9]:%s$'),'0'), '%s', \
						%d, '%s', '%s')",
						Ip, Authid, banName, (time*60), (time*60), banReason, AdminAuthid, AdminAuthid[8], AdminIp, g_iServerId, bantype, country);

	SQL_TQuery(g_hDatabase, VerifyInsert, m_szQuery, Pack, DBPrio_High);
}

stock int FindClientBySteamId(const char[] steamid)
{
	char m_szAuth[32];
	for(int client  = 1; client <= MaxClients; ++client)
		if(IsClientAuthorized(client) && GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true))
			if(StrEqual(m_szAuth, steamid))
				return client;
			
	return 0;
}

stock void UTIL_InsertTempBan(int time, const char[] name, const char[] auth, const char[] ip, const char[] reason, const char[] adminAuth, const char[] adminIp, Handle dataPack)
{
	ReadPackCell(dataPack); // admin index
	int client = ReadPackCell(dataPack);
	ReadPackCell(dataPack); // admin userid
	ReadPackCell(dataPack); // target userid
	ReadPackCell(dataPack); // time
	Handle reasonPack = view_as<Handle>(ReadPackCell(dataPack));
	if(reasonPack != INVALID_HANDLE)
	{
		CloseHandle(reasonPack);
	}
	CloseHandle(dataPack);
	
	char buffer[50];
	Format(buffer, 50, "banid 3 %s", auth);
	ServerCommand(buffer);
	if(IsClientInGame(client))
		KickClient(client, "%t", "Banned Check Site", "https://csgogamers.com");
	
	char banName[128];
	char banReason[256];
	char query[512];
	SQL_EscapeString(g_hSQLite, name, banName, 128);
	SQL_EscapeString(g_hSQLite, reason, banReason, 256);
	FormatEx(query, 512, "INSERT INTO queue VALUES ('%s', %i, %i, '%s', '%s', '%s', '%s', '%s')", auth, time, GetTime(), banReason, banName, ip, adminAuth, adminIp);
	SQL_TQuery(g_hSQLite, ErrorCheckCallback, query);
}

stock void CheckLoadAdmins()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsClientAuthorized(i))
		{
			RunAdminCacheChecks(i);
			NotifyPostAdminCheck(i);
		}
	}
}

stock void InsertServerInfo()
{
	if(g_hDatabase == INVALID_HANDLE)
	{
		return;
	}
	
	char query[100];
	int ip = GetConVarInt(CvarHostIp);
	Format(ServerIp, 64, "%d.%d.%d.%d", ((ip & 0xFF000000) >> 24) & 0xFF, ((ip & 0x00FF0000) >> 16) & 0xFF, ((ip & 0x0000FF00) >>  8) & 0xFF, ((ip & 0x000000FF) >>  0) & 0xFF);

	FormatEx(query, 100, "SELECT sid FROM sb_servers WHERE ip = '%s' AND port = '%d'", ServerIp, GetConVarInt(FindConVar("hostport")));
	SQL_TQuery(g_hDatabase, ServerInfoCallback, query);
}

stock void PrepareBan(int client, int target, int time, char[] reason, int size)
{
	if(!target || !IsClientInGame(target))
		return;
	char authid[128], name[32], bannedSite[512];
	if(!GetClientAuthId(target, AuthId_Steam2, authid, 128, true))
		return;
	GetClientName(target, name, 32);
	
	if(CreateBan(client, target, time, reason))
	{
		if(!time)
		{
			if(reason[0] == '\0')
			{
				ShowActivity(client, "%t", "Permabanned player", name);
			} else {
				ShowActivity(client, "%t", "Permabanned player reason", name, reason);
			}
		} else {
			if(reason[0] == '\0')
			{
				ShowActivity(client, "%t", "Banned player", name, time);
			} else {
				ShowActivity(client, "%t", "Banned player reason", name, time, reason);
			}
		}
		LogAction(client, target, "\"%L\" banned \"%L\" (minutes \"%d\") (reason \"%s\")", client, target, time, reason);
		
		if(time > 5 || time == 0)
			time = 5;
		Format(bannedSite, 512, "%T", "Banned Check Site", target, "https://csgogamers.com");
		BanClient(target, time, BANFLAG_AUTO, bannedSite, bannedSite, "sm_ban", client);
	}

	g_BanTarget[client] = -1;
	g_BanTime[client] = -1;
}

stock void ReadConfig()
{
	InitializeConfigParser();

	if(ConfigParser == INVALID_HANDLE)
	{
		return;
	}

	char ConfigFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, ConfigFile, 256, "configs/sourcebans/sourcebans.cfg");

	if(FileExists(ConfigFile))
	{
		InternalReadConfig(ConfigFile);
		PrintToServer("[SourceBans] Loading configs/sourcebans.cfg config file");
	} else {
		LogToFile(logFile, "FATAL *** ERROR *** can not find %s", ConfigFile);
		SetFailState("FATAL *** ERROR *** can not find configs/sourcebans/sourcebans.cfg");
	}
}

stock void ResetSettings()
{
	ResetMenu();
	ReadConfig();
}

public Action OnLogAction(Handle source, Identity ident, int client, int target, const char[] message)
{
	if(client < 1 || GetUserAdmin(client) == INVALID_ADMIN_ID || g_hDatabase == INVALID_HANDLE || StrContains(message, "console command") >= 0 || StrContains(message, "sm_chat") >= 0)
		return Plugin_Continue;

	if(target >= 1 && client != target)
	{
		char m_szClientauth[32], m_szTargetauth[32], m_szQuery[512], m_sMsg[256], m_szClientid[128], m_szTargetid[128], m_szTmp[32], m_szTmp2[128];
		GetClientAuthId(client, AuthId_Steam2, m_szClientauth, 32, true);
		GetClientAuthId(target, AuthId_Steam2, m_szTargetauth, 32, true);
		Format(m_szClientid, 128, "\"%N<%d><%s><>\"", client, GetClientUserId(client), m_szClientauth);
		Format(m_szTargetid, 128, "\"%N<%d><%s><>\"", target, GetClientUserId(target), m_szTargetauth);
		Format(m_szTmp2, 128, "%s", m_szTargetid);
		Format(m_szTmp, 32, "<%d>", GetClientUserId(target));
		ReplaceString(m_szTargetid, 128, m_szTmp, "");
		ReplaceString(m_szTargetid, 128, "<>", "");
		Format(m_sMsg, 256, "%s", message);
		ReplaceString(m_sMsg, 256, m_szClientid, "");
		ReplaceString(m_sMsg, 256, m_szTmp2, m_szTargetid);
		ReplaceString(m_sMsg, 256, "slayed", "处死");
		ReplaceString(m_sMsg, 256, "slapped", "拍打");
		ReplaceString(m_sMsg, 256, "ignited", "点燃");
		ReplaceString(m_sMsg, 256, "removed a beacon on", "取消点灯");
		ReplaceString(m_sMsg, 256, "set a beacon on", "点灯");
		ReplaceString(m_sMsg, 256, "froze", "冰冻");
		ReplaceString(m_sMsg, 256, "set a TimeBomb on", "设置时间炸弹");
		ReplaceString(m_sMsg, 256, "removed a TimeBomb on", "取消时间炸弹");
		ReplaceString(m_sMsg, 256, "set a FreezeBomb on", "设置火焰炸弹");
		ReplaceString(m_sMsg, 256, "removed a FireBomb on", "取消火焰炸弹");
		ReplaceString(m_sMsg, 256, "set a FreezeBomb on", "设置冰冻炸弹");
		ReplaceString(m_sMsg, 256, "removed a FreezeBomb on", "取消冰冻炸弹");
		ReplaceString(m_sMsg, 256, "set blind on", "设置致盲");
		ReplaceString(m_sMsg, 256, "set gravity on", "设置重力");
		ReplaceString(m_sMsg, 256, "unrenamed", "取消改名");
		ReplaceString(m_sMsg, 256, "renamed", "改名");
		ReplaceString(m_sMsg, 256, "undrugged", "取消毒药");
		ReplaceString(m_sMsg, 256, "drugged", "下毒药");
		ReplaceString(m_sMsg, 256, "teleported", "传送");
		ReplaceString(m_sMsg, 256, "triggered sm_say", "管理员频道喊话");
		ReplaceString(m_sMsg, 256, "triggered sm_msay", "管理员频道喊话");
		ReplaceString(m_sMsg, 256, "triggered sm_csay", "管理员频道喊话");
		ReplaceString(m_sMsg, 256, "triggered sm_hsay", "管理员频道喊话");
		ReplaceString(m_sMsg, 256, "triggered sm_psay", "管理员频道私聊");
		ReplaceString(m_sMsg, 256, "toggled noclip on", "触发穿墙效果");
		ReplaceString(m_sMsg, 256, "changed map to", "更换地图");
		ReplaceString(m_sMsg, 256, "kicked", "踢出");
		ReplaceString(m_sMsg, 256, "reason", "原因");
		ReplaceString(m_sMsg, 256, "added ban", "封禁离线玩家");
		char emsg[512];
		SQL_EscapeString(g_hDatabase, m_sMsg, emsg, 512);
		Format(m_szQuery, 512, "INSERT INTO `sb_adminlog` VALUES (DEFAULT, (IF((SELECT aid FROM `sb_admins` WHERE authid = '%s')>0,(SELECT aid FROM `sb_admins` WHERE authid = '%s'),-1)),%d,'%s',DEFAULT);", m_szClientauth, m_szClientauth, g_iServerId, emsg);
		SQL_TQuery(g_hDatabase, SQLCallback_CheckAdminLog, m_szQuery);
	}
	else
	{
		char m_szClientauth[32], m_szQuery[512], m_sMsg[256], m_szClientid[128];
		GetClientAuthId(client, AuthId_Steam2, m_szClientauth, 32, true);
		Format(m_szClientid, 128, "\"%N<%d><%s><>\"", client, GetClientUserId(client), m_szClientauth);
		Format(m_sMsg, 256, "%s", message);
		ReplaceString(m_sMsg, 256, m_szClientid, "自己");
		ReplaceString(m_sMsg, 256, "slayed", "处死");
		ReplaceString(m_sMsg, 256, "slapped", "拍打");
		ReplaceString(m_sMsg, 256, "ignited", "点燃");
		ReplaceString(m_sMsg, 256, "removed a beacon on", "取消点灯");
		ReplaceString(m_sMsg, 256, "set a beacon on", "点灯");
		ReplaceString(m_sMsg, 256, "froze", "冰冻");
		ReplaceString(m_sMsg, 256, "set a TimeBomb on", "设置时间炸弹");
		ReplaceString(m_sMsg, 256, "removed a TimeBomb on", "取消时间炸弹");
		ReplaceString(m_sMsg, 256, "set a FreezeBomb on", "设置火焰炸弹");
		ReplaceString(m_sMsg, 256, "removed a FireBomb on", "取消火焰炸弹");
		ReplaceString(m_sMsg, 256, "set a FreezeBomb on", "设置冰冻炸弹");
		ReplaceString(m_sMsg, 256, "removed a FreezeBomb on", "取消冰冻炸弹");
		ReplaceString(m_sMsg, 256, "set blind on", "设置致盲");
		ReplaceString(m_sMsg, 256, "set gravity on", "设置重力");
		ReplaceString(m_sMsg, 256, "unrenamed", "取消改名");
		ReplaceString(m_sMsg, 256, "renamed", "改名");
		ReplaceString(m_sMsg, 256, "undrugged", "取消毒药");
		ReplaceString(m_sMsg, 256, "drugged", "下毒药");
		ReplaceString(m_sMsg, 256, "teleported", "传送");
		ReplaceString(m_sMsg, 256, "triggered sm_say", "管理员频道喊话");
		ReplaceString(m_sMsg, 256, "triggered sm_msay", "管理员频道喊话");
		ReplaceString(m_sMsg, 256, "triggered sm_csay", "管理员频道喊话");
		ReplaceString(m_sMsg, 256, "triggered sm_hsay", "管理员频道喊话");
		ReplaceString(m_sMsg, 256, "triggered sm_psay", "管理员频道私聊");
		ReplaceString(m_sMsg, 256, "toggled noclip on", "触发穿墙效果");
		ReplaceString(m_sMsg, 256, "changed map to", "更换地图");
		ReplaceString(m_sMsg, 256, "kicked", "踢出");
		ReplaceString(m_sMsg, 256, "reason", "原因");
		ReplaceString(m_sMsg, 256, "added ban", "封禁离线玩家");
		char emsg[512];
		SQL_EscapeString(g_hDatabase, m_sMsg, emsg, 512);
		Format(m_szQuery, 512, "INSERT INTO `sb_adminlog` VALUES (DEFAULT, (IF((SELECT aid FROM `sb_admins` WHERE authid = '%s')>0,(SELECT aid FROM `sb_admins` WHERE authid = '%s'),-1)),%d,'%s',DEFAULT);", m_szClientauth, m_szClientauth, g_iServerId, emsg);
		SQL_TQuery(g_hDatabase, SQLCallback_CheckAdminLog, m_szQuery);
	}

	return Plugin_Handled;
}