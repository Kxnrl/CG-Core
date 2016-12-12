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
	SetMenuTitleEx(menu, "[CG]  %t", "global menu title");

	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "store", "%t", "main store desc");
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "lily", "%t", "main cp desc");
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "music", "%t", "main music desc");
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "sign", "%t", "main sign desc");
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "auth", "%t", "main auth desc");
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

public Action Command_GetAuth(int client, int args)
{
	if(!g_eClient[client][bLoaded])
		return Plugin_Handled;

	if(g_eClient[client][iGroupId] == 9000 || g_eClient[client][iGroupId] == 9001)
		return Plugin_Handled;
	
	if(g_eClient[client][iGroupId] > 0)
	{
		tPrintToChat(client, "%s  {green}%t", PLUGIN_PREFIX, "you are already Auth Player")
		return Plugin_Handled;
	}
	
	//创建CG玩家主菜单
	Handle menu = CreateMenu(MenuHandler_GetAuth);
	SetMenuTitleEx(menu, "[CG]  %t [Auth name Only SChinese]", "auth menu title");

	AddMenuItemEx(menu, ITEMDRAW_DEFAULT,    "1", "[僵尸逃跑] 断后达人");
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT,    "2", "[僵尸逃跑] 指挥大佬");
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT,    "3", "[僵尸逃跑] 僵尸克星");
	
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT,  "101", "[匪镇谍影] 职业侦探");
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT,  "102", "[匪镇谍影]   心机婊");
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT,  "103", "[匪镇谍影]  TTT影帝");
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT,  "104", "[匪镇谍影] 赌命狂魔");
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT,  "105", "[匪镇谍影] 杰出公民");
	
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT,  "201", "[娱乐休闲] 娱乐挂壁");
	
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT,  "301", "[混战休闲] 首杀无敌");
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT,  "302", "[混战休闲] 混战指挥");
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT,  "303", "[混战休闲] 爆头狂魔");
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT,  "304", "[混战休闲] 助攻之神");

	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
	
	return Plugin_Handled;
}