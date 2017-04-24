#undef REQUIRE_EXTENSIONS
#include <sdktools>
#include <cstrike>
#define REQUIRE_EXTENSIONS

//////////////////////////////
//			ENUMS			// 
//////////////////////////////
//玩家数据
enum Clients
{
	iUID,
	iGetShare,
	iSignNum,
	iSignTime,
	iConnectTime,
	iPlayerId,
	iNumber,
	iOnline,
	iVitality,
	iLastseen,
	iDataRetry,
	iAnalyticsId,
	iGroupId,
	iVipType,
	iCPId,
	iCPDate,
	iDaily,
	bool:bLoaded,
	bool:bListener,
	bool:bSignIn,
	String:szIP[32],
	String:szGroupName[16],
	String:szSignature[256],
	String:szDiscuzName[32],
	String:szClientName[32],
	String:szAdminFlags[16],
	String:szInsertData[512],
	String:szUpdateData[512],
	String:szNewSignature[256],
	Handle:hSignTimer,
	Handle:hListener,
}

//Handles
enum Handles
{
	Handle:DB_Game,
	Handle:DB_Discuz,
	Handle:KV_Local
}

//Forwards
enum Forward
{
	Handle:ServerLoaded,
	Handle:ClientLoaded,
	Handle:ClientSigned,
	Handle:ClientVipChecked,
	Handle:ClientMarried,
	Handle:ClientDivorce,
	Handle:ClientAuthTerm,
	Handle:APIGetCredits,
	Handle:APISetCredits,
	Handle:OnNewDay
}

//Events
enum hEvents
{
	Handle:round_start,
	Handle:round_end,
	Handle:player_spawn,
	Handle:player_death,
	Handle:player_hurt,
	Handle:player_team,
	Handle:player_jump,
	Handle:weapon_fire,
	Handle:player_name
}

//Motd Cmd
enum
{
	MOTDPANEL_CMD_NONE,
	MOTDPANEL_CMD_JOIN,
	MOTDPANEL_CMD_CHANGE_TEAM,
	MOTDPANEL_CMD_IMPULSE_101,
	MOTDPANEL_CMD_MAPINFO,
	MOTDPANEL_CMD_CLOSED_HTMLPAGE,
	MOTDPANEL_CMD_CHOOSE_TEAM,
};

//Game Text
#define MAX_CHANNEL 6
enum TextHud
{
	iEntRef,
	Float:fHolded,
	String:szPosX[16],
	String:szPosY[16],
	Handle:hTimer
}