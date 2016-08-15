//////////////////////////////
//		SQL CONNECTIONS		//
//////////////////////////////
void SQL_TConnect_csgo()
{
	if(g_hDB_csgo != INVALID_HANDLE)
		CloseHandle(g_hDB_csgo);
	
	g_hDB_csgo = INVALID_HANDLE;
	
	if(SQL_CheckConfig("csgo"))
		SQL_TConnect(SQL_TConnect_Callback_csgo, "csgo");
	else
		SetFailState("Connect to Database Failed! Error: no config entry found for 'csgo' in databases.cfg");
}

void SQL_TConnect_discuz()
{
	if(g_hDB_csgo != INVALID_HANDLE)
		CloseHandle(g_hDB_csgo);
	
	g_hDB_csgo = INVALID_HANDLE;
	
	if(SQL_CheckConfig("vip"))
		SQL_TConnect(SQL_TConnect_Callback_discuz, "vip");
	else
		SetFailState("Connect to Database Failed! Error: no config entry found for 'vip' in databases.cfg");
}

public void SQL_TConnect_Callback_csgo(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		g_iReconnect_csgo++;
		
		LogToFileEx(logFile_core, "Connection to SQL database 'csgo' has failed, Try %d, Reason: %s", g_iReconnect_csgo, error);
		
		if(g_iReconnect_csgo >= 100) 
		{
			SetFailState("PLUGIN STOPPED - Reason: can not connect to database 'csgo', retry 100! - PLUGIN STOPPED");
			LogToFileEx(logFile_core, " Too much errors. Restart your server for a new try. ");
		}
		else if(g_iReconnect_csgo > 5) 
			CreateTimer(5.0, Timer_ReConnect_csgo);
		else if(g_iReconnect_csgo > 3)
			CreateTimer(3.0, Timer_ReConnect_csgo);
		else
			CreateTimer(1.0, Timer_ReConnect_csgo);

		return;
	}

	g_hDB_csgo = CloneHandle(hndl);

	SQL_SetCharset(g_hDB_csgo, "utf8");
	
	PrintToServer("[CG-Core] Connection to database 'csgo' successful!");

	char m_szQuery[256];
	
	Format(m_szQuery, 256, "SELECT `id`,`servername` FROM playertrack_server WHERE serverip = '%s'", g_szIP);
	SQL_TQuery(g_hDB_csgo, SQLCallback_GetServerIP, m_szQuery, _, DBPrio_High);
	
	Format(m_szQuery, 256, "UPDATE `playertrack_player` SET groupid = '0', groupname = '未认证', temp = '0' WHERE temp < %d and temp > 0", GetTime());
	SQL_TQuery(g_hDB_csgo, SQLCallback_OnConnect, m_szQuery);

	g_iReconnect_csgo = 1;
}

public void SQL_TConnect_Callback_discuz(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		g_iReconnect_discuz++;
		
		LogToFileEx(logFile_core, "Connection to SQL database 'discuz' has failed, Try %d, Reason: %s", g_iReconnect_discuz, error);
		
		if(g_iReconnect_discuz >= 100) 
		{
			SetFailState("PLUGIN STOPPED - Reason: can not connect to database 'discuz', retry 100! - PLUGIN STOPPED");
			LogToFileEx(logFile_core, " Too much errors. Restart your server for a new try. ");
		}
		else if(g_iReconnect_discuz > 5) 
			CreateTimer(5.0, Timer_ReConnect_discuz);
		else if(g_iReconnect_discuz > 3)
			CreateTimer(3.0, Timer_ReConnect_discuz);
		else
			CreateTimer(1.0, Timer_ReConnect_discuz);

		return;
	}

	g_hDB_discuz = CloneHandle(hndl);

	//SQL_FastQuery(g_hDB_discuz, "SET NAMES 'UTF8'");
	SQL_SetCharset(g_hDB_discuz, "utf8");
	
	PrintToServer("[CG-Core] Connection to database 'discuz' successful!");

	g_iReconnect_discuz = 1;
}

public Action Timer_ReConnect_csgo(Handle timer)
{
	SQL_TConnect_csgo();
	return Plugin_Stop;
}

public Action Timer_ReConnect_discuz(Handle timer)
{
	SQL_TConnect_csgo();
	return Plugin_Stop;
}

//////////////////////////////
//		SQL CALLBACKS		//
//////////////////////////////
/**server callbacks**/
public void SQLCallback_GetServerIP(Handle owner, Handle hndl, const char[] error, any data)
{
	//如果操作失败
	if(hndl == INVALID_HANDLE) 
	{
		//输出错误日志
		LogToFileEx(logFile_core, "Query server ID Failed! Reason: %s", error);
		return;
	}
	
	//执行SQL_FetchRow
	if(SQL_FetchRow(hndl))
	{
		//ServerID获取
		g_ServerID = SQL_FetchInt(hndl, 0);
		SQL_FetchString(hndl, 1, g_szHostName, 256);
		SetConVarString(FindConVar("hostname"), g_szHostName, false, false);
		LogToFileEx(logFile_core, "ServerID is \"%d\"  ServerName is \"%s\" ", g_ServerID, g_szHostName);
		SettingAdver();
		
		char m_szQuery[256];
		Format(m_szQuery, 256, "SELECT faith,SUM(share) FROM playertrack_player GROUP BY faith");
		SQL_TQuery(g_hDB_csgo, SQLCallback_GetShare, m_szQuery);
	}
	else
	{
		//开始查询数据库 并输出到文件 查询进程高优先级
		char m_szQuery[256];
		Format(m_szQuery, 256, "INSERT INTO playertrack_server (servername, serverip) VALUES ('NewServer', '%s')", g_szIP);
		Format(g_szHostName, 128, "☞[CG社区]NewServer!");
		LogToFileEx(logFile_core, "Not Found this server in playertrack_server , now Register this!  %s", m_szQuery);
		SQL_TQuery(g_hDB_csgo, SQLCallback_InsertServerIP, m_szQuery, _, DBPrio_High);
	}
	
	OnServerLoadSuccess();
	
	if(g_bLateLoad)
	{
		for(int i = 1; i <= MaxClients; ++i)
		{
			if(IsClientInGame(i))
				OnClientPostAdminCheck(i);
		}
	}
}

public void SQLCallback_InsertServerIP(Handle owner, Handle hndl, const char[] error, any data)
{
	//如果操作失败
	if(hndl == INVALID_HANDLE)
	{
		//输出错误日志
		LogToFileEx(logFile_core, "INSERT server ID Failed! Reason: %s", error);
		return;
	}
	
	//从INSERT ID获得ServerID 变量g_ServerID
	g_ServerID = SQL_GetInsertId(hndl);
}

public void SQLCallback_GetShare(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		char m_szQuery[256];
		Format(m_szQuery, 256, "SELECT faith,SUM(share) FROM playertrack_player GROUP BY faith");
		SQL_TQuery(g_hDB_csgo, SQLCallback_GetShare, m_szQuery);
		LogToFileEx(logFile_core, "Get Share Failed! Reason: %s", error);
		return;
	}
	
	if(SQL_GetRowCount(hndl) > 0)
	{
		while(SQL_FetchRow(hndl))
		{
			g_Share[SQL_FetchInt(hndl, 0)] = SQL_FetchInt(hndl, 1);
		}
	}
}

/**client callbacks**/
public void SQLCallback_GetClientStat(Handle owner, Handle hndl, const char[] error, any userid)
{
	int client = GetClientOfUserId(userid);
	//如果是BOT, 取消查询

	if(g_eClient[client][bIsBot])
		return;
	
	if(client < 1 || client > MaxClients)
		return;
	
	g_eClient[client][iUserId] = userid;

	//如果操作失败
	if(hndl == INVALID_HANDLE)
	{
		//输出错误日志
		LogToFileEx(logFile_core, "Query Client Stats Failed! Client:\"%N\" \nError Happen: %s", client, error);
		char auth[32], m_szQuery[512];
		GetClientAuthId(client, AuthId_Steam2, auth, 32, true);
		Format(m_szQuery, 512, "SELECT a.id, a.onlines, a.number, a.faith, a.share, a.buff, a.signature, a.groupid, a.groupname, a.exp, a.level, a.temp, a.notice, b.unixtimestamp FROM playertrack_player AS a LEFT JOIN `playertrack_sign` b ON b.steamid = a.steamid WHERE a.steamid = '%s' ORDER BY a.id ASC LIMIT 1;", auth);
		SQL_TQuery(g_hDB_csgo, SQLCallback_GetClientStat, m_szQuery, g_eClient[client][iUserId]);
		return;
	}

	//执行SQL_FetchRow
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		//客户端数据读取 ID|在线时长|连线次数|签名
		g_eClient[client][iPlayerId] = SQL_FetchInt(hndl, 0);
		g_eClient[client][iOnlineTime] = SQL_FetchInt(hndl, 1);
		g_eClient[client][iConnectCounts] = SQL_FetchInt(hndl, 2);
		g_eClient[client][iFaith] = SQL_FetchInt(hndl, 3);
		g_eClient[client][iShare] = SQL_FetchInt(hndl, 4);
		g_eClient[client][iBuff] = SQL_FetchInt(hndl, 5);
		SQL_FetchString(hndl, 6, g_eClient[client][szSignature], 256);
		g_eClient[client][iGroupId] = SQL_FetchInt(hndl, 7);
		SQL_FetchString(hndl, 8, g_eClient[client][szGroupName], 256);
		g_eClient[client][iExp] = SQL_FetchInt(hndl, 9);
		g_eClient[client][iLevel] = SQL_FetchInt(hndl, 10);
		g_eClient[client][iTemp] = SQL_FetchInt(hndl, 11);
		g_eClient[client][bPrint] = SQL_FetchInt(hndl, 12) > g_iLatestData ? true : false;
		
		g_eClient[client][bLoaded] = true;

		char steam32[32], steamid64[32], m_szQuery[512];
		GetClientAuthId(client, AuthId_Steam2, steam32, 32, true);
		GetClientAuthId(client, AuthId_SteamID64, steamid64, 32, true);
		
		Format(m_szQuery, 512, "SELECT m.uid, m.username FROM dz_steam_users AS s LEFT JOIN dz_common_member m ON s.uid = m.uid WHERE s.steamID64 = '%s' LIMIT 1", steamid64);
		SQL_TQuery(g_hDB_discuz, SQLCallback_GetClientDiscuzName, m_szQuery, g_eClient[client][iUserId]);
		
		if(g_eClient[client][iFaith] == 0 && g_ServerID != 23 && g_ServerID != 24 && g_ServerID != 11 && g_ServerID != 12 && g_ServerID != 13)
		{
			ShowFaithFirstMenuToClient(client);
		}
		
		//签到查询部分
		if(SQL_IsFieldNull(hndl, 13))
		{
			//如果查不到数据
			char username[128], EscapeName[256];
			GetClientName(client, username, 128);

			SQL_EscapeString(g_hDB_csgo, username, EscapeName, 256);

			Format(m_szQuery, 512, "INSERT INTO playertrack_sign (username, steamid, timeofsignin, unixtimestamp) VALUES ('%s', '%s', '0', '0')", EscapeName, steam32);
			SQL_TQuery(g_hDB_csgo, SQLCallback_NothingCallback, m_szQuery, g_eClient[client][iUserId]);

			g_eClient[client][iLastSignTime] = 0;
			SetClientSignStat(client);
		}
		else
		{
			g_eClient[client][iLastSignTime] = SQL_FetchInt(hndl, 13);
			SetClientSignStat(client);
		}
		
		OnClientAuthLoaded(client);
	}
	else
	{
		//如果查不到数据 INSERT为新的玩家 记录到日志文件
		//获得客户端数据 steamid|名字|IP|权限
		char auth[32], username[128], EscapeName[256], m_szQuery[512];
		GetClientAuthId(client, AuthId_Steam2, auth, 32, true);
		GetClientName(client, username, 128);
		SQL_EscapeString(g_hDB_csgo, username, EscapeName, 256);
		Format(m_szQuery, 512, "INSERT INTO playertrack_player (name, steamid, onlines, lastip, firsttime, lasttime, os, flags, number, signature) VALUES ('%s', '%s', '0', '%s', '%d', '0', 'unknow', 'unknow', '0', DEFAULT)", EscapeName, auth, g_eClient[client][szIP], g_eClient[client][iConnectTime]);
		SQL_TQuery(g_hDB_csgo, SQLCallback_InsertClientStat, m_szQuery, g_eClient[client][iUserId]);
	}
}

public void SQLCallback_GetClientDiscuzName(Handle owner, Handle hndl, const char[] error, any userid)
{
	int client = GetClientOfUserId(userid);
	
	if(client < 1 || client > MaxClients)
		return;
	
	g_eClient[client][iUserId] = userid;
	
	if(hndl == INVALID_HANDLE)
	{
		RunAdminCacheChecks(client);
		VipChecked(client);
		OnClientDataLoaded(client);
		g_eClient[client][iUID] = -1;
		strcopy(g_eClient[client][szDiscuzName], 128, "未注册");
		LogToFileEx(logFile_core, "Check '%N' VIP Error happened: %s", client, error);
		return;
	}

	if(SQL_FetchRow(hndl) && SQL_HasResultSet(hndl))
	{
		g_eClient[client][iUID] = SQL_FetchInt(hndl, 0);
		SQL_FetchString(hndl, 1, g_eClient[client][szDiscuzName], 128);
		
		OnClientDataLoaded(client);
		
		char m_szQuery[128];
		Format(m_szQuery, 128, "SELECT exptime, isyear FROM dz_dc_vip WHERE uid = %d", g_eClient[client][iUID]);
		SQL_TQuery(g_hDB_discuz, SQLCallback_CheckVIP, m_szQuery, g_eClient[client][iUserId]);
	}
	else
	{
		VipChecked(client);
		OnClientDataLoaded(client);
		g_eClient[client][iUID] = -1;
		strcopy(g_eClient[client][szDiscuzName], 128, "未注册");
	}
}

public void SQLCallback_CheckVIP(Handle owner, Handle hndl, const char[] error, any userid)
{
	int client = GetClientOfUserId(userid);
	
	if(client < 1 || client > MaxClients || !IsClientConnected(client))
		return;
	
	g_eClient[client][iUserId] = userid;

	if(hndl == INVALID_HANDLE)
	{
		RunAdminCacheChecks(client);
		VipChecked(client);
		LogToFileEx(logFile_core, "Check '%N' VIP Error happened: %s", client, error);
		return;
	}

	if(SQL_FetchRow(hndl) && SQL_HasResultSet(hndl))
	{
		int exptime = SQL_FetchInt(hndl, 0);
		if(exptime == 2147454847)
		{
			SetClientVIP(client, 3);
		}
		else if(exptime > GetTime())
		{
			int isyear = SQL_FetchInt(hndl, 1);
			if(isyear == 1)
				SetClientVIP(client, 2);
			else
				SetClientVIP(client, 1);
		}
		else
		{
			RunAdminCacheChecks(client);
			VipChecked(client);
		}
	}
	else
	{
		RunAdminCacheChecks(client);
		VipChecked(client);
	}
}

public void SQLCallback_InsertClientStat(Handle owner, Handle hndl, const char[] error, any userid)
{
	//定义客户
	int client = GetClientOfUserId(userid);

	if(!client)
		return;

	if(hndl == INVALID_HANDLE)
	{
		//记录客户信息 写入到错误日志
		LogToFileEx(logFile_core, "INSERT playertrack_player Failed! Client:\"%N\" \nError Happen: %s", client, error);
		
		//重试检查  辣鸡阿里云RDS
		char auth[32], m_szQuery[512];
		GetClientAuthId(client, AuthId_Steam2, auth, 32, true);
		Format(m_szQuery, 512, "SELECT a.id, a.onlines, a.number, a.faith, a.share, a.buff, a.signature, a.groupid, a.groupname, a.exp, a.level, a.temp, a.notice, b.unixtimestamp FROM playertrack_player AS a LEFT JOIN `playertrack_sign` b ON b.steamid = a.steamid WHERE a.steamid = '%s' ORDER BY a.id ASC LIMIT 1;", auth);
		SQL_TQuery(g_hDB_csgo, SQLCallback_GetClientStat, m_szQuery, g_eClient[client][iUserId]);
	}
	else
	{
		//客户获得ID从INSERT ID
		g_eClient[client][iPlayerId] = SQL_GetInsertId(hndl);
		Format(g_eClient[client][szSignature], 256, "该玩家未设置签名,请登录论坛设置");
		OnClientAuthLoaded(client);
		OnClientDataLoaded(client);
		g_eClient[client][bLoaded] = true;
	}
}

public void SQLCallback_SaveClientStat(Handle owner, Handle hndl, const char[] error, any userid)
{
	int client = GetClientOfUserId(userid);	

	if(!client)
		return;

	//操作失败
	if(hndl == INVALID_HANDLE)
	{
		if(g_eClient[client][iDataRetry] <= 5)
		{
			g_eClient[client][iDataRetry]++;
			SQL_TQuery(g_hDB_csgo, SQLCallback_SaveClientStat, g_eClient[client][szUpdateData], g_eClient[client][iUserId]);
			LogToFileEx(logFile_core, "UPDATE Client Data Failed!   Times:%d Player:\"%N\" \nError Happen:%s", g_eClient[client][iDataRetry], client, error);
		}
		else
		{
			LogToFileEx(logFile_core, "UPDATE Client Data Failed!   Times:(Times out) Player:\"%N\" \nError Happen:%s", client, error);
			g_eClient[client][iDataRetry] = 0;
		}
	}
}

public void SQLCallback_InsertPlayerStat(Handle owner, Handle hndl, const char[] error, any userid)
{
	//定义客户
	int client = GetClientOfUserId(userid);

	if(client == 0)
		return;

	//SQL如果操作失败
	if(hndl == INVALID_HANDLE)
	{
		//记录客户信息 写入到错误日志
		LogToFileEx(logFile_core, "INSERT playertrack_analytics Failed!   Player:\"%N\" \nError Happen:%s", client, error);
		char m_szQuery[256];
		Format(m_szQuery, 256, "SELECT * FROM `playertrack_analytics` WHERE (connect_time = %d AND ip = '%s' AND playerid = %d) order by id desc limit 1;", g_eClient[client][iConnectTime], g_eClient[client][szIP], g_eClient[client][iPlayerId]);
		SQL_TQuery(g_hDB_csgo, SQLCallback_InsertPlayerStatFailed, m_szQuery, g_eClient[client][iUserId]);
		return;
	}
	else
	{
		//获得RowID从INSERT ID
		g_eClient[client][iAnalyticsId] = SQL_GetInsertId(hndl);
	}
}

public void SQLCallback_InsertPlayerStatFailed(Handle owner, Handle hndl, const char[] error, any userid)
{
	int client = GetClientOfUserId(userid);

	if(client == 0)
		return;
	
	if(hndl == INVALID_HANDLE)
	{
		//输出错误日志
		LogToFileEx(logFile_core, "Confirm Insert Failed! Client:\"%N\" \nError Happen: %s", error);
		char m_szQuery[256];
		Format(m_szQuery, 256, "SELECT * FROM `playertrack_analytics` WHERE (connect_time = %d AND ip = '%s' AND playerid = %d) order by id desc limit 1;", g_eClient[client][iConnectTime], g_eClient[client][szIP], g_eClient[client][iPlayerId]);
		SQL_TQuery(g_hDB_csgo, SQLCallback_InsertPlayerStatFailed, m_szQuery, g_eClient[client][iUserId]);
	}
	else
	{
		if(SQL_FetchRow(hndl))
			g_eClient[client][iAnalyticsId] = SQL_FetchInt(hndl, 0);
		else
			SQL_TQuery(g_hDB_csgo, SQLCallback_InsertPlayerStat, g_eClient[client][szInsertData], g_eClient[client][iUserId]);
	}
}

public void SQLCallback_GetSigninStat(Handle owner, Handle hndl, const char[] error, any userid)
{
	int client = GetClientOfUserId(userid);

	if(!client || !IsClientInGame(client))
		return;
	
	if(hndl == INVALID_HANDLE)
	{
		PrintToChat(client, "%s \x02未知错误,请重试!", PLUGIN_PREFIX_SIGN);
		g_eClient[client][LoginProcess] = false;
		return;
	}
	
	char m_szQuery[512], auth[32], username[128], EscapeName[256];
	GetClientName(client, username, 128);
	GetClientAuthId(client, AuthId_Steam2, auth, 32, true);
	SQL_EscapeString(g_hDB_csgo, username, EscapeName, 256);
	
	if(SQL_FetchRow(hndl)) 
	{
		//Getting last login time
		int lastlogon = SQL_FetchInt(hndl, 1);
		int timeslogged = SQL_FetchInt(hndl, 0);
		int thistime = GetTime();
		int result = thistime - lastlogon;	
		
		//86400 = 24h
		if(result >= 86400) 
		{			
			Format(m_szQuery, 512, "UPDATE playertrack_sign SET username = '%s', timeofsignin = timeofsignin+1, unixtimestamp = '%d' WHERE steamid = '%s' ", EscapeName, GetTime(), auth);

			Handle SQLDataPack = CreateDataPack();
			WritePackCell(SQLDataPack, g_eClient[client][iUserId]);
			WritePackCell(SQLDataPack, timeslogged);
			ResetPack(SQLDataPack);
			SQL_TQuery(g_hDB_csgo, SQLCallback_SignCallback, m_szQuery, SQLDataPack);
		}
	}
	else
	{
		Format(m_szQuery, 512, "INSERT INTO playertrack_sign (username, steamid, timeofsignin, unixtimestamp) VALUES ('%s', '%s', '0', '0')", EscapeName, auth);
		SQL_TQuery(g_hDB_csgo, SQLCallback_NothingCallback, m_szQuery, g_eClient[client][iUserId]);
		PrintToChat(client, "%s \x02已经刷新你的签到数据,请重新签到!", PLUGIN_PREFIX_SIGN);
	}
}

public void SQLCallback_SignCallback(Handle owner, Handle hndl, const char[] error, any SQLDataPack)
{
	int userid = ReadPackCell(SQLDataPack);
	int client = GetClientOfUserId(userid);
	int timeslogged = ReadPackCell(SQLDataPack);
	if(hndl == INVALID_HANDLE)
	{
		PrintToChat(client, "%s \x02未知错误!", PLUGIN_PREFIX_SIGN);
		g_eClient[client][LoginProcess] = false;
		LogToFileEx(logFile_core, "UPDATE Client Sign Failed! Client:%N Query:%s", client, error);
		return;
	}
	
	PrintToChat(client, "%s \x01签到成功,你已累计签到\x0C%i\x01天!", PLUGIN_PREFIX_SIGN, timeslogged+1);
	g_eClient[client][bTwiceLogin] = true;
	g_eClient[client][LoginProcess] = false;
	OnClientSignSucessed(client);
	CloseHandle(SQLDataPack);
}

public void SQLCallback_GetAdvData(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl != INVALID_HANDLE)
	{
		if(SQL_HasResultSet(hndl))
		{
			//RemoveADV();
			Handle kv = CreateKeyValues("ServerAdvertisement", "", "");
			char FILE_PATH[256];
			BuildPath(Path_SM, FILE_PATH, 256, "configs/ServerAdvertisement.cfg");
			FileToKeyValues(kv, FILE_PATH);
			//LogToFileEx(logFile_core, "Set New Advertisement");
			KvDeleteKey(kv, "Messages");
			int Count = 0;
			while(SQL_FetchRow(hndl))
			{
				char sType[4], sText[256], sCount[16];
				SQL_FetchString(hndl, 2, sType, 4);
				SQL_FetchString(hndl, 3, sText, 256);  // 0=ID 1=SID 2=TYPE 3=TEXT
				IntToString(Count, sCount, 16);
				if(KvJumpToKey(kv, "Messages", true))
				{
					if(KvJumpToKey(kv, sCount, true))
					{
						Count++;
						KvSetString(kv, "default", sText);
						KvSetString(kv, "type", sType);
						KvRewind(kv);
						//LogToFileEx(logFile_core, "New Adv: \"%s\"   \"%s\" ", sCount, sText);
					}
				}
			}
			KeyValuesToFile(kv, FILE_PATH);
			ServerCommand("sm_reloadsadvert");
			CloseHandle(kv);
			kv = INVALID_HANDLE;
		}
		CloseHandle(hndl);
	}
}

public void SQLCallback_NothingCallback(Handle owner, Handle hndl, const char[] error, any userid)
{
	if(hndl == INVALID_HANDLE)
	{
		int client = GetClientOfUserId(userid);
		LogToFileEx(logFile_core, "INSERT Failed: client:%N ERROR:%s", client, error);
		return;
	}
	
	int client = GetClientOfUserId(userid);
	g_eClient[client][LoginProcess] = false;
}

public void SQLCallBack_SaveAdminOnlines(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!client || !IsClientInGame(client))
		return;
	
	if(!(GetUserFlagBits(client) & ADMFLAG_CHANGEMAP) && !(GetUserFlagBits(client) & ADMFLAG_ROOT))
		return;

	if(hndl == INVALID_HANDLE)
	{
		LogToFileEx(logFile_cat, "==========================================================");
		LogToFileEx(logFile_cat, "Save \"%N\" Admin stats Failed: %s", client, error);
		LogToFileEx(logFile_cat, " \"%N\" AdminId: %d  Connect: %d  Disconnect: %d  Duration: %d", client, g_eClient[client][iConnectTime], GetTime(), GetTime()-g_eClient[client][iConnectTime]);
		LogToFileEx(logFile_cat, "==========================================================");
	}
}

public void SQLCallback_SaveDatabase(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		char m_szQuery[512];
		ReadPackString(data, m_szQuery, 512);
		LogToFileEx(logFile_core, "==========================================================");
		LogToFileEx(logFile_core, "Native SaveDatabase.  Error: %s", error);
		LogToFileEx(logFile_core, "Query: %s", m_szQuery);
		LogToFileEx(logFile_core, "==========================================================");
	}
	CloseHandle(data);
}

public void SQLCallback_SetFaith(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!client || !IsClientInGame(client))
		return;

	if(hndl == INVALID_HANDLE)
	{
		g_eClient[client][iFaith] = 0;
		PrintToChat(client, "%s  更新你的Faith失败,请联系服务器管理员", PLUGIN_PREFIX);
		return;
	}
	
	PrintToChat(client, "%s  服务器已更新你的数据,正在刷新...", PLUGIN_PREFIX);

	if(g_eClient[client][iFaith] == 1)
		PrintToChat(client, "[%s - %s] - Buff: 速度  Guardian: 猫灵", szFaith_CNATION[PURPLE], szFaith_CNAME[PURPLE]);
	else if(g_eClient[client][iFaith] == 2)
		PrintToChat(client, "[%s - %s] - Buff: 暴击  Guardian: 曼妥思", szFaith_CNATION[BLACK], szFaith_CNAME[BLACK]);
	else if(g_eClient[client][iFaith] == 3)
		PrintToChat(client, "[%s - %s] - Buff: 伤害  Guardian: 色拉", szFaith_CNATION[WHITE], szFaith_CNAME[WHITE]);
	else if(g_eClient[client][iFaith] == 4)
		PrintToChat(client, "[%s - %s] - Buff: 伤害  Guardian: 基佬铜", szFaith_CNATION[GREEN], szFaith_CNAME[GREEN]);
	
	CheckClientBuff(client);
}

public void SQLCallback_SetBuff(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!client || !IsClientInGame(client))
		return;

	if(hndl == INVALID_HANDLE)
	{
		g_eClient[client][iFaith] = 0;
		PrintToChat(client, "%s  更新你的Buff失败,请联系服务器管理员", PLUGIN_PREFIX);
		return;
	}
	
	PrintToChat(client, "%s  服务器已更新你的数据,正在刷新...", PLUGIN_PREFIX);
}

public void SQLCallback_InsertShare(Handle owner, Handle hndl, const char[] error, int userid)
{
	if(hndl == INVALID_HANDLE)
	{
		LogToFileEx(logFile_core, "Save Client Share Failed!  Error: %s", error);
		return;
	}
}

public void SQLCallback_FaithShareRank(Handle owner, Handle hndl, const char[] error, int userid)
{
	if(hndl == INVALID_HANDLE)
	{
		LogToFileEx(logFile_core, "Get Faith Share Rank Failed!  Error: %s", error);
		return;
	}
	
	int client = GetClientOfUserId(userid);
	if(!client || !IsClientInGame(client))
		return;
	
	int iIndex, ishare;
	char sName[128];
	
	if(SQL_GetRowCount(hndl))
	{
		Handle hPack = CreateDataPack();
		WritePackCell(hPack, iIndex);
		while(SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, sName, 128);
			ishare = SQL_FetchInt(hndl, 1);

			WritePackString(hPack, sName);
			WritePackCell(hPack, ishare);

			iIndex++;
		}

		ResetPack(hPack);
		WritePackCell(hPack, iIndex);
		CreateTopMenu(client, hPack);
	}
}

public void SQLCallback_GetGroupId(Handle owner, Handle hndl, const char[] error, any userid)
{
	int client = GetClientOfUserId(userid);

	if(!client)
		return;

	if(hndl == INVALID_HANDLE)
	{
		LogToFileEx(logFile_core, "Query player Data Failed! Error:%s", error);
		return;
	}

	if(SQL_FetchRow(hndl))
	{
		g_eClient[client][iGroupId] = SQL_FetchInt(hndl, 0);
		SQL_FetchString(hndl, 1, g_eClient[client][szGroupName], 64);
		g_eClient[client][iExp] = SQL_FetchInt(hndl, 2);
		g_eClient[client][iLevel] = SQL_FetchInt(hndl, 3);
		g_eClient[client][iTemp] = SQL_FetchInt(hndl, 4);
	}

	OnClientAuthLoaded(client);
}

public void SQLCallback_SetTemp(Handle owner, Handle hndl, const char[] error, any userid)
{
	if(hndl == INVALID_HANDLE)
	{
		int client = GetClientOfUserId(userid);
		LogToFileEx(logFile_core, "set temp player Failed! Error:%s", error);
		PrintToChat(client, "%s \x02添加临时认证失败,SQL错误!", PLUGIN_PREFIX);
		return;
	}
}

public void SQLCallback_DeleteTemp(Handle owner, Handle hndl, const char[] error, any userid)
{ 
	int client = GetClientOfUserId(userid);
	
	if(hndl == INVALID_HANDLE)
	{
		LogToFileEx(logFile_core, "DELETE Tmp Data Failed! Client:%N  Target:%N", client, g_eAdmin[iTarget]);
		PrintToChat(client, "%s 解除临时认证失败...", PLUGIN_PREFIX);
		return;
	}
	
	int target = g_eAdmin[iTarget]; 
	LoadAuthorized(target);
}

public void SQLCallback_OnConnect(Handle owner, Handle hndl, const char[] error, any userid)
{
	if(hndl == INVALID_HANDLE)
	{
		LogToFileEx(logFile_core, "Delete on start Failed! Error:%s", error);
		return;
	}
}

public void SQLCallback_GetNotice(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogToFileEx(logFile_core, "Get Notice Failed! Error: %s", error);
		return;
	}
	
	if(SQL_GetRowCount(hndl) > 0)
	{
		int global, server;
		while(SQL_FetchRow(hndl))
		{
			if(SQL_FetchInt(hndl, 0) == 0)
			{
				SQL_FetchString(hndl, 3, g_szGlobal[0], 256);
				SQL_FetchString(hndl, 4, g_szGlobal[1], 256);
				SQL_FetchString(hndl, 5, g_szGlobal[2], 256);
				SQL_FetchString(hndl, 6, g_szGlobal[3], 256);
				SQL_FetchString(hndl, 7, g_szGlobal[4], 256);
				SQL_FetchString(hndl, 8, g_szGlobal[5], 256);
				global = SQL_FetchInt(hndl, 9);
			}
			if(SQL_FetchInt(hndl, 0) == g_ServerID)
			{
				SQL_FetchString(hndl, 3, g_szServer[0], 256);
				SQL_FetchString(hndl, 4, g_szServer[1], 256);
				SQL_FetchString(hndl, 5, g_szServer[2], 256);
				SQL_FetchString(hndl, 6, g_szServer[3], 256);
				SQL_FetchString(hndl, 7, g_szServer[4], 256);
				SQL_FetchString(hndl, 8, g_szServer[5], 256);
				server = SQL_FetchInt(hndl, 9);
			}
		}
		
		if(global > server)
			g_iLatestData = global;
		else
			g_iLatestData = server;
	}
}