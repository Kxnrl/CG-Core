#include <steamworks>
#include <sourcebans>
#include <sourcecomms>

#pragma newdecls required

ArrayList g_aBlackGroups[2];
ArrayList g_aBlockClient;

int g_iSpamTag[MAXPLAYERS+1];
int g_iCheckTk[MAXPLAYERS+1];
char g_szClantag[MAXPLAYERS+1][32];

public Plugin myinfo =
{
	name		= "[CG] - Block Bad Steam Group",
	author		= "Kyle",
	description = "",
	version		= "1.0",
	url			= "http://steamcommunity.com/id/_xQy_/"
};

public void OnPluginStart()
{
    g_aBlackGroups[0] = CreateArray();
    g_aBlackGroups[1] = CreateArray(ByteCountToCells(32));
    g_aBlockClient    = CreateArray(ByteCountToCells(32));

    // Balck Hacking Group
    g_aBlackGroups[0].Push(103582791455638129); //http://steamcommunity.com/groups/SDYniuB/memberslistxml/?xml=1
    g_aBlackGroups[0].Push(103582791458046138); //http://steamcommunity.com/groups/5044000/memberslistxml/?xml=1
    g_aBlackGroups[0].Push(103582791458662119); //http://steamcommunity.com/groups/rainbowcandy7/memberslistxml/?xml=1
    g_aBlackGroups[0].Push(103582791455441970); //http://steamcommunity.com/groups/woshijilao/memberslistxml/?xml=1
    g_aBlackGroups[0].Push(103582791456788193); //http://steamcommunity.com/groups/zhongguohaolaiwu/memberslistxml/?xml=1
    g_aBlackGroups[0].Push(103582791454558691); //http://steamcommunity.com/groups/sssfffggghhhjr/memberslistxml/?xml=1
    g_aBlackGroups[0].Push(103582791459721846); //http://steamcommunity.com/groups/SBmaoling/memberslistxml/?xml=1
    
    g_aBlackGroups[1].PushString("4=1电竞SDY");
    g_aBlackGroups[1].PushString("【50电竞】");
    g_aBlackGroups[1].PushString("RainbowCandy");
    g_aBlackGroups[1].PushString("woshijilao");
    g_aBlackGroups[1].PushString("大牛影业");
    g_aBlackGroups[1].PushString("中国反作弊");
    g_aBlackGroups[1].PushString("弱智小学生");

    CreateTimer(10.0, Timer_CheckSpamTag, _, TIMER_REPEAT);
}

public Action Timer_CheckSpamTag(Handle timer)
{
    for(int client = 1; client <= MaxClients+1; ++client)
        g_iSpamTag[client] = 0;
    
    return Plugin_Continue;
}

public void OnClientCommandKeyValues_Post(int client, KeyValues kv)
{
    if(g_iSpamTag[client] == -1)
        return;
    
    char szCommmand[32];
    if(KvGetSectionName(kv, szCommmand, 32) && StrEqual(szCommmand, "ClanTagChanged", false))
    {
        int tick = GetGameTickCount();

        if(tick == g_iCheckTk[client])
            return;

        g_iCheckTk[client] = tick;

        char tag[32], name[128];
        KvGetString(kv, "tag", tag, 32);
        KvGetString(kv, "name", name, 128);

        UTIL_LogProcess("OnClientCommandKeyValues_Post", "tick[%d] -> \"%L\" -> %s -> %s", tick, client, tag, name);

        if(strcmp(tag, g_szClantag[client]) == 0)
            return;

        strcopy(g_szClantag[client], 32, tag);

        if(++g_iSpamTag[client] >= 5)
            UTIL_PreBanClientByTag(client);
    }
}

void UTIL_PreBanClientByTag(int client)
{
    char AuthId[32], Nickname[32];

    GetClientAuthId(client, AuthId_Steam2, AuthId, 32, true);
    GetClientName(client, Nickname, 32);

    KickClient(client, "CAT:  \n系统检测到你使用了键位自动更换组标.\n已将你封禁60分钟.\n屡教不改将会导致永久封禁");

    int time = 60;
    
    if(FindStringInArray(g_aBlockClient, AuthId) != -1)
        time = 0;
    else
        g_aBlockClient.PushString(AuthId);

    Handle pack;
    CreateDataTimer(1.0, Timer_BanClient, pack);
    WritePackString(pack, AuthId);
    WritePackString(pack, Nickname);
    WritePackString(pack, "CAT:  ClanTag Spam -> 键位自动更换组标");
    WritePackCell(pack, time);
    ResetPack(pack);
    
    g_iSpamTag[client] = -1;
}

public void OnClientPutInServer(int client)
{
    g_iSpamTag[client] = 0;

    int number = GetArraySize(g_aBlackGroups[0]);
    
    for(int index = 1; index < number; ++index)
        SteamWorks_GetUserGroupStatus(client, g_aBlackGroups[0].Get(index));
}

public int SteamWorks_OnClientGroupStatus(int authid, int groupid, bool isMember, bool isOfficer)
{
    if(!isMember && !isOfficer)
        return;

    int client = FindClientByAuthId(authid);
    
    if(client == -1)
        return;

    int index = g_aBlackGroups[0].FindValue(groupid);
    
    char groupname[32];
    g_aBlackGroups[1].GetString(index, groupname, 32);

    UTIL_LogProcess("SteamWorks_OnClientGroupStatus", "Find client in Group -> \"%L\" -> %d -> %s", client, groupid, groupname);
    UTIL_PreBanClientByGroup(client, groupname, groupid);
}

int FindClientByAuthId(int AuthId)
{
    char steamid[32];

    for(int client = 1; client <= MaxClients+1; ++client)
    {
        if(!IsClientAuthorized(client))
            continue;

        GetClientAuthId(client, AuthId_Engine, steamid, 32);
        
        char part[4];
        SplitString(steamid[8], ":", part, 4);

        if(AuthId == (StringToInt(steamid[10]) << 1) + StringToInt(part))
            return client;
    }

    return -1;
}

void UTIL_PreBanClientByGroup(int client, const char[] groupname, int groupid)
{
    char fmt[128], AuthId[32], Nickname[32];
    
    GetClientAuthId(client, AuthId_Steam2, AuthId, 32, true);
    GetClientName(client, Nickname, 32);

    KickClient(client, "CAT:  \n系统检测到你加入了黑名单组\n%d.[%s]\n作弊狗屡教不改只好封禁咯", groupid, groupname);
    
    FormatEx(fmt, 128, "CAT:  Cheater Group Ban [%s], GroupId[%d]", groupname, groupid);

    Handle pack;
    CreateDataTimer(1.0, Timer_BanClient, pack);
    WritePackString(pack, AuthId);
    WritePackString(pack, Nickname);
    WritePackString(pack, fmt);
    WritePackCell(pack, 0);
    ResetPack(pack);
}

public Action Timer_BanClient(Handle timer, Handle pack)
{
    char AuthId[32], Nickname[32], Reason[128];
    
    ReadPackString(pack, AuthId, 32);
    ReadPackString(pack, Nickname, 32);
    ReadPackString(pack, Reason, 128);
    
    int time = ReadPackCell(pack);

    SBAddBan(0, time, AuthId, Nickname, Reason);

    return Plugin_Stop;
}

void UTIL_LogProcess(const char[] funcname, const char[] buffer, any ...)
{
    char fmt[512];
    VFormat(fmt, 512, buffer, 3);
    LogToFileEx("addons/sourcemod/data/blackgroup.log", "%s -> %s", funcname, fmt);
}

public void OnClientSayCommand_Post(int client, const char[] command, const char[] sArgs)
{
    if(!client)
        return;
    
    if( 
        StrContains(sArgs, "打官匹吗") != -1 ||
        StrContains(sArgs, "打竞技吗") != -1 ||
        StrContains(sArgs, "去官匹吗") != -1 ||
        StrContains(sArgs, "去竞技吗") != -1 ||
        StrContains(sArgs, "打不打官匹") != -1 ||
        StrContains(sArgs, "打不打竞技") != -1
        )
        CheckClientCompetitive(client);
}

void CheckClientCompetitive(int client)
{
    UTIL_LogProcess("CheckClientCompetitive", "Client invite others to competitive -> \"%L\"", client);
    
    for(int admin = 1; admin <= MaxClients; admin++)
        if(IsClientInGame(admin))
            if(CheckCommandAccess(admin, "sm_ban", ADMFLAG_BAN, false))
                UTIL_LogProcess("CheckClientCompetitive", "Client invite others to competitive -> \"%L\" -> admin -> \"%L\"", client, admin);
            
    SourceComms_SetClientMute(client, true, 0, true, "CAT: 在服务器里面打广告/拉人");
    SourceComms_SetClientGag(client, true, 0, true, "CAT: 在服务器里面打广告/拉人");
}