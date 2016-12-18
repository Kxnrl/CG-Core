#include <cg_core>
#include <maoling>
#include <diamond>

Handle g_hDatabase;

int g_iDiamods[MAXPLAYERS+1];
bool g_bLoaded[MAXPLAYERS+1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("CG_GetClientDiamond", Native_GetClientDiamond);
	CreateNative("CG_SetClientDiamond", Native_SetClientDiamond);
	
	if(late)
		CG_OnServerLoaded();
	
	return APLRes_Success;
}

public int Native_GetClientDiamond(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(IsValidClient(client) && IsAllowClient(client) && g_bLoaded[client])
		return g_iDiamods[client];

	return -1;
}

public int Native_SetClientDiamond(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int counts = GetNativeCell(2);
	if(IsValidClient(client) && IsAllowClient(client) && g_bLoaded[client])
	{
		int diff = counts - g_iDiamods[client];
		char m_szAuth[32], m_szQuery[256];
		GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
		Format(m_szQuery, 256, "UPDATE `playertrack_diamonds` SET `diamonds` = `diamonds` + '%d' WHERE `playerid` = '%d' AND `dzid` = '%d' AND `steamid` = '%s'", diff, CG_GetPlayerID(client), CG_GetDiscuzUID(client), m_szAuth);
		SQL_TQuery(g_hDatabase, SQLCallback_SaveClient, m_szQuery, GetClientUserId(client));
		g_iDiamods[client] = counts;
		return 0;
	}
	return -1;
}

public void OnPluginStart()
{
	HookClientVIPChecked(OnClientVIPChecked);

	RegConsoleCmd("huodong", Command_Active);
	RegConsoleCmd("sm_hd", Command_Active);
}

public Action Command_Active(int client, int args)
{
	if(client && IsClientInGame(client))
		BuildMainMenu(client);
}

void BuildMainMenu(int client)
{
	if(CG_GetPlayerID(client) < 1)
	{
		PrintToChat(client, "[\x0E新年活动\x01]   未知错误,请联系管理员");
		return;
	}
	
	if(CG_GetDiscuzUID(client) < 1)
	{
		PrintToChat(client, "[\x0E新年活动\x01]   欲参加此活动请先注册论坛");
		return;
	}
	
	if(!g_bLoaded[client])
	{
		PrintToChat(client, "[\x0E新年活动\x01]   你的数据尚未加载完毕");
		return;
	}

	Handle menu = CreateMenu(MenuHandler_MainMenu);
	SetMenuTitleEx(menu, "[CG]  新年活动\n钻石: %d\n \n钻石可兑换:\nStore道具\nCSGO钥匙/皮肤\nCG专属道具", g_iDiamods[client]);

	AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "活动目前还没有开始");
	AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "开放时间请留意论坛");

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public int MenuHandler_MainMenu(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public void CG_OnServerLoaded()
{
	g_hDatabase = CG_GetGameDatabase();
	if(g_hDatabase == INVALID_HANDLE)
		CreateTimer(10.0, Timer_Reconnect);
}

public Action Timer_Reconnect(Handle tiemr)
{
	CG_OnServerLoaded();
}

public void OnClientConnected(int client)
{
	g_bLoaded[client] = false;
	g_iDiamods[client] = -1;
}

public int OnClientVIPChecked(int client)
{
	if(!IsValidClient(client) || !IsAllowClient(client))
		return;

	char m_szAuth[32], m_szQuery[256];
	GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
	Format(m_szQuery, 256, "SELECT `diamonds` FROM `playertrack_diamonds` WHERE `playerid` = '%d' AND `dzid` = '%d' AND `steamid` = '%s' ORDER BY `playerid` ASC LIMIT 1;", CG_GetPlayerID(client), CG_GetDiscuzUID(client), m_szAuth);
	SQL_TQuery(g_hDatabase, SQLCallback_LoadClient, m_szQuery, GetClientUserId(client));
}

public void SQLCallback_LoadClient(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!IsValidClient(client) || !IsAllowClient(client))
		return;
	
	if(hndl == INVALID_HANDLE) 
	{
		if(StrContains(error, "lost connection", false) == -1 && CG_GetPlayerID(client) > 0)
		{
			char m_szAuth[32], m_szQuery[256];
			GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
			Format(m_szQuery, 256, "SELECT `diamonds` FROM `playertrack_diamonds` WHERE `playerid` = '%d' AND `dzid` = '%d' AND `steamid` = '%s' ORDER BY `playerid` ASC LIMIT 1;", CG_GetPlayerID(client), CG_GetDiscuzUID(client), m_szAuth);
			SQL_TQuery(g_hDatabase, SQLCallback_LoadClient, m_szQuery, GetClientUserId(client));
		}

		return;
	}
	
	if(SQL_FetchRow(hndl))
	{
		g_iDiamods[client] = SQL_FetchInt(hndl, 0);
		g_bLoaded[client] = true;
	}
	else if(IsValidClient(client) && IsAllowClient(client))
	{
		char m_szAuth[32], m_szQuery[256];
		GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
		Format(m_szQuery, 128, "INSERT INTO `playertrack_diamonds` (`playerid`, `dzid`, `steamid`) VALUES ('%d', '%d', '%s');", CG_GetPlayerID(client), CG_GetDiscuzUID(client), m_szAuth);
		SQL_TQuery(g_hDatabase, SQLCallback_NewClient, m_szQuery, GetClientUserId(client));
	}
}

public void SQLCallback_NewClient(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!IsValidClient(client) || !IsAllowClient(client))
		return;

	if(hndl == INVALID_HANDLE)
	{
		if(StrContains(error, "lost connection"))
		{
			char m_szAuth[32], m_szQuery[256];
			GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
			Format(m_szQuery, 256, "SELECT `diamonds` FROM `playertrack_diamonds` WHERE `playerid` = '%d' AND `dzid` = '%d' AND `steamid` = '%s' ORDER BY `playerid` ASC LIMIT 1;", CG_GetPlayerID(client), CG_GetDiscuzUID(client), m_szAuth);
			SQL_TQuery(g_hDatabase, SQLCallback_LoadClient, m_szQuery, GetClientUserId(client));
		}
	}
	
	g_iDiamods[client] = 0;
}

public void SQLCallback_SaveClient(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!IsValidClient(client) || !IsAllowClient(client))
		return;
	
	if(hndl == INVALID_HANDLE)
	{
		LogError("SaveClient: %N  Error: %s", client, error);
	}
}

stock bool IsAllowClient(int client)
{
	if(CG_GetPlayerID(client) < 1)
		return false;
	
	if(CG_GetDiscuzUID(client) < 1)
		return false;
	
	return true;
}