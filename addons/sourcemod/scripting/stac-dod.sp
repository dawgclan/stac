#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <stac>
#include <stac_effect>

public Plugin:myinfo =
{
	name				=	"STAC: Day of Defeat Module",
	author				=	STAC_AUTHORS,
	description			=	"STAC: Day of Defeat Module",
	version				=	STAC_VERSION,
	url					=	STAC_WEBSITE
}

/**
 * Globals
 */
new g_iHealth[MAXPLAYERS + 1];
new g_iSpawnTime[MAXPLAYERS + 1];
new bool:g_bAllowExplodeEffect = false;
new Handle:g_hBombDefusedKarma;
new Handle:g_hBombExplodedKarma;
new Handle:g_hBombPlantedKarma;
new Handle:g_hCaptureBlockedKarma;
new Handle:g_hHealDamage;
new Handle:g_hKillDefuserKarma;
new Handle:g_hKillPlanterKarma;
new Handle:g_hMirrorDamage;
new Handle:g_hMirrorDamageSlap;
new Handle:g_hPointCaptureKarma;
new Handle:g_hRoundWinKarma;
new Handle:g_hSpawnProtectTime;

/**
 * Plugin Forwards
 */
public OnPluginStart()
{
	decl String:sGameDir[64];
	GetGameFolderName(sGameDir, sizeof(sGameDir));
	if(!StrEqual(sGameDir, "dod"))
		SetFailState("This plugin only works on Day of Defeat: Source.");
	
	// Load translations
	LoadTranslations("stac-dod.phrases");
	
	if(LibraryExists("stac-explode"))
		OnLibraryAdded("stac-explode");
	
	// Create convars
	g_hBombDefusedKarma		=	CreateConVar("stac_bombdefused_karma",		"2",	"STAC Bomb Defused Karma",		FCVAR_PLUGIN);
	g_hBombExplodedKarma	=	CreateConVar("stac_bombexploded_karma",		"2",	"STAC Bomb Exploded Karma",		FCVAR_PLUGIN);
	g_hBombPlantedKarma		=	CreateConVar("stac_bombplanted_karma",		"1",	"STAC Bomb Planted Karma",		FCVAR_PLUGIN);
	g_hCaptureBlockedKarma	=	CreateConVar("stac_captureblocked_karma",	"2",	"STAC Capture Blocked Karma",	FCVAR_PLUGIN);
	g_hHealDamage			=	CreateConVar("stac_heal_damage",			"0",	"STAC Heal Damage",				FCVAR_PLUGIN);
	g_hKillDefuserKarma		=	CreateConVar("stac_killdefuser_karma",		"1",	"STAC Kill Defuser Karma",		FCVAR_PLUGIN);
	g_hKillPlanterKarma		=	CreateConVar("stac_killplanter_karma",		"1",	"STAC Kill Planter Karma",		FCVAR_PLUGIN);
	g_hMirrorDamage			=	CreateConVar("stac_mirrordamage",			"1",	"STAC Mirror Damage",			FCVAR_PLUGIN);
	g_hMirrorDamageSlap		=	CreateConVar("stac_mirrordamage_slap",		"0",	"STAC Mirror Damage Slap",		FCVAR_PLUGIN);
	g_hPointCaptureKarma	=	CreateConVar("stac_pointcapture_karma",		"3",	"STAC Point Capture Karma",		FCVAR_PLUGIN);
	g_hRoundWinKarma		=	CreateConVar("stac_roundwin_karma",			"2",	"STAC Round Win Karma",			FCVAR_PLUGIN);
	g_hSpawnProtectTime		=	CreateConVar("stac_spawnprotect_time",		"10",	"STAC Spawn Protect Time",		FCVAR_PLUGIN);
	
	// Hook Events
	HookEvent("dod_bomb_planted",    Event_BombPlanted);
	HookEvent("dod_bomb_exploded",   Event_BombExploded);
	HookEvent("dod_bomb_defused",    Event_BombDefused);
	HookEvent("dod_capture_blocked", Event_CaptureBlocked);
	HookEvent("dod_kill_defuser",    Event_KillDefuser);
	HookEvent("dod_kill_planter",    Event_KillPlanter);
	HookEvent("dod_point_captured",  Event_PointCaptured);
	HookEvent("dod_round_win",       Event_RoundWin);
}

public OnLibraryAdded(const String:name[])
{
	if(StrEqual(name, "stac-explode"))
	{
		g_bAllowExplodeEffect = true;
	}	
}

/**
 * Events
 */
public Event_BombDefused(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!STAC_GetSetting(STACSetting_Enabled) && !STAC_GetSetting(STACSetting_KarmaEnabled) && !GetConVarBool(g_hBombDefusedKarma))
		return;
	
	//decl String:sReason[256];
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	
	//Format(sReason, sizeof(sReason), "%T", "Defusing Bomb", iClient);
	new iNewKarma = STAC_GetInfo(iClient,STACInfo_Karma) + GetConVarInt(g_hBombDefusedKarma);
	
	STAC_SetInfo(iClient,STACInfo_Karma, iNewKarma);
}

public Event_BombExploded(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!STAC_GetSetting(STACSetting_Enabled) && !STAC_GetSetting(STACSetting_KarmaEnabled) && !GetConVarBool(g_hBombExplodedKarma))
		return;
	
	//decl String:sReason[256];
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	
	//Format(sReason, sizeof(sReason), "%T", "Detonating Bomb", iClient);
	new iNewKarma = STAC_GetInfo(iClient, STACInfo_Karma) + GetConVarInt(g_hBombExplodedKarma);
	
	STAC_SetInfo(iClient, STACInfo_Karma, iNewKarma);
}

public Event_BombPlanted(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!STAC_GetSetting(STACSetting_Enabled) && !STAC_GetSetting(STACSetting_KarmaEnabled) && !GetConVarBool(g_hBombPlantedKarma))
		return;
	
	//decl String:sReason[256];
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	
	//Format(sReason, sizeof(sReason), "%T", "Planting Bomb", iClient);
	new iNewKarma = STAC_GetInfo(iClient, STACInfo_Karma) + GetConVarInt(g_hBombPlantedKarma);
	
	STAC_SetInfo(iClient, STACInfo_Karma, iNewKarma);
}

public Event_CaptureBlocked(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!STAC_GetSetting(STACSetting_Enabled) && !STAC_GetSetting(STACSetting_KarmaEnabled) && !GetConVarBool(g_hCaptureBlockedKarma))
		return;
	
	//decl String:sReason[256];
	new iClient = GetClientOfUserId(GetEventInt(event, "blocker"));
	
	//Format(sReason, sizeof(sReason), "%T", "Blocking Capture", iClient);
	new iNewKarma = STAC_GetInfo(iClient, STACInfo_Karma) + GetConVarInt(g_hCaptureBlockedKarma);
	
	STAC_SetInfo(iClient, STACInfo_Karma, iNewKarma);
}

public Event_KillDefuser(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!STAC_GetSetting(STACSetting_Enabled) && !STAC_GetSetting(STACSetting_KarmaEnabled) && !GetConVarBool(g_hKillDefuserKarma))
		return;
	
	//decl String:sReason[256];
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	
	//Format(sReason, sizeof(sReason), "%T", "Killing Defuser", iClient);
	new iNewKarma = STAC_GetInfo(iClient, STACInfo_Karma) + GetConVarInt(g_hKillDefuserKarma);
	
	STAC_SetInfo(iClient, STACInfo_Karma, iNewKarma);
}

public Event_KillPlanter(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!STAC_GetSetting(STACSetting_Enabled) && !STAC_GetSetting(STACSetting_KarmaEnabled) && !GetConVarBool(g_hKillPlanterKarma))
		return;
	
	//decl String:sReason[256];
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	
	//Format(sReason, sizeof(sReason), "%T", "Killing Planter", iClient);
	new iNewKarma = STAC_GetInfo(iClient, STACInfo_Karma) + GetConVarInt(g_hKillPlanterKarma);
	
	STAC_SetInfo(iClient,STACInfo_Karma,iNewKarma);
}

public STAC_OnPlayerHurt(attacker, victim)
{
	new iDamage = g_iHealth[victim] - GetClientHealth(victim);
	
	if(!STAC_GetSetting(STACSetting_Enabled)   || !attacker || attacker == victim || GetClientTeam(attacker) != GetClientTeam(victim))
		return;
	
	if(GetConVarBool(g_hHealDamage))
		SetEntityHealth(victim, GetClientHealth(victim) + iDamage);
	
	if(GetConVarBool(g_hMirrorDamage))
	{
		new iHealth = GetClientHealth(attacker) - iDamage;
		if(iHealth <= 0)
		{
			SlayPlayer(attacker);
			return;
		}
		if(GetConVarBool(g_hMirrorDamageSlap))
			SlapPlayer(attacker,      iDamage);
		else
			SetEntityHealth(attacker, iHealth);
	}
	
	// If ignoring bots is enabled, and attacker or victim is a bot, ignore
	if(STAC_GetSetting(STACSetting_IgnoreBots) && (IsFakeClient(attacker) || IsFakeClient(victim)))
		return;
	
	// If immunity is enabled, and attacker has custom6 or root flag, ignore
	if(STAC_GetSetting(STACSetting_Immunity)   && GetUserFlagBits(attacker) & (ADMFLAG_CUSTOM6|ADMFLAG_ROOT))
		return;
	
	// If spawn protection is disabled, or the spawn protection has expired, ignore
	new iProtectTime = GetConVarInt(g_hSpawnProtectTime);
	if(!iProtectTime || GetTime() - g_iSpawnTime[victim] > iProtectTime)
		return;
	
	PrintToChatAll("%c[STAC]%c %t", CLR_GREEN, CLR_DEFAULT, "Spawn Attacking", attacker, victim);
	SlayPlayer(attacker);
}

public STAC_OnPlayerSpawn(client)
{
	g_iSpawnTime[client] = GetTime();
	g_iHealth[client] = GetClientHealth(client);
}

public Event_PointCaptured(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!STAC_GetSetting(STACSetting_Enabled) || GetEventBool(event, "bomb") && !GetConVarBool(g_hPointCaptureKarma) && !STAC_GetSetting(STACSetting_KarmaEnabled))
		return;
	
	decl String:sCappers[256];//, String:sReason[256];
	new iKarma = GetConVarInt(g_hPointCaptureKarma);
	GetEventString(event, "cappers", sCappers, sizeof(sCappers));
	
	for(new i, iCappers = strlen(sCappers); i < iCappers; i++)
	{
		//Format(sReason, sizeof(sReason), "%T", "Capturing Point", sCappers[i]);
		new iNewKarma = STAC_GetInfo(sCappers[i], STACInfo_Karma) + iKarma;
		STAC_SetInfo(sCappers[i],STACInfo_Karma,iNewKarma);
	}
}

public Event_RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!STAC_GetSetting(STACSetting_Enabled) && !STAC_GetSetting(STACSetting_KarmaEnabled) && !GetConVarBool(g_hRoundWinKarma))
		return;
	
	//decl String:sReason[256];
	new iKarma = GetConVarInt(g_hRoundWinKarma);
	
	for(new i = 1, iTeam = GetEventInt(event, "team"); i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || GetClientTeam(i) != iTeam)
			continue;
		
		//Format(sReason, sizeof(sReason), "%T", "Winning Round", i);
		new iNewKarma = STAC_GetInfo(i, STACInfo_Karma) + iKarma;
		STAC_SetInfo(i, STACInfo_Karma, iNewKarma);
	}
}

/**
 * Stocks
 */
SlayPlayer(client)
{
	if(g_bAllowExplodeEffect)
		STACEffect_Explode(client);
	else
		ForcePlayerSuicide(client);
}