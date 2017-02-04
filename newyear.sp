#include <cg_core>
#include <maoling>
#include <emitsoundany>
#include <smlib>

char sndFireworks1[] = "cg/firework/firework_1.mp3";
char sndFireworks2[] = "cg/firework/firework_2.mp3";
char sndFireworks3[] = "cg/firework/firework_3.mp3";
char sndFireworks4[] = "cg/firework/firework_4.mp3";

bool g_bRound;

stock void PrecacheSoundAnyDownload(char[] sSound)
{
	PrecacheSoundAny(sSound);
	
	char sBuffer[256];
	Format(sBuffer, 256, "sound/%s", sSound);
	AddFileToDownloadsTable(sBuffer);
}

public void OnMapStart()
{
	g_bRound = false;

	PrecacheSoundAnyDownload(sndFireworks1);
	PrecacheSoundAnyDownload(sndFireworks2);
	PrecacheSoundAnyDownload(sndFireworks3);
	PrecacheSoundAnyDownload(sndFireworks4);
}

public void CG_OnRoundStart()
{
	g_bRound = true;
}

public void CG_OnRoundEnd(int winner)
{
	g_bRound = false;
	Fireworks();
	CreateTimer(2.0, Timer_Fireworks, _, TIMER_REPEAT);
}

public Action Timer_Fireworks(Handle timer)
{
	if(!g_bRound)
	{
		Fireworks();
		return Plugin_Continue;
	}

	return Plugin_Stop;
}

void Fireworks()
{
	int client = Client_GetRandom(CLIENTFILTER_INGAME|CLIENTFILTER_ALIVE);
	
	if(client <= 0)
		return;
	
	float m_fOrigin[3], m_fDir[3];
	GetClientAbsOrigin(client, m_fOrigin);
	
	float FireworkHeight;
	FireworkHeight = GetRandomFloat(400.0, 600.0);
	m_fOrigin[2] = (m_fOrigin[2] + FireworkHeight);
	
	switch(GetRandomInt(1, 4))
	{
		case 1: EmitSoundToAllAny(sndFireworks1, _, _, SNDLEVEL_DRYER, _, SNDVOL_NORMAL, _, _, _, _, _, _);
		case 2: EmitSoundToAllAny(sndFireworks2, _, _, SNDLEVEL_DRYER, _, SNDVOL_NORMAL, _, _, _, _, _, _); 
		case 3: EmitSoundToAllAny(sndFireworks3, _, _, SNDLEVEL_DRYER, _, SNDVOL_NORMAL, _, _, _, _, _, _); 
		case 4: EmitSoundToAllAny(sndFireworks4, _, _, SNDLEVEL_DRYER, _, SNDVOL_NORMAL, _, _, _, _, _, _); 
	}

	switch(GetRandomInt(1, 3))
	{
		case 1:
		{
			TE_SetupSparks(m_fOrigin, m_fDir, 1000, 1000);
			TE_SendToAll();
		}
		case 2:
		{
			float g_fAir[3];
		
			TE_SetupSparks(m_fOrigin, m_fDir, 1000, 1000);
			TE_SendToAll();
			
			AddVectors(m_fOrigin, g_fAir, g_fAir);
			g_fAir[2] = (g_fAir[2] - 50.0);
			g_fAir[1] = (g_fAir[1] + 100.0);
			
			TE_SetupSparks(g_fAir, m_fDir, 1000, 1000);
			TE_SendToAll();
		}
		case 3:
		{
			float m_fAir[3];
		
			TE_SetupSparks(m_fOrigin, m_fDir, 1000, 1000);
			TE_SendToAll();
			
			AddVectors(m_fOrigin, m_fAir, m_fAir);
			m_fAir[2] = (m_fAir[2] - 50.0);
			m_fAir[1] = (m_fAir[1] + 100.0);
			
			TE_SetupSparks(m_fOrigin, m_fDir, 1000, 1000);
			TE_SendToAll();

			m_fAir[2] = (m_fAir[2] + 25.0);
			m_fAir[0] = (m_fAir[0] + 100.0);
			
			TE_SetupSparks(m_fOrigin, m_fDir, 1000, 1000);
			TE_SendToAll();
		}
	}
	
	PrintHintTextToAll("<font size='25' color='#0066CC'>CG社区管理团队恭祝所有玩家</font>\n<font size='35' color='#993300'>        鸡年大吉");
}