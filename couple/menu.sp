// Handler for the !marry menu.
public MarryMenuHandler(Handle:marry_menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select :
		{
			new target; 
			decl String:source_id[MAX_ID_LENGTH];
			decl String:target_id[MAX_ID_LENGTH];
			decl String:source_name[MAX_NAME_LENGTH];
			decl String:target_name[MAX_NAME_LENGTH];
			
			GetMenuItem(marry_menu, param2, target_id, sizeof(target_id));
			if(GetClientName(param1, source_name, sizeof(source_name)) && GetClientAuthId(param1, AuthId_Steam2, source_id, sizeof(source_id)))
			{
				target = getClientBySteamID(target_id);
				if(target != -1 && GetClientName(target, target_name, sizeof(target_name)))
				{
					if(marriage_slots[target] == -2)
					{					
						if(proposal_slots[target] != param1)
						{												
							addProposal(source_name, source_id, target_name, target_id);
							forwardProposal(param1, target);
							cacheUsage(source_id);
							PrintToChat(param1, "[\x0ECP系统\x01]  你的CP请求已发送,祝你好运!");
							PrintToChat(target, "[\x0ECP系统\x01]  你收到了\x0E%s\x01的CP请求!", source_name);
							PrintToChat(target, "[\x0ECP系统\x01]  按Y输入!cp浏览所有向你提出请求的玩家.");
							proposal_slots[param1] = target;
							proposal_names[param1] = target_name;
							proposal_ids[param1] = target_id;
						}
						else
						{
							PrintToChat(param1, "[\x0ECP系统\x01]  \x0E%s\x01已经向你发出了CP请求!", target_name);
							PrintToChat(target, "[\x0ECP系统\x01]  按Y输入!cp浏览所有向你提出请求的玩家.");
						}
					}
					else
					{
						PrintToChat(param1, "[\x0ECP系统\x01]  什么?你要与人妻结为CP??");
					}
				}
				else
				{
					PrintToChat(param1, "[\x0ECP系统\x01]  对方已离开服务器");
				}
			}
		}
		case MenuAction_End :
		{
			CloseHandle(marry_menu);
		}
	}
	return 0;
}


// Handler for the !proposals menu.
public ProposalsMenuHandler(Handle:proposals_menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select :
		{
			new time;
			new source;
			decl String:source_id[MAX_ID_LENGTH];
			decl String:source_name[MAX_NAME_LENGTH];	
			
			GetMenuItem(proposals_menu, param2, source_id, sizeof(source_id));
			source = getClientBySteamID(source_id);
			if(source != -1 && GetClientName(source, source_name, sizeof(source_name)))
			{
				if(marriage_slots[source] == -2)
				{	
					int ILoveYou = 1314;
					if(Store_GetClientCredits(param1) >= ILoveYou && Store_GetClientCredits(source) >= ILoveYou)
					{
						addMarriage(source_name, source_id, proposal_names[source], proposal_ids[source]);
						forwardWedding(source, param1);
						cacheUsage(proposal_ids[source]);						
						PrintToChat(param1, "[\x0ECP系统\x01]  你和\x0E %s \x01结为CP关系!", source_name);
						PrintToChat(source, "[\x0ECP系统\x01]  \x0E%s\x01接受了与你CP的请求!", proposal_names[source]);
						PrintToChatAll("[\x0ECP系统\x01]  \x0E%s\x01和\x0E%s\x01结为了一对CP!祝他们幸福!", source_name, proposal_names[source]);
						Store_SetClientCredits(param1, Store_GetClientCredits(param1) - ILoveYou, "CP-结婚");
						Store_SetClientCredits(source, Store_GetClientCredits(source) - ILoveYou, "CP-结婚");
						PrintToChat(param1, "[\x0ECP系统\x01]  民政局收取了你\x07%iCredits\x01登记费!", ILoveYou);
						PrintToChat(source, "[\x0ECP系统\x01]  民政局收取了你\x07%iCredits\x01登记费!", ILoveYou);
						EmitSoundToAllAny(ON_MARRIED_SOUND);
						CreateTimer(12.0, PlayFireworkSound, _, TIMER_FLAG_NO_MAPCHANGE);
						time = GetTime();
						marriage_slots[source] = param1;
						marriage_names[source] = proposal_names[source];
						marriage_ids[source] = proposal_ids[source];
						marriage_scores[source] = 0;
						marriage_times[source] = time;						
						marriage_slots[param1] = source;						
						marriage_names[param1] = source_name;						
						marriage_ids[param1] = source_id;						
						marriage_scores[param1] = 0;
						marriage_times[param1] = time;	
						proposal_slots[source] = -2;
						proposal_names[source] = "";
						proposal_ids[source] = "";
						proposal_slots[param1] = -2;
						proposal_names[param1] = "";
						proposal_ids[param1] = "";
						for(new i = 1; i <= MaxClients; i++)
						{
							if(proposal_slots[i] == source || proposal_slots[i] == param1)
							{
								proposal_slots[i] = -2;
								proposal_names[i] = "";
								proposal_ids[i] = "";
							}						
						}
					}
					else
					{
						PrintToChat(param1, "[\x0ECP系统\x01]  你们小俩口的全身家当都不够交登记费的.");
						PrintToChat(source, "[\x0ECP系统\x01]  你们小俩口的全身家当都不够交登记费的.");
					}
				}
				else
				{
					PrintToChat(param1, "[\x0ECP系统\x01]  什么?你要与人妻结为CP??");
				}
			}
			else
			{
				PrintToChat(param1, "[\x0ECP系统\x01]  对方已离开服务器");
			}
		} 
		case MenuAction_End :
		{
			CloseHandle(proposals_menu);
		}
	}
	return 0;
}


// Handler for the !couples menu.
public CouplesMenuHandler(Handle:couples_menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End :
		{
			CloseHandle(couples_menu);
		}
	}
	return 0;
}

//MenuAction
public Action:OpenMenu(client,args)
{
	new Handle:menu = CreateMenu(OpenMainMenuHandler);
	SetMenuTitle(menu, "[CP系统] 主菜单 \n -by shAna.xQy- \n");
	AddMenuItem(menu, "cp_qiuhun", "寻找CP对象");
	AddMenuItem(menu, "cp_qhlb", "CP请求列表");
	AddMenuItem(menu, "cp_qxqh", "撤销CP请求");
	AddMenuItem(menu, "cp_qxcp", "解除CP");
	AddMenuItem(menu, "cp_zxcp", "CP排行榜");
	AddMenuItem(menu, "sm_skill", "CP技能");
	AddMenuItem(menu, "cp_help", "CP系统说明");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 10);
}

public OpenMainMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{
	if ( action == MenuAction_Select ) 
	{
		new String:info[32];
		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		if(FindPluginByFile("KZTimer.smx") || FindPluginByFile("KZTimerGlobal.smx"))
		{
			ClientCommand(client, info);
			PrintToChat(client, "[\x0ECP系统\x01]  KZ服如果出现菜单不显示的BUG请直接使用指令");
			if(strcmp(info, "cp_qiuhun") == 0)
				PrintToChat(client, "[\x0ECP系统\x01]  你选择了寻找CP对象 命令:!cp_qiuhun");
			if(strcmp(info, "cp_qhlb") == 0)
				PrintToChat(client, "[\x0ECP系统\x01]  你选择了查询CP请求列表 命令:!cp_qhlb");
			if(strcmp(info, "cp_qxqh") == 0)
				PrintToChat(client, "[\x0ECP系统\x01]  你选择了撤销CP请求 命令:!cp_qxqh");
			if(strcmp(info, "cp_qxcp") == 0)
				PrintToChat(client, "[\x0ECP系统\x01]  你选择了解除CP 命令:!cp_qxcp");
			if(strcmp(info, "cp_zxcp") == 0)
				PrintToChat(client, "[\x0ECP系统\x01]  你选择了查询CP排行榜 命令:!cp_zxcp");
			if(strcmp(info, "sm_skill") == 0)
				PrintToChat(client, "[\x0ECP系统\x01]  你选择了使用CP技能 命令:!skill");
		}
		else
			FakeClientCommandEx(client, info);
		
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:DivorceMenu(client,args)
{
	new Handle:menu = CreateMenu(OpenDivorceMenuHandler);
	SetMenuTitle(menu, "[CP系统] 你确定要解除CP关系吗？ \n -by shAna.xQy- \n单方解除CP需要: 3166Credits \n ");
	AddMenuItem(menu, "no", "我很爱很爱他");
	AddMenuItem(menu, "no", "月亮代表我心");
	AddMenuItem(menu, "yes", "我要解除关系");
	AddMenuItem(menu, "yes", "妈的他出轨了");
	AddMenuItem(menu, "yes", "我已不爱他了");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 10);
}

public OpenDivorceMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{
	if ( action == MenuAction_Select ) 
	{
		new String:info[32];		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		if(strcmp(info, "no") == 0)
			FakeClientCommand(client, "sm_cp");
		if(strcmp(info, "yes") == 0)
		{
			if(Store_GetClientCredits(client) > 3166)
				Divorce(client);
			else
				PrintToChat(client, "[\x0ECP系统\x01]  钱不够你也想离婚？");
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:CP_HelpPanel(client, args)
{
	CPHelpPanel(client);
	return Plugin_Handled;
}

public CPHelpPanel(client)
{
	new Handle:panel = CreatePanel();
	decl String:title[64];
	Format(title, 64, "[CP系统] 帮助菜单  \n(1/2) -by shAna.xQy-");
	DrawPanelText(panel, title);
	DrawPanelText(panel, " ");
	DrawPanelText(panel, "按Y输入!skill打开CP技能菜单");
	DrawPanelText(panel, "按Y输入!qhlb查看向你CP的人");
	DrawPanelText(panel, "按Y输入!find来向某人发起CP");
	DrawPanelText(panel, "按Y输入!zxcp来查看在线的基佬");
	DrawPanelText(panel, "按Y输入!qxqh来取消发起的CP");
	DrawPanelText(panel, "按Y输入!qxcp来终止CP");
	DrawPanelText(panel, " ");
	DrawPanelItem(panel, "下一页");
	DrawPanelItem(panel, "退出");
	SendPanelToClient(panel, client, CPHelpPanelHandler, 10000);
	CloseHandle(panel);
}

public CPHelpPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if(param2==1)
			CPHelpPanel2(param1);
		else
			FakeClientCommand(param1, "sm_cp");
	}
}

public CPHelpPanel2(client)
{
	new Handle:panel = CreatePanel();
	decl String:szTmp[64];
	Format(szTmp, 64, "[CP系统] 帮助菜单  \n(2/2) -by shAna.xQy-");
	DrawPanelText(panel, szTmp);
	DrawPanelText(panel, " ");
	DrawPanelText(panel, "配对CP需要两厢情愿");
	DrawPanelText(panel, "一旦双方同意,每人自动扣除一定登记费");
	DrawPanelText(panel, "目前情况下为配对CP 1314Credits/人");
	DrawPanelText(panel, "请珍惜来之不易的爱(基)情");
	DrawPanelText(panel, "单方面发起终止CP需要付出很大代价");
	DrawPanelText(panel, "需要你支付3166Credits才能执行");
	DrawPanelText(panel, "CP系统更多功能开发中!!");
	DrawPanelText(panel, " ");
	DrawPanelItem(panel, "前一页");
	DrawPanelItem(panel, "退出");
	SendPanelToClient(panel, client, CPHelpPanelHandler2, 10000);
	CloseHandle(panel);
}

public CPHelpPanelHandler2(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if(param2==1)
			CPHelpPanel(param1);
		else
			FakeClientCommand(param1, "sm_cp");
	}
}

public Action:SkillMenu(client,args)
{
	if(marriage_slots[client] == -2)
	{
		PrintToChat(client,"[\x0ECP系统\x01]  单身狗还想使用CP技能？");
		return Plugin_Handled;
	}
	if(marriage_slots[client] < 1)
	{
		PrintToChat(client,"[\x0ECP系统\x01]  你的CP现在不在线");
		return Plugin_Handled;
	}
	new Handle:menu = CreateMenu(OpenSkillMenuHandler);
	new iCredits = Store_GetClientCredits(client);
	decl String:szTmp[128];
	Format(szTmp, 128, "[CP系统] 技能菜单 \n余额:%i Credits", iCredits);
	SetMenuTitle(menu, szTmp);
	if(iCredits >= 50)
		AddMenuItem(menu, "cp_beacon", "高亮你的另一半[50Credits]");
	else
		AddMenuItem(menu, "cp_beacon", "高亮你的另一半[50Credits]", ITEMDRAW_DISABLED);
	if(iCredits >= 500)
		AddMenuItem(menu, "cp_teleport", "传送到你的另一半[500Credits]");
	else
		AddMenuItem(menu, "cp_teleport", "传送到你的另一半[500Credits]", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "cp_shared", "分享金钱给你的另一半");
	if(iCredits >= 300)
		AddMenuItem(menu, "cp_medic", "与另一半回血[300Credits]");
	else
		AddMenuItem(menu, "cp_medic", "与另一半回血[300Credits]", ITEMDRAW_DISABLED);
	//AddMenuItem(menu, "cp_showx", "与另一半秀恩爱[0金钱]", ITEMDRAW_DISABLED);
	//if(FindPluginByFile("zombiereloaded.smx"))
	//	AddMenuItem(menu, "cp_zedamage", "携手守点伤害加成[100金钱]");
	AddMenuItem(menu, "cp_sync", "与另一半数据同步[免费]");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 10);
	return Plugin_Handled;
}

public OpenSkillMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{
	if(action == MenuAction_Select) 
	{
		new String:info[32];
		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		
		if(strcmp(info,"cp_beacon") == 0) 
		{
			new iCredits = Store_GetClientCredits(client);
			new partner = marriage_slots[client];
			if(partner <= -1)
				PrintToChat(client,"[\x0ECP系统\x01]  你的CP当前离线");
			else
			{
				//Skill_Beacon(client, partner);
				if(iCredits >= 50)
				{
					Store_SetClientCredits(client, Store_GetClientCredits(client) - 50, "CP-高亮");
					g_bClientBeacon[partner] = true;
					g_bEnableBeacon[client] = true;
					PrintToChat(client, "[\x0ECP系统\x01]  \x05已设置高亮你的另一半");
					CreateTimer(0.5, Skill_Beacon, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					LogToFile(LogFile," \"%N\"设置高亮另一半\"%N\".", client, partner);
				}
				else
				{
					PrintToChat(client, "[\x0ECP系统\x01]  \x05你的金钱不够");
				}
			}
		}
		else if(strcmp(info,"cp_teleport") == 0)
		{
			new partner = marriage_slots[client];
			if(partner <= -1)
				PrintToChat(client,"[\x0ECP系统\x01]  你的CP当前离线");
			else
				Skill_Teleport(client, partner);
		}
		else if(strcmp(info,"cp_shared") == 0)
		{
			Skill_Shared(client);
		}
		else if(strcmp(info,"cp_medic") == 0)
		{
			new partner = marriage_slots[client];
			if(partner <= -1)
				PrintToChat(client,"[\x0ECP系统\x01]  你的CP当前离线");
			else
				Skill_Medic(client, partner);
				//CreateTimer(1.0, Skill_Medic, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		else if(strcmp(info,"cp_showx") == 0)
		{
			new partner = marriage_slots[client];
			if(partner <= -1)
				PrintToChat(client,"[\x0ECP系统\x01]  你的CP当前离线");
			else
				Skill_ShowX(client, partner);
		}
		else if(strcmp(info,"cp_sync") == 0)
		{
			new partner = marriage_slots[client];
			if(partner <= -1)
				PrintToChat(client,"[\x0ECP系统\x01]  你的CP当前离线");
			else
				Skill_Sync(client, partner);
		}
		else if(strcmp(info,"cp_zedamage") == 0)
		{
			new partner = marriage_slots[client];
			if(partner <= -1)
				PrintToChat(client,"[\x0ECP系统\x01]  你的CP当前离线");
			else
				Skill_ZombieEscape_Damage(client, partner);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}