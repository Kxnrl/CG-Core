#include <sourcemod>
#include <sdktools>
#include <cg_core>
#include <store>

#pragma newdecls required

#define PREFIX "[\x0EPlaneptune\x01]  "

bool g_bListener[MAXPLAYERS+1];
char g_szSignature[MAXPLAYERS+1][256];
Handle g_hTimerListner[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = " [CG] Faith Extended ",
	author = "xQy",
	description = "",
	version = "1.5",
	url = "http://steamcommunity.com/id/_xQy_/"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_freset", Cmd_BuffReset);
	RegConsoleCmd("sm_fcharge", Cmd_FaithRecharge);
	RegConsoleCmd("sm_qianming", Cmd_Signature);
	RegConsoleCmd("sm_qm", Cmd_Signature);
	RegConsoleCmd("qm", Cmd_Signature);
}

public void OnClientPostAdminCheck(int client)
{
	g_bListener[client] = false;
	Format(g_szSignature[client], 256, "");
	g_hTimerListner[client] = INVALID_HANDLE;
}

public void OnClientDisconnect(int client)
{
	if(g_hTimerListner[client] != INVALID_HANDLE)
	{
		KillTimer(g_hTimerListner[client]);
		g_hTimerListner[client] = INVALID_HANDLE;
	}
}

public Action Cmd_BuffReset(int client, int args)
{
	if(client == 0)
		return Plugin_Handled;
	
	if(CG_GetClientFaith(client) == 0)
	{
		PrintToChat(client, "%s  你当前没有Faith,怎么重置Buff", PREFIX);
		return Plugin_Handled;
	}
	
	int buff = CG_GetSecondBuff(client);
	
	if(buff == 0)
	{
		PrintToChat(client, "%s  你当前没有Buff,不需要重置", PREFIX);
		return Plugin_Handled;
	}
	
	if(Store_GetClientCredits(client) < 5000)
	{
		PrintToChat(client, "%s  \x04Credits\x07余额不足,请先到论坛氪金再来进行Faith重置", PREFIX);
		return Plugin_Handled;
	}
	
	Handle menu = CreateMenu(ResetBuffConfirmMenuHandler);
	char szItem[256];
	Format(szItem, 256, "[Planeptune]   Faith - Reset Second Buff\n \n ");
	SetMenuTitle(menu, szItem);

	Format(szItem, 256, "你当前的Faith为[%s] - %s \n ", szFaith_NAME[CG_GetClientFaith(client)], szFaith_NATION[CG_GetClientFaith(client)]);
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	if(buff == 1)
		Format(szItem, 256, "你当前的Buff为[射速]\n 提升除了手雷/匕首之外所有武器5%%的射速\n ");
	else if(buff == 2)
		Format(szItem, 256, "你当前的Buff为[嗜血]\n 你每造成40点(ZE模式为800点)伤害就能恢复2点HP\n ");
	else if(buff == 3)
		Format(szItem, 256, "你当前的Buff为[生命]\n 出生时提升血量和血量上限8%%(僵尸无效)\n ");
	else if(buff == 4)
		Format(szItem, 256, "你当前的Buff为[护甲]\n 出生时有8%%几率获得重甲|护甲低于10自动补到10\n ");
	else if(buff == 5)
		Format(szItem, 256, "你当前的Buff为[基因]\n 跳跃高度|跳跃距离都提升8%%(不受重力影响)\n ");
	else if(buff == 6)
		Format(szItem, 256, "你当前的Buff为[子弹]\n 你每射出8发(ZE为20)子弹将会往你主弹夹填充2发子弹\n ");
	
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "重置Buff会消耗2000Credits且清空Share[%d点]\n ", CG_GetClientShare(client));
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "你确定要重置你的Buff吗 ;)");
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	AddMenuItem(menu, "1000", "我确定要更换且清空Share");
	
	Format(szItem, 256, "我要更换且花费%dCredits来保留我的Share", (CG_GetClientShare(client)*10+2000));
	AddMenuItem(menu, "9999", szItem);
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
	
	return Plugin_Handled;
}

public int ResetBuffConfirmMenuHandler(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		if(StrEqual(info, "1000"))
		{
			PrintToChat(client, "%s  已提交你重置Buff的请求", PREFIX);
			LogMessage("玩家 [%N] 提交了 重置Buff 的请求", client);
			char m_szQuery[256], auth[32];
			GetClientAuthId(client, AuthId_Steam2, auth, 32, true);
			Format(m_szQuery, 256, "UPDATE `playertrack_player` SET share = 0, buff = 0 WHERE id = '%d' AND steamid = '%s'", CG_GetPlayerID(client), auth);
			CG_SaveDatabase(m_szQuery);
			Store_SetClientCredits(client, Store_GetClientCredits(client)-2000, "Buff重置");
		}
		if(StrEqual(info, "9999"))
		{
			PrintToChat(client, "%s  已提交你重置Buff的请求", PREFIX);
			LogMessage("玩家 [%N] 提交了 重置Buff 的请求", client);
			char m_szQuery[256], auth[32];
			GetClientAuthId(client, AuthId_Steam2, auth, 32, true);
			Format(m_szQuery, 256, "UPDATE `playertrack_player` SET buff = 0 WHERE id = '%d' AND steamid = '%s'", CG_GetPlayerID(client), auth);
			CG_SaveDatabase(m_szQuery);
			Store_SetClientCredits(client, Store_GetClientCredits(client)-(CG_GetClientShare(client)*10+2000), "Buff重置");
		}
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action Cmd_FaithRecharge(int client, int args)
{
	if(client == 0 || PA_GetGroupID(client) == 9998)
		return Plugin_Handled;
	
	if(CG_GetClientFaith(client) == 0)
	{
		PrintToChat(client, "%s  你当前没有Faith, 充值个蛰蛰", PREFIX);
		return Plugin_Handled;
	}
	
	if(Store_GetClientCredits(client) < 20000)
	{
		PrintToChat(client, "%s  \x04Credits\x07余额不足,请先到论坛氪金(需要你存款20,000以上)", PREFIX);
		return Plugin_Handled;
	}
	
	Handle menu = CreateMenu(FaithChargeMenuHandler);
	char szItem[256];
	Format(szItem, 256, "[Planeptune]   充值信仰 \n 你已经为%s贡献了%d点Share\n ", szFaith_NAME[CG_GetClientFaith(client)], CG_GetClientShare(client));
	SetMenuTitle(menu, szItem);
	
	Format(szItem, 256, "20点Share[400Credits]");
	AddMenuItem(menu, "20", szItem);
	
	Format(szItem, 256, "50点Share[1,000Credits]");
	AddMenuItem(menu, "50", szItem);
	
	Format(szItem, 256, "100点Share[2,000Credits]");
	AddMenuItem(menu, "100", szItem);
	
	Format(szItem, 256, "200点Share[4,000Credits]");
	AddMenuItem(menu, "200", szItem);
	
	Format(szItem, 256, "500点Share[10,000Credits]");
	AddMenuItem(menu, "500", szItem);
	
	Format(szItem, 256, "1000点Share[20,000Credits]");
	AddMenuItem(menu, "1000", szItem);
	
	Format(szItem, 256, "2000点Share[40,000Credits]");
	AddMenuItem(menu, "2000", szItem);
	
	Format(szItem, 256, "5000点Share[100,000Credits]");
	AddMenuItem(menu, "5000", szItem);
	
	Format(szItem, 256, "什么? 不够? 老板你的信仰已经很充足了");
	AddMenuItem(menu, "-9999", szItem, ITEMDRAW_DISABLED);
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
	
	return Plugin_Handled;
}

public int FaithChargeMenuHandler(Handle menu, MenuAction action, int client, int itemNum)
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		int ishare = StringToInt(info);
		int icredits = ishare*20;
		
		if(Store_GetClientCredits(client) < icredits)
		{
			PrintToChat(client, "%s  \x04Credits\x07余额不足,请先到论坛氪金", PREFIX);
			return;
		}

		char m_szQuery[256], auth[32];
		GetClientAuthId(client, AuthId_Steam2, auth, 32, true);
		CG_GiveClientShare(client, ishare);
		Format(m_szQuery, 256, "UPDATE store_players SET `credits`=`credits`-%d WHERE `authid`='%s'", icredits, auth[8]);
		CG_SaveDatabase(m_szQuery);
		Format(m_szQuery, 256, "INSERT INTO store_logs (player_id, credits, reason, date) VALUES((SELECT id FROM store_players WHERE `authid`='%s'), %d, '充值信仰', %d)", auth[8], icredits, GetTime());
		CG_SaveDatabase(m_szQuery);
		PrintToChat(client, "[%s]  \x04已收到你充值的信仰\x0C %d \x04点", szFaith_CNAME[CG_GetClientFaith(client)], ishare);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action Cmd_Signature(int client, int args)
{
	char szSignature[256];
	CG_GetSignature(client, szSignature, 256);
	
	if(StrContains(szSignature, "该玩家未设置签名") != -1)
	{
		PrintToChat(client, "%s   %s大赦天下,首次设置签名免费!", PREFIX, szFaith_CNATION[PURPLE]);
		ShowListenerMenu(client);
		return Plugin_Handled;
	}
	
	if(Store_GetClientCredits(client) < 500)
	{
		PrintToChat(client, "%s  Credits余额不足,不能设置签名", PREFIX);
		return Plugin_Handled;
	}
	
	ShowListenerMenu(client);
	
	return Plugin_Handled;
}

void ShowListenerMenu(int client)
{
	Handle menu = CreateMenu(ListenerMenuHandler);
	char szItem[256];
	Format(szItem, 256, "^[Planeptune]^  签名设置  \n设置签名需要500Credits[首次免费] \n ");
	SetMenuTitle(menu, szItem);

	Format(szItem, 256, "你现在可以按Y输入签名了 \n ");
	
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "可用颜色代码\n {亮红} {黄} {蓝} {绿} {橙} {紫} {粉} \n ");
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "例如: {蓝}陈{红}抄{黄}封{紫}不{粉}要{绿}脸 \n ");
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "你当前已输入: \n %s\n", g_szSignature[client]);
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	AddMenuItem(menu, "preview", "查看预览");
	AddMenuItem(menu, "ok", "我写好了");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 120);
	
	if(g_hTimerListner[client] != INVALID_HANDLE)
	{
		KillTimer(g_hTimerListner[client]);
		g_hTimerListner[client] = INVALID_HANDLE;
	}

	g_bListener[client] = true;
	g_hTimerListner[client] = CreateTimer(120.0, Timer_Timeout, GetClientUserId(client));
}

public int ListenerMenuHandler(Handle menu, MenuAction action, int client, int itemNum)
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		g_bListener[client] = false;
		if(g_hTimerListner[client] != INVALID_HANDLE)
		{
			KillTimer(g_hTimerListner[client]);
			g_hTimerListner[client] = INVALID_HANDLE;
		}
		
		if(StrEqual(info, "preview"))
		{
			char szPreview[256];
			szPreview = g_szSignature[client];
			ReplaceString(szPreview, 512, "{白}", "\x01");
			ReplaceString(szPreview, 512, "{红}", "\x02");
			ReplaceString(szPreview, 512, "{粉}", "\x03");
			ReplaceString(szPreview, 512, "{绿}", "\x04");
			ReplaceString(szPreview, 512, "{黄}", "\x05");
			ReplaceString(szPreview, 512, "{亮绿}", "\x06");
			ReplaceString(szPreview, 512, "{亮红}", "\x07");
			ReplaceString(szPreview, 512, "{灰}", "\x08");
			ReplaceString(szPreview, 512, "{褐}", "\x09");
			ReplaceString(szPreview, 512, "{橙}", "\x10");
			ReplaceString(szPreview, 512, "{紫}", "\x0E");
			ReplaceString(szPreview, 512, "{亮蓝}", "\x0B");
			ReplaceString(szPreview, 512, "{蓝}", "\x0C");
			PrintToChat(client, "签名预览: %s", szPreview);
			ShowListenerMenu(client);
		}
		if(StrEqual(info, "ok"))
		{
			if(Store_GetClientCredits(client) < 500)
			{
				PrintToChat(client, "%s  Credits余额不足,不能设置签名", PREFIX);
				return;
			}
			
			Store_SetClientCredits(client, Store_GetClientCredits(client)-500, "设置签名");
			
			char Error[256];
			Handle database = SQL_Connect("csgo", true, Error, 256);
			
			if(database == INVALID_HANDLE)
			{
				PrintToChat(client, "%s  当前服务器网络异常,请稍候再试", PREFIX);
				return;
			}
			
			char auth[32], eSignature[512], m_szQuery[1024];
			GetClientAuthId(client, AuthId_Steam2, auth, 32, true);
			SQL_EscapeString(database, g_szSignature[client], eSignature, 512);
			Format(m_szQuery, 512, "UPDATE `playertrack_player` SET signature = '%s' WHERE id = '%d' and steamid = '%s'", eSignature, CG_GetPlayerID(client), auth);
			CG_SaveDatabase(m_szQuery);
			CloseHandle(database);
			PrintToChat(client, "%s  已成功设置您的签名,花费了\x04500Credits", PREFIX);
			char szPreview[256];
			szPreview = g_szSignature[client];
			ReplaceString(szPreview, 512, "{白}", "\x01");
			ReplaceString(szPreview, 512, "{红}", "\x02");
			ReplaceString(szPreview, 512, "{粉}", "\x03");
			ReplaceString(szPreview, 512, "{绿}", "\x04");
			ReplaceString(szPreview, 512, "{黄}", "\x05");
			ReplaceString(szPreview, 512, "{亮绿}", "\x06");
			ReplaceString(szPreview, 512, "{亮红}", "\x07");
			ReplaceString(szPreview, 512, "{灰}", "\x08");
			ReplaceString(szPreview, 512, "{褐}", "\x09");
			ReplaceString(szPreview, 512, "{橙}", "\x10");
			ReplaceString(szPreview, 512, "{紫}", "\x0E");
			ReplaceString(szPreview, 512, "{亮蓝}", "\x0B");
			ReplaceString(szPreview, 512, "{蓝}", "\x0C");
			PrintToChat(client, "您的签名: %s", szPreview);
		}
	}
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if(!g_bListener[client])
		return Plugin_Continue;
	
	Format(g_szSignature[client], 256, "%s", sArgs);
	
	PrintToChat(client, "您输入了: %s", sArgs);
	
	g_bListener[client] = false;
	if(g_hTimerListner[client] != INVALID_HANDLE)
	{
		KillTimer(g_hTimerListner[client]);
		g_hTimerListner[client] = INVALID_HANDLE;
	}
	
	ShowListenerMenu(client);

	return Plugin_Handled;
}

public Action Timer_Timeout(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	g_bListener[client] = false;
	g_hTimerListner[client] = INVALID_HANDLE;
}