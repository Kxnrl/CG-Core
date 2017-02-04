public int Native_GetServerID(Handle plugin, int numParams)
{
	return g_iServerId;
}

public int Native_GetOnlines(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iOnline];
}

public int Native_GetVitality(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iVitality];
}

public int Native_GetLastseen(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iLastseen];
}

public int Native_GetPlayerID(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iPlayerId];
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
	if(!g_eClient[GetNativeCell(1)][iVipType])
		return false;
	else
		return true;
}

public int Native_SetClientVIP(Handle plugin, int numParams)
{
	SetClientVIP(GetNativeCell(1), 1);
}

public int Native_GetVipType(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iVipType];
}

public int Native_HookOnClientVipChecked(Handle plugin, int numParams)
{
	AddToForward(g_Forward[ClientVipChecked], plugin, GetNativeCell(1));
}

public int Native_SaveDatabase(Handle plugin, int numParams)
{
	if(g_eHandle[DB_Game] != INVALID_HANDLE)
	{
		char m_szQuery[512];
		if(GetNativeString(1, m_szQuery, 512) == SP_ERROR_NONE)
		{
			Handle data = CreateDataPack();
			WritePackString(data, m_szQuery);
			WritePackCell(data, 0);
			ResetPack(data);
			MySQL_Query(g_eHandle[DB_Game], SQLCallback_SaveDatabase, m_szQuery, data);
		}
	}
}

public int Native_SaveForumData(Handle plugin, int numParams)
{
	if(g_eHandle[DB_Discuz] != INVALID_HANDLE)
	{
		char m_szQuery[512];
		if(GetNativeString(1, m_szQuery, 512) == SP_ERROR_NONE)
		{
			Handle data = CreateDataPack();
			WritePackString(data, m_szQuery);
			WritePackCell(data, 1);
			ResetPack(data);
			MySQL_Query(g_eHandle[DB_Discuz], SQLCallback_SaveDatabase, m_szQuery, data);
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

public int Native_GetCPPartner(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iCPId];
}

public int Native_GetCPDate(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iCPDate];
}

public int Native_GetGameDatabase(Handle plugin, int numParams)
{
	return view_as<int>(g_eHandle[DB_Game]);
}

public int Native_GetDiscuzDatabase(Handle plugin, int numParams)
{
	return view_as<int>(g_eHandle[DB_Discuz]);
}

public int Native_ShowNormalMotd(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	QueryClientConVar(client, "cl_disablehtmlmotd", view_as<ConVarQueryFinished>(OnGetClientCVAR), client);
	int width = GetNativeCell(2)-12;
	int height = GetNativeCell(3)-80;
	char m_szUrl[192];
	if(GetNativeString(4, m_szUrl, 192) == SP_ERROR_NONE)
	{
		PrepareUrl(width, height, m_szUrl);
		ShowMOTDPanel(client, "CSGOGAMERS Motd", m_szUrl, MOTDPANEL_TYPE_URL);
		return true;
	}
	else
	{
		ShowHiddenMOTDPanel(client, "about:blank", MOTDPANEL_TYPE_URL);
		return false;
	}
}

public int Native_ShowHiddenMotd(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	QueryClientConVar(client, "cl_disablehtmlmotd", view_as<ConVarQueryFinished>(OnGetClientCVAR), client);

	char m_szUrl[192];
	if(GetNativeString(2, m_szUrl, 192) != SP_ERROR_NONE)
		return false;

	ShowHiddenMOTDPanel(client, m_szUrl, MOTDPANEL_TYPE_URL);

	return true;
}

public int Native_RemoveMotd(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	QueryClientConVar(client, "cl_disablehtmlmotd", view_as<ConVarQueryFinished>(OnGetClientCVAR), client);
	ShowHiddenMOTDPanel(client, "about:blank", MOTDPANEL_TYPE_URL);
	return true;
}

void OnServerLoadSuccess()
{
	//建立临时储存文件
	BuildTempLogFile();

	//Call Forward
	Call_StartForward(g_Forward[ServerLoaded]);
	Call_Finish();
}

void OnClientSignSucessed(int client)
{
	//Call Forward
	Call_StartForward(g_Forward[ClientSigned]);
	Call_PushCell(client);
	Call_Finish();
}

void OnClientDataLoaded(int client)
{
	//输出控制台数据
	PrintConsoleInfo(client);
	
	if(g_eClient[client][iGroupId] == 9999 || g_eClient[client][iPlayerId] == 1 || g_eClient[client][iUID] == 1)
	{
		char m_szAuth[32];
		GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32);
		
		if(!StrEqual(m_szAuth, "STEAM_1:1:44083262"))
		{
			LogToFileEx(g_szLogFile, "Client: name[%s] auth[%s] AuthId Error", client, m_szAuth);
			KickClient(client, "Steam AuthId Error!");
			return;
		}
	}

	//Call Forward
	Call_StartForward(g_Forward[ClientLoaded]);
	Call_PushCell(client);
	Call_Finish();
}

void OnClientVipChecked(int client)
{
	//Check Flags
	GetClientFlags(client);
	
	if(g_eClient[client][iGroupId] == 9999 || g_eClient[client][iPlayerId] == 1 || g_eClient[client][iUID] == 1)
	{
		char m_szAuth[32];
		GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32);
		
		if(!StrEqual(m_szAuth, "STEAM_1:1:44083262"))
		{
			LogToFileEx(g_szLogFile, "Client: name[%s] auth[%s] AuthId Error", client, m_szAuth);
			KickClient(client, "Steam AuthId Error!");
			return;
		}
	}

	//Call Forward
	Call_StartForward(g_Forward[ClientVipChecked]);
	Call_PushCell(client);
	Call_Finish();
}

bool OnAPIStoreSetCredits(int client, int credits, const char[] reason, bool immed)
{
	bool result;

	//Call Forward
	Call_StartForward(g_Forward[APISetCredits]);
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
	Call_StartForward(g_Forward[APIGetCredits]);
	Call_PushCell(client);
	Call_Finish(result);

	return result;
}

bool OnCheckAuthTerm(int client, int AuthId) 
{
	bool result;
	
	//Call Forward
	Call_StartForward(g_Forward[ClientAuthTerm]);
	Call_PushCell(client);
	Call_PushCell(AuthId);
	Call_Finish(result);

	return result;
}

void OnNewDayForward(int iDate)
{
	g_iNowDate = iDate;
	LogMessage("CG Server: On New Date %d", g_iNowDate);

	//Call Forward
	Call_StartForward(g_Forward[OnNewDay]);
	Call_PushCell(g_iNowDate);
	Call_Finish();
}