enum GrilsFrontLine
{
    String:szWeapon[32],
    iUseTimes,
    iKills,
    iDeaths,
    iHS,
    iBroken,
    iDamage,
    iTendresse
}

enum GFL_Round
{
    bool:bUsed,
    iRK,
    iRD,
    iRB,
    iRHS,
    iRDMG
}

int GFL_Client_Data[MAXPLAYERS+1][GrilsFrontLine];
int GFL_Client_Round[MAXPLAYERS+1][GFL_Round];

Menu GFL_Menu_Select_Type;
Menu GFL_Menu_Select_Guns;

void GirlsFL_OnAskPluginLoad2()
{
    CreateNative("CG_GFLGetWeaponName", Native_GirlsFL_GetWeaponName);
    CreateNative("CG_GFLGetUseTimes",   Native_GirlsFL_GetUseTimes);
    CreateNative("CG_GFLGetKills",      Native_GirlsFL_GetKills);
    CreateNative("CG_GFLGetDeaths",     Native_GirlsFL_GetDeaths);
    CreateNative("CG_GFLGetHeadshots",  Native_GirlsFL_GetHS);
    CreateNative("CG_GFLGetDamage",     Native_GirlsFL_GetDamage);
    CreateNative("CG_GFLGetBloodieds",  Native_GirlsFL_GetBloodieds);
    CreateNative("CG_GFLGetTendresse",  Native_GirlsFL_GetTendresse);
}

public int Native_GirlsFL_GetWeaponName(Handle plugin, int numParams)
{
    if(SetNativeString(2, GFL_Client_Data[GetNativeCell(1)][szWeapon], GetNativeCell(3)) != SP_ERROR_NONE)
        ThrowNativeError(SP_ERROR_NATIVE, "Can not return GFL weapon name.");
}

public int Native_GirlsFL_GetUseTimes(Handle plugin, int numParams)
{
    return GFL_Client_Data[GetNativeCell(1)][iUseTimes];
}

public int Native_GirlsFL_GetKills(Handle plugin, int numParams)
{
    return GFL_Client_Data[GetNativeCell(1)][iKills];
}

public int Native_GirlsFL_GetDeaths(Handle plugin, int numParams)
{
    return GFL_Client_Data[GetNativeCell(1)][iDeaths];
}

public int Native_GirlsFL_GetTendresse(Handle plugin, int numParams)
{
    return GFL_Client_Data[GetNativeCell(1)][iTendresse];
}

public int Native_GirlsFL_GetHS(Handle plugin, int numParams)
{
    return GFL_Client_Data[GetNativeCell(1)][iHS];
}

public int Native_GirlsFL_GetDamage(Handle plugin, int numParams)
{
    return GFL_Client_Data[GetNativeCell(1)][iDamage];
}

public int Native_GirlsFL_GetBloodieds(Handle plugin, int numParams)
{
    return GFL_Client_Data[GetNativeCell(1)][iBroken];
}

void GirlsFL_OnPluginStart()
{
    RegConsoleCmd("sm_gfl",   Command_GFL);
    RegConsoleCmd("sm_gril",  Command_GFL);
    RegConsoleCmd("sm_grils", Command_GFL);
    
    GirlsFL_PrepareMenu();
}

void GirlsFL_PrepareMenu()
{
    GFL_Menu_Select_Type = new Menu(MenuHandler_GFLTypeMenu);
    GFL_Menu_Select_Type.SetTitle("[GFL]  选择武器类型");
    GFL_Menu_Select_Type.AddItem("00", "HG");
    GFL_Menu_Select_Type.AddItem("10", "SMG");
    GFL_Menu_Select_Type.AddItem("16", "RF");
    GFL_Menu_Select_Type.AddItem("20", "AR");
    GFL_Menu_Select_Type.AddItem("27", "MG");
    GFL_Menu_Select_Type.AddItem("29", "SG");
    GFL_Menu_Select_Type.ExitBackButton = true;
    GFL_Menu_Select_Type.ExitButton = false;
    
    GFL_Menu_Select_Guns = new Menu(MenuHandler_GFLGunsMenu);
    GFL_Menu_Select_Guns.SetTitle("[GFL]  选择武器");
    //HG
    GFL_Menu_Select_Guns.AddItem("cz75a", "CZ75-Auto");
    GFL_Menu_Select_Guns.AddItem("deagle", "Desert Eagle");
    GFL_Menu_Select_Guns.AddItem("elite", "Dual Berettas");
    GFL_Menu_Select_Guns.AddItem("fiveseven", "Five-SeveN");
    GFL_Menu_Select_Guns.AddItem("glock", "Glock-18");
    GFL_Menu_Select_Guns.AddItem("hkp2000", "P2000");
    GFL_Menu_Select_Guns.AddItem("p250", "P250");
    GFL_Menu_Select_Guns.AddItem("revolver", "Revolver R8");
    GFL_Menu_Select_Guns.AddItem("tec9", "Tec-9");
    GFL_Menu_Select_Guns.AddItem("usp_silencer", "USP-S");
    //SMG
    GFL_Menu_Select_Guns.AddItem("mac10", "MAC-10");
    GFL_Menu_Select_Guns.AddItem("bizon", "PP-Bizon");
    GFL_Menu_Select_Guns.AddItem("mp7", "MP7");
    GFL_Menu_Select_Guns.AddItem("p90", "P90");
    GFL_Menu_Select_Guns.AddItem("ump45", "UMP45");
    GFL_Menu_Select_Guns.AddItem("mp9", "MP9");
    //RF
    GFL_Menu_Select_Guns.AddItem("awp", "AWP");
    GFL_Menu_Select_Guns.AddItem("g3sg1", "G3SG1");
    GFL_Menu_Select_Guns.AddItem("ssg08", "SSG08");
    GFL_Menu_Select_Guns.AddItem("scar20", "Scar20");
    //AR
    GFL_Menu_Select_Guns.AddItem("ak47", "AK47");
    GFL_Menu_Select_Guns.AddItem("aug", "AUG");
    GFL_Menu_Select_Guns.AddItem("famas", "FAMAS");
    GFL_Menu_Select_Guns.AddItem("galilar", "GalilAR");
    GFL_Menu_Select_Guns.AddItem("m4a1", "M4A4");
    GFL_Menu_Select_Guns.AddItem("m4a1_silencer", "M4A1-S");
    GFL_Menu_Select_Guns.AddItem("sg556", "SG553");
    //MG
    GFL_Menu_Select_Guns.AddItem("m249", "M249");
    GFL_Menu_Select_Guns.AddItem("negev", "Negev");
    //SG
    GFL_Menu_Select_Guns.AddItem("nova", "Nova");
    GFL_Menu_Select_Guns.AddItem("sawedoff", "Sawed-Off");
    GFL_Menu_Select_Guns.AddItem("xm1014", "XM1014");
    GFL_Menu_Select_Guns.AddItem("mag7", "MAG-7");
}

public Action Command_GFL(int client, int args)
{
    if(!IsValidClient(client))
        return Plugin_Handled;
    
    DisplayGFLMainMenu(client);
    
    return Plugin_Handled;
}

void GirlsFL_OnClientConnected(int client)
{
    GFL_Client_Data[client][szWeapon][0] = '\0';
    GFL_Client_Data[client][iUseTimes]   = 0;
    GFL_Client_Data[client][iKills]      = 0;
    GFL_Client_Data[client][iDeaths]     = 0;
    GFL_Client_Data[client][iBroken]     = 0;
    GFL_Client_Data[client][iHS]         = 0;
    GFL_Client_Data[client][iDamage]     = 0;
    GFL_Client_Data[client][iTendresse]  = 0;
    
    GFL_Client_Round[client][bUsed] = false;
    GFL_Client_Round[client][iRK]   = 0;
    GFL_Client_Round[client][iRD]   = 0;
    GFL_Client_Round[client][iRB]   = 0;
    GFL_Client_Round[client][iRHS]  = 0;
    GFL_Client_Round[client][iRDMG] = 0;
}

void GirlsFL_InitializeGFLData(int client, const char[] weapon, int uses, int kills, int deaths, int bloodieds, int headshots, int damage, int tendresse)
{
    strcopy(GFL_Client_Data[client][szWeapon], 32, weapon);
    GFL_Client_Data[client][iUseTimes]  = uses;
    GFL_Client_Data[client][iKills]     = kills;
    GFL_Client_Data[client][iDeaths]    = deaths;
    GFL_Client_Data[client][iBroken]    = bloodieds;
    GFL_Client_Data[client][iHS]        = headshots;
    GFL_Client_Data[client][iDamage]    = damage;
    GFL_Client_Data[client][iTendresse] = tendresse;
}

void DisplayGFLMainMenu(int client)
{
    if(strcmp(GFL_Client_Data[client][szWeapon], "INVALID_WEAPON") == 0)
    {
        DisplayMenu(GFL_Menu_Select_Type, client, 30);
        return;
    }

    Handle panel = CreatePanel();

    DrawPanelTextEx(panel, "▽ Girls Frontline ▽");
    DrawPanelTextEx(panel, " ");
    DrawPanelTextEx(panel, "枪娘: %s", GFL_Client_Data[client][szWeapon]);
    DrawPanelTextEx(panel, " ");
    DrawPanelTextEx(panel, "好感: %d", GFL_Client_Data[client][iTendresse]);
    DrawPanelTextEx(panel, "使用: %d", GFL_Client_Data[client][iUseTimes]);
    DrawPanelTextEx(panel, "输出: %d", GFL_Client_Data[client][iDamage]);
    DrawPanelTextEx(panel, "击杀: %d", GFL_Client_Data[client][iKills]);
    DrawPanelTextEx(panel, "爆头: %d", GFL_Client_Data[client][iHS]);
    DrawPanelTextEx(panel, "重创: %d", GFL_Client_Data[client][iBroken]);
    DrawPanelTextEx(panel, "死亡: %d", GFL_Client_Data[client][iDeaths]);
    DrawPanelTextEx(panel, " ");
    DrawPanelTextEx(panel, " ");
    DrawPanelItem(panel, "退出");

    SendPanelToClient(panel, client, GirlsFL_DetailesPanel, 30);
}

public int GirlsFL_DetailesPanel(Handle panel, MenuAction action, int client, int itemNum)
{
    if(action == MenuAction_End)
        delete panel;
}

public int MenuHandler_GFLTypeMenu(Menu menu, MenuAction action, int client, int itemNum)
{
    if(action == MenuAction_Select)
    {
        char info[16];
        menu.GetItem(itemNum, info, 16);
        GFL_Menu_Select_Guns.DisplayAt(client, StringToInt(info), 30);
    }
}

public int MenuHandler_GFLGunsMenu(Menu menu, MenuAction action, int client, int itemNum)
{
    if(action == MenuAction_Select)
    {
        char weapon[32];
        menu.GetItem(itemNum, weapon, 32);
        GrilsFL_UpdateClient(client, weapon);
    }
}

void GrilsFL_UpdateClient(int client, const char[] weapon = "INVALID_WEAPON")
{
    if(!g_ClientGlobal[client][bLoaded])
        return;
    
    if(strcmp(GFL_Client_Data[client][szWeapon], "INVALID_WEAPON") == 0)
    {
        if(strcmp(weapon, "INVALID_WEAPON") == 0)
        {
            DisplayGFLMainMenu(client);
            return;
        }
        
        char m_szQuery[128];
        FormatEx(m_szQuery, 128, "REPLACE INTO playertrack_gungirls VALUES (%d, '%s', 0, 0, 0, 0, 0, 0, 0);", g_ClientGlobal[client][iPId], weapon);
        UTIL_SQLTVoid(g_dbGames, m_szQuery);
        strcopy(GFL_Client_Data[client][szWeapon], 32, weapon);
        char upper[32];
        UpperString(weapon, upper, 32);
        PrintToChat(client, "[\x0CCG\x01] ^ \x0EGFL\x01   你已选择[\x04%s\x01]为你的#$%^%#?", upper);
        return;
    }

    if(!GFL_Client_Round[client][bUsed])
        return;

    char m_szQuery[128];
    FormatEx(m_szQuery, 128, "UPDATE playertrack_gungirls SET kills=kills+%d, death=death+%d, bloodied=bloodied+%d, headshots=headshots+%d, damage=damage+%d useTimes=useTimes+1 WHERE pid=%d", GFL_Client_Round[client][iRK], GFL_Client_Round[client][iRD], GFL_Client_Round[client][iRB], GFL_Client_Round[client][iRHS], GFL_Client_Round[client][iRDMG], g_ClientGlobal[client][iPId]);
    UTIL_SQLTVoid(g_dbGames, m_szQuery);
    
    GFL_Client_Data[client][iUseTimes]++;
    GFL_Client_Data[client][iKills]  += GFL_Client_Round[client][iRK];
    GFL_Client_Data[client][iDeaths] += GFL_Client_Round[client][iRD];
    GFL_Client_Data[client][iBroken] += GFL_Client_Round[client][iRB];
    GFL_Client_Data[client][iHS]     += GFL_Client_Round[client][iRHS];
    GFL_Client_Data[client][iDamage] += GFL_Client_Round[client][iRDMG];

    GFL_Client_Round[client][bUsed] = false;
    GFL_Client_Round[client][iRK]   = 0;
    GFL_Client_Round[client][iRD]   = 0;
    GFL_Client_Round[client][iRB]   = 0;
    GFL_Client_Round[client][iRHS]  = 0;
    GFL_Client_Round[client][iRDMG] = 0;
}

void GirlsFL_OnRoundStart()
{
    for(int client = 1; client <= MaxClients; ++client)
    {
        GFL_Client_Round[client][bUsed] = false;
        GFL_Client_Round[client][iRK]   = 0;
        GFL_Client_Round[client][iRD]   = 0;
        GFL_Client_Round[client][iRB]   = 0;
        GFL_Client_Round[client][iRHS]  = 0;
        GFL_Client_Round[client][iRDMG] = 0;
    }
}

void GirlsFL_OnRoundEnd()
{
    for(int client = 1; client <= MaxClients; ++client)
        GrilsFL_UpdateClient(client);
}

void GirlsFL_OnPlayerDeath(int victim, int attacker, bool headshot, const char[] attacker_weapon)
{
    if(strcmp(GFL_Client_Data[attacker][szWeapon], attacker_weapon) == 0)
    {
        GFL_Client_Round[attacker][iRK]++;
        if(headshot)
            GFL_Client_Round[attacker][iRHS]++;
    }

    char victim_weapon[32];
    GetClientWeapon(victim, victim_weapon, 32);
    if(strcmp(GFL_Client_Data[victim][szWeapon], victim_weapon) == 0)
    {
        GFL_Client_Round[victim][iRD]++;
    }
}

void GirlsFL_OnPlayerHurts(int victim, int attacker, int damage, const char[] weapon)
{
    if(strcmp(GFL_Client_Data[attacker][szWeapon], weapon) == 0)
    {
        GFL_Client_Round[attacker][iRDMG] += damage;
    }
    
    if(GFL_Client_Round[victim][bUsed] && GFL_Client_Round[victim][iRB] == 0)
    {
        int max = GetEntProp(victim, Prop_Data, "m_iMaxHealth", 4, 0);
        int cur = GetClientHealth(victim);
        float p = float(max)/float(cur);
        if(p < 0.3)
            GFL_Client_Round[victim][iRB]++;
    }
}

void GirlsFL_OnItemEquip(int client, const char[] weapon)
{
    if(GFL_Client_Round[client][bUsed])
        return;
    
    GFL_Client_Round[client][bUsed] = (strcmp(GFL_Client_Data[client][szWeapon], weapon) == 0);
}