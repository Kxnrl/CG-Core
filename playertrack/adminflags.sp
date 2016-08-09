//////////////////////////////
//		GET CLIENT FLAG		//
//////////////////////////////
int GetClientFlags(int client)
{
	//先获得客户flags
	int flags = GetUserFlagBits(client);
	char flagstring[64];
	char flag[64];
	
	//取得32位ID
	char steam32[32];
	GetClientAuthId(client, AuthId_Steam2, steam32, sizeof(steam32));
	
	//没flags就是普通玩家 返回
	if (flags == 0)
	{
		strcopy(flag, sizeof(flag), "普通玩家");
		Format(g_eClient[client][szAdminFlags], 64, "%s", flag);
		return;
	}
	else
	{	
		//把flags输出到string
		FlagsToString(flagstring, sizeof(flagstring), flags);
	}

	//在String中匹配字符
	if(StrContains(flagstring, "2", false) != -1 )
	{
		if(StrContains(flagstring, "6", false ) != -1 )
			strcopy(flag, sizeof(flag), "SVIP");
		else
			strcopy(flag, sizeof(flag), "VIP");
	}
	else if( StrContains(flagstring, "map", false ) != -1 )
	{
		if ( StrContains(flagstring, "1", false ) != -1 )
			strcopy(flag, sizeof(flag), "高级OP");
		else if ( StrContains(flagstring, "cvar", false ) != -1 )
			strcopy(flag, sizeof(flag), "管理员");
		else
			strcopy(flag, sizeof(flag), "OP");
	}
	else
	{
		strcopy(flag, sizeof(flag), "普通玩家");
	}
	
	if (StrContains(steam32, "44083262", false ) != -1)
		strcopy(flag, sizeof(flag), "服主");
	
	//返回g_ClientFlags
	Format(g_eClient[client][szAdminFlags], 64, "%s", flag);

	return;
}

#define FLAG_STRINGS 14

void FlagsToString(char[] buffer, int maxlength, int flags)
{
	char joins[FLAG_STRINGS+1][32];
	int total;

	for(int i=0; i<FLAG_STRINGS; i++)
	{
		if (flags & (1<<i))
		{
			strcopy(joins[total++], 32, g_szFlagName[i]);
		}
	}
	
	char custom_flags[32];
	if(CustomFlagsToString(custom_flags, sizeof(custom_flags), flags))
	{
		Format(joins[total++], 32, "custom(%s)", custom_flags);
	}

	ImplodeStrings(joins, total, ", ", buffer, maxlength);
}

int CustomFlagsToString(char[] buffer, int maxlength, int flags)
{
	char joins[6][6];
	int total;
	
	for(int i=view_as<int>(Admin_Custom1); i<=view_as<int>(Admin_Custom6); i++)
	{
		if(flags & (1<<i))
		{
			IntToString(i - view_as<int>(Admin_Custom1) + 1, joins[total++], 6);
		}
	}

	ImplodeStrings(joins, total, ",", buffer, maxlength);
	
	return total;
}

