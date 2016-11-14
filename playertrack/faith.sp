public void SetClientFaith(int client, int faith)
{
	//没加载完就不需要设置Faith了是吧
	if(!g_eClient[client][bLoaded])
	{
		PrintToChat(client, "%s  很抱歉,你的数据尚未加载完毕", PLUGIN_PREFIX);
		return;
	}
	
	g_eClient[client][iFaith] = faith;
	
	//设置完总得同步到数据库吧
	char m_szQuery[256];
	Format(m_szQuery, 256, "UPDATE `playertrack_player` SET faith = '%d' WHERE id = '%d'", faith, g_eClient[client][iPlayerId]);
	SQL_TQuery(g_hDB_csgo, SQLCallback_SetFaith, m_szQuery, GetClientUserId(client));
}

public void BuildFaithFirstMenu(int client)
{
	//初始选择菜单
	Handle menu = CreateMenu(MenuHandler_FaithFirstMenu);
	SetMenuTitle(menu, "[CG]   Faith - Select\n　");
	
	AddMenuItem(menu, "", "目前系统检测到你的Faith为空[输入!fhelp了解更多]", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "", "选择1个Faith以获得Buff[暂时不能更换]", ITEMDRAW_DISABLED);
	
	char m_szItem[256];

	Format(m_szItem, 256, "[%s - %s] - Buff: 速度  Guardian: 猫灵", szFaith_NATION[PURPLE], szFaith_NAME[PURPLE]);
	AddMenuItem(menu, "purple", m_szItem);
	
	Format(m_szItem, 256, "[%s - %s] - Buff: 暴击  Guardian: 曼妥思", szFaith_NATION[BLACK], szFaith_NAME[BLACK]);
	AddMenuItem(menu, "black", m_szItem);
	
	Format(m_szItem, 256, "[%s - %s] - Buff: 伤害  Guardian: 色拉", szFaith_NATION[WHITE], szFaith_NAME[WHITE]);
	AddMenuItem(menu, "white", m_szItem);

	Format(m_szItem, 256, "[%s - %s] - Buff: 闪避  Guardian: 基佬桐", szFaith_NATION[GREEN], szFaith_NAME[GREEN]);
	AddMenuItem(menu, "green", m_szItem);

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public int MenuHandler_FaithFirstMenu(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		if(StrEqual(info, "purple"))
			ConfirmSelect(client, PURPLE);
		else if(StrEqual(info, "black"))
			ConfirmSelect(client, BLACK);
		else if(StrEqual(info, "white"))
			ConfirmSelect(client, WHITE);
		else if(StrEqual(info, "green"))
			ConfirmSelect(client, GREEN);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public int MenuHandler_FaithHelp(Handle menu, MenuAction action, int client, int itemNum) 
{
	
}

public void ConfirmSelect(int client, int faith)
{
	//确认选择菜单
	Handle menu = CreateMenu(MenuHandler_FaithConfirm);
	SetMenuTitle(menu, "[CG]   Faith - Confirm\n　");
	
	char m_szItem[128];
	if(faith == 1)
	{
		Format(m_szItem, 128, "你选择的是 [%s - %s]", szFaith_NATION[faith], szFaith_NAME[faith]);
		AddMenuItem(menu, "", m_szItem, ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "Buff类型 [速度]", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "Guardian [猫灵]", ITEMDRAW_DISABLED);
	}
	if(faith == 2)
	{
		Format(m_szItem, 128, "你选择的是 [%s - %s]", szFaith_NATION[faith], szFaith_NAME[faith]);
		AddMenuItem(menu, "", m_szItem, ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "Buff类型 [暴击]", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "Guardian [MTS.]", ITEMDRAW_DISABLED);
	}
	if(faith == 3)
	{
		Format(m_szItem, 128, "你选择的是 [%s - %s]", szFaith_NATION[faith], szFaith_NAME[faith]);
		AddMenuItem(menu, "", m_szItem, ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "Buff类型 [伤害]", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "Guardian [色拉]", ITEMDRAW_DISABLED);
	}
	if(faith == 4)
	{
		Format(m_szItem, 128, "你选择的是 [%s - %s]", szFaith_NATION[faith], szFaith_NAME[faith]);
		AddMenuItem(menu, "", m_szItem, ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "Buff类型 [闪避]", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "Guardian [桐子]", ITEMDRAW_DISABLED);
	}

	Format(m_szItem, 128, "Faith不能更改, 你确定你的选择吗:)\n　");
	AddMenuItem(menu, "", m_szItem, ITEMDRAW_DISABLED);
	
	Format(m_szItem, 128, "%d", faith);
	AddMenuItem(menu, m_szItem, "我确定");
	AddMenuItem(menu, "0", "我拒绝");

	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 0);
}

public int MenuHandler_FaithConfirm(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		int faith = StringToInt(info);
		
		if(faith > 0)
			SetClientFaith(client, faith);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if(action == MenuAction_Cancel && itemNum == MenuCancel_ExitBack)
	{
		BuildFaithFirstMenu(client);
	}
}

public void BuildFaithMainMenu(int client)
{
	if(!(0 < g_eClient[client][iFaith] <= FAITH_COUNTS))
	{
		BuildFaithFirstMenu(client);
		return;
	}
	
	Handle menu = CreateMenu(MenuHandler_FaithMain);
	SetMenuTitle(menu, "[CG]   Faith - Main\n \n当前归属: %s - %s\n当前Share: %d\n　", szFaith_NATION[g_eClient[client][iFaith]], szFaith_NAME[g_eClient[client][iFaith]], g_eClient[client][iShare]);

	AddMenuItem(menu, "fhelp", "关于Faith系统说明");
	AddMenuItem(menu, "share", "查看当前Share数据");
	AddMenuItem(menu, "fbuff", "查看各个Faith的Buff");
	AddMenuItem(menu, "guild", "承接任务以增加Sahre");
	AddMenuItem(menu, "rank", "查看你的Share排行");
	AddMenuItem(menu, "inves", "投资系统[Alpha测试]");
	AddMenuItem(menu, "freset", "国庆限时重选Faith", ITEMDRAW_DISABLED);

	if(g_eClient[client][iBuff] <= 0)
		AddMenuItem(menu, "reset", "初次设置副Buff");
	else
		AddMenuItem(menu, "reset", "重新选择副Buff");

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public int MenuHandler_FaithMain(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		if(StrEqual(info, "fhelp"))
			Command_FHelp(client, 0);
		else if(StrEqual(info, "share"))
			ShowAllFaithShareToClient(client);
		else if(StrEqual(info, "fbuff"))
			ShowAllFaithBuffToClient(client);
		else if(StrEqual(info, "guild"))
			FakeClientCommandEx(client, "sm_guild");
		else if(StrEqual(info, "inves"))
			BuildInvestmentMenu(client);
		else if(StrEqual(info, "freset"))
			FakeClientCommandEx(client, "sm_freset");
		else if(StrEqual(info, "reset"))
		{
			if(g_eClient[client][iBuff] <= 0)
				CheckClientBuff(client);
			else
				FakeClientCommandEx(client, "sm_fbuffreset");
		}		
		else if(StrEqual(info, "charge"))
			FakeClientCommandEx(client, "sm_fcharge");
		else if(StrEqual(info, "rank"))
			ShowFaithShareRankToClient(client);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public void ShowAllFaithShareToClient(int client)
{
	Handle menu = CreateMenu(MenuHandler_FaithShowAllShare);
	SetMenuTitle(menu, "[CG]   Faith -  查看各个Faith的Share值\n　");

	float share[5];
	share[ALLSHARE] = float(g_Share[PURPLE]+g_Share[BLACK]+g_Share[WHITE]+g_Share[GREEN]);
	share[PURPLE] = (float(g_Share[PURPLE])/share[ALLSHARE])*100;
	share[BLACK] = (float(g_Share[BLACK])/share[ALLSHARE])*100;
	share[WHITE] = (float(g_Share[WHITE])/share[ALLSHARE])*100;
	share[GREEN] = (float(g_Share[GREEN])/share[ALLSHARE])*100;
	
	char m_szItem[256];

	Format(m_szItem, 256, "[Purple] - Share %d [%.2f%% of %d]", g_Share[PURPLE], share[PURPLE], RoundToFloor(share[ALLSHARE]));
	AddMenuItem(menu, "", m_szItem, ITEMDRAW_DISABLED);
	
	Format(m_szItem, 256, "[Black] - Share %d [%.2f%% of %d]", g_Share[BLACK], share[BLACK], RoundToFloor(share[ALLSHARE]));
	AddMenuItem(menu, "", m_szItem, ITEMDRAW_DISABLED);
	
	Format(m_szItem, 256, "[White] - Share %d [%.2f%% of %d]", g_Share[WHITE], share[WHITE], RoundToFloor(share[ALLSHARE]));
	AddMenuItem(menu, "", m_szItem, ITEMDRAW_DISABLED);
	
	Format(m_szItem, 256, "[Green] - Share %d [%.2f%% of %d]", g_Share[GREEN], share[GREEN], RoundToFloor(share[ALLSHARE]));
	AddMenuItem(menu, "", m_szItem, ITEMDRAW_DISABLED);
	
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 60);
	
	ShowFaithOfferToClient(client);
}

public int MenuHandler_FaithShowAllShare(Handle menu, MenuAction action, int client, int itemNum) 
{
	
}

public void ShowAllFaithBuffToClient(int client)
{
	Handle menu = CreateMenu(MenuHandler_FaithShowAllBuff);
	SetMenuTitle(menu, "[CG]   Faith -  查看各个Faith的Buff\n　");
	
	char m_szItem[256];

	Format(m_szItem, 256, "[%s - %s] - Buff: 速度", szFaith_NATION[PURPLE], szFaith_NAME[PURPLE]);
	AddMenuItem(menu, "purple", m_szItem, ITEMDRAW_DISABLED);
	
	Format(m_szItem, 256, "[%s - %s] - Buff: 暴击", szFaith_NATION[BLACK], szFaith_NAME[BLACK]);
	AddMenuItem(menu, "black", m_szItem, ITEMDRAW_DISABLED);
	
	Format(m_szItem, 256, "[%s - %s] - Buff: 伤害", szFaith_NATION[WHITE], szFaith_NAME[WHITE]);
	AddMenuItem(menu, "white", m_szItem, ITEMDRAW_DISABLED);

	Format(m_szItem, 256, "[%s - %s] - Buff: 闪避", szFaith_NATION[GREEN], szFaith_NAME[GREEN]);
	AddMenuItem(menu, "green", m_szItem, ITEMDRAW_DISABLED);

	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public int MenuHandler_FaithShowAllBuff(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Cancel && itemNum == MenuCancel_ExitBack)
	{
		BuildFaithMainMenu(client);
	}
}

public void ShowFaithOfferToClient(int client)
{
	float vol = (float(g_eClient[client][iShare])/float(g_Share[g_eClient[client][iFaith]]))*100;
	PrintToChat(client, "[%s]  你个人贡献的Share为\x0C%d\x01点[%.2f%% of %d - %s]", szFaith_CNAME[g_eClient[client][iFaith]], g_eClient[client][iShare], vol, g_Share[g_eClient[client][iFaith]], szFaith_CNATION[g_eClient[client][iFaith]]);
}

public void ShowFaithShareRankToClient(int client)
{
	char sQuery[512];
	Format(sQuery, 512, "SELECT `name`, `share` FROM `playertrack_player` WHERE `faith` = '%d' ORDER BY `share` DESC LIMIT 50;", g_eClient[client][iFaith]);
	SQL_TQuery(g_hDB_csgo, SQLCallback_FaithShareRank, sQuery, g_eClient[client][iUserId]);
}

void ShareRankToMenu(int client, Handle pack)
{
	char m_szItem[256], sName[128];
	Handle hMenu = CreateMenu(MenuHandler_FaithRank);

	Format(m_szItem, 256, "[CG]   Faith Share Rank - %s \n　", szFaith_NAME[g_eClient[client][iFaith]]);
	SetMenuTitle(hMenu, m_szItem);

	SetMenuExitButton(hMenu, true);
	SetMenuExitBackButton(hMenu, false);

	ResetPack(pack);
	
	int iCount = ReadPackCell(pack);

	for(int i = 0; i < iCount; ++i)
	{
		ReadPackString(pack, sName, 128);
		int ishare = ReadPackCell(pack);
		float vol = (float(ishare)/float(g_Share[g_eClient[client][iFaith]]))*100;
		Format(m_szItem, 128, "#%d   %s  %d[%.2f%% of %d - %s]", i+1, sName, ishare, vol, g_Share[g_eClient[client][iFaith]], szFaith_NATION[g_eClient[client][iFaith]]);
		AddMenuItem(hMenu, "", m_szItem, ITEMDRAW_DISABLED);
	}

	CloseHandle(pack);
	DisplayMenu(hMenu, client, 60);
}

public int MenuHandler_FaithRank(Handle menu, MenuAction action, int client, int itemNum)
{

}

void CheckClientBuff(int client)
{
	if(g_eClient[client][iFaith] <= 0 || g_eClient[client][iBuff] > 0)
		return;

	Handle menu = CreateMenu(MenuHandler_FaithSecondBuff);
	SetMenuTitle(menu, "[CG]   Faith -  Second Buff\n　");
	
	AddMenuItem(menu, "", "系统侦测到当前你未设置副Buff", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "", "副Buff加成为定值,不受Faith和Share影响", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "", "副Buff只有在你的Share大于1000点时才会激活", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "", "修改副Buff每次需要5000Credits", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "", "你现在要设置吗?", ITEMDRAW_DISABLED);

	AddMenuItem(menu, "yes", "设置");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public int MenuHandler_FaithSecondBuff(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		if(StrEqual(info, "yes"))
			ShowSecondBuffToClient(client);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

void ShowSecondBuffToClient(int client)
{
	Handle menu = CreateMenu(MenuHandler_FaithSecondSelect);
	SetMenuTitle(menu, "[CG]   Faith -  Second Buff\n　");
	
	AddMenuItem(menu, "1", "射速 [提高除了匕首和手雷之外枪械的射速]");
	AddMenuItem(menu, "2", "嗜血 [造成40点伤害(ZE为800)后恢复2点HP]");
	AddMenuItem(menu, "3", "生命 [提升当前血量和血量上限8%的生命值]");
	AddMenuItem(menu, "4", "护甲 [几率获得重甲护甲低于10自动补到10]");
	AddMenuItem(menu, "5", "基因 [提升↑10%跳跃高度和跳跃距离的能力]");
	AddMenuItem(menu, "6", "子弹 [每射击一定次数会给主弹夹补充子弹]");
	
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public int MenuHandler_FaithSecondSelect(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		ConfirmSecondBuff(client, StringToInt(info));
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if(action == MenuAction_Cancel && itemNum == MenuCancel_ExitBack)
	{
		CheckClientBuff(client);
	}
}

void ConfirmSecondBuff(int client, int buff)
{
	Handle menu = CreateMenu(MenuHandler_FaithSecondConfirm);
	SetMenuTitle(menu, "[CG]   Faith -  Second Buff\n　");
	
	if(buff == 1)
	{
		AddMenuItem(menu, "", "你选择的Buff是: 射速", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "提升除了手雷/匕首之外所有武器5%的射速", ITEMDRAW_DISABLED);
	}
	else if(buff == 2)
	{
		AddMenuItem(menu, "", "你选择的Buff是: 嗜血", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "你每造成30点(ZE模式为500点)伤害就能恢复2点HP", ITEMDRAW_DISABLED);
	}
	else if(buff == 3)
	{
		AddMenuItem(menu, "", "你选择的Buff是: 生命", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "出生时提升血量和血量上限10%", ITEMDRAW_DISABLED);
	}
	else if(buff == 4)
	{
		AddMenuItem(menu, "", "你选择的Buff是: 护甲", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "出生时有8%几率获得重甲|护甲低于10自动补到10", ITEMDRAW_DISABLED);
	}
	else if(buff == 5)
	{
		AddMenuItem(menu, "", "你选择的Buff是: 基因", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "跳跃高度|跳跃距离都提升8%(不受重力影响)", ITEMDRAW_DISABLED);
	}
	else if(buff == 6)
	{
		AddMenuItem(menu, "", "你选择的Buff是: 子弹", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "你每射出10发(ZE为30)子弹将会往你主弹夹填充2发子弹", ITEMDRAW_DISABLED);
	}

	AddMenuItem(menu, "", "修改子Buff每次需要5000Credits", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "", "你现在要设置吗?", ITEMDRAW_DISABLED);
	
	AddMenuItem(menu, "0", "我要重新选一个");
	
	char m_szItem[4];
	Format(m_szItem, 4, "%d", buff);
	AddMenuItem(menu, m_szItem, "不选了就这个吧");

	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 0);
}

public int MenuHandler_FaithSecondConfirm(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		int buff = StringToInt(info);
		
		if(buff > 0)
			SetClientBuff(client, buff);
		else
			ShowSecondBuffToClient(client);
	}
	else if(action == MenuAction_Cancel && itemNum == MenuCancel_ExitBack)
	{
		ShowSecondBuffToClient(client);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

void SetClientBuff(int client, int buff)
{
	if(!g_eClient[client][bLoaded])
	{
		PrintToChat(client, "%s  很抱歉,你的数据尚未加载完毕", PLUGIN_PREFIX);
		return;
	}

	g_eClient[client][iBuff] = buff;

	char m_szQuery[256];
	Format(m_szQuery, 256, "UPDATE `playertrack_player` SET buff = '%d' WHERE id = '%d'", buff, g_eClient[client][iPlayerId]);
	SQL_TQuery(g_hDB_csgo, SQLCallback_SetBuff, m_szQuery, GetClientUserId(client));
}

void BuildInvestmentMenu(int client)
{
	Handle menu = CreateMenu(MenuHandler_InvestmentConfirm);
	SetMenuTitle(menu, "[CG]   Faith - Investment [developer preview]\n　");
	
	AddMenuItem(menu, "", "因Invesment仍处于开发者预览功能", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "", "进入Invesment之后任意操作都是不可逆的", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "", "有可能会导致Share/Credits增减或者回档", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "", "你确定要进入投资系统吗", ITEMDRAW_DISABLED);

	AddMenuItem(menu, "sure", "我已经明白风险,且确定进入");
	AddMenuItem(menu, "back", "我承担不起风险,我选择返回");

	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 0);
}

public int MenuHandler_InvestmentConfirm(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		if(StrEqual(info, "sure"))
		{
			Handle menu2 = CreateMenu(MenuHandler_InvestmentConfirm2);
			SetMenuTitle(menu2, "[CG]   Faith - Investment [developer preview]\n　");
			
			AddMenuItem(menu2, "", "我已经做好了承担后果的准备", ITEMDRAW_DISABLED);
			AddMenuItem(menu2, "", "一旦出现问题后果都是我自己承担", ITEMDRAW_DISABLED);
			AddMenuItem(menu2, "", "我不会麻烦管理员处理有关此的问题", ITEMDRAW_DISABLED);
			AddMenuItem(menu2, "back", "我承担不起风险,我选择返回");
			AddMenuItem(menu2, "back", "我承担不起风险,我选择返回");
			AddMenuItem(menu2, "sure", "我同意以上使用协议并进入");

			SetMenuExitBackButton(menu2, true);
			SetMenuExitButton(menu2, false);
			DisplayMenu(menu2, client, 0);
		}
		else
		{
			BuildFaithMainMenu(client);
		}
	}
	else if(action == MenuAction_Cancel && itemNum == MenuCancel_ExitBack)
	{
		BuildFaithMainMenu(client);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public int MenuHandler_InvestmentConfirm2(Handle menu, MenuAction action, int client, int itemNum)
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		if(StrEqual(info, "sure"))
		{
			char m_szQuery[128];
			Format(m_szQuery, 128, "SELECT * FROM playertrack_investment WHERE playerid = %d", g_eClient[client][iPlayerId]);
			SQL_TQuery(g_hDB_csgo, SQLCallback_InvesProc, m_szQuery, GetClientUserId(client));
		}
		else
		{
			BuildFaithMainMenu(client);
		}
	}
	else if(action == MenuAction_Cancel && itemNum == MenuCancel_ExitBack)
	{
		BuildFaithMainMenu(client);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}


void BuildInvestmentListMenu(int client, Handle hPack)
{
	ResetPack(hPack);
	int Commerce_Lvl = ReadPackCell(hPack);
	int Commerce_Exp = ReadPackCell(hPack);
	int Industrial_Lvl = ReadPackCell(hPack);
	int Industrial_Exp = ReadPackCell(hPack);
	int PublicRelations_Lvl = ReadPackCell(hPack);
	int PublicRelations_Exp = ReadPackCell(hPack);
	CloseHandle(hPack);
	
	Handle menu = CreateMenu(MenuHandler_InvestmentMenu);
	SetMenuTitle(menu, "[CG]   Faith - Investment :: Select [developer preview]\n　\n Your Credits: %d \n \n ", OnAPIStoreGetCredits(client));
	
	char m_szProc[128], m_szItem[128], m_szDesc[256];
	
	BuildInvesProcBar(Commerce_Exp, m_szProc, 256);
	Format(m_szItem, 128, "commerce_%d_%d", Commerce_Lvl, Commerce_Exp);
	Format(m_szDesc, 256, "  Commerce :: Lv.%d\n    %s\n     Requirement: %d Credits\n ", Commerce_Lvl, m_szProc, (Commerce_Lvl == 7 && Commerce_Exp == 10) ? 0 : Commerce_Lvl*1000+1000);
	AddMenuItem(menu, m_szItem, m_szDesc, (Commerce_Lvl == 7 && Commerce_Exp == 10) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	
	BuildInvesProcBar(Industrial_Exp, m_szProc, 256);
	Format(m_szItem, 128, "industrial_%d_%d", Industrial_Lvl, Industrial_Exp);
	Format(m_szDesc, 256, "  Industrial :: Lv.%d\n    %s\n     Requirement: %d Credits\n ", Industrial_Lvl, m_szProc, (Industrial_Lvl == 10 && Industrial_Exp == 10) ? 0 : Industrial_Lvl*1000+1000);
	AddMenuItem(menu, m_szItem, m_szDesc, (Industrial_Lvl == 10 && Industrial_Exp == 10) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	
	BuildInvesProcBar(PublicRelations_Exp, m_szProc, 256);
	Format(m_szItem, 128, "publicrelations_%d_%d", PublicRelations_Lvl, PublicRelations_Exp);
	Format(m_szDesc, 256, "  Public Relations :: Lv.%d\n    %s\n     Requirement: %d Credits\n ", PublicRelations_Lvl, m_szProc, (PublicRelations_Lvl == 10 && PublicRelations_Exp == 10) ? 0 : PublicRelations_Lvl*1000+500);
	AddMenuItem(menu, m_szItem, m_szDesc, (PublicRelations_Lvl == 10 && PublicRelations_Exp == 10) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 0);
}

stock void BuildInvesProcBar(int iProc, char[] szBuffer, int maxLen)
{
	switch(iProc)
	{
		case  0: strcopy(szBuffer, maxLen, "  □□□□□□□□□□");
		case  1: strcopy(szBuffer, maxLen, "  ■□□□□□□□□□");
		case  2: strcopy(szBuffer, maxLen, "  ■■□□□□□□□□");
		case  3: strcopy(szBuffer, maxLen, "  ■■■□□□□□□□");
		case  4: strcopy(szBuffer, maxLen, "  ■■■■□□□□□□");
		case  5: strcopy(szBuffer, maxLen, "  ■■■■■□□□□□");
		case  6: strcopy(szBuffer, maxLen, "  ■■■■■■□□□□");
		case  7: strcopy(szBuffer, maxLen, "  ■■■■■■■□□□");
		case  8: strcopy(szBuffer, maxLen, "  ■■■■■■■■□□");
		case  9: strcopy(szBuffer, maxLen, "  ■■■■■■■■■□");
		case 10: strcopy(szBuffer, maxLen, "  ■Complete■");
	}
}

public int MenuHandler_InvestmentMenu(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		char m_szData[3][32];
		ExplodeString(info, "_", m_szData, 3, 32);
		
		int iLvl = StringToInt(m_szData[1]);
		int iProc = StringToInt(m_szData[2]);
		
		Handle hPack = CreateDataPack();
		WritePackCell(hPack, GetClientUserId(client));
		
		if(StrEqual(m_szData[0], "commerce"))
		{
			iProc++;
			
			if(iProc >= 10 && iLvl < 7)
			{
				iLvl++;
				iProc = 0;
			}
			
			WritePackCell(hPack, 1);
			WritePackCell(hPack, iLvl);
			WritePackCell(hPack, iProc);

			char m_szQuery[128];
			Format(m_szQuery, 128, "UPDATE playertrack_investment SET commerce_lvl = %d, commerce_exp = %d WHERE playerid = %d", iLvl, iProc, g_eClient[client][iPlayerId]);
			SQL_TQuery(g_hDB_csgo, SQLCallback_InvesUpgrade, m_szQuery, hPack);
		}
		else if(StrEqual(m_szData[0], "industrial"))
		{
			iProc++;

			if(iProc >= 10 && iLvl < 10)
			{
				iLvl++;
				iProc = 0;
			}
			
			WritePackCell(hPack, 2);
			WritePackCell(hPack, iLvl);
			WritePackCell(hPack, iProc);
			
			char m_szQuery[128];
			Format(m_szQuery, 128, "UPDATE playertrack_investment SET industrial_lvl = %d, industrial_exp = %d WHERE playerid = %d", iLvl, iProc, g_eClient[client][iPlayerId]);
			SQL_TQuery(g_hDB_csgo, SQLCallback_InvesUpgrade, m_szQuery, hPack);
		}
		else if(StrEqual(m_szData[0], "publicrelations"))
		{
			iProc++;

			if(iProc >= 10 && iLvl < 10)
			{
				iLvl++;
				iProc = 0;
			}
			
			WritePackCell(hPack, 3);
			WritePackCell(hPack, iLvl);
			WritePackCell(hPack, iProc);
			
			char m_szQuery[128];
			Format(m_szQuery, 128, "UPDATE playertrack_investment SET publicrelations_lvl = %d, publicrelations_exp = %d WHERE playerid = %d", iLvl, iProc, g_eClient[client][iPlayerId]);
			SQL_TQuery(g_hDB_csgo, SQLCallback_InvesUpgrade, m_szQuery, hPack);
		}
	}
	else if(action == MenuAction_Cancel && itemNum == MenuCancel_ExitBack)
	{
		BuildFaithMainMenu(client);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

void ClientInvesUpgraded(int client, int iTyp, int iLvl, int iProc)
{
	char m_szQuery[128];

	switch(iTyp)
	{
		case 1: 
		{
			if(iLvl == 7 && iProc == 10)
			{
				CG_GiveClientShare(client, 10000, "Investment Upgrade[Commerce] to Max Level");
				Format(m_szQuery, 128, "UPDATE playertrack_investment SET share=share+%d WHERE playerid = %d", 10000, g_eClient[client][iPlayerId]);
				CG_SaveDatabase(m_szQuery);
				PrintToChatAll("%s  \x0C%N\x04 upgraded \x0CCommerce \x04 to Max Level(\x0C7\x04).", PLUGIN_PREFIX, client);
			}
			else if(iLvl > 0 && iProc == 0)
			{
				CG_GiveClientShare(client, iLvl*200, "Investment Upgrade[Commerce] to New Level");
				Format(m_szQuery, 128, "UPDATE playertrack_investment SET share=share+%d WHERE playerid = %d", iLvl*200, g_eClient[client][iPlayerId]);
				CG_SaveDatabase(m_szQuery);
				PrintToChat(client, "%s  \x04You upgraded \x0CCommerce \x04 to New Level \x01:: \x10Level\x01: \x0E%d \x01=> \x04You earned \x0E%d \x04Share!", PLUGIN_PREFIX, iLvl, iLvl*200);
			}
			else
			{
				CG_GiveClientShare(client, iLvl*50+50, "Investment Upgrade[Commerce] to New Rate");
				Format(m_szQuery, 128, "UPDATE playertrack_investment SET share=share+%d WHERE playerid = %d", iLvl*50+50, g_eClient[client][iPlayerId]);
				CG_SaveDatabase(m_szQuery);
				PrintToChat(client, "%s  \x04You upgraded \x0CCommerce \x01:: \x10Level\x01: \x0E%d  \x10Rate\x01: \x0E%d \x01=> \x04You earned \x0E%d \x04Share!", PLUGIN_PREFIX, iLvl, iProc, iLvl*50+50);
			}
		}
		case 2: 
		{
			if(iLvl == 10 && iProc == 10)
			{
				CG_GiveClientShare(client, 10000, "Investment Upgrade[Industrial] to Max Level");
				Format(m_szQuery, 128, "UPDATE playertrack_investment SET share=share+%d WHERE playerid = %d", 10000, g_eClient[client][iPlayerId]);
				CG_SaveDatabase(m_szQuery);
				PrintToChatAll("%s  \x0C%N\x04 upgraded \x0CIndustrial \x04 to Max Level(\x0C7\x04).", PLUGIN_PREFIX, client);
			}
			else if(iLvl > 0 && iProc == 0)
			{
				CG_GiveClientShare(client, iLvl*200, "Investment Upgrade[Industrial] to New Level");
				Format(m_szQuery, 128, "UPDATE playertrack_investment SET share=share+%d WHERE playerid = %d", iLvl*200, g_eClient[client][iPlayerId]);
				CG_SaveDatabase(m_szQuery);
				PrintToChat(client, "%s  \x04You upgraded \x0CIndustrial \x04 to New Level \x01:: \x10Level\x01: \x0E%d \x01=> \x04You earned \x0E%d \x04Share!", PLUGIN_PREFIX, iLvl, iLvl*200);
			}
			else
			{
				CG_GiveClientShare(client, iLvl*50+50, "Investment Upgrade[Industrial] to New Rate");
				Format(m_szQuery, 128, "UPDATE playertrack_investment SET share=share+%d WHERE playerid = %d", iLvl*50+50, g_eClient[client][iPlayerId]);
				CG_SaveDatabase(m_szQuery);
				PrintToChat(client, "%s  \x04You upgraded \x0CIndustrial \x01:: \x10Level\x01: \x0E%d  \x10Rate\x01: \x0E%d \x01=> \x04You earned \x0E%d \x04Share!", PLUGIN_PREFIX, iLvl, iProc, iLvl*50+50);
			}
		}
		case 3: 
		{
			if(iLvl == 10 && iProc == 10)
			{
				CG_GiveClientShare(client, 10000, "Investment Upgrade[Public Relations] to Max Level");
				Format(m_szQuery, 128, "UPDATE playertrack_investment SET share=share+%d WHERE playerid = %d", 10000, g_eClient[client][iPlayerId]);
				CG_SaveDatabase(m_szQuery);
				PrintToChatAll("%s  \x0C%N\x04 upgraded \x0CPublic Relations \x04 to Max Level(\x0C7\x04).", PLUGIN_PREFIX, client);
			}
			else if(iLvl > 0 && iProc == 0)
			{
				CG_GiveClientShare(client, iLvl*200, "Investment Upgrade[Public Relations] to New Level");
				Format(m_szQuery, 128, "UPDATE playertrack_investment SET share=share+%d WHERE playerid = %d", iLvl*200, g_eClient[client][iPlayerId]);
				CG_SaveDatabase(m_szQuery);
				PrintToChat(client, "%s  \x04You upgraded \x0CPublic Relations \x04 to New Level \x01:: \x10Level\x01: \x0E%d \x01=> \x04You earned \x0E%d \x04Share!", PLUGIN_PREFIX, iLvl, iLvl*200);
			}
			else
			{
				CG_GiveClientShare(client, iLvl*50+50, "Investment Upgrade[Public Relations] to New Rate");
				Format(m_szQuery, 128, "UPDATE playertrack_investment SET share=share+%d WHERE playerid = %d", iLvl*50+50, g_eClient[client][iPlayerId]);
				CG_SaveDatabase(m_szQuery);
				PrintToChat(client, "%s  \x04You upgraded \x0CPublic Relations \x01:: \x10Level\x01: \x0E%d  \x10Rate\x01: \x0E%d \x01=> \x04You earned \x0E%d \x04Share!", PLUGIN_PREFIX, iLvl, iProc, iLvl*50+50);
			}
		}
	}

	Format(m_szQuery, 128, "SELECT * FROM playertrack_investment WHERE playerid = %d", g_eClient[client][iPlayerId]);
	SQL_TQuery(g_hDB_csgo, SQLCallback_InvesProc, m_szQuery, GetClientUserId(client));
}