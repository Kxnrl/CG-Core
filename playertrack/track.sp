//////////////////////////////
//	TRACK CLIENT ANALYTICS	//
//////////////////////////////
public Action Timer_Tracking(Handle timer)
{
	GetNowDate();
	
	if(g_eHandle[KV_Local] == INVALID_HANDLE)
		return Plugin_Continue;

	for(int client = 1; client <= MaxClients; ++client)
	{
		if(!IsClientInGame(client))
			continue;
		
		if(IsFakeClient(client))
			continue;
		
		if(!g_eClient[client][bLoaded])
			continue;

		if(g_eClient[client][iAnalyticsId] < 1)
			continue;
		
		g_eClient[client][iDaily]++;
		
		if(!g_eClient[client][bSignIn] && g_eClient[client][iDaily] >= 900 && g_eClient[client][hSignTimer] == INVALID_HANDLE)
		{
			tPrintToChat(client, "%s  %T", PLUGIN_PREFIX, "sign allow sign", client);
			g_eClient[client][hSignTimer] = CreateTimer(30.0, Timer_NotifySign, client, TIMER_REPEAT);
		}

		char m_szAuth[32];
		GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);

		KvJumpToKey(g_eHandle[KV_Local], m_szAuth, true);

		KvSetNum(g_eHandle[KV_Local], "PlayerId", g_eClient[client][iPlayerId]);
		KvSetNum(g_eHandle[KV_Local], "Connect", g_eClient[client][iConnectTime]);
		KvSetNum(g_eHandle[KV_Local], "TrackID", g_eClient[client][iAnalyticsId]);
		KvSetString(g_eHandle[KV_Local], "IP", g_eClient[client][szIP]);
		KvSetNum(g_eHandle[KV_Local], "LastTime", GetTime());
		KvSetString(g_eHandle[KV_Local], "Flag", g_eClient[client][szAdminFlags]);
		KvSetNum(g_eHandle[KV_Local], "DayTime", g_eClient[client][iDaily]);

		KvRewind(g_eHandle[KV_Local]);
	}

	KeyValuesToFile(g_eHandle[KV_Local], g_szTempFile);
	
	return Plugin_Continue;
}

public void OnGetClientCVAR(QueryCookie cookie, int client, ConVarQueryResult result, char [] cvarName, char [] cvarValue)
{
	if(StringToInt(cvarValue) > 0)
		tPrintToChat(client, " %T:   \x04cl_disablehtmlmotd 0", "type in console", client);
}

public Action Timer_HandleConnect(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!client || !IsClientInGame(client))
		return Plugin_Stop;
	
	if(!g_eClient[client][iConnectTime])
	{
		g_eClient[client][iConnectTime] = GetTime();
		return Plugin_Continue;
	}

	if(!g_eClient[client][bLoaded])
		return Plugin_Continue;
	
	if(!g_eClient[client][iPlayerId])
		return Plugin_Stop;

	//获得 客户OS|当前地图|当前日期|客户权限
	char date[64], map[128];
	FormatTime(date, 64, "%Y/%m/%d %H:%M:%S", GetTime());

	GetCurrentMap(map, 128);

	Format(g_eClient[client][szInsertData], 512, "INSERT INTO `playertrack_analytics` (`playerid`, `connect_time`, `connect_date`, `serverid`, `map`, `ip`) VALUES ('%d', '%d', '%s', '%d', '%s', '%s')", g_eClient[client][iPlayerId], g_eClient[client][iConnectTime], date, g_iServerId, map, g_eClient[client][szIP]);
	MySQL_Query(g_eHandle[DB_Game], SQLCallback_InsertPlayerStat, g_eClient[client][szInsertData], GetClientUserId(client));

	return Plugin_Stop;
}

void SaveClient(int client)
{
	if(g_eClient[client][iAnalyticsId] == -1 || g_eClient[client][iPlayerId] == 0)
		return;
	
	//获得统计结果
	int duration = -1;
	if(g_eClient[client][iConnectTime] < (GetTime()-86400))
		duration = 0;
	else
		duration = GetTime() - g_eClient[client][iConnectTime];

	//获得客户名字
	char username[64], m_szAuth[32];
	GetClientName(client, username, 64);
	GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);	

	//开始SQL查询操作
	char m_szBuffer[128];
	SQL_EscapeString(g_eHandle[DB_Game], username, m_szBuffer, 128);	

	Format(g_eClient[client][szUpdateData], 512, "UPDATE playertrack_player AS a, playertrack_analytics AS b SET a.name = '%s', a.onlines = a.onlines+%d, a.lastip = '%s', a.lasttime = '%d', a.number = a.number+1, a.flags = '%s', a.daytime = '%d', b.duration = '%d' WHERE a.id = '%d' AND b.id = '%d' AND a.steamid = '%s' AND b.playerid = '%d'", m_szBuffer, duration, g_eClient[client][szIP], GetTime(), g_eClient[client][szAdminFlags], g_eClient[client][iDaily], duration, g_eClient[client][iPlayerId], g_eClient[client][iAnalyticsId], m_szAuth, g_eClient[client][iPlayerId]);

	MySQL_Query(g_eHandle[DB_Game], SQLCallback_SaveClientStat, g_eClient[client][szUpdateData], GetClientUserId(client), DBPrio_High);
	
	if(KvJumpToKey(g_eHandle[KV_Local], m_szAuth))
	{
		KvDeleteThis(g_eHandle[KV_Local]);
		KvRewind(g_eHandle[KV_Local]);
		KeyValuesToFile(g_eHandle[KV_Local], g_szTempFile);
	}
}