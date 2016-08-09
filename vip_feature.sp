#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <cstrike>


enum Client
{
	iType,
	iBoom,
	bool:bDrug,
	bool:Blind,
	bool:bBurn,
	bool:bBoom,
	
}
Client g_eClient[MAXPLAYERS+1][Client];
int g_iYESS = 0;
int g_iVOTE = 0;
int g_iFUCK = 0;
bool g_bInVote;
char logFile[128];

public Plugin myinfo = 
{
	name = "VIP Feature",
	author = "maoling ( xQy )",
	description = "VIP features",
	version = "1.0",
	url = "http://steamcommunity.com/id/_xQy_/"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_vip", Command_VipMenu, ADMFLAG_CUSTOM6);
	RegAdminCmd("sm_v", Command_VipMenu, ADMFLAG_CUSTOM6);

	BuildPath(Path_SM, logFile, 256, "logs/VIP.log");

	HookEvent("player_spawn", Event_PlayerSpawn);
}

public void OnMapStart() 
{
	g_iFUCK = 0;
	g_iYESS = 0;
	g_iVOTE = 0;
	g_bInVote = false;
	
	if(FindPluginByFile("mg_stats.smx") || FindPluginByFile("ct.smx") || FindPluginByFile("sm_hosties.smx") || FindPluginByFile("hg.smx"))
	{
		PrecacheSound("weapons/hegrenade/explode3.wav");
		PrecacheSound("weapons/hegrenade/explode4.wav");
		PrecacheSound("weapons/hegrenade/explode5.wav");
	}
}

public void OnClientPutInServer(int client)
{
	g_eClient[client][iBoom] = 0;
	g_eClient[client][iType] = 0;
	g_eClient[client][bDrug] = false;
	g_eClient[client][Blind] = false;
	g_eClient[client][bBurn] = false;
	g_eClient[client][bBoom] = false;
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	g_eClient[client][iBoom] = 0;
	g_eClient[client][bDrug] = false;
	g_eClient[client][Blind] = false;
	g_eClient[client][bBurn] = false;
	g_eClient[client][bBoom] = false;
}

public Action Command_VipMenu(int client, int args)
{
	Handle menu = CreateMenu(MenuHandler_VipMenu);
	SetMenuTitle(menu, "[CG] - VIP菜单");


	AddMenuItem(menu, "drug", "吸一口吧", (g_eClient[client][bDrug] == true && IsPlayerAlive(client) == true) ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	AddMenuItem(menu, "blin", "自戳双目", (g_eClient[client][Blind] == true && IsPlayerAlive(client) == true) ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	AddMenuItem(menu, "burn", "玩火自焚", (g_eClient[client][bBurn] == true && IsPlayerAlive(client) == true) ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	AddMenuItem(menu, "boom", "这很清真", (g_eClient[client][bBoom] == true && IsPlayerAlive(client) == true) ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	AddMenuItem(menu, " ", " ",ITEMDRAW_SPACER);
	AddMenuItem(menu, " ", " ",ITEMDRAW_SPACER);
	
	AddMenuItem(menu, "emap", "延长地图", g_iFUCK > 3 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	AddMenuItem(menu, "cmap", "更换地图", g_iFUCK > 3 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	AddMenuItem(menu, " ", " ",ITEMDRAW_SPACER);
	AddMenuItem(menu, " ", " ",ITEMDRAW_SPACER);
	AddMenuItem(menu, " ", " ",ITEMDRAW_SPACER);
	AddMenuItem(menu, " ", " ",ITEMDRAW_SPACER);
	
	AddMenuItem(menu, "slay", "处死玩家", g_iFUCK > 3 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	AddMenuItem(menu, "shit", "禁言玩家", g_iFUCK > 3 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	AddMenuItem(menu, "mute", "禁麦玩家", g_iFUCK > 3 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	AddMenuItem(menu, "down", "沉默玩家", g_iFUCK > 3 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	AddMenuItem(menu, "kick", "踢出玩家", g_iFUCK > 3 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	AddMenuItem(menu, "fuck", "封禁玩具", g_iFUCK > 3 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 20);

	return Plugin_Handled;
}

public int MenuHandler_VipMenu(Menu menu, MenuAction action, int client, int item)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			GetMenuItem(menu, item, info, 32);

			if(StrEqual(info, "drug"))
			{
				g_eClient[client][bDrug] = true;
				SetClientDrug(client, true);
				PrintToChatAll("[\x10VIP\x01]  \x04%N\x01选择了[\x07吸一口吧\x01]", client);
				LogToFile(logFile, " %N => 吸一口吧 ", client);
			}
			else if(StrEqual(info, "blin"))
			{
				g_eClient[client][Blind] = true;
				SetClientBlind(client, 255);
				PrintToChatAll("[\x10VIP\x01]  \x04%N\x01选择了[\x07自戳双目\x01]", client);
				LogToFile(logFile, " %N => 自戳双目 ", client);
			}
			else if(StrEqual(info, "burn"))
			{
				g_eClient[client][bBurn] = true;
				if(IsPlayerAlive(client))
					IgniteEntity(client, 120.0);
				PrintToChatAll("[\x10VIP\x01]  \x04%N\x01选择了[\x07玩火自焚\x01]", client);
				LogToFile(logFile, " %N => 玩火自焚 ", client);
			}
			else if(StrEqual(info, "boom"))
			{
				g_eClient[client][bBoom] = true;
				if(IsPlayerAlive(client))
				{
					g_eClient[client][iBoom] = 10;
					CreateTimer(1.0, Timer_Boom, GetClientUserId(client), TIMER_REPEAT);
					PrintToChat(client, " ***\x02  你还有10秒就去见安拉了  \x01***");
				}
				PrintToChatAll("[\x10VIP\x01]  \x04%N\x01选择了[\x07这很清真\x01]", client);
				LogToFile(logFile, " %N => 这很清真 ", client);
			}
			else if(StrEqual(info, "emap"))
			{
				ShowMapMenu(client, true);
			}
			else if(StrEqual(info, "cmap"))
			{
				ShowMapMenu(client, false);
			}
			else if(StrEqual(info, "slay"))
			{
				ShowSlayMenu(client);
			}
			else if(StrEqual(info, "shit"))
			{
				ShowPlayerMenu(client, 0);
			}
			else if(StrEqual(info, "mute"))
			{
				ShowPlayerMenu(client, 1);
			}
			else if(StrEqual(info, "down"))
			{
				ShowPlayerMenu(client, 2);
			}
			else if(StrEqual(info, "kick"))
			{
				ShowPlayerMenu(client, 3);
			}
			else if(StrEqual(info, "fuck"))
			{
				ShowPlayerMenu(client, 3);
			}
		}
	}

}

public void ShowMapMenu(int client, bool extend)
{
	if(g_bInVote)
	{
		PrintToChat(client, "[\x10VIP\x01]  \x04当前投票进行中...");
		return;
	}

	char szItem[128];

	Handle menu = CreateMenu(MenuHandler_VoteProcess);
	
	if(extend)
		Format(szItem, 128, "[CG] - VIP菜单 \n %N 想延长地图\n ", client);
	else
		Format(szItem, 128, "[CG] - VIP菜单 \n %N 想更换地图\n ", client);

	SetMenuTitle(menu, szItem);
	
	AddMenuItem(menu, " ", " ",ITEMDRAW_SPACER);
	AddMenuItem(menu, " ", " ",ITEMDRAW_SPACER);
	AddMenuItem(menu, " ", " ",ITEMDRAW_SPACER);
	AddMenuItem(menu, " ", " ",ITEMDRAW_SPACER);
	
	AddMenuItem(menu, "yes", "同意");
	AddMenuItem(menu, "noo", "反对");
	
	for(int x = 1; x <= MaxClients; ++x)
	{
		if(IsClientInGame(x))
		{
			SetMenuExitButton(menu, true);
			DisplayMenu(menu, x, 15);
		}
	}
	
	Handle pack;
	CreateDataTimer(15.0, Timer_MapVote, pack);
	WritePackCell(pack, client);
	WritePackCell(pack, extend);
	
	g_bInVote = true;
}

public int MenuHandler_VoteProcess(Menu menu, MenuAction action, int client, int item)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			GetMenuItem(menu, item, info, 32);
			
			if(StrEqual(info, "yes"))
				g_iYESS++;
			
			g_iVOTE++;
		}
	}
}

public Action Timer_MapVote(Handle timer, Handle pack)
{
	if(g_iVOTE == 0 || g_iYESS == 0)
	{
		PrintToChatAll("[\x10VIP\x01]  \x04投票人数不足,本次投票失败");
		return Plugin_Stop;
	}
	
	ResetPack(pack);
	int client = ReadPackCell(pack);
	bool extend = ReadPackCell(pack);
	float ratio = float(g_iYESS)/float(g_iVOTE);
	
	if(ratio >= 0.55)
	{
		if(extend)
		{		
			g_iFUCK++;
			SetConVarInt(FindConVar("mp_timelimit"), GetConVarInt(FindConVar("mp_timelimit"))+20);
			PrintToChatAll("[\x10VIP\x01]  \x0C投票成功[\x04%d%%赞同\x0C],已将当前地图延长20分钟", RoundToNearest(ratio*100.0));
			LogToFile(logFile, " %N => 延长地图 => 成功 ", client);
		}
		else
		{
			g_iFUCK++;
			ServerCommand("sm_forcertv");
			PrintToChatAll("[\x10VIP\x01]  \x0C投票成功[\x04%d%%赞同\x0C],已启动换图投票", RoundToNearest(ratio*100.0));
			LogToFile(logFile, " %N => 更换地图 => 成功 ", client);
		}
	}
	else
	{
		if(extend)
			LogToFile(logFile, " %N => 延长地图 => 失败 ", client);
		else
			LogToFile(logFile, " %N => 更换地图 => 失败 ", client);

		g_iFUCK++;
		PrintToChatAll("[\x10VIP\x01]  \x07投票失败[\x04%d%%赞同\x0C]", RoundToNearest(ratio*100.0));
	}
	
	g_bInVote = false;
	g_iVOTE = 0;
	g_iYESS = 0;
	
	return Plugin_Stop;
}

public void ShowSlayMenu(int client)
{
	if(g_bInVote)
	{
		PrintToChat(client, "[\x10VIP\x01]  \x04当前投票进行中...");
		return;
	}

	Handle menu = CreateMenu(MenuHandler_SlayMenu);
	SetMenuTitle(menu, "[CG] - VIP菜单 \n 处死菜单");

	AddMenuItem(menu, "-1", "ALL");
	AddMenuItem(menu, "-2", "TEs");
	AddMenuItem(menu, "-3", "CTs");
	
	char szUserId[16];
	char szItem[128];
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(IsClientInGame(i))
		{
			if(!(GetUserFlagBits(i) & ADMFLAG_ROOT))
			{
				Format(szUserId, 16, "%d", GetClientUserId(i));
				Format(szItem, 128, "%N", i);
				AddMenuItem(menu, szUserId, szItem);
			}
		}
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public int MenuHandler_SlayMenu(Menu menu, MenuAction action, int client, int item)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			GetMenuItem(menu, item, info, 32);
			
			ShowSlayToAll(client, StringToInt(info));
		}
	}
}

public void ShowSlayToAll(int client, int id)
{
	char szItem[128];

	Handle menu = CreateMenu(MenuHandler_VoteProcess);
	
	if(id == -1)
		Format(szItem, 128, "[CG] - VIP菜单 \n %N 想处死 全部人\n ", client);
	else if(id == -2)
		Format(szItem, 128, "[CG] - VIP菜单 \n %N 想处死 恐怖分子\n ", client);
	else if(id == -3)
		Format(szItem, 128, "[CG] - VIP菜单 \n %N 想处死 反恐精英\n ", client);
	else
		Format(szItem, 128, "[CG] - VIP菜单 \n %N 想处死 %N\n ", client, GetClientOfUserId(id));

	SetMenuTitle(menu, szItem);
	
	AddMenuItem(menu, " ", " ", ITEMDRAW_SPACER);
	AddMenuItem(menu, " ", " ", ITEMDRAW_SPACER);
	AddMenuItem(menu, " ", " ", ITEMDRAW_SPACER);
	AddMenuItem(menu, " ", " ", ITEMDRAW_SPACER);
	
	AddMenuItem(menu, "yes", "同意");
	AddMenuItem(menu, "noo", "反对");
	
	for(int x = 1; x <= MaxClients; ++x)
	{
		if(IsClientInGame(x))
		{
			SetMenuExitButton(menu, true);
			DisplayMenu(menu, x, 15);
		}
	}
	
	Handle pack;
	CreateDataTimer(15.0, Timer_SlayVote, pack);
	WritePackCell(pack, client);
	WritePackCell(pack, id);
	
	g_bInVote = true;
}

public Action Timer_SlayVote(Handle timer, Handle pack)
{
	if(g_iVOTE == 0 || g_iYESS == 0)
	{
		PrintToChatAll("[\x10VIP\x01]  \x04投票人数不足,本次投票失败");
		return Plugin_Stop;
	}
	
	ResetPack(pack);
	int client = ReadPackCell(pack);
	int id = ReadPackCell(pack);
	float ratio = float(g_iYESS)/float(g_iVOTE);
	
	if(ratio >= 0.7)
	{
		if(id == -1)
		{
			for(int i = 1; i <= MaxClients; ++i)
				if(IsClientInGame(i))
					if(IsPlayerAlive(i))
						if(!(GetUserFlagBits(i) & ADMFLAG_ROOT))
							ForcePlayerSuicide(i);

			g_iFUCK++;
			PrintToChatAll("[\x10VIP\x01]  \x0C投票成功[\x04%d%%赞同\x0C],执行处死全部人", RoundToNearest(ratio*100.0));
			LogToFile(logFile, " %N => 处死全部人 => 成功 ", client);
		}
		else if(id == -2)
		{
			for(int i = 1; i <= MaxClients; ++i)
				if(IsClientInGame(i))
					if(IsPlayerAlive(i))
						if(GetClientTeam(i) == 2)
							if(!(GetUserFlagBits(i) & ADMFLAG_ROOT))
								ForcePlayerSuicide(i);

			g_iFUCK++;
			PrintToChatAll("[\x10VIP\x01]  \x0C投票成功[\x04%d%%赞同\x0C],执行处死恐怖分子", RoundToNearest(ratio*100.0));
			LogToFile(logFile, " %N => 处死恐怖分子 => 成功 ", client);
		}
		else if(id == -3)
		{
			for(int i = 1; i <= MaxClients; ++i)
				if(IsClientInGame(i))
					if(IsPlayerAlive(i))
						if(GetClientTeam(i) == 3)
							if(!(GetUserFlagBits(i) & ADMFLAG_ROOT))
								ForcePlayerSuicide(i);

			g_iFUCK++;
			PrintToChatAll("[\x10VIP\x01]  \x0C投票成功[\x04%d%%赞同\x0C],执行处死反恐精英", RoundToNearest(ratio*100.0));
			LogToFile(logFile, " %N => 处死反恐精英 => 成功 ", client);
		}
		else
		{
			int target = GetClientOfUserId(id);
			if(IsClientInGame(target))
				if(IsPlayerAlive(target))
					if(!(GetUserFlagBits(target) & ADMFLAG_ROOT))
						ForcePlayerSuicide(target);
					
			g_iFUCK++;
			PrintToChatAll("[\x10VIP\x01]  \x0C投票成功[\x04%d%%赞同\x0C],执行处死 %N", RoundToNearest(ratio*100.0), target);
			LogToFile(logFile, " %N => 处死 %N => 成功 ", client, target);
		}
	}
	else
	{
		if(id < 0)
			LogToFile(logFile, " %N => 处死id %d  => 失败 ", client, id);
		else
			LogToFile(logFile, " %N => 处死 %N  => 失败 ", client, GetClientOfUserId(id));
		
		g_iFUCK++;
		PrintToChatAll("[\x10VIP\x01]  \x07投票失败[\x04%d%%赞同\x0C]", RoundToNearest(ratio*100.0));
	}
	
	g_bInVote = false;
	g_iVOTE = 0;
	g_iYESS = 0;
	
	return Plugin_Stop;
}

public void ShowPlayerMenu(int client, int type)
{
	if(g_bInVote)
	{
		PrintToChat(client, "[\x10VIP\x01]  \x04当前投票进行中...");
		return;
	}

	char szItem[128];

	Handle menu = CreateMenu(MenuHandler_PlayerMenu);
	
	if(type == 0)
		Format(szItem, 128, "[CG] - VIP菜单 \n 禁言菜单\n ");
	else if(type == 1)
		Format(szItem, 128, "[CG] - VIP菜单 \n 禁麦菜单\n ");
	else if(type == 2)
		Format(szItem, 128, "[CG] - VIP菜单 \n 沉默菜单\n ");
	else if(type == 3)
		Format(szItem, 128, "[CG] - VIP菜单 \n 踢人菜单\n ");
	else if(type == 4)
		Format(szItem, 128, "[CG] - VIP菜单 \n 封禁菜单\n ");

	SetMenuTitle(menu, szItem);

	char szUserId[16];
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(IsClientInGame(i))
		{
			if(!(GetUserFlagBits(i) & ADMFLAG_ROOT))
			{
				Format(szUserId, 16, "%d", GetClientUserId(i));
				Format(szItem, 128, "%N", i);
				AddMenuItem(menu, szUserId, szItem);
			}
		}
	}
	
	g_eClient[client][iType] = type;
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
	
	g_bInVote = true;
}

public int MenuHandler_PlayerMenu(Menu menu, MenuAction action, int client, int item)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			GetMenuItem(menu, item, info, 32);

			ShowMenuToAll(client, StringToInt(info), g_eClient[client][iType]);
		}
	}
}

public void ShowMenuToAll(int client, int userid, int type)
{
	char szItem[128];

	Handle menu = CreateMenu(MenuHandler_VoteProcess);
	
	if(type == 0)
		Format(szItem, 128, "[CG] - VIP菜单 \n %N 想禁言 %N\n ", client, GetClientOfUserId(userid));
	else if(type == 1)
		Format(szItem, 128, "[CG] - VIP菜单 \n %N 想禁麦 %N\n ", client, GetClientOfUserId(userid));
	else if(type == 2)
		Format(szItem, 128, "[CG] - VIP菜单 \n %N 想沉默 %N\n ", client, GetClientOfUserId(userid));
	else if(type == 3)
		Format(szItem, 128, "[CG] - VIP菜单 \n %N 想踢出 %N\n ", client, GetClientOfUserId(userid));
	else if(type == 4)
		Format(szItem, 128, "[CG] - VIP菜单 \n %N 想封禁 %N\n ", client, GetClientOfUserId(userid));
	
	SetMenuTitle(menu, szItem);
	
	AddMenuItem(menu, " ", " ", ITEMDRAW_SPACER);
	AddMenuItem(menu, " ", " ", ITEMDRAW_SPACER);
	AddMenuItem(menu, " ", " ", ITEMDRAW_SPACER);
	AddMenuItem(menu, " ", " ", ITEMDRAW_SPACER);
	
	AddMenuItem(menu, "yes", "同意");
	AddMenuItem(menu, "noo", "反对");
	
	for(int x = 1; x <= MaxClients; ++x)
	{
		if(IsClientInGame(x))
		{
			SetMenuExitButton(menu, true);
			DisplayMenu(menu, x, 15);
		}
	}
	
	Handle pack;
	CreateDataTimer(15.0, Timer_PlayerVote, pack);
	WritePackCell(pack, client);
	WritePackCell(pack, userid);
	WritePackCell(pack, type);
}

public Action Timer_PlayerVote(Handle timer, Handle pack)
{
	if(g_iVOTE == 0 || g_iYESS == 0)
	{
		PrintToChatAll("[\x10VIP\x01]  \x04投票人数不足,本次投票失败");
		return Plugin_Stop;
	}
	
	ResetPack(pack);
	int client = ReadPackCell(pack);
	int userid = ReadPackCell(pack);
	int type = ReadPackCell(pack);
	float ratio = float(g_iYESS)/float(g_iVOTE);
	
	if(ratio >= 0.8)
	{
		if(type == 0)
		{
			g_iFUCK++;
			ServerCommand("sm_gag %d 30 \"%N发起VIP投票\"", userid, client);
			PrintToChatAll("[\x10VIP\x01]  \x0C投票成功[\x04%d%%赞同\x0C],执行禁言\x07%N", RoundToNearest(ratio*100.0), GetClientOfUserId(userid));
			LogToFile(logFile, " %N => 禁言 %N => 成功 ", client, GetClientOfUserId(userid));
		}
		else if(type == 1)
		{
			g_iFUCK++;
			ServerCommand("sm_mute %d 30 \"%N发起VIP投票\"", userid, client);
			PrintToChatAll("[\x10VIP\x01]  \x0C投票成功[\x04%d%%赞同\x0C],执行禁麦\x07%N", RoundToNearest(ratio*100.0), GetClientOfUserId(userid));
			LogToFile(logFile, " %N => 禁麦 %N => 成功 ", client, GetClientOfUserId(userid));
		}
		else if(type == 2)
		{
			g_iFUCK++;
			ServerCommand("sm_silence %d 30 \"%N发起VIP投票\"", userid, client);
			PrintToChatAll("[\x10VIP\x01]  \x0C投票成功[\x04%d%%赞同\x0C],执行沉默\x07%N", RoundToNearest(ratio*100.0), GetClientOfUserId(userid));
			LogToFile(logFile, " %N => 沉默 %N => 成功 ", client, GetClientOfUserId(userid));
		}
		else if(type == 3)
		{
			g_iFUCK++;
			ServerCommand("sm_kick %d \"%N发起VIP投票\"", userid, client);
			PrintToChatAll("[\x10VIP\x01]  \x0C投票成功[\x04%d%%赞同\x0C],执行踢出\x07%N", RoundToNearest(ratio*100.0), GetClientOfUserId(userid));
			LogToFile(logFile, " %N => 踢出 %N => 成功 ", client, GetClientOfUserId(userid));
		}
		else if(type == 4)
		{
			g_iFUCK++;
			ServerCommand("sm_ban %d 30 \"%N发起VIP投票\"", userid, client);
			PrintToChatAll("[\x10VIP\x01]  \x0C投票成功[\x04%d%%赞同\x0C],执行封禁\x07%N", RoundToNearest(ratio*100.0), GetClientOfUserId(userid));
			LogToFile(logFile, " %N => 封禁 %N => 成功 ", client, GetClientOfUserId(userid));
		}
	}
	else
	{
		g_iFUCK++;
		LogToFile(logFile, " %N => [type %d] %N  => 失败 ", client, type, GetClientOfUserId(userid));
		PrintToChatAll("[\x10VIP\x01]  \x07投票失败[\x04%d%%赞同\x0C]", RoundToNearest(ratio*100.0));
	}
	
	g_bInVote = false;
	g_iVOTE = 0;
	g_iYESS = 0;
	
	return Plugin_Stop;
}

stock void SetClientBlind(int client, int counts)
{
	int targets[2];
	targets[0] = client;
	
	int duration = 1536;
	int holdtime = 1536;
	int flags;
	if(counts == 0)
	{
		flags = (0x0001 | 0x0010);
	}
	else
	{
		flags = (0x0002 | 0x0008);
	}
	
	int color[4] = { 0, 0, 0, 0 };
	color[3] = counts;
	
	Handle message = StartMessageEx(GetUserMessageId("Fade"), targets, 1);
	if(GetUserMessageType() == UM_Protobuf)
	{
		Protobuf pb = UserMessageToProtobuf(message);
		pb.SetInt("duration", duration);
		pb.SetInt("hold_time", holdtime);
		pb.SetInt("flags", flags);
		pb.SetColor("clr", color);
	}
	else
	{
		BfWrite bf = UserMessageToBfWrite(message);
		bf.WriteShort(duration);
		bf.WriteShort(holdtime);
		bf.WriteShort(flags);		
		bf.WriteByte(color[0]);
		bf.WriteByte(color[1]);
		bf.WriteByte(color[2]);
		bf.WriteByte(color[3]);
	}

	EndMessage();
}

Handle g_DrugTimers[MAXPLAYERS+1];
float g_DrugAngles[22] = {0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 30.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -30.0, -20.0, -15.0, -10.0, -5.0};

stock void SetClientDrug(int target, bool create)
{
	if(create)
	{
		if(g_DrugTimers[target] == null)
		{
			CreateDrug(target);
		}	
	}
	else
	{
		if (g_DrugTimers[target] != null)
		{
			KillDrug(target);
		}
	}
}

stock void CreateDrug(int client)
{
	g_DrugTimers[client] = CreateTimer(1.0, Timer_Drug, client, TIMER_REPEAT);	
}

stock void KillDrug(int client)
{
	KillDrugTimer(client);
	
	float angs[3];
	GetClientEyeAngles(client, angs);
	
	angs[2] = 0.0;
	
	TeleportEntity(client, NULL_VECTOR, angs, NULL_VECTOR);	
	
	int clients[2];
	clients[0] = client;

	int duration = 1536;
	int holdtime = 1536;
	int flags = (0x0001 | 0x0010);
	int color[4] = { 0, 0, 0, 0 };

	Handle message = StartMessageEx(GetUserMessageId("Fade"), clients, 1);
	if (GetUserMessageType() == UM_Protobuf)
	{
		Protobuf pb = UserMessageToProtobuf(message);
		pb.SetInt("duration", duration);
		pb.SetInt("hold_time", holdtime);
		pb.SetInt("flags", flags);
		pb.SetColor("clr", color);
	}
	else
	{	
		BfWrite bf = UserMessageToBfWrite(message);
		bf.WriteShort(duration);
		bf.WriteShort(holdtime);
		bf.WriteShort(flags);
		bf.WriteByte(color[0]);
		bf.WriteByte(color[1]);
		bf.WriteByte(color[2]);
		bf.WriteByte(color[3]);
	}
	
	EndMessage();
}

stock void KillDrugTimer(int client)
{
	KillTimer(g_DrugTimers[client]);
	g_DrugTimers[client] = null;	
}

public Action Timer_Drug(Handle timer, any client)
{
	if (!IsClientInGame(client))
	{
		KillDrugTimer(client);

		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(client))
	{
		KillDrug(client);
		
		return Plugin_Handled;
	}
	
	float angs[3];
	GetClientEyeAngles(client, angs);
	
	angs[2] = g_DrugAngles[GetRandomInt(0,100) % 20];
	
	TeleportEntity(client, NULL_VECTOR, angs, NULL_VECTOR);
	
	int clients[2];
	clients[0] = client;	
	
	int duration = 255;
	int holdtime = 255;
	int flags = 0x0002;
	int color[4] = { 0, 0, 0, 128 };
	color[0] = GetRandomInt(0,255);
	color[1] = GetRandomInt(0,255);
	color[2] = GetRandomInt(0,255);

	Handle message = StartMessageEx(GetUserMessageId("Fade"), clients, 1);
	if (GetUserMessageType() == UM_Protobuf)
	{
		Protobuf pb = UserMessageToProtobuf(message);
		pb.SetInt("duration", duration);
		pb.SetInt("hold_time", holdtime);
		pb.SetInt("flags", flags);
		pb.SetColor("clr", color);
	}
	else
	{
		BfWriteShort(message, duration);
		BfWriteShort(message, holdtime);
		BfWriteShort(message, flags);
		BfWriteByte(message, color[0]);
		BfWriteByte(message, color[1]);
		BfWriteByte(message, color[2]);
		BfWriteByte(message, color[3]);
	}
	
	EndMessage();
		
	return Plugin_Handled;
}

public Action Timer_Boom(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	if(!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;
	
	if(g_eClient[client][iBoom] > 0)
	{
		g_eClient[client][iBoom]--;
		char buffer[256];
		Format(buffer, 256, "<font color='#0066CC' size='20'>%N </font> \n 还有<font color='#FF0000' size='20'> %d </font>秒爆炸", client, g_eClient[client][iBoom]);
		for(int i = 1; i <= MaxClients; ++i)
		{
			if(IsClientInGame(i))
			{
				Handle pb = StartMessageOne("HintText", i);
				PbSetString(pb, "text", buffer);
				EndMessage();
			}
		}
		return Plugin_Continue;
	}
	
	if(FindPluginByFile("mg_stats.smx") || FindPluginByFile("ct.smx") || FindPluginByFile("sm_hosties.smx") || FindPluginByFile("hg.smx"))
	{
		float ClientOrigin[3];
		float TargetOrigin[3];
		float Distance;

		GetClientAbsOrigin(client, ClientOrigin);
		
		int dead,victim;

		for(int target = 1; target <= MaxClients; ++target)
		{
			if(target != client && IsClientInGame(target) && IsPlayerAlive(target) && !(GetUserFlagBits(target) & ADMFLAG_ROOT))
			{
				GetClientAbsOrigin(target, TargetOrigin);
				Distance = GetVectorDistance(TargetOrigin, ClientOrigin);
				if(Distance <= 50)
				{
					ForcePlayerSuicide(target);
					PrintToChat(target, "[\x10VIP\x01]  \x07%N\x01把你炸死了", client);
					dead++;
				}
				else if(50 < Distance <= 125)
				{
					int hp = GetClientHealth(target) - 75;
					if(hp < 1)
						hp = 1;
					SetEntityHealth(target, hp);
					PrintToChat(target, "[\x10VIP\x01]  \x07%N\x01把你炸伤了", client);
					victim++;
				}
				else if(125 < Distance <= 225)
				{
					int hp = GetClientHealth(target) - 50;
					if(hp < 1)
						hp = 1;
					SetEntityHealth(target, hp);
					PrintToChat(target, "[\x10VIP\x01]  \x07%N\x01把你炸伤了", client);
					victim++;
				}
				else if(225 < Distance <= 350)
				{
					int hp = GetClientHealth(target) - 25;
					if(hp < 1)
						hp = 1;
					SetEntityHealth(target, hp);
					PrintToChat(target, "[\x10VIP\x01]  \x07%N\x01把你炸伤了", client);
					victim++;
				}
			}
		}
		
		char szSound[32];
		Format(szSound, 32, "weapons/hegrenade/explode%d.wav", GetRandomInt(3, 5));
		EmitSoundToAll(szSound);
		
		ForcePlayerSuicide(client);
		PrintToChatAll("[\x10VIP\x01]  \x07%N\x01已经去见安拉了[炸死\x07%d\x01人|炸伤\x07%d\x01人]", client, dead, victim);
	}
	else
	{
		char szSound[32];
		Format(szSound, 32, "weapons/hegrenade/explode%d.wav", GetRandomInt(3, 5));
		EmitSoundToAll(szSound);
		
		ForcePlayerSuicide(client);
		PrintToChatAll("[\x10VIP\x01]  \x07%N\x01已经去见安拉了", client);
	}
	
	g_eClient[client][iBoom] = 0;
	
	return Plugin_Stop;
}