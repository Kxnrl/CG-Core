#include <sourcemod>
#include <sdktools>
#include <cg_core>
#include <store>

#pragma newdecls required

#define PREFIX "[\x0CCG\x01]  "

bool g_bListener[MAXPLAYERS+1];
char g_szSignature[MAXPLAYERS+1][256];
Handle g_hTimerListner[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = " [CG] Faith Extended ",
	author = "xQy",
	description = "",
	version = "1.5.2rc1",
	url = "http://steamcommunity.com/id/_xQy_/"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_freset", Cmd_FaithReset);
	RegConsoleCmd("sm_fbuffreset", Cmd_BuffReset);
	RegConsoleCmd("sm_fcharge", Cmd_FaithRecharge);
	RegConsoleCmd("sm_qm", Cmd_Signature);
	
	//CreateTimer(120.0, Timer_Boartcast, _, TIMER_REPEAT);
}

public Action Timer_Boartcast(Handle timer)
{
	PrintToChatAll("%s  \x04国庆节活动期间限时开放重置信仰(Faith)功能", PREFIX);
}

public void OnClientPostAdminCheck(int client)
{
	g_bListener[client] = false;
	strcopy(g_szSignature[client], 256, "");
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

public Action Cmd_FaithReset(int client, int args)
{
	if(client == 0)
		return Plugin_Handled;
	
	if(CG_GetClientFaith(client) == 0)
	{
		PrintToChat(client, "%s  你当前没有信仰,怎么重置信仰", PREFIX);
		return Plugin_Handled;
	}
	
	if(CG_GetClientFaith(client) != 0)
	{
		PrintToChat(client, "%s  当前暂不开放重置信仰(Faith)功能", PREFIX);
		return Plugin_Handled;
	}
	
	Handle menu = CreateMenu(ResetFaithonfirmMenuHandler);
	SetMenuTitle(menu, "[CG]   Faith - Reset Faith\n ");
	
	char szItem[256];

	Format(szItem, 256, "你当前的Faith为[%s] - %s \n ", szFaith_NAME[CG_GetClientFaith(client)], szFaith_NATION[CG_GetClientFaith(client)]);
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	int ishare = CG_GetClientShare(client);

	Format(szItem, 256, "你当前拥有Share[%d点]\n ", ishare);
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "我要花费10,000Credits来重置[Share也将会被清空]\n ");
	AddMenuItem(menu, "rest", szItem);
	
	Format(szItem, 256, "我要花费100,000Credits来重置Faith并且保留Share\n ");
	AddMenuItem(menu, "keep", szItem);
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
	return Plugin_Handled;
}

public int ResetFaithonfirmMenuHandler(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		if(StrEqual(info, "rest"))
		{
			if(Store_GetClientCredits(client) < 10000)
			{
				PrintToChat(client, "%s  \x07你的Credits余额不足", PREFIX);
				return;
			}
			PrintToChat(client, "%s  已提交你重置Faith的请求,你需要重进服务器", PREFIX);
			LogMessage("玩家 [%N] 提交了 重置Faith 的请求", client);
			char m_szQuery[256], auth[32];
			GetClientAuthId(client, AuthId_Steam2, auth, 32, true);
			Format(m_szQuery, 256, "UPDATE `playertrack_player` SET faith = 0, share = 0 WHERE id = '%d' AND steamid = '%s'", CG_GetPlayerID(client), auth);
			CG_SaveDatabase(m_szQuery);
			Store_SetClientCredits(client, Store_GetClientCredits(client)-10000, "Faith重置");
			Store_SaveClientAll(client);
		}
		if(StrEqual(info, "keep"))
		{
			if(Store_GetClientCredits(client) < 100000)
			{
				PrintToChat(client, "%s  \x07你的Credits余额不足", PREFIX);
				return;
			}
			PrintToChat(client, "%s  已提交你重置Faith的请求,你需要重进服务器", PREFIX);
			LogMessage("玩家 [%N] 提交了 重置Faith的请求", client);
			char m_szQuery[256], auth[32];
			GetClientAuthId(client, AuthId_Steam2, auth, 32, true);
			Format(m_szQuery, 256, "UPDATE `playertrack_player` SET faith = 0 WHERE id = '%d' AND steamid = '%s'", CG_GetPlayerID(client), auth);
			CG_SaveDatabase(m_szQuery);
			Store_SetClientCredits(client, Store_GetClientCredits(client)-100000, "Faith重置");
			Store_SaveClientAll(client);
		}
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action Cmd_BuffReset(int client, int args)
{
	if(client == 0)
		return Plugin_Handled;
	
	if(CG_GetClientFaith(client) == 0)
	{
		PrintToChat(client, "%s  你当前没有信仰,怎么重置Buff", PREFIX);
		return Plugin_Handled;
	}
	
	int buff = CG_GetSecondBuff(client);
	
	if(buff == 0)
	{
		PrintToChat(client, "%s  你当前没有Buff,不需要重置", PREFIX);
		return Plugin_Handled;
	}
	
	int ishare = CG_GetClientShare(client);
	
	if(ishare < 0)
	{
		PrintToChat(client, "%s  你当前Share为负,无法重置", PREFIX);
		return Plugin_Handled;
	}
	
	Handle menu = CreateMenu(ResetBuffConfirmMenuHandler);
	SetMenuTitle(menu, "[CG]   Faith - Reset Second Buff\n ");

	char szItem[256];

	Format(szItem, 256, "你当前的Faith为[%s] - %s \n ", szFaith_NAME[CG_GetClientFaith(client)], szFaith_NATION[CG_GetClientFaith(client)]);
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	if(buff == 1)
		Format(szItem, 256, "你当前的Buff为[射速]\n 提升除了手雷/匕首之外所有武器5%%的射速\n ");
	else if(buff == 2)
		Format(szItem, 256, "你当前的Buff为[嗜血]\n 你每造成40点(ZE模式为800点)伤害就能恢复2点HP\n ");
	else if(buff == 3)
		Format(szItem, 256, "你当前的Buff为[生命]\n 出生时提升血量和血量上限8%%\n ");
	else if(buff == 4)
		Format(szItem, 256, "你当前的Buff为[护甲]\n 出生时有8%%几率获得重甲|护甲低于10自动补到10\n ");
	else if(buff == 5)
		Format(szItem, 256, "你当前的Buff为[基因]\n 跳跃高度|跳跃距离都提升8%%(不受重力影响)\n ");
	else if(buff == 6)
		Format(szItem, 256, "你当前的Buff为[子弹]\n 你每射出8发(ZE为20)子弹将会往你主弹夹填充2发子弹\n ");
	
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "重置Buff会消耗2000Credits且清空Share[%d点]\n ", ishare);
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "你确定要重置你的Buff吗 ;)");
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	AddMenuItem(menu, "1000", "我确定要更换且清空Share", (Store_GetClientCredits(client) >= 2000) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "我要更换且花费%dCredits来保留我的Share", (ishare*10+2000));
	AddMenuItem(menu, "9999", szItem, (Store_GetClientCredits(client) >= (ishare*10+2000)) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
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
			PrintToChat(client, "%s  已提交你重置Buff的请求,你需要重进服务器", PREFIX);
			LogMessage("玩家 [%N] 提交了 重置Buff 的请求", client);
			char m_szQuery[256], auth[32];
			GetClientAuthId(client, AuthId_Steam2, auth, 32, true);
			Format(m_szQuery, 256, "UPDATE `playertrack_player` SET share = 0, buff = 0 WHERE id = '%d' AND steamid = '%s'", CG_GetPlayerID(client), auth);
			CG_SaveDatabase(m_szQuery);
			Store_SetClientCredits(client, Store_GetClientCredits(client)-2000, "Buff重置");
		}
		if(StrEqual(info, "9999"))
		{
			PrintToChat(client, "%s  已提交你重置Buff的请求,你需要重进服务器", PREFIX);
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
	
	if(1 <= CG_GetClientFaith(client) <= 4)
	{
		PrintToChat(client, "%s  服务器已关闭充值信仰功能,请使用!guild来增加Share", PREFIX);
		return Plugin_Handled;
	}
	
	Handle menu = CreateMenu(FaithChargeMenuHandler);
	SetMenuTitle(menu, "[CG]   充值信仰 \n 你已经为%s贡献了%d点Share\n ", szFaith_NAME[CG_GetClientFaith(client)], CG_GetClientShare(client));
	
	AddMenuItem(menu, "20", "20点Share[400Credits]");
	AddMenuItem(menu, "50", "50点Share[1,000Credits]");
	AddMenuItem(menu, "100", "100点Share[2,000Credits]");
	AddMenuItem(menu, "200", "200点Share[4,000Credits]");
	AddMenuItem(menu, "500", "500点Share[10,000Credits]");
	AddMenuItem(menu, "1000", "1000点Share[20,000Credits]");
	AddMenuItem(menu, "2000", "2000点Share[40,000Credits]");
	AddMenuItem(menu, "5000", "5000点Share[100,000Credits]");
	AddMenuItem(menu, "-9999", "什么? 不够? 老板你的信仰已经很充足了", ITEMDRAW_DISABLED);
	
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

		CG_GiveClientShare(client, ishare, "充值信仰");
		Store_SetClientCredits(client, Store_GetClientCredits(client)-icredits, "充值信仰");
		PrintToChat(client, "[%s]  \x04已收到你充值的信仰\x0C %d \x04点[立即生效]", szFaith_CNAME[CG_GetClientFaith(client)], ishare);
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
	SetMenuTitle(menu, "[CG^  签名设置  \n设置签名需要500Credits[首次免费] \n ");

	char szItem[256];
	
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
			Handle database = CG_GetGameDatabase();
			
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
			PrintToChat(client, "%s  已成功设置您的签名,花费了\x04500Credits", PREFIX);
			char szPreview[256];
			strcopy(szPreview, 256, g_szSignature[client]);
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
	
	strcopy(g_szSignature[client], 256, sArgs);
	
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