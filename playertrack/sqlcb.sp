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
		
		LogToFileEx(LogFile, "Connection to SQL database 'csgo' has failed, Try %d, Reason: %s", g_iReconnect_csgo, error);
		
		if(g_iReconnect_csgo >= 100) 
		{
			SetFailState("PLUGIN STOPPED - Reason: can not connect to database 'csgo', retry 100! - PLUGIN STOPPED");
			LogToFileEx(LogFile, " Too much errors. Restart your server for a new try. ");
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
		
		LogToFileEx(LogFile, "Connection to SQL database 'discuz' has failed, Try %d, Reason: %s", g_iReconnect_discuz, error);
		
		if(g_iReconnect_discuz >= 100) 
		{
			SetFailState("PLUGIN STOPPED - Reason: can not connect to database 'discuz', retry 100! - PLUGIN STOPPED");
			LogToFileEx(LogFile, " Too much errors. Restart your server for a new try. ");
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
		LogToFileEx(LogFile, "Query server ID Failed! Reason: %s", error);
		return;
	}
	
	//执行SQL_FetchRow
	if(SQL_FetchRow(hndl))
	{
		//ServerID获取
		g_iServerId = SQL_FetchInt(hndl, 0);
		SQL_FetchString(hndl, 1, g_szHostName, 256);
		SetConVarString(FindConVar("hostname"), g_szHostName, false, false);
		LogToFileEx(LogFile, "ServerID is \"%d\"  ServerName is \"%s\" ", g_iServerId, g_szHostName);
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
		LogToFileEx(LogFile, "Not Found this server in playertrack_server , now Register this!  %s", m_szQuery);
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
		LogToFileEx(LogFile, "INSERT server ID Failed! Reason: %s", error);
		return;
	}
	
	//从INSERT ID获得ServerID 变量g_ServerID
	g_iServerId = SQL_GetInsertId(hndl);
}

public void SQLCallback_GetShare(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		char m_szQuery[256];
		Format(m_szQuery, 256, "SELECT faith,SUM(share) FROM playertrack_player GROUP BY faith");
		SQL_TQuery(g_hDB_csgo, SQLCallback_GetShare, m_szQuery);
		LogToFileEx(LogFile, "Get Share Failed! Reason: %s", error);
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
public void SQLCallback_GetClientStat(Handle owner, Handle hndl, const char[] error, int userid)
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
		LogToFileEx(LogFile, "Query Client Stats Failed! Client:\"%N\" \nError Happen: %s", client, error);
		char m_szAuth[32], m_szQuery[512];
		GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
		Format(m_szQuery, 512, "SELECT id, onlines, number, faith, share, buff, signature, groupid, groupname, exp, level, temp, notice, reqid, reqterm, reqrate, signnumber, signtime, lilyid, lilyrank, lilyexp, lilydate FROM playertrack_player WHERE steamid = '%s' ORDER BY id ASC LIMIT 1;", m_szAuth);
		SQL_TQuery(g_hDB_csgo, SQLCallback_GetClientStat, m_szQuery, g_eClient[client][iUserId], DBPrio_High);
		return;
	}

	//执行SQL_FetchRow
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		//客户端数据读取 ID|在线时长|连线次数|签名
		g_eClient[client][iPlayerId] = SQL_FetchInt(hndl, 0);
		g_eClient[client][iOnline] = SQL_FetchInt(hndl, 1);
		g_eClient[client][iNumber] = SQL_FetchInt(hndl, 2);
		g_eClient[client][iFaith] = SQL_FetchInt(hndl, 3);
		g_eClient[client][iShare] = SQL_FetchInt(hndl, 4);
		g_eClient[client][iBuff] = SQL_FetchInt(hndl, 5);
		SQL_FetchString(hndl, 6, g_eClient[client][szSignature], 256);
		g_eClient[client][iGroupId] = SQL_FetchInt(hndl, 7);
		SQL_FetchString(hndl, 8, g_eClient[client][szGroupName], 256);
		g_eClient[client][iExp] = SQL_FetchInt(hndl, 9);
		g_eClient[client][iLevel] = SQL_FetchInt(hndl, 10);
		g_eClient[client][iTemp] = SQL_FetchInt(hndl, 11);
		//g_eClient[client][bPrint] = SQL_FetchInt(hndl, 12) > g_iLatestData ? true : false;
		g_eClient[client][iReqId] = SQL_FetchInt(hndl, 13);
		g_eClient[client][iReqTerm] = SQL_FetchInt(hndl, 14);
		g_eClient[client][iReqRate] = SQL_FetchInt(hndl, 15);
		g_eClient[client][iSignNum] = SQL_FetchInt(hndl, 16);
		g_eClient[client][iSignTime] = SQL_FetchInt(hndl, 17);
		InitializeLily(client, SQL_FetchInt(hndl, 18), SQL_FetchInt(hndl, 19), SQL_FetchInt(hndl, 20), SQL_FetchInt(hndl, 21));
		
		g_eClient[client][bLoaded] = true;

		char m_szAuth[32], m_szQuery[512];
		GetClientAuthId(client, AuthId_SteamID64, m_szAuth, 32, true);
		
		Format(m_szQuery, 512, "SELECT m.uid, m.username FROM dz_steam_users AS s LEFT JOIN dz_common_member m ON s.uid = m.uid WHERE s.steamID64 = '%s' LIMIT 1", m_szAuth);
		SQL_TQuery(g_hDB_discuz, SQLCallback_GetClientDiscuzName, m_szQuery, g_eClient[client][iUserId]);
		
		if(g_eClient[client][iFaith] == 0 && g_iServerId != 23 && g_iServerId != 24 && g_iServerId != 11 && g_iServerId != 12 && g_iServerId != 13)
		{
			ShowFaithFirstMenuToClient(client);
		}

		SetClientSignStat(client);
		OnClientAuthLoaded(client);
	}
	else
	{
		//如果查不到数据 INSERT为新的玩家 记录到日志文件
		//获得客户端数据 steamid|名字|IP|权限
		char m_szAuth[32], username[128], EscapeName[256], m_szQuery[512];
		GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
		GetClientName(client, username, 128);
		SQL_EscapeString(g_hDB_csgo, username, EscapeName, 256);
		Format(m_szQuery, 512, "INSERT INTO playertrack_player (name, steamid, onlines, lastip, firsttime, lasttime, os, flags, number, signature) VALUES ('%s', '%s', '0', '%s', '%d', '0', 'unknow', 'unknow', '0', DEFAULT)", EscapeName, m_szAuth, g_eClient[client][szIP], g_eClient[client][iConnectTime]);
		SQL_TQuery(g_hDB_csgo, SQLCallback_InsertClientStat, m_szQuery, g_eClient[client][iUserId]);
	}
}

public void SQLCallback_GetClientDiscuzName(Handle owner, Handle hndl, const char[] error, int userid)
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
		LogToFileEx(LogFile, "Check '%N' VIP Error happened: %s", client, error);
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

public void SQLCallback_CheckVIP(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(client < 1 || client > MaxClients || !IsClientConnected(client))
		return;
	
	g_eClient[client][iUserId] = userid;

	if(hndl == INVALID_HANDLE)
	{
		RunAdminCacheChecks(client);
		VipChecked(client);
		LogToFileEx(LogFile, "Check '%N' VIP Error happened: %s", client, error);
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

public void SQLCallback_InsertClientStat(Handle owner, Handle hndl, const char[] error, int userid)
{
	//定义客户
	int client = GetClientOfUserId(userid);

	if(!client)
		return;

	if(hndl == INVALID_HANDLE)
	{
		//记录客户信息 写入到错误日志
		LogToFileEx(LogFile, "INSERT playertrack_player Failed! Client:\"%N\" \nError Happen: %s", client, error);
		
		//重试检查  辣鸡阿里云RDS
		char m_szAuth[32], m_szQuery[512];
		GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
		Format(m_szQuery, 512, "SELECT id, onlines, number, faith, share, buff, signature, groupid, groupname, exp, level, temp, notice, reqid, reqterm, reqrate, signnumber, signtime, lilyid, lilyrank, lilyexp, lilydate FROM playertrack_player WHERE steamid = '%s' ORDER BY id ASC LIMIT 1;", m_szAuth);
		SQL_TQuery(g_hDB_csgo, SQLCallback_GetClientStat, m_szQuery, g_eClient[client][iUserId], DBPrio_High);
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
			g_eClient[client][iDataRetry]++;
			SQL_TQuery(g_hDB_csgo, SQLCallback_SaveClientStat, g_eClient[client][szUpdateData], g_eClient[client][iUserId]);
			LogToFileEx(LogFile, "UPDATE Client Data Failed!   Times:%d Player:\"%N\" \nError Happen:%s", g_eClient[client][iDataRetry], client, error);
		}
		else
		{
			LogToFileEx(LogFile, "UPDATE Client Data Failed!   Times:(Times out) Player:\"%N\" \nError Happen:%s", client, error);
			g_eClient[client][iDataRetry] = 0;
		}
	}
}

public void SQLCallback_InsertPlayerStat(Handle owner, Handle hndl, const char[] error, int userid)
{
	//定义客户
	int client = GetClientOfUserId(userid);

	if(client == 0)
		return;

	//SQL如果操作失败
	if(hndl == INVALID_HANDLE)
	{
		//记录客户信息 写入到错误日志
		LogToFileEx(LogFile, "INSERT playertrack_analytics Failed!   Player:\"%N\" \nError Happen:%s", client, error);
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

public void SQLCallback_InsertPlayerStatFailed(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);

	if(client == 0)
		return;
	
	if(hndl == INVALID_HANDLE)
	{
		//输出错误日志
		LogToFileEx(LogFile, "Confirm Insert Failed! Client:\"%N\" \nError Happen: %s", error);
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

public void SQLCallback_GetSigninStat(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);

	if(!client || !IsClientInGame(client))
		return;
	
	if(hndl == INVALID_HANDLE)
	{
		PrintToChat(client, "%s \x02未知错误,请重试!", PLUGIN_PREFIX);
		g_eClient[client][LoginProcess] = false;
		LogToFileEx(LogFile, "Get SigninStat Failed client: %N error: %s", client, error);
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
			SQL_TQuery(g_hDB_csgo, SQLCallback_SignCallback, m_szQuery, GetClientUserId(client));
		}
	}
}

public void SQLCallback_SignCallback(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);

	if(hndl == INVALID_HANDLE)
	{
		PrintToChat(client, "%s \x02未知错误!", PLUGIN_PREFIX);
		g_eClient[client][LoginProcess] = false;
		LogToFileEx(LogFile, "UPDATE Client Sign Failed! Client:%N Query:%s", client, error);
		return;
	}

	g_eClient[client][iSignNum]++;
	g_eClient[client][iSignTime] = GetTime();
	PrintToChat(client, "%s \x01签到成功,你已累计签到\x0C%i\x01天!", PLUGIN_PREFIX, g_eClient[client][iSignNum]);
	g_eClient[client][bTwiceLogin] = true;
	g_eClient[client][LoginProcess] = false;
	OnClientSignSucessed(client);
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
			//LogToFileEx(LogFile, "Set New Advertisement");
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
						//LogToFileEx(LogFile, "New Adv: \"%s\"   \"%s\" ", sCount, sText);
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

public void SQLCallback_NothingCallback(Handle owner, Handle hndl, const char[] error, int userid)
{
	if(hndl == INVALID_HANDLE)
	{
		int client = GetClientOfUserId(userid);
		LogToFileEx(LogFile, "INSERT Failed: client:%N ERROR:%s", client, error);
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
		LogToFileEx(LogFile, "==========================================================");
		LogToFileEx(LogFile, "Save \"%N\" Admin stats Failed: %s", client, error);
		LogToFileEx(LogFile, " \"%N\" AdminId: %d  Connect: %d  Disconnect: %d  Duration: %d", client, g_eClient[client][iConnectTime], GetTime(), GetTime()-g_eClient[client][iConnectTime]);
		LogToFileEx(LogFile, "==========================================================");
	}
}

public void SQLCallback_SaveDatabase(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		char m_szQuery[512];
		ReadPackString(data, m_szQuery, 512);
		LogToFileEx(LogFile, "==========================================================");
		LogToFileEx(LogFile, "Native SaveDatabase.  Error: %s", error);
		LogToFileEx(LogFile, "Query: %s", m_szQuery);
		LogToFileEx(LogFile, "==========================================================");
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
		LogToFileEx(LogFile, "Save Client Share Failed!  Error: %s", error);
		return;
	}
}

public void SQLCallback_FaithShareRank(Handle owner, Handle hndl, const char[] error, int userid)
{
	if(hndl == INVALID_HANDLE)
	{
		LogToFileEx(LogFile, "Get Faith Share Rank Failed!  Error: %s", error);
		return;
	}
	
	int client = GetClientOfUserId(userid);
	if(!client || !IsClientInGame(client))
		return;
	
	int m_iIndex, ishare;
	char m_szName[128];
	
	if(SQL_GetRowCount(hndl))
	{
		Handle hPack = CreateDataPack();
		WritePackCell(hPack, m_iIndex);
		while(SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, m_szName, 128);
			ishare = SQL_FetchInt(hndl, 1);

			WritePackString(hPack, m_szName);
			WritePackCell(hPack, ishare);

			m_iIndex++;
		}

		ResetPack(hPack);
		WritePackCell(hPack, m_iIndex);
		ShareRankToMenu(client, hPack);
	}
}

public void SQLCallback_GetGroupId(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);

	if(!client)
		return;

	if(hndl == INVALID_HANDLE)
	{
		LogToFileEx(LogFile, "Query player Data Failed! Error:%s", error);
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

public void SQLCallback_SetTemp(Handle owner, Handle hndl, const char[] error, int userid)
{
	if(hndl == INVALID_HANDLE)
	{
		int client = GetClientOfUserId(userid);
		LogToFileEx(LogFile, "set temp player Failed! Error:%s", error);
		PrintToChat(client, "%s \x02添加临时认证失败,SQL错误!", PLUGIN_PREFIX);
		return;
	}
}

public void SQLCallback_DeleteTemp(Handle owner, Handle hndl, const char[] error, int userid)
{ 
	int client = GetClientOfUserId(userid);
	
	if(hndl == INVALID_HANDLE)
	{
		LogToFileEx(LogFile, "DELETE Tmp Data Failed! Client:%N  Target:%N", client, g_eAdmin[iTarget]);
		PrintToChat(client, "%s 解除临时认证失败...", PLUGIN_PREFIX);
		return;
	}
	
	int target = g_eAdmin[iTarget]; 
	LoadAuthorized(target);
}

public void SQLCallback_OnConnect(Handle owner, Handle hndl, const char[] error, int userid)
{
	if(hndl == INVALID_HANDLE)
	{
		LogToFileEx(LogFile, "Delete on start Failed! Error:%s", error);
		return;
	}
}

public void SQLCallback_ResetReq(Handle owner, Handle hndl, const char[] error, int userid)
{ 
	int client = GetClientOfUserId(userid);
	
	if(hndl == INVALID_HANDLE)
		LogToFileEx(LogFile, "Reset Client Req Failed! [%N]  %s", client, error);
	else
	{
		if(client && IsClientInGame(client))
			PrintToConsole(client, "[Planeptune]  任务进度已重置!");
	}
}

public void SQLCallback_SaveReq(Handle owner, Handle hndl, const char[] error, int userid)
{ 
	int client = GetClientOfUserId(userid);
	
	if(hndl == INVALID_HANDLE)
		LogToFileEx(LogFile, "Save Client Req Failed! [%N]  %s", client, error);
	else
	{
		if(client && IsClientInGame(client))
			PrintToConsole(client, "[Planeptune]  任务进度已保存!");
	}
}

public void SQLCallback_InsertGuild(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(hndl == INVALID_HANDLE)
		LogToFileEx(LogFile, "Insert Client Req Conpelete Failed! [%N](%d)  %s", client, g_eClient[client][iReqId], error);
	else
	{
		if(client && IsClientInGame(client))
			PrintToConsole(client, "[Planeptune]  任务已添加!");
	}
}

public void SQLCallback_UpdateLily(Handle owner, Handle hndl, const char[] error, Handle pack)
{
	int Neptune = GetClientOfUserId(ReadPackCell(pack));
	int Noire = GetClientOfUserId(ReadPackCell(pack));
	CloseHandle(pack);

	if(hndl == INVALID_HANDLE)
	{
		if(Neptune && IsClientInGame(Neptune))
		{
			PrintToChat(Neptune, "%s  系统中闪光弹了,请重试[错误x03]", PLUGIN_PREFIX);
			LogToFileEx(LogFile, "UpdateLily %N error: %s", Neptune, error);
		}
		
		if(Noire && IsClientInGame(Noire))
		{
			PrintToChat(Noire, "%s  系统中闪光弹了,请重试[错误x03]", PLUGIN_PREFIX);
			LogToFileEx(LogFile, "UpdateLily %N error: %s", Noire, error);
		}
		
		return;
	}
	
	if(Neptune && IsClientInGame(Neptune) && Noire && IsClientInGame(Noire))
	{
		g_eClient[Neptune][iLilyId] = Noire;
		g_eClient[Noire][iLilyId] = Neptune;
		
		g_eClient[Neptune][iLilyRank] = 0;
		g_eClient[Neptune][iLilyExp] = 0;
		g_eClient[Neptune][iLilyDate] = GetTime();
		
		g_eClient[Noire][iLilyRank] = 0;
		g_eClient[Noire][iLilyExp] = 0;
		g_eClient[Noire][iLilyDate] = GetTime();
		
		Call_StartForward(g_fwdOnLilyCouple);
		Call_PushCell(Neptune);
		Call_PushCell(Noire);
		Call_Finish();
		
		PrintToChatAll("%s  \x0F恭喜\x0E%N\x0F和\x0E%N\x0F结成Lily.", PLUGIN_PREFIX, Neptune, Noire);
	}
	
	if(Neptune && IsClientInGame(Neptune) && (!Noire || !IsClientInGame(Noire)))
	{
		g_eClient[Neptune][iLilyId] = -1;
		g_eClient[Neptune][iLilyRank] = 0;
		g_eClient[Neptune][iLilyExp] = 0;
		g_eClient[Neptune][iLilyDate] = GetTime();
		
		PrintToChat(Neptune, "%s  系统已保存你们的数据,但是你老婆当前离线,你不能享受\x0ENeptune\x01的新婚祝福", PLUGIN_PREFIX);
	}
	
	if(Noire && IsClientInGame(Noire) && (!Neptune || !IsClientInGame(Neptune)))
	{
		g_eClient[Noire][iLilyId] = -1;
		g_eClient[Noire][iLilyRank] = 0;
		g_eClient[Noire][iLilyExp] = 0;
		g_eClient[Noire][iLilyDate] = GetTime();
		
		PrintToChat(Noire, "%s  系统已保存你们的数据,但是你老婆当前离线,你不能享受\x0ENeptune\x01的新婚祝福", PLUGIN_PREFIX);
	}
}

public void SQLCallback_CheckDivorce(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!client || !IsClientInGame(client))
		return;
	
	if(hndl == INVALID_HANDLE)
	{
		PrintToChat(client, "%s  服务器中了闪光弹,请稍候再试[错误x04]", PLUGIN_PREFIX);
		LogToFileEx(LogFile, "CheckDivorce %N error: %s", client, error);
		return;
	}
	
	if(!SQL_FetchRow(hndl))
	{
		PrintToChat(client, "%s  服务器中了闪光弹,请稍候再试[错误x05]", PLUGIN_PREFIX);
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
	
	if(!client || !IsClientInGame(client))
		return;
	
	if(hndl == INVALID_HANDLE)
	{
		PrintToChat(client, "%s  服务器中了闪光弹,请稍候再试[错误x06]", PLUGIN_PREFIX);
		LogToFileEx(LogFile, "UpdateDivorce %N error: %s", client, error);
		return;
	}

	int m_iPartner = FindClientByPlayerId(m_iId);

	PrintToChatAll("%s  \x0F%N\x05解除了和\x0F%s\x05的Lily,他们的关系维持了\x07%d\x05天", PLUGIN_PREFIX, client, m_szName, (GetTime()-g_eClient[client][iLilyDate])/86400);

	if(m_iPartner > 0)
	{
		g_eClient[m_iPartner][iLilyId] = -2;
		g_eClient[m_iPartner][iLilyRank] = 0;
		g_eClient[m_iPartner][iLilyExp] = 0;
		g_eClient[m_iPartner][iLilyDate] = 0;
	}
	
	g_eClient[client][iLilyId] = -2;
	g_eClient[client][iLilyRank] = 0;
	g_eClient[client][iLilyExp] = 0;
	g_eClient[client][iLilyDate] = 0;
	
	Call_StartForward(g_fwdOnLilyDivorce);
	Call_PushCell(client);
	Call_PushCell(m_iPartner);
	Call_Finish();
}

public void SQLCallback_LilyRank(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!client || !IsClientInGame(client))
		return;
	
	if(hndl == INVALID_HANDLE)
	{
		PrintToChat(client, "%s  服务器中了闪光弹,请稍候再试[错误x07]", PLUGIN_PREFIX);
		LogToFileEx(LogFile, "LilyRank %N error: %s", client, error);
		return;
	}
	
	int m_iIndex, m_iRank;
	char m_szName[128];
	if(SQL_GetRowCount(hndl))
	{
		Handle hPack = CreateDataPack();
		WritePackCell(hPack, m_iIndex);

		while(SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, m_szName, 128);
			m_iRank = SQL_FetchInt(hndl, 1);

			WritePackString(hPack, m_szName);
			WritePackCell(hPack, m_iRank);

			m_iIndex++;
		}

		ResetPack(hPack);
		WritePackCell(hPack, m_iIndex);
		LilyRankToMenu(client, hPack);
	}
}