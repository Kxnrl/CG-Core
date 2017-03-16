public Action Timer_NotifySign(Handle timer, int client)
{
	if(!IsClientInGame(client) || g_eClient[client][bSignIn] || g_eClient[client][iDaily] < 900)
	{
		g_eClient[client][hSignTimer] = INVALID_HANDLE;
		return Plugin_Stop;
	}

	tPrintToChat(client, "%s  %T", PLUGIN_PREFIX, "sign allow sign", client);
	
	return Plugin_Continue;
}

public void ProcessingLogin(int client) 
{
	if(g_eClient[client][bSignIn])
	{
		tPrintToChat(client, "%s  %T", PLUGIN_PREFIX, "sign twice sign", client);
		return;
	}

	if(g_eClient[client][iDaily] < 900) 
	{
		tPrintToChat(client, "%s  %T", PLUGIN_PREFIX, "sign no time", client, 900 - g_eClient[client][iDaily]);
		return;
	}

	char m_szQuery[500];
	Format(m_szQuery, 256, "SELECT signnumber,signtime FROM playertrack_player WHERE id = %d ", g_eClient[client][iPlayerId]);
	MySQL_Query(g_eHandle[DB_Game], SQLCallback_GetSigninStat, m_szQuery, GetClientUserId(client));

	g_eClient[client][bSignIn] = true;
}