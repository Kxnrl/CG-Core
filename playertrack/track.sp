//////////////////////////////
//	TRACK CLIENT ANALYTICS	//
//////////////////////////////
public void OnOSQueried(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{
	//如果是无效操作
	if(g_eClient[client][hOSTimer] == INVALID_HANDLE)
	{
		return; // Timed out
	}
	
	//获得查询结果
	if(result == ConVarQuery_NotFound)
	{
		g_eClient[client][iOSQuery]++;
		if(g_eClient[client][iOSQuery] >= view_as<int>(OS_Total))
		{
			CloseHandle(g_eClient[client][hOSTimer]);
			g_eClient[client][hOSTimer] = INVALID_HANDLE;
		}
		return;
	}
	else
	{
		for(int i = 0; i < view_as<int>(OS_Total); i++)
		{
			if(StrEqual(cvarName, g_szOSConVar[i]))
			{
				g_eClient[client][iOS] = view_as<OS>(i);		//g_eClient[client][iOS] = OS:i;
				break;
			}
		}
		
		CloseHandle(g_eClient[client][hOSTimer]);
		g_eClient[client][hOSTimer] = INVALID_HANDLE;
	}
}

public Action Timer_OSTimeout(Handle timer, any userid)
{
	//OS查询Timeout
	int client = GetClientOfUserId(userid);
	if(client == 0)
	{
		return;
	}
	
	g_eClient[client][hOSTimer] = INVALID_HANDLE;
}

public Action Timer_HandleConnect(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	
	if(client == 0 || !IsClientInGame(client))
		return Plugin_Stop;
	
	if(g_eClient[client][iConnectTime] == 0)
	{
		g_eClient[client][iConnectTime] = GetTime();
		return Plugin_Continue;
	}
	
	if(g_eClient[client][iPlayerId] == 0)
		return Plugin_Continue;

	if(g_eClient[client][hOSTimer] != INVALID_HANDLE || !g_eClient[client][bLoaded])
		return Plugin_Continue;
	
	//获得 客户OS|当前地图|当前日期|客户权限
	char date[64], map[128], os[64];
	FormatTime(date, 64, "%Y/%m/%d %H:%M:%S", GetTime());

	GetCurrentMap(map, 128);
	if(g_eClient[client][iOS] == OS_Windows)
		strcopy(os, 64, "Windows");
	else if(g_eClient[client][iOS] == OS_Mac)
		strcopy(os, 64, "MacOS");
	else if(g_eClient[client][iOS] == OS_Linux)
		strcopy(os, 64, "Linux");
	
	GetClientFlags(client);

	Format(g_eClient[client][szInsertData], 512, "INSERT INTO `playertrack_analytics` (`playerid`, `connect_time`, `connect_date`, `serverid`, `map`, `flags`, `ip`, `os`) VALUES ('%d', '%d', '%s', '%d', '%s', '%s', '%s', '%s')", g_eClient[client][iPlayerId], g_eClient[client][iConnectTime], date, g_iServerId, map, g_eClient[client][szAdminFlags], g_eClient[client][szIP], os);
	SQL_TQuery(g_hDB_csgo, SQLCallback_InsertPlayerStat, g_eClient[client][szInsertData], g_eClient[client][iUserId]);

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
	
	//处理Share值
	int share = duration/60 + g_eClient[client][iGetShare];
	
	char os[64];
	if(g_eClient[client][iOS] == OS_Windows) 
		strcopy(os, 64, "Windows");
	else if(g_eClient[client][iOS] == OS_Mac) 
		strcopy(os, 64, "MacOS");
	else if(g_eClient[client][iOS] == OS_Linux) 
		strcopy(os, 64, "Linux");

	//获得客户名字
	char username[128], auth[32];
	GetClientName(client, username, 128);
	GetClientAuthId(client, AuthId_Steam2, auth, 32, true);	

	//开始SQL查询操作
	char sBuffer[3][256];
	SQL_EscapeString(g_hDB_csgo, username, sBuffer[0], 256);	
	SQL_EscapeString(g_hDB_csgo, os, sBuffer[1], 256);
	SQL_EscapeString(g_hDB_csgo, g_eClient[client][szAdminFlags], sBuffer[2], 256);
	
	if(g_eClient[client][iGroupId] != 0 && g_eClient[client][iTemp] == -1)
	{
		int exp = (RoundToNearest(duration * 0.033333) + g_eClient[client][iExp]) % 1000;
		int upl = (RoundToNearest(duration * 0.033333) + g_eClient[client][iExp]) / 1000;
		Format(g_eClient[client][szUpdateData], 1024, "UPDATE playertrack_player AS a, playertrack_analytics AS b SET a.name = '%s', a.onlines = a.onlines+%d, a.lastip = '%s', a.lasttime = '%d', a.os = '%s', a.flags = '%s', a.number = a.number+1, a.share = a.share+%d, a.exp = '%d', a.level = a.level+%d, b.duration = '%d' WHERE a.id = '%d' AND b.id = '%d' AND a.steamid = '%s' AND b.playerid = '%d'", sBuffer[0], duration, g_eClient[client][szIP], GetTime(), sBuffer[1], sBuffer[2], share, exp, upl, duration, g_eClient[client][iPlayerId], g_eClient[client][iAnalyticsId], auth, g_eClient[client][iPlayerId]);
	}
	else
		Format(g_eClient[client][szUpdateData], 1024, "UPDATE playertrack_player AS a, playertrack_analytics AS b SET a.name = '%s', a.onlines = a.onlines+%d, a.lastip = '%s', a.lasttime = '%d', a.os = '%s', a.flags = '%s', a.number = a.number+1, a.share = a.share+%d, b.duration = '%d' WHERE a.id = '%d' AND b.id = '%d' AND a.steamid = '%s' AND b.playerid = '%d'", sBuffer[0], duration, g_eClient[client][szIP], GetTime(), sBuffer[1], sBuffer[2], share, duration, g_eClient[client][iPlayerId], g_eClient[client][iAnalyticsId], auth, g_eClient[client][iPlayerId]);
	
	SQL_TQuery(g_hDB_csgo, SQLCallback_SaveClientStat, g_eClient[client][szUpdateData], g_eClient[client][iUserId]);

	if(GetUserFlagBits(client) & ADMFLAG_CHANGEMAP)
	{
		char steamid[32], m_szQueryString[256];
		GetClientAuthId(client, AuthId_Steam2, steamid, 32, true);
		Format(m_szQueryString, 256, "UPDATE sb_admins SET onlines=onlines+%d,lastseen=%d,today=today+%d WHERE (authid=\"STEAM_1:%s\" OR authid=\"STEAM_0:%s\")", duration, GetTime(), duration, steamid[8], steamid[8]);
		SQL_TQuery(g_hDB_csgo, SQLCallBack_SaveAdminOnlines, m_szQueryString, GetClientUserId(client));
	}
}