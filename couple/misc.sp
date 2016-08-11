BuildLogFilePath()
{
	new String:sLogPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sLogPath, sizeof(sLogPath), "logs/CP");

	if ( !DirExists(sLogPath) )
	{
		CreateDirectory(sLogPath, 511);
	}

	decl String:cTime[64];
	FormatTime(cTime, sizeof(cTime), "logs/CP/%Y%m%d.log");

	new String:sLogFile[PLATFORM_MAX_PATH];
	sLogFile = LogFile;

	BuildPath(Path_SM, LogFile, sizeof(LogFile), cTime);
}

public Action:PA_OnClientLoaded(int client)
{
	g_iPAID[client] = PA_GetGroupID(client);
	if(g_iPAID[client] > 0 && g_iPAID[client] != 9000 && g_iPAID[client] != 9001) g_bIsPA[client] = true;
}

public Action:PlayFireworkSound(Handle:Timer)
{
	EmitSoundToAllAny(FIREWORK_SOUND_1);
	CreateTimer(2.0, PlayFirewordSound2, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:PlayFirewordSound2(Handle:Timer)
{
	EmitSoundToAllAny(FIREWORK_SOUND_2);
	CreateTimer(6.0, PlayFirewordSound3, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:PlayFirewordSound3(Handle:Timer)
{
	EmitSoundToAllAny(FIREWORK_SOUND_3);
	CreateTimer(5.0, PlayFirewordSound4, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:PlayFirewordSound4(Handle:Timer)
{
	EmitSoundToAllAny(FIREWORK_SOUND_4);
	CreateTimer(5.0, PlayFirewordSound0, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:PlayFirewordSound0(Handle:Timer)
{
	EmitSoundToAllAny(FIREWORK_SOUND_1);
	EmitSoundToAllAny(FIREWORK_SOUND_2);
}

public Action:Cmd_GiveScore(int client, int args)
{
	char STEAMID[64];
	GetClientAuthId(client, AuthId_Steam2, STEAMID, 64);
	
	new partner = marriage_slots[client];
	
	if(!StrEqual(STEAMID, "STEAM_1:1:44083262"))
		return Plugin_Handled;
	
	if(args > 1)
		return Plugin_Handled;

	if(args < 1)
	{
		marriage_scores[client] = 5201314;
		PrintToChat(client, "[\x0ECP系统\x01]  \x05你获得了5201314 Score");
		if(partner > -1)
		{
			marriage_scores[partner] = 5201314;
			PrintToChat(partner, "[\x0ECP系统\x01]  \x05你获得了5201314 Score");
		}
	}
	if(args == 1)
	{
		decl String:buffer[12];
		GetCmdArg(1, buffer, sizeof(buffer));
		new iScore = StringToInt(buffer);
		marriage_scores[client] += iScore;
		PrintToChat(client, "[\x0ECP系统\x01]  \x05你获得了%d Score", iScore);
		if(partner > -1)
		{
			if(marriage_scores[client] >= marriage_scores[partner])
				marriage_scores[partner] = marriage_scores[client];
			else
				marriage_scores[client] = marriage_scores[partner];
			PrintToChat(partner, "[\x0ECP系统\x01]  \x05同步CP数据成功");
		}
	}
	return Plugin_Handled;
}

public Action:Timer_AddScoreTimer(Handle:timer, any:userid)
{
	for(new client = 1; client <= MaxClients; ++client)
	{
		if(IsClientInGame(client) && !IsFakeClient(client))
		{
			if(GetClientTeam(client) > 1)
			{
				new partner = marriage_slots[client];
				if(partner != -2)
				{
					if(partner > 0)
					{
						if(IsClientInGame(partner))
						{
							if(GetClientTeam(partner) > 1)
							{
								if(GetClientTeam(client) == GetClientTeam(partner))
								{
									marriage_scores[client] += 10;
								}
								if(marriage_scores[client] >= marriage_scores[partner])
									marriage_scores[partner] = marriage_scores[client];
								else
									marriage_scores[client] = marriage_scores[partner];
							}
						}
						else
						{
							marriage_scores[client] += 3;
						}
					}
					else
					{
						marriage_scores[client] += 3;
					}
				}
			}
		}
	}

	g_hTimer = CreateTimer(30.0, Timer_AddScoreTimer);
	return Plugin_Continue;
}