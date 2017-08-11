int MenuCmds_PlayListCurIndex[MAXPLAYERS+1];
int MenuCmds_PlayListCooldown[MAXPLAYERS+1];
Handle MenuCmds_GlobalMenuHandler;

void MenuCmds_OnPluginStart()
{
    //Create console command
    RegConsoleCmd("sm_online",       Command_Online);
    RegConsoleCmd("sm_track",        Command_Track);
    RegConsoleCmd("sm_players",      Command_Players);
    RegConsoleCmd("sm_cg",           Command_Menu);

    //Createe admin command
    RegAdminCmd("sm_reloadadv",      Command_ReloadAdv,   ADMFLAG_BAN);
    RegAdminCmd("sm_reloadcache",    Command_ReloadCache, ADMFLAG_BAN);

    //Add command listener
    AddCommandListener(Command_Status, "status");

    //Create Global Menu
    Handle menu = CreateMenu(MenuHandler_CGMainMenu);
    SetMenuTitleEx(menu, "[CG]  主菜单");
    SetMenuExitButton(menu, true);
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "store",  "打开商店菜单[购买皮肤/名字颜色/翅膀等道具]");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "talent", "打开天赋菜单[选择/分配你的天赋]");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "lily",   "打开CP菜单[进行CP配对/加成等功能]");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "sign",   "进行每日签到[签到可以获得相应的奖励]");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "auth",   "打开认证菜单[申请玩家认证]");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "vip",    "打开VIP菜单[年费/永久VIP可用]");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "rule",   "查看规则[当前服务器规则]");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "group",  "官方组[查看组页面]");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "forum",  "官方论坛[https://csgogamers.com]");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "music",  "音乐菜单[点歌/听歌]");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "online", "在线时间[显示你的在线统计]");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "setrp",  "分辨率[设置游戏内浏览器分辨率]");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "lang",   "选择你的语言");
    MenuCmds_GlobalMenuHandler = menu;
}

public Action Command_ReloadAdv(int client, int args)
{
    //Re-build server advertisment cache
    char m_szQuery[128];
    Format(m_szQuery, 128, "SELECT * FROM playertrack_adv WHERE sid = '%i' OR sid = '0'", g_iServerId);
    MySQL_Query(false, SQLCallback_GetAdvData, m_szQuery, _, DBPrio_High);
    PrintToChatAll("[\x0CCG\x01]   \x04已刷新服务器Tips数据缓存");
    return Plugin_Handled;
}

public Action Command_ReloadCache(int client, int args)
{
    //Re-build server forum data cache
    CreateTimer(2.0, Timer_RefreshData);
    PrintToChatAll("[\x0CCG\x01]   \x04已刷新服务器用户数据缓存");
    return Plugin_Handled;
}

public Action Command_Online(int client, int args)
{
    if(!IsValidClient(client) || !g_ClientGlobal[client][bLoaded])
        return Plugin_Handled;

    int m_iHours = g_ClientGlobal[client][iOnline] / 3600;
    int m_iMins = g_ClientGlobal[client][iOnline] % 3600;
    PrintToChat(client, "[\x0CCG\x01]   尊贵的CG玩家\x04%N\x01,你已经在CG社区进行了\x0C%d\x01小时\x0C%d\x01分钟的游戏(\x02%d\x01次连线)", client, m_iHours, m_iMins/60, g_ClientGlobal[client][iNumber]);

    return Plugin_Handled;
}

public Action Command_Status(int client, const char[] command, int argc)
{
    PrintToChatAll("[\x0CCG\x01]   服务器已屏蔽\x07status\x01指令,输入\x07!players\x01可查看详细信息");
    return Plugin_Handled;
}

public Action Command_Track(int client, int args)
{
    if(!IsValidClient(client))
        return Plugin_Handled;

    PrintToChat(client, "[\x0CCG\x01]   当前已在服务器内\x04%d\x01人,已建立连接的玩家\x02%d\x01人,输入\x07!players\x01可查看详细信息", GetClientCount(true), GetClientCount(false));

    return Plugin_Handled;
}

public Action  Command_Players(int client, int args)
{
    if(!IsValidClient(client))
        return Plugin_Handled;

    if(MenuCmds_PlayListCurIndex[client] != 0)
        return Plugin_Handled;
    
    if(MenuCmds_PlayListCooldown[client] > GetTime())
    {
        PrintToChat(client, "[\x0CCG\x01]   \x07请勿频繁使用该指令...");
        return Plugin_Handled;
    }
    
    MenuCmds_PlayListCooldown[client] = GetTime() + 45;

    MenuCmds_PlayListCurIndex[client] = 1;

    PrintToChat(client, "[\x0CCG\x01]   请查看控制台输出");

    PrintToConsole(client, "#userid    PID    UID   玩家   论坛名称   steam32   steam64    认证    VIP\n========================================================================================");

    CreateTimer(0.1, Timer_PrintPlayerList, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

    return Plugin_Handled;
}

public Action Timer_PrintPlayerList(Handle timer, int client)
{
    if(!IsValidClient(client) || MenuCmds_PlayListCurIndex[client] == MaxClients)
    {
        MenuCmds_PlayListCurIndex[client] = 0;
        return Plugin_Stop;
    }

    int start = MenuCmds_PlayListCurIndex[client];
    int end = MenuCmds_PlayListCurIndex[client]+4;
    if(end > MaxClients)
        end = MaxClients;
    
    char szItem[512], szAuth32[32], szAuth64[64];

    for(int i = start; i <= end; ++i)
    {
        if(IsClientConnected(i) && !IsFakeClient(i))
        {
            if(IsClientInGame(i))
            {
                GetClientAuthId(i, AuthId_Steam2, szAuth32, 32, true);
                GetClientAuthId(i, AuthId_SteamID64, szAuth64, 64, true);
                Format(szItem, 512, " %d    %d    %d    %N    %s    %s    %s    %s    %s", GetClientUserId(i), g_ClientGlobal[i][iPId], g_ClientGlobal[i][iUId], i, g_ClientGlobal[i][szForumName], szAuth32, szAuth64, g_ClientGlobal[i][szGroupName], g_ClientGlobal[i][bVip] ? "Y" : "N");
                PrintToConsole(client, szItem);
            }
        }
        MenuCmds_PlayListCurIndex[client] = i;
    }

    return Plugin_Continue;
}

public Action Command_Menu(int client, int args)
{
    if(!IsValidClient(client))
        return Plugin_Handled;

    MenuCmds_DisplayGlobalMenu(client, -1);

    return Plugin_Handled;
}

void MenuCmds_DisplayGlobalMenu(int client, int last)
{
    if(last == -1) DisplayMenu(MenuCmds_GlobalMenuHandler, client, 0);
    else DisplayMenuAtItem(MenuCmds_GlobalMenuHandler, client, (last/GetMenuPagination(MenuCmds_GlobalMenuHandler))*GetMenuPagination(MenuCmds_GlobalMenuHandler), 0);
}

public int MenuHandler_CGMainMenu(Handle menu, MenuAction action, int client, int itemNum) 
{
    if(action == MenuAction_Select) 
    {
        char info[32];
        GetMenuItem(menu, itemNum, info, 32);
        
        if(!strcmp(info, "store"))
            FakeClientCommand(client, "sm_store");
        else if(!strcmp(info, "lily"))
            Command_Couples(client, 0);
        else if(!strcmp(info, "talent"))
            FakeClientCommand(client, "sm_talent");
        else if(!strcmp(info, "sign"))
        {
            Command_Login(client, 0);
            MenuCmds_DisplayGlobalMenu(client, itemNum);
        }
        else if(!strcmp(info, "auth"))
            Command_GetAuth(client, 0);
        else if(!strcmp(info, "vip"))
            FakeClientCommand(client, "sm_vip");
        else if(!strcmp(info, "rule"))
            FakeClientCommand(client, "sm_rules");
        else if(!strcmp(info, "group"))
            FakeClientCommand(client, "sm_group");
        else if(!strcmp(info, "forum"))
            FakeClientCommand(client, "sm_forum");
        else if(!strcmp(info, "music"))
            FakeClientCommand(client, "sm_music");
        else if(!strcmp(info, "online"))
        {
            Command_Online(client, 0);
            MenuCmds_DisplayGlobalMenu(client, itemNum);
        }
        else if(!strcmp(info, "setrp"))
            FakeClientCommand(client, "sm_setrp");
        else if(!strcmp(info, "lang"))
        {
            switch(GetClientLanguage(client))
            {
                case 0:
                {
                    SetClientLanguage(client, 23);
                    PrintToChat(client, "[\x0CCG\x01]   你的语言已切换为\x04简体中文");
                }
                case 23:
                {
                    SetClientLanguage(client, 27);
                    PrintToChat(client, "[\x0CCG\x01]   你的語言已經切換到\x04繁體中文");
                }
                case 27:
                {
                    SetClientLanguage(client, 0);
                    PrintToChat(client, "[\x0CCG\x01]   you language has been changed to \x04English");
                }
            }
            MenuCmds_DisplayGlobalMenu(client, itemNum);
        }
    }
}