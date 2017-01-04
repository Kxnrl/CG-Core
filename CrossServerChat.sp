#include <sdktools>
#include <socket>
#include <cg_core>
#include <store>
#include <csc>

#pragma newdecls required 

#define DISCONNECTSTR	"DISCONNECTMEPLSTHX"
#define key				"[&KVJL>P*^Y*(JHjkhlsa]"
#define MasterServer	"112.74.128.238"
#define port			"64333"
#define CHAT_SYMBOL '#'

Handle globalClientSocket;
bool g_bConnected;

public Plugin myinfo = 
{
    name		= "Broadcast System - Client",
    author		= "Kyle",
    description	= "Send message on all connected server !",
    version		= "1.5",
    url			= "http://steamcommunity.com/id/_xQy_/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("CG_Broadcast", Native_Broadcast);
	
	return APLRes_Success;
}

public int Native_Broadcast(Handle plugin, int numParams)
{
	char m_szContent[512];
	if(GetNativeString(2, m_szContent, 512) == SP_ERROR_NONE)
	{
		if(GetNativeCell(1))
		{
			Handle db = CG_GetDiscuzDatabase();
			char m_szSQL[512], m_szEsc[512], m_szQuery[1024];
			strcopy(m_szSQL, 512, m_szContent);
			PrepareString(m_szSQL, 512);
			SQL_EscapeString(db, m_szSQL, m_szEsc, 512);
			Format(m_szQuery, 1024, "INSERT INTO `dz_plugin_ahome_laba` (`username`, `tousername`, `level`, `lid`, `dateline`, `content`, `color`, `url`) VALUES ('Broadcast System', '', 'system', 0, '%d', '%s', '', '')", GetTime(), m_szEsc);
			CG_SaveForumData(m_szQuery);
		}
		
		char m_szFinalMsg[1024];
		Format(m_szFinalMsg, 1024, "[\x10Broadcast\x01]  \x07>\x04>\x0C>  \x05%s", m_szContent);
		PrintToChatAll(m_szFinalMsg);

		Format(m_szFinalMsg, 1024, "%s%s", key, m_szFinalMsg);
		SocketSend(globalClientSocket, m_szFinalMsg, 1024);
	}
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_msg", Command_PubMessage);
	RegConsoleCmd("sm_xlb", Command_PubMessage);
	RegConsoleCmd("sm_dlb", Command_PnlMessage);
	
	CreateTimer(3.0, Timer_Reconnect);
}

public void OnPluginEnd()
{
	if(g_bConnected)
	{
		DisconnectFromMasterServer();
	}
}

public void Lily_OnLilyCouple(int Neptune, int Noire)
{
	char m_szFinalMsg[1024];
	Format(m_szFinalMsg, 1024, " \x07恭喜\x0C%N\x07和\x0C%N\x07组成了\x0ELily\x07!", Neptune, Noire);

	Handle database = CG_GetDiscuzDatabase();
	
	if(database == INVALID_HANDLE)
	{
		return;
	}
	
	char EscapeString[512];
	SQL_EscapeString(database, m_szFinalMsg, EscapeString, 512);

	char m_szQuery[1024];
	Format(m_szQuery, 1024, "INSERT INTO `dz_plugin_ahome_laba` (`username`, `tousername`, `level`, `lid`, `dateline`, `content`, `color`, `url`) VALUES ('Lily System', '', 'system', 0, '%d', '%s', '', '')", GetTime(), EscapeString);
	CG_SaveForumData(m_szQuery);
	
	Format(m_szFinalMsg, 1024, "\x04[\x0ELily\x04]  \x07>\x05>\x0C> %s", m_szFinalMsg);
	PrintToChatAll(m_szFinalMsg);

	Format(m_szFinalMsg, 1024, "%s%s", key, m_szFinalMsg);
	SocketSend(globalClientSocket, m_szFinalMsg, 1024);
}

public void OnMapVoteEnd(const char[] map)
{
	if(StrContains(map, "extend", false) != -1)
		return;
	
	if(StrContains(map, "change", false) != -1)
		return;

	char m_szFinalMsg[1024], m_szServerTag[32];
	GetServerTag(m_szServerTag, 32);
	
	Format(m_szFinalMsg, 1024, "[\x10Broadcast\x01]  \x07>\x04>\x0C>  \x04%s即将更换地图为\x05 %s", m_szServerTag, map);
	PrintToChatAll(m_szFinalMsg);

	Format(m_szFinalMsg, 1024, "%s%s", key, m_szFinalMsg);
	SocketSend(globalClientSocket, m_szFinalMsg, 1024);
}

public Action Command_PubMessage(int client, int args)
{
	if(Store_GetClientCredits(client) < 500)
	{
		PrintToChat(client, "\x01 \x04[Store]  \x01没钱还想发小喇叭?");
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

	Store_SetClientCredits(client, Store_GetClientCredits(client)-500, "发送小喇叭");
	PrintToChat(client, "\x01 \x04[Store]  \x01你花费\x04500信用点\x01发送了一条小喇叭");

	PrintToChatAll(m_szFinalMsg);

	Format(m_szFinalMsg, 1024, "%s%s", key, m_szFinalMsg);
	SocketSend(globalClientSocket, m_szFinalMsg, 1024);

	return Plugin_Handled;
}

public Action Command_PnlMessage(int client, int args)
{
	if(Store_GetClientCredits(client) < 5000)
	{
		PrintToChat(client, "\x01 \x04[Store]  \x01没钱还想发大喇叭?");
		return Plugin_Handled;
	}
	
	if(args < 1)
		return Plugin_Handled;
	
	char message[512], m_szFinalMsg[1024], m_szServerTag[32];
	GetCmdArgString(message, 512);
	PrepareString(message, 512);
	GetServerTag(m_szServerTag, 32);

	if(!UpdateMessageToDiscuz(client, message))
		return Plugin_Handled;

	Format(m_szFinalMsg, 1024, "[\x02大\x04喇\x0C叭\x01]  \x04%N\x01 :   \x07%s", client, message);
	
	Store_SetClientCredits(client, Store_GetClientCredits(client)-5000, "发送大喇叭");
	PrintToChat(client, "\x01 \x04[Store]  \x01你花费\x045000信用点\x01发送了一条小喇叭");

	PrintToMenuAll(m_szFinalMsg);

	Format(m_szFinalMsg, 1024, "%s%s", key, m_szFinalMsg);
	SocketSend(globalClientSocket, m_szFinalMsg, 1024);

	return Plugin_Handled;
}

public Action Timer_Reconnect(Handle timer)
{
	ConnecToMasterServer();
}

public int OnClientSocketConnected(Handle socket, any arg)
{	
	SocketSetOption(socket, SocketSendTimeout, 4000);
	SocketSetOption(socket, SocketReceiveTimeout, 4000);

	g_bConnected = true;
}

public int OnClientSocketError(Handle socket, const int errorType, const int errorNum, any ary)
{
	g_bConnected = false;
	LogError("socket error %d (errno %d)", errorType, errorNum);
	CreateTimer(3.0, Timer_Reconnect);
	CloseHandle(socket);
}

public int OnChildSocketReceive(Handle socket, char[] receiveData, const int dataSize, any hFile)
{
	if(StrContains(receiveData, key) != -1)
	{
		ReplaceString(receiveData, dataSize, key, "");

		if(StrContains(receiveData, DISCONNECTSTR) == -1)
		{
			if(StrContains(receiveData, "[\x02小\x04喇\x0C叭\x01]", false) != -1 || StrContains(receiveData, "Broadcast", false) != -1 || StrContains(receiveData, "[\x0ELily\x04]", false) != -1)
				PrintToChatAll(receiveData);
			else
			{
				PrintToChatAll(receiveData);
				PrintToMenuAll(receiveData);
			}
		}
	}
}

public int OnChildSocketDisconnected(Handle socket, any hFile)
{
	LogError("Lost connection to master chat server, reconnecting...");
	g_bConnected = false;
	CreateTimer(10.0, Timer_Reconnect);
	CloseHandle(socket);
}

stock void DisconnectFromMasterServer()
{
	char m_szFinalMsg[1024];
	char serverName[45];
	GetConVarString(FindConVar("hostname"), serverName, sizeof(serverName));
	Format(m_szFinalMsg, 1024, "%s%s%s", key, DISCONNECTSTR, serverName);
	SocketSend(globalClientSocket, m_szFinalMsg, 1024);
	CloseHandle(globalClientSocket);
	globalClientSocket = INVALID_HANDLE;
}


stock void ConnecToMasterServer()
{
	if(g_bConnected)
		return;
	
	g_bConnected = false;
	globalClientSocket = SocketCreate(SOCKET_TCP, OnClientSocketError);
	SocketConnect(globalClientSocket, OnClientSocketConnected, OnChildSocketReceive, OnChildSocketDisconnected, MasterServer, StringToInt(port));
}

stock void PrintToMenuAll(char[] message)
{
	ReplaceString(message, 512, "[\x02大\x04喇\x0C叭\x01]  ", "");
	ReplaceString(message, 512, "[\x02小\x04喇\x0C叭\x01] ", "");
	PrepareString(message, 512);

	char title[100];
	Format(title, 64, "全服/全站 大喇叭：");
	
	Panel mSayPanel = CreatePanel();
	mSayPanel.SetTitle(title);

	DrawPanelItem(mSayPanel, "", ITEMDRAW_SPACER);
	DrawPanelText(mSayPanel, message);
	DrawPanelItem(mSayPanel, "", ITEMDRAW_SPACER);

	SetPanelCurrentKey(mSayPanel, 10);
	DrawPanelItem(mSayPanel, "Exit", ITEMDRAW_CONTROL);

	for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && !IsFakeClient(i))
			SendPanelToClient(mSayPanel, i, Handler_DoNothing, 10);

	delete mSayPanel;
}

public int Handler_DoNothing(Menu menu, MenuAction action, int param1, int param2)
{

}

public bool UpdateMessageToDiscuz(int client, const char[] message)
{
	Handle database = CG_GetDiscuzDatabase();
	
	if(database == INVALID_HANDLE)
	{
		PrintToChat(client, "[\x0CCG\x01]  服务器当前未准备就绪");
		return false;
	}

	char EscapeString[512];
	SQL_EscapeString(database, message, EscapeString, 512);
	
	if(CG_GetDiscuzUID(client) < 1)
	{
		PrintToChat(client, "[\x0CCG\x01]  未注册论坛不能发送喇叭");
		return false;
	}
	
	char m_szName[64];
	CG_GetDiscuzName(client, m_szName, 64);
	
	char m_szQuery[1024];
	Format(m_szQuery, 1024, "INSERT INTO `dz_plugin_ahome_laba` (`username`, `tousername`, `level`, `lid`, `dateline`, `content`, `color`, `url`) VALUES ('%s', '', 'game', 0, '%d', '%s', '', '')", m_szName, GetTime(), EscapeString);
	CG_SaveForumData(m_szQuery);
	
	return true;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if(!IsValidClient(client))
		return Plugin_Continue;

	int startidx;
	if(sArgs[startidx] != CHAT_SYMBOL)
		return Plugin_Continue;
	
	if(Store_GetClientCredits(client) < 500)
		return Plugin_Continue;

	startidx++;

	if(sArgs[startidx] != CHAT_SYMBOL) // sm_say alias
	{
		char message[1024], m_szFinalMsg[1024], m_szServerTag[32];
		strcopy(message, 1024, sArgs[startidx]);
		PrepareString(message, 1024);

		GetServerTag(m_szServerTag, 32);
		
		Format(m_szFinalMsg, 1024, "[\x02小\x04喇\x0C叭\x01] [\x0E%s\x01]  \x04%N\x01 :   \x07%s", m_szServerTag, client, message);
		
		if(!UpdateMessageToDiscuz(client, message))
			return Plugin_Stop;

		Store_SetClientCredits(client, Store_GetClientCredits(client)-500, "发送小喇叭");
		PrintToChat(client, "\x01 \x04[Store]  \x01你花费\x04500信用点\x01发送了一条小喇叭");

		PrintToChatAll(m_szFinalMsg);

		Format(m_szFinalMsg, 1024, "%s%s", key, m_szFinalMsg);
		SocketSend(globalClientSocket, m_szFinalMsg, 1024);

		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

stock void PrepareString(char[] message, int mexLen)
{
	ReplaceString(message, mexLen, "!msg ", "", false);
	ReplaceString(message, mexLen, "!xlb ", "", false);
	ReplaceString(message, mexLen, "!dlb ", "", false);
	ReplaceString(message, mexLen, "{default}", "", false);
	ReplaceString(message, mexLen, "{white}", "", false);
	ReplaceString(message, mexLen, "{darkred}", "", false);
	ReplaceString(message, mexLen, "{pink}", "", false);
	ReplaceString(message, mexLen, "{green}", "", false);
	ReplaceString(message, mexLen, "{lime}", "", false);
	ReplaceString(message, mexLen, "{lightgreen}", "", false);
	ReplaceString(message, mexLen, "{red}", "", false);
	ReplaceString(message, mexLen, "{gray}", "", false);
	ReplaceString(message, mexLen, "{grey}", "", false);
	ReplaceString(message, mexLen, "{olive}", "", false);
	ReplaceString(message, mexLen, "{orange}", "", false);
	ReplaceString(message, mexLen, "{purple}", "", false);
	ReplaceString(message, mexLen, "{lightblue}", "", false);
	ReplaceString(message, mexLen, "{blue}", "", false);
	ReplaceString(message, mexLen, "\x01", "", false);
	ReplaceString(message, mexLen, "\x02", "", false);
	ReplaceString(message, mexLen, "\x03", "", false);
	ReplaceString(message, mexLen, "\x04", "", false);
	ReplaceString(message, mexLen, "\x05", "", false);
	ReplaceString(message, mexLen, "\x06", "", false);
	ReplaceString(message, mexLen, "\x07", "", false);
	ReplaceString(message, mexLen, "\x08", "", false);
	ReplaceString(message, mexLen, "\x09", "", false);
	ReplaceString(message, mexLen, "\x10", "", false);
	ReplaceString(message, mexLen, "\x0A", "", false);
	ReplaceString(message, mexLen, "\x0B", "", false);
	ReplaceString(message, mexLen, "\x0C", "", false);
	ReplaceString(message, mexLen, "\x0D", "", false);
	ReplaceString(message, mexLen, "\x0E", "", false);
	ReplaceString(message, mexLen, "\x0F", "", false);
}

stock void GetServerTag(char[] m_szServerTag, int maxLen)
{
	char m_szServerName[64];
	GetConVarString(FindConVar("hostname"), m_szServerName, 64);
	if(StrContains(m_szServerName, "逃跑", false ) != -1)
		strcopy(m_szServerTag, 32, "僵尸逃跑");
	else if(StrContains(m_szServerName, "TTT", false ) != -1)
		strcopy(m_szServerTag, 32, "匪镇碟影");
	else if(StrContains(m_szServerName, "MiniGames", false ) != -1)
		strcopy(m_szServerTag, 32, "娱乐休闲");
	else if(StrContains(m_szServerName, "JailBreak", false ) != -1)
		strcopy(m_szServerTag, 32, "越狱搞基");
	else if(StrContains(m_szServerName, "KreedZ", false ) != -1)
		strcopy(m_szServerTag, 32, "Kz跳跃");
	else if(StrContains(m_szServerName, "DeathRun", false ) != -1)
		strcopy(m_szServerTag, 32, "死亡奔跑");
	else if(StrContains(m_szServerName, "战役", false ) != -1)
		strcopy(m_szServerTag, 32, "求生战役");
	else if(StrContains(m_szServerName, "对抗", false ) != -1)
		strcopy(m_szServerTag, 32, "求生对抗");
	else if(StrContains(m_szServerName, "HG", false ) != -1)
		strcopy(m_szServerTag, 32, "饥饿游戏");
	else if(StrContains(m_szServerName, "死斗", false ) != -1)
		strcopy(m_szServerTag, 32, "纯净死斗");
	else if(StrContains(m_szServerName, "纯净死亡", false ) != -1)
		strcopy(m_szServerTag, 32, "纯净死亡");
	else if(StrContains(m_szServerName, "Riot", false ) != -1)
		strcopy(m_szServerTag, 32, "僵尸暴动");
	else if(StrContains(m_szServerName, "Ninja", false ) != -1)
		strcopy(m_szServerTag, 32, "忍者行动");
	else if(StrContains(m_szServerName, "BHop", false ) != -1)
		strcopy(m_szServerTag, 32, "BHop连跳");
	else if(StrContains(m_szServerName, "满十", false ) != -1)
		strcopy(m_szServerTag, 32, "满十比赛");
	else
		strcopy(m_szServerTag, 32, "论坛");
	
	if(StrContains(m_szServerName, "1#", false ) != -1 || StrContains(m_szServerName, "1服", false ) != -1)
		StrCat(m_szServerTag, 32, "1服");
	
	if(StrContains(m_szServerName, "2#", false ) != -1 || StrContains(m_szServerName, "2服", false ) != -1)
		StrCat(m_szServerTag, 32, "2服");
}

stock bool IsValidClient(int client)
{
	if(client <= 0) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}