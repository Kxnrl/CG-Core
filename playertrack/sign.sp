public void SetClientSignStat(int client)
{
	if(g_eClient[client][iLastSignTime] == 0)
	{
		g_eClient[client][hSignTimer] = CreateTimer(600.0, AllowToLogin, GetClientUserId(client));
		g_eClient[client][bTwiceLogin] = false;
	}
	else
	{
		g_eClient[client][bTwiceLogin] = true;
		g_eClient[client][bAllowLogin] = false;
	}
}

public Action AllowToLogin(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);

	if (IsClientInGame(client) && !IsFakeClient(client) && !g_eClient[client][bTwiceLogin])
	{
		PrintToChat(client, "%s \x04你现在可以签到了,按Y输入\x07!sign\x04来签到!", PLUGIN_PREFIX_SIGN);
		g_eClient[client][bAllowLogin] = true;
		g_eClient[client][hSignTimer] = INVALID_HANDLE;
	}
	else
	{
		g_eClient[client][bAllowLogin] = false;
		g_eClient[client][hSignTimer] = INVALID_HANDLE;
	}
	
	g_eClient[client][hSignTimer] = INVALID_HANDLE;
}

public Action Command_Login(int client, int args) 
{
	if(g_eClient[client][bTwiceLogin])
	{
		PrintToChat(client, "%s \x01每天只能签到1次!", PLUGIN_PREFIX_SIGN);
		return Plugin_Handled;
	}
	
	if(!g_eClient[client][bAllowLogin]) 
	{
		int m_iTime = (600 - (GetTime() - g_eClient[client][iConnectTime]));
		PrintToChat(client, "%s \x01你还需要在线\x04%d\x01秒才能签到!", PLUGIN_PREFIX_SIGN, m_iTime);
		return Plugin_Handled;
	}
	
	if(g_eClient[client][LoginProcess])
	{
		PrintToChat(client, "%s \x01正在执行签到查询!", PLUGIN_PREFIX_SIGN);
		return Plugin_Handled;
	}

	//拿客户端数据
	char steamid[32];
	GetClientAuthId(client, AuthId_Steam2, steamid, 32, true);

	char m_szQuery[500];
	Format(m_szQuery, 256, "SELECT timeofsignin,unixtimestamp FROM playertrack_sign WHERE steamid = '%s' ", steamid);
	SQL_TQuery(g_hDB_csgo, SQLCallback_GetSigninStat, m_szQuery, g_eClient[client][iUserId]);
	
	g_eClient[client][LoginProcess] = true;
	
	return Plugin_Handled;
}
