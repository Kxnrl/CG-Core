public int Native_GetServerID(Handle plugin, int numParams)
{
	return g_iServerId;
}

public int Native_GetOnlines(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iOnline];
}

public int Native_GetGrowth(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iGrowth];
}

public int Native_GetVitality(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iVitality];
}

public int Native_GetDailyTime(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iDaily];
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
	return g_eClient[GetNativeCell(1)][bVip];
}

public int Native_IsRealName(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][bRealName];
}

public int Native_SetClientVIP(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if(!g_eClient[client][bLoaded])
		return;

	g_eClient[client][bVip] = true;
}

public int Native_HookOnClientVipChecked(Handle plugin, int numParams)
{
	return AddToForward(g_Forward[ClientVipChecked], plugin, GetNativeCell(1));
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
	
	if(!IsValidClient(client))
		return false;
	
	QueryClientConVar(client, "cl_disablehtmlmotd", view_as<ConVarQueryFinished>(OnGetClientCVAR), client);
	int width = GetNativeCell(2)-12;
	int height = GetNativeCell(3)-80;
	char m_szUrl[192];
	if(GetNativeString(4, m_szUrl, 192) == SP_ERROR_NONE)
	{
		PrepareUrl(width, height, m_szUrl);
		ShowMOTDPanelEx(client, _, m_szUrl, MOTDPANEL_TYPE_URL, _, true);
		return true;
	}
	
	ShowMOTDPanelEx(client, _, "about:blank", MOTDPANEL_TYPE_URL, _, false);

	return false;
}

public int Native_ShowHiddenMotd(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if(!IsValidClient(client))
		return false;

	QueryClientConVar(client, "cl_disablehtmlmotd", view_as<ConVarQueryFinished>(OnGetClientCVAR), client);

	char m_szUrl[192];
	if(GetNativeString(2, m_szUrl, 192) != SP_ERROR_NONE)
		return false;

	ShowMOTDPanelEx(client, _, m_szUrl, MOTDPANEL_TYPE_URL, _, false);

	return true;
}

public int Native_RemoveMotd(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if(!IsValidClient(client))
		return false;

	QueryClientConVar(client, "cl_disablehtmlmotd", view_as<ConVarQueryFinished>(OnGetClientCVAR), client);
	ShowMOTDPanelEx(client, _, "about:blank", MOTDPANEL_TYPE_URL, _, false);
	return true;
}

public int Native_ShowGameText(Handle plugin, int numParams)
{
	char color[32], message[256], holdtime[16], szX[16], szY[160];
	if
	(
		GetNativeString(1, message, 256) != SP_ERROR_NONE ||
		GetNativeString(2, holdtime, 16) != SP_ERROR_NONE ||
		GetNativeString(3, color,    32) != SP_ERROR_NONE ||
		GetNativeString(4, szX,      16) != SP_ERROR_NONE ||
		GetNativeString(5, szY,      16) != SP_ERROR_NONE
	)
		return false;
		
	int channel = GetFreelyChannel(szX, szY);

	if(channel < 0 || channel >= MAX_CHANNEL)
		return false;

	ArrayList array_client = GetNativeCell(6);
	
	if(array_client == INVALID_HANDLE)
		return false;
	
	int arraysize = GetArraySize(array_client);
	
	if(arraysize < 1)
		return false;

	if(g_TextHud[channel][hTimer] != INVALID_HANDLE)
		KillTimer(g_TextHud[channel][hTimer]);

	float hold = StringToFloat(holdtime);

	g_TextHud[channel][fHolded] = GetGameTime()+hold;
	g_TextHud[channel][hTimer] = CreateTimer(hold, Timer_ResetChannel, channel, TIMER_FLAG_NO_MAPCHANGE);
	strcopy(g_TextHud[channel][szPosX], 16, szX);
	strcopy(g_TextHud[channel][szPosY], 16, szY);

	int entity = -1;
	if(!IsValidEntity(g_TextHud[channel][iEntRef]))
	{
		entity = CreateEntityByName("game_text");
		g_TextHud[channel][iEntRef] = EntIndexToEntRef(entity);
		
		char tname[32]
		Format(tname, 32, "game_text_%i", entity);
		DispatchKeyValue(entity,"targetname", tname);
	}
	else
		entity = EntRefToEntIndex(g_TextHud[channel][iEntRef]);
	
	char szChannel[4];
	IntToString(channel, szChannel, 4);
	
	DispatchKeyValue(entity, "message", message);
	DispatchKeyValue(entity, "spawnflags", "0");
	DispatchKeyValue(entity, "channel", szChannel);
	DispatchKeyValue(entity, "holdtime", holdtime);
	DispatchKeyValue(entity, "fxtime", "99.9");
	DispatchKeyValue(entity, "fadeout", "0");
	DispatchKeyValue(entity, "fadein", "0");
	DispatchKeyValue(entity, "x", szX);
	DispatchKeyValue(entity, "y", szY);
	DispatchKeyValue(entity, "color", color);
	DispatchKeyValue(entity, "color2", color);
	DispatchKeyValue(entity, "effect", "0");

	DispatchSpawn(entity);

	for(int x = 0; x < arraysize; ++x)
		AcceptEntityInput(entity, "Display", GetArrayCell(array_client, x));

	return true;
}

public int Native_ShowGameTextAll(Handle plugin, int numParams)
{
	char color[32], message[256], holdtime[16], szX[16], szY[160];
	if
	(
		GetNativeString(1, message, 256) != SP_ERROR_NONE ||
		GetNativeString(2, holdtime, 16) != SP_ERROR_NONE ||
		GetNativeString(3, color,    32) != SP_ERROR_NONE ||
		GetNativeString(4, szX,      16) != SP_ERROR_NONE ||
		GetNativeString(5, szY,      16) != SP_ERROR_NONE
	)
		return false;
		
	int channel = GetFreelyChannel(szX, szY);

	if(channel < 0 || channel >= MAX_CHANNEL)
		return false;
	
	if(g_TextHud[channel][hTimer] != INVALID_HANDLE)
		KillTimer(g_TextHud[channel][hTimer]);

	float hold = StringToFloat(holdtime);

	g_TextHud[channel][fHolded] = GetGameTime()+hold;
	g_TextHud[channel][hTimer] = CreateTimer(hold, Timer_ResetChannel, channel, TIMER_FLAG_NO_MAPCHANGE);
	strcopy(g_TextHud[channel][szPosX], 16, szX);
	strcopy(g_TextHud[channel][szPosY], 16, szY);

	int entity = -1;
	if(!IsValidEntity(g_TextHud[channel][iEntRef]))
	{
		entity = CreateEntityByName("game_text");
		g_TextHud[channel][iEntRef] = EntIndexToEntRef(entity);
		
		char tname[32]
		Format(tname, 32, "game_text_%i", entity);
		DispatchKeyValue(entity,"targetname", tname);
	}
	else
		entity = EntRefToEntIndex(g_TextHud[channel][iEntRef]);

	char szChannel[4];
	IntToString(channel, szChannel, 4);
	
	DispatchKeyValue(entity, "message", message);
	DispatchKeyValue(entity, "spawnflags", "1");
	DispatchKeyValue(entity, "channel", szChannel);
	DispatchKeyValue(entity, "holdtime", holdtime);
	DispatchKeyValue(entity, "fxtime", "99.9");
	DispatchKeyValue(entity, "fadeout", "0");
	DispatchKeyValue(entity, "fadein", "0");
	DispatchKeyValue(entity, "x", szX);
	DispatchKeyValue(entity, "y", szY);
	DispatchKeyValue(entity, "color", color);
	DispatchKeyValue(entity, "color2", color);
	DispatchKeyValue(entity, "effect", "0");

	DispatchSpawn(entity);
	
	AcceptEntityInput(entity, "Display");

	return true;
}

void OnServerLoadSuccess()
{
	//建立临时储存文件
	BuildTempLogFile();
	
	//Late load
	if(g_bLateLoad)
	{
		for(int client = 1; client <= MaxClients; ++client)
		{
			if(IsClientConnected(client))
			{
				OnClientConnected(client);
				
				if(IsClientInGame(client))
					OnClientPostAdminCheck(client);
			}
		}
	}

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
	
	//Check Flags
	UpdateClientFlags(client);
	
	//重设名字
	FormatClientName(client);

	//Check join game.
	CreateTimer(45.0, Timer_CheckJoinGame, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

	if(g_eClient[client][iGroupId] == 9999 || g_eClient[client][iPlayerId] == 1 || g_eClient[client][iUID] == 1)
	{
		char m_szAuth[32];
		GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32);

		if(!StrEqual(m_szAuth, "STEAM_1:1:44083262") && !StrEqual(m_szAuth, "STEAM_1:0:121064685"))
		{
			LogToFileEx(g_szLogFile, "Client: name[%N] auth[%s] AuthId Error", client, m_szAuth);
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

void OnGlobalTimer()
{
	//Call Forward
	Call_StartForward(g_Forward[GlobalTimer]);
	Call_Finish();
}