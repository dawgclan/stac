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
new Handle:g_hHealDamage;
new Handle:g_hMirrorDamage;
new Handle:g_hMirrorDamageSlap;
new Handle:g_hPointCaptureKarma;
new Handle:g_hRoundWinKarma;
new Handle:g_hSpawnProtectTime;

public OnPluginStart()
{
	decl String:sGameDir[64];
	GetGameFolderName(sGameDir, sizeof(sGameDir));
	if(!StrEqual(sGameDir, "insurgency"))
		SetFailState("This plugin only works on Insurgency.");
	
	if(LibraryExists("stac-explode"))
		OnLibraryAdded("stac-explode");
	
	// Create convars
	g_hHealDamage        = CreateConVar("stac_heal_damage",        "0",  "STAC Heal Damage",         FCVAR_PLUGIN);
	g_hMirrorDamage      = CreateConVar("stac_mirrordamage",       "1",  "STAC Mirror Damage",       FCVAR_PLUGIN);
	g_hMirrorDamageSlap  = CreateConVar("stac_mirrordamage_slap",  "0",  "STAC Mirror Damage Slap",  FCVAR_PLUGIN);
	g_hPointCaptureKarma = CreateConVar("stac_pointcapture_karma", "2",  "STAC Point Capture Karma", FCVAR_PLUGIN);
	g_hRoundWinKarma     = CreateConVar("stac_roundwin_karma",     "2",  "STAC Round Win Karma",     FCVAR_PLUGIN);
	g_hSpawnProtectTime  = CreateConVar("stac_spawnprotect_time",  "10", "STAC Spawn Protect Time",  FCVAR_PLUGIN);
	
	// Hook events
	HookEvent("round_end",    Event_RoundEnd);
	
	// Hook user messages
	HookUserMessage(GetUserMessageId("ObjMsg"), UserMsg_ObjMsg);
	
	// Load translations
	LoadTranslations("stac-insurgency.phrases");
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
public STAC_OnPlayerHurt(attacker,victim)
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
			ForcePlayerSuicide(attacker);
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
	if(g_bAllowExplodeEffect)
	{
		STACEffect_Explode(attacker);
	}else{
		ForcePlayerSuicide(attacker);
	}
}


public STAC_OnPlayerSpawn(client)
{
	g_iSpawnTime[client] = GetTime();
	g_iHealth[client] = GetClientHealth(client);
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!STAC_GetSetting(STACSetting_Enabled))
		return;
	
	//decl String:sReason[256];
	new iKarma = GetConVarInt(g_hRoundWinKarma);
	
	for(new i = 1, iTeam = GetEventInt(event, "winner"); i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || GetClientTeam(i) != iTeam)
			continue;
		
		//Format(sReason, sizeof(sReason), "%T", "Winning Round", i);
		new iNewKarma = STAC_GetInfo(i,STACInfo_Karma) + iKarma;
		STAC_SetInfo(i,STACInfo_Karma,iNewKarma);
	}
}


/**
 * User Messages
 */
public Action:UserMsg_ObjMsg(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	if(!STAC_GetSetting(STACSetting_Enabled))
		return;
	
	// Objective Point: 1 = point A, 2 = point B, 3 = point C, etc.
	BfReadByte(bf);
	// Capture Status: 1 = starting capture, 2 = finished capture
	if(BfReadByte(bf) != 2)
		return;
	
	//decl String:sReason[256];
	new iKarma = GetConVarInt(g_hPointCaptureKarma);
	
	for(new i = 1, iTeam = BfReadByte(bf); i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || GetClientTeam(i) != iTeam)
			continue;
		
		//Format(sReason, sizeof(sReason), "%T", "Capturing Point", i);
		new iNewKarma = STAC_GetInfo(i,STACInfo_Karma) + iKarma;
		STAC_SetInfo(i,STACInfo_Karma,iNewKarma);
	}
}