#include <sourcemod>
#include <cg_core>
#include <cstrike>
#include <sdktools>

#define PLUGIN_VERSION " 1.0 "
#define PLUGIN_AUTHOR "maoling ( xQy )"

#pragma semicolon 1
#pragma dynamic 131072

int g_iClientDirty[MAXPLAYERS+1];
int g_iClientAdv[MAXPLAYERS+1];
bool g_bDisableFilteTag;
bool g_bConnected[MAXPLAYERS+1];
char FiltLog[128];

public Plugin myinfo = 
{
	name = "Filter",
	author = PLUGIN_AUTHOR,
	description = "Player Authorized System , Powered by CG Community",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/_xQy_/"
};

public void OnPluginStart()
{
	BuildPath(Path_SM, FiltLog, 128, "logs/Filter.log");
	
	RegConsoleCmd("say", HookSay);
	RegConsoleCmd("say_team", HookSay);
}

public void OnClientConnected(client)
{
	g_bConnected[client] = true;
}

public void CG_OnClientLoaded(client)
{
	g_bConnected[client] = false;
	g_iClientAdv[client] = 0;
	g_iClientDirty[client] = 0;

	if(IsClientInGame(client) && PA_GetGroupID(client) < 9999)
	{
		FilteClientName(client);
	}
}

public void OnClientSettingsChanged(client)
{
	if(!g_bConnected[client] && IsClientInGame(client) && PA_GetGroupID(client) < 9999)
	{
		FilteClientName(client);
	}
}

public FilteClientName(client)
{
	char name[64];
	GetClientName(client, name, 64);
	if(StrContains(name, "X社", false) != -1 || StrContains(name, "茶社", false) != -1)
		ResetClientName(client, 0);
	if(StrContains(name, "僵尸乐园", false) != -1 || StrContains(name, "ŽΣĎ", false) != -1)
		ResetClientName(client, 0);
	if(StrContains(name, "垃圾服务器", false) != -1 || StrContains(name, "垃圾社区", false) != -1)
		ResetClientName(client, 1);
	if(StrContains(name, "操你妈", false) != -1 || StrContains(name, "干你", false) != -1)
		ResetClientName(client, 1);
	if(StrContains(name, "<font", false) != -1 || StrContains(name, "<u>", false) != -1 || StrContains(name, "<b>", false) != -1)
		ResetClientName(client, 2);
	if(StrContains(name, "purple heart", false) != -1 || StrContains(name, "purpleheart", false) != -1 || StrContains(name, "neptune", false) != -1 || StrContains(name, "planeptune", false) != -1)
		if(PA_GetGroupID(client) != 9999) ResetClientName(client, 3);
	if(StrContains(name, "垃圾CG", false) != -1 || StrContains(name, "CG艹狗", false) != -1 || StrContains(name, "STF .") != -1)
	{
		int userid = GetClientUserId(client);
		ServerCommand("sm_ban #%i 10080 \"Name Fileter Ban\"", userid);
	}
}

public ResetClientName(client, type)
{
	char newname[32];
	if(type == 0)
		FormatEx(newname, 32, "违规字符已屏蔽");
	if(type == 1)
		FormatEx(newname, 32, "不雅昵称已屏蔽");
	if(type == 2)
		FormatEx(newname, 32, "特殊字符已屏蔽");
	if(type == 3)
	{
		GetClientName(client, newname, 64);
		ReplaceString(newname,64,"purple heart","",false);
		ReplaceString(newname,64,"purpleheart","",false);
		ReplaceString(newname,64,"planeptune","",false);
		ReplaceString(newname,64,"neptune","",false);
	}

	LogToFile(FiltLog, "Reset name %N to %s", client, newname);
	SetClientName(client, newname);
}

public Action HookSay(int client, int args)
{
	char message[1024];
	GetCmdArgString(message, sizeof(message));
	
	if(StrContains(message, "!msg ", false) != -1 || StrContains(message, "!xlb ", false) != -1 || StrContains(message, "!dlb ", false) != -1)
		return Plugin_Handled;
	
	if(StrEqual(message, "") || StrEqual(message, " "))
		FakeClientCommand(client, "sm_store");

	if (
		StrContains(message, "X社", false) != -1 ||
		StrContains(message, "茶社", false) != -1 ||
		StrContains(message, "93x", false) != -1 ||
		StrContains(message, "僵尸乐园", false) != -1 ||
		StrContains(message, "ZombieDen", false) != -1 ||
		StrContains(message, "Aomc", false) != -1 ||
		StrContains(message, "UB服", false) != -1 ||
		StrContains(message, "牛逼服", false) != -1 ||
		StrContains(message, "dashijie", false) != -1 ||
		StrContains(message, "大世界", false) != -1 ||
		StrContains(message, "狼群", false) != -1 ||
		StrContains(message, "垃圾服务器", false) != -1 ||
		StrContains(message, "辣鸡服务器", false) != -1 ||
		StrContains(message, "垃圾社区", false) != -1 ||
		StrContains(message, "辣鸡社区", false) != -1 ||
		StrContains(message, "CG垃圾", false) != -1 ||
		StrContains(message, "辣鸡CG", false) != -1 ||
		StrContains(message, "垃圾CG", false) != -1
		)
	{
		LogToFile(FiltLog, "Chat  %N:%s", client, message);
		
		if(client == 0)
			return Plugin_Handled;

		PrintToChat(client, "[\x02Filter\x01]  含有敏感内容请检查后重试...");
		PrintToChat(client, "[\x02Filter\x01]  已将敏感内容上传至数据库...");
		
		g_iClientAdv[client]++;
		
		if(g_iClientAdv[client] >= 5)
		{
			ServerCommand("sm_gag #%i 30 诋毁社区/无关广告!", GetClientUserId(client));
			g_iClientAdv[client] = 0;
		}

		if(FindPluginByFile("ct.smx"))
			SlapPlayer(client, 100, true);
		
		if(FindPluginByFile("hg.smx"))
			SlapPlayer(client, 50, true);
		
		if(FindPluginByFile("mg_stats.smx"))
			SlapPlayer(client, 99, true);
		
		if(FindPluginByFile("JB-Simon.smx"))
			SlapPlayer(client, 66, true);
		
		return Plugin_Handled;
	}
	
	if (
		StrContains(message, "操你妈", false) != -1 ||
		StrContains(message, "干你妈", false) != -1 ||
		StrContains(message, "死光光", false) != -1 ||
		StrContains(message, "死全家", false) != -1 ||
		StrContains(message, "你妈逼", false) != -1 ||
		StrContains(message, "傻逼儿子", false) != -1 ||
		StrContains(message, "傻逼玩意", false) != -1 ||
		StrContains(message, "煞笔", false) != -1 ||
		StrContains(message, "杀你全家", false) != -1 ||
		StrContains(message, "干你血妈", false) != -1 ||
		StrContains(message, "傻屌", false) != -1 ||
		StrContains(message, "狗逼", false) != -1 ||
		StrContains(message, "叼你老母", false) != -1 ||
		StrContains(message, "死妈", false) != -1 ||
		StrContains(message, "你妈死了", false) != -1 ||
		StrContains(message, "傻逼", false) != -1
		)
	{
		//LogToFile(FiltLog, "Chat  %N:%s", clientname, message);
		
		if(client == 0)
			return Plugin_Handled;
		
		PrintToChat(client, "[\x02Filter\x01]  请注意文明用语...");
		
		g_iClientDirty[client]++;
		
		if(g_iClientDirty[client] >= 5)
		{
			ServerCommand("sm_gag #%i 30 说脏话过多,自动禁言!", GetClientUserId(client));
			g_iClientDirty[client] = 0;
		}
		
		return Plugin_Handled;
	}
	
	if (
		StrContains(message, "猫儿子", false) != -1 ||
		StrContains(message, "猫孙子", false) != -1 ||
		StrContains(message, "猫灵儿子", false) != -1 ||
		StrContains(message, "猫灵孙子", false) != -1 ||
		StrContains(message, "傻逼猫灵", false) != -1 ||
		StrContains(message, "驴灵", false) != -1 ||
		StrContains(message, "sbml", false) != -1 ||
		StrContains(message, "猫孙", false) != -1
		)
	{
		//LogToFile(FiltLog, "Chat  %N:%s", clientname, message);
		
		if(client == 0)
			return Plugin_Handled;
		
		PrintToChat(client, "[\x02Filter\x01]  请注意文明用语...");
		
		ServerCommand("sm_gag #%i 1440 恶意喷粪,情节恶劣!", GetClientUserId(client));
		
		if(IsPlayerAlive(client))
			ForcePlayerSuicide(client);
		
		return Plugin_Handled;
	}
	
	if (
		StrContains(message, "sakuracsgo", false) != -1 ||
		StrContains(message, "433198174", false) != -1 ||
		StrContains(message, "300824941", false) != -1 ||
		StrContains(message, "113.17.140.210", false) != -1 ||
		StrContains(message, "61.153.107.98", false) != -1 ||
		StrContains(message, "429436520", false) != -1 ||
		StrContains(message, "Sakura聚集地", false) != -1
		)
	{	
		if(client == 0)
			return Plugin_Handled;
	
		ServerCommand("sm_ban #%i 0 恶意打广告", GetClientUserId(client));
		
		return Plugin_Handled;
	}
	
	if(!FindPluginByFile("KZTimer.smx") && !FindPluginByFile("rankmetag.smx"))
	{
		if(client > 0)
		{
			if(GetClientTeam(client) == 1)
			{
				if(PA_GetGroupID(client) != 9000 && PA_GetGroupID(client) != 9001)
				{
					char szText[1024];
					char clientname[64];
					
					GetClientName(client, clientname, sizeof(clientname));
					ReplaceString(clientname,64,"{darkred}","",false);
					ReplaceString(clientname,64,"{green}","",false);
					ReplaceString(clientname,64,"{lightgreen}","",false);
					ReplaceString(clientname,64,"{blue}","",false);
					ReplaceString(clientname,64,"{olive}","",false);
					ReplaceString(clientname,64,"{lime}","",false);
					ReplaceString(clientname,64,"{red}","",false);
					ReplaceString(clientname,64,"{purple}","",false);
					ReplaceString(clientname,64,"{grey}","",false);
					ReplaceString(clientname,64,"{yellow}","",false);
					ReplaceString(clientname,64,"{lightblue}","",false);
					ReplaceString(clientname,64,"{steelblue}","",false);
					ReplaceString(clientname,64,"{darkblue}","",false);
					ReplaceString(clientname,64,"{pink}","",false);
					ReplaceString(clientname,64,"{lightred}","",false);

					ReplaceString(message,1024,"{darkred}","",false);
					ReplaceString(message,1024,"{green}","",false);
					ReplaceString(message,1024,"{lightgreen}","",false);
					ReplaceString(message,1024,"{blue}","",false);
					ReplaceString(message,1024,"{olive}","",false);
					ReplaceString(message,1024,"{lime}","",false);
					ReplaceString(message,1024,"{red}","",false);
					ReplaceString(message,1024,"{purple}","",false);
					ReplaceString(message,1024,"{grey}","",false);
					ReplaceString(message,1024,"{yellow}","",false);
					ReplaceString(message,1024,"{lightblue}","",false);
					ReplaceString(message,1024,"{steelblue}","",false);
					ReplaceString(message,1024,"{darkblue}","",false);
					ReplaceString(message,1024,"{pink}","",false);
					ReplaceString(message,1024,"{lightred}","",false);
					
					StripQuotes(message);
					if (StrEqual(message,"") || StrEqual(message," ") || StrEqual(message,"  "))
						return Plugin_Handled;
					
					char groupname[32];
					PA_GetGroupName(client, groupname, 32);
					
					if(PA_GetGroupID(client) == 9999)
						Format(szText, 1024, "*SPEC* \x01[\x0E%s\x01] %s :  %s", groupname, clientname, message);
					else if(PA_GetGroupID(client) > 1)
						Format(szText, 1024, "*SPEC* \x01[\x0C%s\x01] %s :  %s", groupname, clientname, message);
					else
						Format(szText, 1024, "*SPEC* \x01[\x07%s\x01] %s :  %s", groupname, clientname, message);
					
					PrintToChatAll(szText);
					
					return Plugin_Handled;
				}
			}
		}
	}
	return Plugin_Continue;
}