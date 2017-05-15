public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	Call_StartForward(g_eEvents[round_start]);
	Call_Finish();
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	Call_StartForward(g_eEvents[round_end]);
	Call_PushCell(GetEventInt(event, "winner"));
	Call_Finish();
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	Call_StartForward(g_eEvents[player_spawn]);
	Call_PushCell(GetClientOfUserId(GetEventInt(event, "userid")));
	Call_Finish();
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	Call_StartForward(g_eEvents[player_death]);
	Call_PushCell(GetClientOfUserId(GetEventInt(event, "userid")));
	Call_PushCell(GetClientOfUserId(GetEventInt(event, "attacker")));
	Call_PushCell(GetClientOfUserId(GetEventInt(event, "assister")));
	Call_PushCell(GetEventBool(event, "headshot"));
	char weapon[32];
	GetEventString(event, "weapon", weapon, 32, "");
	Call_PushString(weapon);
	Call_Finish();
}

public void Event_PlayerHurts(Event event, const char[] name, bool dontBroadcast)
{
	Call_StartForward(g_eEvents[player_hurt]);
	Call_PushCell(GetClientOfUserId(GetEventInt(event, "userid")));
	Call_PushCell(GetClientOfUserId(GetEventInt(event, "attacker")));
	Call_PushCell(GetEventInt(event, "dmg_health"));
	Call_PushCell(GetEventInt(event, "hitgroup"));
	char weapon[32];
	GetEventString(event, "weapon", weapon, 32, "");
	Call_PushString(weapon);
	Call_Finish();
}

public Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	SetEventBroadcast(event, true);
	
	Call_StartForward(g_eEvents[player_team]);
	Call_PushCell(GetClientOfUserId(GetEventInt(event, "userid")));
	Call_PushCell(GetEventInt(event, "oldteam"));
	Call_PushCell(GetEventInt(event, "team"));
	Call_Finish();

	return Plugin_Changed;
}

public void Event_PlayerJump(Event event, const char[] name, bool dontBroadcast)
{
	Call_StartForward(g_eEvents[player_jump]);
	Call_PushCell(GetClientOfUserId(GetEventInt(event, "userid")));
	Call_Finish();
}

public void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	Call_StartForward(g_eEvents[weapon_fire]);
	Call_PushCell(GetClientOfUserId(GetEventInt(event, "userid")));
	char weapon[32];
	GetEventString(event, "weapon", weapon, 32, "");
	Call_PushString(weapon);
	Call_Finish();
}

public Action Event_PlayerName(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"))

	Call_StartForward(g_eEvents[player_name]);
	Call_PushCell(client);
	char oldname[32];
	GetEventString(event, "oldname", oldname, 32, "");
	Call_PushString(oldname);
	char newname[32];
	GetEventString(event, "newname", newname, 32, "");
	Call_PushString(newname);
	Call_Finish();

	RequestFrame(Frame_CheckClientName, client);
	
	SetEventBroadcast(event, true);
	
	return Plugin_Changed;
}