void InitializeCP(int client, int CPId, int CPDate)
{
	// 在数据库中如果CPId<1那么肯定就是光棍
	if(CPId < 1)
	{
		g_eClient[client][iCPId] = -2;
		g_eClient[client][iCPDate] = 0;
	}
	else
	{
		//通过PlayerId来查询Client Slot    -1就是离线,-2就是光棍,0因为是Console比较特殊所以排除
		int m_iPartner = FindClientByPlayerId(CPId);
		
		//建立CP关联
		g_eClient[client][iCPId] = m_iPartner;
		g_eClient[client][iCPDate] = CPDate;
		
		//如果返回的Slot是有效的，那么那个Client就是你的CP的Id
		if(1 <= m_iPartner <= MaxClients)
		{
			g_eClient[m_iPartner][iCPId] = client;
		}
	}
}

void CheckingCP(int Neptune)
{
	//先获取你CP是不是有效的玩家
	int Noire = g_eClient[Neptune][iCPId];
	
	if(Noire < 1)
		return;

	//清除关联
	g_eClient[Noire][iCPId] = -1;
}

void BuildCPMenu(int client)
{
	//CP主菜单
	Handle menu = CreateMenu(MenuHandler_CPMain);
	SetMenuTitleEx(menu, "[CP]  %t ", "global menu title");

	AddMenuItemEx(menu, g_eClient[client][iCPId] == -2 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED, "propose", "%t", "cp find");
	AddMenuItemEx(menu, g_eClient[client][iCPId] > -2 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED, "divorce", "%t", "cp out");
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "aboutlily", "%t", "cp about");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 20);
}

public int MenuHandler_CPMain(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		if(StrEqual(info, "propose"))
			BuildSelectCPMenu(client);
		else if(StrEqual(info, "divorce"))
			CheckingDivorce(client);
		else if(StrEqual(info, "aboutlily"))
			BuildCPHelpPanel(client);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

void BuildSelectCPMenu(int client)
{
	//选择CP对象的菜单
	Handle menu = CreateMenu(MenuHandler_CPSelect)

	SetMenuTitleEx(menu, "[CP]  选择CP对象");
	
	int counts;
	char m_szItem[128], m_szId[8];
	for(int target = 1; target <= MaxClients; ++target)
	{
		if(IsClientInGame(target) && target != client)
		{
			if(g_eClient[target][bLoaded] && g_eClient[target][iCPId] == -2)
			{
				Format(m_szId, 8, "%d", GetClientUserId(target));
				GetClientName(target, m_szItem, 128);
				AddMenuItemEx(menu, ITEMDRAW_DEFAULT, m_szId, m_szItem);
				counts++;
			}
		}
	}
	
	if(counts == 0)
	{
		AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "", "%t", "cp no target");
	}
	
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public int MenuHandler_CPSelect(Handle menu, MenuAction action, int client, int itemNum) 
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			GetMenuItem(menu, itemNum, info, 32);
			
			int target = GetClientOfUserId(StringToInt(info));

			if(!target || !IsClientInGame(target) || g_eClient[target][iCPId] != -2)
			{
				tPrintToChat(client, "%s  %t", PLUGIN_PREFIX, "cp invalid target");
				BuildCPMenu(client);
				return;
			}
			
			ConfirmCPRequest(client, target);
			
			tPrintToChat(client, "%s  %t", PLUGIN_PREFIX, "cp send", target);
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if(itemNum == MenuCancel_ExitBack)
				BuildCPMenu(client);
		}
	}
}

void ConfirmCPRequest(int client, int target)
{
	//接受lily请求菜单
	Handle menu = CreateMenu(MenuHandler_CPConfirm)
	SetMenuTitleEx(menu, "[CP]  %t", "cp request");

	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "", "%t", "cp request item target", target);
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "", "%t", "cp 7days");
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "", "%t", "cp buff");
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "", "%t", "cp confirm");

	char m_szItem[32];
	
	Format(m_szItem, 32, "Accept%d", GetClientUserId(client));
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, m_szItem, "%t", "cp accept");
	
	Format(m_szItem, 32, "Refuse%d", GetClientUserId(client));
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, m_szItem, "%t", "cp refuse");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, target, 0);
}

public int MenuHandler_CPConfirm(Handle menu, MenuAction action, int target, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);

		//接受?
		if(StrContains(info, "Accept", false) != -1)
		{
			//移除标识符
			ReplaceString(info, 32, "Accept", "", false);
			int client = GetClientOfUserId(StringToInt(info));
			
			if(!client || !IsClientInGame(client) || g_eClient[client][iCPId] != -2)
			{
				tPrintToChat(target, "%s  %t", PLUGIN_PREFIX, "cp invalid target");
				return;
			}
			
			CP_AddNewCouple(client, target);
		}
		
		//拒绝?
		if(StrContains(info, "Refuse", false) != -1)
		{
			ReplaceString(info, 32, "Refuse", "", false);
			int client = GetClientOfUserId(StringToInt(info));
			
			if(!client || !IsClientInGame(client))
			{
				return;
			}
			
			tPrintToChat(target, "%s  %t", PLUGIN_PREFIX, "cp refuse target", client);
			tPrintToChat(client, "%s  %t", PLUGIN_PREFIX, "cp refuse client", target);
		}
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public void CP_AddNewCouple(int Neptune, int Noire)
{
	//对象无效?
	if(!IsClientInGame(Neptune))
	{
		tPrintToChat(Noire, "%s  %t 000000", PLUGIN_PREFIX, "system error");
		return;
	}
	
	if(!IsClientInGame(Noire))
	{
		tPrintToChat(Neptune, "%s  %t 000000", PLUGIN_PREFIX, "system error");
		return;
	}
	
	//创建DataPack
	Handle m_hPack = CreateDataPack();
	WritePackCell(m_hPack, GetClientUserId(Neptune));
	WritePackCell(m_hPack, GetClientUserId(Noire));
	ResetPack(m_hPack);

	//使用SQL函数 CALL
	char m_szQuery[128];
	Format(m_szQuery, 128, "CALL lily_addcouple(%d, %d)", g_eClient[Neptune][iPlayerId], g_eClient[Noire][iPlayerId]);
	MySQL_Query(g_hDB_csgo, SQLCallback_UpdateCP, m_szQuery, m_hPack);
}

void CheckingDivorce(int client)
{
	//防止某些人刷CP
	if((GetTime() - g_eClient[client][iCPDate]) < 604800)
	{
		tPrintToChat(client, "%s  %t", PLUGIN_PREFIX, "cp can divorce");
		BuildCPMenu(client);
		return;
	}

	//CP是不是在服务器内
	if(g_eClient[client][iCPId] > 0)
	{
		char m_szName[64];
		GetClientName(g_eClient[client][iCPId], m_szName, 64);
		//过滤名字中的保留符号';' 因为之后的函数需要用这个做间隔符来爆破字符串
		ReplaceString(m_szName, 64, ";", "", false);
		ConfirmDivorce(client, g_eClient[g_eClient[client][iCPId]][iPlayerId], m_szName);
	}
	else
	{
		//需要读取CP的名字来创建确认菜单
		char m_szQuery[256];
		Format(m_szQuery, 256, "SELECT id, name FROM `playertrack_player` WHERE lilyid = %d", g_eClient[client][iPlayerId]);
		MySQL_Query(g_hDB_csgo, SQLCallback_CheckDivorce, m_szQuery, GetClientUserId(client));
	}
}

void ConfirmDivorce(int client, const int m_iId, const char[] m_szName)
{
	//确认离婚了
	Handle menu = CreateMenu(MenuHandler_CPConfirmDivorce);
	SetMenuTitleEx(menu, "[CP]  Confirm Divorce ");
	
	char m_szItem[128];

	Format(m_szItem, 128, "%t", "cp your cp", m_szName);
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "", m_szItem);
	
	Format(m_szItem, 128, "%t", "cp your days", (GetTime() - g_eClient[client][iCPDate])/86400);
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "", m_szItem);

	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "", "%t", "cp confirm divorce");
	
	AddMenuItemEx(menu, ITEMDRAW_SPACER, "", "");
	
	Format(m_szItem, 128, "%d;%s", m_iId, m_szName);
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, m_szItem, "%t", "global item sure");
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "fuckyou", "%t",  "global item refuse");

	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 0);
}

public int MenuHandler_CPConfirmDivorce(Handle menu, MenuAction action, int client, int itemNum) 
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[128];
			GetMenuItem(menu, itemNum, info, 128);
			
			if(StrEqual(info, "fuckyou", false))
			{
				BuildCPMenu(client);
				return;
			}

			//使用';'来爆破字符串取得数据? 其实是因为我偷懒 不想用全局变量，当然也算节省开销
			char m_szData[2][64];
			ExplodeString(info, ";", m_szData, 2, 64);

			//DataPack
			Handle m_hPack = CreateDataPack();
			WritePackCell(m_hPack, GetClientUserId(client));
			WritePackCell(m_hPack, StringToInt(m_szData[0]));
			WritePackString(m_hPack, m_szData[1]);
			ResetPack(m_hPack);

			//确认离婚之后更新数据库
			char m_szQuery[256];
			Format(m_szQuery, 256, "UPDATE `playertrack_player` SET lilyid = '-2', lilydate = 0 where id = %d or lilyid = %d", g_eClient[client][iPlayerId], g_eClient[client][iPlayerId]);
			MySQL_Query(g_hDB_csgo, SQLCallback_UpdateDivorce, m_szQuery, m_hPack);
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
        {
            if(itemNum == MenuCancel_ExitBack)
            {
				//返回之后就重铸菜单
                BuildCPMenu(client);
            }
        }
	}
}

void BuildCPHelpPanel(int client)
{
	//lily的帮助菜单
	Handle menu = CreateMenu(CPHelpPanelHandler);
	SetMenuTitleEx(menu, "[CP]  %t", "cp help title");

	AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "%t", "cp each other");
	AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "%t", "cp after 7days");
	AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "%t", "cp earn buff");

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public int CPHelpPanelHandler(Handle menu, MenuAction action, int client, int param2)
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}