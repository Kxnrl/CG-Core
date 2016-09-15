public Action Timer_Notice(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!client)
		return Plugin_Stop;
	
	if(!IsClientInGame(client))
		return Plugin_Stop;

	if(g_iServerId == 23 || g_iServerId == 24 || g_iServerId == 11 || g_iServerId == 12 || g_iServerId == 13)
		return Plugin_Stop;
	
	if(g_eClient[client][bPrint])
		return Plugin_Stop;

	if(GetClientTeam(client) < 2)
		return Plugin_Continue;

	FakeClientCommandEx(client, "sm_notice");

	return Plugin_Stop;
}

void ShowPanelToClient(int client)
{
	g_eClient[client][bPrint] = true;
	PrintToChat(client, "[\x0EPlaneptune\x01]   输入\x07!notice\x01可以重新打开公告板,完全阅读后将不再提示");
	BuiltPanelToClient(client);
}

void BuiltPanelToClient(int client)
{
	if(!IsValidClient(client, true))
		return;
	
	Handle menu = CreateMenu(MenuHandler_Panel);
	char szItem[256];
	Format(szItem, 256, "尊敬的[%s]\n　", g_eClient[client][szAdminFlags]);
	SetMenuTitle(menu, szItem);

	if(CG_GetOnlines(client) > 3600)
		AddMenuItem(menu, "", "欢迎您回到Planeptune大地", ITEMDRAW_DISABLED);
	else
		AddMenuItem(menu, "", "欢迎您来到Planeptune大地", ITEMDRAW_DISABLED);
	
	AddMenuItem(menu, "", "在紫色大地上需要你遵守CG玩家守则", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "", "", ITEMDRAW_SPACER);

	Format(szItem, 256, "查看全服[%s]", g_szGlobal[0]);
	AddMenuItem(menu, "public", szItem);
	
	if(!StrEqual(g_szServer[0], "空"))
	{
		Format(szItem, 256, "查看本服[%s]\n　", g_szServer[0]);
		AddMenuItem(menu, "update", szItem);
	}
	else
	{
		Format(szItem, 256, " 当前没有本服更新说明\n　");
		AddMenuItem(menu, "update", szItem, ITEMDRAW_DISABLED);
	}
	
	AddMenuItem(menu, "exit", "关闭公告板");

	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 0);
}

public int MenuHandler_Panel(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		if(StrEqual(info, "public"))
		{
			ShowNoticePadToClient(client, true);
		}
		else if(StrEqual(info, "update"))
		{
			ShowNoticePadToClient(client, false);
		}
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if(action == MenuAction_Cancel)
	{
		BuiltPanelToClient(client);
	}
}

void ShowNoticePadToClient(int client, bool global)
{
	Handle menu = CreateMenu(MenuHandler_NoticePad);
	char szItem[256];
	Format(szItem, 256, "[Planeptune]  全服 %s \n　", global ? g_szGlobal[0] : g_szServer[0]);
	SetMenuTitle(menu, szItem);
	
	Format(szItem, 256, "%s", global ? g_szGlobal[1] : g_szServer[1]);
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "%s", global ? g_szGlobal[2] : g_szServer[2]);
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "%s", global ? g_szGlobal[3] : g_szServer[3]);
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "%s", global ? g_szGlobal[4] : g_szServer[4]);
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "%s\n　", global ? g_szGlobal[5] : g_szServer[5]);
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "下次更新维护前不再提示");
	AddMenuItem(menu, "skip", szItem);

	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 0);
}

public int MenuHandler_NoticePad(Handle menu, MenuAction action, int client, int itemNum)
{
	if(action == MenuAction_Select || action == MenuAction_Cancel)
	{
		BuiltPanelToClient(client);
		SetClientViewNotice(client);
	}
}

void SetClientViewNotice(int client)
{
	if(!IsValidClient(client))
		return;
	
	if(!g_eClient[client][bPrint])
		return;
	
	char m_szQuery[256];
	Format(m_szQuery, 256, "UPDATE `playertrack_player` SET notice = %d WHERE id = %d", GetTime(), g_eClient[client][iPlayerId]);
	SQL_TQuery(g_hDB_csgo, SQLCallback_NothingCallback, m_szQuery, GetClientUserId(client));

	g_eClient[client][bPrint] = false;
}