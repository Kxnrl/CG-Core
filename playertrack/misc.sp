void SettingAdver()
{
	Handle kv = CreateKeyValues("ServerAdvertisement", "", "");
	char FILE_PATH[256];
	BuildPath(Path_SM, FILE_PATH, 256, "configs/ServerAdvertisement.cfg");
	
	if(KvJumpToKey(kv, "Settings", true))
	{
		KvSetString(kv, "enable", "1");
		KvSetFloat(kv, "Delay_between_messages", 30.0);
		KvSetString(kv, "Advertisement_tag", "[{purple}Planeptune{default}] ^");
		KvSetString(kv, "Time_Format", "%H:%M:%S");
		KvGoBack(kv);
		KvRewind(kv);
		KeyValuesToFile(kv, FILE_PATH);
	}
	CloseHandle(kv);
	kv = INVALID_HANDLE;

	if(0 < g_ServerID)
	{
		char query[280];
		Format(query, 280, "SELECT * FROM playertrack_adv WHERE sid = '%i' OR sid = '0'", g_ServerID);
		SQL_TQuery(g_hDB_csgo, SQLCallback_GetAdvData, query, _, DBPrio_High);
	}
}

stock bool IsClientBot(int client)
{
	//是不是有效的客户
	if(IsFakeClient(client) || client < 1 || client > MaxClients)
		return true;

	//是不是BOT
	char SteamID[32];
	GetClientAuthId(client, AuthId_Steam2, SteamID, 32);

	if(StrEqual(SteamID, "BOT", false))
		return true;

	return false;
}

stock bool IsValidClient(int client, bool checkBOT = false)
{
	if(client > MaxClients || client < 1)
		return false;

	if(!IsClientInGame(client) || IsFakeClient(client))
		return false;
	
	if(checkBOT)
	{
		char SteamID[64];
		GetClientAuthId(client, AuthId_Steam2, SteamID, 32);

		if(StrEqual(SteamID, "BOT", false))
		return false;
	}
	
	return true;
}

public void SetClientVIP(int client, int type)
{
	g_eClient[client][bIsVip] = true;
	g_eClient[client][iVipType] = type;
	
	char steamid[32];
	GetClientAuthId(client, AuthId_Steam2, steamid, 32);

	if(GetUserAdmin(client) == INVALID_ADMIN_ID && FindAdminByIdentity(AUTHMETHOD_STEAM, steamid) == INVALID_ADMIN_ID)
	{
		AdminId adm = CreateAdmin(g_eClient[client][szDiscuzName]);
		
		BindAdminIdentity(adm, AUTHMETHOD_STEAM, steamid);
		
		SetAdminFlag(adm, Admin_Reservation, true);
		SetAdminFlag(adm, Admin_Generic, true);
		SetAdminFlag(adm, Admin_Custom2, true);
		
		if(type == 3)
		{
			SetAdminFlag(adm, Admin_Custom5, true);
			SetAdminFlag(adm, Admin_Custom6, true);
			SetAdminImmunityLevel(adm, 9);
		}
		else if(type == 2)
		{
			SetAdminFlag(adm, Admin_Custom6, true);
			SetAdminImmunityLevel(adm, 8);
		}
		else if(type == 1)
		{
			SetAdminImmunityLevel(adm, 5);
		}
		
		RunAdminCacheChecks(client);
	}
	else
	{
		AdminId adm = GetUserAdmin(client);
		AdminId admid = FindAdminByIdentity(AUTHMETHOD_STEAM, steamid);
		
		if(adm == admid)
		{
			if(!GetAdminFlag(adm, Admin_Reservation))
				SetAdminFlag(adm, Admin_Reservation, true);
			
			if(!GetAdminFlag(adm, Admin_Generic))
				SetAdminFlag(adm, Admin_Generic, true);
		
			if(!GetAdminFlag(adm, Admin_Custom2))
				SetAdminFlag(adm, Admin_Custom2, true);
			
			if(GetAdminImmunityLevel(adm) < 5)
					SetAdminImmunityLevel(adm, 5);

			if(type == 3)
			{
				if(!GetAdminFlag(adm, Admin_Custom5))
					SetAdminFlag(adm, Admin_Custom5, true);
				
				if(!GetAdminFlag(adm, Admin_Custom6))
					SetAdminFlag(adm, Admin_Custom6, true);
				
				if(GetAdminImmunityLevel(adm) < 9)
					SetAdminImmunityLevel(adm, 9);
			}
			else if(type == 2)
			{
				if(!GetAdminFlag(adm, Admin_Custom6))
					SetAdminFlag(adm, Admin_Custom6, true);
				
				if(GetAdminImmunityLevel(adm) < 8)
					SetAdminImmunityLevel(adm, 8);
			}
		}
		
	}

	VipChecked(client);
}

public void SetClientFaith(int client, int faith)
{
	if(!g_eClient[client][bLoaded])
	{
		PrintToChat(client, "%s  很抱歉,你的数据尚未加载完毕", PLUGIN_PREFIX);
		return;
	}
	
	g_eClient[client][iFaith] = faith;
	
	char m_szQuery[256];
	Format(m_szQuery, 256, "UPDATE `playertrack_player` SET faith = '%d' WHERE id = '%d'", faith, g_eClient[client][iPlayerId]);
	SQL_TQuery(g_hDB_csgo, SQLCallback_SetFaith, m_szQuery, GetClientUserId(client));
}

public void ShowFaithFirstMenuToClient(int client)
{
	int share[5];
	share[0] = g_Share[1]+g_Share[2]+g_Share[3]+g_Share[4];
	share[1] = RoundToFloor((float(g_Share[1])/float(share[0]))*100);
	share[2] = RoundToFloor((float(g_Share[2])/float(share[0]))*100);
	share[3] = RoundToFloor((float(g_Share[3])/float(share[0]))*100);
	share[4] = RoundToFloor((float(g_Share[4])/float(share[0]))*100);

	Handle menu = CreateMenu(FaithFirstMenuHandler);
	char szTmp[256];
	Format(szTmp, 256, "[Planeptune]   Faith\n \n ");
	SetMenuTitle(menu, szTmp);
	AddMenuItem(menu, "", "目前系统检测到你的Faith为空[输入!fhelp了解更多]", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "", "选择1个Faith以获得Buff[暂时不能更换]", ITEMDRAW_DISABLED);
	
	Format(szTmp, 256, "Perfect Purple  [速度++ | 射速++] [FD: 猫灵] | Credits+3", share[1], share[0]);
	AddMenuItem(menu, "purple", szTmp);
	
	Format(szTmp, 256, "Brave Black  [生命++ | 暴击++] [FD: 曼妥思] | Credits+5", share[2], share[0]);
	AddMenuItem(menu, "black", szTmp);
	
	Format(szTmp, 256, "Liberty White  [伤害++ | 护甲++] [FD: 色拉] | Credits+4", share[4], share[0]);
	AddMenuItem(menu, "white", szTmp);
	
	Format(szTmp, 256, "Greedy Green  [闪避++ | 嗜血++] [FD: 基佬桐] | Credits+4", share[3], share[0]);
	AddMenuItem(menu, "green", szTmp);

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public int FaithFirstMenuHandler(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		if(StrEqual(info, "purple"))
			ConfirmSelect(client, 1);
		else if(StrEqual(info, "black"))
			ConfirmSelect(client, 2);
		else if(StrEqual(info, "green"))
			ConfirmSelect(client, 3);
		else if(StrEqual(info, "white"))
			ConfirmSelect(client, 4);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public int FaithHelpMenuHandler(Handle menu, MenuAction action, int client, int itemNum) 
{
	
}

public void ConfirmSelect(int client, int faith)
{
	g_eClient[client][iFaithSelect] = faith;
	
	Handle menu = CreateMenu(FaithConfirmMenuHandler);
	char szTmp[64];
	Format(szTmp, 64, "[Planeptune]   Faith - Confirm\n \n ");
	SetMenuTitle(menu, szTmp);
	if(faith == 1)
	{
		AddMenuItem(menu, "", "你选择的是: [Perfect Purple]", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "Faith Buff: [速度++ | 射速++]", ITEMDRAW_DISABLED);
	}
	if(faith == 2)
	{
		AddMenuItem(menu, "", "你选择的是 [Brave Black]", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "Faith Buff: [生命++ | 暴击++]", ITEMDRAW_DISABLED);
	}	
	if(faith == 3)
	{
		AddMenuItem(menu, "", "你选择的是 [Greedy Green]", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "Faith Buff: [闪避++ | 嗜血++]", ITEMDRAW_DISABLED);
	}
	if(faith == 4)
	{
		AddMenuItem(menu, "", "你选择的是 [Liberty White]", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "Faith Buff: [伤害++ | 护甲++]", ITEMDRAW_DISABLED);
	}
	
	AddMenuItem(menu, "", "更改Faith需要一定Credits还会清空你的贡献值", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "", "你确定你的选择吗:)", ITEMDRAW_DISABLED);

	AddMenuItem(menu, "yes", "我确定");
	AddMenuItem(menu, "no", "我拒绝");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public int FaithConfirmMenuHandler(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		if(g_eClient[client][iFaithSelect] != 0)
			if(StrEqual(info, "yes"))
				SetClientFaith(client, g_eClient[client][iFaithSelect]);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public void ShowFaithMainMenuToClient(int client)
{
	Handle menu = CreateMenu(FaithMainMenuHandler);
	char szItem[256];
	
	Format(szItem, 256, "[Planeptune]   Faith - Main\n ");
	SetMenuTitle(menu, szItem);
	
	Format(szItem, 256, "更改Faith需要一定Credits还会清空你的贡献值");
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	if(g_eClient[client][iFaith] == 1)
		Format(szItem, 256, "你当前的Faith为[Perfect Purple] \n ");
	else if(g_eClient[client][iFaith] == 2)
		Format(szItem, 256, "你当前的Faith为[Brave Black] \n ");
	else if(g_eClient[client][iFaith] == 3)
		Format(szItem, 256, "你当前的Faith为[Greedy Green] \n ");
	else if(g_eClient[client][iFaith] == 4)
		Format(szItem, 256, "你当前的Faith为[Liberty White] \n ");

	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "查看各个Faith的Share值");
	AddMenuItem(menu, "query_share", szItem);
	
	Format(szItem, 256, "查看各个Faith的Buff类型");
	AddMenuItem(menu, "query_buff", szItem);
	
	Format(szItem, 256, "查看我的Share贡献值");
	AddMenuItem(menu, "query_offer", szItem);
	
	Format(szItem, 256, "查看Faith排行榜");
	AddMenuItem(menu, "query_rank", szItem);
	
	Format(szItem, 256, "充值信仰");
	AddMenuItem(menu, "charge", szItem);
	
	Format(szItem, 256, "重新选择我的Faith");
	AddMenuItem(menu, "resetmyfaith", szItem);

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public int FaithMainMenuHandler(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		if(StrEqual(info, "query_share"))
			ShowAllFaithShareToClient(client);
		else if(StrEqual(info, "query_buff"))
			ShowAllFaithBuffToClient(client);
		else if(StrEqual(info, "query_offer"))
			ShowFaithOfferToClient(client);
		else if(StrEqual(info, "resetmyfaith"))
			FakeClientCommandEx(client, "sm_freset");
		else if(StrEqual(info, "charge"))
			FakeClientCommandEx(client, "sm_fcharge");
		else if(StrEqual(info, "query_rank"))
			ShowFaithShareRankToClient(client);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public void ShowAllFaithShareToClient(int client)
{
	Handle menu = CreateMenu(ShowAllFaithShareMenuHandler);
	char szItem[256];
	Format(szItem, 256, "[Planeptune]   Faith -  查看各个Faith的Share值\n ");
	SetMenuTitle(menu, szItem);
	
	float share[5];
	share[0] = float(g_Share[1]+g_Share[2]+g_Share[3]+g_Share[4]);
	share[1] = (float(g_Share[1])/share[0])*100;
	share[2] = (float(g_Share[2])/share[0])*100;
	share[3] = (float(g_Share[3])/share[0])*100;
	share[4] = (float(g_Share[4])/share[0])*100;
	
	Format(szItem, 256, "[Perfect Purple] - Share %d [%.2f%% of %d]", g_Share[1], share[1], RoundToFloor(share[0]));
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "[Brave Black] - Share %d [%.2f%% of %d]", g_Share[2], share[2], RoundToFloor(share[0]));
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "[Greedy Green] - Share %d [%.2f%% of %d]", g_Share[3], share[3], RoundToFloor(share[0]));
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "[Liberty White] - Share %d [%.2f%% of %d]", g_Share[4], share[4], RoundToFloor(share[0]));
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 60);
}

public int ShowAllFaithShareMenuHandler(Handle menu, MenuAction action, int client, int itemNum) 
{
	
}

public void ShowAllFaithBuffToClient(int client)
{
	float g_fShareLevel[5];

	//purple
	float g_fBoostSpeed;
	float g_fFireRate;
	
	//black
	int g_iBoostHP;
	float g_fCrit;
	
	//green
	float g_fDodge;
	int g_iVampire;
	
	//white
	float g_fBoostDamage;
	int g_iBoostAM;
	
	g_fShareLevel[0] = 100.0; //全局25%
	g_Share[0] = g_Share[1] + g_Share[2] + g_Share[3] + g_Share[4];
	
	if(g_Share[0] == 0)
		g_Share[0] = 1;

	g_fShareLevel[1] = (float(g_Share[1])/float(g_Share[0])-0.24)*100;
	g_fShareLevel[2] = (float(g_Share[2])/float(g_Share[0])-0.24)*100;
	g_fShareLevel[3] = (float(g_Share[3])/float(g_Share[0])-0.24)*100;
	g_fShareLevel[4] = (float(g_Share[4])/float(g_Share[0])-0.24)*100;

	g_fBoostSpeed = 1.05+g_fShareLevel[1]*0.01;
	g_fFireRate = g_fShareLevel[1]*0.01;
	
	if(g_fBoostSpeed < 1.0)
		g_fBoostSpeed = 1.0;
	
	if(g_fFireRate > 1.0)
		g_fFireRate = 1.0;

	g_iBoostHP = 10+RoundToFloor(g_fShareLevel[2]);
	g_fCrit = 5.0+g_fShareLevel[2];
	
	if(g_iBoostHP < 0)
		g_iBoostHP = 0;
	
	if(g_fCrit < 0.0)
		g_fCrit = 0.0;

	g_fDodge = 5.0+g_fShareLevel[3];
	g_iVampire = 2+RoundToFloor(g_fShareLevel[3]*0.5);
	
	if(g_fDodge < 0.0)
		g_fDodge = 0.0;
	
	if(g_iVampire < 0)
		g_iVampire = 0;

	g_fBoostDamage = 1.05+g_fShareLevel[4]*0.025;
	g_iBoostAM = 10+RoundToFloor(g_fShareLevel[4]);
	
	if(g_fBoostDamage < 1.0)
		g_fBoostDamage = 1.0;

	if(g_iBoostAM < 0)
		g_iBoostAM = 0;
	
	Handle menu = CreateMenu(ShowAllFaithBuffMenuHandler);
	char szItem[256];
	Format(szItem, 256, "[Planeptune]   Faith -  查看各个Faith的Share值\n \n ");
	SetMenuTitle(menu, szItem);

	float speed = (g_fBoostSpeed - 1.0)*100;
	float firerate = g_fFireRate*100;
	Format(szItem, 256, "[Perfect Purple]  -  [速度+%.2f%% | 射速+%.2f%%] Credits+3\n ", speed, firerate);
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "[Brave Black]  -  [生命+%d | 暴击+%.2f] Credits+5\n ", g_iBoostHP, g_fCrit);
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "[Greedy Green]  -  [闪避+%.2f%% | 嗜血+%d] Credits+4\n ", g_fDodge, g_iVampire);
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	float damage = (g_fBoostDamage-1.0)*100;
	Format(szItem, 256, "[Liberty White]  -  [伤害+%.2f%% | 护甲+%d] Credits+4\n", damage, g_iBoostAM);
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 60);
}

public int ShowAllFaithBuffMenuHandler(Handle menu, MenuAction action, int client, int itemNum) 
{
	
}

public void ShowFaithOfferToClient(int client)
{
	float vol = float(g_eClient[client][iShare])/float(g_Share[g_eClient[client][iFaith]]);
	PrintToChat(client, "[%s]  你个人贡献的Share为\x0C%d\x01点[%.2f%% of %d - %s]", szFaith_CNAME[g_eClient[client][iFaith]], g_eClient[client][iShare], vol, g_Share[g_eClient[client][iFaith]], szFaith_CNATION[g_eClient[client][iFaith]]);
}

public void ShowFaithShareRankToClient(int client)
{
	char sQuery[512];
	FormatEx(sQuery, 512, "SELECT `name`, `share` FROM `playertrack_player` WHERE `faith` = '%d' ORDER BY `share` DESC LIMIT 50;", g_eClient[client][iFaith]);
	SQL_TQuery(g_hDB_csgo, SQLCallback_FaithShareRank, sQuery, g_eClient[client][iUserId]);
}

void CreateTopMenu(int client, Handle pack)
{
	char szItem[256], sName[128];
	Handle hMenu = CreateMenu(FaithRankMenuHandler);

	FormatEx(szItem, 256, "[Planeptune]   Faith Share Rank - %s \n ", szFaith_NAME[g_eClient[client][iFaith]]);
	SetMenuTitle(hMenu, szItem);

	SetMenuPagination(hMenu, 10);

	SetMenuExitButton(hMenu, true);
	SetMenuExitBackButton(hMenu, false);

	ResetPack(pack);
	
	int iCount = ReadPackCell(pack);
	for(int i = 0; i < iCount; i++)
	{
		ReadPackString(pack, sName, 128);
		int ishare = ReadPackCell(pack);
		float vol = (float(ishare)/float(g_Share[g_eClient[client][iFaith]]))*100;
		FormatEx(szItem, 128, "#%d   %s  %d[%.2f%% of %d - %s]", i+1, sName, ishare, vol, g_Share[g_eClient[client][iFaith]], szFaith_NATION[g_eClient[client][iFaith]]);
		AddMenuItem(hMenu, "", szItem, ITEMDRAW_DISABLED);
	}

	CloseHandle(pack);
	DisplayMenu(hMenu, client, 60);
}

public int FaithRankMenuHandler(Handle menu, MenuAction action, int client, int itemNum)
{
	
}

public void PrintConsoleInfo(int client)
{
	int timeleft;
	GetMapTimeLeft(timeleft);
	int mins, secs;	
	char finalOutput[32];
	mins = timeleft / 60;
	secs = timeleft % 60;
	Format(finalOutput, 32, "%d:%02d", mins, secs);
	float fltickrate = 1.0 / GetTickInterval();
	char map[128];
	GetCurrentMap(map, 128);
	char hostname[128];
	GetConVarString(FindConVar("hostname"), hostname, 128);

	PrintToConsole(client, "-----------------------------------------------------------------------------------------------------------");
	PrintToConsole(client, " ");
	PrintToConsole(client, "                                           欢迎来到[CG]游戏社区                                            ");	
	PrintToConsole(client, " ");
	PrintToConsole(client, "当前服务器:  %s   -   Tickrate: %i.0", hostname, RoundToNearest(fltickrate));
	PrintToConsole(client, " ");
	PrintToConsole(client, "论坛地址: http://csgogamers.com  官方QQ群: 107421770  官方YY: 435773");
	if (timeleft > 0)
		PrintToConsole(client, "当前地图: %s   剩余时间: %s", map, finalOutput);
	PrintToConsole(client, " ");
	PrintToConsole(client, "服务器基础命令:");
	PrintToConsole(client, "Store相关： !store [打开Store], !credits [显示余额], !inv [查看库存]");
	PrintToConsole(client, "地图相关： rtv/!rtv [滚动投票], !revote[重新选择], !nominate[预定地图]");
	PrintToConsole(client, "娱乐相关： !music[点歌菜单], !stop[停止地图音乐], !stopmusic[停止点播歌曲]");
	PrintToConsole(client, "其他命令： !sign [签到], !hideneon[屏蔽霓虹], !tp[第三人称视角], !seeme[360°视角]");
	PrintToConsole(client, "玩家认证： !renzheng/!pawho!/!rz [查询认证], !exp/!jingyan/!jy[查询经验值]");
	PrintToConsole(client, "搞基系统： !love/!cp [功能菜单], !skill/!cp_skill[技能菜单], ");
	PrintToConsole(client, " ");
	PrintToConsole(client, "-----------------------------------------------------------------------------------------------------------");		
	PrintToConsole(client, " ");
}

public int AdminMainMenuHandler(Handle menu, MenuAction action, int client, int itemNum) 
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
	Handle menu = CreateMenu(SelectTargetMenuHandler);
	char szTmp[64];
	Format(szTmp, 64, "[Planeptune]   未知错误");
	if(g_eAdmin[iType] == 1)
		Format(szTmp, 64, "[Planeptune]   添加临时神烦坑比\n -by shAna.xQy");
	if(g_eAdmin[iType] == 2)
		Format(szTmp, 64, "[Planeptune]   添加临时小学生\n -by shAna.xQy");
	if(g_eAdmin[iType] == 3)
		Format(szTmp, 64, "[Planeptune]  撤销临时认证\n -by shAna.xQy");
	if(g_eAdmin[iType] == 4)
		Format(szTmp, 64, "[Planeptune]   重新载入认证\n -by shAna.xQy");

	SetMenuTitle(menu, szTmp);

	if(g_eAdmin[iType] == 1 || g_eAdmin[iType] == 2)
	{
		for(int x=1; x<=MaxClients; ++x)
		{
			if(IsClientInGame(x) && !IsClientBot(x))
			{
				if(g_eClient[x][iGroupId] == 0 && g_eClient[x][iTemp] == 0)
				{
					char szInfo[16], szName[64];
					FormatEx(szInfo, 16, "%d", GetClientUserId(x));
					FormatEx(szName, 64, "%N", x);
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
					FormatEx(szInfo, 16, "%d", GetClientUserId(x));
					FormatEx(szName, 64, "%N", x);
					if(g_eClient[x][iGroupId] == 9000)
						FormatEx(szName, 64, "%N[神烦坑比]", x);
					if(g_eClient[x][iGroupId] == 9001)
						FormatEx(szName, 64, "%N[小学生]", x);
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
				FormatEx(szInfo, 16, "%d", GetClientUserId(x));
				FormatEx(szName, 64, "%N", x);
				AddMenuItem(menu, szInfo, szName);
			}
		}
	}

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 30);
}


public int SelectTargetMenuHandler(Handle menu, MenuAction action, int client, int itemNum) 
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
	Handle menu = CreateMenu(SelectTimeMenuHandler);
	char szTmp[64];
	Format(szTmp, 64, "[Planeptune]   选择临时认证时长\n -by shAna.xQy");
	SetMenuTitle(menu, szTmp);
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

public int SelectTimeMenuHandler(Handle menu, MenuAction action, int client, int itemNum) 
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
		LogToFile(logFile_core, " %N 给 %N 加上了临时认证[神烦坑比]!", client, target);
		LogAction(client, target, "\"%L\" 给 \"%L\" 加上了临时认证[神烦坑比]", client, target);
		Format(sName, 32, "神烦坑比");
	}

	if(GroupIndex == 9001)
	{
		PrintToChatAll("%s 管理员\x10%N\x01给\x02%N\x01添加了临时认证[\x02我是小学生\x01]", PLUGIN_PREFIX, client, target);
		LogToFile(logFile_core, " %N 给 %N 加上了临时认证[神烦坑比]!", client, target);
		LogAction(client, target, "\"%L\" 给 \"%L\" 加上了临时认证[我是小学生]", client, target);
		Format(sName, 32, "小学生");
	}
	
	char szQuery[256], auth[32];
	GetClientAuthId(target, AuthId_Steam2, auth, 32, true);
	
	Format(szQuery, 256, "UPDATE `playertrack_player` SET groupid = '%d', groupname = '%s', temp = '%d' WHERE id = '%d' and steamid = '%s'", GroupIndex, sName, ExpiredTime, g_eClient[target][iPlayerId], auth);
	SQL_TQuery(g_hDB_csgo, SQLCallback_SetTemp, szQuery, GetClientUserId(client));
}

void DoUnbanTempPA(int client)
{
	int target = g_eAdmin[iTarget]; 

	char szQuery[256], auth[32];
	
	GetClientAuthId(target, AuthId_Steam2, auth, 32);

	Format(szQuery, 256, "UPDATE `playertrack_player` SET groupid = '0', groupname = '未认证', temp = '0' WHERE id = '%d' and steamid = '%s'", g_eClient[target][iPlayerId], auth);
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
	char szQuery[256], auth[32];
	GetClientAuthId(client, AuthId_Steam2, auth, 32);
	Format(szQuery, 256, "SELECT `groupid`,`groupname`,`exp`,`level`,`temp` FROM `playertrack_player` WHERE id = '%d' and steamid = '%s'", g_eClient[client][iPlayerId], auth);
	SQL_TQuery(g_hDB_csgo, SQLCallback_GetGroupId, szQuery, GetClientUserId(client));
}

public Action Timer_Notice(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!client)
		return Plugin_Stop;
	
	if(!IsClientInGame(client))
		return Plugin_Stop;

	if(g_ServerID == 23 && g_ServerID == 24 && g_ServerID == 11 && g_ServerID == 12 && g_ServerID == 13)
		return Plugin_Stop;
	
	if(g_eClient[client][bPrint])
		return Plugin_Stop;

	if(GetClientTeam(client) < 2)
		return Plugin_Continue;

	FakeClientCommandEx(client, "sm_notice");

	return Plugin_Stop;
}

void ShowPanelToClient(int client)
{
	g_eClient[client][bPrint] = true;
	FakeClientCommandEx(client, "sm_bgm");
	PrintToChat(client, "[\x0EPlaneptune\x01]   输入\x07!notice\x01可以重新打开公告板,阅读完全后下次进入将不再提示");
	
	BuiltPanelToClient(client);
}

void BuiltPanelToClient(int client)
{
	if(!IsValidClient(client))
		return;
	
	Handle menu = CreateMenu(MenuHandler_Panel);
	char szItem[256];
	Format(szItem, 256, "尊敬的玩家:  %N\n ", client);
	SetMenuTitle(menu, szItem);

	if(CG_GetOnlines(client) > 3600)
		Format(szItem, 256, "欢迎您回到Planeptune大地");
	else
		Format(szItem, 256, "欢迎您来到Planeptune大地");
	
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "在紫色大地上需要你遵守CG玩家守则");
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);

	AddMenuItem(menu, "", "", ITEMDRAW_SPACER);

	Format(szItem, 256, "查看全服[%s]", g_szGlobal[0]);
	AddMenuItem(menu, "public", szItem);
	
	if(!StrEqual(g_szServer[0], "空"))
	{
		Format(szItem, 256, "查看本服[%s]\n", g_szServer[0]);
		AddMenuItem(menu, "update", szItem);
	}
	else
	{
		Format(szItem, 256, " 当前没有本服更新说明\n", g_szServer[0]);
		AddMenuItem(menu, "update", szItem, ITEMDRAW_DISABLED);
	}
	
	Format(szItem, 256, "关闭BGM");
	AddMenuItem(menu, "bgmstp", szItem);

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 20);
}

public int MenuHandler_Panel(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		if(StrEqual(info, "public"))
		{
			ShowGlobalNoticeToClient(client);
		}
		else if(StrEqual(info, "update"))
		{
			ShowServerNoticeToClient(client);
		}
		else if(StrEqual(info, "bgmstp"))
		{
			ConfirmStopMusic(client);
		}
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

void ShowGlobalNoticeToClient(int client)
{
	Handle menu = CreateMenu(MenuHandler_Global);
	char szItem[256];
	Format(szItem, 256, "[Planeptune]  全服 %s \n ", g_szGlobal[0]);
	SetMenuTitle(menu, szItem);
	
	Format(szItem, 256, "%s", g_szGlobal[1]);
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "%s", g_szGlobal[2]);
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "%s", g_szGlobal[3]);
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "%s", g_szGlobal[4]);
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "%s\n ", g_szGlobal[5]);
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "下次更新维护前不再提示");
	AddMenuItem(menu, "skip", szItem);

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}

void ShowServerNoticeToClient(int client)
{
	Handle menu = CreateMenu(MenuHandler_Server);
	char szItem[256];
	Format(szItem, 256, "[Planeptune]  本服 %s \n ", g_szServer[0]);
	SetMenuTitle(menu, szItem);
	
	Format(szItem, 256, "%s", g_szServer[1]);
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "%s", g_szServer[2]);
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "%s", g_szServer[3]);
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "%s", g_szServer[4]);
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "%s\n ", g_szServer[5]);
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "下次更新维护前不再提示");
	AddMenuItem(menu, "skip", szItem);

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}

void ConfirmStopMusic(int client)
{
	Handle menu = CreateMenu(MenuHandler_Confirm);
	char szItem[256];
	Format(szItem, 256, "[Planeptune]   你确定要关闭BGM吗 \n ", szItem);
	SetMenuTitle(menu, szItem);
	
	int rdm = GetRandomInt(1, 6);
	
	for(int x = 1; x <= 6; ++x)
		if(x == rdm)
			AddMenuItem(menu, "bgmstp", "我确定");
		else
			AddMenuItem(menu, "", "按错了");

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public int MenuHandler_Confirm(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		if(StrEqual(info, "bgmstp"))
		{
			FakeClientCommandEx(client, "sm_bgmstop");
		}
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public int MenuHandler_Global(Handle menu, MenuAction action, int client, int itemNum)
{
	if(action == MenuAction_Select || action == MenuAction_Cancel)
	{
		BuiltPanelToClient(client);
		SetClientViewNotice(client);
	}
}

public int MenuHandler_Server(Handle menu, MenuAction action, int client, int itemNum)
{
	if(action == MenuAction_Select || action == MenuAction_Cancel)
	{
		BuiltPanelToClient(client);
		SetClientViewNotice(client);
	}
}

void SetClientViewNotice(int client)
{
	if(!IsValidClient(client))
		return;
	
	if(!g_eClient[client][bPrint])
		return;
	
	char m_szQuery[256];
	Format(m_szQuery, 256, "UPDATE `playertrack_player` SET notice = %d WHERE id = %d", GetTime(), g_eClient[client][iPlayerId]);
	SQL_TQuery(g_hDB_csgo, SQLCallback_NothingCallback, m_szQuery, GetClientUserId(client));
	
	g_eClient[client][bPrint] = false;
}