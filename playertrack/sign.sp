public void SetClientSignStat(int client)
{
	//初始化签到程序的Client状态
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

public Action Timer_AllowToLogin(Handle timer, int userid)
{
	//计时器满，允许签到
	int client = GetClientOfUserId(userid);

	if(!g_eClient[client][bTwiceLogin])
	{
		tPrintToChat(client, "%s  %T", PLUGIN_PREFIX, "sign allow sign", client);
		g_eClient[client][bAllowLogin] = true;
		g_eClient[client][hSignTimer] = INVALID_HANDLE;
	}
	else
	{
		g_eClient[client][bAllowLogin] = false;
		g_eClient[client][hSignTimer] = INVALID_HANDLE;
	}
	
	g_eClient[client][hSignTimer] = CreateTimer(30.0, Timer_NotifySign, GetClientUserId(client));
}

public Action Timer_NotifySign(Handle timer, int userid)
{
	//重复提示签到
	int client = GetClientOfUserId(userid);
	if(!g_eClient[client][bTwiceLogin])
	{
		tPrintToChat(client, "%s  %T", PLUGIN_PREFIX, "sign allow sign", client);
		g_eClient[client][hSignTimer] = INVALID_HANDLE;
	}
	else
	{
		g_eClient[client][hSignTimer] = CreateTimer(30.0, Timer_NotifySign, GetClientUserId(client));
	}
}

public void ProcessingLogin(int client) 
{
	if(g_eClient[client][bTwiceLogin])
	{
		tPrintToChat(client, "%s  %T", PLUGIN_PREFIX, "sign twice sign", client);
		return;
	}
	
	if(!g_eClient[client][bAllowLogin]) 
	{
		int m_iTime = (600 - (GetTime() - g_eClient[client][iConnectTime]));
		tPrintToChat(client, "%s  %T", PLUGIN_PREFIX, "sign no time", client, m_iTime);
		return;
	}
	
	if(g_eClient[client][bLoginProc])
	{
		tPrintToChat(client, "%s  %T", PLUGIN_PREFIX, "sign in processing", client);
		return;
	}

	char m_szQuery[500];
	Format(m_szQuery, 256, "SELECT signnumber,signtime FROM playertrack_player WHERE id = %d ", g_eClient[client][iPlayerId]);
	MySQL_Query(g_eHandle[DB_Game], SQLCallback_GetSigninStat, m_szQuery, GetClientUserId(client));
	
	g_eClient[client][bLoginProc] = true;
}