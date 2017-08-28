#pragma semicolon 1
#pragma newdecls required

#include <sourcebans>

#undef REQUIRE_PLUGIN
#include <adminmenu>
#include <geoip>

#define Prefix "[\x02SourceBans\x01]  "

int g_BanTarget[MAXPLAYERS+1] = {-1, ...};
int g_BanTime[MAXPLAYERS+1] = {-1, ...};

Handle hTopMenu = INVALID_HANDLE;

char ServerIp[24];

/* Admin Stuff*/
bool g_bAdminLoading;
AdminFlag g_FlagLetters[26];

/* Admin KeyValues */
char adminsLoc[128];

/* Database handle */
Handle g_hDatabase;

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

/* Server Id */
int g_iServerId = -1;

/* Ban Type */
g_iBanType[MAXPLAYERS+1];

public Plugin myinfo =
{
	name		= "SourceBans [Redux]",
	author		= "SourceBans Development Team, Sarabveer(VEER™), Kyle",
	description	= "Advanced ban management for the Source engine",
	version		= "2.1+dev11 [Base on SB-1.5.3F]",
	url			= "http://steamcommunity.com/id/_xQy_/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("sourcebans");
	CreateNative("SBBanPlayer", Native_SBBanPlayer);
	CreateNative("SBAddBan", Native_SBAddBan);
	g_bLateLoaded = late;
	
	MarkNativeAsOptional("GeoipCode2");

	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("plugin.basecommands");
	LoadTranslations("sourcebans.phrases");
	LoadTranslations("basebans.phrases");

	RegServerCmd("Server_Rehash", Server_Rehash, "Reload SQL admins");

	RegAdminCmd("sm_ban", CommandBan, ADMFLAG_BAN, "sm_ban <#userid|name> <minutes|0> [reason]", "sourcebans");
	RegAdminCmd("sb_reload", _CmdReload, ADMFLAG_RCON, "Reload sourcebans config and ban reason menu options", "sourcebans");

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
	
	g_bConnecting = true;

	SQL_TConnect(GotDatabase, "csgo");

	BuildPath(Path_SM, logFile, 128, "logs/sourcebans.log");
	BuildPath(Path_SM, adminsLoc, 128,"configs/admins.cfg");

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
	
	if(g_bAdminLoading)
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
	if(auth[0] == 'B' || auth[9] == 'L' || auth[0] == 'G')
	{
		PlayerStatus[client] = true;
		return;
	}
	
	if(g_hDatabase == INVALID_HANDLE)
	{
		if(PlayerRecheck[client] != INVALID_HANDLE)
			KillTimer(PlayerRecheck[client]);

		PlayerRecheck[client] = CreateTimer(30.0, ClientRecheck, client);
		return;
	}

	char m_szQuery[512], ip[16];
	GetClientIP(client, ip, 16);
	FormatEx(m_szQuery, 512, "SELECT bid, ends, length, reason, sid, btype FROM sb_bans WHERE ((type = 0 AND authid REGEXP '^STEAM_[0-9]:%s$') OR (type = 1 AND ip = '%s')) AND (length = '0' OR ends > UNIX_TIMESTAMP()) AND (RemoveType IS NULL)", auth[8], ip);
	SQL_TQuery(g_hDatabase, VerifyBan, m_szQuery, GetClientUserId(client), DBPrio_High);
}

public void OnRebuildAdminCache(AdminCachePart part)
{
	if(g_hDatabase == INVALID_HANDLE)
	{
		if(!g_bConnecting)
		{
			g_bConnecting = true;
			SQL_TConnect(GotDatabase,"sourcebans");
		}
		return;
	}

	if(part == AdminCache_Admins)
		LoadAdminsAndGroups();
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if(g_ownReasons[client])
	{
		char reason[512];
		strcopy(reason, 512, sArgs);
		StripQuotes(reason);
		g_ownReasons[client] = false;
		PrepareBan(client, g_BanTarget[client], g_BanTime[client], reason);

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
			PrepareBan(param1, g_BanTarget[param1], g_BanTime[param1], info);
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
			PrepareBan(param1, g_BanTarget[param1], g_BanTime[param1], info);
		
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

void DisplayBanTargetMenu(int client)
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

void DisplayBanTimeMenu(int client)
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

void ResetMenu()
{
	if(ReasonMenuHandle != INVALID_HANDLE)
	{
		RemoveAllMenuItems(ReasonMenuHandle);
	}
	if(HackingMenuHandle != INVALID_HANDLE)
	{
		RemoveAllMenuItems(HackingMenuHandle);
	}
}

public void GotDatabase(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogToFileEx(logFile, "Database failure: %s.", error);
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
		LogToFileEx(logFile, "Ban Failed: %s", error);
		return;
	}

	if(hndl == INVALID_HANDLE || error[0])
	{
		LogToFileEx(logFile, "Verify Insert Query Failed: %s", error);
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

		LogToFileEx(logFile, "VerifyInsert => admin: \"%L\" client: \"%s<%s>\" length: %d", admin, name, auth, time);
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
			ShowActivityEx(admin, "[SourceBans]", "%t", "Permabanned player", Name);
		else
			ShowActivityEx(admin, "[SourceBans]", "%t","Permabanned player reason", Name, Reason);
	}
	else
	{
		if(Reason[0] == '\0')
			ShowActivityEx(admin, "[SourceBans]", "%t", "Banned player", Name, time);
		else
			ShowActivityEx(admin, "[SourceBans]", "%t", "Banned player reason", Name, time, Reason);
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
		LogToFileEx(logFile, "Add Ban Select Query Failed: %s", error);
		if(admin && IsClientInGame(admin))
			PrintToChat(admin, "%s 封禁 %s[%s] 失败", Prefix, nickName, authid);

		return;
	}

	char bantype[32];
	strcopy(bantype, 32, "全服封禁");
	if(!admin)
	{
		if(FindPluginByFile("ct.smx")) strcopy(bantype, 32, "匪镇谍影封禁");
		if(FindPluginByFile("mg_stats.smx")) strcopy(bantype, 32, "娱乐休闲封禁");
		if(FindPluginByFile("sm_hosties.smx")) strcopy(bantype, 32, "越狱搞基封禁");
		if(FindPluginByFile("zombiereloaded.smx")) strcopy(bantype, 32, "僵尸逃跑封禁");
		if(FindPluginByFile("deathmatch.smx") || FindPluginByFile("public_ext.smx") || FindPluginByFile("warmod.smx")) strcopy(bantype, 32, "竞技模式封禁");
		if(FindPluginByFile("KZTimerGlobal.smx")) strcopy(bantype, 32, "KZ跳跃封禁");
		if(StrContains(reason, "CAT", false) != -1) strcopy(bantype, 32, "全服封禁");
	}else strcopy(bantype, 32, "单服封禁");

	if(SQL_GetRowCount(hndl))
	{
		int sid = SQL_FetchInt(hndl, 1);
		if(StrEqual(bantype, "单服封禁") && sid == g_iServerId)
		{
			if(admin && IsClientInGame(admin))
				PrintToChat(admin, "%s %s[%s]已经被封禁.", Prefix, nickName, authid);
		}

		return;
	}

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
		LogToFileEx(logFile, "Add Ban Insert Query Failed: %s", error);
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
		LogToFileEx(logFile, "INSERT Admin Log to Database Failed! Error: %s", error);
		return;
	}
}

void LoadAdminsAndGroups()
{
	char query[512];

	FormatEx(query,1024,"SELECT authid, srv_flags, user, immunity FROM sb_admins_servers_groups AS asg LEFT JOIN sb_admins AS a ON a.aid = asg.admin_id WHERE server_id = %d AND lastvisit > UNIX_TIMESTAMP()-259200 AND hide = 0 GROUP BY aid, authid, srv_password, srv_group, srv_flags, user", g_iServerId, g_iServerId);
	SQL_TQuery(g_hDatabase,AdminsDone,query);
	g_bAdminLoading = true;
}

public void ServerInfoCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if(error[0] || hndl	== INVALID_HANDLE)
	{
		LogToFileEx(logFile, "Server Select Query Failed: %s", error);
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
		LogToFileEx(logFile, "Query Failed: %s", error);
	}
}

public void VerifyBan(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!client)
		return;

	if(hndl == INVALID_HANDLE)
	{
		LogToFileEx(logFile, "Verify Ban Query Failed: %s", error);
		PlayerRecheck[client] = CreateTimer(30.0, ClientRecheck, client);
		return;
	}

	char clientName[128];
	char clientAuth[128];
	char clientIp[128];
	GetClientIP(client, clientIp, 128);
	GetClientAuthId(client, AuthId_Steam2, clientAuth, 128, true);
	GetClientName(client, clientName, 128);
	if(SQL_GetRowCount(hndl))
	{
		char buffer[40], Name[128], m_szQuery[512], KickMsg[256], Reason[128], Expired[128], bType[32], bantype[32];
		if(FindPluginByFile("ct.smx")) strcopy(bantype, 32, "匪镇谍影封禁");
		if(FindPluginByFile("mg_stats.smx")) strcopy(bantype, 32, "娱乐休闲封禁");
		if(FindPluginByFile("sm_hosties.smx")) strcopy(bantype, 32, "越狱搞基封禁");
		if(FindPluginByFile("zombiereloaded.smx")) strcopy(bantype, 32, "僵尸逃跑封禁");
		if(FindPluginByFile("deathmatch.smx") || FindPluginByFile("public_ext.smx") || FindPluginByFile("warmod.smx")) strcopy(bantype, 32, "竞技模式封禁");
		if(FindPluginByFile("KZTimerGlobal.smx")) strcopy(bantype, 32, "KZ跳跃封禁");

		while(SQL_FetchRow(hndl))
		{
			int StartTime = SQL_FetchInt(hndl, 1);
			int Length = SQL_FetchInt(hndl, 2);
			SQL_FetchString(hndl, 3, Reason, 128);
			int sid = SQL_FetchInt(hndl, 4);
			SQL_FetchString(hndl, 5, bType, 32);
			if(StrEqual(bType, "全服封禁") || StrEqual(bType, bantype) || (StrEqual(bType, "单服封禁") && sid == g_iServerId))
			{
				SQL_EscapeString(g_hDatabase, clientName, Name, 128);
				FormatEx(m_szQuery, 512, "INSERT INTO sb_banlog VALUES (%d, UNIX_TIMESTAMP(), '%s', '%s', %d)", g_iServerId, Name, clientIp, SQL_FetchInt(hndl, 0));
				SQL_TQuery(g_hDatabase, ErrorCheckCallback, m_szQuery, client, DBPrio_High);
				FormatEx(buffer, 40, "banid 2 %s", clientAuth);
				ServerCommand(buffer);
				if(Length != 0)
					FormatTime(Expired, 128, "%Y.%m.%d %H:%M:%S", StartTime);
				else
					FormatEx(Expired, 128, "永久封禁");
				FormatEx(KickMsg, 256, "你已被: %s[原因:%s][到期时间:%s]  请登陆 https://csgogamers.com/banned/ 查看详细信息", bType, Reason, Expired);
				KickClient(client, KickMsg);
				return;
			}
		}
	}

	PlayerStatus[client] = true;
}

public void AdminsDone(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		g_bAdminLoading = false;
		CheckLoadAdmins();
		LogToFileEx(logFile, "Failed to retrieve admins from the database, %s", error);
		return;
	}

	char identity[66];
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
		SQL_FetchString(hndl,1,flags,32);
		SQL_FetchString(hndl,2,name,66);

		Immunity = SQL_FetchInt(hndl,3);
		
		TrimString(name);
		TrimString(identity);
		TrimString(flags);

		KvJumpToKey(adminsKV, name, true);
		
		KvSetString(adminsKV, "auth", "steam");
		KvSetString(adminsKV, "identity", identity);
		
		if(strlen(flags) > 0)
			KvSetString(adminsKV, "flags", flags);

		if(Immunity > 0)
			KvSetNum(adminsKV, "immunity", Immunity);
		
		KvRewind(adminsKV);

		if((curAdm = FindAdminByIdentity("steam", identity)) == INVALID_ADMIN_ID)
		{
			curAdm = CreateAdmin(name);
			if(!BindAdminIdentity(curAdm, "steam", identity))
			{
				LogToFileEx(logFile, "Unable to bind admin %s to identity %s", name, identity);
				RemoveAdmin(curAdm);
				continue;
			}
		}

		for (int i = 0; i < strlen(flags); ++i)
		{
			if(flags[i] < 'a' || flags[i] > 'z')
				continue;
				
			if(g_FlagLetters[flags[i] - 'a'] < Admin_Reservation)
				continue;
				
			SetAdminFlag(curAdm, g_FlagLetters[flags[i] - 'a'], true);
		}

		if(GetAdminImmunityLevel(curAdm) < Immunity)
			SetAdminImmunityLevel(curAdm, Immunity);

		++admCount;
	}
	
	KeyValuesToFile(adminsKV, adminsLoc);
	CloseHandle(adminsKV);
	
	g_bAdminLoading = false;

	CheckLoadAdmins();
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

void PrepareMenu()
{
	AddMenuItem(ReasonMenuHandle, "Own Reason",	"手动输入原因");
	AddMenuItem(ReasonMenuHandle, "Hacking", "作弊");
	AddMenuItem(ReasonMenuHandle, "Exploit", "卡bug");
	AddMenuItem(ReasonMenuHandle, "zaoyao",  "造谣");
	AddMenuItem(ReasonMenuHandle, "badmic",  "卡麦");
	AddMenuItem(ReasonMenuHandle, "maren",   "喷粪");

	AddMenuItem(HackingMenuHandle, "Aimbot", "自瞄作弊");
	AddMenuItem(HackingMenuHandle, "Wallhack", "透视作弊");
	AddMenuItem(HackingMenuHandle, "aimware", "暴力作弊");
	AddMenuItem(HackingMenuHandle, "autobhop", "连跳作弊");
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

	PrepareBan(client, target, time, reason);
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
	
	char bantype[32];
	strcopy(bantype, 32, "全服封禁");
	if(!client)
	{
		if(FindPluginByFile("ct.smx")) strcopy(bantype, 32, "匪镇谍影封禁");
		if(FindPluginByFile("mg_stats.smx")) strcopy(bantype, 32, "娱乐休闲封禁");
		if(FindPluginByFile("sm_hosties.smx")) strcopy(bantype, 32, "越狱搞基封禁");
		if(FindPluginByFile("zombiereloaded.smx")) strcopy(bantype, 32, "僵尸逃跑封禁");
		if(FindPluginByFile("deathmatch.smx") || FindPluginByFile("public_ext.smx") || FindPluginByFile("warmod.smx")) strcopy(bantype, 32, "竞技模式封禁");
		if(FindPluginByFile("KZTimerGlobal.smx")) strcopy(bantype, 32, "KZ跳跃封禁");
		if(StrContains(reason, "CAT", false) != -1) strcopy(bantype, 32, "全服封禁");
	}else strcopy(bantype, 32, "单服封禁");

	char Query[256];
	FormatEx(Query, 256, "SELECT bid, sid FROM sb_bans WHERE type = 0 AND authid = '%s' AND (length = 0 OR ends > UNIX_TIMESTAMP()) AND RemoveType IS NULL AND btype = '%s'", authid, bantype);
	SQL_TQuery(g_hDatabase, SelectAddbanCallback, Query, dataPack, DBPrio_High);
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
	}
	else
	{
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
			UTIL_InsertBan(time, name, auth, ip, reason, adminAuth, adminIp, dataPack);
		else
			LogToFileEx(logFile, "CreateBan => admin: \"%L\" client: \"%s<%s>\" length: %d", admin, name, auth, time);
	}
	else
	{
		PlayerDataPack[admin] = dataPack;
		DisplayMenu(ReasonMenuHandle, admin, MENU_TIME_FOREVER);
		PrintToChat(admin, "%s %t", Prefix, "Check Menu");
	}

	return true;
}

void GetCountryCode2(const char[] ip, char[] country)
{
	if(GetFeatureStatus(FeatureType_Native, "GeoipCode2") != FeatureStatus_Available)
		return;

	char buffer[4];
	GeoipCode2(ip, buffer);
	strcopy(country, 4, buffer);
}

void UTIL_InsertBan(int time, const char[] Name, const char[] Authid, const char[] Ip, const char[] Reason, const char[] AdminAuthid, const char[] AdminIp, Handle Pack)
{
	char banName[128], banReason[256], m_szQuery[1024], country[4], bantype[32], adminAuth[32];
	SQL_EscapeString(g_hDatabase, Name, banName, 128);
	SQL_EscapeString(g_hDatabase, Reason, banReason, 256);
	GetCountryCode2(Ip, country);
	
	strcopy(adminAuth, 32, AdminAuthid);
	int admin = FindClientBySteamId(adminAuth);
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
	if(admin == 0)
	{
		if(StrContains(banReason, "CAT") == 0)
			strcopy(bantype, 32, "全服封禁");

		if(StrContains(banReason, "发起的VIP投票封禁") != -1)
		{
			strcopy(bantype, 32, "单服封禁");
			strcopy(adminAuth, 32, "STEAM_ID_VIP");
		}
	}
	
	FormatEx(m_szQuery, 1024, "INSERT INTO sb_bans (ip, authid, name, created, ends, length, reason, aid, adminIp, sid, btype, country) VALUES \
						('%s', '%s', '%s', UNIX_TIMESTAMP(), UNIX_TIMESTAMP() + %d, %d, '%s', IFNULL((SELECT aid FROM sb_admins WHERE authid = '%s' OR authid REGEXP '^STEAM_[0-9]:%s$'),'0'), '%s', \
						%d, '%s', '%s')",
						Ip, Authid, banName, (time*60), (time*60), banReason, adminAuth, adminAuth[8], AdminIp, g_iServerId, bantype, country);

	SQL_TQuery(g_hDatabase, VerifyInsert, m_szQuery, Pack, DBPrio_High);
}

int FindClientBySteamId(const char[] steamid)
{
	char m_szAuth[32];
	for(int client  = 1; client <= MaxClients; ++client)
		if(IsClientAuthorized(client) && GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true))
			if(StrEqual(m_szAuth, steamid))
				return client;
			
	return 0;
}

void CheckLoadAdmins()
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

void InsertServerInfo()
{
	char query[100];
	int ip = GetConVarInt(FindConVar("hostip"));
	Format(ServerIp, 64, "%d.%d.%d.%d", ((ip & 0xFF000000) >> 24) & 0xFF, ((ip & 0x00FF0000) >> 16) & 0xFF, ((ip & 0x0000FF00) >>  8) & 0xFF, ((ip & 0x000000FF) >>  0) & 0xFF);

	FormatEx(query, 100, "SELECT sid FROM sb_servers WHERE ip = '%s' AND port = '%d'", ServerIp, GetConVarInt(FindConVar("hostport")));
	SQL_TQuery(g_hDatabase, ServerInfoCallback, query);
}

void PrepareBan(int client, int target, int time, char[] reason)
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
				ShowActivity(client, "%t", "Permabanned player", name);
			else
				ShowActivity(client, "%t", "Permabanned player reason", name, reason);
		}
		else
		{
			if(reason[0] == '\0')
				ShowActivity(client, "%t", "Banned player", name, time);
			else
				ShowActivity(client, "%t", "Banned player reason", name, time, reason);
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

void ResetSettings()
{
	ResetMenu();
	PrepareMenu();
}

public Action OnLogAction(Handle source, Identity ident, int client, int target, const char[] message)
{
	if(client < 1 || GetUserAdmin(client) == INVALID_ADMIN_ID || g_hDatabase == INVALID_HANDLE || StrContains(message, "console command") >= 0 || StrContains(message, "sm_chat") >= 0)
		return Plugin_Continue;
	
	char emsg[512], m_szQuery[512], m_sMsg[256], m_szClientauth[32], m_szClientid[128];

	if(target >= 1 && client != target)
	{
		char m_szTargetauth[32], m_szTargetid[128], m_szTmp[32], m_szTmp2[128];
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
	}
	else
	{
		GetClientAuthId(client, AuthId_Steam2, m_szClientauth, 32, true);
		Format(m_szClientid, 128, "\"%N<%d><%s><>\"", client, GetClientUserId(client), m_szClientauth);
		Format(m_sMsg, 256, "%s", message);
		ReplaceString(m_sMsg, 256, m_szClientid, "自己");
	}

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
	ReplaceString(m_sMsg, 256, "respawned", "重生玩家");

	SQL_EscapeString(g_hDatabase, m_sMsg, emsg, 512);
	Format(m_szQuery, 512, "INSERT INTO `sb_adminlog` VALUES (DEFAULT, (IF((SELECT aid FROM `sb_admins` WHERE authid = '%s')>0,(SELECT aid FROM `sb_admins` WHERE authid = '%s'),-1)),%d,'%s',DEFAULT);", m_szClientauth, m_szClientauth, g_iServerId, emsg);
	SQL_TQuery(g_hDatabase, SQLCallback_CheckAdminLog, m_szQuery);

	return Plugin_Handled;
}