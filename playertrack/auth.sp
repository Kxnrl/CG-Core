public void CheckClientAuthTerm(int client, int AuthId)
{
	if(1 < AuthId < 100 && !FindPluginByFile("zombiereloaded.smx"))
	{
		tPrintToChat(client, "%s  请到[僵尸逃跑]服务器中申请此认证", PLUGIN_PREFIX);
		return;
	}
	
	if(100 < AuthId < 200 && !FindPluginByFile("ct.smx"))
	{
		tPrintToChat(client, "%s  请到[匪镇谍影]服务器中申请此认证", PLUGIN_PREFIX);
		return;
	}
	
	if(200 < AuthId < 300 && !FindPluginByFile("mg_stats.smx"))
	{
		tPrintToChat(client, "%s  请到[娱乐休闲]服务器中申请此认证", PLUGIN_PREFIX);
		return;
	}
	
	if(300 < AuthId < 400 && !FindPluginByFile("public_ext.smx"))
	{
		tPrintToChat(client, "%s  请到[混战休闲]服务器中申请此认证", PLUGIN_PREFIX);
		return;
	}
	
	tPrintToChat(client, "%s  {blue}%t", PLUGIN_PREFIX, "querying");
	
	if(OnCheckAuthTerm(client, AuthId))
	{
		g_eClient[client][iGroupId] = AuthId;
		char m_szQuery[256], m_szAuthId[32];
		GetClientAuthId(client, AuthId_Steam2, m_szAuthId, 32, true);
		Format(m_szQuery, 256, "UPDATE `playertrack_player` SET `groupid` = '%d' WHERE `id` = '%d' and `steamid` = '%s';", AuthId, g_eClient[client][iPlayerId], m_szAuthId);
		MySQL_Query(g_hDB_csgo, SQLCallback_GiveAuth, m_szQuery, GetClientUserId(client));
		tPrintToChat(client, "%s  {blue}正在同步数据库...", PLUGIN_PREFIX);
	}
	else
	{
		tPrintToChat(client, "%s  {lightred}%t", PLUGIN_PREFIX, "auth not enough req");
	}
}