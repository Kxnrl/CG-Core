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
	RegConsoleCmd("sm_auth", Command_GetAuth);
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
	g_Forward[OnNowTime] = CreateGlobalForward("CG_OnNowTime", ET_Ignore, Param_Cell);
	g_Forward[GlobalTimer] = CreateGlobalForward("CG_OnGlobalTimer", ET_Ignore);
	g_Forward[ClientAuthTerm] = CreateGlobalForward("CG_OnCheckAuthTerm", ET_Event, Param_Cell, Param_Cell);

	g_eEvents[round_start] = CreateGlobalForward("CG_OnRoundStart", ET_Ignore);
	g_eEvents[round_end] = CreateGlobalForward("CG_OnRoundEnd", ET_Ignore, Param_Cell);
	g_eEvents[player_spawn] = CreateGlobalForward("CG_OnClientSpawn", ET_Ignore, Param_Cell);
	g_eEvents[player_death] = CreateGlobalForward("CG_OnClientDeath", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_String);
	g_eEvents[player_hurt] = CreateGlobalForward("CG_OnClientHurted", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_String);
	g_eEvents[player_team] = CreateGlobalForward("CG_OnClientTeam", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
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
	CreateNative("CG_GetClientGrowth", Native_GetGrowth);
	CreateNative("CG_GetClientVitality", Native_GetVitality);
	CreateNative("CG_GetClientLastseen", Native_GetLastseen);
	CreateNative("CG_GetClientDailyTime", Native_GetDailyTime);
	CreateNative("CG_GetClientId", Native_GetPlayerID);
	CreateNative("CG_GetClientUId", Native_GetDiscuzUID);
	CreateNative("CG_GetClientGId", Native_GetGroupID);
	CreateNative("CG_GetClientPartner", Native_GetCPPartner);
	CreateNative("CG_GetClientLilyDate", Native_GetCPDate);
	CreateNative("CG_IsClientVIP", Native_IsClientVIP);
	CreateNative("CG_IsClientRealName", Native_IsRealName);
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

void InitDiscuz()
{
	if(g_eHandle[Array_Discuz] != INVALID_HANDLE)
		CloseHandle(g_eHandle[Array_Discuz]);

	g_eHandle[Array_Discuz] = CreateArray(view_as<int>(Discuz_Data));
}

void InitClient(int client)
{
	g_eClient[client][bVip] = false;
	g_eClient[client][bLoaded] = false;
	g_eClient[client][bListener] = false;
	g_eClient[client][bSignIn] = false;
	g_eClient[client][bRealName] = false;
	g_eClient[client][iUID] = -1;
	g_eClient[client][iSignNum] = 0;
	g_eClient[client][iSignTime] = 0;
	g_eClient[client][iConnectTime] = GetTime();
	g_eClient[client][iPlayerId] = 0;
	g_eClient[client][iNumber] = 0;
	g_eClient[client][iOnline] = 0;
	g_eClient[client][iGrowth] = 0;
	g_eClient[client][iVitality] = 0
	g_eClient[client][iLastseen] = 0;
	g_eClient[client][iDataRetry] = 0;
	g_eClient[client][iAnalyticsId] = -1;
	g_eClient[client][iGroupId] = 0;
	g_eClient[client][iCPId] = -2;
	g_eClient[client][iCPDate] = 0;
	g_eClient[client][iDaily] = 0;

	strcopy(g_eClient[client][szIP], 32, "127.0.0.1");
	strcopy(g_eClient[client][szSignature], 256, "数据读取中...");
	strcopy(g_eClient[client][szDiscuzName], 32, "未注册");
	strcopy(g_eClient[client][szAdminFlags], 16, "Unknown");
	strcopy(g_eClient[client][szInsertData], 512, "");
	strcopy(g_eClient[client][szUpdateData], 512, "");
	strcopy(g_eClient[client][szGroupName], 16, "未认证");
	strcopy(g_eClient[client][szNewSignature], 256, "该玩家未设置签名");
	strcopy(g_eClient[client][szClientName], 32, "无名氏");
}