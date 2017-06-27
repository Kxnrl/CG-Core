enum Signature
{
    bool:bListener,
    Handle:hListener,
    String:szNewSignature[256],
}

Signature Signature_Data_Client[MAXPLAYERS+1][Signature];

void Signature_OnPluginStart()
{
    RegConsoleCmd("sm_qm", Command_Signature);
}

void Signature_OnClientConnected(int client)
{
    Signature_Data_Client[client][bListener]         = false;
    Signature_Data_Client[client][hListener]         = INVALID_HANDLE;
    Signature_Data_Client[client][szNewSignature][0] = '\0';
}

public Action Command_Signature(int client, int args)
{
    if(StrContains(g_ClientGlobal[client][szSignature], "该玩家未设置签名") != -1)
    {
        Chat(client, "首次设置签名免费!");
        BuildListenerMenu(client);
        return Plugin_Handled;
    }

    if(OnAPIStoreGetCredits(client) < 500)
    {
        Chat(client, "\x04信用点不足,不能设置签名");
        return Plugin_Handled;
    }

    BuildListenerMenu(client);
    
    return Plugin_Handled;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
    if(!Signature_Data_Client[client][bListener])
        return Plugin_Continue;
    
    strcopy(Signature_Data_Client[client][szNewSignature], 256, sArgs);
    
    Chat(client, "你当前已输入: \n %s", sArgs);

    Signature_Data_Client[client][bListener] = false;

    if(g_ClientGlobal[client][hListener] != INVALID_HANDLE)
    {
        KillTimer(g_ClientGlobal[client][hListener]);
        g_ClientGlobal[client][hListener] = INVALID_HANDLE;
    }
    
    BuildListenerMenu(client);

    return Plugin_Handled;
}

void BuildListenerMenu(int client)
{
    Handle menu = CreateMenu(MenuHandler_Listener);
    SetMenuTitleEx(menu, "[CG]  %T", "signature title", client);

    AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "%T", "signature now you can type", client);
    AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "%T", "signature color codes", client);
    AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "%T", "signature example", client);
    AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "%T", "signature input preview", client, Signature_Data_Client[client][szNewSignature]);
    
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "preview", "%T", "signature item preview", client);
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "ok", "%T", "signature item ok", client);
    
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, client, 60);

    if(g_ClientGlobal[client][hListener] != INVALID_HANDLE)
    {
        KillTimer(g_ClientGlobal[client][hListener]);
        g_ClientGlobal[client][hListener] = INVALID_HANDLE;
    }

    Signature_Data_Client[client][bListener] = true;
    g_ClientGlobal[client][hListener] = CreateTimer(60.0, Timer_ListenerTimeout, client);
}

public int MenuHandler_Listener(Handle menu, MenuAction action, int client, int itemNum)
{
    if(action == MenuAction_Select) 
    {
        char info[32];
        GetMenuItem(menu, itemNum, info, 32);
        
        Signature_Data_Client[client][bListener] = false;
        if(g_ClientGlobal[client][hListener] != INVALID_HANDLE)
        {
            KillTimer(g_ClientGlobal[client][hListener]);
            g_ClientGlobal[client][hListener] = INVALID_HANDLE;
        }
        
        if(StrEqual(info, "preview"))
        {
            char m_szPreview[256];
            strcopy(m_szPreview, 256, Signature_Data_Client[client][szNewSignature]);
            ReplaceString(m_szPreview, 512, "{白}", "\x01");
            ReplaceString(m_szPreview, 512, "{红}", "\x02");
            ReplaceString(m_szPreview, 512, "{粉}", "\x03");
            ReplaceString(m_szPreview, 512, "{绿}", "\x04");
            ReplaceString(m_szPreview, 512, "{黄}", "\x05");
            ReplaceString(m_szPreview, 512, "{亮绿}", "\x06");
            ReplaceString(m_szPreview, 512, "{亮红}", "\x07");
            ReplaceString(m_szPreview, 512, "{灰}", "\x08");
            ReplaceString(m_szPreview, 512, "{褐}", "\x09");
            ReplaceString(m_szPreview, 512, "{橙}", "\x10");
            ReplaceString(m_szPreview, 512, "{紫}", "\x0E");
            ReplaceString(m_szPreview, 512, "{亮蓝}", "\x0B");
            ReplaceString(m_szPreview, 512, "{蓝}", "\x0C");
            Chat(client, "签名预览: %s", m_szPreview);
            BuildListenerMenu(client);
        }
        if(StrEqual(info, "ok"))
        {
            if(!OnAPIStoreSetCredits(client, -500, "设置签名", true))
            {
                Chat(client, "\x07信用点不足,不能设置签名");
                return;
            }
            
            char auth[32], eSignature[512], m_szQuery[1024];
            GetClientAuthId(client, AuthId_Steam2, auth, 32, true);
            SQL_EscapeString(Database_DBHandle_Games, Signature_Data_Client[client][szNewSignature], eSignature, 512);
            Format(m_szQuery, 512, "UPDATE `playertrack_player` SET signature = '%s' WHERE id = '%d' and steamid = '%s'", eSignature, g_ClientGlobal[client][iPId], auth);
            Handle data = CreateDataPack();
            WritePackString(data, m_szQuery);
            WritePackCell(data, 0);
            ResetPack(data);
            MySQL_Query(false, Database_SQLCallback_SaveDatabase, m_szQuery, data);
            Chat(client, "\x04已成功设置您的签名,花费了\x10500\x04信用点");
            strcopy(g_ClientGlobal[client][szSignature], 256, Signature_Data_Client[client][szNewSignature]);
            ReplaceString(Signature_Data_Client[client][szNewSignature], 512, "{白}", "\x01");
            ReplaceString(Signature_Data_Client[client][szNewSignature], 512, "{红}", "\x02");
            ReplaceString(Signature_Data_Client[client][szNewSignature], 512, "{粉}", "\x03");
            ReplaceString(Signature_Data_Client[client][szNewSignature], 512, "{绿}", "\x04");
            ReplaceString(Signature_Data_Client[client][szNewSignature], 512, "{黄}", "\x05");
            ReplaceString(Signature_Data_Client[client][szNewSignature], 512, "{亮绿}", "\x06");
            ReplaceString(Signature_Data_Client[client][szNewSignature], 512, "{亮红}", "\x07");
            ReplaceString(Signature_Data_Client[client][szNewSignature], 512, "{灰}", "\x08");
            ReplaceString(Signature_Data_Client[client][szNewSignature], 512, "{褐}", "\x09");
            ReplaceString(Signature_Data_Client[client][szNewSignature], 512, "{橙}", "\x10");
            ReplaceString(Signature_Data_Client[client][szNewSignature], 512, "{紫}", "\x0E");
            ReplaceString(Signature_Data_Client[client][szNewSignature], 512, "{亮蓝}", "\x0B");
            ReplaceString(Signature_Data_Client[client][szNewSignature], 512, "{蓝}", "\x0C");
            Chat(client, "您的签名: %s", Signature_Data_Client[client][szNewSignature]);
        }
    }
    else if(action == MenuAction_End)
        CloseHandle(menu);
}

public Action Timer_ListenerTimeout(Handle timer, int client)
{
    g_ClientGlobal[client][hListener] = INVALID_HANDLE;
    Signature_Data_Client[client][bListener] = false;
    
    return Plugin_Stop;
}