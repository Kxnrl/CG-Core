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
		char m_szAuthId[32], m_szQuery[512], m_szIp[16];
		KvGetSectionName(g_eHandle[KV_Local], m_szAuthId, 32);
		
		int m_iPlayerId = KvGetNum(g_eHandle[KV_Local], "PlayerId", 0);
		int m_iConnect = KvGetNum(g_eHandle[KV_Local], "Connect", 0);
		int m_iTrackId = KvGetNum(g_eHandle[KV_Local], "TrackID", 0);
		KvGetString(g_eHandle[KV_Local], "IP", m_szIp, 16, "127.0.0.1");
		int m_iLastTime = KvGetNum(g_eHandle[KV_Local], "LastTime", 0);
		int m_iOnlines = m_iLastTime - m_iConnect;
		int m_iDaily = KvGetNum(g_eHandle[KV_Local], "DayTime", 0);
		Format(m_szQuery, 512, "UPDATE playertrack_player AS a, playertrack_analytics AS b SET a.onlines = a.onlines+%d, a.lastip = '%s', a.lasttime = '%d', a.number = a.number+1, a.daytime = '%d', b.duration = '%d' WHERE a.id = '%d' AND b.id = '%d' AND a.steamid = '%s' AND b.playerid = '%d'", m_iOnlines, m_szIp, m_iLastTime, m_iDaily, m_iOnlines, m_iPlayerId, m_iTrackId, m_szAuthId, m_iPlayerId);

		Handle data = CreateDataPack();
		WritePackString(data, m_szQuery);
		WritePackString(data, m_szAuthId);
		WritePackCell(data, m_iPlayerId);
		WritePackCell(data, m_iConnect);
		WritePackCell(data, m_iTrackId);
		WritePackString(data, m_szIp);
		WritePackCell(data, m_iLastTime);
		ResetPack(data);
		
		if(!MySQL_Query(g_eHandle[DB_Game], SQLCallback_SaveTempLog, m_szQuery, data))
			LogToFileEx(g_szLogFile, "Error On KV_Local Start: \n%s", m_szQuery);

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

void UpdateClientFlags(int client)
{
	if(StrEqual(g_eClient[client][szAdminFlags], "OP+VIP") && g_eClient[client][bVip])
		return;
	
	if(StrEqual(g_eClient[client][szAdminFlags], "OP") && !(GetUserFlagBits(client) & ADMFLAG_CHANGEMAP))
		return;

	char newflags[16];
	
	//Admin?
	if(g_eClient[client][iGroupId] >= 9990)
	{
		strcopy(newflags, 16, "Admin");
	}
	//OP?
	else if(GetUserFlagBits(client) & ADMFLAG_CHANGEMAP)
	{
		if(g_eClient[client][bVip])
			strcopy(newflags, 16, "OP+VIP");
		else
			strcopy(newflags, 16, "OP");
	}
	//VIP?
	else if(g_eClient[client][bVip])
	{
		strcopy(newflags, 16, "VIP"); //SVIP
	}
	//以上都不是则为普通玩家
	else
	{
		strcopy(newflags, 16, "荣誉会员");
	}
	
	if(StrEqual(g_eClient[client][szAdminFlags], newflags))
		return;

	strcopy(g_eClient[client][szAdminFlags], 16, newflags);

	char m_szQuery[128];
	Format(m_szQuery, 128, "UPDATE `playertrack_player` SET `flags` = '%s' WHERE `id` = '%d'", g_eClient[client][szAdminFlags], g_eClient[client][iPlayerId]);
	MySQL_Query(g_eHandle[DB_Game], SQLCallback_OnUpdateFlags, m_szQuery);
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
	PrintToConsole(client, "当前服务器:  %s   -   Tickrate: %d.0   -   主程序版本: %s", szHostname, RoundToNearest(1.0 / GetTickInterval()), PLUGIN_VERSION);
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
		RemoveCharFromName(g_eClient[client][szClientName], 32);
		if(g_eClient[client][iGroupId] >= 9990)
			Format(g_eClient[client][szClientName], 32, "♚%s", g_eClient[client][szClientName]);
		else if(GetUserFlagBits(client) & ADMFLAG_BAN)
			Format(g_eClient[client][szClientName], 32, "♜%s", g_eClient[client][szClientName]);
		else
			Format(g_eClient[client][szClientName], 32, "%s%s", g_eClient[client][bVip] ? "✪" : "★", g_eClient[client][szClientName]);
	}
	else
	{
		if(AllowSelfName())
		{
			GetClientName(client, g_eClient[client][szClientName], 32);
			RemoveCharFromName(g_eClient[client][szClientName], 32);
			Format(g_eClient[client][szClientName], 32, "[Visitor] %s", g_eClient[client][szClientName]);
		}
		else
			Format(g_eClient[client][szClientName], 32, "[Visitor] #%6d", g_eClient[client][iPlayerId]);
	}

	SetClientName(client, g_eClient[client][szClientName]);
}

void Frame_CheckClientName(int client)
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

public Action Timer_GlobalTimer(Handle timer)
{
	GetNowDate();
	TrackClient();
	OnGlobalTimer();

	return Plugin_Continue;
}

public Action Timer_GotoRegister(Handle timer)
{
	for(int client = 1; client <= MaxClients; ++client)
	{
		if(!IsClientInGame(client) || !g_eClient[client][bLoaded] || g_eClient[client][iUID] > 0)
			continue;
		
		tPrintToChat(client, "%s  %T", PLUGIN_PREFIX, "go to forum to register", client);
	}
}

public Action Timer_RefreshDiscuzData(Handle timer)
{
	if(g_eHandle[DB_Discuz] == INVALID_HANDLE)
		return Plugin_Continue;

	MySQL_Query(g_eHandle[DB_Discuz], SQLCallback_LoadDiscuzData, "SELECT b.uid,a.steamID64,b.username,c.exptime,d.growth,e.issm FROM dz_steam_users a LEFT JOIN dz_common_member b ON a.uid=b.uid LEFT JOIN dz_dc_vip c ON a.uid=c.uid LEFT JOIN dz_pay_growth d ON a.uid=d.uid LEFT JOIN dz_lev_user_sm e ON a.uid=e.uid ORDER by b.uid ASC", _, DBPrio_High);

	return Plugin_Continue;
}

bool MySQL_Query(Handle database, SQLTCallback callback, const char[] query, any data = 0, DBPriority prio = DBPrio_Normal)
{
	if(database == INVALID_HANDLE)
	{
		if(database == g_eHandle[DB_Game])
		{
			SQL_TConnect_csgo();
		}
		else if(database == g_eHandle[DB_Discuz])
		{
			SQL_TConnect_discuz();
		}
		return false;
	}

	SQL_TQuery(database, callback, query, data, prio);

	return true;
}

void SetMenuTitleEx(Handle menu, const char[] fmt, any ...)
{
	char m_szBuffer[256];
	VFormat(m_szBuffer, 256, fmt, 3);
	
	if(g_eGame == Engine_CSGO)
		Format(m_szBuffer, 256, "%s\n　", m_szBuffer);
	else
	{
		ReplaceString(m_szBuffer, 256, "\n \n", " - ");
		ReplaceString(m_szBuffer, 256, "\n", " - ");
	}

	SetMenuTitle(menu, m_szBuffer);
}

bool AddMenuItemEx(Handle menu, int style, const char[] info, const char[] display, any ...)
{
	char m_szBuffer[256];
	VFormat(m_szBuffer, 256, display, 5);

	if(g_eGame != Engine_CSGO)
		ReplaceString(m_szBuffer, 256, "\n", " - ");

	return AddMenuItem(menu, info, m_szBuffer, style);
}

bool TalentAvailable()
{
	if(FindPluginByFile("talent.smx"))
		return true;

	return false;
}

int FindClientByPlayerId(int playerid)
{
	for(int client = 1; client <= MaxClients; ++client)
		if(IsClientInGame(client) && g_eClient[client][bLoaded])
			if(g_eClient[client][iPlayerId] == playerid)
				return client;
			
	return -1;
}

void PrepareUrl(int width, int height, char[] m_szUrl)
{
	Format(m_szUrl, 192, "https://csgogamers.com/webplugin.php?width=%d&height=%d&url=%s", width, height, m_szUrl);
}

void ShowMOTDPanelEx(int client, const char[] title = "CSGOGAMERS.COM", const char[] url, int type = MOTDPANEL_TYPE_INDEX, int cmd = MOTDPANEL_CMD_NONE, bool show = true)
{
	Handle m_hKv = CreateKeyValues("data");
	KvSetString(m_hKv, "title", title);
	KvSetNum(m_hKv, "type", type);
	KvSetString(m_hKv, "msg", url);
	KvSetNum(m_hKv, "cmd", cmd);
	ShowVGUIPanel(client, "info", m_hKv, show);
	CloseHandle(m_hKv);
}

void LoadClientDiscuzData(int client, const char[] FriendID)
{
	int array_size = GetArraySize(g_eHandle[Array_Discuz]);
	Discuz_Data data[Discuz_Data];

	for(int i = 0; i < array_size; i++)
	{
		GetArrayArray(g_eHandle[Array_Discuz], i, data[0], view_as<int>(Discuz_Data));
		
		if(!StrEqual(FriendID, data[szSteamId64]))
			continue;

		g_eClient[client][bVip] = (data[iExpTime] > GetTime());
		g_eClient[client][iUID] = data[iUId];
		g_eClient[client][iGrowth] = data[iGrowths];
		g_eClient[client][bRealName] = data[bIsRealName];
		strcopy(g_eClient[client][szDiscuzName], 32, data[szDName]);
		break;
	}
}

void GetClientAuthName(int client, char[] buffer, int maxLen)
{
	switch(g_eClient[client][iGroupId])
	{
		case    0: strcopy(buffer, maxLen, "未认证");
		case    1: strcopy(buffer, maxLen, "断后达人");
		case    2: strcopy(buffer, maxLen, "指挥大佬");
		case    3: strcopy(buffer, maxLen, "僵尸克星");
		case  101: strcopy(buffer, maxLen, "职业侦探");
		case  102: strcopy(buffer, maxLen, "心机婊");
		case  103: strcopy(buffer, maxLen, "TTT影帝");
		case  104: strcopy(buffer, maxLen, "赌命狂魔");
		case  105: strcopy(buffer, maxLen, "杰出公民");
		case  201: strcopy(buffer, maxLen, "娱乐挂壁");
		case  301: strcopy(buffer, maxLen, "首杀无敌");
		case  302: strcopy(buffer, maxLen, "混战指挥");
		case  303: strcopy(buffer, maxLen, "爆头狂魔");
		case  304: strcopy(buffer, maxLen, "助攻之神");
	}
}

bool AllowSelfName()
{
	if(FindPluginByFile("deathmatch.smx") || FindPluginByFile("warmod.smx"))
		return true;

	return false;
}

public Action Timer_CheckJoinGame(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(!client || !IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) >= 1)
		return Plugin_Stop;

	RequestFrame(Frame_KickDelay, client);

	return Plugin_Stop;
}

void Frame_KickDelay(int client)
{
	if(!IsClientConnected(client))
		return;

	char fmt[256];
	Format(fmt, 256, "你因为太久没有激活游戏,已被踢出游戏.\nYou have been AFK too long");
	KickClient(client, fmt);
}

void TranslationToFile(const char[] m_szPath)
{
	Handle file = OpenFile(m_szPath, "w");
	WriteFileLine(file, "\"Phrases\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"signature title\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Signature setup \\n500Credits per setup[Free for first time]\"");
	WriteFileLine(file, "\"chi\"	\"签名设置  \\n设置签名需要500信用点[首次免费]\"");
	WriteFileLine(file, "\"zho\"	\"簽名設置　\\n設定簽名需要500個點數[第一次免費]\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"signature now you can type\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Input your signature in chat \\n\"");
	WriteFileLine(file, "\"chi\"	\"你现在可以按Y输入签名了 \\n \"");
	WriteFileLine(file, "\"zho\"	\"你現在可以按Y輸入簽名了 \\n \"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"signature color codes\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Useable color codes:\\n {lightred} {yellow} {blue} {green} {orange} {purple} {pink} \\n\"");
	WriteFileLine(file, "\"chi\"	\"可用颜色代码\\n {亮红} {黄} {蓝} {绿} {橙} {紫} {粉} \\n \"");
	WriteFileLine(file, "\"zho\"	\"可用顏色代碼\\n {亮红} {黄} {蓝} {绿} {橙} {紫} {粉} \\n \"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"signature example\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"EXAMPLE: (blue)E{yellow}X{lightred}A{green}M{orange}P{purple}L{pink}E\"");
	WriteFileLine(file, "\"chi\"	\"例如: {蓝}陈{红}抄{黄}封{紫}不{粉}要{绿}脸 \\n \"");
	WriteFileLine(file, "\"zho\"	\"比如: {蓝}陈{红}抄{黄}封{紫}不{粉}要{绿}脸 \\n \"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"signature input preview\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"#format\" \"{1:s}\"");
	WriteFileLine(file, "\"en\"	\"Inputed: \\n {1}\\n \"");
	WriteFileLine(file, "\"chi\"	\"你当前已输入: \\n {1}\\n \"");
	WriteFileLine(file, "\"zho\"	\"你當前已輸入: \\n {1}\\n \"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"signature input\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"#format\" \"{1:s}\"");
	WriteFileLine(file, "\"en\"	\"Inputed: {1}\"");
	WriteFileLine(file, "\"chi\"	\"您输入了: {1}\"");
	WriteFileLine(file, "\"zho\"	\"你輸入了: {1}\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"signature item preview\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Preview signature\"");
	WriteFileLine(file, "\"chi\"	\"查看预览\"");
	WriteFileLine(file, "\"zho\"	\"查看預覽\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"signature item ok\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Complete\"");
	WriteFileLine(file, "\"chi\"	\"我写好了\"");
	WriteFileLine(file, "\"zho\"	\"我寫完了\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"signature you have not enough credits\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Insufficient credits\"");
	WriteFileLine(file, "\"chi\"	\"信用点不足,不能设置签名\"");
	WriteFileLine(file, "\"zho\"	\"點數不夠,不能設定簽名\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"signature set successful\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Signature sucessfully setup\"");
	WriteFileLine(file, "\"chi\"	\"已成功设置您的签名,花费了{green}500信用点\"");
	WriteFileLine(file, "\"zho\"	\"已經設定了你的簽名,花了{green}500個點數\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"signature yours\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Your signature\"");
	WriteFileLine(file, "\"chi\"	\"您的签名\"");
	WriteFileLine(file, "\"zho\"	\"你的簽名\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"signature free first\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Free for first set-up\"");
	WriteFileLine(file, "\"chi\"	\"首次设置签名免费!\"");
	WriteFileLine(file, "\"zho\"	\"第一次設定簽名免費\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"sign allow sign\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"{green}You can sign now - Type{lightred} !sign{green} in chat to sign\"");
	WriteFileLine(file, "\"chi\"	\"{green}你现在可以签到了,按Y输入{lightred}!sign{green}来签到!\"");
	WriteFileLine(file, "\"zho\"	\"{green}你現在可以簽到了,按Y輸入{lightred}!sign{green}來簽到!\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"sign twice sign\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"You can only sign once each day!\"");
	WriteFileLine(file, "\"chi\"	\"每天只能签到1次!\"");
	WriteFileLine(file, "\"zho\"	\"每天只能簽到1次!\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"sign no time\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"#format\" \"{1:d}\"");
	WriteFileLine(file, "\"en\"	\"{green}{1}{default} more second for sign-up!\"");
	WriteFileLine(file, "\"chi\"	\"你还需要在线{green}{1}{default}秒才能签到!\"");
	WriteFileLine(file, "\"zho\"	\"你還需要在綫{green}{1}{default}秒才能簽到!\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"sign error\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"{darkred}Sign error - try again later\"");
	WriteFileLine(file, "\"chi\"	\"{darkred}未知错误,请重试!\"");
	WriteFileLine(file, "\"zho\"	\"{darkred}未知錯誤,請重試!\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"sign successful\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"#format\" \"{1:d}\"");
	WriteFileLine(file, "\"en\"	\"{default}You had signed up today. Total signed up for {blue}{1}{default} day(s)!\"");
	WriteFileLine(file, "\"chi\"	\"{default}签到成功,你已累计签到{blue}{1}{default}天!\"");
	WriteFileLine(file, "\"zho\"	\"{default}簽到成功,你已經簽到了{blue}{1}{default}天!\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"system error\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"An error occupied - try again later:\"");
	WriteFileLine(file, "\"chi\"	\"系统中闪光弹了,请重试!  错误:\"");
	WriteFileLine(file, "\"zho\"	\"系統出錯,請重試!  錯誤:\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp married\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"#format\" \"{1:s},{2:s}\"");
	WriteFileLine(file, "\"en\"	\"{orange}Congraulates {purple}{1}{orange} and {purple}{2}{orange} made a couple.\"");
	WriteFileLine(file, "\"chi\"	\"{orange}恭喜{purple}{1}{orange}和{purple}{2}{orange}结成CP.\"");
	WriteFileLine(file, "\"zho\"	\"{orange}恭喜{purple}{1}{orange}和{purple}{2}{orange}組成CP.\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp married offline\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Data saved - Awards unaviliable\"");
	WriteFileLine(file, "\"chi\"	\"系统已保存你们的数据,但是你老婆当前离线,你不能享受新婚祝福\"");
	WriteFileLine(file, "\"zho\"	\"系統已保存你們的檔案,但是你老婆現在離綫,你不能接受新婚祝福\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp divorce\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"#format\" \"{1:N},{2:s},{3:d}\"");
	WriteFileLine(file, "\"en\"	\"{orange}{1}{yellow} terminated couple relationship with {orange}{2}{yellow} - Their relationship existed for{red}{3}{yellow}days\"");
	WriteFileLine(file, "\"chi\"	\"{orange}{1}{yellow}解除了和{orange}{2}{yellow}的CP,他们的关系维持了{red}{3}{yellow}天\"");
	WriteFileLine(file, "\"zho\"	\"{orange}{1}{yellow}解除了和{orange}{2}{yellow}的CP,他們搞基了{red}{3}{yellow}天\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp find\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Find couple\"");
	WriteFileLine(file, "\"chi\"	\"寻找CP\"");
	WriteFileLine(file, "\"zho\"	\"尋找CP\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp out\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Dissolute couple\"");
	WriteFileLine(file, "\"chi\"	\"解除CP\"");
	WriteFileLine(file, "\"zho\"	\"解除CP\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp about\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"About\"");
	WriteFileLine(file, "\"chi\"	\"关于CP\"");
	WriteFileLine(file, "\"zho\"	\"關於CP\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp no target\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"No one can receive request now\"");
	WriteFileLine(file, "\"chi\"	\"当前服务器内没有人能跟你搞基\"");
	WriteFileLine(file, "\"zho\"	\"當前服務器裏面沒有人能跟你CP\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp invalid target\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Invalid request target\"");
	WriteFileLine(file, "\"chi\"	\"你选择的对象目前不可用\"");
	WriteFileLine(file, "\"zho\"	\"你選擇的對象不正確\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp send\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"#format\" \"{1:N}\"");
	WriteFileLine(file, "\"en\"	\"{purple}{1}{normal} received your request\"");
	WriteFileLine(file, "\"chi\"	\"已将你的CP请求发送至{purple}{1}\"");
	WriteFileLine(file, "\"zho\"	\"已經將你的CP請求發送給{purple}{1}\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp request\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Received a couple request\"");
	WriteFileLine(file, "\"chi\"	\"您有一个CP请求\"");
	WriteFileLine(file, "\"zho\"	\"你有一個CP請求\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp request item target\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"#format\" \"{1:N}\"");
	WriteFileLine(file, "\"en\"	\"Received couple request from {1}\"");
	WriteFileLine(file, "\"chi\"	\"你收到了一个来自 {1} 的CP邀请\"");
	WriteFileLine(file, "\"zho\"	\"你收到了一個來自 {1} 的CP邀請\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp 7days\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Cannot terminate relationship in 7 days\"");
	WriteFileLine(file, "\"chi\"	\"组成CP后7天内不能申请解除\"");
	WriteFileLine(file, "\"zho\"	\"組成CP後7天內不能申請解開\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp buff\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Spec awards for couples\"");
	WriteFileLine(file, "\"chi\"	\"组成CP后可以享受多种福利\"");
	WriteFileLine(file, "\"zho\"	\"組成CP可以想說一些福利\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp confirm\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Accept this request?\"");
	WriteFileLine(file, "\"chi\"	\"你确定要接受这个邀请吗\"");
	WriteFileLine(file, "\"zho\"	\"你確定要接受這個邀請嗎\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp accept\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Yes\"");
	WriteFileLine(file, "\"chi\"	\"我接受\"");
	WriteFileLine(file, "\"zho\"	\"我接受\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp refuse\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Nope\"");
	WriteFileLine(file, "\"chi\"	\"我拒绝\"");
	WriteFileLine(file, "\"zho\"	\"我拒絕\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp refuse target\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"#format\" \"{1:N}\"");
	WriteFileLine(file, "\"en\"	\"You rejected {orange}{1}{default}'s couple request\"");
	WriteFileLine(file, "\"chi\"	\"你拒绝了{orange}{1}{default}的CP邀请\"");
	WriteFileLine(file, "\"zho\"	\"你拒絕了{orange}{1}{default}的CP邀請\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp refuse client\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"#format\" \"{1:N}\"");
	WriteFileLine(file, "\"en\"	\"{orange}{1}{default} had rejected your request\"");
	WriteFileLine(file, "\"chi\"	\"{orange}{1}{default}拒绝了你的CP邀请\"");
	WriteFileLine(file, "\"zho\"	\"{orange}{1}{default}拒絕了你的CP邀請\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp can divorce\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Cannot terminate relationship in week once you make new couple\"");
	WriteFileLine(file, "\"chi\"	\"新组成CP之后7天内不能申请解除\"");
	WriteFileLine(file, "\"zho\"	\"新組成CP之後7天內不能申請解開\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp your cp\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"#format\" \"{1:s}\"");
	WriteFileLine(file, "\"en\"	\"Your couple is {1}\"");
	WriteFileLine(file, "\"chi\"	\"你当前的CP伴侣为 {1}\"");
	WriteFileLine(file, "\"zho\"	\"你現在的CP伴侶为 {1}\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp your days\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"#format\" \"{1:d}\"");
	WriteFileLine(file, "\"en\"	\"Relationship exists for {1} days\"");
	WriteFileLine(file, "\"chi\"	\"你们已组成CP {1} 天\"");
	WriteFileLine(file, "\"zho\"	\"你們已經搞基 {1} 天\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp confirm divorce\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Terminate couple relationship?\"");
	WriteFileLine(file, "\"chi\"	\"你确定要解除CP组合吗\"");
	WriteFileLine(file, "\"zho\"	\"你確定要解開CP配對嗎\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp help title\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Help\"");
	WriteFileLine(file, "\"chi\"	\"帮助菜单\"");
	WriteFileLine(file, "\"zho\"	\"幫助菜單\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp each other\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Need true willing to make couple\"");
	WriteFileLine(file, "\"chi\"	\"组成CP需要两厢情愿\"");
	WriteFileLine(file, "\"zho\"	\"組成CP需要兩廂情願\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp after 7days\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Cannot disassemle couple in a week after couple created\"");
	WriteFileLine(file, "\"chi\"	\"CP配对后7天内不能解除\"");
	WriteFileLine(file, "\"zho\"	\"CP配對後7天內不能解除\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp earn buff\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Couple award: limit BUFFs\"");
	WriteFileLine(file, "\"chi\"	\"CP能为你提供一定的加成\"");
	WriteFileLine(file, "\"zho\"	\"CP能為你提供一些BUFF\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"global menu title\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"General Menu\"");
	WriteFileLine(file, "\"chi\"	\"主菜单\"");
	WriteFileLine(file, "\"zho\"	\"主菜單\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"global item sure\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Yes\"");
	WriteFileLine(file, "\"chi\"	\"我确定\"");
	WriteFileLine(file, "\"zho\"	\"我確定\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"global item refuse\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"No\"");
	WriteFileLine(file, "\"chi\"	\"我拒绝\"");
	WriteFileLine(file, "\"zho\"	\"我拒絕\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cmd onlines\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"#format\" \"{1:N},{2:d},{3:d},{4:d},{5:d}\"");
	WriteFileLine(file, "\"en\"	\"Player {green}{1}{default}: You had played {blue}{2}{default}hours {blue}{3}{default}minute in our server(For {red}{4}{default} time(s)), have connected for {blue}{5}{default} minute(s) this time\"");
	WriteFileLine(file, "\"chi\"	\"尊贵的CG玩家{green}{1}{default},你已经在CG社区进行了{blue}{2}{default}小时{blue}{3}{default}分钟的游戏({red}{4}{default}次连线),本次游戏时长{blue}{5}{default}分钟\"");
	WriteFileLine(file, "\"zho\"	\"尊貴的CG玩家{green}{1}{default},你已經在CG社區進行了{blue}{2}{default}小時{blue}{3}{default}分鐘的遊戲({red}{4}{default}次連線),本次遊戲時長{blue}{5}{default}分鐘\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"check console\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Check console output\"");
	WriteFileLine(file, "\"chi\"	\"请查看控制台输出\"");
	WriteFileLine(file, "\"zho\"	\"請查看控制臺輸出\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cmd track\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"#format\" \"{1:d},{2:d}\"");
	WriteFileLine(file, "\"en\"	\"{green}{1}{default} player in-game / {red}{2}{default} connected\"");
	WriteFileLine(file, "\"chi\"	\"当前已在服务器内{green}{1}{default}人,已建立连接的玩家{red}{2}{default}人\"");
	WriteFileLine(file, "\"zho\"	\"當前已在伺服器內{green}{1}{default}人,已建立連線的玩家{red}{2}{default}人\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"main store desc\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Store [PlayerSkins/NameTag/Etc]\"");
	WriteFileLine(file, "\"chi\"	\"打开商店菜单[购买皮肤/名字颜色/翅膀等道具]\"");
	WriteFileLine(file, "\"zho\"	\"打開商店菜單[購買皮膚/名字顏色/翅膀等道具]\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"main cp desc\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Couple [Couple options]\"");
	WriteFileLine(file, "\"chi\"	\"打开CP菜单[进行CP配对/加成等功能]\"");
	WriteFileLine(file, "\"zho\"	\"打開CP菜單[進行搞基配對/加成等功能]\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"main talent desc\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Talent[Increase ability]\"");
	WriteFileLine(file, "\"chi\"	\"打开天赋菜单[选择/分配你的天赋]\"");
	WriteFileLine(file, "\"zho\"	\"打開天賦菜單[選取/分配你的天賦]\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"main talent not allow\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Talent[Increase ability](this server not allow)\"");
	WriteFileLine(file, "\"chi\"	\"打开天赋菜单[选择/分配你的天赋](当前服务器不可用)\"");
	WriteFileLine(file, "\"zho\"	\"打開天賦菜單[選取/分配你的天賦](當前伺服器不可用)\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"main sign desc\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Sign [Sign for daliy award]\"");
	WriteFileLine(file, "\"chi\"	\"进行每日签到[签到可以获得相应的奖励]\"");
	WriteFileLine(file, "\"zho\"	\"進行每日簽到[簽到可以獲得一些獎勵]\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"main vip desc\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"VIP Member options\"");
	WriteFileLine(file, "\"chi\"	\"打开VIP菜单[年费/永久VIP可用]\"");
	WriteFileLine(file, "\"zho\"	\"打開VIP菜單[年費/永久VIP可用]\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"main auth desc\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Auth Player[Get Auth]\"");
	WriteFileLine(file, "\"chi\"	\"打开认证菜单[申请玩家认证]\"");
	WriteFileLine(file, "\"zho\"	\"打開認證菜單[申請玩家認證]\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"main rule desc\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Server Rule[Check Rules]\"");
	WriteFileLine(file, "\"chi\"	\"查看规则[当前服务器规则]\"");
	WriteFileLine(file, "\"zho\"	\"查看規則[當前伺服器規則]\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"main group desc\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Offical Group[Join Group]\"");
	WriteFileLine(file, "\"chi\"	\"官方组[查看组页面]\"");
	WriteFileLine(file, "\"zho\"	\"官方組[查看組頁面]\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"main forum desc\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Offical Forum[Visit Forum]\"");
	WriteFileLine(file, "\"chi\"	\"官方论坛[https://csgogamers.com]\"");
	WriteFileLine(file, "\"zho\"	\"官方論壇[https://csgogamers.com]\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"main music desc\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Music Player[Broadcast music]\"");
	WriteFileLine(file, "\"chi\"	\"音乐菜单[点歌/听歌]\"");
	WriteFileLine(file, "\"zho\"	\"音樂菜單[點歌/聽歌]\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"main radio desc\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Music Radio[Listen to the Radio]\"");
	WriteFileLine(file, "\"chi\"	\"音乐电台[收听电台]\"");
	WriteFileLine(file, "\"zho\"	\"音樂電台[收聽電台]\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"main online desc\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Onlines[check your online time]\"");
	WriteFileLine(file, "\"chi\"	\"在线时间[显示你的在线统计]\"");
	WriteFileLine(file, "\"zho\"	\"在綫時間[顯示你的在綫統計]\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"main setrp desc\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"SetRP[Set Motd resolution]\"");
	WriteFileLine(file, "\"chi\"	\"分辨率[设置游戏内浏览器分辨率]\"");
	WriteFileLine(file, "\"zho\"	\"分辨率[設置遊戲內瀏覽器分辨率]\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"auth menu title\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Auth Player[Get Auth]\"");
	WriteFileLine(file, "\"chi\"	\"打开认证菜单[申请玩家认证]\"");
	WriteFileLine(file, "\"zho\"	\"打開認證菜單[申請玩家認證]\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"auth not enough req\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"More assets for authourize required\"");
	WriteFileLine(file, "\"chi\"	\"很抱歉噢,你没有达到该认证的要求\"");
	WriteFileLine(file, "\"zho\"	\"很抱歉噢,你還沒有達到這個認證的要求\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"auth get new auth\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"had got an authroize\"");
	WriteFileLine(file, "\"chi\"	\"获得了新的认证\"");
	WriteFileLine(file, "\"zho\"	\"獲得了新的認證\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"you are already Auth Player\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"you are already Auth Player\"");
	WriteFileLine(file, "\"chi\"	\"你已经有认证了\"");
	WriteFileLine(file, "\"zho\"	\"你已經有認證了\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"querying\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Querying...\"");
	WriteFileLine(file, "\"chi\"	\"正在查询...\"");
	WriteFileLine(file, "\"zho\"	\"正在查詢...\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"type in console\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Type in Console\"");
	WriteFileLine(file, "\"chi\"	\"请在控制台中输入\"");
	WriteFileLine(file, "\"zho\"	\"在操作臺中輸入\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"main act desc\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Community`s Activities\"");
	WriteFileLine(file, "\"chi\"	\"社区活动\"");
	WriteFileLine(file, "\"zho\"	\"社群活動\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"main select language\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Select your language\"");
	WriteFileLine(file, "\"chi\"	\"选择你的语言\"");
	WriteFileLine(file, "\"zho\"	\"選擇你的語言\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"go to forum to register\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Your steamID hasn`t been connect the forum account.\"");
	WriteFileLine(file, "\"chi\"	\"你的SteamID尚未关联论坛账户,部分功能将不可用!\"");
	WriteFileLine(file, "\"zho\"	\"你的遊戲帳戶還沒有綁定論壇帳號,有的東西將無權使用!\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "}");
	CloseHandle(file);
}