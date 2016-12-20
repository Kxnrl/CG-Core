#include <cg_core>
#include <maoling>
#include <diamond>

#define PREFIX "[\x10新年快乐\x01]  "

Handle g_hDatabase;

int g_iDiamonds[MAXPLAYERS+1];
bool g_bLoaded[MAXPLAYERS+1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("CG_GetClientDiamond", Native_GetClientDiamond);
	CreateNative("CG_SetClientDiamond", Native_SetClientDiamond);

	return APLRes_Success;
}

public int Native_GetClientDiamond(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(IsValidClient(client) && IsAllowClient(client) && g_bLoaded[client])
		return g_iDiamonds[client];

	return -1;
}

public int Native_SetClientDiamond(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int counts = GetNativeCell(2);
	if(IsValidClient(client) && IsAllowClient(client) && g_bLoaded[client])
	{
		if(counts > 255) counts = 255;
		int diff = counts - g_iDiamonds[client];
		if(diff != 0)
		{
			g_iDiamonds[client] = counts;
			char m_szAuth[32], m_szQuery[256];
			GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
			Format(m_szQuery, 256, "UPDATE `playertrack_diamonds` SET `diamonds` = `diamonds` + '%d' WHERE `playerid` = '%d' AND `dzid` = '%d' AND `steamid` = '%s'", diff, CG_GetPlayerID(client), CG_GetDiscuzUID(client), m_szAuth);
			SQL_TQuery(g_hDatabase, SQLCallback_SaveClient, m_szQuery, GetClientUserId(client));
			PrintToChat(client, "%s  \x04你%s了\x10 %d钻石 \x04当前剩余\x01: \x10 %d钻石", PREFIX, (diff >= 0) ? "获得" : "失去", diff, g_iDiamonds[client]);
			return true;
		}
		return false;
	}
	return false;
}

public void OnPluginStart()
{
	HookClientVIPChecked(OnClientVIPChecked);
	
	RegAdminCmd("hdtest", CMDTEST, ADMFLAG_ROOT);

	RegConsoleCmd("huodong", Command_Active);
	RegConsoleCmd("sm_hd", Command_Active);
}

public void OnMapStart()
{
	CG_OnServerLoaded();
}

public Action CMDTEST(int client, int args)
{
	CG_SetClientDiamond(client, CG_GetClientDiamond(client) + 1);
	CG_SetClientDiamond(client, CG_GetClientDiamond(client) + 10);
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
	SetMenuTitleEx(menu, "[CG]  新年活动\n钻石: %d\n \n钻石可兑换:\nStore道具\nCSGO钥匙/皮肤\nCG专属道具", g_iDiamonds[client]);

	AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "活动目前尚未正式开始");
	AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "开放时间敬请留意论坛");

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

public void OnClientPutInServer(int client)
{
	g_bLoaded[client] = false;
	g_iDiamonds[client] = -1;
}

void LoadClient(int client)
{
	char m_szAuth[32], m_szQuery[256];
	GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
	Format(m_szQuery, 256, "SELECT `diamonds` FROM `playertrack_diamonds` WHERE `playerid` = '%d' AND `dzid` = '%d' AND `steamid` = '%s' ORDER BY `playerid` ASC LIMIT 1;", CG_GetPlayerID(client), CG_GetDiscuzUID(client), m_szAuth);
	SQL_TQuery(g_hDatabase, SQLCallback_LoadClient, m_szQuery, GetClientUserId(client));
}

public int OnClientVIPChecked(int client)
{
	if(!IsValidClient(client) || !IsAllowClient(client))
		return;

	LoadClient(client);
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
			LoadClient(client);
		}

		return;
	}
	
	if(SQL_FetchRow(hndl))
	{
		g_iDiamonds[client] = SQL_FetchInt(hndl, 0);
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
			LoadClient(client);
		}
		return;
	}
	
	g_bLoaded[client] = true;
	g_iDiamonds[client] = 0;
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