public void SetClientSignStat(int client)
{
	if(g_eClient[client][iSignTime] == 0)
	{
		g_eClient[client][hSignTimer] = CreateTimer(600.0, Timer_AllowToLogin, GetClientUserId(client));
		g_eClient[client][bTwiceLogin] = false;
	}
	else
	{
		g_eClient[client][bTwiceLogin] = true;
		g_eClient[client][bAllowLogin] = false;
	}
}

public Action Timer_AllowToLogin(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);

	if (IsClientInGame(client) && !IsFakeClient(client) && !g_eClient[client][bTwiceLogin])
	{
		PrintToChat(client, "%s \x04你现在可以签到了,按Y输入\x07!sign\x04来签到!", PLUGIN_PREFIX);
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
		PrintToChat(client, "%s \x01每天只能签到1次!", PLUGIN_PREFIX);
		return Plugin_Handled;
	}
	
	if(!g_eClient[client][bAllowLogin]) 
	{
		int m_iTime = (600 - (GetTime() - g_eClient[client][iConnectTime]));
		PrintToChat(client, "%s \x01你还需要在线\x04%d\x01秒才能签到!", PLUGIN_PREFIX, m_iTime);
		return Plugin_Handled;
	}
	
	if(g_eClient[client][LoginProcess])
	{
		PrintToChat(client, "%s \x01正在执行签到查询!", PLUGIN_PREFIX);
		return Plugin_Handled;
	}

	char m_szQuery[500];
	Format(m_szQuery, 256, "SELECT signnumber,signtime FROM playertrack_player WHERE id = %d ", g_eClient[client][iPlayerId]);
	SQL_TQuery(g_hDB_csgo, SQLCallback_GetSigninStat, m_szQuery, g_eClient[client][iUserId]);
	
	g_eClient[client][LoginProcess] = true;
	
	return Plugin_Handled;
}
