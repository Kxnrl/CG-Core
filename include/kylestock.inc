#include <sdktools>

stock void RemoveCharFromName(char[] code, int maxLen)
{
    ReplaceString(code, maxLen, "◇", "");
    ReplaceString(code, maxLen, "◆", "");
    ReplaceString(code, maxLen, "☆", "");
    ReplaceString(code, maxLen, "★", "");
    ReplaceString(code, maxLen, "✪", "");
    ReplaceString(code, maxLen, "♜", "");
    ReplaceString(code, maxLen, "♚", "");
    ReplaceString(code, maxLen, "♪", "");
    ReplaceString(code, maxLen, "♬", "");
    ReplaceString(code, maxLen, "'", "");
    ReplaceString(code, maxLen, "\"", "");
    ReplaceString(code, maxLen, "\\", "");
    ReplaceString(code, maxLen, "^", "");
    ReplaceString(code, maxLen, "(", "");
    ReplaceString(code, maxLen, ")", "");
    ReplaceString(code, maxLen, "`", "");
    ReplaceString(code, maxLen, ";", "");
    ReplaceString(code, maxLen, "☀", "");
    ReplaceString(code, maxLen, "▪", "");
    ReplaceString(code, maxLen, "♩", "");
    ReplaceString(code, maxLen, "♭", "");
    ReplaceString(code, maxLen, "♈", "");
    ReplaceString(code, maxLen, "*", "");
    ReplaceString(code, maxLen, "✄", "");
    ReplaceString(code, maxLen, "☎", "");
    ReplaceString(code, maxLen, "✈", "");
    ReplaceString(code, maxLen, "☬", "");
    ReplaceString(code, maxLen, "▽", "");
    ReplaceString(code, maxLen, "▼", "");
    ReplaceString(code, maxLen, "☽", "");
    ReplaceString(code, maxLen, "☾", "");
    ReplaceString(code, maxLen, "•", "");
    ReplaceString(code, maxLen, "♪", "");
    ReplaceString(code, maxLen, "♯", "");
    ReplaceString(code, maxLen, "♉", "");
    ReplaceString(code, maxLen, "＊", "");
    ReplaceString(code, maxLen, "✁", "");
    ReplaceString(code, maxLen, "ஐ", "");
    ReplaceString(code, maxLen, "〠", "");
    ReplaceString(code, maxLen, "♔", "");
    ReplaceString(code, maxLen, "○", "");
    ReplaceString(code, maxLen, "●", "");
    ReplaceString(code, maxLen, "♀", "");
    ReplaceString(code, maxLen, "♂", "");
    ReplaceString(code, maxLen, "‥", "");
    ReplaceString(code, maxLen, "♫", "");
    ReplaceString(code, maxLen, "♮", "");
    ReplaceString(code, maxLen, "♊", "");
    ReplaceString(code, maxLen, "✲", "");
    ReplaceString(code, maxLen, "✌", "");
    ReplaceString(code, maxLen, "☩", "");
    ReplaceString(code, maxLen, "۩", "");
    ReplaceString(code, maxLen, "☺", "");
    ReplaceString(code, maxLen, "☹", "");
    ReplaceString(code, maxLen, "…", "");
    ReplaceString(code, maxLen, "♬", "");
    ReplaceString(code, maxLen, "‖", "");
    ReplaceString(code, maxLen, "♋", "");
    ReplaceString(code, maxLen, "❈", "");
    ReplaceString(code, maxLen, "✍", "");
    ReplaceString(code, maxLen, "➹", "");
    ReplaceString(code, maxLen, "✙", "");
    ReplaceString(code, maxLen, "♕", "");
    ReplaceString(code, maxLen, "□", "");
    ReplaceString(code, maxLen, "■", "");
    ReplaceString(code, maxLen, "◐", "");
    ReplaceString(code, maxLen, "◑", "");
    ReplaceString(code, maxLen, "▁", "");
    ReplaceString(code, maxLen, "§", "");
    ReplaceString(code, maxLen, "¶", "");
    ReplaceString(code, maxLen, "♌", "");
    ReplaceString(code, maxLen, "❉", "");
    ReplaceString(code, maxLen, "✎", "");
    ReplaceString(code, maxLen, "〄", "");
    ReplaceString(code, maxLen, "✟", "");
    ReplaceString(code, maxLen, "♛", "");
    ReplaceString(code, maxLen, "☑", "");
    ReplaceString(code, maxLen, "☒", "");
    ReplaceString(code, maxLen, "▂", "");
    ReplaceString(code, maxLen, "〼", "");
    ReplaceString(code, maxLen, "卍", "");
    ReplaceString(code, maxLen, "♎", "");
    ReplaceString(code, maxLen, "✿", "");
    ReplaceString(code, maxLen, "₪", "");
    ReplaceString(code, maxLen, "☮", "");
    ReplaceString(code, maxLen, "☤", "");
    ReplaceString(code, maxLen, "♗", "");
    ReplaceString(code, maxLen, "◁", "");
    ReplaceString(code, maxLen, "▶", "");
    ReplaceString(code, maxLen, "√", "");
    ReplaceString(code, maxLen, "×", "");
    ReplaceString(code, maxLen, "▃", "");
    ReplaceString(code, maxLen, "◎", "");
    ReplaceString(code, maxLen, "卐", "");
    ReplaceString(code, maxLen, "♏", "");
    ReplaceString(code, maxLen, "❀", "");
    ReplaceString(code, maxLen, "ி", "");
    ReplaceString(code, maxLen, "☪", "");
    ReplaceString(code, maxLen, "☥", "");
    ReplaceString(code, maxLen, "♝", "");
    ReplaceString(code, maxLen, "▷", "");
    ReplaceString(code, maxLen, "◀", "");
    ReplaceString(code, maxLen, "✔", "");
    ReplaceString(code, maxLen, "✘", "");
    ReplaceString(code, maxLen, "▄", "");
    ReplaceString(code, maxLen, "¤", "");
    ReplaceString(code, maxLen, "▬", "");
    ReplaceString(code, maxLen, "♐", "");
    ReplaceString(code, maxLen, "❃", "");
    ReplaceString(code, maxLen, "❧", "");
    ReplaceString(code, maxLen, "❂", "");
    ReplaceString(code, maxLen, "☦", "");
    ReplaceString(code, maxLen, "♘", "");
    ReplaceString(code, maxLen, "♤", "");
    ReplaceString(code, maxLen, "♠", "");
    ReplaceString(code, maxLen, "☜", "");
    ReplaceString(code, maxLen, "☚", "");
    ReplaceString(code, maxLen, "▅", "");
    ReplaceString(code, maxLen, "۞", "");
    ReplaceString(code, maxLen, "〓", "");
    ReplaceString(code, maxLen, "♑", "");
    ReplaceString(code, maxLen, "❁", "");
    ReplaceString(code, maxLen, "❦", "");
    ReplaceString(code, maxLen, "☭", "");
    ReplaceString(code, maxLen, "☧", "");
    ReplaceString(code, maxLen, "♞", "");
    ReplaceString(code, maxLen, "♡", "");
    ReplaceString(code, maxLen, "♥", "");
    ReplaceString(code, maxLen, "☝", "");
    ReplaceString(code, maxLen, "☟", "");
    ReplaceString(code, maxLen, "▆", "");
    ReplaceString(code, maxLen, "℗", "");
    ReplaceString(code, maxLen, "℡", "");
    ReplaceString(code, maxLen, "♓", "");
    ReplaceString(code, maxLen, "☸", "");
    ReplaceString(code, maxLen, "ღ", "");
    ReplaceString(code, maxLen, "☠", "");
    ReplaceString(code, maxLen, "☨", "");
    ReplaceString(code, maxLen, "♖", "");
    ReplaceString(code, maxLen, "♢", "");
    ReplaceString(code, maxLen, "♦", "");
    ReplaceString(code, maxLen, "☞", "");
    ReplaceString(code, maxLen, "☛", "");
    ReplaceString(code, maxLen, "█", "");
    ReplaceString(code, maxLen, "®", "");
    ReplaceString(code, maxLen, "™", "");
    ReplaceString(code, maxLen, "♒", "");
    ReplaceString(code, maxLen, "❁", "");
    ReplaceString(code, maxLen, "❤", "");
    ReplaceString(code, maxLen, "☣", "");
    ReplaceString(code, maxLen, "☫", "");
    ReplaceString(code, maxLen, "♧", "");
    ReplaceString(code, maxLen, "♣", "");
    ReplaceString(code, maxLen, "㏂", "");
    ReplaceString(code, maxLen, "㏘", "");
    ReplaceString(code, maxLen, "█", "");
    ReplaceString(code, maxLen, "©", "");
    ReplaceString(code, maxLen, "㏇", "");
    ReplaceString(code, maxLen, "♍", "");
    ReplaceString(code, maxLen, "✖", "");
    ReplaceString(code, maxLen, "☢", "");
    ReplaceString(code, maxLen, "✚", "");
    ReplaceString(code, maxLen, "♙", "");
    ReplaceString(code, maxLen, "♟", "");
    ReplaceString(code, maxLen, "☁", "");
    ReplaceString(code, maxLen, "☂", "");
    ReplaceString(code, maxLen, "☃", "");
    ReplaceString(code, maxLen, "初音", ".");
    ReplaceString(code, maxLen, "ミク", ".");
}

stock void FriendIDtoSteamID(const char[] szSteam64, char[] szSteam2, int iLen)
{
    char[] szBase = "76561197960265728";
    char szSteam[18], szAccount[18];
    int iBorrow, iY, iZ, iTemp;

    strcopy(szSteam, 18, szSteam64);

    if(CharToNumber(szSteam[16]) % 2 == 1)
    {
        iY = 1;
        szSteam[16] = NumberToChar(CharToNumber(szSteam[16]) - 1);
    }
    
    for(int k = 16; k >= 0; k--)
    {
        if (iBorrow > 0)
        {
            iTemp = CharToNumber(szSteam[k]) - 1;
            
            if (iTemp >= CharToNumber(szBase[k]))
            {
                iBorrow = 0;
                szAccount[k] = NumberToChar(iTemp - CharToNumber(szBase[k]));
            }
            else
            {
                iBorrow = 1;
                szAccount[k] = NumberToChar((iTemp + 10) - CharToNumber(szBase[k]));
            }
        }
        else
        {
            if (CharToNumber(szSteam[k]) >= CharToNumber(szBase[k]))
            {
                iBorrow = 0;
                szAccount[k] = NumberToChar(CharToNumber(szSteam[k]) - CharToNumber(szBase[k]));
            }
            else
            {
                iBorrow = 1;
                szAccount[k] = NumberToChar((CharToNumber(szSteam[k]) + 10) - CharToNumber(szBase[k]));
            }
        }
    }
    
    iZ = StringToInt(szAccount);
    iZ /= 2;
    
    FormatEx(szSteam2, iLen, "STEAM_1:%d:%d", iY, iZ);
}

stock int NumberToChar(const int iNum)
{
    return '0' + ((iNum >= 0 && iNum <= 9) ? iNum : 0);
}

stock int CharToNumber(const int cNum)
{
    return (cNum >= '0' && cNum <= '9') ? (cNum - '0') : 0;
}

void Chat(int client, const char[] message, any ...)
{
    char m_szBuffer[512];
    VFormat(m_szBuffer, 512, message, 3);
    Format(m_szBuffer, 512, "[\x0CCG\x01]  %s", m_szBuffer);

    Handle pb = StartMessageOne("SayText2", client);
    PbSetInt(pb, "ent_idx", 0);
    PbSetBool(pb, "chat", false);
    PbSetString(pb, "msg_name", m_szBuffer);
    PbAddString(pb, "params", "");
    PbAddString(pb, "params", "");
    PbAddString(pb, "params", "");
    PbAddString(pb, "params", "");
    EndMessage();
}

void ChatAll(const char[] message, any ...)
{
    char m_szBuffer[512];
    VFormat(m_szBuffer, 512, message, 2);
    Format(m_szBuffer, 512, "[\x0CCG\x01]  %s", m_szBuffer);

    Handle pb = StartMessageAll("SayText2");
    PbSetInt(pb, "ent_idx", 0);
    PbSetBool(pb, "chat", false);
    PbSetString(pb, "msg_name", m_szBuffer);
    PbAddString(pb, "params", "");
    PbAddString(pb, "params", "");
    PbAddString(pb, "params", "");
    PbAddString(pb, "params", "");
    EndMessage();
}

stock bool IsValidClient(int client)
{
    if(!(1 <= client <= MaxClients))
        return false;

    if(!IsClientInGame(client))
        return false;

    if(IsFakeClient(client))
        return false;

    return true;
}

stock void SetMenuTitleEx(Handle menu, const char[] fmt, any ...)
{
    char m_szBuffer[256];
    VFormat(m_szBuffer, 256, fmt, 3);
    Format(m_szBuffer, 256, "%s\n　", m_szBuffer);
    SetMenuTitle(menu, m_szBuffer);
}

stock bool AddMenuItemEx(Handle menu, int style, const char[] info, const char[] display, any ...)
{
    char m_szBuffer[256];
    VFormat(m_szBuffer, 256, display, 5);
    return AddMenuItem(menu, info, m_szBuffer, style);
}