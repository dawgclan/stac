#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <stac>
#include <stac_effect>

new Handle:g_hBeacon =			INVALID_HANDLE;
new Handle:g_hBeaconRadius =	INVALID_HANDLE;

public Plugin:myInfo =
{
	name		= "STAC: Beacon",
	author		= STAC_AUTHORS,
	description	= "STAC: Beacon",
	version		= STAC_VERSION,
	url			= STAC_WEBSITE
};

/**
 *	Plugin Forwards
 */
public OnPluginStart()
{
	// Load Translations
	LoadTranslations("stac-beacon.phrases");
	
	if(LibraryExists("stac"))
		OnLibraryAdded("stac");

	g_hBeacon =			CreateConVar("stac_beacon", "1", "Is the STAC Beacon option enabled or disabled? [0 = DISABLED, 1 = ENABLED]", 0, true, 0.0, true, 1.0);
	g_hBeaconRadius =	CreateConVar("stac_beacon_radius", "375.0", "STAC Beacon radius for light rings.", 0, true, 50.0, true, 1500.0);
}

public OnLibraryAdded(const String:name[])
{
	if(!StrEqual(name, "stac"))
		return;
	
	decl String:sName[32];
	Format(sName, sizeof(sName), "%T", "Beacon", LANG_SERVER);
	STAC_RegisterPunishment(sName, STACPunishment_Beacon);
}
//////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////
public APLRes:AskPluginLoad2(Handle:myself, bool:late,String:error[],err_max)
{
	CreateNative("STACEffect_Beacon",			Native_SEBeacon);
}

public Native_SEBeacon(Handle:plugin, numParams)
{
	new iClient = GetNativeCell(1);
	if(IsClientInGame(iClient))
	{
		CreateBeacon(iClient);
	}else{
		ThrowNativeError(SP_ERROR_INDEX,"[STAC] Beacon | Client %d not in game", iClient);
	}
}
//////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////

/**
 *	STAC Punishments
 */

public STACPunishment_Beacon(victim, attacker)
{
	PrintToChatAll("%c[STAC]%c %t", CLR_GREEN, CLR_DEFAULT, "Beaconed", STAC_GetInfo(attacker, STACInfo_Kills), STAC_GetSetting(STACSetting_KillLimit));

	if (g_BeaconSerial[attacker] == 0)
	{
		CreateBeacon(attacker);
	}
}

// Model indexes for temp entities (based off funcommands.sp)
new g_BeamSprite;
new g_HaloSprite;

// Basic color arrays for temp entities (based off funcommands.sp)
new redColor[4] = {255, 75, 75, 255};
new greenColor[4] = {75, 255, 75, 255};
new blueColor[4] = {75, 75, 255, 255};
new greyColor[4] = {128, 128, 128, 255};

// Include Punishments (based off funcommands.sp slightly modified)
new g_BeaconSerial[MAXPLAYERS+1] = { 0, ... };

CreateBeacon(client)
{
	g_BeaconSerial[client] = ++g_Serial_Gen;
	CreateTimer(1.0, Timer_Beacon, client | (g_Serial_Gen << 7), DEFAULT_TIMER_FLAGS);	
}

KillBeacon(client)
{
	g_BeaconSerial[client] = 0;

	if (IsClientInGame(client))
	{
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
}

KillAllBeacons()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		KillBeacon(i);
	}
}

public Action:Timer_Beacon(Handle:timer, any:value)
{
	new client = value & 0x7f;
	new serial = value >> 7;

	if (!IsClientInGame(client)
		|| !IsPlayerAlive(client)
		|| g_BeaconSerial[client] != serial)
	{
		KillBeacon(client);
		return Plugin_Stop;
	}

	new team = GetClientTeam(client);

	new Float:vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 10;

	new Float:BEACON_RADIUS = GetConVarFloat(g_hBeaconRadius);

	TE_SetupBeamRingPoint(vec, 10.0, BEACON_RADIUS, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, greyColor, 10, 0);
	TE_SendToAll();

	if (team == 2)
	{
		TE_SetupBeamRingPoint(vec, 10.0, BEACON_RADIUS, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, redColor, 10, 0);
	}
	else if (team == 3)
	{
		TE_SetupBeamRingPoint(vec, 10.0, BEACON_RADIUS, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, blueColor, 10, 0);
	}
	else
	{
		TE_SetupBeamRingPoint(vec, 10.0, BEACON_RADIUS, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, greenColor, 10, 0);
	}

	TE_SendToAll();

	GetClientEyePosition(client, vec);
	EmitAmbientSound(SOUND_BLIP, vec, client, SNDLEVEL_RAIDSIREN);	

	return Plugin_Continue;
}