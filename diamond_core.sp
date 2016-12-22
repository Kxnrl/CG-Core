#include <cg_core>
#include <maoling>
#include <diamond>

#define PREFIX "[\x10新年快乐\x01]  "

Handle g_hDatabase;

int g_iDiamonds[MAXPLAYERS+1];
bool g_bLoaded[MAXPLAYERS+1];
bool g_bPackage[MAXPLAYERS+1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("CG_GetClientDiamond", Native_GetClientDiamond);
	CreateNative("CG_SetClientDiamond", Native_SetClientDiamond);

	return APLRes_Success;
}

public int Native_GetClientDiamond(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(IsValidClient(client) && IsAllowClient(client) && g_bLoaded[client])
		return g_iDiamonds[client];

	return -1;
}

public int Native_SetClientDiamond(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int counts = GetNativeCell(2);
	if(IsValidClient(client) && IsAllowClient(client) && g_bLoaded[client])
	{
		if(counts > 255) counts = 255;
		int diff = counts - g_iDiamonds[client];
		if(diff != 0)
		{
			g_iDiamonds[client] = counts;
			char m_szAuth[32], m_szQuery[256];
			GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
			Format(m_szQuery, 256, "UPDATE `playertrack_diamonds` SET `diamonds` = `diamonds` + '%d' WHERE `playerid` = '%d' AND `dzid` = '%d' AND `steamid` = '%s'", diff, CG_GetPlayerID(client), CG_GetDiscuzUID(client), m_szAuth);
			SQL_TQuery(g_hDatabase, SQLCallback_SaveClient, m_szQuery, GetClientUserId(client));
			PrintToChat(client, "%s  \x04你%s了\x10 %d钻石 \x04当前剩余\x01: \x10 %d钻石", PREFIX, (diff >= 0) ? "获得" : "失去", diff, g_iDiamonds[client]);
			return true;
		}
		return false;
	}
	return false;
}

public void OnPluginStart()
{
	HookClientVIPChecked(OnClientVIPChecked);

	RegConsoleCmd("huodong", Command_Active);
	RegConsoleCmd("sm_hd", Command_Active);
}

public void OnMapStart()
{
	CG_OnServerLoaded();
}

public Action Command_Active(int client, int args)
{
	if(client && IsClientInGame(client))
		BuildMainMenu(client);
}

void BuildMainMenu(int client)
{
	if(CG_GetPlayerID(client) < 1)
	{
		PrintToChat(client, "[\x0E新年活动\x01]   未知错误,请联系管理员");
		return;
	}
	
	if(CG_GetDiscuzUID(client) < 1)
	{
		PrintToChat(client, "[\x0E新年活动\x01]   欲参加此活动请先注册论坛");
		return;
	}
	
	if(!g_bLoaded[client])
	{
		PrintToChat(client, "[\x0E新年活动\x01]   你的数据尚未加载完毕");
		return;
	}

	Handle menu = CreateMenu(MenuHandler_MainMenu);
	SetMenuTitleEx(menu, "[CG]  新年活动\n钻石: %d\n \n钻石可兑换:\nStore道具\nCSGO钥匙/皮肤\nCG专属道具", g_iDiamonds[client]);

	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "view", "查看活动");
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "earn", "查看奖励");
	AddMenuItemEx(menu, g_bPackage[client] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED, "pkge", "领取礼包");

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public int MenuHandler_MainMenu(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		if(StrEqual(info, "view"))
			BuildViewMenu(client);
		else
			PrintToChat(client, "%s  \x04Coming soon...", PREFIX);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

void BuildViewMenu(int client)
{
	if(!IsAllowClient(client) || !g_bLoaded[client])
		return;
	
	Handle menu = CreateMenu(MenuHandler_ViewMenu);
	SetMenuTitleEx(menu, "[CG]  新年活动 - 查看活动\n钻石: %d", g_iDiamonds[client]);

	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "0", "全服活动");
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "1", "匪镇谍影");
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "2", "僵尸逃跑");
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "3", "娱乐休闲");
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "4", "越狱搞基");
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "5", "混战休闲");

	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public int MenuHandler_ViewMenu(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32], name[32];
		GetMenuItem(menu, itemNum, info, 32, _, name, 32);
		BuildModeMenu(client, StringToInt(info), name);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if(action == MenuAction_Cancel)
	{
		if(itemNum == MenuCancel_ExitBack)
			BuildMainMenu(client);
	}
}

void BuildModeMenu(int client, int mode, const char[] name)
{
	if(!IsAllowClient(client) || !g_bLoaded[client])
		return;

	Handle menu = CreateMenu(MenuHandler_ModeMenu);
	SetMenuTitleEx(menu, "[CG]  新年活动 - %s\n钻石: %d", name, g_iDiamonds[client]);
	
	switch(mode)
	{
		case 0:
		{
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "无限火力开启|不统计死亡|击杀奖励加倍");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "每日签到后,参加新年专属皮肤抽奖");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "服务器内随机掉落宝箱,打开后获得奖励");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "领取双旦礼包/新春礼包");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "在线获得信用点加倍");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "每日签到信用点加倍");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "每日签到随机抽皮肤");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "热度统计值获得加倍");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "每隔五分钟进行抽奖");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "使用钻石币兑换钥匙");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "使用钻石币参与抽奖");	
		}
		case 1:
		{
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "每次正确击杀都会额外获得随机数量的信用点");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "使用电击枪验明叛徒有概率获得钻石或信用点");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "每次正确击杀重甲玩家有概率获得钻石或信用点");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "在地图时间内叛徒累计击杀50人即可获得钻石或信用点");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "在地图时间内总消费50职业点数即可获得钻石或信用点");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "每隔5分钟随机抽300信用点/随机皮肤/MVIP/夕立限定皮肤");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "当日在线奖励(60分钟1钻石|150分钟5钻石|300分钟10钻石)");
		}
		case 2:
		{
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "通关神图的幸存者获得随机数量的钻石或信用点");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "通关神图后所有玩家参与抽取皮肤/限定皮肤");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "爆头击杀僵尸即可获得随机数量的钻石或信用点");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "一局爆菊10个人类获得随机数量的钻石或信用点");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "一局伤害输出前五名奖励随机数量钻石或信用点");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "在地图时间累计击杀10只僵尸即可获得钻石或信用点");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "在地图时间累计感染30个人类即可获得钻石或信用点");
		}
		case 3:
		{
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "刀杀/电死玩家会有概率获得钻石或信用点[击杀狗OP概率翻倍]");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "地图结束时(>30分钟)获得玩家得分*3的信用点|*0.1的钻石");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "每局菠菜获胜的玩家可以选择将信用点转换成钻石");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "每句菠菜失败的玩家有一定概率获得返还信用点");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "投掷物击杀将会获得[15~50]信用点奖励");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "爆头击杀玩家有概率获得[1~250]信用点奖励|[1~5]钻石");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "EndGame中1V1获胜的玩家,随机抽取商店任意在售皮肤[7天]");
		}
		case 4:
		{
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "越狱狗OP尚未提交活动策划");
		}
		case 5:
		{
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "混战狗OP尚未提交活动策划");
		}
	}

	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public int MenuHandler_ModeMenu(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32], name[32];
		GetMenuItem(menu, itemNum, info, 32, _, name, 32);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if(action == MenuAction_Cancel)
	{
		if(itemNum == MenuCancel_ExitBack)
			BuildViewMenu(client);
	}
}

public void CG_OnServerLoaded()
{
	g_hDatabase = CG_GetGameDatabase();
	if(g_hDatabase == INVALID_HANDLE)
		CreateTimer(10.0, Timer_Reconnect);
}

public Action Timer_Reconnect(Handle tiemr)
{
	CG_OnServerLoaded();
}

public void OnClientPutInServer(int client)
{
	g_bLoaded[client] = false;
	g_bPackage[client] = false;
	g_iDiamonds[client] = -1;
}

void LoadClient(int client)
{
	char m_szAuth[32], m_szQuery[256];
	GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
	Format(m_szQuery, 256, "SELECT `diamonds`,`package` FROM `playertrack_diamonds` WHERE `playerid` = '%d' AND `dzid` = '%d' AND `steamid` = '%s' ORDER BY `playerid` ASC LIMIT 1;", CG_GetPlayerID(client), CG_GetDiscuzUID(client), m_szAuth);
	SQL_TQuery(g_hDatabase, SQLCallback_LoadClient, m_szQuery, GetClientUserId(client));
}

public int OnClientVIPChecked(int client)
{
	if(!IsValidClient(client) || !IsAllowClient(client))
		return;

	LoadClient(client);
}

public void SQLCallback_LoadClient(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);

	if(!IsValidClient(client) || !IsAllowClient(client))
		return;
	
	if(hndl == INVALID_HANDLE)
	{
		if(StrContains(error, "lost connection", false) == -1 && CG_GetPlayerID(client) > 0)
		{
			LoadClient(client);
		}

		return;
	}
	
	if(SQL_FetchRow(hndl))
	{
		g_iDiamonds[client] = SQL_FetchInt(hndl, 0);
		g_bPackage[client] = SQL_FetchInt(hndl, 1) == 0 ? true : false;
		g_bLoaded[client] = true;
	}
	else if(IsValidClient(client) && IsAllowClient(client))
	{
		char m_szAuth[32], m_szQuery[256];
		GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
		Format(m_szQuery, 128, "INSERT INTO `playertrack_diamonds` (`playerid`, `dzid`, `steamid`) VALUES ('%d', '%d', '%s');", CG_GetPlayerID(client), CG_GetDiscuzUID(client), m_szAuth);
		SQL_TQuery(g_hDatabase, SQLCallback_NewClient, m_szQuery, GetClientUserId(client));
	}
}

public void SQLCallback_NewClient(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!IsValidClient(client) || !IsAllowClient(client))
		return;

	if(hndl == INVALID_HANDLE)
	{
		if(StrContains(error, "lost connection"))
		{
			LoadClient(client);
		}
		return;
	}
	
	g_bLoaded[client] = true;
	g_iDiamonds[client] = 0;
}

public void SQLCallback_SaveClient(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!IsValidClient(client) || !IsAllowClient(client))
		return;
	
	if(hndl == INVALID_HANDLE)
	{
		LogError("SaveClient: %N  Error: %s", client, error);
	}
}

stock bool IsAllowClient(int client)
{
	if(CG_GetPlayerID(client) < 1)
		return false;
	
	if(CG_GetDiscuzUID(client) < 1)
		return false;
	
	return true;
}