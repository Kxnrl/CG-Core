void InitLogFile()
{
	BuildPath(Path_SM, g_szLogFile, 128, "logs/Core.log");
}

void InitServerIP()
{
	int ip = GetConVarInt(FindConVar("hostip"));
	Format(g_szIP, 32, "%d.%d.%d.%d:%d", ((ip & 0xFF000000) >> 24) & 0xFF, ((ip & 0x00FF0000) >> 16) & 0xFF, ((ip & 0x0000FF00) >>  8) & 0xFF, ((ip & 0x000000FF) >>  0) & 0xFF, GetConVarInt(FindConVar("hostport")));
}

void InitDate()
{
	char m_szDate[32];
	FormatTime(m_szDate, 64, "%Y%m%d", GetTime());
	g_iNowDate = StringToInt(m_szDate);
}

void InitGame()
{
	g_eGame = GetEngineVersion();
}

void InitCommands()
{
	RegConsoleCmd("sm_sign", Command_Login);
	RegConsoleCmd("sm_qiandao", Command_Login);
	RegConsoleCmd("sm_online", Command_Online);
	RegConsoleCmd("sm_track", Command_Track);
	RegConsoleCmd("sm_rz", Command_GetAuth);
	RegConsoleCmd("sm_cp", Command_CP);
	RegConsoleCmd("sm_lily", Command_CP);
	RegConsoleCmd("sm_cg", Command_Menu);
	RegConsoleCmd("sm_qm", Command_Signature);
	RegConsoleCmd("sm_language", Command_Language);

	RegAdminCmd("sm_reloadadv", Command_ReloadAdv, ADMFLAG_BAN);
}

void MarkNative()
{
	//Cstrike EXT
	MarkNativeAsOptional("CS_SetClientClanTag");
	
	//SDKTools EXT
	MarkNativeAsOptional("SetClientName");
	MarkNativeAsOptional("GetClientName");
}

void InitForward()
{
	g_Forward[ServerLoaded] = CreateGlobalForward("CG_OnServerLoaded", ET_Ignore);
	g_Forward[APISetCredits] = CreateGlobalForward("CG_APIStoreSetCredits", ET_Event, Param_Cell, Param_Cell, Param_String, Param_Cell);
	g_Forward[APIGetCredits] = CreateGlobalForward("CG_APIStoreGetCredits", ET_Event, Param_Cell);
	g_Forward[ClientSigned] = CreateGlobalForward("CG_OnClientDailySign", ET_Ignore, Param_Cell);
	g_Forward[ClientLoaded] = CreateGlobalForward("CG_OnClientLoaded", ET_Ignore, Param_Cell);
	g_Forward[ClientMarried] = CreateGlobalForward("CG_OnLilyCouple", ET_Ignore, Param_Cell, Param_Cell);
	g_Forward[ClientDivorce] = CreateGlobalForward("CG_OnLilyDivorce", ET_Ignore, Param_Cell, Param_Cell);
	g_Forward[OnNewDay] = CreateGlobalForward("CG_OnNewDay", ET_Ignore, Param_Cell);
	g_Forward[ClientAuthTerm] = CreateGlobalForward("CG_OnCheckAuthTerm", ET_Event, Param_Cell, Param_Cell);

	g_eEvents[round_start] = CreateGlobalForward("CG_OnRoundStart", ET_Ignore);
	g_eEvents[round_end] = CreateGlobalForward("CG_OnRoundEnd", ET_Ignore, Param_Cell);
	g_eEvents[player_spawn] = CreateGlobalForward("CG_OnClientSpawn", ET_Ignore, Param_Cell);
	g_eEvents[player_death] = CreateGlobalForward("CG_OnClientDeath", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_String);
	g_eEvents[player_hurt] = CreateGlobalForward("CG_OnClientHurted", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_String);
	g_eEvents[player_team] = CreateGlobalForward("CG_OnClientTeam", ET_Ignore, Param_Cell);
	g_eEvents[player_jump] = CreateGlobalForward("CG_OnClientJump", ET_Ignore, Param_Cell);
	g_eEvents[weapon_fire] = CreateGlobalForward("CG_OnClientFire", ET_Ignore, Param_Cell, Param_String);
	g_eEvents[player_name] = CreateGlobalForward("CG_OnClientName", ET_Ignore, Param_Cell, Param_String, Param_String);

	g_Forward[ClientVipChecked] = CreateForward(ET_Ignore, Param_Cell);
	CreateNative("HookClientVIPChecked", Native_HookOnClientVipChecked);
}

void InitNative()
{
	CreateNative("CG_GetServerId", Native_GetServerID);
	CreateNative("CG_GetClientOnlines", Native_GetOnlines);
	CreateNative("CG_GetClientVitality", Native_GetVitality);
	CreateNative("CG_GetClientLastseen", Native_GetLastseen);
	CreateNative("CG_GetClientDailyTime", Native_GetDailyTime);
	CreateNative("CG_GetClientId", Native_GetPlayerID);
	CreateNative("CG_GetClientUId", Native_GetDiscuzUID);
	CreateNative("CG_GetClientGId", Native_GetGroupID);
	CreateNative("CG_GetClientVip", Native_GetVipType);
	CreateNative("CG_GetClientPartner", Native_GetCPPartner);
	CreateNative("CG_GetClientLilyDate", Native_GetCPDate);
	CreateNative("CG_IsClientVIP", Native_IsClientVIP);
	CreateNative("CG_ShowNormalMotd", Native_ShowNormalMotd);
	CreateNative("CG_ShowHiddenMotd", Native_ShowHiddenMotd);
	CreateNative("CG_RemoveMotd", Native_RemoveMotd);
	CreateNative("CG_SetClientVIP", Native_SetClientVIP);
	CreateNative("CG_SaveDatabase", Native_SaveDatabase);
	CreateNative("CG_SaveForumData", Native_SaveForumData);
	CreateNative("CG_GetClientSignature", Native_GetSingature);
	CreateNative("CG_GetClientDName", Native_GetDiscuzName);
	CreateNative("CG_GetClientGName", Native_GetGroupName);
	CreateNative("CG_GetGameDatabase", Native_GetGameDatabase);
	CreateNative("CG_GetDiscuzDatabase", Native_GetDiscuzDatabase);
	CreateNative("CG_ShowGameText", Native_ShowGameText);
	CreateNative("CG_ShowGameTextAll", Native_ShowGameTextAll);
}

void InitEvents()
{
	//Hook 回合开始
	if(!HookEventEx("round_start", Event_RoundStart, EventHookMode_Post))
		LogToFileEx(g_szLogFile, "Hook Event \"round_start\" Failed");
	
	//Hook 回合结束
	if(!HookEventEx("round_end", Event_RoundEnd, EventHookMode_Post))
		LogToFileEx(g_szLogFile, "Hook Event \"round_end\" Failed");
	
	//Hook 玩家出生
	if(!HookEventEx("player_spawn", Event_PlayerSpawn, EventHookMode_Post))
		LogToFileEx(g_szLogFile, "Hook Event \"player_spawn\" Failed");

	//Hook 玩家死亡
	if(!HookEventEx("player_death", Event_PlayerDeath, EventHookMode_Post))
		LogToFileEx(g_szLogFile, "Hook Event \"player_death\" Failed");
	
	//Hook 玩家受伤
	if(!HookEventEx("player_hurt", Event_PlayerHurts, EventHookMode_Post))
		LogToFileEx(g_szLogFile, "Hook Event \"player_hurt\" Failed");
	
	//Hook 玩家队伍
	if(!HookEventEx("player_team", Event_PlayerTeam, EventHookMode_Pre))
		LogToFileEx(g_szLogFile, "Hook Event \"player_team\" Failed");

	//Hook 玩家跳跃
	if(!HookEventEx("player_jump", Event_PlayerJump, EventHookMode_Post))
		LogToFileEx(g_szLogFile, "Hook Event \"player_jump\" Failed");
	
	//Hook 武器射击
	if(!HookEventEx("weapon_fire", Event_WeaponFire, EventHookMode_Post))
		LogToFileEx(g_szLogFile, "Hook Event \"weapon_fire\" Failed");
	
	//Hook 玩家改名
	if(!HookEventEx("player_changename", Event_PlayerName, EventHookMode_Pre))
		LogToFileEx(g_szLogFile, "Hook Event \"player_changename\" Failed");
}

void InitClient(int client)
{
	g_eClient[client][bLoaded] = false;
	g_eClient[client][bListener] = false;
	g_eClient[client][bSignIn] = false;
	g_eClient[client][iUID] = -1;
	g_eClient[client][iSignNum] = 0;
	g_eClient[client][iSignTime] = 0;
	g_eClient[client][iConnectTime] = GetTime();
	g_eClient[client][iPlayerId] = 0;
	g_eClient[client][iNumber] = 0;
	g_eClient[client][iOnline] = 0;
	g_eClient[client][iVitality] = 0
	g_eClient[client][iLastseen] = 0;
	g_eClient[client][iDataRetry] = 0;
	g_eClient[client][iAnalyticsId] = -1;
	g_eClient[client][iVipType] = 0;
	g_eClient[client][iGroupId] = 0;
	g_eClient[client][iCPId] = -2;
	g_eClient[client][iCPDate] = 0;
	g_eClient[client][iDaily] = 0;

	strcopy(g_eClient[client][szIP], 32, "127.0.0.1");
	strcopy(g_eClient[client][szSignature], 256, "数据读取中...");
	strcopy(g_eClient[client][szDiscuzName], 256, "未注册");
	strcopy(g_eClient[client][szAdminFlags], 64, "Unknown");
	strcopy(g_eClient[client][szInsertData], 512, "");
	strcopy(g_eClient[client][szUpdateData], 512, "");
	strcopy(g_eClient[client][szGroupName], 64, "未认证");
	strcopy(g_eClient[client][szNewSignature], 256, "该玩家未设置签名");
	strcopy(g_eClient[client][szClientName], 32, "无名氏");
}

void GetNowDate()
{
	char m_szDate[32];
	FormatTime(m_szDate, 64, "%Y%m%d", GetTime());
	int iDate = StringToInt(m_szDate);
	if(iDate > g_iNowDate)
	{
		OnNewDayForward(iDate);
		
		for(int client = 1; client <= MaxClients; ++client)
			g_eClient[client][iDaily] = 0;
	}
}

void BuildTempLogFile()
{
	BuildPath(Path_SM, g_szTempFile, 128, "data/core.track.kv.txt");
	
	if(g_eHandle[KV_Local] != INVALID_HANDLE)
		CloseHandle(g_eHandle[KV_Local]);
	
	g_eHandle[KV_Local] = CreateKeyValues("core_track", "", "");
	
	FileToKeyValues(g_eHandle[KV_Local], g_szTempFile);
	
	while(KvGotoFirstSubKey(g_eHandle[KV_Local], true))
	{
		char m_szAuthId[32], m_szQuery[512], m_szIp[16], m_szFlag[32];
		KvGetSectionName(g_eHandle[KV_Local], m_szAuthId, 32);
		
		int m_iPlayerId = KvGetNum(g_eHandle[KV_Local], "PlayerId", 0);
		int m_iConnect = KvGetNum(g_eHandle[KV_Local], "Connect", 0);
		int m_iTrackId = KvGetNum(g_eHandle[KV_Local], "TrackID", 0);
		KvGetString(g_eHandle[KV_Local], "IP", m_szIp, 16, "127.0.0.1");
		int m_iLastTime = KvGetNum(g_eHandle[KV_Local], "LastTime", 0);
		KvGetString(g_eHandle[KV_Local], "Flag", m_szFlag, 32, "CG玩家");
		int m_iOnlines = m_iLastTime - m_iConnect;
		int m_iDaily = KvGetNum(g_eHandle[KV_Local], "DayTime", 0);
		Format(m_szQuery, 512, "UPDATE playertrack_player AS a, playertrack_analytics AS b SET a.onlines = a.onlines+%d, a.lastip = '%s', a.lasttime = '%d', a.number = a.number+1, a.flags = '%s', a.daytime = '%d', b.duration = '%d' WHERE a.id = '%d' AND b.id = '%d' AND a.steamid = '%s' AND b.playerid = '%d'", m_iOnlines, m_szIp, m_iLastTime, m_szFlag, m_iDaily, m_iOnlines, m_iPlayerId, m_iTrackId, m_szAuthId, m_iPlayerId);

		Handle data = CreateDataPack();
		WritePackString(data, m_szQuery);
		WritePackString(data, m_szAuthId);
		WritePackCell(data, m_iPlayerId);
		WritePackCell(data, m_iConnect);
		WritePackCell(data, m_iTrackId);
		WritePackString(data, m_szIp);
		WritePackCell(data, m_iLastTime);
		WritePackString(data, m_szFlag);
		ResetPack(data);
		MySQL_Query(g_eHandle[DB_Game], SQLCallback_SaveTempLog, m_szQuery, data);
		
		if(KvDeleteThis(g_eHandle[KV_Local]))
		{
			char m_szAfter[32];
			KvGetSectionName(g_eHandle[KV_Local], m_szAfter, 32);
			if(StrContains(m_szAfter, "STEAM", false) != -1)
				KvGoBack(g_eHandle[KV_Local]);
		}
	}

	KvRewind(g_eHandle[KV_Local]);
	KeyValuesToFile(g_eHandle[KV_Local], g_szTempFile);
	
	//建立监听Timer
	CreateTimer(1.0, Timer_Tracking, _, TIMER_REPEAT);
}

void LoadTranstion()
{
	char m_szPath[128];
	BuildPath(Path_SM, m_szPath, 128, "translations/cg.core.phrases.txt");
	if(FileSize(m_szPath) != TRANSDATASIZE)
	{
		DeleteFile(m_szPath);
		TranslationToFile(m_szPath);
		Handle kv = CreateKeyValues("Phrases", "", "");
		FileToKeyValues(kv, m_szPath);
		KeyValuesToFile(kv, m_szPath);
		CloseHandle(kv);
		LogToFileEx(g_szLogFile, "TranslationToFile: %s    size: %d    version: %s", m_szPath, FileSize(m_szPath), PLUGIN_VERSION);
	}
	LoadTranslations("cg.core.phrases");
}

void SettingAdver()
{
	//创建Kv
	Handle kv = CreateKeyValues("ServerAdvertisement", "", "");
	char FILE_PATH[256];
	BuildPath(Path_SM, FILE_PATH, 256, "configs/ServerAdvertisement.cfg");
	KeyValuesToFile(kv, FILE_PATH);
	CloseHandle(kv);

	if(0 < g_iServerId)
	{
		char m_szQuery[128];
		Format(m_szQuery, 128, "SELECT * FROM playertrack_adv WHERE sid = '%i' OR sid = '0'", g_iServerId);
		MySQL_Query(g_eHandle[DB_Game], SQLCallback_GetAdvData, m_szQuery, _, DBPrio_High);
	}
}

void SetClientVIP(int client, int type)
{
	//设置VIP(Allow API)
	g_eClient[client][iVipType] = type;
	
	char m_szAuth[32];
	GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);

	//看看这个VIP是不是OP? 并且补起各个权限和权重
	if(GetUserAdmin(client) == INVALID_ADMIN_ID && FindAdminByIdentity(AUTHMETHOD_STEAM, m_szAuth) == INVALID_ADMIN_ID)
	{
		AdminId adm = CreateAdmin(g_eClient[client][szDiscuzName]);
		
		BindAdminIdentity(adm, AUTHMETHOD_STEAM, m_szAuth);
		
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
		AdminId admid = FindAdminByIdentity(AUTHMETHOD_STEAM, m_szAuth);
		
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
	
	if(g_eGame == Engine_Left4Dead2)
	{
		RunAdminCacheChecks(client);
	}

	OnClientVipChecked(client);
}

void GetClientFlags(int client)
{
	//先获得客户flags
	int flags = GetUserFlagBits(client);
	
	//取得32位ID
	char m_szAuth[32];
	GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);

	//Main判定
	if(g_eClient[client][iGroupId] == 9999)
	{
		strcopy(g_eClient[client][szAdminFlags], 64, "CTO");
	}
	//狗管理CEO
	else if(g_eClient[client][iGroupId] == 9998)
	{
		strcopy(g_eClient[client][szAdminFlags], 64, "CEO");
	}
	//狗管理CIO
	else if(g_eClient[client][iGroupId] == 9992)
	{
		strcopy(g_eClient[client][szAdminFlags], 64, "CIO");
	}
	//狗OP权限为 CHANGEMAP
	else if(flags & ADMFLAG_CHANGEMAP)
	{
		strcopy(g_eClient[client][szAdminFlags], 64, "OP");
	}
	//永久VIP权限为 Custom5
	else if(flags & ADMFLAG_CUSTOM5)
	{
		strcopy(g_eClient[client][szAdminFlags], 64, "SVIP");
	}
	//年费VIP权限为 Custom6
	else if(flags & ADMFLAG_CUSTOM6)
	{
		strcopy(g_eClient[client][szAdminFlags], 64, "AVIP");
	}
	//月费VIP权限为 Custom2
	else if(flags & ADMFLAG_CUSTOM2)
	{
		strcopy(g_eClient[client][szAdminFlags], 64, "MVIP");
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
	
	if(timeleft <= 30)
		return;

	char szTimeleft[32], szMap[128], szHostname[128];
	Format(szTimeleft, 32, "%d:%02d", timeleft / 60, timeleft % 60);
	GetCurrentMap(szMap, 128);
	GetConVarString(FindConVar("hostname"), szHostname, 128);

	PrintToConsole(client, "-----------------------------------------------------------------------------------------------");
	PrintToConsole(client, "                                                                                               ");
	PrintToConsole(client, "                                     欢迎来到[CG]游戏社区                                      ");	
	PrintToConsole(client, "                                                                                               ");
	PrintToConsole(client, "当前服务器:  %s   -   Tickrate: %i.0   -   主程序版本: %s", szHostname, RoundToNearest(1.0 / GetTickInterval()), PLUGIN_VERSION);
	PrintToConsole(client, " ");
	PrintToConsole(client, "论坛地址: https://csgogamers.com  官方QQ群: 107421770  官方YY: 435773");
	PrintToConsole(client, "当前地图: %s   剩余时间: %s", szMap, szTimeleft);
	PrintToConsole(client, "                                                                                               ");
	PrintToConsole(client, "服务器基础命令:");
	PrintToConsole(client, "商店相关： !store [打开商店]  !credits [显示余额]      !inv       [查看库存]");
	PrintToConsole(client, "地图相关： !rtv   [滚动投票]  !revote  [重新选择]      !nominate  [预定地图]");
	PrintToConsole(client, "娱乐相关： !music [点歌菜单]  !stop    [停止地图音乐]  !musicstop [停止点播歌曲]");
	PrintToConsole(client, "其他命令： !sign  [每日签到]  !hide    [屏蔽足迹霓虹]  !tp/!seeme [第三人称视角]");
	PrintToConsole(client, "玩家认证： !track [查询认证]  !rz      [申请认证]");
	PrintToConsole(client, "搞基系统： !cp    [功能菜单]");
	PrintToConsole(client, "天赋系统： !talent[功能菜单]");
	PrintToConsole(client, "                                                                                               ");
	PrintToConsole(client, "-----------------------------------------------------------------------------------------------");		
	PrintToConsole(client, "                                                                                               ");
}

public int MenuHandler_CGMainMenu(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		if(strcmp(info, "store") == 0)
			FakeClientCommand(client, "sm_store");
		else if(strcmp(info, "lily") == 0)
			FakeClientCommand(client, "sm_lily");
		else if(strcmp(info, "talent") == 0)
			FakeClientCommand(client, "sm_talent");
		else if(strcmp(info, "sign") == 0)
			FakeClientCommand(client, "sm_sign");
		else if(strcmp(info, "auth") == 0)
			FakeClientCommand(client, "sm_rz");
		else if(strcmp(info, "vip") == 0)
			FakeClientCommand(client, "sm_vip");
		else if(strcmp(info, "rule") == 0)
			FakeClientCommand(client, "sm_rules");
		else if(strcmp(info, "group") == 0)
			FakeClientCommand(client, "sm_group");
		else if(strcmp(info, "forum") == 0)
			FakeClientCommand(client, "sm_forum");
		else if(strcmp(info, "music") == 0)
			FakeClientCommand(client, "sm_music");
		else if(strcmp(info, "radio") == 0)
			FakeClientCommand(client, "sm_radio");
		else if(strcmp(info, "online") == 0)
			FakeClientCommand(client, "sm_online");
		else if(strcmp(info, "setrp") == 0)
			FakeClientCommand(client, "sm_setrp");
		else if(strcmp(info, "huodo") == 0)
			FakeClientCommand(client, "sm_hd");
		else if(strcmp(info, "lang") == 0)
			Command_Language(client, -1);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public int MenuHandler_GetAuth(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		CheckClientAuthTerm(client, StringToInt(info));
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if(action == MenuAction_Cancel)
	{
		if(itemNum == MenuCancel_ExitBack)
			FakeClientCommand(client, "sm_cg");
	}
}

void BuildListenerMenu(int client)
{
	Handle menu = CreateMenu(MenuHandler_Listener);
	SetMenuTitleEx(menu, "[CG]  %T", "signature title", client);

	AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "%T", "signature now you can type", client);
	AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "%T", "signature color codes", client);
	AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "%T", "signature example", client);
	AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "%T", "signature input preview", client, g_eClient[client][szNewSignature]);
	
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "preview", "%T", "signature item preview", client);
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "ok", "%T", "signature item ok", client);
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 60);

	if(g_eClient[client][hListener] != INVALID_HANDLE)
	{
		KillTimer(g_eClient[client][hListener]);
		g_eClient[client][hListener] = INVALID_HANDLE;
	}

	g_eClient[client][bListener] = true;
	g_eClient[client][hListener] = CreateTimer(60.0, Timer_ListenerTimeout, client);
}

public int MenuHandler_Listener(Handle menu, MenuAction action, int client, int itemNum)
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		g_eClient[client][bListener] = false;
		if(g_eClient[client][hListener] != INVALID_HANDLE)
		{
			KillTimer(g_eClient[client][hListener]);
			g_eClient[client][hListener] = INVALID_HANDLE;
		}
		
		if(StrEqual(info, "preview"))
		{
			char m_szPreview[256];
			strcopy(m_szPreview, 256, g_eClient[client][szNewSignature]);
			ReplaceString(m_szPreview, 512, "{白}", "\x01");
			ReplaceString(m_szPreview, 512, "{红}", "\x02");
			ReplaceString(m_szPreview, 512, "{粉}", "\x03");
			ReplaceString(m_szPreview, 512, "{绿}", "\x04");
			ReplaceString(m_szPreview, 512, "{黄}", "\x05");
			ReplaceString(m_szPreview, 512, "{亮绿}", "\x06");
			ReplaceString(m_szPreview, 512, "{亮红}", "\x07");
			ReplaceString(m_szPreview, 512, "{灰}", "\x08");
			ReplaceString(m_szPreview, 512, "{褐}", "\x09");
			ReplaceString(m_szPreview, 512, "{橙}", "\x10");
			ReplaceString(m_szPreview, 512, "{紫}", "\x0E");
			ReplaceString(m_szPreview, 512, "{亮蓝}", "\x0B");
			ReplaceString(m_szPreview, 512, "{蓝}", "\x0C");
			tPrintToChat(client, "签名预览: %s", m_szPreview);
			BuildListenerMenu(client);
		}
		if(StrEqual(info, "ok"))
		{
			if(!OnAPIStoreSetCredits(client, -500, "设置签名", true))
			{
				tPrintToChat(client, "%s  %T", PLUGIN_PREFIX, "signature you have not enough credits", client);
				return;
			}
			
			char auth[32], eSignature[512], m_szQuery[1024];
			GetClientAuthId(client, AuthId_Steam2, auth, 32, true);
			SQL_EscapeString(g_eHandle[DB_Game], g_eClient[client][szNewSignature], eSignature, 512);
			Format(m_szQuery, 512, "UPDATE `playertrack_player` SET signature = '%s' WHERE id = '%d' and steamid = '%s'", eSignature, g_eClient[client][iPlayerId], auth);
			Handle data = CreateDataPack();
			WritePackString(data, m_szQuery);
			WritePackCell(data, 0);
			ResetPack(data);
			MySQL_Query(g_eHandle[DB_Game], SQLCallback_SaveDatabase, m_szQuery, data);
			tPrintToChat(client, "%s  %T", PLUGIN_PREFIX, "signature set successful", client);
			strcopy(g_eClient[client][szSignature], 256, g_eClient[client][szNewSignature]);
			ReplaceString(g_eClient[client][szNewSignature], 512, "{白}", "\x01");
			ReplaceString(g_eClient[client][szNewSignature], 512, "{红}", "\x02");
			ReplaceString(g_eClient[client][szNewSignature], 512, "{粉}", "\x03");
			ReplaceString(g_eClient[client][szNewSignature], 512, "{绿}", "\x04");
			ReplaceString(g_eClient[client][szNewSignature], 512, "{黄}", "\x05");
			ReplaceString(g_eClient[client][szNewSignature], 512, "{亮绿}", "\x06");
			ReplaceString(g_eClient[client][szNewSignature], 512, "{亮红}", "\x07");
			ReplaceString(g_eClient[client][szNewSignature], 512, "{灰}", "\x08");
			ReplaceString(g_eClient[client][szNewSignature], 512, "{褐}", "\x09");
			ReplaceString(g_eClient[client][szNewSignature], 512, "{橙}", "\x10");
			ReplaceString(g_eClient[client][szNewSignature], 512, "{紫}", "\x0E");
			ReplaceString(g_eClient[client][szNewSignature], 512, "{亮蓝}", "\x0B");
			ReplaceString(g_eClient[client][szNewSignature], 512, "{蓝}", "\x0C");
			tPrintToChat(client, "%T: %s", "signature yours", client, g_eClient[client][szNewSignature]);
		}
	}
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action Timer_ListenerTimeout(Handle timer, int client)
{
	g_eClient[client][hListener] = INVALID_HANDLE;
	g_eClient[client][bListener] = false;
}

public Action Timer_ReLoadClient(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(client && IsClientInGame(client))
		OnClientPostAdminCheck(client);
}

void FormatClientName(int client)
{
	if(IsFakeClient(client))
		return;
	
	if(g_eClient[client][iUID] > 0)
	{
		strcopy(g_eClient[client][szClientName], 32, g_eClient[client][szDiscuzName]);
		ReplaceString(g_eClient[client][szClientName], 32, "◇", "");
		ReplaceString(g_eClient[client][szClientName], 32, "◆", "");
		ReplaceString(g_eClient[client][szClientName], 32, "☆", "");
		ReplaceString(g_eClient[client][szClientName], 32, "★", "");
		ReplaceString(g_eClient[client][szClientName], 32, "✪", "");
		ReplaceString(g_eClient[client][szClientName], 32, "♜", "");
		ReplaceString(g_eClient[client][szClientName], 32, "♚", "");
		if(g_eClient[client][iGroupId] >= 9990)
			Format(g_eClient[client][szClientName], 32, "♚ %s", g_eClient[client][szClientName]);
		else if(GetUserFlagBits(client) & ADMFLAG_BAN)
			Format(g_eClient[client][szClientName], 32, "♜ %s", g_eClient[client][szClientName]);
		else
		{
			switch(g_eClient[client][iVipType])
			{
				case 0: Format(g_eClient[client][szClientName], 32, "◆ %s", g_eClient[client][szClientName]);
				case 1: Format(g_eClient[client][szClientName], 32, "☆ %s", g_eClient[client][szClientName]);
				case 2: Format(g_eClient[client][szClientName], 32, "★ %s", g_eClient[client][szClientName]);
				case 3: Format(g_eClient[client][szClientName], 32, "✪ %s", g_eClient[client][szClientName]);
			}
		}
	}
	else
	{
		GetClientName(client, g_eClient[client][szClientName], 32);
		ReplaceString(g_eClient[client][szClientName], 32, "◇", "");
		ReplaceString(g_eClient[client][szClientName], 32, "◆", "");
		ReplaceString(g_eClient[client][szClientName], 32, "☆", "");
		ReplaceString(g_eClient[client][szClientName], 32, "★", "");
		ReplaceString(g_eClient[client][szClientName], 32, "✪", "");
		ReplaceString(g_eClient[client][szClientName], 32, "♜", "");
		ReplaceString(g_eClient[client][szClientName], 32, "♚", "");

		Format(g_eClient[client][szClientName], 32, "◇ %s", g_eClient[client][szClientName]);
		
		if(g_eGame == Engine_CSGO)
			CS_SetClientClanTag(client, "[未注册]");
	}

	SetClientName(client, g_eClient[client][szClientName]);
}

void CheckClientName(int client)
{
	if(IsFakeClient(client))
		return;

	char name[32];
	GetClientName(client, name, 32);

	if(StrEqual(name, g_eClient[client][szClientName]))
		return;

	SetClientName(client, g_eClient[client][szClientName]);
}

int GetFreelyChannel(const char[] szX, const char[] szY)
{
	for(int channel = 0; channel < MAX_CHANNEL; ++channel)
		if(StrEqual(g_TextHud[channel][szPosX], szX) && StrEqual(g_TextHud[channel][szPosY], szY))
			return channel;

	for(int channel = 0; channel < MAX_CHANNEL; ++channel)
		if(g_TextHud[channel][fHolded] <= GetGameTime())
			return channel;

	return -1;
}

public Action Timer_ResetChannel(Handle timer, int channel)
{
	g_TextHud[channel][hTimer] = INVALID_HANDLE;
	g_TextHud[channel][szPosX][0] = '\0';
	g_TextHud[channel][szPosY][0] = '\0';
}