#pragma newdecls required //let`s go! new syntax!!!
//Build 357
//////////////////////////////
//		DEFINITIONS			//
//////////////////////////////
#define PLUGIN_VERSION " 5.4rc1 - 2016/11/10 09:17 "
#define PLUGIN_PREFIX "[\x0CCG\x01]  "

//////////////////////////////
//			INCLUDES		//
//////////////////////////////
#include <sourcemod>
#include <cg_core>

//////////////////////////////
//			ENUMS			//
//////////////////////////////

//操作系统类型
enum OS
{
	OS_Unknown = -1,
	OS_Windows = 0,
	OS_Mac = 1,
	OS_Linux = 2,
	OS_Total = 3
};

//玩家数据
enum Clients
{
	iUserId,
	iUID,
	iFaith,
	iShare,
	iBuff,
	iGetShare,
	iSignNum,
	iSignTime,
	iConnectTime,
	iPlayerId,
	iNumber,
	iOnline,
	iLastseen,
	iDataRetry,
	iOSQuery,
	iAnalyticsId,
	iGroupId,
	iLevel,
	iExp,
	iTemp,
	iUpgrade,
	iVipType,
	iReqId,
	iReqTerm,
	iReqRate,
	iLilyId,
	iLilyRank,
	iLilyExp,
	iLilyDate,
	bool:bLoaded,
	bool:bIsBot,
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

//认证系统Index
enum eAdmins
{
	iType,
	iTarget,
	iTime
}

//////////////////////////////////
//		GLOBAL VARIABLES		//
//////////////////////////////////
//Handles
Handle g_hDB_csgo;
Handle g_hDB_discuz;
Handle g_hOSGamedata;
Handle g_fwdOnServerLoaded;
Handle g_fwdOnClientDailySign;
Handle g_fwdOnClientDataLoaded;
Handle g_fwdOnClientAuthLoaded;
Handle g_fwdOnClientCompleteReq;
Handle g_fwdOnAPIStoreSetCredits;
Handle g_fwdOnAPIStoreGetCredits;
Handle g_fwdOnLilyCouple;
Handle g_fwdOnLilyDivorce;
Handle g_hCheckedForwared;
Handle g_hCVAR;

//enum
Clients g_eClient[MAXPLAYERS+1][Clients];
eAdmins g_eAdmin[eAdmins];

//全部变量
int g_iServerId = -1;
int g_iReconnect_csgo;
int g_iReconnect_discuz;
bool g_bLateLoad;
char g_szIP[64];
char g_szHostName[256];
char LogFile[128];
char g_szOSConVar[OS_Total][64];


//////////////////////////////
//			MODULES			//
//////////////////////////////
#include "playertrack/auth.sp"
#include "playertrack/faith.sp"
#include "playertrack/misc.sp"
#include "playertrack/sign.sp"
#include "playertrack/sqlcb.sp"
#include "playertrack/track.sp"
#include "playertrack/lily.sp"

//////////////////////////////
//		PLUGIN DEFINITION	//
//////////////////////////////
public Plugin myinfo = 
{
	name = " [CG] - Core ",
	author = "maoling ( xQy )",
	description = "Player Tracker System",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/_xQy_/"
};

//////////////////////////////
//		PLUGIN FORWARDS		//
//////////////////////////////
public void OnPluginStart()
{
	//建立Log文件
	BuildPath(Path_SM, LogFile, 128, "logs/Core.log");

	//锁定ConVar
	g_hCVAR = FindConVar("sv_hibernate_when_empty");
	SetConVarInt(g_hCVAR, 0);
	HookConVarChange(g_hCVAR, OnSettingChanged);

	//连接到数据库
	SQL_TConnect_csgo();
	SQL_TConnect_discuz();
	
	//初始化游戏数据
	IntiGameData();

	//监听控制台命令
	RegConsoleCmd("sm_sign", Command_Login);
	RegConsoleCmd("sm_qiandao", Command_Login);
	RegConsoleCmd("sm_online", Command_Online);
	RegConsoleCmd("sm_track", Command_Track);
	RegConsoleCmd("sm_rz", Command_Track);
	RegConsoleCmd("sm_faith", Command_Faith);
	RegConsoleCmd("sm_fhelp", Command_FHelp);
	RegConsoleCmd("sm_share", Command_Share);
	RegConsoleCmd("sm_exp", Command_Exp);
	RegConsoleCmd("sm_cp", Command_Lily);
	RegConsoleCmd("sm_lily", Command_Lily);
	RegConsoleCmd("sm_cg", Command_Menu);
	RegConsoleCmd("sm_investment", Command_Inves);
	RegConsoleCmd("sm_inves", Command_Inves);

	//创建管理员命令
	RegAdminCmd("sm_pa", Command_Set, ADMFLAG_BAN);
	RegAdminCmd("sm_reloadadv", Command_ReloadAdv, ADMFLAG_BAN);
	RegAdminCmd("pareloadall", Command_reloadall, ADMFLAG_ROOT);

	//创建全局Forward
	g_fwdOnServerLoaded = CreateGlobalForward("CG_OnServerLoaded", ET_Ignore, Param_Cell);
	g_fwdOnAPIStoreSetCredits = CreateGlobalForward("CG_APIStoreSetCredits", ET_Event, Param_Cell, Param_Cell, Param_String, Param_Cell);
	g_fwdOnAPIStoreGetCredits = CreateGlobalForward("CG_APIStoreGetCredits", ET_Event, Param_Cell);
	g_fwdOnClientDailySign = CreateGlobalForward("CG_OnClientDailySign", ET_Ignore, Param_Cell);
	g_fwdOnClientDataLoaded = CreateGlobalForward("CG_OnClientLoaded", ET_Ignore, Param_Cell);
	g_fwdOnClientAuthLoaded = CreateGlobalForward("PA_OnClientLoaded", ET_Ignore, Param_Cell);
	g_fwdOnClientCompleteReq = CreateGlobalForward("CG_OnClientCompleteReq", ET_Ignore, Param_Cell, Param_Cell);
	g_fwdOnLilyCouple = CreateGlobalForward("Lily_OnLilyCouple", ET_Ignore, Param_Cell, Param_Cell);
	g_fwdOnLilyDivorce = CreateGlobalForward("Lily_OnLilyDivorce", ET_Ignore, Param_Cell, Param_Cell);
}

public void OnPluginEnd()
{
	//保存所有玩家数据
	for(int i = 1; i <= MaxClients; ++i)
		if(IsClientInGame(i))
			OnClientDisconnect(i);
}

//////////////////////////////
//		Creat Native		//
//////////////////////////////
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	//创建API
	CreateNative("CG_GetServerID", Native_GetServerID);
	CreateNative("CG_GetShare", Native_GetShare);
	CreateNative("CG_GetOnlines", Native_GetOnlines);
	CreateNative("CG_GetLastseen", Native_GetLastseen);
	CreateNative("CG_GetPlayerID", Native_GetPlayerID);
	CreateNative("CG_GetClientFaith", Native_GetClientFaith);
	CreateNative("CG_GetClientShare", Native_GetClientShare);
	CreateNative("CG_GetSecondBuff", Native_GetSecondBuff);
	CreateNative("CG_GiveClientShare", Native_GiveClientShare);
	CreateNative("CG_GetSignature", Native_GetSingature);
	CreateNative("CG_GetDiscuzUID", Native_GetDiscuzUID);
	CreateNative("CG_GetDiscuzName", Native_GetDiscuzName);
	CreateNative("CG_GetGameDatabase", Native_GetGameDatabase);
	CreateNative("CG_GetDiscuzDatabase", Native_GetDiscuzDatabase);
	CreateNative("CG_SaveDatabase", Native_SaveDatabase);
	CreateNative("CG_SaveForumData", Native_SaveForumData);
	CreateNative("CG_GetReqID", Native_GetReqID);
	CreateNative("CG_GetReqTerm", Native_GetReqTerm);
	CreateNative("CG_GetReqRate", Native_GetReqRate);
	CreateNative("CG_SetReqID", Native_SetReqID);
	CreateNative("CG_SetReqTerm", Native_SetReqTerm);
	CreateNative("CG_SetReqRate", Native_SetReqRate);
	CreateNative("CG_ResetReq", Native_ResetReq);
	CreateNative("CG_SaveReq", Native_SaveReq);
	CreateNative("CG_CheckReq", Native_CheckReq);
	CreateNative("VIP_IsClientVIP", Native_IsClientVIP);
	CreateNative("VIP_SetClientVIP", Native_SetClientVIP);
	CreateNative("VIP_GetVipType", Native_GetVipType);
	CreateNative("PA_GetGroupID", Native_GetGroupID);
	CreateNative("PA_GetGroupName", Native_GetGroupName);
	CreateNative("PA_GetLevel", Native_GetLevel);
	CreateNative("PA_GivePlayerExp", Native_GivePlayerExp);
	CreateNative("Lily_GetPartner", Native_GetLilyPartner);
	CreateNative("Lily_GetRank", Native_GetLilyRank);
	CreateNative("Lily_GetExp", Native_GetLilyExp);
	CreateNative("Lily_GetDate", Native_GetLilyDate);
	CreateNative("Lily_GiveExp", Native_GiveLilyExp);
	CreateNative("Lily_AddLily", Native_AddLily);

	g_hCheckedForwared = CreateForward(ET_Ignore, Param_Cell);
	CreateNative("HookClientVIPChecked", Native_HookClientVIPChecked);

	//读取服务器IP地址
	int ip = GetConVarInt(FindConVar("hostip"));
	Format(g_szIP, 64, "%d.%d.%d.%d:%d", ((ip & 0xFF000000) >> 24) & 0xFF, ((ip & 0x00FF0000) >> 16) & 0xFF, ((ip & 0x0000FF00) >>  8) & 0xFF, ((ip & 0x000000FF) >>  0) & 0xFF, GetConVarInt(FindConVar("hostport")));

	g_bLateLoad = late;

	//注册函数库
	RegPluginLibrary("csgogamers");

	return APLRes_Success;
}

void OnServerLoadSuccess()
{
	//Call Forward
	Call_StartForward(g_fwdOnServerLoaded);
	Call_Finish();
}

void OnClientSignSucessed(int client)
{
	//Call Forward
	Call_StartForward(g_fwdOnClientDailySign);
	Call_PushCell(client);
	Call_Finish();
}

void OnClientDataLoaded(int client)
{
	//检查玩家是否设置Buff|输出控制台数据
	CheckClientBuff(client);
	PrintConsoleInfo(client);

	//Call Forward
	Call_StartForward(g_fwdOnClientDataLoaded);
	Call_PushCell(client);
	Call_Finish();
}

void OnClientAuthLoaded(int client)
{
	//Call Forward
	Call_StartForward(g_fwdOnClientAuthLoaded);
	Call_PushCell(client);
	Call_Finish();
}

void VipChecked(int client)
{
	//Call Forward
	Call_StartForward(g_hCheckedForwared);
	Call_PushCell(client);
	Call_Finish();
}

bool OnAPIStoreSetCredits(int client, int credits, const char[] reason, bool immed)
{
	bool result;

	//Call Forward
	Call_StartForward(g_fwdOnAPIStoreSetCredits);
	Call_PushCell(client);
	Call_PushCell(credits);
	Call_PushString(reason);
	Call_PushCell(immed);
	Call_Finish(result);
	
	return result;
}

int OnAPIStoreGetCredits(int client) 
{
	int result;
	
	//Call Forward
	Call_StartForward(g_fwdOnAPIStoreGetCredits);
	Call_PushCell(client);
	Call_Finish(result);

	return result;
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
	return g_eClient[GetNativeCell(1)][iOnline];
}

public int Native_GetLastseen(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iLastseen];
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
	int client = GetNativeCell(1);
	
	if(g_eClient[client][iFaith] > 0)
	{
		char m_szReason[128];
		int ishare = GetNativeCell(2);
		GetNativeString(3, m_szReason, 128);
		if(ishare > 0)
		{
			g_eClient[client][iGetShare] += ishare;
			g_eClient[client][iShare] += ishare;
			PrintToConsole(client, "[Planeptune]  你获得了%d点Share,当前总计%d点!  来自: %s", ishare, g_eClient[client][iShare], m_szReason);
		}
		else
		{
			ishare *= -1;
			g_eClient[client][iGetShare] -= ishare;
			g_eClient[client][iShare] -= ishare;
			PrintToConsole(client, "[Planeptune]  你失去了%d点Share,当前总计%d点!  原因: %s", ishare, g_eClient[client][iShare], m_szReason);
		}
	}
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
	AddToForward(g_hCheckedForwared, plugin, GetNativeCell(1));
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
			WritePackCell(data, 0);
			ResetPack(data);
			SQL_TQuery(g_hDB_csgo, SQLCallback_SaveDatabase, m_szQuery, data);
		}
	}
}

public int Native_SaveForumData(Handle plugin, int numParams)
{
	if(g_hDB_discuz != INVALID_HANDLE)
	{
		char m_szQuery[512];
		if(GetNativeString(1, m_szQuery, 512) == SP_ERROR_NONE)
		{
			Handle data = CreateDataPack();
			WritePackString(data, m_szQuery);
			WritePackCell(data, 1);
			ResetPack(data);
			SQL_TQuery(g_hDB_discuz, SQLCallback_SaveDatabase, m_szQuery, data);
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
	
	//过滤临时认证
	if(IsClientInGame(client) && g_eClient[client][iGroupId] && g_eClient[client][iTemp] == -1)
	{
		PrintToConsole(client,"%s  你获得了%d点认证Exp!  来自: %s", PLUGIN_PREFIX, Exp, m_szReason);
		g_eClient[client][iExp] += Exp;
		
		if(g_eClient[client][iExp] >= 1000)
		{
			g_eClient[client][iExp] = 0;
			g_eClient[client][iLevel]++;
			PrintToChat(client, "%s  \x04你的认证等级已提升,当前\x0C%d\x04级", PLUGIN_PREFIX, g_eClient[client][iLevel]);
			char m_szQuery[128];
			Format(m_szQuery, 128, "UPDATE `playertrack_player` SET level = level + 1 WHERE id = %d", g_eClient[client][iPlayerId]);
			CG_SaveDatabase(m_szQuery);
		}
	}
}

public int Native_GetReqID(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iReqId];
}

public int Native_GetReqTerm(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iReqTerm];
}

public int Native_GetReqRate(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iReqRate];
}

public int Native_SetReqID(Handle plugin, int numParams)
{
	g_eClient[GetNativeCell(1)][iReqId] = GetNativeCell(2);
}

public int Native_SetReqTerm(Handle plugin, int numParams)
{
	g_eClient[GetNativeCell(1)][iReqTerm] = GetNativeCell(2);
}

public int Native_SetReqRate(Handle plugin, int numParams)
{
	g_eClient[GetNativeCell(1)][iReqRate] = GetNativeCell(2);
}

public int Native_ResetReq(Handle plugin, int numParams)
{
	//清空任务数据
	int client = GetNativeCell(1);
	if(IsClientInGame(client) && g_eClient[client][bLoaded])
	{
		char m_szQuery[256];
		Format(m_szQuery, 256, "UPDATE `playertrack_player` SET reqid = 0, reqterm = 0, reqrate = 0 WHERE id = %d", g_eClient[client][iPlayerId]);
		SQL_TQuery(g_hDB_csgo, SQLCallback_ResetReq, m_szQuery, GetClientUserId(client));
		
		g_eClient[client][iReqId] = 0;
		g_eClient[client][iReqTerm] = 0;
		g_eClient[client][iReqRate] = 0;
	}
}

public int Native_SaveReq(Handle plugin, int numParams)
{
	//保存任务进度
	int client = GetNativeCell(1);
	if(IsClientInGame(client) && g_eClient[client][bLoaded])
	{
		char m_szQuery[256];
		Format(m_szQuery, 256, "UPDATE `playertrack_player` SET reqid = %d, reqterm = %d, reqrate = %d WHERE id = %d", g_eClient[client][iReqId], g_eClient[client][iReqTerm], g_eClient[client][iReqRate], g_eClient[client][iPlayerId]);
		SQL_TQuery(g_hDB_csgo, SQLCallback_SaveReq, m_szQuery, GetClientUserId(client));
	}
}

public int Native_CheckReq(Handle plugin, int numParams)
{
	//检查任务进度
	int client = GetNativeCell(1);
	if(IsClientInGame(client) && g_eClient[client][bLoaded])
	{
		if(g_eClient[client][iReqId] != 0)
		{
			if(g_eClient[client][iReqRate] >= g_eClient[client][iReqTerm])
			{
				char m_szQuery[256];
				Format(m_szQuery, 256, "INSERT INTO `playertrack_guild` VALUES (DEFAULT, %d, %d, %d)", g_eClient[client][iPlayerId], g_eClient[client][iReqId], GetTime());
				SQL_TQuery(g_hDB_csgo, SQLCallback_InsertGuild, m_szQuery, GetClientUserId(client));
				
				Call_StartForward(g_fwdOnClientCompleteReq);
				Call_PushCell(client);
				Call_PushCell(g_eClient[client][iReqId]);
				Call_Finish();
			}
		}
	}
}

public int Native_GetLilyPartner(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iLilyId];
}

public int Native_GetLilyRank(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iLilyRank];
}

public int Native_GetLilyExp(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iLilyExp];
}

public int Native_GetLilyDate(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iLilyDate];
}

public int Native_GiveLilyExp(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int exp = GetNativeCell(2)
	g_eClient[client][iLilyExp] += exp;
	if(g_eClient[client][iLilyExp] > ((g_eClient[client][iLilyRank]+5)*10))
	{
		g_eClient[client][iLilyRank]++;
		if(SyncLilyData(client))
		{
			g_eClient[client][iLilyExp] = 0;
			PrintToChat(client, "%s  Lily Rank Level Up! Now: \x04Lv.\x0C%d", PLUGIN_PREFIX, g_eClient[client][iLilyRank]);
			PrintToChat(g_eClient[client][iLilyId], "%s  Lily Rank Level Up! Now: \x04Lv.\x0C%d", PLUGIN_PREFIX, g_eClient[client][iLilyRank]);
		}
		else
		{
			g_eClient[client][iLilyRank]--;
		}
	}
	else
		PrintToConsole(client, "[Planeptune]  Lily Exp +%d", exp);
}

public int Native_AddLily(Handle plugin, int numParams)
{
	int Neptune = GetNativeCell(1);
	int Noire = GetNativeCell(2);
	if(g_eClient[Neptune][iLilyId] == -2 &&  g_eClient[Noire][iLilyId] == -2)
	{
		g_eClient[Neptune][iLilyId] = Noire;
		g_eClient[Noire][iLilyId] = Neptune;
		char m_szQuery[128];
		Format(m_szQuery, 128, "UPDATE `playertrack_player` SET lilyid = %d where id = %d", g_eClient[Noire][iPlayerId], g_eClient[Neptune][iPlayerId]);
		CG_SaveDatabase(m_szQuery);
		Format(m_szQuery, 128, "UPDATE `playertrack_player` SET lilyid = %d where id = %d", g_eClient[Neptune][iPlayerId], g_eClient[Noire][iPlayerId]);
		CG_SaveDatabase(m_szQuery);
		SyncLilyData(Neptune);
		
		Call_StartForward(g_fwdOnLilyCouple);
		Call_PushCell(Neptune);
		Call_PushCell(Noire);
		Call_Finish();
	}
}

public int Native_GetGameDatabase(Handle plugin, int numParams)
{
	return view_as<int>(g_hDB_csgo);
}

public int Native_GetDiscuzDatabase(Handle plugin, int numParams)
{
	return view_as<int>(g_hDB_discuz);
}

//////////////////////////////
//			HOOK CONVAR		//
//////////////////////////////
public void OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	//锁定ConVar
	SetConVarInt(g_hCVAR, 0);
}

public void OnMapStart()
{
	//每次地图开始都刷新全部Share
	if(g_iServerId != 0 && g_hDB_csgo != INVALID_HANDLE)
	{
		char m_szQuery[256];
		Format(m_szQuery, 256, "SELECT faith,SUM(share) FROM playertrack_player GROUP BY faith");
		SQL_TQuery(g_hDB_csgo, SQLCallback_GetShare, m_szQuery);
	}
}

//////////////////////////////
//		ON CLIENT EVENT		//
//////////////////////////////
public void OnClientConnected(int client)
{
	//初始化Client数据
	InitializingClient(client);
}

public void OnClientPostAdminCheck(int client)
{
	//过滤BOT和FakeClient
	g_eClient[client][bIsBot] = false;

	if(IsClientBot(client))
	{
		g_eClient[client][bIsBot] = true;
		OnClientDataLoaded(client);
		OnClientAuthLoaded(client);
		VipChecked(client);
		return;
	}

	//re fixed
	InitializingClient(client);

	//从数据库查询初始数据
	//如果连不上数据库直接就跳过了
	if(g_hDB_csgo == INVALID_HANDLE)
	{
		//Call Forward让其它程序也执行
		OnClientAuthLoaded(client);
		OnClientDataLoaded(client);
		VipChecked(client);
		LogToFileEx(LogFile, "Query Client[%N] Failed:  Database is not avaliable!", client);
	}

	for(int i = 0; i < view_as<int>(OS_Total); i++)
		QueryClientConVar(client, g_szOSConVar[i], OnOSQueried);

	GetClientIP(client, g_eClient[client][szIP], 64);
	CreateTimer(10.0, Timer_HandleConnect, g_eClient[client][iUserId], TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	g_eClient[client][hOSTimer] = CreateTimer(30.0, Timer_OSTimeout, g_eClient[client][iUserId]);

	char m_szAuth[32], m_szQuery[512];
	GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
	
	Format(m_szQuery, 512, "SELECT id, onlines, number, faith, share, buff, signature, groupid, groupname, exp, level, temp, notice, reqid, reqterm, reqrate, signnumber, signtime, lilyid, lilyrank, lilyexp, lilydate, lasttime FROM playertrack_player WHERE steamid = '%s' ORDER BY id ASC LIMIT 1;", m_szAuth);
	SQL_TQuery(g_hDB_csgo, SQLCallback_GetClientStat, m_szQuery, g_eClient[client][iUserId], DBPrio_High);
}

public void OnClientDisconnect(int client)
{
	//Bot直接返回
	if(g_eClient[client][bIsBot])
		return;

	//检查Lily在线情况
	CheckingLily(client);

	//杀掉签到Timer
	if(g_eClient[client][hSignTimer] != INVALID_HANDLE)
	{
		KillTimer(g_eClient[client][hSignTimer]);
		g_eClient[client][hSignTimer] = INVALID_HANDLE;
	}

	//如果客户没有成功INSERT ANALYTICS
	if(g_eClient[client][iAnalyticsId] <= 0 || g_eClient[client][iConnectTime] == 0)
	{
		g_eClient[client][iConnectTime] = 0;
		return;
	}

	//执行回写数据
	//数据库不可用或没加载成功就不用了
	if(g_hDB_csgo != INVALID_HANDLE && g_eClient[client][bLoaded])
	{
		//保存数据
		SaveClient(client);
	}
}

public void InitializingClient(int client)
{
	g_eClient[client][bLoaded] = false;
	g_eClient[client][LoginProcess] = false;
	g_eClient[client][bAllowLogin] = false;
	g_eClient[client][bTwiceLogin] = false;
	g_eClient[client][bIsVip] = false;
	g_eClient[client][iUserId] = GetClientUserId(client);
	g_eClient[client][iUID] = -1;
	g_eClient[client][iFaith] = -1;
	g_eClient[client][iBuff] = 0;
	g_eClient[client][iShare] = -1;
	g_eClient[client][iGetShare] = 0;
	g_eClient[client][iSignNum] = 0;
	g_eClient[client][iSignTime] = 0;
	g_eClient[client][iConnectTime] = GetTime();
	g_eClient[client][iPlayerId] = 0;
	g_eClient[client][iNumber] = 0;
	g_eClient[client][iOnline] = 0;
	g_eClient[client][iLastseen] = 0;
	g_eClient[client][iDataRetry] = 0;
	g_eClient[client][iOSQuery] = 0;
	g_eClient[client][iAnalyticsId] = -1;
	g_eClient[client][iVipType] = 0;
	g_eClient[client][iGroupId] = 0;
	g_eClient[client][iLevel] = 0;
	g_eClient[client][iExp] = 0;
	g_eClient[client][iTemp] = 0;
	g_eClient[client][iUpgrade] = 0;
	g_eClient[client][iReqId] = 0;
	g_eClient[client][iReqTerm] = 0;
	g_eClient[client][iReqRate] = 0;
	g_eClient[client][iLilyId] = -2;
	g_eClient[client][iLilyRank] = 0;
	g_eClient[client][iLilyExp] = 0;
	g_eClient[client][iLilyDate] = 0;
	g_eClient[client][iOS] = OS_Unknown;

	strcopy(g_eClient[client][szIP], 32, "127.0.0.1");
	strcopy(g_eClient[client][szSignature], 256, "数据读取中...");
	strcopy(g_eClient[client][szDiscuzName], 256, "未注册");
	strcopy(g_eClient[client][szAdminFlags], 64, "Unknown");
	strcopy(g_eClient[client][szInsertData], 512, "");
	strcopy(g_eClient[client][szUpdateData], 1024, "");
	strcopy(g_eClient[client][szGroupName], 64, "未认证");
}

//////////////////////////////
//		CLIENT COMMAND		//
//////////////////////////////
public Action Command_ReloadAdv(int client, int args)
{
	//重载广告
	SettingAdver();
}

public Action Command_Online(int client, int args)
{
	//查询在线时间
	int m_iHours = g_eClient[client][iOnline] / 3600;
	int m_iMins = g_eClient[client][iOnline] % 3600;
	int t_iMins = (GetTime() - g_eClient[client][iConnectTime]) / 60;
	PrintToChat(client, "%s 尊贵的CG玩家\x04%N\x01,你已经在CG社区进行了\x0C%d\x01小时\x0C%d\x01分钟的游戏(\x07%d\x01次连线),本次游戏时长\x0C%d\x01分钟", PLUGIN_PREFIX, client, m_iHours, m_iMins, g_eClient[client][iNumber], t_iMins);
}

public Action Command_Track(int client, int args)
{
	//控制台查看玩家数据
	if(!client || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;

	char szItem[512], szAuth32[32], szAuth64[64];
	Format(szItem, 512,"#PlayerId   玩家姓名    UID   论坛名称   steam32   steam64    认证\n========================================================================================");
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
				Format(szItem, 512, " %d    %N    %d    %s    %s    %s    %s", g_eClient[i][iPlayerId], i, g_eClient[i][iUID], g_eClient[i][szDiscuzName], szAuth32, szAuth64, g_eClient[i][szGroupName]);
				PrintToConsole(client, szItem);
			}
		}
	}
	
	PrintToChat(client, "%s  请查看控制台输出", PLUGIN_PREFIX);
	PrintToChat(client, "%s  当前已在服务器内\x04%d\x01人,已建立连接的玩家\x07%d\x01人", PLUGIN_PREFIX, ingame, connected);

	return Plugin_Handled;
}

public Action Command_Faith(int client, int args)
{
	//判断是不是设置了Faith
	if(1 <= g_eClient[client][iFaith] <= 4)
		BuildFaithMainMenu(client);
	else
		BuildFaithFirstMenu(client);
	
	return Plugin_Handled;
}

public Action Command_FHelp(int client, int args)
{
	//创建帮助面板
	Handle panel = CreatePanel(GetMenuStyleHandle(MenuStyle_Radio));
	
	char szItem[64];
	Format(szItem, 64, "[Planeptune]   Faith - Help \n　");

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
	DrawPanelText(panel, "完成任务获得奖励 | 死亡会失去Share");
	DrawPanelText(panel, "在线每分钟将会贡献1点Share");
	DrawPanelText(panel, "Share值达到1000点才会激活副Buff");
	DrawPanelItem(panel, " ",ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	DrawPanelItem(panel, "Exit");
	
	SendPanelToClient(panel, client, MenuHandler_FaithHelp, 30);
	CloseHandle(panel);
	
	return Plugin_Handled;
}

public Action Command_Share(int client, int args)
{
	//直接输出所有Share到聊天框
	float share[5];
	share[ALLSHARE] = float(g_Share[PURPLE]+g_Share[BLACK]+g_Share[WHITE]+g_Share[GREEN]);
	share[PURPLE] = (float(g_Share[PURPLE])/share[ALLSHARE])*100;
	share[BLACK] = (float(g_Share[BLACK])/share[ALLSHARE])*100;
	share[WHITE] = (float(g_Share[WHITE])/share[ALLSHARE])*100;
	share[GREEN] = (float(g_Share[GREEN])/share[ALLSHARE])*100;
	
	PrintToChat(client, "[%s] Share [\x0F%.2f%%\x01 of \x05%d\x01]", szFaith_CNAME[GREEN], share[GREEN], RoundToFloor(share[ALLSHARE]));
	PrintToChat(client, "[%s] Share [\x0F%.2f%%\x01 of \x05%d\x01]", szFaith_CNAME[WHITE], share[WHITE], RoundToFloor(share[ALLSHARE]));
	PrintToChat(client, "[%s] Share [\x0F%.2f%%\x01 of \x05%d\x01]", szFaith_CNAME[BLACK], share[BLACK], RoundToFloor(share[ALLSHARE]));
	PrintToChat(client, "[%s] Share [\x0F%.2f%%\x01 of \x05%d\x01]", szFaith_CNAME[PURPLE], share[PURPLE], RoundToFloor(share[ALLSHARE]));

	return Plugin_Handled;
}

public Action Command_Set(int client, int args)
{
	//狗OP的菜单
	Handle menu = CreateMenu(MenuHandler_PAAdminMenuHandler);
	
	SetMenuTitle(menu, "[玩家认证]   管理员菜单\n　");
	
	AddMenuItem(menu, "9000", "添加临时认证[神烦坑比]");
	AddMenuItem(menu, "9001", "添加临时认证[小学生]");
	AddMenuItem(menu, "unban", "解除临时认证");
	AddMenuItem(menu, "reload", "重载认证");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 15);
	
	return Plugin_Handled;
}

public Action Command_Exp(int client, int args)
{
	//判定是不是认证
	if(g_eClient[client][iGroupId] > 0 && g_eClient[client][iTemp] == -1)
		PrintToChat(client, "%s \x04你当前经验值为: %i ,等级为: %i", PLUGIN_PREFIX, g_eClient[client][iExp], g_eClient[client][iLevel]);
	else
		PrintToChat(client, "%s 你没有认证,凑啥热闹?登陆论坛可以申请认证", PLUGIN_PREFIX);
	
	return Plugin_Handled;
}

public Action Command_reloadall(int client, int args)
{
	//管理员刷新所有人的认证
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(IsClientInGame(i))
			LoadAuthorized(i);
	}
	
	return Plugin_Handled;
}

public Action Command_Lily(int client, int args)
{
	//打开Lily主菜单
	BuildLilyMenu(client);
	
	return Plugin_Handled;
}

public Action Command_Menu(int client, int args)
{
	//创建CG玩家主菜单
	Handle menu = CreateMenu(MenuHandler_CGMainMenu);
	SetMenuTitle(menu, "[Planeptune]   主菜单\n　");

	AddMenuItem(menu, "store", "打开Store商店[购买皮肤/名字颜色/翅膀等道具]");
	AddMenuItem(menu, "faith", "打开Faith菜单[Faith信仰系统各个功能]");
	AddMenuItem(menu, "lily", "打开Lily菜单[进行CP配对/加成等功能]");
	AddMenuItem(menu, "music", "打开CG电台[可以点播歌曲/收听电台]");
	AddMenuItem(menu, "sign", "进行每日游戏签到[签到可以获得相应的奖励]");
	AddMenuItem(menu, "vip", "打开VIP菜单[年费/永久VIP可用]", g_eClient[client][iVipType] > 1 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
	
	return Plugin_Handled;
}

public Action Command_Inves(int client, int args)
{
	BuildInvestmentMenu(client);
	
	return Plugin_Handled;
}

public Action Command_Login(int client, int args) 
{
	ProcessingLogin(client);
	
	return Plugin_Handled;
}