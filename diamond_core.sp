#include <cg_core>
#include <maoling>
#include <csc>

#define PREFIX "[\x10新年快乐\x01]  "

Handle g_hDatabase;

int g_iDiamonds[MAXPLAYERS+1];
bool g_bLoaded[MAXPLAYERS+1];
bool g_bPackage[MAXPLAYERS+1];
bool g_bTradeLnk[MAXPLAYERS+1];

public Plugin myinfo = 
{
    name		= "Diamonds Core",
    author		= "Kyle",
    description	= "",
    version		= "1.1",
    url			= "http://steamcommunity.com/id/_xQy_/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("CG_GetClientDiamond", Native_GetClientDiamond);
	CreateNative("CG_SetClientDiamond", Native_SetClientDiamond);
	
	if(late)
		CG_OnServerLoaded();

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
		if(counts > 9999) counts = 9999;
		int diff = counts - g_iDiamonds[client];
		if(diff != 0)
		{
			g_iDiamonds[client] = counts;
			char m_szAuth[32], m_szQuery[256];
			GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
			Format(m_szQuery, 256, "UPDATE `playertrack_diamonds` SET `diamonds` = `diamonds` + '%d' WHERE `playerid` = '%d' AND `dzid` = '%d' AND `steamid` = '%s'", diff, CG_GetPlayerID(client), CG_GetDiscuzUID(client), m_szAuth);
			SQL_TQuery(g_hDatabase, SQLCallback_SaveClient, m_szQuery, GetClientUserId(client));
			PrintToChat(client, "%s  \x04你%s了\x10 %d钻石 \x04当前剩余\x01: \x10 %d钻石", PREFIX, (diff >= 0) ? "获得" : "失去", diff, g_iDiamonds[client]);
			LoadClient(client); //prevent hack
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
		PrintToChat(client, "%s  未知错误,请联系管理员", PREFIX);
		return;
	}
	
	if(CG_GetDiscuzUID(client) < 1)
	{
		PrintToChat(client, "%s  欲参加此活动请先注册论坛", PREFIX);
		return;
	}
	
	if(!g_bLoaded[client])
	{
		PrintToChat(client, "%s  你的数据尚未加载完毕", PREFIX);
		return;
	}

	Handle menu = CreateMenu(MenuHandler_MainMenu);
	SetMenuTitleEx(menu, "[CG]  新年活动\n钻石: %d\n \n钻石可兑换:\nStore道具\nCSGO钥匙/皮肤\nCG专属道具", g_iDiamonds[client]);

	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "view", "查看活动");
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "earn", "查看奖励");
	AddMenuItemEx(menu, g_iDiamonds[client] >= 200 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED, "keys", "兑换钥匙%s", g_iDiamonds[client] >= 200 ? "[可兑换]" : "[钻石不足]");
	AddMenuItemEx(menu, g_bPackage[client] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED, "pkge", "领取礼包%s", g_bPackage[client] ? "" : "[已领取]");

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
		else if(StrEqual(info, "keys"))
			QueryKeyCount(client);
		else
			PrintToChat(client, "%s  \x04Coming soon...", PREFIX);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

void QueryKeyCount(int client)
{
	if(!IsAllowClient(client) || !g_bLoaded[client])
		return;
	
	char m_szQuery[128], date[32];
	FormatTime(date, 32, "%Y%m%d", GetTime());
	Format(m_szQuery, 128, "SELECT * FROM playertrack_keys WHERE date = '%s'", date);
	SQL_TQuery(g_hDatabase, SQLCallback_QueryKeys, m_szQuery, GetClientUserId(client));
}

void RaffleKey(int client)
{
	PrintToChat(client, "%s  Coming Soon...", PREFIX);
}

void BuildKeysMenu(int client, int keys)
{
	if(!IsAllowClient(client) || !g_bLoaded[client])
		return;
	
	int left = 30 - keys;

	Handle menu = CreateMenu(MenuHandler_KeysMenu);
	SetMenuTitleEx(menu, "[CG]  新年活动 - 兑换CSGO钥匙\n钻石: %d\n今日剩余兑换数量: %d", g_iDiamonds[client], left);

	AddMenuItemEx(menu, left > 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED, "0", "兑换一把CSGO钥匙[200钻石]%s", left > 0 ? "" : "明天再来吧");
	AddMenuItemEx(menu, ITEMDRAW_DISABLED, "1", "抽奖一把CSGO钥匙[20钻石]");
	AddMenuItemEx(menu, ITEMDRAW_DISABLED, "2", "参与CSGO钥匙夺宝[10钻石]");

	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public int MenuHandler_KeysMenu(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		if(!IsAllowClient(client) || !g_bLoaded[client])
			return;
		
		if(!g_bTradeLnk[client])
		{
			tPrintToChat(client, "%s  \x04请先到论坛填写Steam交易链接再来兑换吧", PREFIX);
			return;
		}

		char info[32], name[32];
		GetMenuItem(menu, itemNum, info, 32, _, name, 32);
		
		if(StrEqual(info, "0"))
		{
			PrintToChat(client, "%s  正在处理...", PREFIX);
			char m_szAuth[32], m_szQuery[256];
			GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
			Format(m_szQuery, 256, "SELECT `diamonds` FROM `playertrack_diamonds` WHERE `playerid` = '%d' AND `dzid` = '%d' AND `steamid` = '%s' ORDER BY `playerid` ASC LIMIT 1;", CG_GetPlayerID(client), CG_GetDiscuzUID(client), m_szAuth);
			SQL_TQuery(g_hDatabase, SQLCallback_ExchangeKey, m_szQuery, GetClientUserId(client));
		}
		else if(StrEqual(info, "1"))
			RaffleKey(client);
		else if(StrEqual(info, "1"))
			RaffleKey(client);
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

void ExchangeKey(int client)
{
	if(!IsAllowClient(client) || !g_bLoaded[client])
		return;
	
	if(g_iDiamonds[client] < 200)
	{
		PrintToChat(client, "%s  你的钻石不足", PREFIX);
		return;
	}
	
	char m_szAuth[32], m_szQuery[256];
	GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
	Format(m_szQuery, 256, "UPDATE `playertrack_diamonds` SET `diamonds` = `diamonds` - '200' WHERE `playerid` = '%d' AND `dzid` = '%d' AND `steamid` = '%s' ORDER BY `playerid` ASC LIMIT 1;", CG_GetPlayerID(client), CG_GetDiscuzUID(client), m_szAuth);
	SQL_TQuery(g_hDatabase, SQLCallback_RefreshKey, m_szQuery, GetClientUserId(client));
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
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "每隔5分钟随机抽300信用点/随机皮肤/MVIP/限定皮肤");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "当日在线奖励(60分钟1钻石|150分钟5钻石|300分钟10钻石)");
		}
		case 2:
		{
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "通关神图的幸存者获得随机数量的钻石和信用点");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "通关神图后所有玩家参与抽取皮肤/限定皮肤");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "爆头击杀僵尸即可获得随机数量的钻石或信用点");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "一局爆菊10个人类获得随机数量的钻石或信用点");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "一局伤害输出前五名奖励随机数量钻石或信用点");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "积极断后即可有机会奖励随机数量钻石或信用点");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "救人冰冻[保全2个以上队友]随机奖励钻石或信用点");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "在地图时间累计击杀10只僵尸即可获得钻石或信用点");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "在地图时间累计感染30个人类即可获得钻石或信用点");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "每隔5分钟随机抽夕立改二|普鲁鲁特|艾米莉亚|500信用点");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "当日在线奖励(60分钟2钻石|150分钟8钻石|300分钟15钻石)");
		}
		case 3:
		{
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "刀杀/电死玩家会有概率获得钻石或信用点[击杀狗OP概率翻倍]");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "地图结束时(>25分钟)获得玩家得分*1的信用点|*5%%的钻石");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "每局菠菜获胜的玩家可以选择将信用点转换成钻石");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "每句菠菜失败的玩家有一定概率获得返还信用点");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "投掷物击杀将会获得[15~30]信用点奖励");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "爆头击杀玩家有概率获得[1~50]信用点奖励|[1~3]钻石");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "EndGame中1V1获胜的玩家有概率获得[15~30]信用点奖励");
		}
		case 4:
		{
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "越狱狗OP尚未提交活动策划");
		}
		case 5:
		{
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "每局最多杀敌|最多爆头获得随机信用点");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "5杀随机获得钻石|8杀随机获得钻石+信用点");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "使用电击枪/刀杀随机获得信用点或钻石");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "单幅地图击杀30人以上随机获得钻石或信用点");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "当日在线奖励(60分钟1钻石|150分钟5钻石|300分钟10钻石)");
			AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "每隔5分钟随机抽300信用点/随机皮肤/MVIP/限定皮肤");
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
	g_bTradeLnk[client] = false;
	g_iDiamonds[client] = -1;
}

void LoadClient(int client)
{
	char m_szAuth[32], m_szQuery[256];
	GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
	Format(m_szQuery, 256, "SELECT `diamonds`,`package`,`tradelink` FROM `playertrack_diamonds` WHERE `playerid` = '%d' AND `dzid` = '%d' AND `steamid` = '%s' ORDER BY `playerid` ASC LIMIT 1;", CG_GetPlayerID(client), CG_GetDiscuzUID(client), m_szAuth);
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
		g_bTradeLnk[client] = !SQL_IsFieldNull(hndl, 2);
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
	g_bPackage[client] = true;
	g_bTradeLnk[client] = false;
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

public void SQLCallback_QueryKeys(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!IsValidClient(client) || !IsAllowClient(client))
		return;

	if(hndl == INVALID_HANDLE)
	{
		LogError("QueryKeys: %N  Error: %s", client, error);
		return;
	}
	
	if(!SQL_HasResultSet(hndl))
		return;

	BuildKeysMenu(client, SQL_GetRowCount(hndl));
}

public void SQLCallback_RefreshKey(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!IsValidClient(client) || !IsAllowClient(client))
		return;
	
	if(hndl == INVALID_HANDLE)
	{
		PrintToChat(client, "%s  \x07位置错误0x04\x01,请稍后在试...", PREFIX);
		LogError("RefreshKey: %N  Error: %s", client, error);
		return;
	}

	g_iDiamonds[client] -= 200;

	char m_szAuth[32], m_szQuery[256], date[32];
	FormatTime(date, 32, "%Y%m%d", GetTime());
	GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
	Format(m_szQuery, 256, "INSERT INTO `playertrack_keys` (`playerid`, `dzid`, `steamid`, `date`, `time`) VALUES ('%d', '%d', '%s', '%s', '%d');", CG_GetPlayerID(client), CG_GetDiscuzUID(client), m_szAuth, date, GetTime());
	SQL_TQuery(g_hDatabase, SQLCallback_PorcKey, m_szQuery, GetClientUserId(client));
}

public void SQLCallback_PorcKey(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!IsValidClient(client) || !IsAllowClient(client))
		return;
	
	if(hndl == INVALID_HANDLE)
	{
		int rdm = GetRandomInt(100000, 999999);
		PrintToChat(client, "%s  \x07后台处理请求失败,请立即按下F12保存此截图\x01[\x0Cid\x01: \x04%d\x01]", PREFIX, rdm);
		LogError("client %N  id %d", client, rdm);
		LogError("ExchangeKey: %N  Error: %s", client, error);
		return;
	}

	char fmt[256];
	Format(fmt, 256, "%s  \x0C%N\x04使用活动钻石兑换了一把CSGO钥匙", PREFIX, client);
	CG_Broadcast(false, fmt);

	char m_szQuery[256], m_szName[64];
	CG_GetDiscuzName(client, m_szName, 64);
	Format(m_szQuery, 256, "INSERT INTO `dz_plugin_ahome_laba` (`username`, `tousername`, `level`, `lid`, `dateline`, `content`, `color`, `url`) VALUES ('%s', '', 'game', 0, '%d', '使用活动钻石兑换了一把CSGO钥匙', '', '')", m_szName, GetTime());
	CG_SaveForumData(m_szQuery);

	PrintToChat(client, "%s  \x04兑换成功,你兑换了一个CSGO钥匙", PREFIX);
	PrintToChat(client, "%s  \x04为保证奖品发放,若未在论坛填写steam交易链接,请及时填写", PREFIX);
}

public void SQLCallback_ExchangeKey(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!IsValidClient(client) || !IsAllowClient(client))
		return;
	
	if(hndl == INVALID_HANDLE)
	{
		LogError("ExchangeKey: %N  Error: %s", client, error);
		return;
	}
	
	if(SQL_FetchRow(hndl))
	{
		g_iDiamonds[client] = SQL_FetchInt(hndl, 0);
		ExchangeKey(client);
	}
	else
		PrintToChat(client, "%s  \x07未知错误0x06", PREFIX);
}

stock bool IsAllowClient(int client)
{
	if(CG_GetPlayerID(client) < 1)
		return false;
	
	if(CG_GetDiscuzUID(client) < 1)
		return false;
	
	return true;
}