public Action:Uncache(Handle:timer, Handle:data)
{
	new entries = GetArraySize(usage_cache);
	decl String:client_id[MAX_ID_LENGTH];
	decl String:client_id_stored[MAX_ID_LENGTH];
	
	ReadPackString(data, client_id, sizeof(client_id));
	CloseHandle(data);
	for(new i = 0; i < entries; i++)
	{
		GetArrayString(usage_cache, i, client_id_stored, sizeof(client_id_stored));
		if(StrEqual(client_id, client_id_stored))
		{
			RemoveFromArray(usage_cache, i);
			break;
		}
	}
	return Plugin_Handled;
}

public Action:Marry(client, args)
{		
	decl String:client_id[MAX_ID_LENGTH];
	
	if(GetClientAuthId(client, AuthId_Steam2, client_id, sizeof(client_id)))
	{
		if(proposal_checked[client] && marriage_checked[client])
		{		
			if(checkUsage(client_id))
			{
				if(marriage_slots[client] == -2)
				{
					if(proposal_slots[client] == -2)
					{
						new Handle:marry_menu = CreateMenu(MarryMenuHandler, MENU_ACTIONS_DEFAULT);
						SetMenuTitle(marry_menu, "结为CP的玩家:");
						if(addTargets(marry_menu, client) > 0)
						{
							if(Store_GetClientCredits(client) >= 520)
							{
								Store_SetClientCredits(client, Store_GetClientCredits(client) - 520, "CP-求婚");
								PrintToChat(client, "[\x0ECP系统\x01]  你发起CP请求,花费了520Credits");
								DisplayMenu(marry_menu, client, MAX_MENU_DISPLAY_TIME);
							}
							else
							{
								PrintToChat(client, "[\x0ECP系统\x01]  你没钱了,怎么求婚?");
							}
						}
						else
						{
							PrintToChat(client, "[\x0ECP系统\x01]  当前没有未配对CP的玩家.已进入全民CP时代");
						}
					}
					else
					{
						PrintToChat(client, "[\x0ECP系统\x01]  你已经发出和\x0E%s\x01组CP的请求了!", proposal_names[client]);
						//PrintToChat(client,  "[\x0ECP系统\x01]  现在你可以按Y输入\x04!cp_revoke\x01来撤销C(gao)P(ji)请求.");
					}					
				}
				else
				{
					PrintToChat(client, "[\x0ECP系统\x01]  你已经和\x0E%s\x01结成CP关系了!", marriage_names[client]);
					//PrintToChat(client, "[\x0ECP系统\x01]  按Y输入!cp_divorce与你的CP解除关系");
				}
			}
			else
			{
				PrintToChat(client, "[\x0ECP系统\x01]  请尊总彼此的CP对象,切忌滥用CP命令!");
				PrintToChat(client, "[\x0ECP系统\x01]  该操作延迟 %.2f 分钟.", GetConVarFloat(cvar_delay));
			}			
		}
		else
		{
			PrintToChat(client, "[\x0ECP系统\x01]  正在读取你的CP信息,请稍后再试.");
		}
	}
	return Plugin_Handled;
}

public Action:Revoke(client, args)
{
	decl String:client_id[MAX_ID_LENGTH];
	
	if(GetClientAuthId(client, AuthId_Steam2, client_id, sizeof(client_id)))
	{
		if(proposal_checked[client] && marriage_checked[client])
		{
			if(checkUsage(client_id)) {		
				if(marriage_slots[client] == -2)
				{
					if(proposal_slots[client] == -2)
					{
						PrintToChat(client, "[\x0ECP系统\x01]  请选择你要CP的对象.");	
					} 
					else
					{
						revokeProposal(client_id);
						cacheUsage(client_id);						
						PrintToChat(client, "[\x0ECP系统\x01]  你已经撤销了给 \x04%s \x01的CP请求!", proposal_names[client]);
						proposal_slots[client] = -2;
						proposal_names[client] = "";
						proposal_ids[client] = "";
					}
				}
				else
				{
					PrintToChat(client, "[\x0ECP系统\x01]  你已经和\x0E%s\x01结成CP关系了!", marriage_names[client]);
					//PrintToChat(client, "[\x0ECP系统\x01]  按Y输入!cp_divorce与你的CP解除关系");
				}
			}
			else
			{
				PrintToChat(client, "[\x0ECP系统\x01]  请尊总彼此的CP对象,切忌滥用CP命令!");
				PrintToChat(client, "[\x0ECP系统\x01]  该操作延迟 %.2f 分钟.", GetConVarFloat(cvar_delay));
			}
		}
		else
		{
			PrintToChat(client, "[\x0ECP系统\x01]  正在读取你的CP信息,请稍后再试.");
		}
	}
	return Plugin_Handled;
}

public Action:Proposals(client, args)
{
	decl String:client_id[MAX_ID_LENGTH];
	
	if(GetClientAuthId(client, AuthId_Steam2, client_id, sizeof(client_id)))
	{
		if(proposal_checked[client] && marriage_checked[client])
		{
			if(checkUsage(client_id))
			{
				if(marriage_slots[client] == -2)
				{
					findProposals(client_id);
				}
				else
				{
					PrintToChat(client, "[\x0ECP系统\x01]  你已经和\x0E%s\x01结成CP关系了!", marriage_names[client]);
					//PrintToChat(client, "[\x0ECP系统\x01]  按Y输入!cp_divorce与你的CP解除关系");
				}		
			}
			else
			{
				PrintToChat(client, "[\x0ECP系统\x01]  请尊总彼此的CP对象,切忌滥用CP命令!");
				PrintToChat(client, "[\x0ECP系统\x01]  该操作延迟 %.2f 分钟.", GetConVarFloat(cvar_delay));
			}
		}
		else
		{
			PrintToChat(client, "[\x0ECP系统\x01]  正在读取你的CP信息,请稍后再试.");
		}
	}
	return Plugin_Handled;
}

public Action:Divorce(client)
{
	decl String:client_id[MAX_ID_LENGTH];
	
	if(GetClientAuthId(client, AuthId_Steam2, client_id, sizeof(client_id)))
	{
		if(proposal_checked[client] && marriage_checked[client])
		{
			if(checkUsage(client_id))
			{
				if(marriage_slots[client] == -2)
				{
					PrintToChat(client, "[\x0ECP系统\x01]  你还没有CP");
					//PrintToChat(client, "[\x0ECP系统\x01]  按Y输入!marry浏览CP列表");
				}
				else
				{
					new format;
					new time_spent;
					new partner = marriage_slots[client];
					decl String:client_name[MAX_NAME_LENGTH];				
					
					if(GetClientName(client, client_name, sizeof(client_name)))
					{
						revokeMarriage(client_id);
						forwardDivorce(client, partner);
						cacheUsage(client_id);				
						computeTimeSpent(marriage_times[client], time_spent, format);						
						switch(format)
						{
							case 0 :
							{
								PrintToChatAll("[\x0ECP系统\x01]  \x0E%s\x01与\x0E%s\x01解除了CP关系,他们的关系维持了\x04%i\x01天!", client_name, marriage_names[client], time_spent);
							}
							case 1 :
							{
								PrintToChatAll("[\x0ECP系统\x01]  \x0E%s\x01与\x0E%s\x01解除了CP关系,他们的关系维持了\x04%i\x01月!", client_name, marriage_names[client], time_spent);
							}
							case 2 :
							{
								PrintToChatAll("[\x0ECP系统\x01]  \x0E%s\x01与\x0E%s\x01解除了CP关系,他们的关系维持了\x04%i\x01年!", client_name, marriage_names[client], time_spent);
							}
						}
						EmitSoundToAllAny(ON_DEVORCE_SOUND);
						int FuckYou = 3166;
						Store_SetClientCredits(client, Store_GetClientCredits(client) - FuckYou, "CP-分手");
						PrintToChat(client, "[\x0ECP系统\x01]  主动发起离婚方扣除\x07%iCredits\x01,叫你丫瞎鸡巴玩弄感情", FuckYou);
						//PrintToChatAll("[\x0ECP系统\x01]  双方正在进行约定");
						marriage_slots[client] = -2;
						marriage_names[client] = "";
						marriage_ids[client] = "";
						marriage_scores[client] = -1;
						marriage_times[client] = -1;
						if(partner != -1)
						{
							marriage_slots[partner] = -2;
							marriage_names[partner] = "";
							marriage_ids[partner] = "";
							marriage_scores[partner] = -1;
							marriage_times[partner] = -1;						
						}						
					}
				}
			}
			else
			{
				PrintToChat(client, "[\x0ECP系统\x01]  请尊总彼此的CP对象,切忌滥用CP命令!");
				PrintToChat(client, "[\x0ECP系统\x01]  该操作延迟 %.2f 分钟.", GetConVarFloat(cvar_delay));
			}			
		}
		else
		{
			PrintToChat(client, "[\x0ECP系统\x01]  正在读取你的CP信息,请稍后再试.");
		}
	}
	return Plugin_Handled;
}

public Action:Couples(client, args)
{
	decl String:client_id[MAX_ID_LENGTH];
	
	if(GetClientAuthId(client, AuthId_Steam2, client_id, sizeof(client_id)))
	{
		findMarriages(client_id);
	}
	return Plugin_Handled;
}

public Action:Reset(client, args)
{
	resetTables(client);
	return Plugin_Handled;
}
