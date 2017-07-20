#include <maoling>
#include <socket>
#include <cg_core>
#include <store>
#include <chat-processor>
#include <clientprefs>

#define REQUIRE_PLUGIN
#include <basecomm>

#pragma newdecls required 

#define DISCONNECTSTR	"DISCONNECTMEPLSTHX"
#define key				"[&KVJL>P*^Y*(JHjkhlsa]"
#define MasterServer	"112.74.128.238"
#define port			"64333"

Handle g_hSocket;
Handle g_hCookie;
bool g_bPbCSC[MAXPLAYERS+1];
bool g_bConnected;
char g_szLAST[1024];

public Plugin myinfo = 
{
    name		= "Broadcast System - Client",
    author		= "Kyle",
    description	= "Send message on all connected server !",
    version		= "3.0.4",
    url			= "http://steamcommunity.com/id/_xQy_/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("CG_Broadcast", Native_Broadcast);
	MarkNativeAsOptional("BaseComm_IsClientGagged");
	
	return APLRes_Success;
}

public int Native_Broadcast(Handle plugin, int numParams)
{
	if(g_hSocket == INVALID_HANDLE)
		return;

	char m_szContent[512];
	if(GetNativeString(2, m_szContent, 512) == SP_ERROR_NONE)
	{
		if(GetNativeCell(1))
		{
			Handle db = CG_DatabaseGetForum();
			char m_szSQL[512], m_szEsc[512], m_szQuery[1024];
			strcopy(m_szSQL, 512, m_szContent);
			PrepareString(m_szSQL, 512);
			SQL_EscapeString(db, m_szSQL, m_szEsc, 512);
			Format(m_szQuery, 1024, "INSERT INTO `dz_plugin_ahome_laba` (`username`, `tousername`, `level`, `lid`, `dateline`, `content`, `color`, `url`) VALUES ('Broadcast System', '', 'system', 0, '%d', '%s', '', '')", GetTime(), m_szEsc);
			CG_DatabaseSaveForum(m_szQuery);
		}
		
		if(StrContains(m_szContent, "[\x10Store\x01]") != -1)
		{
			char fmt[512];
			strcopy(fmt, 512, m_szContent);
			ReplaceString(fmt, 512, "[\x10Store\x01] ", "", false);
			PrepareString(fmt, 512);
			Format(fmt, 512, ">>> 全服广播 <<<\n%s", fmt);
			CG_ShowGameTextAll(fmt, "10.0", "57 197 187", "-1.0", "0.2");
		}
		
		char m_szFinalMsg[1024];
		Format(m_szFinalMsg, 1024, "[\x10Broadcast\x01]  \x07>\x04>\x0C>  \x05%s", m_szContent);
		PrintToChatAll(m_szFinalMsg);

		Format(m_szFinalMsg, 1024, "%s%s", key, m_szFinalMsg);
		SocketSend(g_hSocket, m_szFinalMsg, 1024);
		strcopy(g_szLAST, 1024, m_szFinalMsg);
	}
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_msg", Command_PubMessage);
	RegConsoleCmd("sm_xlb", Command_PubMessage);
	RegConsoleCmd("sm_dlb", Command_PubMessage);
	RegConsoleCmd("sm_pbcsc", Command_PbCSC);

	g_hCookie = RegClientCookie("csc_pb", "pb csc chat", CookieAccess_Private);

	CreateTimer(3.0, Timer_Reconnect);
	CreateTimer(180.0, Timer_Broadcast, _, TIMER_REPEAT);
}

public Action Timer_Broadcast(Handle timer)
{
	PrintToChatAll("[\x0CCG\x01]   \x04输入\x07!pbcsc\x04可以开关全服聊天消息");
}

public void OnClientCookiesCached(int client)
{
	char Buffer[8];
	GetClientCookie(client, g_hCookie, Buffer, 8);
	if(!strcmp(Buffer, "true", false))
		g_bPbCSC[client] = true;
}

public void OnClientDisconnect(int client)
{
	g_bPbCSC[client] = false;
}

public void OnPluginEnd()
{
	if(g_bConnected)
	{
		char m_szFinalMsg[1024], serverName[128];
		GetConVarString(FindConVar("hostname"), serverName, 128);
		Format(m_szFinalMsg, 1024, "%s%s%s", key, DISCONNECTSTR, serverName);
		SocketSend(g_hSocket, m_szFinalMsg, 1024);
		CloseHandle(g_hSocket);
		g_hSocket = INVALID_HANDLE;
	}
}

public Action Command_PbCSC(int client, int args)
{
	if(g_bPbCSC[client])
	{
		g_bPbCSC[client] = false;
		SetClientCookie(client, g_hCookie, "false");
		tPrintToChat(client, "[\x0CCG\x01]   \x04您已打开全服聊天功能");
	}
	else
	{
		g_bPbCSC[client] = true;
		SetClientCookie(client, g_hCookie, "true");
		tPrintToChat(client, "[\x0CCG\x01]   \x04您已屏蔽全服聊天功能");
    }
}

void ChatClientDisable(int client)
{
	if(!IsClientInGame(client))
		return;
	
	tPrintToChat(client, "[\x0CCG\x01]   \x04您已关闭全服聊天功能,你所发送的内容无法被其它服务器的玩家收到");
}

public void CP_OnChatMessagePost(int client, ArrayList recipients, const char[] flagstring, const char[] formatstring, const char[] name, const char[] message, bool processcolors, bool removecolors)
{
	if(g_hSocket == INVALID_HANDLE)
		return;

	if(g_bPbCSC[client])
	{
		RequestFrame(ChatClientDisable, client);
		return;
	}

	if(message[0] == '!' || message[0] == '.' || message[0] == '/' || message[0] == '#' || message[0] == '@' || StrEqual(message, "rtv", false) || StrContains(message, "nominat", false) != -1)
		return;

	if(StrContains(flagstring, "_All") == -1)
		return;
	
	UpdateChatToDiscuz(client, message);

	char m_szServerTag[32], m_szFinalMsg[1024];
	GetServerTag(m_szServerTag, 32);

	Format(m_szFinalMsg, 1024, "%s \x04%s\x01>>>  %s \x01:  %s", key, m_szServerTag, name, message);
	ReplaceAllColors(m_szFinalMsg, 1024);

	SocketSend(g_hSocket, m_szFinalMsg, 1024);
	strcopy(g_szLAST, 1024, m_szFinalMsg);
}

void UpdateChatToDiscuz(int client, const char[] message)
{
	Handle database = CG_DatabaseGetGames();

	if(database == INVALID_HANDLE)
		return;

	char msg[256], esc[256];
	strcopy(msg, 256, message);
	PrepareString(msg, 256);
	SQL_EscapeString(database, msg, esc, 256);

	char name[32], ename[64];
	GetClientName(client, name, 32);
	SQL_EscapeString(database, name, ename, 64);

	char auth[32];
	GetClientAuthId(client, AuthId_Steam2, auth, 32, true);

	char m_szQuery[512];
	Format(m_szQuery, 512, "INSERT INTO `playertrack_csclog` VALUES (DEFAULT, '%d', '%d', '%s', '%s', '%d', '%s')", CG_GetServerId(), CG_ClientGetUId(client), auth, ename, GetTime(), esc);
	CG_DatabaseSaveGames(m_szQuery);
}

public void CG_OnCouplesWedding(int source, int target)
{
	if(g_hSocket == INVALID_HANDLE)
		return;

	char m_szFinalMsg[1024];
	Format(m_szFinalMsg, 1024, "恭喜[%N]和[%N]组成了一对CP!", source, target);
    
	char fmt[512];
	Format(fmt, 512, ">>> 新婚大吉 <<<\n%s", m_szFinalMsg);
	CG_ShowGameTextAll(fmt, "10.0", "255 255 255", "-1.0", "0.2");

	Handle database = CG_DatabaseGetForum();

	if(!database)
		return;

	char EscapeString[512];
	SQL_EscapeString(database, m_szFinalMsg, EscapeString, 512);

	char m_szQuery[1024];
	Format(m_szQuery, 1024, "INSERT INTO `dz_plugin_ahome_laba` (`username`, `tousername`, `level`, `lid`, `dateline`, `content`, `color`, `url`) VALUES ('Lily System', '', 'system', 0, '%d', '%s', '', '')", GetTime(), EscapeString);
	CG_DatabaseSaveForum(m_szQuery);

	Format(m_szFinalMsg, 1024, " \x04[\x0ECouples\x04]  \x07>\x05>\x0C> \x0E恭喜\x0C%N\x0E和\x0C%N\x0E组成了CP!", source, target);
	PrintToChatAll(m_szFinalMsg);

	Format(m_szFinalMsg, 1024, "%s%s", key, m_szFinalMsg);
	SocketSend(g_hSocket, m_szFinalMsg, 1024);
	strcopy(g_szLAST, 1024, m_szFinalMsg);
}

public void OnMapVoteEnd(const char[] map)
{
	if(g_hSocket == INVALID_HANDLE)
		return;

	if(StrContains(map, "extend", false) != -1)
		return;
	
	if(StrContains(map, "change", false) != -1)
		return;

	char m_szFinalMsg[1024], m_szServerTag[32];
	GetServerTag(m_szServerTag, 32);
	
	Format(m_szFinalMsg, 1024, "[\x10Broadcast\x01]  \x07>\x04>\x0C>  \x04%s即将更换地图为\x05 %s", m_szServerTag, map);
	PrintToChatAll(m_szFinalMsg);

	Format(m_szFinalMsg, 1024, "%s%s", key, m_szFinalMsg);
	SocketSend(g_hSocket, m_szFinalMsg, 1024);
	strcopy(g_szLAST, 1024, m_szFinalMsg);
}

public Action Command_PubMessage(int client, int args)
{
	if(g_hSocket == INVALID_HANDLE)
		return Plugin_Continue;

	if(Store_GetClientCredits(client) < 200)
	{
		PrintToChat(client, "[\x04Store\x01]  \x01没钱还想发小喇叭?");
		return Plugin_Handled;
	}

	if(args < 1)
		return Plugin_Handled;

	char message[512], m_szFinalMsg[1024], m_szServerTag[32];
	GetCmdArgString(message, 512);
	PrepareString(message, 512);
	GetServerTag(m_szServerTag, 32);

	Format(m_szFinalMsg, 1024, "[\x02小\x04喇\x0C叭\x01] [\x0E%s\x01]  \x04%N\x01 :   \x07%s", m_szServerTag, client, message);

	if(!UpdateMessageToDiscuz(client, message))
		return Plugin_Handled;
	
	Store_SetClientCredits(client, Store_GetClientCredits(client)-200, "发送小喇叭");
	PrintToChat(client, "[\x04Store\x01]  \x01你花费\x04200信用点\x01发送了一条小喇叭");
	
	if(IsClientGag(client))
	{
		PrintToChat(client, "[\x04Store\x01]  \x01你被口球了还想发喇叭?");
		return Plugin_Handled;
	}

	char fmt[512];
	strcopy(fmt, 512, m_szFinalMsg);
	ReplaceString(fmt, 512, "[\x02小\x04喇\x0C叭\x01] ", "", false);
	PrepareString(fmt, 512);
	Format(fmt, 512, ">>> 小喇叭 <<<\n%s", fmt);
	CG_ShowGameTextAll(fmt, "20.0", "57 197 187", "-1.0", "0.2");

	Format(m_szFinalMsg, 1024, "%s%s", key, m_szFinalMsg);
	SocketSend(g_hSocket, m_szFinalMsg, 1024);
	strcopy(g_szLAST, 1024, m_szFinalMsg);

	return Plugin_Handled;
}

public Action Timer_Reconnect(Handle timer)
{
	ConnecToMasterServer();
}

public int OnClientSocketConnected(Handle socket, any arg)
{
	SocketSetOption(socket, SocketKeepAlive, true);
	SocketSetOption(socket, SocketSendTimeout, 5000);
	SocketSetOption(socket, SocketReceiveTimeout, 5000);

	g_bConnected = true;
}

public int OnClientSocketError(Handle socket, const int errorType, const int errorNum, any ary)
{
	g_bConnected = false;
	LogMessage("socket error %d (errno %d)", errorType, errorNum);
	CreateTimer(3.0, Timer_Reconnect);
	CloseHandle(socket);
	g_hSocket = INVALID_HANDLE;
}

public int OnChildSocketReceive(Handle socket, char[] receiveData, const int dataSize, any hFile)
{
	if(StrContains(receiveData, key) == -1)
		return;
	
	if(StrContains(receiveData, g_szLAST) != -1)
		return;

	ReplaceString(receiveData, dataSize, key, "");

	if(StrContains(receiveData, DISCONNECTSTR) != -1)
		return;

	if(StrContains(receiveData, "\x01>>>", false) != -1)
	{
		for(int client = 1; client <= MaxClients; ++client)
			if(IsClientInGame(client))
				if(!g_bPbCSC[client])
					PrintToChat(client, receiveData);

		return;
	}

	if(StrContains(receiveData, "[\x02小\x04喇\x0C叭\x01]", false) != -1)
	{
		char fmt[512];
		strcopy(fmt, 512, receiveData);
		ReplaceString(fmt, 512, "[\x02小\x04喇\x0C叭\x01] ", "", false);
		PrepareString(fmt, 512);
		Format(fmt, 512, ">>> 小喇叭 <<<\n%s", fmt);
		CG_ShowGameTextAll(fmt, "20.0", "57 197 187", "-1.0", "0.2");
	}

	if(StrContains(receiveData, "[\x0ECouples\x04]") != -1)
	{
		char fmt[512];
		strcopy(fmt, 512, receiveData);
		ReplaceString(fmt, 512, " \x04[\x0ECouples\x04]  \x07>\x05>\x0C> ", "", false);
		PrepareString(fmt, 512);
		Format(fmt, 512, ">>> 新婚大吉 <<<\n%s", fmt);
		CG_ShowGameTextAll(fmt, "10.0", "255 255 255", "-1.0", "0.2");
	}

	PrintToChatAll(receiveData);
}

public int OnChildSocketDisconnected(Handle socket, any hFile)
{
	LogMessage("Lost connection to master chat server, reconnecting...");
	g_bConnected = false;
	CreateTimer(10.0, Timer_Reconnect);
	CloseHandle(socket);
}

void ConnecToMasterServer()
{
	if(g_bConnected)
		return;
	
	g_bConnected = false;
	g_hSocket = SocketCreate(SOCKET_TCP, OnClientSocketError);
	SocketConnect(g_hSocket, OnClientSocketConnected, OnChildSocketReceive, OnChildSocketDisconnected, MasterServer, StringToInt(port));
}

public bool UpdateMessageToDiscuz(int client, const char[] message)
{
	Handle database = CG_DatabaseGetForum();
	
	if(database == INVALID_HANDLE)
	{
		PrintToChat(client, "[\x0CCG\x01]  服务器当前未准备就绪");
		return false;
	}

	char EscapeString[512];
	SQL_EscapeString(database, message, EscapeString, 512);
	
	if(CG_ClientGetUId(client) < 1)
	{
		PrintToChat(client, "[\x0CCG\x01]  未注册论坛不能发送喇叭");
		return false;
	}

	char m_szName[64];
	CG_ClientGetForumName(client, m_szName, 64);
	
	char m_szQuery[1024];
	Format(m_szQuery, 1024, "INSERT INTO `dz_plugin_ahome_laba` (`username`, `tousername`, `level`, `lid`, `dateline`, `content`, `color`, `url`) VALUES ('%s', '', 'game', 0, '%d', '%s', '', '')", m_szName, GetTime(), EscapeString);
	CG_DatabaseSaveForum(m_szQuery);
	
	return true;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if(!client || !IsClientInGame(client) || g_hSocket == INVALID_HANDLE || IsClientGag(client))
		return Plugin_Continue;

	int startidx;
	if(sArgs[startidx] != '#')
		return Plugin_Continue;
	
	if(Store_GetClientCredits(client) < 200)
		return Plugin_Continue;

	startidx++;

	if(sArgs[startidx] != '#') // sm_say alias
	{
		char message[1024], m_szFinalMsg[1024], m_szServerTag[32];
		strcopy(message, 1024, sArgs[startidx]);
		PrepareString(message, 1024);

		GetServerTag(m_szServerTag, 32);
		
		Format(m_szFinalMsg, 1024, "[\x02小\x04喇\x0C叭\x01] [\x0E%s\x01]  \x04%N\x01 :   \x07%s", m_szServerTag, client, message);
		
		if(!UpdateMessageToDiscuz(client, message))
			return Plugin_Stop;

		Store_SetClientCredits(client, Store_GetClientCredits(client)-200, "发送小喇叭");
		PrintToChat(client, "[\x04Store\x01]  \x01你花费\x04200信用点\x01发送了一条小喇叭");
		
		if(IsClientGag(client))
		{
			PrintToChat(client, "[\x04Store\x01]  \x01你被口球了还想发喇叭?");
			return Plugin_Stop;
		}

		PrintToChatAll(m_szFinalMsg);

		char fmt[512];
		strcopy(fmt, 512, m_szFinalMsg);
		ReplaceString(fmt, 512, "[\x02小\x04喇\x0C叭\x01] ", "", false);
		PrepareString(fmt, 512);
		Format(fmt, 512, ">>> 小喇叭 <<<\n%s", fmt);
		CG_ShowGameTextAll(fmt, "20.0", "57 197 187", "-1.0", "0.2");
	
		Format(m_szFinalMsg, 1024, "%s%s", key, m_szFinalMsg);
		SocketSend(g_hSocket, m_szFinalMsg, 1024);
		strcopy(g_szLAST, 1024, m_szFinalMsg);

		return Plugin_Stop;
	}

	return Plugin_Continue;
}

void PrepareString(char[] message, int maxLen)
{
	ReplaceString(message, maxLen, "!msg ", "", false);
	ReplaceString(message, maxLen, "!xlb ", "", false);
	ReplaceString(message, maxLen, "!dlb ", "", false);
	ReplaceString(message, maxLen, "{normal}", "", false);
	ReplaceString(message, maxLen, "{default}", "", false);
	ReplaceString(message, maxLen, "{white}", "", false);
	ReplaceString(message, maxLen, "{darkred}", "", false);
	ReplaceString(message, maxLen, "{teamcolor}", "", false);
	ReplaceString(message, maxLen, "{pink}", "", false);
	ReplaceString(message, maxLen, "{green}", "", false);
	ReplaceString(message, maxLen, "{HIGHLIGHT}", "", false);
	ReplaceString(message, maxLen, "{lime}", "", false);
	ReplaceString(message, maxLen, "{lightgreen}", "", false);
	ReplaceString(message, maxLen, "{lime}", "", false);
	ReplaceString(message, maxLen, "{lightred}", "", false);
	ReplaceString(message, maxLen, "{red}", "", false);
	ReplaceString(message, maxLen, "{gray}", "", false);
	ReplaceString(message, maxLen, "{grey}", "", false);
	ReplaceString(message, maxLen, "{olive}", "", false);
	ReplaceString(message, maxLen, "{yellow}", "", false);
	ReplaceString(message, maxLen, "{orange}", "", false);
	ReplaceString(message, maxLen, "{silver}", "", false);
	ReplaceString(message, maxLen, "{lightblue}", "", false);
	ReplaceString(message, maxLen, "{blue}", "", false);
	ReplaceString(message, maxLen, "{purple}", "", false);
	ReplaceString(message, maxLen, "{darkorange}", "", false);
	ReplaceString(message, maxLen, "\x01", "", false);
	ReplaceString(message, maxLen, "\x02", "", false);
	ReplaceString(message, maxLen, "\x03", "", false);
	ReplaceString(message, maxLen, "\x04", "", false);
	ReplaceString(message, maxLen, "\x05", "", false);
	ReplaceString(message, maxLen, "\x06", "", false);
	ReplaceString(message, maxLen, "\x07", "", false);
	ReplaceString(message, maxLen, "\x08", "", false);
	ReplaceString(message, maxLen, "\x09", "", false);
	ReplaceString(message, maxLen, "\x10", "", false);
	ReplaceString(message, maxLen, "\x0A", "", false);
	ReplaceString(message, maxLen, "\x0B", "", false);
	ReplaceString(message, maxLen, "\x0C", "", false);
	ReplaceString(message, maxLen, "\x0D", "", false);
	ReplaceString(message, maxLen, "\x0E", "", false);
	ReplaceString(message, maxLen, "\x0F", "", false);
}

void GetServerTag(char[] m_szServerTag, int maxLen)
{
	switch(CG_GetServerId())
	{
		case  1: strcopy(m_szServerTag, maxLen, "僵尸逃跑");
		case  2: strcopy(m_szServerTag, maxLen, "匪镇碟影");
		case  3: strcopy(m_szServerTag, maxLen, "娱乐休闲");
		case  4: strcopy(m_szServerTag, maxLen, "僵尸逃跑");
		case  5: strcopy(m_szServerTag, maxLen, "越狱搞基");
		case  6: strcopy(m_szServerTag, maxLen, "混战干拉");
		case  7: strcopy(m_szServerTag, maxLen, "死斗练枪");
		case  8: strcopy(m_szServerTag, maxLen, "死亡练枪");
		case  9: strcopy(m_szServerTag, maxLen, "满十比赛");
		case 10: strcopy(m_szServerTag, maxLen, "KreedZ①");
		case 11: strcopy(m_szServerTag, maxLen, "KreedZ②");
		case 15: strcopy(m_szServerTag, maxLen, "回防对抗");
		case 21: strcopy(m_szServerTag, maxLen, "测试调试");
		case 22: strcopy(m_szServerTag, maxLen, "饥饿游戏");
		case 23: strcopy(m_szServerTag, maxLen, "死亡滑翔");
		default: strcopy(m_szServerTag, maxLen, "论坛");
	}
}

void ReplaceAllColors(char[] message, int maxLen)
{
	ReplaceString(message, maxLen, "{normal}", "\x01", false);
	ReplaceString(message, maxLen, "{default}", "\x01", false);
	ReplaceString(message, maxLen, "{white}", "\x01", false);
	ReplaceString(message, maxLen, "{darkred}", "\x02", false);
	ReplaceString(message, maxLen, "{teamcolor}", "\x03", false);
	ReplaceString(message, maxLen, "{pink}", "\x03", false);
	ReplaceString(message, maxLen, "{green}", "\x04", false);
	ReplaceString(message, maxLen, "{highlight}", "\x04", false);
	ReplaceString(message, maxLen, "{yellow}", "\x05", false);
	ReplaceString(message, maxLen, "{lightgreen}", "\x05", false);
	ReplaceString(message, maxLen, "{lime}", "\x06", false);
	ReplaceString(message, maxLen, "{lightred}", "\x07", false);
	ReplaceString(message, maxLen, "{red}", "\x07", false);
	ReplaceString(message, maxLen, "{gray}", "\x08", false);
	ReplaceString(message, maxLen, "{grey}", "\x08", false);
	ReplaceString(message, maxLen, "{olive}", "\x09", false);
	ReplaceString(message, maxLen, "{orange}", "\x10", false);
	ReplaceString(message, maxLen, "{silver}", "\x0A", false);
	ReplaceString(message, maxLen, "{lightblue}", "\x0B", false);
	ReplaceString(message, maxLen, "{blue}", "\x0C", false);
	ReplaceString(message, maxLen, "{purple}", "\x0E", false);
	ReplaceString(message, maxLen, "{darkorange}", "\x0F", false);
}

bool IsClientGag(int client)
{
	if(GetFeatureStatus(FeatureType_Native, "BaseComm_IsClientGagged") != FeatureStatus_Available)
		return false;
	
	return BaseComm_IsClientGagged(client);
}