//////////////////////////////
//		SQL CONNECTIONS		//
//////////////////////////////
void SQL_TConnect_csgo()
{
	if(g_eHandle[DB_Game] != INVALID_HANDLE)
		CloseHandle(g_eHandle[DB_Game]);
	
	g_eHandle[DB_Game] = INVALID_HANDLE;
	
	if(SQL_CheckConfig("csgo"))
		SQL_TConnect(SQL_TConnect_Callback_csgo, "csgo");
	else
		SetFailState("Connect to Database Failed! Error: no config entry found for 'csgo' in databases.cfg");
}

void SQL_TConnect_discuz()
{
	if(g_eHandle[DB_Discuz] != INVALID_HANDLE)
		CloseHandle(g_eHandle[DB_Discuz]);
	
	g_eHandle[DB_Discuz] = INVALID_HANDLE;
	
	if(SQL_CheckConfig("vip"))
		SQL_TConnect(SQL_TConnect_Callback_discuz, "vip");
	else
		SetFailState("Connect to Database Failed! Error: no config entry found for 'vip' in databases.cfg");
}

public void SQL_TConnect_Callback_csgo(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		g_iConnect_csgo++;
		
		LogToFileEx(g_szLogFile, "Connection to SQL database 'csgo' has failed, Try %d, Reason: %s", g_iConnect_csgo, error);
		
		if(g_iConnect_csgo >= 100) 
		{
			SetFailState("PLUGIN STOPPED - Reason: can not connect to database 'csgo', retry 100! - PLUGIN STOPPED");
			LogToFileEx(g_szLogFile, " Too much errors. Restart your server for a new try. ");
		}
		else if(g_iConnect_csgo > 5) 
			CreateTimer(5.0, Timer_ReConnect_csgo);
		else if(g_iConnect_csgo > 3)
			CreateTimer(3.0, Timer_ReConnect_csgo);
		else
			CreateTimer(1.0, Timer_ReConnect_csgo);

		return;
	}

	g_eHandle[DB_Game] = CloneHandle(hndl);

	SQL_SetCharset(g_eHandle[DB_Game], "utf8");
	
	PrintToServer("[CG-Core] Connection to database 'csgo' successful!");

	char m_szQuery[256];
	
	Format(m_szQuery, 256, "SELECT `id`,`servername` FROM playertrack_server WHERE serverip = '%s'", g_szIP);
	MySQL_Query(g_eHandle[DB_Game], SQLCallback_GetServerIP, m_szQuery, _, DBPrio_High);
	
	Format(m_szQuery, 256, "DELETE FROM `playertrack_analytics` WHERE connect_time < %d and duration = -1", GetTime()-18000);
	MySQL_Query(g_eHandle[DB_Game], SQLCallback_OnConnect, m_szQuery, _, DBPrio_Low);

	g_iConnect_csgo = 1;
}

public void SQL_TConnect_Callback_discuz(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		g_iConnect_discuz++;
		
		LogToFileEx(g_szLogFile, "Connection to SQL database 'discuz' has failed, Try %d, Reason: %s", g_iConnect_discuz, error);
		
		if(g_iConnect_discuz >= 100) 
		{
			SetFailState("PLUGIN STOPPED - Reason: can not connect to database 'discuz', retry 100! - PLUGIN STOPPED");
			LogToFileEx(g_szLogFile, " Too much errors. Restart your server for a new try. ");
		}
		else if(g_iConnect_discuz > 5) 
			CreateTimer(5.0, Timer_ReConnect_discuz);
		else if(g_iConnect_discuz > 3)
			CreateTimer(3.0, Timer_ReConnect_discuz);
		else
			CreateTimer(1.0, Timer_ReConnect_discuz);

		return;
	}

	g_eHandle[DB_Discuz] = CloneHandle(hndl);

	//SQL_FastQuery(g_eHandle[DB_Discuz], "SET NAMES 'UTF8'");
	SQL_SetCharset(g_eHandle[DB_Discuz], "utf8");
	
	PrintToServer("[CG-Core] Connection to database 'discuz' successful!");

	g_iConnect_discuz = 1;
}

public Action Timer_ReConnect_csgo(Handle timer)
{
	SQL_TConnect_csgo();
	return Plugin_Stop;
}

public Action Timer_ReConnect_discuz(Handle timer)
{
	SQL_TConnect_discuz();
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
		LogToFileEx(g_szLogFile, "Query server ID Failed! Reason: %s", error);
		
		if(StrContains(error, "lost connection", false) == -1)
		{
			char m_szQuery[256];
	
			Format(m_szQuery, 256, "SELECT `id`,`servername` FROM playertrack_server WHERE serverip = '%s'", g_szIP);
			MySQL_Query(g_eHandle[DB_Game], SQLCallback_GetServerIP, m_szQuery, _, DBPrio_High);
		}
		
		return;
	}
	
	//执行SQL_FetchRow
	if(SQL_FetchRow(hndl))
	{
		//ServerID获取
		g_iServerId = SQL_FetchInt(hndl, 0);
		SQL_FetchString(hndl, 1, g_szHostName, 256);
		SetConVarString(FindConVar("hostname"), g_szHostName, false, false);
		SettingAdver();
		
		OnServerLoadSuccess();
	}
	else
	{
		//开始查询数据库 并输出到文件 查询进程高优先级
		char m_szQuery[256];
		Format(m_szQuery, 256, "INSERT INTO playertrack_server (servername, serverip) VALUES ('NewServer', '%s')", g_szIP);
		Format(g_szHostName, 128, "【CG社区】NewServer!");
		SetConVarString(FindConVar("hostname"), g_szHostName, false, false);
		LogToFileEx(g_szLogFile, "Not Found this server in playertrack_server , now Register this!  %s", m_szQuery);
		MySQL_Query(g_eHandle[DB_Game], SQLCallback_InsertServerIP, m_szQuery, _, DBPrio_High);
	}
	
	if(g_bLateLoad)
	{
		for(int client = 1; client <= MaxClients; ++client)
		{
			if(IsClientInGame(client))
				OnClientPostAdminCheck(client);
		}
	}
}

public void SQLCallback_InsertServerIP(Handle owner, Handle hndl, const char[] error, any data)
{
	//如果操作失败
	if(hndl == INVALID_HANDLE)
	{
		//输出错误日志
		LogToFileEx(g_szLogFile, "INSERT server ID Failed! Reason: %s", error);
		return;
	}
	
	//从INSERT ID获得ServerID 变量g_ServerID
	g_iServerId = SQL_GetInsertId(hndl);
	OnServerLoadSuccess();
}

/**client callbacks**/
public void SQLCallback_GetClientStat(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);
	//如果是BOT, 取消查询
	if(client < 1 || client > MaxClients || !IsClientInGame(client) || g_eClient[client][bIsBot])
		return;

	//如果操作失败
	if(hndl == INVALID_HANDLE)
	{
		//输出错误日志
		if(StrContains(error, "lost connection", false) == -1)
		{
			LogToFileEx(g_szLogFile, "Query Client Stats Failed! Client:\"%N\" Error Happened: %s", client, error);
			return;
		}

		char m_szAuth[32], m_szQuery[256];
		GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
		Format(m_szQuery, 256, "SELECT id, onlines, lasttime, number, signature, signnumber, signtime, groupid, groupname, lilyid, lilydate, active FROM playertrack_player WHERE steamid = '%s' ORDER BY id ASC LIMIT 1;", m_szAuth);
		MySQL_Query(g_eHandle[DB_Game], SQLCallback_GetClientStat, m_szQuery, GetClientUserId(client), DBPrio_High);
		return;
	}

	//执行SQL_FetchRow
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		//客户端数据读取 ID|在线时长|连线次数|签名
		g_eClient[client][iPlayerId] = SQL_FetchInt(hndl, 0);
		g_eClient[client][iOnline] = SQL_FetchInt(hndl, 1);
		g_eClient[client][iLastseen] = SQL_FetchInt(hndl, 2);
		g_eClient[client][iNumber] = SQL_FetchInt(hndl, 3);
		SQL_FetchString(hndl, 4, g_eClient[client][szSignature], 256);
		g_eClient[client][iSignNum] = SQL_FetchInt(hndl, 5);
		g_eClient[client][iSignTime] = SQL_FetchInt(hndl, 6);
		g_eClient[client][iGroupId] = SQL_FetchInt(hndl, 7);
		SQL_FetchString(hndl, 8, g_eClient[client][szGroupName], 256);
		InitializeCP(client, SQL_FetchInt(hndl, 9), SQL_FetchInt(hndl, 10));
		g_eClient[client][iVitality] = SQL_FetchInt(hndl, 11);

		g_eClient[client][bLoaded] = true;

		if(g_eHandle[DB_Discuz] != INVALID_HANDLE)
		{
			char m_szAuth[32], m_szQuery[256];
			GetClientAuthId(client, AuthId_SteamID64, m_szAuth, 32, true);
			Format(m_szQuery, 256, "SELECT m.uid, m.username FROM dz_steam_users AS s LEFT JOIN dz_common_member m ON s.uid = m.uid WHERE s.steamID64 = '%s' LIMIT 1", m_szAuth);
			MySQL_Query(g_eHandle[DB_Discuz], SQLCallback_GetClientDiscuzName, m_szQuery, GetClientUserId(client), DBPrio_High);
		}
		else
		{
			LogToFileEx(g_szLogFile, "Check '%N' DZ Error happened: %s", client, error);
			RunAdminCacheChecks(client);
			OnClientVipChecked(client);
			OnClientDataLoaded(client);
			g_eClient[client][iUID] = -1;
			strcopy(g_eClient[client][szDiscuzName], 128, "未注册");
		}

		SetClientSignStat(client);
		
		CreateTimer(10.0, Timer_HandleConnect, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		//如果查不到数据 INSERT为新的玩家 记录到日志文件
		//获得客户端数据 steamid|名字|IP|权限
		char m_szAuth[32], username[128], EscapeName[256], m_szQuery[512];
		GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
		GetClientName(client, username, 128);
		SQL_EscapeString(g_eHandle[DB_Game], username, EscapeName, 256);
		Format(m_szQuery, 512, "INSERT INTO playertrack_player (name, steamid, onlines, lastip, firsttime, lasttime, number, flags, signature) VALUES ('%s', '%s', '0', '%s', '%d', '0', '0', 'unknow', DEFAULT)", EscapeName, m_szAuth, g_eClient[client][szIP], g_eClient[client][iConnectTime]);
		MySQL_Query(g_eHandle[DB_Game], SQLCallback_InsertClientStat, m_szQuery, GetClientUserId(client));
	}
}

public void SQLCallback_GetClientDiscuzName(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(client < 1 || client > MaxClients || !IsClientInGame(client) || g_eClient[client][bIsBot])
		return;

	if(hndl == INVALID_HANDLE)
	{
		if(StrContains(error, "lost connection", false) == -1)
		{
			LogToFileEx(g_szLogFile, "Check '%N' DZ Error happened: %s", client, error);
			RunAdminCacheChecks(client);
			OnClientVipChecked(client);
			OnClientDataLoaded(client);
			g_eClient[client][iUID] = -1;
			strcopy(g_eClient[client][szDiscuzName], 128, "未注册");
			return;
		}
		
		char m_szAuth[32], m_szQuery[256];
		GetClientAuthId(client, AuthId_SteamID64, m_szAuth, 32, true);
		
		Format(m_szQuery, 256, "SELECT m.uid, m.username FROM dz_steam_users AS s LEFT JOIN dz_common_member m ON s.uid = m.uid WHERE s.steamID64 = '%s' LIMIT 1", m_szAuth);
		MySQL_Query(g_eHandle[DB_Discuz], SQLCallback_GetClientDiscuzName, m_szQuery, GetClientUserId(client), DBPrio_High);

		return;
	}

	if(SQL_FetchRow(hndl))
	{
		g_eClient[client][iUID] = SQL_FetchInt(hndl, 0);
		SQL_FetchString(hndl, 1, g_eClient[client][szDiscuzName], 128);
		
		OnClientDataLoaded(client);
		
		char m_szQuery[256];
		Format(m_szQuery, 256, "SELECT exptime, isyear FROM dz_dc_vip WHERE uid = %d", g_eClient[client][iUID]);
		MySQL_Query(g_eHandle[DB_Discuz], SQLCallback_CheckVIP, m_szQuery, GetClientUserId(client));
	}
	else
	{
		OnClientVipChecked(client);
		OnClientDataLoaded(client);
		g_eClient[client][iUID] = -1;
		strcopy(g_eClient[client][szDiscuzName], 128, "未注册");
	}
}

public void SQLCallback_CheckVIP(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(client < 1 || client > MaxClients || !IsClientInGame(client) || g_eClient[client][bIsBot])
		return;

	if(hndl == INVALID_HANDLE)
	{
		if(StrContains(error, "lost connection", false) == -1)
		{
			RunAdminCacheChecks(client);
			OnClientVipChecked(client);
			LogToFileEx(g_szLogFile, "Check '%N' VIP Error happened: %s", client, error);
		}
		
		char m_szQuery[128];
		Format(m_szQuery, 128, "SELECT exptime, isyear FROM dz_dc_vip WHERE uid = %d", g_eClient[client][iUID]);
		MySQL_Query(g_eHandle[DB_Discuz], SQLCallback_CheckVIP, m_szQuery, GetClientUserId(client));
		
		return;
	}

	if(SQL_FetchRow(hndl))
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
			OnClientVipChecked(client);
		}
	}
	else
	{
		RunAdminCacheChecks(client);
		OnClientVipChecked(client);
	}
}

public void SQLCallback_InsertClientStat(Handle owner, Handle hndl, const char[] error, int userid)
{
	//定义客户
	int client = GetClientOfUserId(userid);

	if(client < 1 || client > MaxClients || !IsClientInGame(client) || g_eClient[client][bIsBot])
		return;

	if(hndl == INVALID_HANDLE)
	{
		//记录客户信息 写入到错误日志
		LogToFileEx(g_szLogFile, "INSERT playertrack_player Failed! Client:\"%N\" Error Happened: %s", client, error);
		
		//重试检查  辣鸡阿里云RDS
		char m_szAuth[32], m_szQuery[512];
		GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
		Format(m_szQuery, 256, "SELECT id, onlines, lasttime, number, signature, signnumber, signtime, groupid, groupname, lilyid, lilydate, active FROM playertrack_player WHERE steamid = '%s' ORDER BY id ASC LIMIT 1;", m_szAuth);
		MySQL_Query(g_eHandle[DB_Game], SQLCallback_GetClientStat, m_szQuery, GetClientUserId(client), DBPrio_High);
	}
	else
	{
		//客户获得ID从INSERT ID
		g_eClient[client][iPlayerId] = SQL_GetInsertId(hndl);
		Format(g_eClient[client][szSignature], 256, "该玩家未设置签名,请登录论坛设置");
		OnClientDataLoaded(client);
		g_eClient[client][bLoaded] = true;
	}
}

public void SQLCallback_SaveClientStat(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);	

	if(!client)
		return;

	//操作失败
	if(hndl == INVALID_HANDLE)
	{
		if(g_eClient[client][iDataRetry] <= 5)
		{
			LogToFileEx(g_szLogFile, "UPDATE Client Data Failed!   Times:%d Player:\"%N\" Error Happened:%s", g_eClient[client][iDataRetry], client, error);
			g_eClient[client][iDataRetry]++;

			if(StrContains(error, "empty", false) != -1)
				return;

			MySQL_Query(g_eHandle[DB_Game], SQLCallback_SaveClientStat, g_eClient[client][szUpdateData], GetClientUserId(client));
		}
		else
		{
			LogToFileEx(g_szLogFile, "UPDATE Client Data Failed!   Times:(Times out) Player:\"%N\" Error Happened:%s", client, error);
			g_eClient[client][iDataRetry] = 0;
		}
	}
}

public void SQLCallback_InsertPlayerStat(Handle owner, Handle hndl, const char[] error, int userid)
{
	//定义客户
	int client = GetClientOfUserId(userid);

	if(client < 1 || client > MaxClients || !IsClientInGame(client) || g_eClient[client][bIsBot])
		return;

	//SQL如果操作失败
	if(hndl == INVALID_HANDLE)
	{
		//记录客户信息 写入到错误日志
		LogToFileEx(g_szLogFile, "INSERT playertrack_analytics Failed!   Player:\"%N\" Error Happened:%s", client, error);
		char m_szQuery[256];
		Format(m_szQuery, 256, "SELECT * FROM `playertrack_analytics` WHERE (connect_time = %d AND ip = '%s' AND playerid = %d) order by id desc limit 1;", g_eClient[client][iConnectTime], g_eClient[client][szIP], g_eClient[client][iPlayerId]);
		MySQL_Query(g_eHandle[DB_Game], SQLCallback_InsertPlayerStatFailed, m_szQuery, GetClientUserId(client));
		return;
	}
	else
	{
		//获得RowID从INSERT ID
		g_eClient[client][iAnalyticsId] = SQL_GetInsertId(hndl);
	}
}

public void SQLCallback_InsertPlayerStatFailed(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);

	if(client < 1 || client > MaxClients || !IsClientInGame(client) || g_eClient[client][bIsBot])
		return;
	
	if(hndl == INVALID_HANDLE)
	{
		//输出错误日志
		LogToFileEx(g_szLogFile, "Confirm Insert Failed! Client:\"%N\" Error Happened: %s", error);
		char m_szQuery[256];
		Format(m_szQuery, 256, "SELECT * FROM `playertrack_analytics` WHERE (connect_time = %d AND ip = '%s' AND playerid = %d) order by id desc limit 1;", g_eClient[client][iConnectTime], g_eClient[client][szIP], g_eClient[client][iPlayerId]);
		MySQL_Query(g_eHandle[DB_Game], SQLCallback_InsertPlayerStatFailed, m_szQuery, GetClientUserId(client));
	}
	else
	{
		if(SQL_FetchRow(hndl))
			g_eClient[client][iAnalyticsId] = SQL_FetchInt(hndl, 0);
		else
			MySQL_Query(g_eHandle[DB_Game], SQLCallback_InsertPlayerStat, g_eClient[client][szInsertData], GetClientUserId(client));
	}
}

public void SQLCallback_GetSigninStat(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);

	if(client < 1 || client > MaxClients || !IsClientInGame(client) || g_eClient[client][bIsBot])
		return;
	
	if(hndl == INVALID_HANDLE)
	{
		tPrintToChat(client, "%s  %t", PLUGIN_PREFIX, "sign error");
		g_eClient[client][bLoginProc] = false;
		LogToFileEx(g_szLogFile, "Get SigninStat Failed client: %N error: %s", client, error);
		return;
	}

	if(SQL_FetchRow(hndl)) 
	{
		//Getting last login time
		g_eClient[client][iSignNum] = SQL_FetchInt(hndl, 0);
		g_eClient[client][iSignTime] = SQL_FetchInt(hndl, 1);

		//86400 = 24h
		if((GetTime()-g_eClient[client][iSignTime]) >= 86400) 
		{
			char m_szQuery[256];
			Format(m_szQuery, 256, "UPDATE playertrack_player SET signnumber = signnumber+1, signtime = '%d' WHERE id = '%d' ", GetTime(), g_eClient[client][iPlayerId]);
			MySQL_Query(g_eHandle[DB_Game], SQLCallback_SignCallback, m_szQuery, GetClientUserId(client));
		}
	}
}

public void SQLCallback_SignCallback(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(client < 1 || client > MaxClients || !IsClientInGame(client) || g_eClient[client][bIsBot])
		return;

	if(hndl == INVALID_HANDLE)
	{
		tPrintToChat(client, "%s  %t", PLUGIN_PREFIX, "sign error");
		g_eClient[client][bLoginProc] = false;
		LogToFileEx(g_szLogFile, "UPDATE Client Sign Failed! Client:%N Query:%s", client, error);
		return;
	}

	g_eClient[client][iSignNum]++;
	g_eClient[client][iSignTime] = GetTime();
	tPrintToChat(client, "%s  %t", PLUGIN_PREFIX, "sign successful", g_eClient[client][iSignNum]);
	g_eClient[client][bTwiceLogin] = true;
	g_eClient[client][bLoginProc] = false;
	OnClientSignSucessed(client);
}

public void SQLCallback_GetAdvData(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE)
		return;
	
	if(SQL_GetRowCount(hndl))
	{
		//RemoveADV();
		Handle kv = CreateKeyValues("ServerAdvertisement", "", "");
		char m_szPath[256];
		BuildPath(Path_SM, m_szPath, 256, "configs/ServerAdvertisement.cfg");
		FileToKeyValues(kv, m_szPath);
		KvDeleteKey(kv, "Messages");
		int Count = 0;
		while(SQL_FetchRow(hndl))
		{
			char m_szType[4], m_szText_EN[256], m_szText_CN[256], m_szCount[16];
			SQL_FetchString(hndl, 2, m_szType, 4);
			SQL_FetchString(hndl, 3, m_szText_EN, 256);  // 0=ID 1=SID 2=TYPE 3=EN 4=CN
			SQL_FetchString(hndl, 4, m_szText_CN, 256);
			IntToString(Count, m_szCount, 16);
			if(KvJumpToKey(kv, "Messages", true))
			{
				if(KvJumpToKey(kv, m_szCount, true))
				{
					Count++;
					KvSetString(kv, "default", m_szText_EN);
					KvSetString(kv, "trans", m_szText_CN);
					KvSetString(kv, "type", m_szType);
					KvRewind(kv);
				}
			}
		}
		KeyValuesToFile(kv, m_szPath);
		ServerCommand("sm_reloadsadvert");
		CloseHandle(kv);
	}
}

public void SQLCallback_NothingCallback(Handle owner, Handle hndl, const char[] error, int userid)
{
	if(hndl == INVALID_HANDLE)
	{
		int client = GetClientOfUserId(userid);
		LogToFileEx(g_szLogFile, "INSERT Failed: client:%N ERROR:%s", client, error);
		return;
	}
	
	int client = GetClientOfUserId(userid);
	g_eClient[client][bLoginProc] = false;
}

public void SQLCallback_SaveDatabase(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		char m_szQuery[512];
		ReadPackString(data, m_szQuery, 512);
		int database = ReadPackCell(data);
		ResetPack(data);
		LogToFileEx(g_szLogFile, "==========================================================");
		LogToFileEx(g_szLogFile, "Native SaveDatabase[%s].  Error: %s", database == 0 ? "csgo" : "discuz", error);
		LogToFileEx(g_szLogFile, "Query: %s", m_szQuery);
		LogToFileEx(g_szLogFile, "==========================================================");
		
		if(StrContains(error, "lost connection", false) != -1)
		{
			MySQL_Query(database == 0 ? g_eHandle[DB_Game] : g_eHandle[DB_Discuz], SQLCallback_NothingCallback, m_szQuery, data);
			return;
		}
	}
	CloseHandle(data);
}

public void SQLCallback_OnConnect(Handle owner, Handle hndl, const char[] error, int userid)
{
	if(hndl == INVALID_HANDLE)
	{
		LogToFileEx(g_szLogFile, "Delete on start Failed! Error:%s", error);
		return;
	}
}

public void SQLCallback_UpdateCP(Handle owner, Handle hndl, const char[] error, Handle pack)
{
	int Neptune = GetClientOfUserId(ReadPackCell(pack));
	int Noire = GetClientOfUserId(ReadPackCell(pack));
	CloseHandle(pack);

	if(hndl == INVALID_HANDLE)
	{
		if(Neptune && IsClientInGame(Neptune))
		{
			tPrintToChat(Neptune, "%s  %t:\x02 x03", PLUGIN_PREFIX, "system error");
			LogToFileEx(g_szLogFile, "UpdateCP %N error: %s", Neptune, error);
		}
		
		if(Noire && IsClientInGame(Noire))
		{
			tPrintToChat(Neptune, "%s  %t:\x02 x03", PLUGIN_PREFIX, "system error");
			LogToFileEx(g_szLogFile, "UpdateCP %N error: %s", Noire, error);
		}
		
		return;
	}
	
	if(Neptune && IsClientInGame(Neptune) && Noire && IsClientInGame(Noire))
	{
		g_eClient[Neptune][iCPId] = Noire;
		g_eClient[Neptune][iCPDate] = GetTime();
		g_eClient[Noire][iCPId] = Neptune;
		g_eClient[Noire][iCPDate] = GetTime();
		
		Call_StartForward(g_Forward[ClientMarried]);
		Call_PushCell(Neptune);
		Call_PushCell(Noire);
		Call_Finish();
		
		tPrintToChatAll("%s  %t", PLUGIN_PREFIX, "cp married", Neptune, Noire);
	}
	
	if(Neptune && IsClientInGame(Neptune) && (!Noire || !IsClientInGame(Noire)))
	{
		g_eClient[Neptune][iCPId] = -1;
		g_eClient[Neptune][iCPDate] = GetTime();
		
		tPrintToChat(Neptune, "%s  %t", PLUGIN_PREFIX, "cp married offline");
	}
	
	if(Noire && IsClientInGame(Noire) && (!Neptune || !IsClientInGame(Neptune)))
	{
		g_eClient[Noire][iCPId] = -1;
		g_eClient[Noire][iCPDate] = GetTime();
		
		tPrintToChat(Noire, "%s  %t", PLUGIN_PREFIX, "cp married offline");
	}
}

public void SQLCallback_CheckDivorce(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(client < 1 || client > MaxClients || !IsClientInGame(client) || g_eClient[client][bIsBot])
		return;
	
	if(hndl == INVALID_HANDLE)
	{
		tPrintToChat(client, "%s  %t:\x02 x04", PLUGIN_PREFIX, "system error");
		LogToFileEx(g_szLogFile, "CheckDivorce %N error: %s", client, error);
		return;
	}
	
	if(!SQL_FetchRow(hndl))
	{
		tPrintToChat(client, "%s  %t:\x02 x05", PLUGIN_PREFIX, "system error");
		return;
	}
	else
	{
		int m_iId = SQL_FetchInt(hndl, 0);
		char m_szName[64];
		SQL_FetchString(hndl, 1, m_szName, 64);
		ReplaceString(m_szName, 64, ";", "", false);
		ConfirmDivorce(client, m_iId, m_szName);
	}
}

public void SQLCallback_UpdateDivorce(Handle owner, Handle hndl, const char[] error, Handle pack)
{
	int client = GetClientOfUserId(ReadPackCell(pack));
	int m_iId = ReadPackCell(pack);
	char m_szName[64];
	ReadPackString(pack, m_szName, 64);
	CloseHandle(pack);
	
	if(client < 1 || client > MaxClients || !IsClientInGame(client) || g_eClient[client][bIsBot])
		return;
	
	if(hndl == INVALID_HANDLE)
	{
		tPrintToChat(client, "%s  %t:\x02 x06", PLUGIN_PREFIX, "system error");
		LogToFileEx(g_szLogFile, "UpdateDivorce %N error: %s", client, error);
		return;
	}

	int m_iPartner = FindClientByPlayerId(m_iId);

	tPrintToChatAll("%s  %t", PLUGIN_PREFIX, "cp divorce", client, m_szName, (GetTime()-g_eClient[client][iCPDate])/86400);

	if(m_iPartner > 0)
	{
		g_eClient[m_iPartner][iCPId] = -2;
		g_eClient[m_iPartner][iCPDate] = 0;
	}
	
	g_eClient[client][iCPId] = -2;
	g_eClient[client][iCPDate] = 0;
	
	Call_StartForward(g_Forward[ClientDivorce]);
	Call_PushCell(client);
	Call_PushCell(m_iPartner);
	Call_Finish();
}

public void SQLCallback_SaveTempLog(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		char m_szAuthId[32], m_szQuery[512], m_szIp[16], m_szFlag[32];
		ReadPackString(data, m_szQuery, 512);
		ReadPackString(data, m_szAuthId, 32);
		int m_iPlayerId = ReadPackCell(data);
		int m_iConnect = ReadPackCell(data);
		int m_iTrackId = ReadPackCell(data);
		ReadPackString(data, m_szIp, 32);
		int m_iLastTime = ReadPackCell(data);
		ReadPackString(data, m_szFlag, 32);

		LogToFileEx(g_szLogFile, " \n------------------------------------------------------------------------------\nAuthId: %s\nPlayerId: %d\nConnect: %d\nTrackId: %d\nIP: %s\nLastTime: %d\nFlag: %s\nQuery: %s\n------------------------------------------------------------------------------", m_szAuthId, m_iPlayerId, m_iConnect, m_iTrackId, m_szIp, m_iLastTime, m_szFlag, m_szQuery);
	}
}

public void SQLCallback_GiveAuth(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!client)
		return;
	
	if(hndl == INVALID_HANDLE)
	{
		LogToFileEx(g_szLogFile, "UPDATE auth Failed: client:%N ERROR:%s", client, error);
		tPrintToChat(client, "%s  %t:\x02 x99", PLUGIN_PREFIX, "system error");
		g_eClient[client][iGroupId] = 0;
		return;
	}

	tPrintToChatAll("%s  {blue}%N{green}%t", PLUGIN_PREFIX, client, "auth get new auth");
}