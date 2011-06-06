#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <stac>
#include <stac_effect>

public Plugin:myinfo	=
{
	name				=	"STAC: Counter-Strike Module",
	author				=	STAC_AUTHORS,
	description			=	"STAC: Counter-Strike Module",
	version				=	STAC_VERSION,
	url					=	STAC_WEBSITE
};

/**
 *	Globals
 */
new g_iSpawnTime[MAXPLAYERS + 1];
new bool:g_bAllowExplodeEffect = false;
new Handle:g_hBombDefusedKarma;
new Handle:g_hBombExplodedKarma;
new Handle:g_hBombPlantedKarma;
new Handle:g_hHealDamage;
new Handle:g_hHostageRescuedKarma;
new Handle:g_hMirrorDamage;
new Handle:g_hMirrorDamageSlap;
new Handle:g_hRoundWinKarma;
new	Handle:g_hSpawnProtectTime;


/**
 *	Plugin Forwards
 */
public OnPluginStart()
{
	// Load translations
	LoadTranslations("stac-cstrike.phrases");
	
	if(LibraryExists("stac-explode"))
		OnLibraryAdded("stac-explode");
	
	decl String:sGameDir[64];
	GetGameFolderName(sGameDir,sizeof(sGameDir));
	if(!StrEqual(sGameDir, "cstrike"))
		SetFailState("This plugin will only work for Counter-Strike: Source.");
	
	// Create Convars
	g_hBombDefusedKarma		=	CreateConVar("stac_bombdefused_karma",		"3",	"STAC Bomb Defused Karma",		FCVAR_PLUGIN);
	g_hBombExplodedKarma	=	CreateConVar("stac_bombexploded_karma",		"2",	"STAC Bomb Exploded Karma", 	FCVAR_PLUGIN);
	g_hBombPlantedKarma		=	CreateConVar("stac_bombplanted_karma",		"1",	"STAC Bomb Planted Karma",		FCVAR_PLUGIN);
	g_hHealDamage			=	CreateConVar("stac_heal_damage",			"0",	"STAC Heal Damage",				FCVAR_PLUGIN);
	g_hHostageRescuedKarma	=	CreateConVar("stac_hostagerescued_karma",	"1",	"STAC Hostage Rescued Karma",	FCVAR_PLUGIN);
	g_hMirrorDamage			=	CreateConVar("stac_mirrordamage",			"1",	"STAC Mirror Damage",			FCVAR_PLUGIN);
	g_hMirrorDamageSlap		=	CreateConVar("stac_mirrordamage_slap",		"0",	"STAC Mirror Damage Slap",		FCVAR_PLUGIN);
	g_hRoundWinKarma		=	CreateConVar("stac_roundwin_karma",			"2",	"STAC Round Win Karma",			FCVAR_PLUGIN);
	g_hSpawnProtectTime		=	CreateConVar("stac_spawnprotect_time",		"10",	"STAC Spawn Protect Time",		FCVAR_PLUGIN);
	
	// Hook Events
	HookEvent("bomb_defused",		Event_BombDefused);
	HookEvent("bomb_exploded",		Event_BombExploded);
	HookEvent("bomb_planted",		Event_BombPlanted);
	HookEvent("hostage_rescued",	Event_HostageRescued);
	HookEvent("player_hurt",		Event_PlayerHurt);
	HookEvent("round_end",			Event_RoundEnd);
	
}

public OnLibraryAdded(const String:name[])
{
	if(StrEqual(name, "stac-explode"))
	{
		g_bAllowExplodeEffect = true;
	}	
}

/**
 *	Events
 */
public Event_BombDefused(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!STAC_GetSetting(STACSetting_Enabled) || !STAC_GetSetting(STACSetting_KarmaEnabled))
		return;
	
	decl String:sReason[256];
	new iClient = GetClientOfUserId(GetEventInt(event,"userid"));
	
	Format(sReason, sizeof(sReason), "%T",	"Defusing Bomb", iClient);
	new iNewKarma = STAC_GetInfo(iClient, STACInfo_Karma) + GetConVarInt(g_hBombDefusedKarma);
	STAC_SetInfo(iClient, STACInfo_Karma, iNewKarma);
	PrintToChat(iClient, "%c[STAC]%c %t %s", CLR_GREEN, CLR_DEFAULT, "Earned Karma", STAC_GetInfo(iClient,STACInfo_Karma), STAC_GetSetting(STACSetting_KarmaLimit), sReason);
}

public Event_BombExploded(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!STAC_GetSetting(STACSetting_Enabled) || !STAC_GetSetting(STACSetting_KarmaEnabled))
		return;
	
	decl String:sReason[256];
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	
	Format(sReason, sizeof(sReason), "%T", "Detonating Bomb", iClient);
	new iNewKarma = STAC_GetInfo(iClient, STACInfo_Karma) + GetConVarInt(g_hBombExplodedKarma);
	STAC_SetInfo(iClient, STACInfo_Karma, iNewKarma);
	PrintToChat(iClient, "%c[STAC]%c %t %s", CLR_GREEN, CLR_DEFAULT, "Earned Karma", STAC_GetInfo(iClient,STACInfo_Karma), STAC_GetSetting(STACSetting_KarmaLimit), sReason);
}

public Event_BombPlanted(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!STAC_GetSetting(STACSetting_Enabled) || !STAC_GetSetting(STACSetting_KarmaEnabled))
		return;
	
	decl String:sReason[256];
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	
	Format(sReason, sizeof(sReason), "%T", "Planting Bomb", iClient);
	new iNewKarma = STAC_GetInfo(iClient, STACInfo_Karma) + GetConVarInt(g_hBombPlantedKarma);
	STAC_SetInfo(iClient, STACInfo_Karma, iNewKarma);
	PrintToChat(iClient, "%c[STAC]%c %t %s", CLR_GREEN, CLR_DEFAULT, "Earned Karma", STAC_GetInfo(iClient,STACInfo_Karma), STAC_GetSetting(STACSetting_KarmaLimit), sReason);
}

public Event_HostageRescued(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!STAC_GetSetting(STACSetting_Enabled) || !STAC_GetSetting(STACSetting_KarmaEnabled))
		return;
	
	decl String:sReason[256];
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	
	new iNewKarma = STAC_GetInfo(iClient, STACInfo_Karma) + GetConVarInt(g_hHostageRescuedKarma);
	STAC_SetInfo(iClient, STACInfo_Karma, iNewKarma);
	PrintToChat(iClient, "%c[STAC]%c %t %s", CLR_GREEN, CLR_DEFAULT, "Earned Karma", STAC_GetInfo(iClient,STACInfo_Karma), STAC_GetSetting(STACSetting_KarmaLimit), sReason);
	
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	
	new iAttacker	=	GetClientOfUserId(GetEventInt(event, "attacker")),
		iDamage		=	GetEventInt(event, "dmg_health"),
		iVictim		=	GetClientOfUserId(GetEventInt(event, "userid"));
		
	if(!STAC_GetSetting(STACSetting_Enabled) || !iAttacker || iAttacker == iVictim || GetClientTeam(iAttacker) != GetClientTeam(iVictim))
		return;
	
	if(GetConVarBool(g_hHealDamage))
		SetEntityHealth(iVictim, GetClientHealth(iVictim) + iDamage);
	
	if(GetConVarBool(g_hMirrorDamage))
	{
			new iHealth = GetClientHealth(iAttacker);
			if(iHealth <= 0)
			{
				SlayPlayer(iAttacker);
				return;
			}
			if(GetConVarBool(g_hMirrorDamageSlap))
				SlapPlayer(iAttacker,		iDamage);
			else
				SetEntityHealth(iAttacker,	iHealth);
	}
	
	// If Ignoring bots is enabled, and attacker or victim is a bot, ignore
	if(STAC_GetSetting(STACSetting_IgnoreBots)	&& (IsFakeClient(iAttacker) || IsFakeClient(iVictim)))
		return;
	
	// If immunity is enabled, and attacker has custom 6 or root flag, ignore
	if(STAC_GetSetting(STACSetting_Immunity)	&& GetUserFlagBits(iAttacker) & (ADMFLAG_CUSTOM6|ADMFLAG_ROOT))
		return;
	
	// If spawn protection is disabled, or the spawn protection has expired, ignore
	new iProtectTime = GetConVarInt(g_hSpawnProtectTime);
	if(!iProtectTime || GetTime() - g_iSpawnTime[iVictim] > iProtectTime)
		return;
	
	PrintToChatAll("%c[STAC]%c %t", CLR_GREEN, CLR_DEFAULT, "Spawn Attacking", iAttacker, iVictim);
	SlayPlayer(iAttacker);
}

public STAC_OnPlayerSpawn(client)
{
	if(!STAC_GetSetting(STACSetting_Enabled))
		return;
	
	g_iSpawnTime[client] = GetTime();
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!STAC_GetSetting(STACSetting_Enabled))
		return;
	
	decl String:sReason[256];
	new iKarma = GetConVarInt(g_hRoundWinKarma);
	
	for(new i = 1, iTeam = GetEventInt(event, "winner"); i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || GetClientTeam(i) != iTeam)
			continue;
		
		Format(sReason, sizeof(sReason), "%T", "Winning Round", i);
		
		new iNewKarma = STAC_GetInfo(i, STACInfo_Karma) + iKarma;
		STAC_SetInfo(i, STACInfo_Karma, iNewKarma);
		
		PrintToChat(i, "%c[STAC]%c %t %s", CLR_GREEN, CLR_DEFAULT, "Earned Karma", STAC_GetInfo(i,STACInfo_Karma), STAC_GetSetting(STACSetting_KarmaLimit), sReason);
	}
}

SlayPlayer(client)
{
	if(g_bAllowExplodeEffect)
		STACEffect_Explode(client);
	else
		ForcePlayerSuicide(client);
}