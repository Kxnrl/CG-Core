#pragma newdecls required //let`s go! new syntax!!!
//Build 315
//////////////////////////////
//		DEFINITIONS			//
//////////////////////////////
#define PLUGIN_VERSION " 5.2.1 - 2016/08/19 06:34 "
#define PLUGIN_PREFIX "[\x0EPlaneptune\x01]  "
#define PLUGIN_PREFIX_SIGN "[\x0EPlaneptune\x01]  "

//////////////////////////////
//			INCLUDES		//
//////////////////////////////
#include <sourcemod>
#include <cg_core>

//////////////////////////////
//			ENUMS			//
//////////////////////////////
enum OS
{
	OS_Unknown = -1,
	OS_Windows = 0,
	OS_Mac = 1,
	OS_Linux = 2,
	OS_Total = 3
};

enum Clients
{
	iUserId,
	iUID,
	iFaith,
	iShare,
	iBuff,
	iGetShare,
	iLastSignTime,
	iConnectTime,
	iPlayerId,
	iConnectCounts,
	iOnlineTime,
	iDataRetry,
	iOSQuery,
	iAnalyticsId,
	iGroupId,
	iLevel,
	iExp,
	iTemp,
	iUpgrade,
	iVipType,
	bool:bLoaded,
	bool:bIsBot,
	bool:bPrint,
	bool:bIsVip,
	bool:bAllowLogin,
	bool:bTwiceLogin,
	bool:LoginProcess,
	String:szIP[32],
	String:szGroupName[64],
	String:szSignature[256],
	String:szDiscuzName[128],
	String:szAdminFlags[64],
	String:szInsertData[512],
	String:szUpdateData[1024],
	Handle:hOSTimer,
	Handle:hSignTimer,
	OS:iOS
}

enum eAdmins
{
	iType,
	iTarget,
	iTime
}

//////////////////////////////////
//		GLOBAL VARIABLES		//
//////////////////////////////////
Handle g_hDB_csgo;
Handle g_hDB_discuz;
Handle g_hOSGamedata;
Handle g_fwdOnServerLoaded;
Handle g_fwdOnClientDailySign;
Handle g_fwdOnClientDataLoaded;
Handle g_fwdOnClientAuthLoaded;
Handle g_CheckedForwared;
Handle g_hCVAR;

Clients g_eClient[MAXPLAYERS+1][Clients];
eAdmins g_eAdmin[eAdmins];

int g_iServerId = -1;
int g_iReconnect_csgo;
int g_iReconnect_discuz;
int g_iLatestData;
bool g_bLateLoad;
char g_szIP[64];
char g_szHostName[256];
char logFile_core[128];
char logFile_cat[128];
char g_szOSConVar[OS_Total][64];
char g_szGlobal[6][256];
char g_szServer[6][256];


//////////////////////////////
//			MODULES			//
//////////////////////////////
#include "playertrack/auth.sp"
#include "playertrack/faith.sp"
#include "playertrack/misc.sp"
#include "playertrack/notice.sp"
#include "playertrack/sign.sp"
#include "playertrack/sqlcb.sp"
#include "playertrack/track.sp"

//////////////////////////////
//		PLUGIN DEFINITION	//
//////////////////////////////
public Plugin myinfo = 
{
	name = " [CG] - Core ",
	author = "maoling ( shAna.xQy )",
	description = "Player Tracker System",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/_xQy_/"
};

//////////////////////////////
//		PLUGIN FORWARDS		//
//////////////////////////////
public void OnPluginStart()
{
	//Create Log Files
	BuildPath(Path_SM, logFile_core, 128, "logs/Core.log");
	BuildPath(Path_SM, logFile_cat, 128, "logs/CAT.log");
	
	//Hook ConVar
	g_hCVAR = FindConVar("sv_hibernate_when_empty");
	SetConVarInt(g_hCVAR, 0);
	HookConVarChange(g_hCVAR, OnSettingChanged);
	
	//Connect To Database
	SQL_TConnect_csgo();
	SQL_TConnect_discuz();
	
	//Load gamedata
	g_hOSGamedata = LoadGameConfigFile("detect_os.games");
	if(g_hOSGamedata == INVALID_HANDLE)
	{
		SetFailState("Failed to load gamedata file detect_os.games.txt: client operating system data will be unavailable.");
	}
	else
	{
		GameConfGetKeyValue(g_hOSGamedata, "Convar_Windows", g_szOSConVar[OS_Windows], 64);
		GameConfGetKeyValue(g_hOSGamedata, "Convar_Mac", g_szOSConVar[OS_Mac], 64);
		GameConfGetKeyValue(g_hOSGamedata, "Convar_Linux", g_szOSConVar[OS_Linux], 64);
	}

	//Register Command
	RegConsoleCmd("sm_sign", Cmd_Login);
	RegConsoleCmd("sm_qiandao", Cmd_Login);
	RegConsoleCmd("sm_online", Cmd_Online);
	RegConsoleCmd("sm_onlines", Cmd_Online);
	RegConsoleCmd("sm_track", Cmd_Track);
	RegConsoleCmd("sm_rz", Cmd_Track)
	RegConsoleCmd("sm_faith", Cmd_Faith);
	RegConsoleCmd("sm_fhelp", Cmd_FHelp);
	RegConsoleCmd("sm_share", Cmd_Share);
	RegConsoleCmd("sm_exp", Cmd_Exp);
	RegConsoleCmd("sm_notice", Cmd_Notice);
	RegAdminCmd("sm_pa", Cmd_Set, ADMFLAG_BAN);
	RegAdminCmd("sm_reloadadv", Cmd_ReloadAdv, ADMFLAG_BAN);
	RegAdminCmd("pareloadall", Cmd_reloadall, ADMFLAG_ROOT);
	
	//Create Forward
	g_fwdOnServerLoaded = CreateGlobalForward("CG_OnServerLoaded", ET_Ignore, Param_Cell);
	g_fwdOnClientDailySign = CreateGlobalForward("CG_OnClientDailySign", ET_Ignore, Param_Cell);
	g_fwdOnClientDataLoaded = CreateGlobalForward("CG_OnClientLoaded", ET_Ignore, Param_Cell);
	g_fwdOnClientAuthLoaded = CreateGlobalForward("PA_OnClientLoaded", ET_Ignore, Param_Cell);
}

public void OnPluginEnd()
{
	for(int i = 1; i <= MaxClients; ++i)
		if(IsClientInGame(i))
			OnClientDisconnect(i);
}

//////////////////////////////
//		Creat Native		//
//////////////////////////////
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("CG_GetServerID", Native_GetServerID);
	CreateNative("CG_GetShare", Native_GetShare);
	CreateNative("CG_GetOnlines", Native_GetOnlines);
	CreateNative("CG_GetPlayerID", Native_GetPlayerID);
	CreateNative("CG_GetClientFaith", Native_GetClientFaith);
	CreateNative("CG_GetClientShare", Native_GetClientShare);
	CreateNative("CG_GetSecondBuff", Native_GetSecondBuff);
	CreateNative("CG_GiveClientShare", Native_GiveClientShare);
	CreateNative("CG_GetSignature", Native_GetSingature);
	CreateNative("CG_GetDiscuzUID", Native_GetDiscuzUID);
	CreateNative("CG_GetDiscuzName", Native_GetDiscuzName);
	CreateNative("CG_SaveDatabase", Native_SaveDatabase);
	CreateNative("VIP_IsClientVIP", Native_IsClientVIP);
	CreateNative("VIP_SetClientVIP", Native_SetClientVIP);
	CreateNative("VIP_GetVipType", Native_GetVipType);
	CreateNative("PA_GetGroupID", Native_GetGroupID);
	CreateNative("PA_GetGroupName", Native_GetGroupName);
	CreateNative("PA_GetLevel", Native_GetLevel);
	CreateNative("PA_GivePlayerExp", Native_GivePlayerExp);

	g_CheckedForwared = CreateForward(ET_Ignore, Param_Cell);
	CreateNative("HookClientVIPChecked", Native_HookClientVIPChecked);
	
	//Get Server IP
	int ip = GetConVarInt(FindConVar("hostip"));
	Format(g_szIP, 64, "%d.%d.%d.%d:%d", ((ip & 0xFF000000) >> 24) & 0xFF, ((ip & 0x00FF0000) >> 16) & 0xFF, ((ip & 0x0000FF00) >>  8) & 0xFF, ((ip & 0x000000FF) >>  0) & 0xFF, GetConVarInt(FindConVar("hostport")));
	
	g_bLateLoad = late;

	RegPluginLibrary("csgogamers");

	return APLRes_Success;
}

void OnServerLoadSuccess()
{
	Call_StartForward(g_fwdOnServerLoaded);
	Call_Finish();
}

void OnClientSignSucessed(int client)
{
	Call_StartForward(g_fwdOnClientDailySign);
	Call_PushCell(client);
	Call_Finish();
}

void OnClientDataLoaded(int client)
{
	CheckClientBuff(client);
	PrintConsoleInfo(client);
	CreateTimer(10.0, Timer_Notice, GetClientUserId(client), TIMER_REPEAT);

	Call_StartForward(g_fwdOnClientDataLoaded);
	Call_PushCell(client);
	Call_Finish();
}

void OnClientAuthLoaded(int client)
{
	Call_StartForward(g_fwdOnClientAuthLoaded);
	Call_PushCell(client);
	Call_Finish();
}

void VipChecked(int client)
{
	Call_StartForward(g_CheckedForwared);
	Call_PushCell(client);
	Call_Finish();
}

public int Native_GetServerID(Handle plugin, int numParams)
{
	return g_iServerId;
}

public int Native_GetShare(Handle plugin, int numParams)
{
	return g_Share[GetNativeCell(1)];
}

public int Native_GetOnlines(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iOnlineTime];
}

public int Native_GetPlayerID(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iPlayerId];
}

public int Native_GetClientFaith(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iFaith];
}

public int Native_GetClientShare(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iShare];
}

public int Native_GetSecondBuff(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iBuff];
}

public int Native_GiveClientShare(Handle plugin, int numParams)
{
	char m_szReason[128];
	int client = GetNativeCell(1);
	int ishare = GetNativeCell(2);
	GetNativeString(3, m_szReason, 512);
	g_eClient[client][iGetShare] = g_eClient[client][iGetShare] + ishare;
	g_eClient[client][iShare] = g_eClient[client][iShare] + ishare;
	PrintToConsole(client, "[Planeptune]  你获得了%d点Share,当前总计%d点! 来自: %s", ishare, g_eClient[client][iShare], m_szReason);
}

public int Native_GetDiscuzUID(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iUID];
}

public int Native_GetDiscuzName(Handle plugin, int numParams)
{
	if(SetNativeString(2, g_eClient[GetNativeCell(1)][szDiscuzName], GetNativeCell(3)) != SP_ERROR_NONE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Can not return Player Forum name.");
	}
}

public int Native_GetSingature(Handle plugin, int numParams)
{
	if(SetNativeString(2, g_eClient[GetNativeCell(1)][szSignature], GetNativeCell(3)) != SP_ERROR_NONE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Can not return Player Singature.");
	}
}

public int Native_IsClientVIP(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][bIsVip];
}

public int Native_SetClientVIP(Handle plugin, int numParams)
{
	SetClientVIP(GetNativeCell(1), 1);
}

public int Native_GetVipType(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iVipType];
}

public int Native_HookClientVIPChecked(Handle plugin, int numParams)
{
	AddToForward(g_CheckedForwared, plugin, GetNativeCell(1));
}

public int Native_SaveDatabase(Handle plugin, int numParams)
{
	if(g_hDB_csgo != INVALID_HANDLE)
	{
		char m_szQuery[512];
		if(GetNativeString(1, m_szQuery, 512) == SP_ERROR_NONE)
		{
			Handle data = CreateDataPack();
			WritePackString(data, m_szQuery);
			ResetPack(data);
			SQL_TQuery(g_hDB_csgo, SQLCallback_SaveDatabase, m_szQuery, data);
		}
	}
}

public int Native_GetGroupID(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iGroupId];
}

public int Native_GetGroupName(Handle plugin, int numParams)
{
	if(SetNativeString(2, g_eClient[GetNativeCell(1)][szGroupName], GetNativeCell(3)) != SP_ERROR_NONE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Can not return Player Group Name.");
	}
}

public int Native_GetLevel(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iLevel];
}

public int Native_GivePlayerExp(Handle plugin, int numParams)
{
	char m_szReason[128];
	int client = GetNativeCell(1);
	int Exp = GetNativeCell(2);
	GetNativeString(3, m_szReason, 128);
	
	if(IsClientInGame(client) && g_eClient[client][iTemp] == -1)
	{
		PrintToConsole(client,"%s  你获得了%d点认证Exp!  来自: %s", PLUGIN_PREFIX, Exp, m_szReason);
		g_eClient[client][iExp] += Exp;
	}
}

//////////////////////////////
//			HOOK CONVAR		//
//////////////////////////////
public void OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(convar == g_hCVAR)
		SetConVarInt(g_hCVAR, 0);
}

public void OnMapStart()
{
	if(g_iServerId != 0 && g_hDB_csgo != INVALID_HANDLE)
	{
		char m_szQuery[256];
		Format(m_szQuery, 256, "SELECT faith,SUM(share) FROM playertrack_player GROUP BY faith");
		SQL_TQuery(g_hDB_csgo, SQLCallback_GetShare, m_szQuery);
		
		Format(m_szQuery, 256, "SELECT * FROM playertrack_server WHERE id = 0 or id = %d order by id asc;", g_iServerId);
		SQL_TQuery(g_hDB_csgo, SQLCallback_GetNotice, m_szQuery);

		SettingAdver();
	}
}

//////////////////////////////
//		ON CLIENT EVENT		//
//////////////////////////////
public void OnClientPostAdminCheck(int client)
{
	g_eClient[client][bIsBot] = false;

	if(IsClientBot(client) || client > MaxClients || client < 1 || IsFakeClient(client))
	{
		g_eClient[client][bIsBot] = true;
		OnClientDataLoaded(client);
		VipChecked(client);
		return;
	}

	//玩家数据初始化
	g_eClient[client][bLoaded] = false;
	g_eClient[client][LoginProcess] = false;
	g_eClient[client][bAllowLogin] = false;
	g_eClient[client][bTwiceLogin] = false;
	g_eClient[client][bIsVip] = false;
	g_eClient[client][bPrint] = false;
	g_eClient[client][iUserId] = GetClientUserId(client);
	g_eClient[client][iUID] = -1;
	g_eClient[client][iFaith] = -1;
	g_eClient[client][iBuff] = 0;
	g_eClient[client][iShare] = -1;
	g_eClient[client][iGetShare] = 0;
	g_eClient[client][iLastSignTime] = 0;
	g_eClient[client][iConnectTime] = GetTime();
	g_eClient[client][iPlayerId] = 0;
	g_eClient[client][iConnectCounts] = 0;
	g_eClient[client][iOnlineTime] = 0;
	g_eClient[client][iDataRetry] = 0;
	g_eClient[client][iOSQuery] = 0;
	g_eClient[client][iAnalyticsId] = -1;
	g_eClient[client][iVipType] = 0;
	g_eClient[client][iGroupId] = 0;
	g_eClient[client][iLevel] = 0;
	g_eClient[client][iExp] = 0;
	g_eClient[client][iTemp] = 0;
	g_eClient[client][iUpgrade] = 0;
	g_eClient[client][iOS] = OS_Unknown;

	strcopy(g_eClient[client][szIP], 32, "127.0.0.1");
	strcopy(g_eClient[client][szSignature], 256, "数据读取中...");
	strcopy(g_eClient[client][szDiscuzName], 256, "未注册");
	strcopy(g_eClient[client][szAdminFlags], 64, "Unknown");
	strcopy(g_eClient[client][szInsertData], 512, "");
	strcopy(g_eClient[client][szUpdateData], 1024, "");
	strcopy(g_eClient[client][szGroupName], 64, "未认证");

	//从数据库查询初始数据
	if(g_hDB_csgo != INVALID_HANDLE)
	{
		for(int i = 0; i < view_as<int>(OS_Total); i++)
			QueryClientConVar(client, g_szOSConVar[i], OnOSQueried);
	
		GetClientIP(client, g_eClient[client][szIP], 64);
		CreateTimer(10.0, Timer_HandleConnect, g_eClient[client][iUserId], TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		g_eClient[client][hOSTimer] = CreateTimer(30.0, Timer_OSTimeout, g_eClient[client][iUserId]);

		char steam32[32], m_szQuery[512];
		GetClientAuthId(client, AuthId_Steam2, steam32, 32, true);
		
		Format(m_szQuery, 512, "SELECT a.id, a.onlines, a.number, a.faith, a.share, a.buff, a.signature, a.groupid, a.groupname, a.exp, a.level, a.temp, a.notice, b.unixtimestamp FROM playertrack_player AS a LEFT JOIN `playertrack_sign` b ON b.steamid = a.steamid WHERE a.steamid = '%s' ORDER BY a.id ASC LIMIT 1;", steam32);
		SQL_TQuery(g_hDB_csgo, SQLCallback_GetClientStat, m_szQuery, g_eClient[client][iUserId], DBPrio_High);
	}
}

public void OnClientDisconnect(int client)
{
	if(g_eClient[client][bIsBot])
		return;

	g_eClient[client][bAllowLogin] = false;
	
	if(g_eClient[client][hSignTimer] != INVALID_HANDLE)
	{
		KillTimer(g_eClient[client][hSignTimer]);
		g_eClient[client][hSignTimer] = INVALID_HANDLE;
	}

	//如果客户没有成功INSERT ANALYTICS
	if(g_eClient[client][iAnalyticsId] == -1 || g_eClient[client][iConnectTime] == 0)
	{
		g_eClient[client][iConnectTime] = 0;
		return;
	}
	
	//执行回写数据
	if(g_hDB_csgo != INVALID_HANDLE && g_eClient[client][bLoaded])
	{
		SaveClient(client);
	}
}

//////////////////////////////
//		CLIENT COMMAND		//
//////////////////////////////
public Action Cmd_ReloadAdv(int client, int args)
{
	SettingAdver();
}

public Action Cmd_Online(int client, int args)
{
	int m_iHours = g_eClient[client][iOnlineTime]/3600;
	int m_iMins = g_eClient[client][iOnlineTime]/60 - m_iHours*60;
	int t_iMins = (GetTime() - g_eClient[client][iConnectTime])/60;
	PrintToChat(client, "%s 尊贵的CG玩家\x04%N\x01,你已经在CG社区进行了\x0C%d\x01小时\x0C%d\x01分钟的游戏(\x07%d\x01次连线),本次游戏时长\x0C%d\x01分钟", PLUGIN_PREFIX, client, m_iHours, m_iMins, g_eClient[client][iConnectCounts], t_iMins);
}

public Action Cmd_Track(int client, int args)
{
	if(client == 0)
		return Plugin_Handled;
	
	if(!IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;

	char szItem[512], szAuth32[32], szAuth64[64];
	Format(szItem, 512,"#userid   玩家姓名    uid   论坛名称   steam32   steam64    认证\n========================================================================================");
	PrintToConsole(client, szItem);
	
	int connected, ingame;

	for(int i = 1; i <= MaxClients; ++i)
	{
		if(IsClientConnected(i))
		{
			connected++;
			
			if(IsClientInGame(i) && !IsClientBot(i))
			{
				ingame++;
				
				GetClientAuthId(i, AuthId_Steam2, szAuth32, 32, true);
				GetClientAuthId(i, AuthId_SteamID64, szAuth64, 64, true);
				Format(szItem, 512, " %d    %N    %d    %s    %s    %s    %s", GetClientUserId(i), i, g_eClient[i][iUID], g_eClient[i][szDiscuzName], szAuth32, szAuth64, g_eClient[i][szGroupName]);
				PrintToConsole(client, szItem);
			}
		}
	}
	
	PrintToChat(client, "%s  请查看控制台输出", PLUGIN_PREFIX);
	PrintToChat(client, "%s  当前已在服务器内\x04%d\x01人,已建立连接的玩家\x07%d\x01人", PLUGIN_PREFIX, ingame, connected);

	return Plugin_Handled;
}

public Action Cmd_Faith(int client, int args)
{
	if(1 <= g_eClient[client][iFaith] <= 4)
		ShowFaithMainMenuToClient(client);
	else
		ShowFaithFirstMenuToClient(client);
}

public Action Cmd_FHelp(int client, int args)
{
	Handle panel = CreatePanel(GetMenuStyleHandle(MenuStyle_Radio));
	
	char szItem[64];
	Format(szItem, 64, "[Planeptune]   Faith - Help \n ");

	DrawPanelText(panel, szItem);
	DrawPanelText(panel, "Buff:");
	DrawPanelText(panel, "在休闲模式[TTT/MG/HG/ZE/ZR]中");
	DrawPanelText(panel, "有Faith的玩家每局都会获得Buff");
	DrawPanelText(panel, "不同的Faith拥有的Buff效果都不同");
	DrawPanelText(panel, "主Buff是由Faith决定的");
	DrawPanelText(panel, "副Buff是由玩家自己选择的");
	DrawPanelText(panel, "副Buff与你的Faith和Share无关");
	DrawPanelText(panel, "Share:");
	DrawPanelText(panel, "Share值是Faith强大的体现所在");
	DrawPanelText(panel, "Share值越高主Buff就越强大");
	DrawPanelText(panel, "正确击杀+1(ZE+5)点 | 死亡-3点");
	DrawPanelText(panel, "在线每分钟将会贡献1点Share");
	DrawPanelText(panel, "Share值达到1000点才会激活副Buff");
	DrawPanelItem(panel, " ",ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	DrawPanelItem(panel, "Exit");
	SendPanelToClient(panel, client, FaithHelpMenuHandler, 30);
	CloseHandle(panel);
}

public Action Cmd_Share(int client, int args)
{
	float share[5];
	share[0] = float(g_Share[1]+g_Share[2]+g_Share[3]+g_Share[4]);
	share[1] = (float(g_Share[1])/share[0])*100;
	share[2] = (float(g_Share[2])/share[0])*100;
	share[3] = (float(g_Share[3])/share[0])*100;
	share[4] = (float(g_Share[4])/share[0])*100;
	
	PrintToChat(client, "[%s] Share [\x0F%.2f%%\x01 of \x05%d\x01]", szFaith_CNAME[4], share[4], RoundToFloor(share[0]));
	PrintToChat(client, "[%s] Share [\x0F%.2f%%\x01 of \x05%d\x01]", szFaith_CNAME[3], share[3], RoundToFloor(share[0]));
	PrintToChat(client, "[%s] Share [\x0F%.2f%%\x01 of \x05%d\x01]", szFaith_CNAME[2], share[2], RoundToFloor(share[0]));
	PrintToChat(client, "[%s] Share [\x0F%.2f%%\x01 of \x05%d\x01]", szFaith_CNAME[1], share[1], RoundToFloor(share[0]));
}

public Action Cmd_Set(int client, int args)
{
	Handle menu = CreateMenu(AdminMainMenuHandler);
	char szItem[64];
	Format(szItem, 64, "[玩家认证]   管理员菜单\n -by shAna.xQy");
	SetMenuTitle(menu, szItem);
	AddMenuItem(menu, "9000", "添加临时认证[神烦坑比]");
	AddMenuItem(menu, "9001", "添加临时认证[小学生]");
	AddMenuItem(menu, "unban", "解除临时认证");
	AddMenuItem(menu, "reload", "重载认证");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 15);
}

public Action Cmd_Exp(int client, int args)
{
	if(g_eClient[client][iGroupId] > 0 && g_eClient[client][iTemp] == -1)
		PrintToChat(client, "%s \x04你当前经验值为: %i ,等级为: %i", PLUGIN_PREFIX, g_eClient[client][iExp], g_eClient[client][iLevel]);
	else
		PrintToChat(client, "%s 你没有认证,凑啥热闹?登陆论坛可以申请认证", PLUGIN_PREFIX);
}

public Action Cmd_reloadall(int client, int args)
{
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(IsClientInGame(i))
			LoadAuthorized(i);
	}
}

public Action Cmd_Notice(int client, int args)
{
	ShowPanelToClient(client);
}