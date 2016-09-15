void InitializeLily(int client, int LilyId, int LilyRank, int LilyExp, int LilyDate)
{
	if(LilyId < 1)
	{
		g_eClient[client][iLilyId] = -2;
		g_eClient[client][iLilyRank] = 0;
		g_eClient[client][iLilyExp] = 0;
		g_eClient[client][iLilyDate] = 0;
	}
	else
	{
		int m_iPartner = FindClientByPlayerId(LilyId);
		g_eClient[client][iLilyId] = m_iPartner;
		g_eClient[client][iLilyRank] = LilyRank;
		g_eClient[client][iLilyExp] = LilyExp;
		g_eClient[client][iLilyDate] = LilyDate;
		
		if(1 <= m_iPartner <= MaxClients)
		{
			g_eClient[m_iPartner][iLilyId] = client;
			SyncLilyData(client);
		}
	}
}

void CheckingLily(int Neptune)
{
	int Noire = g_eClient[Neptune][iLilyId];
	
	if(Noire < 1)
		return;

	g_eClient[Noire][iLilyId] = -1;
}

bool SyncLilyData(int Neptune)
{
	int Noire = g_eClient[Neptune][iLilyId];

	if(Noire < 1)
		return false;

	if(g_eClient[Neptune][iLilyRank] != g_eClient[Noire][iLilyRank])
	{
		if(g_eClient[Neptune][iLilyRank] < g_eClient[Noire][iLilyRank])
			g_eClient[Neptune][iLilyRank] = g_eClient[Noire][iLilyRank];
		else
			g_eClient[Noire][iLilyRank] = g_eClient[Neptune][iLilyRank];
		
		char m_szQuery[256];
		Format(m_szQuery, 256, "UPDATE `playertrack_player` SET lilyrank = %d where id = %d or id = %d", g_eClient[Neptune][iLilyRank], Neptune, Noire);
		CG_SaveDatabase(m_szQuery);
		
		return true;
	}
	
	return false;
}

void BuildLilyMenuToClient(int client)
{
	Handle menu = CreateMenu(LilyMainMenuHandler);
	SetMenuTitle(menu, "[Lily]  主菜单 \n　");

	AddMenuItem(menu, "propose", "寻找Lily", g_eClient[client][iLilyId] == -2 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	AddMenuItem(menu, "divorce", "解除Lily", g_eClient[client][iLilyId] > -2 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	AddMenuItem(menu, "lilyrank", "Lily Rank");
	AddMenuItem(menu, "lilyskill", "Lily Skill");
	AddMenuItem(menu, "aboutlily", "关于Lily");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 20);
}

public int LilyMainMenuHandler(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		if(StrEqual(info, "propose"))
			BuildSelectLilyMenu(client);
		else if(StrEqual(info, "divorce"))
			CheckingDivorce(client);
		else if(StrEqual(info, "lilyrank"))
			BuildLilyRankPanel(client);
		else if(StrEqual(info, "lilyskill"))
			FakeClientCommandEx(client, "sm_cskill");
		else if(StrEqual(info, "aboutlily"))
			BuildLilyHelpPanel(client);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

void BuildSelectLilyMenu(int client)
{
	Handle menu = CreateMenu(SelectLilyMenuHandler)
	
	
	SetMenuTitle(menu, "[Lily]  选择Lily对象\n　");
	
	int counts;
	char m_szItem[128], m_szId[8];
	for(int target = 1; target <= MaxClients; ++target)
	{
		if(IsClientInGame(target) && target != client)
		{
			if(g_eClient[target][bLoaded] && g_eClient[target][iLilyId] == -2)
			{
				Format(m_szId, 8, "%d", GetClientUserId(target));
				GetClientName(target, m_szItem, 128);
				AddMenuItem(menu, m_szId, m_szItem);
				counts++;
			}
		}
	}
	
	if(counts == 0)
	{
		AddMenuItem(menu, "", "当前服务器内没有人能跟你百合", ITEMDRAW_DISABLED);
	}
	
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public int SelectLilyMenuHandler(Handle menu, MenuAction action, int client, int itemNum) 
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			GetMenuItem(menu, itemNum, info, 32);
			
			int target = GetClientOfUserId(StringToInt(info));

			if(!target || !IsClientInGame(target) || g_eClient[target][iLilyId] != -2)
			{
				PrintToChat(client, "%s  你选择的对象目前不可用", PLUGIN_PREFIX);
				BuildLilyMenuToClient(client);
				return;
			}
			
			ConfirmLilyRequest(client, target);
			
			PrintToChat(client, "%s  已将你的Lily请求发送至\x0E%N", PLUGIN_PREFIX, target);
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
        {
			if(itemNum == MenuCancel_ExitBack)
				BuildLilyMenuToClient(client);
        }
	}
}

void ConfirmLilyRequest(int client, int target)
{
	Handle menu = CreateMenu(ConfirmLilyMenuHandler)
	SetMenuTitle(menu, "[Lily]  Lily Requset\n \n 你收到了一个来自 %N 的Lily邀请\n　", target);

	AddMenuItem(menu, "", "Lily能提供多种游戏福利", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "", "组成Lily后7天内不能申请解除", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "", "组成Lily后可享受Lily Buff和技能", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "", "你确定要接受这个邀请吗", ITEMDRAW_DISABLED);

	char m_szItem[32];
	
	Format(m_szItem, 32, "Accept%d", GetClientUserId(client));
	AddMenuItem(menu, m_szItem, "我接受");
	
	Format(m_szItem, 32, "Refuse%d", GetClientUserId(client));
	AddMenuItem(menu, m_szItem, "我拒绝");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, target, 0);
}

public int ConfirmLilyMenuHandler(Handle menu, MenuAction action, int target, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);

		if(StrContains(info, "Accept", false) != -1)
		{
			ReplaceString(info, 32, "Accept", "", false);
			int client = GetClientOfUserId(StringToInt(info));
			
			if(!client || !IsClientInGame(client) || g_eClient[client][iLilyId] != -2)
			{
				PrintToChat(target, "%s  邀请你的玩家当前不可用", PLUGIN_PREFIX);
				return;
			}
			
			Lily_AddNewCouple(client, target);
		}
		
		if(StrContains(info, "Refuse", false) != -1)
		{
			ReplaceString(info, 32, "Refuse", "", false);
			int client = GetClientOfUserId(StringToInt(info));
			
			if(!client || !IsClientInGame(client) || g_eClient[client][iLilyRank] != -2)
			{
				return;
			}
			
			PrintToChat(target, "%s  你拒绝了\x10%N\x01的Lily邀请", PLUGIN_PREFIX, client);
			PrintToChat(client, "%s  \x10%N\x01拒绝了你的Lily邀请", PLUGIN_PREFIX, target);
		}
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public void Lily_AddNewCouple(int Neptune, int Noire)
{
	if(!IsClientInGame(Neptune))
	{
		PrintToChat(Noire, "%s  系统中闪光弹了,请重试", PLUGIN_PREFIX);
		return;
	}
	
	if(!IsClientInGame(Noire))
	{
		PrintToChat(Neptune, "%s  系统中闪光弹了,请重试", PLUGIN_PREFIX);
		return;
	}
	
	Handle m_hPack = CreateDataPack();
	WritePackCell(m_hPack, GetClientUserId(Neptune));
	WritePackCell(m_hPack, GetClientUserId(Noire));
	ResetPack(m_hPack);

	char m_szQuery[512];
	Format(m_szQuery, 512, "CALL lily_addcouple(%d, %d)", g_eClient[Neptune][iPlayerId], g_eClient[Noire][iPlayerId]);
	SQL_TQuery(g_hDB_csgo, SQLCallback_UpdateLily, m_szQuery, m_hPack);
}

void CheckingDivorce(int client)
{
	if((GetTime() - g_eClient[client][iLilyDate]) < 604800)
	{
		PrintToChat(client, "%s  新组成Lily之后7天内不能申请解除", PLUGIN_PREFIX);
		BuildLilyMenuToClient(client);
		return;
	}

	if(g_eClient[client][iLilyId] > 0)
	{
		char m_szName[64];
		GetClientName(g_eClient[client][iLilyId], m_szName, 64);
		ReplaceString(m_szName, 64, ";", "", false);
		ConfirmDivorce(client, g_eClient[g_eClient[client][iLilyId]][iPlayerId], m_szName);
	}
	else
	{
		char m_szQuery[256];
		Format(m_szQuery, 256, "SELECT id, name FROM `playertrack_player` WHERE lilyid = %d", g_eClient[client][iPlayerId]);
		SQL_TQuery(g_hDB_csgo, SQLCallback_CheckDivorce, m_szQuery, GetClientUserId(client));
	}
}

void ConfirmDivorce(int client, const int m_iId, const char[] m_szName)
{
	Handle menu = CreateMenu(ConfirmDivorceMenuHandler);
	SetMenuTitle(menu, "[Lily]  Confirm Divorce \n　");
	
	char m_szItem[128];

	Format(m_szItem, 128, "你当前的Lily伴侣为 %s", m_szName);
	AddMenuItem(menu, "", m_szItem, ITEMDRAW_DISABLED);
	
	Format(m_szItem, 128, "你们已组成Lily %d 天", (GetTime() - g_eClient[client][iLilyDate])/86400);
	AddMenuItem(menu, "", m_szItem, ITEMDRAW_DISABLED);
	
	Format(m_szItem, 128, "你们当前Lily Rank %d ", g_eClient[client][iLilyRank]);
	AddMenuItem(menu, "", m_szItem, ITEMDRAW_DISABLED);

	AddMenuItem(menu, "", "你确定要解除Lily组合吗", ITEMDRAW_DISABLED);
	
	Format(m_szItem, 128, "%d;%s", m_iId, m_szName);
	AddMenuItem(menu, m_szItem, "我确定");
	AddMenuItem(menu, "fuckyou", "我拒绝");

	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 0);
}

public int ConfirmDivorceMenuHandler(Handle menu, MenuAction action, int client, int itemNum) 
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[128];
			GetMenuItem(menu, itemNum, info, 128);
			
			if(StrEqual(info, "fuckyou", false))
			{
				BuildLilyMenuToClient(client);
				return;
			}

			char m_szData[2][64];
			ExplodeString(info, ";", m_szData, 2, 64);

			Handle m_hPack = CreateDataPack();
			WritePackCell(m_hPack, GetClientUserId(client));
			WritePackCell(m_hPack, StringToInt(m_szData[0]));
			WritePackString(m_hPack, m_szData[1]);
			ResetPack(m_hPack);

			char m_szQuery[512];
			Format(m_szQuery, 512, "UPDATE `playertrack_player` SET lilyid = '-2', lilyrank = 0, lilyexp = 0, lilydate = 0 where id = %d or lilyid = %d", g_eClient[client][iPlayerId], g_eClient[client][iPlayerId]);
			SQL_TQuery(g_hDB_csgo, SQLCallback_UpdateDivorce, m_szQuery, m_hPack);
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
        {
            if(itemNum == MenuCancel_ExitBack)
            {
                BuildLilyMenuToClient(client);
            }
        }
	}
}

void BuildLilyRankPanel(int client)
{
	char m_szQuery[128];
	Format(m_szQuery, 128, "SELECT name, lilyrank FROM `playertrack_player` WHERE lilyid > 0 ORDER BY lilyrank DESC LIMIT 30;")
	SQL_TQuery(g_hDB_csgo, SQLCallback_LilyRank, m_szQuery, GetClientUserId(client));
}

void LilyRankToMenu(int client, Handle pack)
{
	ResetPack(pack);
	
	char m_szItem[256], m_szName[128];
	Handle menu = CreateMenu(LilyRankMenuHandler);

	SetMenuTitle(menu, "[Planeptune]   Lily Rank \n　");

	int m_iRank, iCount = ReadPackCell(pack);

	for(int i = 0; i < iCount; ++i)
	{
		ReadPackString(pack, m_szName, 128);
		m_iRank = ReadPackCell(pack);
		Format(m_szItem, 128, "#%d   %s [Lily Level: %d]", i+1, m_szName, m_iRank);
		AddMenuItem(menu, "", m_szItem, ITEMDRAW_DISABLED);
	}

	CloseHandle(pack);

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 20);
}

public int LilyRankMenuHandler(Handle menu, MenuAction action, int client, int itemNum)
{
	
}

void BuildLilyHelpPanel(int client)
{
	Handle panel = CreatePanel();
	DrawPanelText(panel, "[Lily]  Lily Help");
	DrawPanelText(panel, " ");
	DrawPanelText(panel, "组成Lily需要两厢情愿");
	DrawPanelText(panel, "Lily配对后7天内不能解除");
	DrawPanelText(panel, "Lily能为你提供Buff和技能");
	DrawPanelText(panel, "Rank为一套等级系统");
	DrawPanelText(panel, "Level影响buff和技能以及Credits加成");
	DrawPanelText(panel, "Exp能提升你的 Level");
	DrawPanelText(panel, "完成Guild任务或达成游戏条件可以获得Exp");
	DrawPanelText(panel, " ");
	DrawPanelItem(panel, "退出");
	SendPanelToClient(panel, client, LilyHelpPanelHandler, 0);
	CloseHandle(panel);
}

public int LilyHelpPanelHandler(Handle menu, MenuAction action, int client, int param2)
{
	if(action == MenuAction_Select)
	{
		BuildLilyMenuToClient(client);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}