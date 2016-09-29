#include <sourcemod>
#include <sdktools>
#include <socket>
#include <clientprefs>
#include <cg_core>
#include <store>

#define PLUGIN_AUTHOR 	"maoling ( xQy )"
#define PLUGIN_VERSION 	"1.4"
#define PLUGIN_TAG		"[\x0C小喇叭\x01] "
#define PLAYER_GAGED 	1
#define PLAYER_UNGAGED 	0
#define DISCONNECTSTR	"DISCONNECTMEPLSTHX"
#define SENDERNAME		"[SENDER NAME]"
#define SERVERTAG		"[SERVER TAG]"
#define SENDERMSG		"[MESSAGE]"
#define key				"[&KVJL>P*^Y*(JHjkhlsa]"
#define MasterServer	"112.74.128.238"
#define port			"64333"
#define CHAT_SYMBOL '#'

Handle globalClientSocket;

int gagState[MAXPLAYERS+1];

bool connected;

public Plugin myinfo = 
{
    name = "小喇叭 - Clients",
    author = PLUGIN_AUTHOR,
    description = "Send message on all connected server !",
    version = PLUGIN_VERSION,
    url = "http://www.sourcemod.net"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_msg", Command_PubMessage);
	RegConsoleCmd("sm_xlb", Command_PubMessage);
	RegConsoleCmd("sm_dlb", Command_SrvMessage);
	RegAdminCmd("sm_servermsg", Command_SrvMessage, ADMFLAG_ROOT);
}

public void OnPluginEnd()
{
	if(connected)
	{
		DisconnectFromMasterServer();
	}
}

public void OnConfigsExecuted()
{
	ConnecToMasterServer();
}

public void Lily_OnLilyCouple(int Neptune, int Noire)
{
	char finalMessage[1024];
	Format(finalMessage, 1024, " \x07恭喜\x0C%N\x07和\x0C%N\x07组成了\x0ELily\x07!他们收到了来自Planeptune女神的祝福...", Neptune, Noire);

	char Error[256];
	Handle database = SQL_Connect("csgo", true, Error, 256);
	
	if(database == INVALID_HANDLE)
	{
		return;
	}
	
	char EscapeString[512];
	SQL_EscapeString(database, finalMessage, EscapeString, 512);
	CloseHandle(database);

	char m_szQuery[1024];
	Format(m_szQuery, 1024, "INSERT INTO `dz_plugin_ahome_laba` (`username`, `tousername`, `level`, `lid`, `dateline`, `content`, `color`, `url`) VALUES ('Lily System', '', 'game', 0, '%d', '%s', '', '')", GetTime(), EscapeString);
	CG_SaveForumData(m_szQuery);
	
	Format(finalMessage, 1024, "\x04[\x0ELily\x04]  \x07>\x05>\x0C> %s", finalMessage);
	
	PrintToChatAll(finalMessage);

	Format(finalMessage, 1024, "%s%s", key, finalMessage);
	LogMessage("Send message: %s", finalMessage);
	SocketSend(globalClientSocket, finalMessage, sizeof(finalMessage));
}

public Action Command_PubMessage(client, args)
{
	if(Store_GetClientCredits(client) < 500)
	{
		PrintToChat(client, "\x01 \x04[Store]  \x01没钱还想发小喇叭?");
		return Plugin_Handled;
	}
	
	if(args < 1)
		return Plugin_Handled;
	
	char message[900];
	GetCmdArgString(message, sizeof(message));
	ReplaceString(message, sizeof(message), "!msg ", "");
	ReplaceString(message, sizeof(message), "!xlb ", "");
	ReplaceString(message, sizeof(message), "!dlb ", "");
	ReplaceString(message, sizeof(message), "{default}", "");
	ReplaceString(message, sizeof(message), "{white}", "");
	ReplaceString(message, sizeof(message), "{darkred}", "");
	ReplaceString(message, sizeof(message), "{pink}", "");
	ReplaceString(message, sizeof(message), "{green}", "");
	ReplaceString(message, sizeof(message), "{lime}", "");
	ReplaceString(message, sizeof(message), "{lightgreen}", "");
	ReplaceString(message, sizeof(message), "{red}", "");
	ReplaceString(message, sizeof(message), "{gray}", "");
	ReplaceString(message, sizeof(message), "{grey}", "");
	ReplaceString(message, sizeof(message), "{olive}", "");
	ReplaceString(message, sizeof(message), "{orange}", "");
	ReplaceString(message, sizeof(message), "{purple}", "");
	ReplaceString(message, sizeof(message), "{lightblue}", "");
	ReplaceString(message, sizeof(message), "{blue}", "");
	ReplaceString(message, sizeof(message), "\x01", "");
	ReplaceString(message, sizeof(message), "\x02", "");
	ReplaceString(message, sizeof(message), "\x03", "");
	ReplaceString(message, sizeof(message), "\x04", "");
	ReplaceString(message, sizeof(message), "\x05", "");
	ReplaceString(message, sizeof(message), "\x06", "");
	ReplaceString(message, sizeof(message), "\x07", "");
	ReplaceString(message, sizeof(message), "\x08", "");
	ReplaceString(message, sizeof(message), "\x09", "");
	ReplaceString(message, sizeof(message), "\x10", "");
	ReplaceString(message, sizeof(message), "\x0A", "");
	ReplaceString(message, sizeof(message), "\x0B", "");
	ReplaceString(message, sizeof(message), "\x0C", "");
	ReplaceString(message, sizeof(message), "\x0D", "");
	ReplaceString(message, sizeof(message), "\x0E", "");
	ReplaceString(message, sizeof(message), "\x0F", "");

	char finalMessage[999];
	
	char m_szServerName[64], m_szServerTag[32];
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
	
	Format(finalMessage, sizeof(finalMessage), "[\x02小\x04喇\x0C叭\x01] [\x0E%s\x01]  \x04%N\x01 :   \x07%s", m_szServerTag, client, message);
	
	if(!UpdateMessageToDiscuz(client, message))
		return Plugin_Handled;
	
	Store_SetClientCredits(client, Store_GetClientCredits(client)-500, "发送小喇叭");
	PrintToChat(client, "\x01 \x04[Store]  \x01你花费\x04500Credits\x01发送了一条小喇叭");

	PrintToChatAll(finalMessage);

	Format(finalMessage, sizeof(finalMessage), "%s%s", key, finalMessage);
	SocketSend(globalClientSocket, finalMessage, sizeof(finalMessage));

	return Plugin_Handled;
}

public Action Command_SrvMessage(client, args)
{
	if(args < 1)
		return Plugin_Handled;
	
	char message[900];
	GetCmdArgString(message, sizeof(message));

	char finalMessage[999];

	if(client >= 0)
	{	
		char m_szServerName[64], m_szServerTag[32];
		GetConVarString(FindConVar("hostname"), m_szServerName, 64);
		if(StrContains(m_szServerName, "逃跑", false ) != -1)
			strcopy(m_szServerTag, 32, "僵尸逃跑");
		else if(StrContains(m_szServerName, "TTT", false ) != -1)
			strcopy(m_szServerTag, 32, "匪镇碟影");
		else if(StrContains(m_szServerName, "MiniGames", false ) != -1)
			strcopy(m_szServerTag, 32, "娱乐休闲");
		else if(StrContains(m_szServerName, "JaliBreak", false ) != -1)
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
		
		Format(finalMessage, sizeof(finalMessage), "[\x02小\x04喇\x0C叭\x01] [\x0E%s\x01]  \x04服务器消息\x01 :   \x07%s", m_szServerTag, message);

		PrintToChatAll(finalMessage);

		Format(finalMessage, sizeof(finalMessage), "%s%s", key, finalMessage);
		LogMessage("Send message: %s", finalMessage);
		SocketSend(globalClientSocket, finalMessage, sizeof(finalMessage));
	}

	return Plugin_Handled;
}


public Action Command_PnlMessage(client, args)
{
	if(Store_GetClientCredits(client) < 10000)
	{
		PrintToChat(client, "\x01 \x04[Store]  \x01没钱还想发大喇叭?");
		return Plugin_Handled;
	}
	
	if(args < 1)
		return Plugin_Handled;
	
	char message[900];
	GetCmdArgString(message, sizeof(message));
	ReplaceString(message, sizeof(message), "!msg ", "");
	ReplaceString(message, sizeof(message), "!xlb ", "");
	ReplaceString(message, sizeof(message), "!dlb ", "");
	ReplaceString(message, sizeof(message), "{default}", "");
	ReplaceString(message, sizeof(message), "{white}", "");
	ReplaceString(message, sizeof(message), "{darkred}", "");
	ReplaceString(message, sizeof(message), "{pink}", "");
	ReplaceString(message, sizeof(message), "{green}", "");
	ReplaceString(message, sizeof(message), "{lime}", "");
	ReplaceString(message, sizeof(message), "{lightgreen}", "");
	ReplaceString(message, sizeof(message), "{red}", "");
	ReplaceString(message, sizeof(message), "{gray}", "");
	ReplaceString(message, sizeof(message), "{grey}", "");
	ReplaceString(message, sizeof(message), "{olive}", "");
	ReplaceString(message, sizeof(message), "{orange}", "");
	ReplaceString(message, sizeof(message), "{purple}", "");
	ReplaceString(message, sizeof(message), "{lightblue}", "");
	ReplaceString(message, sizeof(message), "{blue}", "");
	ReplaceString(message, sizeof(message), "\x01", "");
	ReplaceString(message, sizeof(message), "\x02", "");
	ReplaceString(message, sizeof(message), "\x03", "");
	ReplaceString(message, sizeof(message), "\x04", "");
	ReplaceString(message, sizeof(message), "\x05", "");
	ReplaceString(message, sizeof(message), "\x06", "");
	ReplaceString(message, sizeof(message), "\x07", "");
	ReplaceString(message, sizeof(message), "\x08", "");
	ReplaceString(message, sizeof(message), "\x09", "");
	ReplaceString(message, sizeof(message), "\x10", "");
	ReplaceString(message, sizeof(message), "\x0A", "");
	ReplaceString(message, sizeof(message), "\x0B", "");
	ReplaceString(message, sizeof(message), "\x0C", "");
	ReplaceString(message, sizeof(message), "\x0D", "");
	ReplaceString(message, sizeof(message), "\x0E", "");
	ReplaceString(message, sizeof(message), "\x0F", "");

	char finalMessage[999];
	
	if(!UpdateMessageToDiscuz(client, message))
		return Plugin_Handled;

	Format(finalMessage, sizeof(finalMessage), "[\x02大\x04喇\x0C叭\x01]  \x04%N\x01 :   \x07%s", client, message);
	
	Store_SetClientCredits(client, Store_GetClientCredits(client)-5000, "发送大喇叭");
	PrintToChat(client, "\x01 \x04[Store]  \x01你花费\x045000Credits\x01发送了一条小喇叭");

	PrintToMenuAll(finalMessage);

	Format(finalMessage, sizeof(finalMessage), "%s%s", key, finalMessage);
	LogMessage("Send message: %s", finalMessage);
	SocketSend(globalClientSocket, finalMessage, sizeof(finalMessage));


	return Plugin_Handled;
}

   
//In case a client get disconnected, reconnect him every X seconds
public Action TimerReconnect(Handle tmr, any arg)
{
	PrintToServer("Trying to reconnect to the master server...");
	ConnecToMasterServer();
}

//stocks

//Nah.
stock bool IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}

//When the CLIENT (and not the MCS) connected to the MCS :
public OnClientSocketConnected(Handle socket, any arg)
{	
	PrintToServer("Sucessfully connected to master chat server ! (%s:%s)", MasterServer, port);
	LogMessage("Sucessfully connected to master chat server ! (%s:%s)", MasterServer, port);
	SocketSetOption(socket, SocketSendTimeout, 4000);
	SocketSetOption(socket, SocketReceiveTimeout, 4000);
	
	//Nothing much to say...
	
	connected = true; //Important boolean : Store the state of the connection for this server.
}

//When the client crash
public OnClientSocketError(Handle socket, const int errorType, const int errorNum, any ary)
{
	connected = false; //Client NOT connected anymore, this is very important.
	LogError("socket error %d (errno %d)", errorType, errorNum);
	CreateTimer(30.0, TimerReconnect); //Ask for the plugin to reconnect to the MCS in X seconds
	CloseHandle(socket);
}

//When a client sent a message to the MCS OR the MCS sent a message to the client, and the MCS have to handle it :
public OnChildSocketReceive(Handle socket, char[] receiveData, const int dataSize, any hFile)
{
	LogMessage("Receive data");
	if(StrContains(receiveData, key) != -1) //The message contain the security key ?
	{
		ReplaceString(receiveData, dataSize, key, ""); //Remove the key from the message
		LogMessage(receiveData);
		if(StrContains(receiveData, DISCONNECTSTR) != -1) //Is the message a quit message ?
		{
		}
		else //The message is a simple message, print it.
		{
			PrintToServer(receiveData);
			if(StrContains(receiveData, "[\x02小\x04喇\x0C叭\x01]", false) != -1)
				PrintToChatAll(receiveData);
			else
			{
				PrintToMenuAll(receiveData);
				PrintToChatAll(receiveData);
			}
		}
	}
}

//Called when the MCS disconnect, force the client to reconnect :
public OnChildSocketDisconnected(Handle socket, any hFile)
{
	PrintToServer("Lost connection to master chat server, reconnecting...");
	LogMessage("Lost connection to master chat server, reconnecting...");
	connected = false; //Very important.
	CreateTimer(10.0, TimerReconnect); //Reconnecting timer
	CloseHandle(socket);
}

stock void DisconnectFromMasterServer()
{
	//Build the disconnecting message
	char finalMessage[400];
	char serverName[45];
	GetConVarString(FindConVar("hostname"), serverName, sizeof(serverName));
	Format(finalMessage, sizeof(finalMessage), "%s%s%s", key, DISCONNECTSTR, serverName);
	//Send the disconnecting message
	SocketSend(globalClientSocket, finalMessage, sizeof(finalMessage));
	CloseHandle(globalClientSocket);
	globalClientSocket = INVALID_HANDLE;	
}

//Connect to the MCS
stock void ConnecToMasterServer()
{
	if (connected)
		return;
	
	connected = false;
	globalClientSocket = SocketCreate(SOCKET_UDP, OnClientSocketError);
	PrintToServer("Attempt to connect to %s:%s ...", MasterServer, port);
	SocketConnect(globalClientSocket, OnClientSocketConnected, OnChildSocketReceive, OnChildSocketDisconnected, MasterServer, StringToInt(port));
	LogMessage("Attempt to connect to %s:%s ...", MasterServer, port);
}

stock void PrintToMenuAll(char[] message)
{
	ReplaceString(message, 512, "[\x02大\x04喇\x0C叭\x01]  ", "");
	ReplaceString(message, 512, "[\x02小\x04喇\x0C叭\x01] ", "");
	ReplaceString(message, 512, "\x01", "");
	ReplaceString(message, 512, "\x02", "");
	ReplaceString(message, 512, "\x03", "");
	ReplaceString(message, 512, "\x04", "");
	ReplaceString(message, 512, "\x05", "");
	ReplaceString(message, 512, "\x06", "");
	ReplaceString(message, 512, "\x07", "");
	ReplaceString(message, 512, "\x08", "");
	ReplaceString(message, 512, "\x09", "");
	ReplaceString(message, 512, "\x10", "");
	ReplaceString(message, 512, "\x0A", "");
	ReplaceString(message, 512, "\x0B", "");
	ReplaceString(message, 512, "\x0C", "");
	ReplaceString(message, 512, "\x0D", "");
	ReplaceString(message, 512, "\x0E", "");
	ReplaceString(message, 512, "\x0F", "");

	char title[100];
	Format(title, 64, "全服/全站 大喇叭：");
	
	Panel mSayPanel = CreatePanel();
	mSayPanel.SetTitle(title);

	DrawPanelItem(mSayPanel, "", ITEMDRAW_SPACER);
	DrawPanelText(mSayPanel, message);
	DrawPanelItem(mSayPanel, "", ITEMDRAW_SPACER);

	SetPanelCurrentKey(mSayPanel, 10);
	DrawPanelItem(mSayPanel, "Exit", ITEMDRAW_CONTROL);

	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			SendPanelToClient(mSayPanel, i, Handler_DoNothing, 10);
		}
	}

	delete mSayPanel;
}

public Handler_DoNothing(Menu menu, MenuAction action, int param1, int param2)
{
	/* Do nothing */
}

public bool UpdateMessageToDiscuz(int client, const char[] message)
{
	char Error[256];
	Handle database = SQL_Connect("csgo", true, Error, 256);
	
	if(database == INVALID_HANDLE)
	{
		PrintToChat(client, "[\x0EPlaneptune\x01]  服务器当前未准备就绪");
		return false;
	}
	
	char EscapeString[512];
	SQL_EscapeString(database, message, EscapeString, 512);
	CloseHandle(database);
	
	if(CG_GetDiscuzUID(client) < 1)
	{
		PrintToChat(client, "[\x0EPlaneptune\x01]  未注册论坛不能发送喇叭");
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
	if(client == 0)
		return Plugin_Continue;

	int startidx;
	if(sArgs[startidx] != CHAT_SYMBOL)
		return Plugin_Continue;

	startidx++;
	
	if(strcmp(command, "say", false) != 0)
		return Plugin_Continue;

	if(sArgs[startidx] != CHAT_SYMBOL) // sm_say alias
	{
		char message[900];
		strcopy(message, sizeof(message), sArgs[startidx]);
		ReplaceString(message, sizeof(message), "{default}", "");
		ReplaceString(message, sizeof(message), "{white}", "");
		ReplaceString(message, sizeof(message), "{darkred}", "");
		ReplaceString(message, sizeof(message), "{pink}", "");
		ReplaceString(message, sizeof(message), "{green}", "");
		ReplaceString(message, sizeof(message), "{lime}", "");
		ReplaceString(message, sizeof(message), "{lightgreen}", "");
		ReplaceString(message, sizeof(message), "{red}", "");
		ReplaceString(message, sizeof(message), "{gray}", "");
		ReplaceString(message, sizeof(message), "{grey}", "");
		ReplaceString(message, sizeof(message), "{olive}", "");
		ReplaceString(message, sizeof(message), "{orange}", "");
		ReplaceString(message, sizeof(message), "{purple}", "");
		ReplaceString(message, sizeof(message), "{lightblue}", "");
		ReplaceString(message, sizeof(message), "{blue}", "");
		ReplaceString(message, sizeof(message), "\x01", "");
		ReplaceString(message, sizeof(message), "\x02", "");
		ReplaceString(message, sizeof(message), "\x03", "");
		ReplaceString(message, sizeof(message), "\x04", "");
		ReplaceString(message, sizeof(message), "\x05", "");
		ReplaceString(message, sizeof(message), "\x06", "");
		ReplaceString(message, sizeof(message), "\x07", "");
		ReplaceString(message, sizeof(message), "\x08", "");
		ReplaceString(message, sizeof(message), "\x09", "");
		ReplaceString(message, sizeof(message), "\x10", "");
		ReplaceString(message, sizeof(message), "\x0A", "");
		ReplaceString(message, sizeof(message), "\x0B", "");
		ReplaceString(message, sizeof(message), "\x0C", "");
		ReplaceString(message, sizeof(message), "\x0D", "");
		ReplaceString(message, sizeof(message), "\x0E", "");
		ReplaceString(message, sizeof(message), "\x0F", "");

		char finalMessage[999];
		
		char m_szServerName[64], m_szServerTag[32];
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
		
		Format(finalMessage, sizeof(finalMessage), "[\x02小\x04喇\x0C叭\x01] [\x0E%s\x01]  \x04%N\x01 :   \x07%s", m_szServerTag, client, message);
		
		if(!UpdateMessageToDiscuz(client, message))
			return Plugin_Stop;
		
		Store_SetClientCredits(client, Store_GetClientCredits(client)-500, "发送小喇叭");
		PrintToChat(client, "\x01 \x04[Store]  \x01你花费\x04500Credits\x01发送了一条小喇叭");

		PrintToChatAll(finalMessage);

		Format(finalMessage, sizeof(finalMessage), "%s%s", key, finalMessage);
		SocketSend(globalClientSocket, finalMessage, sizeof(finalMessage));

		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}
