Skill_Teleport(client, partner)
{
	if(!IsClientInGame(partner) || !IsPlayerAlive(client) || !IsPlayerAlive(partner) || GetClientTeam(client) != GetClientTeam(partner))
	{
		if(!IsClientInGame(partner) || !IsPlayerAlive(client) || !IsPlayerAlive(partner))
			PrintToChat(client, "[\x0ECP系统\x01]  \x05你只能在你和你的炮友同时存活的情况下使用");
		if(GetClientTeam(client) != GetClientTeam(partner))
			PrintToChat(client, "[\x0ECP系统\x01]  \x05你与你的炮友阵营不同");
		return;
	}
	
	new iCredits = Store_GetClientCredits(client)
	if(iCredits < 500)
	{
		PrintToChat(client, "[\x0ECP系统\x01]  \x05你的金钱不够");
		return;
	}

	Skill_Teleport_Menu(partner);

}

Skill_Teleport_Menu(partner)
{
	new Handle:menu = CreateMenu(OpenTeleportMenuHandler);
	decl String:szTmp[64];
	Format(szTmp, 64, "[CP系统] 你的伴侣要传送到你这里 \n");
	SetMenuTitle(menu, szTmp);
	AddMenuItem(menu, "yes", "好的,让他过来吧");
	AddMenuItem(menu, "yes", "爱他,就在一起吧");
	AddMenuItem(menu, "no", "滚开,不想看见他");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, partner, 10);
}

public OpenTeleportMenuHandler(Handle:menu, MenuAction:action, partner, itemNum)
{
	if(action == MenuAction_Select) 
	{
		new String:info[32];
		GetMenuItem(menu, itemNum, info, sizeof(info));
		new client = marriage_slots[partner];
		if(strcmp(info,"yes") == 0) 
		{
			if(client > -1)
				Skill_Teleport_DoTeleport(client, partner);
		}
		if(strcmp(info,"no") == 0)
		{
			if(client > -1)
				PrintToChat(client, "[\x0ECP系统\x01]  \x05你的CP现在不想看见你.");
			if(FindPluginByFile("KZTimer.smx") || FindPluginByFile("KZTimerGlobal.smx"))
				FakeClientCommandEx(partner, "sm_menu");
		}
	}
	else if (action == MenuAction_End)
	{
		if(FindPluginByFile("KZTimer.smx") || FindPluginByFile("KZTimerGlobal.smx"))
			FakeClientCommandEx(partner, "sm_menu");
		else
			CloseHandle(menu);
	}
}

Skill_Teleport_DoTeleport(client, partner)
{
	Store_SetClientCredits(client, Store_GetClientCredits(client) - 500, "CP-传送");
	
	decl Float:ang[3], Float:vec[3];
	GetClientAbsAngles(partner, ang);
	GetClientAbsOrigin(partner, vec);
	
	if(FindPluginByFile("KZTimer.smx") || FindPluginByFile("KZTimerGlobal.smx"))
	{
		FakeClientCommandEx(client, "sm_stop");
		FakeClientCommandEx(client, "sm_start");
	}
	
	if(FindPluginByFile("timer-core.smx"))
	{
		FakeClientCommandEx(client, "say !r");
	}

	TeleportEntity(client, vec, ang, NULL_VECTOR);
	
	PrintToChat(client, "[\x0ECP系统\x01] \x05成功把你传送到你炮友所在的位置");
	PrintToChat(partner, "[\x0ECP系统\x01] \x05成功把你炮友传送到你所在的位置");
	PrintToChat(client, "[\x0ECP系统\x01] 恶意使用该技能将会导致你们被封禁CP(包括但不限于卡地图BUG)");
	PrintToChat(partner, "[\x0ECP系统\x01] 恶意使用该技能将会导致你们被封禁CP(包括但不限于卡地图BUG)");
	PrintToChatAll("[\x0ECP系统\x01] \x04%N\x05使用CP技能传送到\x04%N\x05的位置", client, partner);
	LogToFile(LogFile," \"%N\"传送到\"%N\". Maps:%s", client, partner, g_szMapName);
}

public Action:Skill_Beacon(Handle:timer, any:client)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;
	
	if(!g_bEnableBeacon[client])
		return Plugin_Stop;

	new partner = marriage_slots[client];
	if(partner<1)
		return Plugin_Stop;

	if(!g_bClientBeacon[partner])
		return Plugin_Stop;

	if(partner < 1 || !IsClientInGame(partner) || !IsPlayerAlive(partner) || GetClientTeam(client) != GetClientTeam(partner))
	{
		g_bClientBeacon[client] = false;

		if(!IsClientInGame(partner))
		{
			PrintToChat(client, "[\x0ECP系统\x01]  \x05你的CP已经离开了游戏");
			return Plugin_Stop;
		}
		if(!IsPlayerAlive(partner))
		{
			PrintToChat(client, "[\x0ECP系统\x01]  \x05你的CP已经死亡");
			return Plugin_Stop;
		}
		if(GetClientTeam(client) != GetClientTeam(partner))
		{
			PrintToChat(client, "[\x0ECP系统\x01]  \x05你们阵营不同");
			return Plugin_Stop;
		}
	}
	
	new Float:vec[3];
	GetClientAbsOrigin(partner, vec);
	vec[2] += 10;
	//TE_SetupBeamRingPoint(vec, 10.0, 375.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, {247, 191, 190, 255}, 10, 0);
	TE_SetupBeamRingPoint(vec, 10.0, 100.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, {255, 0, 255, 255}, 10, 0);
	TE_SendToClient(client);
	return Plugin_Continue;
}

Skill_Shared(client)
{
	new Handle:menu = CreateMenu(OpenSharedMenuHandler);
	decl String:szTmp[64];
	Format(szTmp, 64, "[CP系统] 选择你要分享的类型 \n");
	SetMenuTitle(menu, szTmp);
	AddMenuItem(menu, "credits", "分享你的Credits");
	AddMenuItem(menu, "gamemoney", "分享你的游戏金钱(当前模式禁用)", ITEMDRAW_DISABLED);
	//AddMenuItem(menu, "cpmoney", "分享你的CP金钱");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 10);
}

public OpenSharedMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{
	if(action == MenuAction_Select) 
	{
		new String:info[32];
		GetMenuItem(menu, itemNum, info, sizeof(info));
		
		if(strcmp(info,"credits") == 0) 
		{
			Skill_Shared_Credits(client);
		}
		else if(strcmp(info,"gamemoney") == 0)
		{
			Skill_Shared_GameMoney(client);
		}
		else if(strcmp(info,"cpmoney") == 0)
		{
			//Skill_Shared_CPMoney(client);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

Skill_Shared_Credits(client)
{
	new Handle:menu = CreateMenu(OpenSharedCreditsMenuHandler);
	decl String:szTmp[64];
	int iCredits= Store_GetClientCredits(client);
	Format(szTmp, 64, "[CP系统] 你要分享Credits? \nCredits:%i", iCredits);
	SetMenuTitle(menu, szTmp);
	if(iCredits >= 500)
		AddMenuItem(menu, "500", "500 Credits");
	else
		AddMenuItem(menu, "500", "500 Credits", ITEMDRAW_DISABLED);
	
	if(iCredits >= 1000)
		AddMenuItem(menu, "1000", "1000 Credits");
	else
		AddMenuItem(menu, "1000", "1000 Credits", ITEMDRAW_DISABLED);
	
	if(iCredits >= 2000)
		AddMenuItem(menu, "2000", "2000 Credits");
	else
		AddMenuItem(menu, "2000", "2000 Credits", ITEMDRAW_DISABLED);
	
	if(iCredits >= 5000)
		AddMenuItem(menu, "5000", "5000 Credits");
	else
		AddMenuItem(menu, "5000", "5000 Credits", ITEMDRAW_DISABLED);
	
	if(iCredits >= 10000)
		AddMenuItem(menu, "10000", "10000 Credits");
	else
		AddMenuItem(menu, "10000", "10000 Credits", ITEMDRAW_DISABLED);
	
	if(iCredits >= 5201314)
		AddMenuItem(menu, "5201314", "5201314 Credits");
	else
		AddMenuItem(menu, "5201314", "5201314 Credits", ITEMDRAW_DISABLED);
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 10);
}

public OpenSharedCreditsMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{
	if(action == MenuAction_Select) 
	{
		new String:info[32];
		GetMenuItem(menu, itemNum, info, sizeof(info));
		
		if(strcmp(info,"500") == 0) 
			Skill_Shared_DoCredits(client, 500);
		else if(strcmp(info,"1000") == 0) 
			Skill_Shared_DoCredits(client, 1000);
		else if(strcmp(info,"2000") == 0) 
			Skill_Shared_DoCredits(client, 2000);
		else if(strcmp(info,"5000") == 0) 
			Skill_Shared_DoCredits(client, 5000);
		else if(strcmp(info,"10000") == 0) 
			Skill_Shared_DoCredits(client, 10000);
		else if(strcmp(info,"5201314") == 0) 
			Skill_Shared_DoCredits(client, 5201314);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

Skill_Shared_DoCredits(client, credits)
{
	new partner = marriage_slots[client];
	
	if(partner<1)
		return;
	
	if(!IsClientInGame(partner))
	{
		PrintToChat(client, "[\x0ECP系统\x01]  \x05你的CP当前离线");
		return;
	}
	
	if(credits > Store_GetClientCredits(client))
	{
		PrintToChat(client, "[\x0ECP系统\x01]  \x05Credits不足");
		return;
	}
	
	int EarnCredits = RoundToFloor(credits * 0.88);
	Store_SetClientCredits(client, Store_GetClientCredits(client) - credits, "CP-分享(支出)");
	Store_SetClientCredits(partner, Store_GetClientCredits(partner) + EarnCredits, "CP-分享(收入)");
	
	LogToFile(LogFile," \"%N\"分享给\"%N\" %iCredits 到帐%iCredits", client, partner, credits, EarnCredits);
	PrintToChat(client, "\x01 \x04[Store]  \x01你给你的伴侣分享了\x04%i\x07Credits\x01,TA收到了\x04%i\x07Credits", credits, EarnCredits);
	PrintToChat(partner, "\x01 \x04[Store]  \x01你的伴侣给你分享了\x04%i\x07Credits\x01,你收到了\x04%i\x07Credits", credits, EarnCredits);
}

Skill_Shared_GameMoney(client)
{
	PrintToChat(client, "[\x0ECP系统\x01]  \x01功能测试中");
}

Skill_Medic(client, partner)
{
	if(partner<1)
		return;
	
	if(!IsClientInGame(partner))
	{
		PrintToChat(client, "[\x0ECP系统\x01]  \x05你的CP当前离线");
		return;
	}
	
	if(GetClientTeam(client) != GetClientTeam(partner))
	{
		PrintToChat(client, "[\x0ECP系统\x01]  \x05你的CP与你阵营不同");
		return;
	}
	
	new iCredits = Store_GetClientCredits(client);
	if(iCredits < 300)
	{
		PrintToChat(client, "[\x0ECP系统\x01]  \x05你的金钱不够");
		return;
	}
	
	decl Float:MedicOrigin[3],Float:TargetOrigin[3], Float:Distance;
	GetClientAbsOrigin(client, MedicOrigin);
	GetClientAbsOrigin(partner, TargetOrigin);
	Distance = GetVectorDistance(TargetOrigin,MedicOrigin);
	if(Distance >= 50.0)
	{
		PrintToChat(client, "[\x0ECP系统\x01]  \x05你们之间的距离太远了");
		g_bClientMedic[client] = false;
	}
	else
	{
		Store_SetClientCredits(client, Store_GetClientCredits(client) - 300, "CP-恢复");
		g_bClientMedic[client] = true;
		g_bClientMedic[partner] = true;
		g_iClientMedic[client] = 0;
		g_iClientMedic[partner] = 0;
		SetEntityMoveType(client, MOVETYPE_NONE);
		SetEntityMoveType(partner, MOVETYPE_NONE);
		PrintToChatAll("[\x0ECP系统\x01] \x04%N\x05和\x04%N\x05使用了CP技能(恢复生命)", client, partner);
		PrintToChat(client, "[\x0ECP系统\x01] 恶意使用该技能将会导致你们被封禁CP(包括但不限于卡地图BUG)");
		PrintToChat(partner, "[\x0ECP系统\x01] 恶意使用该技能将会导致你们被封禁CP(包括但不限于卡地图BUG)");
		LogToFile(LogFile," \"%N\"发起了和\"%N\"的回血 Map:%s", client, partner, g_szMapName);
		CreateTimer(0.125, Skill_Medic_DoHP, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Skill_Medic_DoHP(Handle:timer, any:client)
{
	new partner = marriage_slots[client];
	
	if(partner<1)
		return Plugin_Stop;
	
	if(!IsClientInGame(partner) || !IsClientInGame(client))
	{
		PrintToChat(client, "[\x0ECP系统\x01]  \x05你的CP当前离线");
		PrintToChat(partner, "[\x0ECP系统\x01]  \x05你的CP当前离线");
		SetEntityMoveType(client, MOVETYPE_WALK);
		SetEntityMoveType(partner, MOVETYPE_WALK);
		g_iClientMedic[client] = 0;
		g_iClientMedic[partner] = 0;
		g_bClientMedic[client] = false;
		g_bClientMedic[partner] = false;
		return Plugin_Stop;
	}
	
	if(!IsPlayerAlive(partner) || !IsPlayerAlive(client))
	{
		PrintToChat(client, "[\x0ECP系统\x01]  \x05你们当中有一人阵亡了");
		PrintToChat(partner, "[\x0ECP系统\x01]  \x05你们当中有一人阵亡了");
		SetEntityMoveType(client, MOVETYPE_WALK);
		SetEntityMoveType(partner, MOVETYPE_WALK);
		g_iClientMedic[client] = 0;
		g_iClientMedic[partner] = 0;
		g_bClientMedic[client] = false;
		g_bClientMedic[partner] = false;
		return Plugin_Stop;
	}
	
	if(GetClientTeam(client) != GetClientTeam(partner))
	{
		PrintToChat(client, "[\x0ECP系统\x01]  \x05你的CP与你阵营不同");
		PrintToChat(partner, "[\x0ECP系统\x01]  \x05你的CP与你阵营不同");
		SetEntityMoveType(client, MOVETYPE_WALK);
		SetEntityMoveType(partner, MOVETYPE_WALK);
		g_iClientMedic[client] = 0;
		g_iClientMedic[partner] = 0;
		g_bClientMedic[client] = false;
		g_bClientMedic[partner] = false;
		return Plugin_Stop;
	}
	
	new ClientHealth = GetClientHealth(client);
	new PartnerHealth = GetClientHealth(partner);
	new maxhp = 100;
	if(FindPluginByFile("ct.smx"))
		maxhp = 165;
	
	if(g_iClientMedic[client] >= 99 || g_iClientMedic[partner] >= 99 || ClientHealth >= maxhp || PartnerHealth >= maxhp)
	{
		PrintToChat(client, "[\x0ECP系统\x01]  \x05恢复完成,祝你们小两口好运");
		PrintToChat(partner, "[\x0ECP系统\x01]  \x05恢复完成,祝你们小两口好运");
		SetEntityMoveType(client, MOVETYPE_WALK);
		SetEntityMoveType(partner, MOVETYPE_WALK);
		g_iClientMedic[client] = 0;
		g_iClientMedic[partner] = 0;
		g_bClientMedic[client] = false;
		g_bClientMedic[partner] = false;
		return Plugin_Stop;
	}
	else
	{
		SetClientHealth(client, ClientHealth + 1);
		SetClientHealth(partner, ClientHealth + 1);
		g_iClientMedic[client] += 1;
		g_iClientMedic[partner] += 1;
	}
	return Plugin_Continue;
}

Skill_ShowX(client, partner)
{
	PrintToChat(client, "[\x0ECP系统\x01]  \x01功能测试中");
	PrintToChat(partner, "[\x0ECP系统\x01]  \x01功能测试中");
}

Skill_Sync(client, partner)
{
	if(partner < 1)
		return;
	
	if(!IsClientInGame(partner))
		return;
	
	if(marriage_scores[client] >= marriage_scores[partner])
		marriage_scores[partner] = marriage_scores[client];
	else
		marriage_scores[client] = marriage_scores[partner];
	
	PrintToChat(client, "[\x0ECP系统\x01]  同步完成");
}

Skill_ZombieEscape_Damage(client, partner)
{
	if(partner<1)
		return;
	
	if(!IsClientInGame(partner))
	{
		PrintToChat(client, "[\x0ECP系统\x01]  \x05你的CP当前离线");
		return;
	}
	
	if(GetClientTeam(client) != GetClientTeam(partner))
	{
		PrintToChat(client, "[\x0ECP系统\x01]  \x05你的CP与你阵营不同");
		return;
	}
	
	new iCredits = Store_GetClientCredits(client);
	if(iCredits < 100)
	{
		PrintToChat(client, "[\x0ECP系统\x01]  \x05你的金钱不够");
		return;
	}
	
	decl Float:MedicOrigin[3],Float:TargetOrigin[3], Float:Distance;
	GetClientAbsOrigin(client, MedicOrigin);
	GetClientAbsOrigin(partner, TargetOrigin);
	Distance = GetVectorDistance(TargetOrigin,MedicOrigin);
	if(Distance >= 500.0)
	{
		PrintToChat(client, "[\x0ECP系统\x01]  \x05你们之间的距离太远了");
		g_bClientMedic[client] = false;
	}
	else
	{
		Store_SetClientCredits(client, Store_GetClientCredits(client) - 100, "CP-Buff");
		//g_bZombieDamage[client] = true;
		//g_bZombieDamage[partner] = true;
		PrintToChat(client, "[\x0ECP系统\x01] 你和你的伴侣获得了20%%的守点伤害加成,只要你们之间距离不超过500,Buff将会持续.");
		PrintToChat(partner, "[\x0ECP系统\x01] 你和你的伴侣获得了20%%的守点伤害加成,只要你们之间距离不超过500,Buff将会持续.");
		LogToFile(LogFile," \"%N\"发起了和\"%N\"的守点伤害加成 Map:%s", client, partner, g_szMapName);
		CreateTimer(5.0, Skill_ZombieEscape_Fix, client, TIMER_REPEAT);
	}
}

public Action Skill_ZombieEscape_Fix(Handle timer, any client)
{
	new partner = marriage_slots[client];
	
	if(!IsClientInGame(client) || partner < 1)
	{
		//g_bZombieDamage[client] = false;
		//g_bZombieDamage[partner] = false;
		if(!IsClientInGame(client))
			PrintToChat(partner, "[\x0ECP系统\x01] 你的伴侣已离线,伤害加成Buff消失.");
		if(partner < 1)
			PrintToChat(client, "[\x0ECP系统\x01] 你的伴侣已离线,伤害加成Buff消失.");
		return Plugin_Stop;
	}
	if(!IsPlayerAlive(client) || !IsPlayerAlive(partner))
	{
		//g_bZombieDamage[client] = false;
		//g_bZombieDamage[partner] = false;
		if(!IsPlayerAlive(client))
			PrintToChat(partner, "[\x0ECP系统\x01] 你的伴侣已阵亡,伤害加成Buff消失.");
		if(!IsPlayerAlive(partner))
			PrintToChat(client, "[\x0ECP系统\x01] 你的伴侣已阵亡,伤害加成Buff消失.");
		return Plugin_Stop;
	}
	if(GetClientTeam(client) != GetClientTeam(partner))
	{
		PrintToChat(client, "[\x0ECP系统\x01]  \x05你的CP与你阵营不同");
		PrintToChat(partner, "[\x0ECP系统\x01]  \x05你的CP与你阵营不同");
		//g_bZombieDamage[client] = false;
		//g_bZombieDamage[partner] = false;
		return Plugin_Stop;
	}
	
	decl Float:MedicOrigin[3],Float:TargetOrigin[3], Float:Distance;
	GetClientAbsOrigin(client, MedicOrigin);
	GetClientAbsOrigin(partner, TargetOrigin);
	Distance = GetVectorDistance(TargetOrigin,MedicOrigin);
	
	if(Distance >= 500.0)
	{
		PrintToChat(client, "[\x0ECP系统\x01]  \x05你们之间的距离超出范围,Buff消失");
		PrintToChat(partner, "[\x0ECP系统\x01]  \x05你们之间的距离超出范围,Buff消失");
		//g_bZombieDamage[client] = true;
		//g_bZombieDamage[partner] = true;
		return Plugin_Stop;
	}
	
	//g_bZombieDamage[client] = true;
	//g_bZombieDamage[partner] = true;

	return Plugin_Continue;
}

SetClientHealth(client, amount)
{
	new HealthOffs = FindDataMapOffs(client, "m_iHealth");
	SetEntData(client, HealthOffs, amount, true);
}
/*
public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(damage <= 0.0 || victim < 1 || victim > MaxClients || attacker < 1 || attacker > MaxClients)
		return Plugin_Continue;
	
	if(!IsValidEdict(weapon))
		return Plugin_Continue;
	
	//if(!g_bZombieDamage[attacker])
	//	return Plugin_Continue;
	
	damage = damage * 1.2;
	return Plugin_Changed;
}
*/