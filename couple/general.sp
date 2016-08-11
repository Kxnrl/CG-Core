/**
 * Fills the !marry menu with unmarried clients.
 *
 * @param marry_menu			Handle to the menu.
 * @param client				The slot number of the caller.
 * @return						Number of clients added to the menu.
 */ 
addTargets(Handle:marry_menu, client)
{
	new hits = 0;
	decl String:single_id[MAX_ID_LENGTH];
	decl String:single_name[MAX_NAME_LENGTH];
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(client != i)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) && !IsClientReplay(i))
			{
				if(marriage_slots[i] == -2 && GetClientAuthId(i, AuthId_Steam2, single_id, sizeof(single_id))
				&& GetClientName(i, single_name, sizeof(single_name)))
				{					
					AddMenuItem(marry_menu, single_id, single_name);
					hits++;
				}
			}			
		}
	}
	return hits;
}


/**
 * Checks for existing proposals and marriages for all connected clients.
 */ 
checkClients()
{
	decl String:client_id[MAX_ID_LENGTH];
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && !IsClientReplay(i) && !proposal_beingChecked[i] && !marriage_beingChecked[i] 
		&& GetClientAuthId(i, AuthId_Steam2, client_id, sizeof(client_id)))
		{
			proposal_beingChecked[i] = true;
			marriage_beingChecked[i] = true;
			checkProposal(client_id);
			checkMarriage(client_id);
		}
	}
}


/**
 * Computes the time a marriage has lasted.
 *
 * @param timestamp				Time of the wedding.
 * @param &time_spent			Destination cell to store the computed time.
 * @param &format				Destination cell to store the format of the computed time. 0 : days, 1 : months, 2 : years.
 * @noreturn					
 */ 
computeTimeSpent(timestamp, &time_spent, &format)
{
	new now;
	new days;
	
	now = GetTime();
	days = (now - timestamp) / 86400;
	if(days < 30)
	{
		time_spent = days;
		format = 0;
	}
	else if(days < 365)
	{
		time_spent = days / 30;
		format = 1;
	}
	else
	{
		time_spent = days / 365;
		format = 2;
	}
}


/**
 * Finds the slot number of a client.
 *
 * @param client_id				The steam ID of a client.
 * @return						The slot number if the client is connected, -1 otherwise.					
 */
getClientBySteamID(String:client_id[])
{
	new client = -1;
	decl String:temp_id[MAX_ID_LENGTH];
		
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && !IsFakeClient(i) && !IsClientReplay(i) && GetClientAuthId(i, AuthId_Steam2, temp_id, sizeof(temp_id))) {			
			if(StrEqual(client_id, temp_id))
			{
				client = i;
				break;
			}			
		}
	}
	return client;
}


/**
 * Stores a client who successfully used a command.
 *
 * @param client_id				The steam ID of a client.
 * @noreturn					
 */
cacheUsage(String:client_id[])
{
	new Float:delay;
	new Handle:data = CreateDataPack();
	
	delay = GetConVarFloat(cvar_delay) * 60;
	if(delay > 0)
	{
		PushArrayString(usage_cache, client_id);
		WritePackString(data, client_id);
		ResetPack(data, false);
		CreateTimer(delay, Uncache, data);
	}
}


/**
 * Checks if a client is allowed to use a command.
 *
 * @param client_id				The steam ID of a client.
 * @return						True if the client is allowed to, false otherwise.					
 */
checkUsage(String:client_id[])
{
	new allowed = true;
	new entries = GetArraySize(usage_cache);
	decl String:client_id_stored[MAX_ID_LENGTH];
	
	for(new i = 0; i < entries; i++)
	{
		GetArrayString(usage_cache, i, client_id_stored, sizeof(client_id_stored));
		if(StrEqual(client_id, client_id_stored))
		{
			allowed = false;
			break;
		}
	}
	return allowed;
}


/**
 * Selects and initiates a database connection.
 *
 * @noreturn			
 */
initDatabase()
{
	if (weddings_db != INVALID_HANDLE) return;
	new database;
	
	database = GetConVarInt(cvar_database);
	switch(database)
	{
		case 0 :
		{
			SQL_TConnect(DB_Connect, "storage-local");
		}
		case 1 :
		{
			if(SQL_CheckConfig("csgo"))
			{
				SQL_TConnect(DB_Connect, "csgo");
			}
			else
			{
				LogError("Unable to find \"weddings\" entry in \"sourcemod\\configs\\databases.cfg\".");
			}
		}
	}
}


/**
 * Creates the cp_proposals and cp_marriages tables.
 *
 * @noreturn			
 */
createTables()
{
	if(weddings_db == INVALID_HANDLE)
	{
		LogError("链接到数据库失败.");
	}
	else 
	{
		SQL_TQuery(weddings_db, DB_Create, sql_createProposals);
		SQL_TQuery(weddings_db, DB_Create, sql_createMarriages);
	}
}


/**
 * Deletes all data from the cp_proposals and cp_marriages tables.
 *
 * @param client				Slot number of the caller.
 * @noreturn			
 */
resetTables(client)
{
	if(weddings_db == INVALID_HANDLE)
	{
		LogError("链接到数据库失败.");
	}
	else
	{
		new Handle:data_proposals = CreateDataPack();
		new Handle:data_marriages = CreateDataPack();
		WritePackCell(data_proposals, 0);
		WritePackCell(data_proposals, client);
		ResetPack(data_proposals, false);
		WritePackCell(data_marriages, 1);
		WritePackCell(data_marriages, client);
		ResetPack(data_marriages, false);
		SQL_TQuery(weddings_db, DB_Reset, sql_resetProposals, data_proposals);
		SQL_TQuery(weddings_db, DB_Reset, sql_resetMarriages, data_marriages);
	}
}


// Callback for initDatabase.
public DB_Connect(Handle:owner, Handle:handle, const String:error[], any:data)
{
	if(handle == INVALID_HANDLE)
	{
		LogError("Unable to initiate database connection. (%s)", error);
	}
	else
	{
		weddings_db = handle;
		SQL_SetCharset(weddings_db, "utf8");
		createTables();
	}
}


// Callback for createTables.
public DB_Create(Handle:owner, Handle:handle, const String:error[], any:data) {
	if(handle == INVALID_HANDLE)
	{
		LogError("Error creating tables in database. (%s)", error);
	}
	else
	{
		checkClients();
	}
}


// Callback for resetTables.
public DB_Reset(Handle:owner, Handle:handle, const String:error[], any:data) {
	if(handle == INVALID_HANDLE)
	{
		LogError("Error resetting tables in database. (%s)", error);
	} else
	{
		new type = ReadPackCell(data);
		new client = ReadPackCell(data);
		CloseHandle(data);
		if(IsClientInGame(client))
		{
			switch(type)
			{
				case 0 :
				{
					PrintToChat(client, "[\x0ECP系统\x01]  数据表cp_proposals已经被清除.");
				}
				case 1 :
				{
					PrintToChat(client, "[\x0ECP系统\x01]  数据表cp_marriages已经被清除.");
				}
			}
		}
	}
}


/**
 * Calls the OnProposal forward.
 *
 * @param proposer			The slot number of the proposer. 
 * @param target			The slot number of the target.
 * @noreturn 					 
 */
forwardProposal(proposer, target)
{
	Call_StartForward(forward_proposal);
	Call_PushCell(proposer);
	Call_PushCell(target);
	Call_Finish();
}


/**
 * Calls the OnWedding forward.
 *
 * @param proposer			The slot number of the proposer. 
 * @param accepter			The slot number of the accepter.
 * @noreturn 					 
 */
forwardWedding(proposer, accepter)
{
	Call_StartForward(forward_wedding);
	Call_PushCell(proposer);
	Call_PushCell(accepter);
	Call_Finish();
}


/**
 * Calls the OnDivorce forward.
 *
 * @param divorcer			The slot number of the divorcer.
 * @param partner			The slot number of the partner, -1 if the partner is not connected.
 * @noreturn 					 
 */
forwardDivorce(divorcer, partner)
{
	Call_StartForward(forward_divorce);
	Call_PushCell(divorcer);
	Call_PushCell(partner);
	Call_Finish();
}