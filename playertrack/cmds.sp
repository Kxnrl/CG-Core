//////////////////////////////
//		CLIENT COMMAND		//
//////////////////////////////
public Action Command_ReloadAdv(int client, int args)
{
	//重载广告
	SettingAdver();
}

public Action Command_Online(int client, int args)
{
	//查询在线时间
	int m_iHours = g_eClient[client][iOnline] / 3600;
	int m_iMins = g_eClient[client][iOnline] % 3600;
	int t_iMins = (GetTime() - g_eClient[client][iConnectTime]) / 60;
	tPrintToChat(client, "%s  %t", PLUGIN_PREFIX, "cmd onlines", client, m_iHours, m_iMins, g_eClient[client][iNumber], t_iMins);
}

public Action Command_Track(int client, int args)
{
	//控制台查看玩家数据
	if(!client || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;

	char szItem[512], szAuth32[32], szAuth64[64];
	Format(szItem, 512,"#PlayerId   玩家姓名    UID   论坛名称   steam32   steam64    认证\n========================================================================================");
	PrintToConsole(client, szItem);
	
	int connected, ingame;

	for(int i = 1; i <= MaxClients; ++i)
	{
		if(IsClientConnected(i))
		{
			connected++;
			
			if(IsValidClient(i, true))
			{
				ingame++;
				
				GetClientAuthId(i, AuthId_Steam2, szAuth32, 32, true);
				GetClientAuthId(i, AuthId_SteamID64, szAuth64, 64, true);
				Format(szItem, 512, " %d    %N    %d    %s    %s    %s    %s", g_eClient[i][iPlayerId], i, g_eClient[i][iUID], g_eClient[i][szDiscuzName], szAuth32, szAuth64, g_eClient[i][szGroupName]);
				PrintToConsole(client, szItem);
			}
		}
	}
	
	tPrintToChat(client, "%s  %t", PLUGIN_PREFIX, "check console");
	tPrintToChat(client, "%s  %t", PLUGIN_PREFIX, "cmd track", ingame, connected);

	return Plugin_Handled;
}

public Action Command_CP(int client, int args)
{
	//打开CP主菜单
	BuildCPMenu(client);
	
	return Plugin_Handled;
}

public Action Command_Menu(int client, int args)
{
	//创建CG玩家主菜单
	Handle menu = CreateMenu(MenuHandler_CGMainMenu);
	SetMenuTitleEx(menu, "[CG]   主菜单");

	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "store", "%t", "main store desc");
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "lily", "%t", "main cp desc");
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "music", "%t", "main music desc");
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "sign", "%t", "main sign desc");
	AddMenuItemEx(menu, g_eClient[client][iVipType] > 1 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED, "vip", "%t", "main vip desc");

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
	
	return Plugin_Handled;
}

public Action Command_Login(int client, int args) 
{
	ProcessingLogin(client);
	
	return Plugin_Handled;
}

public Action Command_Signature(int client, int args)
{
	if(StrContains(g_eClient[client][szSignature], "该玩家未设置签名") != -1)
	{
		tPrintToChat(client, "%s  %t", PLUGIN_PREFIX, "signature free first");
		BuildListenerMenu(client);
		return Plugin_Handled;
	}

	if(OnAPIStoreGetCredits(client) < 500)
	{
		tPrintToChat(client, "%s  %t", PLUGIN_PREFIX, "signature you have not enough credits");
		return Plugin_Handled;
	}

	BuildListenerMenu(client);
	
	return Plugin_Handled;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if(!g_eClient[client][bListener])
		return Plugin_Continue;
	
	strcopy(g_eClient[client][szNewSignature], 256, sArgs);
	
	tPrintToChat(client, "%t", "signature input", sArgs);

	g_eClient[client][bListener] = false;

	if(g_eClient[client][hListener] != INVALID_HANDLE)
	{
		KillTimer(g_eClient[client][hListener]);
		g_eClient[client][hListener] = INVALID_HANDLE;
	}
	
	BuildListenerMenu(client);

	return Plugin_Handled;
}