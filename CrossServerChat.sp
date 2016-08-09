#include <sourcemod>
#include <sdktools>
#include <socket>
#include <clientprefs>
#include <store>

#define PLUGIN_AUTHOR 	"maoling ( shAna.xQy )"
#define PLUGIN_VERSION 	"1.00"
#define PLUGIN_TAG		"[\x0C小喇叭\x01] "
#define PLAYER_GAGED 	1
#define PLAYER_UNGAGED 	0
#define DISCONNECTSTR	"DISCONNECTMEPLSTHX"
#define SENDERNAME		"[SENDER NAME]"
#define SERVERTAG		"[SERVER TAG]"
#define SENDERMSG		"[MESSAGE]"
#define key				"[&KVJL>P*^Y*(JHjkhlsa]"
#define MasterServer	"112.74.128.238"
#define port			"2001"

Handle globalClientSocket;
Handle COOKIE_ClientGaged;

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
	RegAdminCmd("sm_cscgag", CMD_GagFromCrossServer, ADMFLAG_CHAT, "Ban/Unban a player from using the cross server chat functionality.");
	RegConsoleCmd("sm_msg", CMD_SendMessage1, "Send a message to all server.");
	RegConsoleCmd("sm_xlb", CMD_SendMessage1, "Send a message to all server.");
	RegConsoleCmd("sm_dlb", CMD_SendMessage2, "Send a message to all server.");
	RegAdminCmd("sm_servermsg", CMD_ServerMessage, ADMFLAG_ROOT, "Send a message to all server.");

	COOKIE_ClientGaged = RegClientCookie("sm_csc_client_gaged", "Store the gag state of the player.", CookieAccess_Private);
	
	for(new i = MaxClients; i > 0; --i)
	{
		if(!AreClientCookiesCached(i))
			continue;
		
		OnClientCookiesCached(i);
	}

	AutoExecConfig(true, "CrossServerChat");
}

//When the plugin is unloaded / reloaded
public void OnPluginEnd()
{
	//If the client is connected (and is not the master chat server (MCS)) send the qui messsage to MCS
	if(connected)
	{
		DisconnectFromMasterServer();
	}
}

public void OnConfigsExecuted()
{
	ConnecToMasterServer(); //This server is a client server and want to connect to the MCS
}

//Load data from cookies
public OnClientCookiesCached(int client)
{
	//Get value of cookie and store it inside gagState[]
	char cookieValue[10];
	GetClientCookie(client, COOKIE_ClientGaged, cookieValue, sizeof(cookieValue));
	gagState[client] = StringToInt(cookieValue);
}

public Action CMD_SendMessage1(client, args)
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
	
	if(gagState[client] == PLAYER_GAGED)
	{
		Handle pack;
		char text[200];
		CreateDataTimer(0.5, PrintMessageOnChatMessage, pack);
		WritePackCell(pack, client);
		Format(text, sizeof(text), "%s You have been banned from using this command.", PLUGIN_TAG);
		WritePackString(pack, text);
	}
	else
	{	
		char m_szServerName[64], m_szServerTag[32];
		GetConVarString(FindConVar("hostname"), m_szServerName, 64);
		if(StrContains(m_szServerName, "逃跑", false ) != -1)
			Format(m_szServerTag, 32, "僵尸逃跑");
		else if(StrContains(m_szServerName, "TTT", false ) != -1)
			Format(m_szServerTag, 32, "匪镇碟影");
		else if(StrContains(m_szServerName, "MiniGames", false ) != -1)
			Format(m_szServerTag, 32, "娱乐休闲");
		else if(StrContains(m_szServerName, "JailBreak", false ) != -1)
			Format(m_szServerTag, 32, "越狱搞基");
		else if(StrContains(m_szServerName, "KreedZ", false ) != -1)
			Format(m_szServerTag, 32, "Kz跳跃");
		else if(StrContains(m_szServerName, "DeathRun", false ) != -1)
			Format(m_szServerTag, 32, "死亡奔跑");
		else if(StrContains(m_szServerName, "战役", false ) != -1)
			Format(m_szServerTag, 32, "求生战役");
		else if(StrContains(m_szServerName, "对抗", false ) != -1)
			Format(m_szServerTag, 32, "求生对抗");
		else if(StrContains(m_szServerName, "HG", false ) != -1)
			Format(m_szServerTag, 32, "饥饿游戏");
		else if(StrContains(m_szServerName, "死斗", false ) != -1)
			Format(m_szServerTag, 32, "纯净死斗");
		else if(StrContains(m_szServerName, "纯净死亡", false ) != -1)
			Format(m_szServerTag, 32, "纯净死亡");
		else if(StrContains(m_szServerName, "Riot", false ) != -1)
			Format(m_szServerTag, 32, "僵尸暴动");
		else if(StrContains(m_szServerName, "Ninja", false ) != -1)
			Format(m_szServerTag, 32, "忍者行动");
		else if(StrContains(m_szServerName, "BHop", false ) != -1)
			Format(m_szServerTag, 32, "BHop连跳");
		else if(StrContains(m_szServerName, "满十", false ) != -1)
			Format(m_szServerTag, 32, "满十比赛");
		else
			Format(m_szServerTag, 32, "论坛");
		
		Format(finalMessage, sizeof(finalMessage), "[\x02小\x04喇\x0C叭\x01] [\x0E%s\x01]  \x04%N\x01 :   \x07%s", m_szServerTag, client, message);
		
		Store_SetClientCredits(client, Store_GetClientCredits(client)-500, "发送小喇叭");
		PrintToChat(client, "\x01 \x04[Store]  \x01你花费\x04500Credits\x01发送了一条小喇叭");

		PrintToChatAll(finalMessage);

		Format(finalMessage, sizeof(finalMessage), "%s%s", key, finalMessage);
		LogMessage("Send message: %s", finalMessage);
		SocketSend(globalClientSocket, finalMessage, sizeof(finalMessage));
	}

	return Plugin_Handled;
}

public Action CMD_ServerMessage(client, args)
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
			Format(m_szServerTag, 32, "僵尸逃跑");
		else if(StrContains(m_szServerName, "TTT", false ) != -1)
			Format(m_szServerTag, 32, "匪镇碟影");
		else if(StrContains(m_szServerName, "MiniGames", false ) != -1)
			Format(m_szServerTag, 32, "娱乐休闲");
		else if(StrContains(m_szServerName, "JaliBreak", false ) != -1)
			Format(m_szServerTag, 32, "越狱搞基");
		else if(StrContains(m_szServerName, "KreedZ", false ) != -1)
			Format(m_szServerTag, 32, "Kz跳跃");
		else if(StrContains(m_szServerName, "DeathRun", false ) != -1)
			Format(m_szServerTag, 32, "死亡奔跑");
		else if(StrContains(m_szServerName, "战役", false ) != -1)
			Format(m_szServerTag, 32, "求生战役");
		else if(StrContains(m_szServerName, "对抗", false ) != -1)
			Format(m_szServerTag, 32, "求生对抗");
		else if(StrContains(m_szServerName, "HG", false ) != -1)
			Format(m_szServerTag, 32, "饥饿游戏");
		else if(StrContains(m_szServerName, "死斗", false ) != -1)
			Format(m_szServerTag, 32, "纯净死斗");
		else if(StrContains(m_szServerName, "纯净死亡", false ) != -1)
			Format(m_szServerTag, 32, "纯净死亡");
		else if(StrContains(m_szServerName, "Riot", false ) != -1)
			Format(m_szServerTag, 32, "僵尸暴动");
		else if(StrContains(m_szServerName, "Ninja", false ) != -1)
			Format(m_szServerTag, 32, "忍者行动");
		else if(StrContains(m_szServerName, "BHop", false ) != -1)
			Format(m_szServerTag, 32, "BHop连跳");
		else if(StrContains(m_szServerName, "满十", false ) != -1)
			Format(m_szServerTag, 32, "满十比赛");
		else
			Format(m_szServerTag, 32, "论坛");
		
		Format(finalMessage, sizeof(finalMessage), "[\x02小\x04喇\x0C叭\x01] [\x0E%s\x01]  \x04服务器消息\x01 :   \x07%s", m_szServerTag, message);

		PrintToChatAll(finalMessage);

		Format(finalMessage, sizeof(finalMessage), "%s%s", key, finalMessage);
		LogMessage("Send message: %s", finalMessage);
		SocketSend(globalClientSocket, finalMessage, sizeof(finalMessage));
	}

	return Plugin_Handled;
}


public Action CMD_SendMessage2(client, args)
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
	
	if(gagState[client] == PLAYER_GAGED)
	{
		Handle pack;
		char text[200];
		CreateDataTimer(0.5, PrintMessageOnChatMessage, pack);
		WritePackCell(pack, client);
		Format(text, sizeof(text), "%s You have been banned from using this command.", PLUGIN_TAG);
		WritePackString(pack, text);
	}
	else
	{
		Format(finalMessage, sizeof(finalMessage), "[\x02大\x04喇\x0C叭\x01]  \x04%N\x01 :   \x07%s", client, message);
		
		Store_SetClientCredits(client, Store_GetClientCredits(client)-5000, "发送大喇叭");
		PrintToChat(client, "\x01 \x04[Store]  \x01你花费\x045000Credits\x01发送了一条小喇叭");

		PrintToMenuAll(finalMessage);

		Format(finalMessage, sizeof(finalMessage), "%s%s", key, finalMessage);
		LogMessage("Send message: %s", finalMessage);
		SocketSend(globalClientSocket, finalMessage, sizeof(finalMessage));
	}

	return Plugin_Handled;
}


//I don't think commenting this block is needed.
public Action CMD_GagFromCrossServer(client, args)
{
	if(!IsValidClient(client))
		return Plugin_Handled;
		
	if(args != 1)
	{
		PrintToChat(client, "%s Usage : sm_cscgag [TARGET]", PLUGIN_TAG);
		return Plugin_Handled;
	}
		
	char arg1[20];
	char tmp[10];
	char cookieValue[10];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetClientCookie(client, COOKIE_ClientGaged, cookieValue, sizeof(cookieValue));
	gagState[client] = StringToInt(cookieValue);
	
	int target = FindTarget(client, arg1, true);
	
	if(gagState[target] == PLAYER_GAGED)
	{
		PrintToChat(client, "%s %N is now \x04ungaged\x01 !", PLUGIN_TAG, target);	
		gagState[target] = PLAYER_UNGAGED;
	}
	else if(gagState[target] == PLAYER_UNGAGED)
	{
		PrintToChat(client, "%s %N is now \x02gaged\x01 !", PLUGIN_TAG, target);	
		gagState[target] = PLAYER_GAGED;
	}
	
	IntToString(gagState[client], tmp, sizeof(tmp));
	SetClientCookie(client, COOKIE_ClientGaged, tmp);
		
	return Plugin_Continue;		
}
   
//In case a client get disconnected, reconnect him every X seconds
public Action TimerReconnect(Handle tmr, any arg)
{
	PrintToServer("Trying to reconnect to the master server...");
	ConnecToMasterServer();
}

//Allow you to print messages when OnChatMessage hook delayed by a timer
public Action PrintMessageOnChatMessage(Handle timer, Handle pack)
{
	char text[128];
	int client;
 
	ResetPack(pack);
	client = ReadPackCell(pack);
	ReadPackString(pack, text, sizeof(text));
	//Restoring pack has finished, go abive and print message.
 
	PrintToChat(client, "%s", text);
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
	globalClientSocket = SocketCreate(SOCKET_TCP, OnClientSocketError);
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
