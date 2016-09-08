#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <cg_core>
#include <store>

#define PREFIX "[\x0EPlaneptune\x01]  "

enum types
{
	iId,
	iLvl,
	iTerm,
	iAwdShare,
	iAwdCredit,
	String:szLvls[16],
	String:szName[32],
	String:szDesc[64],
	String:szAwds[64]
}

types g_eReqs[1000][types];
int g_iTrackTime[MAXPLAYERS+1];
Handle g_hTrackTimer[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = " [CG] Guild Center ",
	author = "xQy",
	description = "",
	version = "1.2.2",
	url = "http://steamcommunity.com/id/_xQy_/"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_guild", Command_Guild);
	
	InitializingRedDatabase();
}

public void OnClientDisconnect(int client)
{
	if(g_hTrackTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hTrackTimer[client]);
	}

	g_hTrackTimer[client] = INVALID_HANDLE;
	g_iTrackTime[client] = -1;
}

public void CG_OnClientCompleteReq(int client, int ReqId)
{
	PrintToChatAll("%s \x0C%N\x01完成了\x07%s\x01任务\x04[%s]\x01获得了不菲的奖励", PREFIX, client, g_eReqs[ReqId][szLvls], g_eReqs[ReqId][szName]);
	char m_szReason[64];
	Format(m_szReason, 64, "完成%s任务%s", g_eReqs[ReqId][szLvls], g_eReqs[ReqId][szName]);
	Store_SetClientCredits(client, Store_GetClientCredits(client)+g_eReqs[ReqId][iAwdCredit], m_szReason);
	CG_GiveClientShare(client, g_eReqs[ReqId][iAwdShare], m_szReason);
	CG_ResetReq(client);
}

public Action Timer_TrackClient(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(client && IsClientInGame(client))
	{
		CG_SetReqRate(client, 1500);
		CG_CheckReq(client);
	}

	g_hTrackTimer[client] = INVALID_HANDLE;
}

public Action Command_Guild(int client, int args)
{
	int reqid = CG_GetReqID(client);
	
	if(reqid == 0)
		ShowMainGuild(client);
	else
		ShowRateMenu(client, reqid);
	
	CG_CheckReq(client);
	
	return Plugin_Handled;
}

void ShowMainGuild(int client)
{
	int ishare = CG_GetClientShare(client);
	
	Handle menu = CreateMenu(MenuHandler_MainGuild);
	char szItem[256];
	Format(szItem, 256, "[Planeptune]   Faith - Guild Center\n 你当前有 %d 点 Share\n 当前你没有进行中的任务\n ", ishare);
	SetMenuTitle(menu, szItem);
	
	AddMenuItem(menu, "0", "承接S级任务", ishare >= 3000 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	AddMenuItem(menu, "1", "承接A级任务", ishare >= 1500 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	AddMenuItem(menu, "2", "承接B级任务", ishare >= 1000 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	AddMenuItem(menu, "3", "承接C级任务", ishare >=  500 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	AddMenuItem(menu, "4", "承接D级任务", ishare >=  200 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	AddMenuItem(menu, "5", "承接E级任务", ishare >= -999 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public int MenuHandler_MainGuild(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		SelectReqMenu(client, StringToInt(info));
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

void ShowRateMenu(int client, int reqid)
{
	int ishare = CG_GetClientShare(client);
	
	Handle menu = CreateMenu(MenuHandler_RateGuild);
	char szItem[256];
	Format(szItem, 256, "[Planeptune]   Faith - Guild Center\n 你当前有 %d 点 Share\n ", ishare);
	SetMenuTitle(menu, szItem);
	
	int rate = CG_GetReqRate(client);
	int term = CG_GetReqTerm(client);
	float vol = (float(rate)/float(term))*100;
	Format(szItem, 256, "[%s - %s]   完成度%.2f%%[%d/%d]\n ", g_eReqs[reqid][szLvls], g_eReqs[reqid][szName], vol, rate, term);
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "任务说明: %s\n ", g_eReqs[reqid][szDesc]);
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "任务奖励: %s\n ", g_eReqs[reqid][szAwds]);
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	
	AddMenuItem(menu, "xxxxx", "我就看看");
	AddMenuItem(menu, "reset", "重置任务");
	AddMenuItem(menu, "forgv", "放弃任务");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public int MenuHandler_RateGuild(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		if(StrEqual(info, "reset"))
			ConfirmRateMenu(client, 0);
		
		if(StrEqual(info, "forgv"))
			ConfirmRateMenu(client, 1);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

void SelectReqMenu(int client, int level)
{
	int ishare = CG_GetClientShare(client);
	
	Handle menu = CreateMenu(MenuHandler_SelectReq);
	char szItem[256], szId[4];
	Format(szItem, 256, "[Planeptune]   Faith - Guild Center\n 你当前有 %d 点 Share\n  ", ishare);
	SetMenuTitle(menu, szItem);
	
	int count;
	for(int x; x < 1000; ++x)
	{
		if(g_eReqs[x][iLvl] == level)
		{
			Format(szItem, 256, "[%s] - %s \n%s", g_eReqs[x][szName], g_eReqs[x][szAwds], g_eReqs[x][szDesc]);
			Format(szId, 4, "%d", x);
			AddMenuItem(menu, szId, szItem);
			count++;
		}
	}
	
	if(count)
	{
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 0);
	}
	else
		PrintToChat(client, "%s 目前你没有可以承接的任务", PREFIX);
}

public int MenuHandler_SelectReq(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		ConfirmReqMenu(client, StringToInt(info));
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

void ConfirmRateMenu(int client, int type)
{
	int ishare = CG_GetClientShare(client);
	
	Handle menu = CreateMenu(MenuHandler_ConfirmRate);
	char szItem[256];
	Format(szItem, 256, "[Planeptune]   Faith - Guild Center[beta]\n 你当前有 %d 点 Share\n ", ishare);
	SetMenuTitle(menu, szItem);
	
	if(type == 0)
	{
		AddMenuItem(menu, "", "你确定要重置任务吗?", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "你确定要重置任务吗?", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "你确定要重置任务吗?", ITEMDRAW_DISABLED);
	}
	
	if(type == 1)
	{
		AddMenuItem(menu, "", "你确定要取消任务吗?", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "你确定要取消任务吗?", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "你确定要取消任务吗?", ITEMDRAW_DISABLED);
	}
	
	AddMenuItem(menu, "", "这项操作不可恢复", ITEMDRAW_DISABLED);
	
	AddMenuItem(menu, "no", "我拒绝");

	Format(szItem, 256, "%d", type);
	AddMenuItem(menu, szItem, "我确定");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public int MenuHandler_ConfirmRate(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		if(!StrEqual(info, "no"))
		{
			int type = StringToInt(info);
			
			if(type == 0)
			{
				PrintToChat(client,  "%s  你已经重置了[%s]", PREFIX, g_eReqs[CG_GetReqID(client)][szName]);
				CG_SetReqRate(client, 0);
				CG_SaveReq(client);
			}
			
			if(type == 1)
			{
				PrintToChat(client,  "%s  你已经放弃了[%s]", PREFIX, g_eReqs[CG_GetReqID(client)][szName]);
				CG_ResetReq(client);
			}
		}
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

void ConfirmReqMenu(int client, int id)
{
	int ishare = CG_GetClientShare(client);
	
	Handle menu = CreateMenu(MenuHandler_ConfirmReq);
	char szItem[256];
	Format(szItem, 256, "[Planeptune]   Faith - Guild Center\n 你当前有 %d 点 Share\n ", ishare);
	SetMenuTitle(menu, szItem);
	
	Format(szItem, 256, "你要承接[%s]吗?", g_eReqs[id][szName]);
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "任务难度: %s", g_eReqs[id][szLvls]);
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "任务奖励: %s", g_eReqs[id][szAwds]);
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "任务说明: %s", g_eReqs[id][szDesc]);
	AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);
	
	Format(szItem, 256, "%d", id);
	AddMenuItem(menu, szItem, "接受任务");
	AddMenuItem(menu, "no", "我不干了");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public int MenuHandler_ConfirmReq(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		if(!StrEqual(info, "no"))
		{
			int id = StringToInt(info);

			CG_SetReqID(client, id);
			CG_SetReqTerm(client, g_eReqs[id][iTerm]);
			CG_SetReqRate(client, 0);
			CG_SaveReq(client);
			
			PrintToChat(client, "%s  你已经承接任务[\x04%s\x01]", PREFIX, g_eReqs[id][szName]);
		}
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public void InitializingRedDatabase()
{
	for(int i; i < 1000; ++i)
	{
		g_eReqs[i][iLvl] = -1;
		
		//for  zombiereloaded
		if(i == 1)
		{
			g_eReqs[i][iId] = i;
			g_eReqs[i][iLvl] = 5;
			g_eReqs[i][iTerm] = 10;
			g_eReqs[i][iAwdShare] = 40;
			g_eReqs[i][iAwdCredit] = 20;
			strcopy(g_eReqs[i][szLvls], 16, "E级");
			strcopy(g_eReqs[i][szName], 32, "初来乍到");
			strcopy(g_eReqs[i][szDesc], 64, "在僵尸逃跑服务器进行10局游戏");
			strcopy(g_eReqs[i][szAwds], 64, "Share+40|Credits+20");
		}
		if(i == 2)
		{
			g_eReqs[i][iId] = i;
			g_eReqs[i][iLvl] = 5;
			g_eReqs[i][iTerm] = 200000;
			g_eReqs[i][iAwdShare] = 40;
			g_eReqs[i][iAwdCredit] = 20;
			strcopy(g_eReqs[i][szLvls], 16, "E级");
			strcopy(g_eReqs[i][szName], 32, "火力填充");
			strcopy(g_eReqs[i][szDesc], 64, "在僵尸逃跑服务器造成20万点伤害");
			strcopy(g_eReqs[i][szAwds], 64, "Share+40|Credits+20");
		}
		if(i == 11)
		{
			g_eReqs[i][iId] = i;
			g_eReqs[i][iLvl] = 4;
			g_eReqs[i][iTerm] = 10;
			g_eReqs[i][iAwdShare] = 60;
			g_eReqs[i][iAwdCredit] = 30;
			strcopy(g_eReqs[i][szLvls], 16, "D级");
			strcopy(g_eReqs[i][szName], 32, "刷他妈的");
			strcopy(g_eReqs[i][szDesc], 64, "在僵尸逃跑服务器击杀10只僵尸");
			strcopy(g_eReqs[i][szAwds], 64, "Share+60|Credits+30");
		}
		if(i == 12)
		{
			g_eReqs[i][iId] = i;
			g_eReqs[i][iLvl] = 4;
			g_eReqs[i][iTerm] = 100;
			g_eReqs[i][iAwdShare] = 60;
			g_eReqs[i][iAwdCredit] = 30;
			strcopy(g_eReqs[i][szLvls], 16, "D级");
			strcopy(g_eReqs[i][szName], 32, "瞎眼神器");
			strcopy(g_eReqs[i][szDesc], 64, "在僵尸逃跑服务器使用人类神器100次");
			strcopy(g_eReqs[i][szAwds], 64, "Share+60|Credits+30");
		}
		if(i == 21)
		{
			g_eReqs[i][iId] = i;
			g_eReqs[i][iLvl] = 3;
			g_eReqs[i][iTerm] = 10;
			g_eReqs[i][iAwdShare] = 100;
			g_eReqs[i][iAwdCredit] = 50;
			strcopy(g_eReqs[i][szLvls], 16, "C级");
			strcopy(g_eReqs[i][szName], 32, "渐行渐远");
			strcopy(g_eReqs[i][szDesc], 64, "在僵尸逃跑服务器神图人类获胜10局");
			strcopy(g_eReqs[i][szAwds], 64, "Share+100|Credits+50");
		}
		if(i == 22)
		{
			g_eReqs[i][iId] = i;
			g_eReqs[i][iLvl] = 3;
			g_eReqs[i][iTerm] = 15;
			g_eReqs[i][iAwdShare] = 100;
			g_eReqs[i][iAwdCredit] = 50;
			strcopy(g_eReqs[i][szLvls], 16, "C级");
			strcopy(g_eReqs[i][szName], 32, "你头真大");
			strcopy(g_eReqs[i][szDesc], 64, "在僵尸逃跑服务器爆头击杀15只僵尸");
			strcopy(g_eReqs[i][szAwds], 64, "Share+100|Credits+50");
		}
		if(i == 31)
		{
			g_eReqs[i][iId] = i;
			g_eReqs[i][iLvl] = 2;
			g_eReqs[i][iTerm] = 30;
			g_eReqs[i][iAwdShare] = 160;
			g_eReqs[i][iAwdCredit] = 80;
			strcopy(g_eReqs[i][szLvls], 16, "B级");
			strcopy(g_eReqs[i][szName], 32, "瓦哥之怒");
			strcopy(g_eReqs[i][szDesc], 64, "在僵尸逃跑服务器终结者击杀30只僵尸");
			strcopy(g_eReqs[i][szAwds], 64, "Share+160|Credits+80");
		}
		if(i == 41)
		{
			g_eReqs[i][iId] = i;
			g_eReqs[i][iLvl] = 1;
			g_eReqs[i][iTerm] = 10;
			g_eReqs[i][iAwdShare] = 200;
			g_eReqs[i][iAwdCredit] = 100;
			strcopy(g_eReqs[i][szLvls], 16, "A级");
			strcopy(g_eReqs[i][szName], 32, "都听我的");
			strcopy(g_eReqs[i][szDesc], 64, "在僵尸逃跑服务器神图指挥官指挥通关10次");
			strcopy(g_eReqs[i][szAwds], 64, "Share+200|Credits+100");
		}
		if(i == 51)
		{
			g_eReqs[i][iId] = i;
			g_eReqs[i][iLvl] = 0;
			g_eReqs[i][iTerm] = 1;
			g_eReqs[i][iAwdShare] = 400;
			g_eReqs[i][iAwdCredit] = 200;
			strcopy(g_eReqs[i][szLvls], 16, "S级");
			strcopy(g_eReqs[i][szName], 32, "神勇无敌");
			strcopy(g_eReqs[i][szDesc], 64, "在僵尸逃跑服务器使用终结者SOLO Win通关1次");
			strcopy(g_eReqs[i][szAwds], 64, "Share+400|Credits+200");
		}
		
		//for TTT
		if(i == 101)
		{
			g_eReqs[i][iId] = i;
			g_eReqs[i][iLvl] = 5;
			g_eReqs[i][iTerm] = 20;
			g_eReqs[i][iAwdShare] = 40;
			g_eReqs[i][iAwdCredit] = 20;
			strcopy(g_eReqs[i][szLvls], 16, "E级");
			strcopy(g_eReqs[i][szName], 32, "影帝之路");
			strcopy(g_eReqs[i][szDesc], 64, "在匪镇谍影服务器进行20局游戏");
			strcopy(g_eReqs[i][szAwds], 64, "Share+40|Credits+20");
		}
		if(i == 102)
		{
			g_eReqs[i][iId] = i;
			g_eReqs[i][iLvl] = 5;
			g_eReqs[i][iTerm] = 16;
			g_eReqs[i][iAwdShare] = 40;
			g_eReqs[i][iAwdCredit] = 20;
			strcopy(g_eReqs[i][szLvls], 16, "E级");
			strcopy(g_eReqs[i][szName], 32, "平民日常");
			strcopy(g_eReqs[i][szDesc], 64, "在匪镇谍影服务器以平民身份获胜16局");
			strcopy(g_eReqs[i][szAwds], 64, "Share+40|Credits+20");
		}
		if(i == 103)
		{
			g_eReqs[i][iId] = i;
			g_eReqs[i][iLvl] = 5;
			g_eReqs[i][iTerm] = 30;
			g_eReqs[i][iAwdShare] = 40;
			g_eReqs[i][iAwdCredit] = 20;
			strcopy(g_eReqs[i][szLvls], 16, "E级");
			strcopy(g_eReqs[i][szName], 32, "叛徒日常");
			strcopy(g_eReqs[i][szDesc], 64, "在匪镇谍影服务器以叛徒正确击杀30人");
			strcopy(g_eReqs[i][szAwds], 64, "Share+40|Credits+20");
		}
		if(i == 111)
		{
			g_eReqs[i][iId] = i;
			g_eReqs[i][iLvl] = 4;
			g_eReqs[i][iTerm] = 20;
			g_eReqs[i][iAwdShare] = 60;
			g_eReqs[i][iAwdCredit] = 30;
			strcopy(g_eReqs[i][szLvls], 16, "D级");
			strcopy(g_eReqs[i][szName], 32, "干死侦探");
			strcopy(g_eReqs[i][szDesc], 64, "在匪镇谍影服务器击杀20名侦探");
			strcopy(g_eReqs[i][szAwds], 64, "Share+60|Credits+30");
		}
		if(i == 121)
		{
			g_eReqs[i][iId] = i;
			g_eReqs[i][iLvl] = 3;
			g_eReqs[i][iTerm] = 50;
			g_eReqs[i][iAwdShare] = 100;
			g_eReqs[i][iAwdCredit] = 50;
			strcopy(g_eReqs[i][szLvls], 16, "C级");
			strcopy(g_eReqs[i][szName], 32, "我是影帝");
			strcopy(g_eReqs[i][szDesc], 64, "在匪镇谍影服务器击杀50个平民");
			strcopy(g_eReqs[i][szAwds], 64, "Share+100|Credits+50");
		}
		if(i == 131)
		{
			g_eReqs[i][iId] = i;
			g_eReqs[i][iLvl] = 2;
			g_eReqs[i][iTerm] = 30;
			g_eReqs[i][iAwdShare] = 160;
			g_eReqs[i][iAwdCredit] = 80;
			strcopy(g_eReqs[i][szLvls], 16, "B级");
			strcopy(g_eReqs[i][szName], 32, "你太鶸了");
			strcopy(g_eReqs[i][szDesc], 64, "在匪镇谍影服务器击杀30名叛徒");
			strcopy(g_eReqs[i][szAwds], 64, "Share+160|Credits+80");
		}
		if(i == 141)
		{
			g_eReqs[i][iId] = i;
			g_eReqs[i][iLvl] = 1;
			g_eReqs[i][iTerm] = 12;
			g_eReqs[i][iAwdShare] = 200;
			g_eReqs[i][iAwdCredit] = 100;
			strcopy(g_eReqs[i][szLvls], 16, "A级");
			strcopy(g_eReqs[i][szName], 32, "神挡杀神");
			strcopy(g_eReqs[i][szDesc], 64, "在匪镇谍影服务器一局正确击杀12名玩家");
			strcopy(g_eReqs[i][szAwds], 64, "Share+200|Credits+100");
		}
		if(i == 151)
		{
			g_eReqs[i][iId] = i;
			g_eReqs[i][iLvl] = 0;
			g_eReqs[i][iTerm] = 18;
			g_eReqs[i][iAwdShare] = 400;
			g_eReqs[i][iAwdCredit] = 200;
			strcopy(g_eReqs[i][szLvls], 16, "S级");
			strcopy(g_eReqs[i][szName], 32, "佛挡杀佛");
			strcopy(g_eReqs[i][szDesc], 64, "在匪镇谍影服务器一局正确击杀18名玩家");
			strcopy(g_eReqs[i][szAwds], 64, "Share+400|Credits+200");
		}
		
		//for MiniGame
		if(i == 201)
		{
			g_eReqs[i][iId] = i;
			g_eReqs[i][iLvl] = 5;
			g_eReqs[i][iTerm] = 20;
			g_eReqs[i][iAwdShare] = 40;
			g_eReqs[i][iAwdCredit] = 20;
			strcopy(g_eReqs[i][szLvls], 16, "E级");
			strcopy(g_eReqs[i][szName], 32, "无证驾驶");
			strcopy(g_eReqs[i][szDesc], 64, "在娱乐休闲服务器进行20局游戏");
			strcopy(g_eReqs[i][szAwds], 64, "Share+40|Credits+20");
		}
		if(i == 211)
		{
			g_eReqs[i][iId] = i;
			g_eReqs[i][iLvl] = 4;
			g_eReqs[i][iTerm] = 10;
			g_eReqs[i][iAwdShare] = 60;
			g_eReqs[i][iAwdCredit] = 30;
			strcopy(g_eReqs[i][szLvls], 16, "D级");
			strcopy(g_eReqs[i][szName], 32, "一刀见血");
			strcopy(g_eReqs[i][szDesc], 64, "在娱乐休闲服务器使用匕首背刺击杀10个玩家");
			strcopy(g_eReqs[i][szAwds], 64, "Share+60|Credits+30");
		}
		if(i == 221)
		{
			g_eReqs[i][iId] = i;
			g_eReqs[i][iLvl] = 3;
			g_eReqs[i][iTerm] = 10;
			g_eReqs[i][iAwdShare] = 100;
			g_eReqs[i][iAwdCredit] = 50;
			strcopy(g_eReqs[i][szLvls], 16, "C级");
			strcopy(g_eReqs[i][szName], 32, "我要电鸡");
			strcopy(g_eReqs[i][szDesc], 64, "在娱乐休闲服务器使用电击枪击杀10个玩家");
			strcopy(g_eReqs[i][szAwds], 64, "Share+100|Credits+50");
		}
		if(i == 231)
		{
			g_eReqs[i][iId] = i;
			g_eReqs[i][iLvl] = 2;
			g_eReqs[i][iTerm] = 10;
			g_eReqs[i][iAwdShare] = 160;
			g_eReqs[i][iAwdCredit] = 80;
			strcopy(g_eReqs[i][szLvls], 16, "B级");
			strcopy(g_eReqs[i][szName], 32, "武神附体");
			strcopy(g_eReqs[i][szDesc], 64, "在娱乐休闲服务器非刷分图一局击杀10个玩家");
			strcopy(g_eReqs[i][szAwds], 64, "Share+160|Credits+80");
		}
		if(i == 241)
		{
			g_eReqs[i][iId] = i;
			g_eReqs[i][iLvl] = 1;
			g_eReqs[i][iTerm] = 12;
			g_eReqs[i][iAwdShare] = 200;
			g_eReqs[i][iAwdCredit] = 100;
			strcopy(g_eReqs[i][szLvls], 16, "A级");
			strcopy(g_eReqs[i][szName], 32, "小李飞刀");
			strcopy(g_eReqs[i][szDesc], 64, "在娱乐休闲服务器使用匕首一局内刀杀10名玩家");
			strcopy(g_eReqs[i][szAwds], 64, "Share+200|Credits+100");
		}
		if(i == 251)
		{
			g_eReqs[i][iId] = i;
			g_eReqs[i][iLvl] = 0;
			g_eReqs[i][iTerm] = 18;
			g_eReqs[i][iAwdShare] = 400;
			g_eReqs[i][iAwdCredit] = 200;
			strcopy(g_eReqs[i][szLvls], 16, "S级");
			strcopy(g_eReqs[i][szName], 32, "女神之光");
			strcopy(g_eReqs[i][szDesc], 64, "在娱乐休闲服务器非刷分图ACE");
			strcopy(g_eReqs[i][szAwds], 64, "Share+400|Credits+200");
		}
		
	}
}