//////////////////////////////
//	TRACK CLIENT ANALYTICS	//
//////////////////////////////
public Action Timer_Tracking(Handle timer)
{
	g_iNewDayLeft--;
	if(g_iNewDayLeft == 0)
		OnNewDay();
	
	for(int client = 1; client <= MaxClients; ++client)
	{
		if(!IsValidClient(client, false))
			continue;
		
		if(!g_eClient[client][bLoaded])
			continue;

		if(g_eClient[client][iAnalyticsId] < 1)
			continue;
		
		char m_szAuth[32];
		GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);

		KvJumpToKey(g_hKeyValue, m_szAuth, true);
		
		KvSetNum(g_hKeyValue, "PlayerId", g_eClient[client][iPlayerId]);
		KvSetNum(g_hKeyValue, "Connect", g_eClient[client][iConnectTime]);
		KvSetNum(g_hKeyValue, "TrackID", g_eClient[client][iAnalyticsId]);
		KvSetString(g_hKeyValue, "IP", g_eClient[client][szIP]);
		KvSetNum(g_hKeyValue, "LastTime", GetTime());
		KvSetString(g_hKeyValue, "Flag", g_eClient[client][szAdminFlags]);
		
		KvRewind(g_hKeyValue);
	}

	KeyValuesToFile(g_hKeyValue, g_szTempFile);
}

public void OnGetClientCVAR(QueryCookie cookie, int client, ConVarQueryResult result, char [] cvarName, char [] cvarValue)
{
	if(StringToInt(cvarValue) > 0)
		tPrintToChat(client, " %t:   \x04cl_disablehtmlmotd 0", "type in console");
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
	MySQL_Query(g_hDB_csgo, SQLCallback_InsertPlayerStat, g_eClient[client][szInsertData], g_eClient[client][iUserId]);

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
	SQL_EscapeString(g_hDB_csgo, username, m_szBuffer, 128);	

	Format(g_eClient[client][szUpdateData], 512, "UPDATE playertrack_player AS a, playertrack_analytics AS b SET a.name = '%s', a.onlines = a.onlines+%d, a.lastip = '%s', a.lasttime = '%d', a.number = a.number+1, a.flags = '%s', b.duration = '%d' WHERE a.id = '%d' AND b.id = '%d' AND a.steamid = '%s' AND b.playerid = '%d'", m_szBuffer, duration, g_eClient[client][szIP], GetTime(), g_eClient[client][szAdminFlags], duration, g_eClient[client][iPlayerId], g_eClient[client][iAnalyticsId], m_szAuth, g_eClient[client][iPlayerId]);

	MySQL_Query(g_hDB_csgo, SQLCallback_SaveClientStat, g_eClient[client][szUpdateData], g_eClient[client][iUserId]);
	
	if(KvJumpToKey(g_hKeyValue, m_szAuth))
	{
		KvDeleteThis(g_hKeyValue);
		KvRewind(g_hKeyValue);
		KeyValuesToFile(g_hKeyValue, g_szTempFile);
	}
}