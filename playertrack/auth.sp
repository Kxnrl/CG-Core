 public int MenuHandler_AdminPAMenuHandler(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, sizeof(info));
		
		if(strcmp(info, "9000") == 0)
			g_eAdmin[iType] = 1;
		else if(strcmp(info, "9001") == 0)
			g_eAdmin[iType] = 2;
		else if(strcmp(info, "unban") == 0)
			g_eAdmin[iType] = 3;
		else if(strcmp(info, "reload") == 0)
			g_eAdmin[iType] = 4;

		OpenSelectTargetMenu(client);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

void OpenSelectTargetMenu(int client)
{
	Handle menu = CreateMenu(MenuHandler_PASelectTarget);

	if(g_eAdmin[iType] == 1)
		SetMenuTitle(menu, "[Planeptune]   添加临时神烦坑比\n　");
	else if(g_eAdmin[iType] == 2)
		SetMenuTitle(menu, "[Planeptune]   添加临时小学生\n　");
	else if(g_eAdmin[iType] == 3)
		SetMenuTitle(menu, "[Planeptune]   撤销临时认证\n　");
	else if(g_eAdmin[iType] == 4)
		SetMenuTitle(menu, "[Planeptune]   重新载入认证\n　");
	else
		SetMenuTitle(menu, "[Planeptune]   未知错误");

	if(g_eAdmin[iType] == 1 || g_eAdmin[iType] == 2)
	{
		for(int x=1; x<=MaxClients; ++x)
		{
			if(IsClientInGame(x) && !IsClientBot(x))
			{
				if(g_eClient[x][iGroupId] == 0 && g_eClient[x][iTemp] == 0)
				{
					char szInfo[16], szName[64];
					Format(szInfo, 16, "%d", GetClientUserId(x));
					Format(szName, 64, "%N", x);
					AddMenuItem(menu, szInfo, szName);
				}
			}
		}
	}
	else if(g_eAdmin[iType] == 3)
	{
		for(int x=1; x<=MaxClients; ++x)
		{
			if(IsClientInGame(x) && !IsClientBot(x))
			{
				if(g_eClient[x][iTemp] > 0)
				{
					char szInfo[16], szName[64];
					Format(szInfo, 16, "%d", GetClientUserId(x));
					Format(szName, 64, "%N", x);
					if(g_eClient[x][iGroupId] == 9000)
						Format(szName, 64, "%N[神烦坑比]", x);
					if(g_eClient[x][iGroupId] == 9001)
						Format(szName, 64, "%N[小学生]", x);
					AddMenuItem(menu, szInfo, szName);
				}
			}
		}
	}
	else if(g_eAdmin[iType] == 4)
	{
		for(int x=1; x<=MaxClients; ++x)
		{
			if(IsClientInGame(x) && !IsClientBot(x))
			{
				char szInfo[16], szName[64];
				Format(szInfo, 16, "%d", GetClientUserId(x));
				Format(szName, 64, "%N", x);
				AddMenuItem(menu, szInfo, szName);
			}
		}
	}

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 30);
}


public int MenuHandler_PASelectTarget(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		int target = GetClientOfUserId((StringToInt(info)));

		g_eAdmin[iTarget] = target;
		
		if(g_eAdmin[iType] == 1 || g_eAdmin[iType] == 2)
			OpenSelectTimeMenu(client);
		
		if(g_eAdmin[iType] == 3)
			DoUnbanTempPA(client);
		
		if(g_eAdmin[iType] == 4)
			DoReloadPA(client);
		
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

void OpenSelectTimeMenu(int client)
{
	Handle menu = CreateMenu(MenuHandler_PASelectTime);
	SetMenuTitle(menu, "[Planeptune]   选择临时认证时长\n　");
	AddMenuItem(menu, "1800", "30 Mins");
	AddMenuItem(menu, "3600", "1 Hour");
	AddMenuItem(menu, "10800", "3 Hours");
	AddMenuItem(menu, "21600", "6 Hours");
	AddMenuItem(menu, "43200", "12 Hours");
	AddMenuItem(menu, "86400", "1 Day");
	AddMenuItem(menu, "259200", "3 Days");
	AddMenuItem(menu, "604800", "7 Days");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public int MenuHandler_PASelectTime(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		g_eAdmin[iTime] = StringToInt(info);
		
		DoAddTempPA(client);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

void DoAddTempPA(int client)
{
	int target = g_eAdmin[iTarget];
	int ExpiredTime = g_eAdmin[iTime] + GetTime();
	int GroupIndex;
	if(g_eAdmin[iType] == 1)
		GroupIndex = 9000;
	if(g_eAdmin[iType] == 2)
		GroupIndex = 9001;
	
	g_eClient[target][iGroupId] = GroupIndex;
	g_eClient[target][iTemp] = g_eAdmin[iTime];

	OnClientAuthLoaded(target);

	char sName[32];
	if(GroupIndex == 9000)
	{
		PrintToChatAll("%s 管理员\x10%N\x01给\x02%N\x01添加了临时认证[\x02神烦坑比\x01]", PLUGIN_PREFIX, client, target);
		LogToFileEx(LogFile, " %N 给 %N 加上了临时认证[神烦坑比]!", client, target);
		LogAction(client, target, "\"%L\" 给 \"%L\" 加上了临时认证[神烦坑比]", client, target);
		Format(sName, 32, "神烦坑比");
	}

	if(GroupIndex == 9001)
	{
		PrintToChatAll("%s 管理员\x10%N\x01给\x02%N\x01添加了临时认证[\x02我是小学生\x01]", PLUGIN_PREFIX, client, target);
		LogToFileEx(LogFile, " %N 给 %N 加上了临时认证[神烦坑比]!", client, target);
		LogAction(client, target, "\"%L\" 给 \"%L\" 加上了临时认证[我是小学生]", client, target);
		Format(sName, 32, "小学生");
	}
	
	char szQuery[256], m_szAuth[32];
	GetClientAuthId(target, AuthId_Steam2, m_szAuth, 32, true);
	
	Format(szQuery, 256, "UPDATE `playertrack_player` SET groupid = '%d', groupname = '%s', temp = '%d' WHERE id = '%d' and steamid = '%s'", GroupIndex, sName, ExpiredTime, g_eClient[target][iPlayerId], m_szAuth);
	SQL_TQuery(g_hDB_csgo, SQLCallback_SetTemp, szQuery, GetClientUserId(client));
}

void DoUnbanTempPA(int client)
{
	int target = g_eAdmin[iTarget]; 

	char szQuery[256], m_szAuth[32];

	GetClientAuthId(target, AuthId_Steam2, m_szAuth, 32);

	Format(szQuery, 256, "UPDATE `playertrack_player` SET groupid = '0', groupname = '未认证', temp = '0' WHERE id = '%d' and steamid = '%s'", g_eClient[target][iPlayerId], m_szAuth);
	SQL_TQuery(g_hDB_csgo, SQLCallback_DeleteTemp, szQuery, GetClientUserId(client), DBPrio_High);

	PrintToChatAll("%s 管理员\x10%N\x01解除了\x02%N\x01的临时认证", PLUGIN_PREFIX, client, target);
}

void DoReloadPA(int client)
{
	int target = g_eAdmin[iTarget]; 
	LoadAuthorized(target);
	PrintToChat(client, "%s 刷新了\x04%N\x01的认证数据...", PLUGIN_PREFIX, target);
}

void LoadAuthorized(int client)
{
	char szQuery[256], m_szAuth[32];
	GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32);
	Format(szQuery, 256, "SELECT `groupid`,`groupname`,`exp`,`level`,`temp` FROM `playertrack_player` WHERE id = '%d' and steamid = '%s'", g_eClient[client][iPlayerId], m_szAuth);
	SQL_TQuery(g_hDB_csgo, SQLCallback_GetGroupId, szQuery, GetClientUserId(client));
}