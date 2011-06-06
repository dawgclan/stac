/**
 * 
 * NOTE: Every single one of these functions KILLS THE PLAYER
 * 
 * A LOT of the functionality placed here utilizes code that is
 * directly inside of SourceMod's funcommands.sp and it's sub-plugins
 * 
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <stac>
#include <se_beacon>

// Sounds
#define SOUND_BLIP		"buttons/blip1.wav"
#define SOUND_BEEP		"buttons/button17.wav"
#define SOUND_FINAL		"weapons/cguard/charging.wav"
#define SOUND_BOOM		"weapons/explode3.wav"
#define SOUND_FREEZE	"physics/glass/glass_impact_bullet4.wav"
#define SOUND_EXPLODE	"ambient/explosions/explode_8.wav"

public Plugin:myinfo	=
{
	name				=	"STAC: Effects Module",
	author				=	STAC_AUTHORS,
	description			=	"STAC: Effects Module",
	version				=	STAC_VERSION,
	url					=	STAC_WEBSITE
};

/**
 * Globals
 */
// Beacon
new g_BeaconSerial[MAXPLAYERS+1] = { 0, ... };

// UserMessageId for Fade.
new UserMsg:g_FadeUserMsgId;

// Drug
new Handle:g_DrugTimers[MAXPLAYERS+1];
new Float:g_DrugAngles[20] = {0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0};

// Colors
new redColor[4]		= {255, 75, 75, 255};
new orangeColor[4]	= {255, 128, 0, 255};
new greenColor[4]	= {75, 255, 75, 255};
new blueColor[4]	= {75, 75, 255, 255};
new whiteColor[4]	= {255, 255, 255, 255};
new greyColor[4]	= {128, 128, 128, 255};

// General
new Float:g_fRadius[MAXPLAYERS+1];
new g_iTicks[MAXPLAYERS+1];
new g_iTargetMode[MAXPLAYERS+1];
new Float:g_fDuration[MAXPLAYERS+1] = { 20.0, ...};

new g_BeamSprite        = -1;
new g_BeamSprite2       = -1;
new g_HaloSprite        = -1;
new g_GlowSprite        = -1;
new g_ExplosionSprite   = -1;


// Explosion
new g_iExplosionModel;
new g_iLightningModel;
new g_iSmokeModel;

// Firebomb
new g_FireBombSerial[MAXPLAYERS+1] = { 0, ... };
new g_FireBombTime[MAXPLAYERS+1] = { 0, ... };

// FreezeBomb
new g_FreezeSerial[MAXPLAYERS+1] = { 0, ... };
new g_FreezeBombSerial[MAXPLAYERS+1] = { 0, ... };
new g_FreezeTime[MAXPLAYERS+1] = { 0, ... };
new g_FreezeBombTime[MAXPLAYERS+1] = { 0, ... };

// TimeBomb
new g_TimeBombSerial[MAXPLAYERS+1] = { 0, ... };
new g_TimeBombTime[MAXPLAYERS+1] = { 0, ... };

// Timer Safety
new g_Serial_Gen = 0;

// Game Engine
new g_GameEngine = SOURCE_SDK_UNKNOWN;

#define DEFAULT_TIMER_FLAGS TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE

/**
 * Plugin Forwards
 */
public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("funcommands.phrases");
	g_FadeUserMsgId = GetUserMessageId("Fade");
	g_GameEngine = GuessSDKVersion();
	
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
} 

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
   CreateNative("STAC_Effect", Native_STAC_Effect);
   return APLRes_Success;
}

public OnMapStart()
{
	g_iExplosionModel = PrecacheModel("materials/effects/fire_cloud1.vmt");
	g_iLightningModel = PrecacheModel("materials/sprites/tp_beam001.vmt");
	g_iSmokeModel     = PrecacheModel("materials/effects/fire_cloud2.vmt");
		
	PrecacheSound(SOUND_BLIP, true);
	PrecacheSound(SOUND_BEEP, true);
	PrecacheSound(SOUND_FINAL, true);
	PrecacheSound(SOUND_BOOM, true);
	PrecacheSound(SOUND_FREEZE, true);
	PrecacheSound(SOUND_EXPLODE, true);

	new sdkversion = GuessSDKVersion();
	if (sdkversion == SOURCE_SDK_LEFT4DEAD || sdkversion == SOURCE_SDK_LEFT4DEAD2)
	{
		g_BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
		g_HaloSprite = PrecacheModel("materials/sprites/glow01.vmt");
	}
	else
	{
		g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
		g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
		g_BeamSprite2 = PrecacheModel("sprites/bluelight1.vmt");
		g_GlowSprite = PrecacheModel("sprites/blueglow2.vmt");
		g_ExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt");
	}
}

public OnMapEnd()
{
	KillAllBeacons( );
	KillAllTimeBombs();
	KillAllFireBombs();
	KillAllFreezes();
	KillAllDrugs();
}

public Action:Event_RoundEnd(Handle:event,const String:name[],bool:dontBroadcast)
{
	KillAllBeacons( );
	KillAllTimeBombs();
	KillAllFireBombs();
	KillAllFreezes();
	KillAllDrugs();
}

/**
 * Natives
 */
public Native_STAC_Effect(Handle:plugin, numParams)
{
	new iClient = GetNativeCell(1);
	if(IsClientInGame(iClient))
		ThrowNativeError(SP_ERROR_INDEX,"Client index %d not in game",iClient);
	
	
	if(GetNativeCell(2)				==	STACEffect_Beacon)
	{
		g_fRadius[iClient]	=	GetNativeCell(3);
		CreateBeacon(iClient);
	}
	else if(GetNativeCell(2)		==	STACEffect_Blind)
	{
		PerformBlind(iClient,255);
	}
	else if(GetNativeCell(2)		==	STACEffect_Burn)
	{
		g_fDuration[iClient]	=	GetNativeCell(6);
		PerformBurn(iClient);
	}	
	else if(GetNativeCell(2)		==	STACEffect_Drug)
	{
		PerformDrug(iClient);
	}
	else if(GetNativeCell(2)		==	STACEffect_Explode)
	{
		PerformExplode(iClient);
	}
	else if(GetNativeCell(2)		==	STACEffect_FireBomb)
	{
		g_fRadius[iClient]		=	GetNativeCell(3);
		g_iTicks[iClient]		=	GetNativeCell(4);
		g_iTargetMode[iClient]	=	GetNativeCell(5);
		g_fDuration[iClient]	=	GetNativeCell(6);
		CreateFireBomb(iClient);
	}
	else if(GetNativeCell(2)		==	STACEffect_Freeze)
	{
		g_fDuration[iClient]	=	GetNativeCell(6);
		PerformFreeze(iClient);
	}
	else if(GetNativeCell(2)		==	STACEffect_FreezeBomb)
	{
		g_fRadius[iClient]		=	GetNativeCell(3);
		g_iTicks[iClient]		=	GetNativeCell(4);
		g_iTargetMode[iClient]	=	GetNativeCell(5);
		g_fDuration[iClient]	=	GetNativeCell(6);
		PerformFreezeBomb(iClient);

	}
	else if(GetNativeCell(2)		==	STACEffect_TimeBomb)
	{
		g_fRadius[iClient]		=	GetNativeCell(3);
		g_iTicks[iClient]		=	GetNativeCell(4);
		g_iTargetMode[iClient]	=	GetNativeCell(5);
		PerformTimeBomb(iClient);
	}

}

/**
 * Functions
 */

// Beacon
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

	TE_SetupBeamRingPoint(vec, 10.0, g_fRadius[client], g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, greyColor, 10, 0);
	TE_SendToAll();
	
	if (team == 2)
	{
		TE_SetupBeamRingPoint(vec, 10.0, g_fRadius[client], g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, redColor, 10, 0);
	}
	else if (team == 3)
	{
		TE_SetupBeamRingPoint(vec, 10.0, g_fRadius[client], g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, blueColor, 10, 0);
	}
	else
	{
		TE_SetupBeamRingPoint(vec, 10.0, g_fRadius[client], g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, greenColor, 10, 0);
	}
	
	TE_SendToAll();
		
	GetClientEyePosition(client, vec);
	EmitAmbientSound(SOUND_BLIP, vec, client, SNDLEVEL_RAIDSIREN);	
		
	return Plugin_Continue;
}

// Blind
PerformBlind(target, amount)
{
	new targets[2];
	targets[0] = target;
	
	new Handle:message = StartMessageEx(g_FadeUserMsgId, targets, 1);
	BfWriteShort(message, 1536);
	BfWriteShort(message, 1536);
	
	if (amount == 0)
	{
		BfWriteShort(message, (0x0001 | 0x0010));
	}
	else
	{
		BfWriteShort(message, (0x0002 | 0x0008));
	}
	
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, amount);
	
	EndMessage();
}

// Burn
PerformBurn(target)
{
	IgniteEntity(target, g_fDuration[target]);
}

// Drug
CreateDrug(client)
{
	g_DrugTimers[client] = CreateTimer(1.0, Timer_Drug, client, TIMER_REPEAT);	
}

KillDrug(client)
{
	KillDrugTimer(client);
	
	new Float:pos[3];
	GetClientAbsOrigin(client, pos);
	new Float:angs[3];
	GetClientEyeAngles(client, angs);
	
	angs[2] = 0.0;
	
	TeleportEntity(client, pos, angs, NULL_VECTOR);	
	
	new clients[2];
	clients[0] = client;	
	
	new Handle:message = StartMessageEx(g_FadeUserMsgId, clients, 1);
	BfWriteShort(message, 1536);
	BfWriteShort(message, 1536);
	BfWriteShort(message, (0x0001 | 0x0010));
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	EndMessage();	
}

KillDrugTimer(client)
{
	KillTimer(g_DrugTimers[client]);
	g_DrugTimers[client] = INVALID_HANDLE;	
}

KillAllDrugs()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (g_DrugTimers[i] != INVALID_HANDLE)
		{
			if(IsClientInGame(i))
			{
				KillDrug(i);
			}
			else
			{
				KillDrugTimer(i);
			}
		}
	}
}

PerformDrug(target)
{
	if (g_DrugTimers[target] == INVALID_HANDLE)
	{
		CreateDrug(target);
	}
	else
	{
		KillDrug(target);
	}			
}

public Action:Timer_Drug(Handle:timer, any:client)
{
	if (!IsClientInGame(client))
	{
		KillDrugTimer(client);

		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(client))
	{
		KillDrug(client);
		
		return Plugin_Handled;
	}
	
	new Float:pos[3];
	GetClientAbsOrigin(client, pos);
	
	new Float:angs[3];
	GetClientEyeAngles(client, angs);
	
	angs[2] = g_DrugAngles[GetRandomInt(0,100) % 20];
	
	TeleportEntity(client, pos, angs, NULL_VECTOR);
	
	new clients[2];
	clients[0] = client;	
	
	new Handle:message = StartMessageEx(g_FadeUserMsgId, clients, 1);
	BfWriteShort(message, 255);
	BfWriteShort(message, 255);
	BfWriteShort(message, (0x0002));
	BfWriteByte(message, GetRandomInt(0,255));
	BfWriteByte(message, GetRandomInt(0,255));
	BfWriteByte(message, GetRandomInt(0,255));
	BfWriteByte(message, 128);
	
	EndMessage();	
		
	return Plugin_Handled;
}

// Explode
PerformExplode(client)
{
	decl Float:flEnd[3], Float:flSparkDir[3], Float:flSparkPos[3], Float:flStart[3];
	// Get player position to use as ending coords
	GetClientAbsOrigin(client, flEnd);
	
	// Se starting coords
	flSparkDir		=	flEnd;
	flSparkPos		=	flEnd;
	flStart			=	flEnd;
	
	flSparkDir[2]	+=	23;
	flSparkPos[2]	+=	13;
	flStart[2]		+=	1000;
	
	// create lightning effects, sparks, and explosion
	
	TE_SetupBeamPoints(flStart, flEnd, g_iLightningModel, g_iLightningModel, 0, 1, 2.0, 5.0, 5.0, 1, 1.0, {255, 255, 255, 255}, 250);
	TE_SendToAll();
	
	TE_SetupExplosion(flEnd,			g_iExplosionModel,	10.0,	10,	TE_EXPLFLAG_NONE,	200,	255);
	TE_SendToAll();
	
	TE_SetupSmoke(flEnd,				g_iExplosionModel,		50.0,	2);
	TE_SendToAll();
	
	TE_SetupSmoke(flEnd,				g_iSmokeModel,		50.0,	2);
	TE_SendToAll();
	
	TE_SetupMetalSparks(flSparkPos,	flSparkDir);
	TE_SendToAll();
	
	EmitAmbientSound(SOUND_EXPLODE,	flEnd, SOUND_FROM_WORLD,	SNDLEVEL_NORMAL,	SND_NOFLAGS,	1.0,	SNDPITCH_NORMAL,	0.0);
	ForcePlayerSuicide(client);
}

// FireBomb
CreateFireBomb(client)
{
	g_FireBombSerial[client] = ++g_Serial_Gen;
	CreateTimer(1.0, Timer_FireBomb, client | (g_Serial_Gen << 7), DEFAULT_TIMER_FLAGS);
	g_FireBombTime[client] = g_iTicks[client];
}

KillFireBomb(client)
{
	g_FireBombSerial[client] = 0;

	if (IsClientInGame(client))
	{
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
}

KillAllFireBombs()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		KillFireBomb(i);
	}
}

public Action:Timer_FireBomb(Handle:timer, any:value)
{
	new client = value & 0x7f;
	new serial = value >> 7;

	if (!IsClientInGame(client)
		|| !IsPlayerAlive(client)
		|| g_FireBombSerial[client] != serial)
	{
		KillFireBomb(client);
		return Plugin_Stop;
	}	
	g_FireBombTime[client]--;
	
	new Float:vec[3];
	GetClientEyePosition(client, vec);
	
	if (g_FireBombTime[client] > 0)
	{
		new color;
		
		if (g_FireBombTime[client] > 1)
		{
			color = RoundToFloor(g_FireBombTime[client] * (255.0 / g_iTicks[client]));
			EmitAmbientSound(SOUND_BEEP, vec, client, SNDLEVEL_RAIDSIREN);	
		}
		else
		{
			color = 0;
			EmitAmbientSound(SOUND_FINAL, vec, client, SNDLEVEL_RAIDSIREN);
		}
		
		SetEntityRenderColor(client, 255, color, color, 255);

		decl String:name[64];
		GetClientName(client, name, sizeof(name));
		PrintCenterTextAll("%t", "Till Explodes", name, g_FireBombTime[client]);		
		
		GetClientAbsOrigin(client, vec);
		vec[2] += 10;

		TE_SetupBeamRingPoint(vec, 10.0, g_fRadius[client] / 3.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, greyColor, 10, 0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(vec, 10.0, g_fRadius[client] / 3.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, whiteColor, 10, 0);
		TE_SendToAll();
		return Plugin_Continue;
	}
	else
	{
		if (g_ExplosionSprite > -1)
		{
			TE_SetupExplosion(vec, g_ExplosionSprite, 0.1, 1, 0, RoundFloat(g_fRadius[client]), 5000);
			TE_SendToAll();
		}
		
		GetClientAbsOrigin(client, vec);
		vec[2] += 10;
		TE_SetupBeamRingPoint(vec, 50.0, g_fRadius[client], g_BeamSprite, g_HaloSprite, 0, 10, 0.5, 30.0, 1.5, orangeColor, 5, 0);
		TE_SendToAll();
		vec[2] += 15;
		TE_SetupBeamRingPoint(vec, 40.0, g_fRadius[client], g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 30.0, 1.5, orangeColor, 5, 0);
		TE_SendToAll();	
		vec[2] += 15;
		TE_SetupBeamRingPoint(vec, 30.0, g_fRadius[client], g_BeamSprite, g_HaloSprite, 0, 10, 0.7, 30.0, 1.5, orangeColor, 5, 0);
		TE_SendToAll();
		vec[2] += 15;
		TE_SetupBeamRingPoint(vec, 20.0, g_fRadius[client], g_BeamSprite, g_HaloSprite, 0, 10, 0.8, 30.0, 1.5, orangeColor, 5, 0);
		TE_SendToAll();		
		
		EmitAmbientSound(SOUND_BOOM, vec, client, SNDLEVEL_RAIDSIREN);

		IgniteEntity(client, g_fDuration[client]);
		KillFireBomb(client);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		
		if (g_iTargetMode[client] > 0)
		{
			new teamOnly = ((g_iTargetMode[client] == 1) ? true : false);
			
			for (new i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i) || !IsPlayerAlive(i) || i == client)
				{
					continue;
				}
				
				if (teamOnly && GetClientTeam(i) != GetClientTeam(client))
				{
					continue;
				}
				
				new Float:pos[3];
				GetClientAbsOrigin(i, pos);
				
				new Float:distance = GetVectorDistance(vec, pos);
				
				if (distance > g_fRadius[client])
				{
					continue;
				}
				
				new Float:duration = g_fDuration[client];
				duration *= (g_fRadius[client] - distance) / g_fRadius[client];

				IgniteEntity(i, duration);
			}		
		}
		return Plugin_Stop;
	}
}

// Freeze and FreezeBomb
FreezeClient(client, time)
{
	if (g_FreezeSerial[client] != 0)
	{
		UnfreezeClient(client);
		return;
	}
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetEntityRenderColor(client, 0, 128, 255, 192);

	new Float:vec[3];
	GetClientEyePosition(client, vec);
	EmitAmbientSound(SOUND_FREEZE, vec, client, SNDLEVEL_RAIDSIREN);

	g_FreezeTime[client] = time;
	g_FreezeSerial[client] = ++ g_Serial_Gen;
	CreateTimer(1.0, Timer_Freeze, client | (g_Serial_Gen << 7), DEFAULT_TIMER_FLAGS);
}

UnfreezeClient(client)
{
	g_FreezeSerial[client] = 0;
	g_FreezeTime[client] = 0;

	if (IsClientInGame(client))
	{
		new Float:vec[3];
		GetClientAbsOrigin(client, vec);
		vec[2] += 10;	
		
		GetClientEyePosition(client, vec);
		EmitAmbientSound(SOUND_FREEZE, vec, client, SNDLEVEL_RAIDSIREN);

		SetEntityMoveType(client, MOVETYPE_WALK);
		
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
}

CreateFreezeBomb(client)
{
	if (g_FreezeBombSerial[client] != 0)
	{
		KillFreezeBomb(client);
		return;
	}
	g_FreezeBombTime[client] = g_iTicks[client];
	g_FreezeBombSerial[client] = ++g_Serial_Gen;
	CreateTimer(1.0, Timer_FreezeBomb, client | (g_Serial_Gen << 7), DEFAULT_TIMER_FLAGS);
}

KillFreezeBomb(client)
{
	g_FreezeBombSerial[client] = 0;
	g_FreezeBombTime[client] = 0;

	if (IsClientInGame(client))
	{
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
}

KillAllFreezes( )
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if (g_FreezeSerial[i] != 0)
		{
			UnfreezeClient(i);
		}

		if (g_FreezeBombSerial[i] != 0)
		{
			KillFreezeBomb(i);
		}
	}
}

PerformFreeze(target)
{
	FreezeClient(target, g_iTicks[target]);
}

PerformFreezeBomb(target)
{
	if (g_FreezeBombSerial[target] != 0)
	{
		KillFreezeBomb(target);
	}
	else
	{
		CreateFreezeBomb(target);
	}
}

public Action:Timer_Freeze(Handle:timer, any:value)
{
	new client = value & 0x7f;
	new serial = value >> 7;

	if (!IsClientInGame(client)
		|| !IsPlayerAlive(client)
		|| g_FreezeSerial[client] != serial)
	{
		UnfreezeClient(client);
		return Plugin_Stop;
	}

	if (g_FreezeTime[client] == 0)
	{
		UnfreezeClient(client);
		
		/* HintText doesn't work on Dark Messiah */
		if (g_GameEngine != SOURCE_SDK_DARKMESSIAH)
		{
			PrintHintText(client, "You are now unfrozen.");
		}
		else
		{
			PrintCenterText(client, "You are now unfrozen.");
		}
		
		return Plugin_Stop;
	}

	if (g_GameEngine != SOURCE_SDK_DARKMESSIAH)
	{
		PrintHintText(client, "You will be unfrozen in %d seconds.", g_FreezeTime[client]);
	}
	else
	{
		PrintCenterText(client, "You will be unfrozen in %d seconds.", g_FreezeTime[client]);
	}
	
	g_FreezeTime[client]--;
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetEntityRenderColor(client, 0, 128, 255, 135);

	new Float:vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 10;

	if (g_GlowSprite > -1)
	{
		TE_SetupGlowSprite(vec, g_GlowSprite, 0.95, 1.5, 50);
	}
	else
	{
		TE_SetupGlowSprite(vec, g_HaloSprite, 0.95, 1.5, 50);
	}
	
	TE_SendToAll();

	return Plugin_Continue;
}

public Action:Timer_FreezeBomb(Handle:timer, any:value)
{
	new client = value & 0x7f;
	new serial = value >> 7;

	if (!IsClientInGame(client)
		|| !IsPlayerAlive(client)
		|| g_FreezeBombSerial[client] != serial)
	{
		KillFreezeBomb(client);
		return Plugin_Stop;
	}

	new Float:vec[3];
	GetClientEyePosition(client, vec);
	g_FreezeBombTime[client]--;

	if (g_FreezeBombTime[client] > 0)
	{
		new color;

		if (g_FreezeBombTime[client] > 1)
		{
			color = RoundToFloor(g_FreezeBombTime[client] * (255.0 / g_iTicks[client]));
			EmitAmbientSound(SOUND_BEEP, vec, client, SNDLEVEL_RAIDSIREN);	
		}
		else
		{
			color = 0;
			EmitAmbientSound(SOUND_FINAL, vec, client, SNDLEVEL_RAIDSIREN);
		}
		
		SetEntityRenderColor(client, color, color, 255, 255);

		decl String:name[64];
		GetClientName(client, name, sizeof(name));
		PrintCenterTextAll("%t", "Till Explodes", name, g_FreezeBombTime[client]);

		GetClientAbsOrigin(client, vec);
		vec[2] += 10;

		TE_SetupBeamRingPoint(vec, 10.0, g_fRadius[client] / 3.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, greyColor, 10, 0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(vec, 10.0, g_fRadius[client] / 3.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, whiteColor, 10, 0);
		TE_SendToAll();
		return Plugin_Continue;
	}
	else
	{
		if (g_ExplosionSprite > -1)
		{
			TE_SetupExplosion(vec, g_ExplosionSprite, 5.0, 1, 0, RoundFloat(g_fRadius[client]), 5000);
			TE_SendToAll();
		}

		EmitAmbientSound(SOUND_BOOM, vec, client, SNDLEVEL_RAIDSIREN);

		KillFreezeBomb(client);
		FreezeClient(client, RoundFloat(g_fDuration[client]));
		
		if (g_iTargetMode[client] > 0)
		{
			new bool:teamOnly = ((g_iTargetMode[client] == 1) ? true : false);
			
			for (new i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i) || !IsPlayerAlive(i) || i == client)
				{
					continue;
				}
				
				if (teamOnly && GetClientTeam(i) != GetClientTeam(client))
				{
					continue;
				}
				
				new Float:pos[3];
				GetClientEyePosition(i, pos);
				
				new Float:distance = GetVectorDistance(vec, pos);
				
				if (distance > g_fRadius[client])
				{
					continue;
				}
				
				if (g_BeamSprite2 > -1)
				{
					TE_SetupBeamPoints(vec, pos, g_BeamSprite2, g_HaloSprite, 0, 1, 0.7, 20.0, 50.0, 1, 1.5, blueColor, 10);
				}
				else
				{
					TE_SetupBeamPoints(vec, pos, g_BeamSprite, g_HaloSprite, 0, 1, 0.7, 20.0, 50.0, 1, 1.5, blueColor, 10);
				}
				TE_SendToAll();
				
				FreezeClient(i, RoundFloat(g_fDuration[client]));
			}		
		}
		return Plugin_Stop;
	}
}

// TimeBomb
CreateTimeBomb(client)
{
	g_TimeBombSerial[client] = ++g_Serial_Gen;
	CreateTimer(1.0, Timer_TimeBomb, client | (g_Serial_Gen << 7), DEFAULT_TIMER_FLAGS);
	g_TimeBombTime[client] = g_iTicks[client];
}

KillTimeBomb(client)
{
	g_TimeBombSerial[client] = 0;

	if (IsClientInGame(client))
	{
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
}

KillAllTimeBombs()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		KillTimeBomb(i);
	}
}

PerformTimeBomb(target)
{
	if (g_TimeBombSerial[target] == 0)
	{
		CreateTimeBomb(target);
	}
	else
	{
		KillTimeBomb(target);
	}
}

public Action:Timer_TimeBomb(Handle:timer, any:value)
{
	new client = value & 0x7f;
	new serial = value >> 7;

	if (!IsClientInGame(client)
		|| !IsPlayerAlive(client)
		|| serial != g_TimeBombSerial[client])
	{
		KillTimeBomb(client);
		return Plugin_Stop;
	}	
	g_TimeBombTime[client]--;
	
	new Float:vec[3];
	GetClientEyePosition(client, vec);
	
	if (g_TimeBombTime[client] > 0)
	{
		new color;
		
		if (g_TimeBombTime[client] > 1)
		{
			color = RoundToFloor(g_TimeBombTime[client] * (128.0 / g_iTicks[client]));
			EmitAmbientSound(SOUND_BEEP, vec, client, SNDLEVEL_RAIDSIREN);	
		}
		else
		{
			color = 0;
			EmitAmbientSound(SOUND_FINAL, vec, client, SNDLEVEL_RAIDSIREN);
		}
		
		SetEntityRenderColor(client, 255, 128, color, 255);

		decl String:name[64];
		GetClientName(client, name, sizeof(name));
		PrintCenterTextAll("%t", "Till Explodes", name, g_TimeBombTime[client]);
		
		GetClientAbsOrigin(client, vec);
		vec[2] += 10;

		TE_SetupBeamRingPoint(vec, 10.0, g_fRadius[client] / 3.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, greyColor, 10, 0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(vec, 10.0, g_fRadius[client] / 3.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, whiteColor, 10, 0);
		TE_SendToAll();
		return Plugin_Continue;
	}
	else
	{
		if (g_ExplosionSprite > -1)
		{
			TE_SetupExplosion(vec, g_ExplosionSprite, 5.0, 1, 0, RoundFloat(g_fRadius[client]), 5000);
			TE_SendToAll();
		}

		EmitAmbientSound(SOUND_BOOM, vec, client, SNDLEVEL_RAIDSIREN);

		ForcePlayerSuicide(client);
		KillTimeBomb(client);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		
		if (g_iTargetMode[client] > 0)
		{
			new teamOnly = ((g_iTargetMode[client] == 1) ? true : false);
			
			for (new i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i) || !IsPlayerAlive(i) || i == client)
				{
					continue;
				}
				
				if (teamOnly && GetClientTeam(i) != GetClientTeam(client))
				{
					continue;
				}
				
				new Float:pos[3];
				GetClientEyePosition(i, pos);
				
				new Float:distance = GetVectorDistance(vec, pos);
				
				if (distance > g_fRadius[client])
				{
					continue;
				}
				
				new damage = 220;
				damage = RoundToFloor(damage * ((g_fRadius[client] - distance) / g_fRadius[client]));
					
				SlapPlayer(i, damage, false);
				
				if (g_ExplosionSprite > -1)
				{
					TE_SetupExplosion(pos, g_ExplosionSprite, 0.05, 1, 0, 1, 1);
					TE_SendToAll();	
				}
				
				/* ToDo
				new Float:dir[3];
				SubtractVectors(vec, pos, dir);
				TR_TraceRayFilter(vec, dir, MASK_SOLID, RayType_Infinite, TR_Filter_Client);

				if (i == TR_GetEntityIndex())
				{
					new damage = 100;
					new radius = GetConVarInt(g_Cvar_TimeBombRadius) / 2;
					
					if (distance > radius)
					{
						distance -= radius;
						damage = RoundToFloor(damage * ((radius - distance) / radius));
					}
					
					SlapPlayer(i, damage, false);
				}
				*/
			}		
		}
		return Plugin_Stop;
	}
}