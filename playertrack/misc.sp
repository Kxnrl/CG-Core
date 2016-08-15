stock bool IsClientBot(int client)
{
	//是不是有效的客户
	if(client < 1 || client > MaxClients || IsFakeClient(client))
		return true;

	//是不是BOT
	char SteamID[32];
	GetClientAuthId(client, AuthId_Steam2, SteamID, 32, true);

	if(StrEqual(SteamID, "BOT", false))
		return true;

	return false;
}

stock bool IsValidClient(int client, bool checkBOT = false)
{
	if(client > MaxClients || client < 1)
		return false;

	if(!IsClientInGame(client) || IsFakeClient(client))
		return false;
	
	if(checkBOT)
	{
		char SteamID[64];
		GetClientAuthId(client, AuthId_Steam2, SteamID, 32);

		if(StrEqual(SteamID, "BOT", false))
		return false;
	}

	return true;
}

public void SettingAdver()
{
	Handle kv = CreateKeyValues("ServerAdvertisement", "", "");
	char FILE_PATH[256];
	BuildPath(Path_SM, FILE_PATH, 256, "configs/ServerAdvertisement.cfg");
	
	if(KvJumpToKey(kv, "Settings", true))
	{
		KvSetString(kv, "enable", "1");
		KvSetFloat(kv, "Delay_between_messages", 30.0);
		KvSetString(kv, "Advertisement_tag", "[{purple}Planeptune{default}] ^");
		KvSetString(kv, "Time_Format", "%H:%M:%S");
		KvGoBack(kv);
		KvRewind(kv);
		KeyValuesToFile(kv, FILE_PATH);
	}
	CloseHandle(kv);
	kv = INVALID_HANDLE;

	if(0 < g_iServerId)
	{
		char query[280];
		Format(query, 280, "SELECT * FROM playertrack_adv WHERE sid = '%i' OR sid = '0'", g_iServerId);
		SQL_TQuery(g_hDB_csgo, SQLCallback_GetAdvData, query, _, DBPrio_High);
	}
}

public void SetClientVIP(int client, int type)
{
	g_eClient[client][bIsVip] = true;
	g_eClient[client][iVipType] = type;
	
	char steamid[32];
	GetClientAuthId(client, AuthId_Steam2, steamid, 32);

	if(GetUserAdmin(client) == INVALID_ADMIN_ID && FindAdminByIdentity(AUTHMETHOD_STEAM, steamid) == INVALID_ADMIN_ID)
	{
		AdminId adm = CreateAdmin(g_eClient[client][szDiscuzName]);
		
		BindAdminIdentity(adm, AUTHMETHOD_STEAM, steamid);
		
		SetAdminFlag(adm, Admin_Reservation, true);
		SetAdminFlag(adm, Admin_Generic, true);
		SetAdminFlag(adm, Admin_Custom2, true);
		
		if(type == 3)
		{
			SetAdminFlag(adm, Admin_Custom5, true);
			SetAdminFlag(adm, Admin_Custom6, true);
			SetAdminImmunityLevel(adm, 9);
		}
		else if(type == 2)
		{
			SetAdminFlag(adm, Admin_Custom6, true);
			SetAdminImmunityLevel(adm, 8);
		}
		else if(type == 1)
		{
			SetAdminImmunityLevel(adm, 5);
		}
		
		RunAdminCacheChecks(client);
	}
	else
	{
		AdminId adm = GetUserAdmin(client);
		AdminId admid = FindAdminByIdentity(AUTHMETHOD_STEAM, steamid);
		
		if(adm == admid)
		{
			if(!GetAdminFlag(adm, Admin_Reservation))
				SetAdminFlag(adm, Admin_Reservation, true);
			
			if(!GetAdminFlag(adm, Admin_Generic))
				SetAdminFlag(adm, Admin_Generic, true);
		
			if(!GetAdminFlag(adm, Admin_Custom2))
				SetAdminFlag(adm, Admin_Custom2, true);
			
			if(GetAdminImmunityLevel(adm) < 5)
					SetAdminImmunityLevel(adm, 5);

			if(type == 3)
			{
				if(!GetAdminFlag(adm, Admin_Custom5))
					SetAdminFlag(adm, Admin_Custom5, true);
				
				if(!GetAdminFlag(adm, Admin_Custom6))
					SetAdminFlag(adm, Admin_Custom6, true);
				
				if(GetAdminImmunityLevel(adm) < 9)
					SetAdminImmunityLevel(adm, 9);
			}
			else if(type == 2)
			{
				if(!GetAdminFlag(adm, Admin_Custom6))
					SetAdminFlag(adm, Admin_Custom6, true);
				
				if(GetAdminImmunityLevel(adm) < 8)
					SetAdminImmunityLevel(adm, 8);
			}
		}
		
	}

	VipChecked(client);
}

public void GetClientFlags(int client)
{
	//先获得客户flags
	int flags = GetUserFlagBits(client);
	
	//取得32位ID
	char auth[32];
	GetClientAuthId(client, AuthId_Steam2, auth, 32, true);

	//Main判定
	if(StrEqual(auth, "STEAM_1:1:44083262")|| StrEqual(auth, "STEAM_1:1:3339181") || StrEqual(auth, "STEAM_1:0:3339246"))
	{
		strcopy(g_eClient[client][szAdminFlags], 64, "守护女神");
	}
	//没flags就是普通玩家
	else if(flags == 0)
	{
		strcopy(g_eClient[client][szAdminFlags], 64, "普通玩家");
	}
	//狗管理权限为 CVAR
	else if(flags & ADMFLAG_CONVARS)
	{
		strcopy(g_eClient[client][szAdminFlags], 64, "管理员");
	}
	//狗OP权限为 CHANGEMAP
	else if(flags & ADMFLAG_CHANGEMAP)
	{
		strcopy(g_eClient[client][szAdminFlags], 64, "服务器OP");
	}
	//永久VIP权限为 Custom5
	else if(flags & ADMFLAG_CUSTOM5)
	{
		strcopy(g_eClient[client][szAdminFlags], 64, "永久VIP");
	}
	//年费VIP权限为 Custom6
	else if(flags & ADMFLAG_CUSTOM6)
	{
		strcopy(g_eClient[client][szAdminFlags], 64, "年费VIP");
	}
	//月费VIP权限为 Custom2
	else if(flags & ADMFLAG_CUSTOM2)
	{
		strcopy(g_eClient[client][szAdminFlags], 64, "月费VIP");
	}
	//以上都不是则为普通玩家
	else
	{
		strcopy(g_eClient[client][szAdminFlags], 64, "CG玩家");
	}
}

void PrintConsoleInfo(int client)
{
	int timeleft;
	GetMapTimeLeft(timeleft);
	
	if(timeleft <= 0)
		return;
	
	char szTimeleft[32], szMap[128], szHostname[128];
	Format(szTimeleft, 32, "%d:%02d", timeleft / 60, timeleft % 60);
	GetCurrentMap(szMap, 128);
	GetConVarString(FindConVar("hostname"), szHostname, 128);

	PrintToConsole(client, "-----------------------------------------------------------------------------------------------");
	PrintToConsole(client, "                                                                                               ");
	PrintToConsole(client, "                                     欢迎来到[CG]游戏社区                                      ");	
	PrintToConsole(client, "                                                                                               ");
	PrintToConsole(client, "当前服务器:  %s   -   Tickrate: %i.0", szHostname, RoundToNearest(1.0 / GetTickInterval()));
	PrintToConsole(client, " ");
	PrintToConsole(client, "论坛地址: https://csgogamers.com  官方QQ群: 107421770  官方YY: 435773");
	PrintToConsole(client, "当前地图: %s   剩余时间: %s", szMap, szTimeleft);
	PrintToConsole(client, "                                                                                               ");
	PrintToConsole(client, "服务器基础命令:");
	PrintToConsole(client, "商店相关： !store [打开商店]  !credits [显示余额]      !inv       [查看库存]");
	PrintToConsole(client, "地图相关： !rtv   [滚动投票]  !revote  [重新选择]      !nominate  [预定地图]");
	PrintToConsole(client, "娱乐相关： !music [点歌菜单]  !stop    [停止地图音乐]  !musicstop [停止点播歌曲]");
	PrintToConsole(client, "其他命令： !sign  [每日签到]  !hide    [屏蔽足迹霓虹]  !tp/!seeme [第三人称视角]");
	PrintToConsole(client, "玩家认证： !rz    [查询认证]  !exp     [查询经验值]");
	PrintToConsole(client, "搞基系统： !cp    [功能菜单]  !skill   [技能菜单]");
	PrintToConsole(client, "信仰系统： !faith [功能菜单]  !fhelp   [帮助菜单]");
	PrintToConsole(client, "                                                                                               ");
	PrintToConsole(client, "-----------------------------------------------------------------------------------------------");		
	PrintToConsole(client, "                                                                                               ");
}