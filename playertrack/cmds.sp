//////////////////////////////
//		CLIENT COMMAND		//
//////////////////////////////
public Action Command_ReloadAdv(int client, int args)
{
	//重载广告
	SettingAdver();
	return Plugin_Handled;
}

public Action Command_Online(int client, int args)
{
	if(!IsValidClient(client) || !g_eClient[client][bLoaded])
		return Plugin_Handled;
	
	//查询在线时间
	int m_iHours = g_eClient[client][iOnline] / 3600;
	int m_iMins = g_eClient[client][iOnline] % 3600;
	int t_iMins = (GetTime() - g_eClient[client][iConnectTime]) / 60;
	tPrintToChat(client, "%s  %T", PLUGIN_PREFIX, "cmd onlines", client, client, m_iHours, m_iMins/60, g_eClient[client][iNumber], t_iMins);

	return Plugin_Handled;
}

public Action Command_Track(int client, int args)
{
	//控制台查看玩家数据
	if(!IsValidClient(client))
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
			
			if(IsClientInGame(i))
			{
				ingame++;

				GetClientAuthId(i, AuthId_Steam2, szAuth32, 32, true);
				GetClientAuthId(i, AuthId_SteamID64, szAuth64, 64, true);
				Format(szItem, 512, " %d    %N    %d    %s    %s    %s    %s", g_eClient[i][iPlayerId], i, g_eClient[i][iUID], g_eClient[i][szDiscuzName], szAuth32, szAuth64, g_eClient[i][szGroupName]);
				PrintToConsole(client, szItem);
			}
		}
	}
	
	tPrintToChat(client, "%s  %T", PLUGIN_PREFIX, "check console", client);
	tPrintToChat(client, "%s  %T", PLUGIN_PREFIX, "cmd track", client, ingame, connected);

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
	SetMenuTitleEx(menu, "[CG]  %T", "global menu title", client);

	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "store", "%T", "main store desc", client);
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "lily", "%T", "main cp desc", client);
	AddMenuItemEx(menu, TalentAvailable() ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED, "talent", "%T", TalentAvailable() ? "main talent desc" : "main talent not allow", client);
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "sign", "%T", "main sign desc", client);
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "auth", "%T", "main auth desc", client);
	AddMenuItemEx(menu, g_eClient[client][iVipType] > 1 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED, "vip", "%T", "main vip desc", client);
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "rule", "%T", "main rule desc", client);
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "group", "%T", "main group desc", client);
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "forum", "%T", "main forum desc", client);
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "music", "%T", "main music desc", client);
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "radio", "%T", "main radio desc", client);
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "online", "%T", "main online desc", client);
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "setrp", "%T", "main setrp desc", client);
	AddMenuItemEx(menu, ITEMDRAW_DISABLED, "huodo", "%T", "main act desc", client);
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "lang", "%T", "main select language", client);

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
		tPrintToChat(client, "%s  %T", PLUGIN_PREFIX, "signature free first", client);
		BuildListenerMenu(client);
		return Plugin_Handled;
	}

	if(OnAPIStoreGetCredits(client) < 500)
	{
		tPrintToChat(client, "%s  %T", PLUGIN_PREFIX, "signature you have not enough credits", client);
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
	
	tPrintToChat(client, "%T", "signature input", client, sArgs);

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
		tPrintToChat(client, "%s  {green}%T", PLUGIN_PREFIX, "you are already Auth Player", client)
		return Plugin_Handled;
	}

	//创建CG玩家主菜单
	Handle menu = CreateMenu(MenuHandler_GetAuth);
	SetMenuTitleEx(menu, "[CG]  %T [Auth name Only SChinese]", "auth menu title", client);

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
	
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "1001", "[全服认证] 女装大佬");
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "1002", "[全服认证] 援交少女");
	
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "9901", "[全服认证] CG地图组");
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "9902", "[全服认证] CG测试组");
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "9903", "[全服认证] CG技术组");

	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
	
	return Plugin_Handled;
}

public Action Command_Language(int client, int args)
{
	int newlang;
	switch(GetClientLanguage(client))
	{
		case 0:
		{
			newlang = 23;
			tPrintToChat(client, "%s  你的语言已切换为\x04简体中文", PLUGIN_PREFIX);
		}
		case 23:
		{
			newlang = 27;
			tPrintToChat(client, "%s  你的語言已經切換到\x04繁體中文", PLUGIN_PREFIX);
		}
		case 27:
		{
			newlang = 0;
			tPrintToChat(client, "%s  you language has been changed to \x04English", PLUGIN_PREFIX);
		}
	}

	SetClientLanguage(client, newlang);

	if(args < 0)
		FakeClientCommand(client, "sm_cg");
	
	return Plugin_Handled;
}