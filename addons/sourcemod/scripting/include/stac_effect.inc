#if defined __stac_effect_included_
  #endinput
#endif
#define __stac_effect_included_

#define CLR_DEFAULT		1
#define CLR_LIGHTGREEN	3
#define CLR_GREEN		4
#define CLR_DARKGREEN	5

#define STAC_VERSION	"0.5.0"
#define STAC_AUTHORS	"Rothgar, Tsunami, FlyingMongoose"
#define STAC_WEBSITE	"http://dawgclan.github.com/stac"

functag public STAC_Effect(Handle:plugin, numParams);

enum STACEffect_Type
{
	STACEffect_Blind,
	STACEffect_Burn,
	STACEffect_Drug,
	STACEffect_Explode,
	STACEffect_FireBomb,
	STACEffect_Freeze,
	STACEffect_FreezeBomb,
	STACEffect_TimeBomb
}


/**
 * Executes an explosion effect on the client
 *
 * @param	client		Player index
 * @param	type		STACEffects_Type
 * @param	radius		Optional param that allows a Float to be passed
 * 						for radii of functions (such as bombs and beacon)
 *						Default = 375.0
 * @param	ticks		Optional param that allows an int to be passed for customizable timers
 * 						such as in FireBomb, and TimeBomb.
 *						Default = 10
 * @param	targetmode	Optional param that allows you to set the mode of a bomb
 *						0 = Target Only
 *						1 = Target Team Mates and Target
 *						2 = Everyone
 * @param	duration	Optional param that allows an amount of time before an effect wears off
 *						such as "Freeze", "FreezeBomb", and "Burn"
 *						Default = 20.0
 *
 * @noreturn
 * @error				Client not in game.
 */
native STAC_Effect(client,STACEffect_Type:type,Float:radius=375.0,ticks=10,targetmode=0,Float:duration=20.0);

/**
 * Executes a beacon on the client
 *
 * @param	client
 *
 * @noreturn
 * @error	Client not in game.
 */
native STACEffect_Beacon(client);
 
public SharedPlugin:__pl_stac_effect = 
{
	name = "stac_effect",
	file = "stac_effect.smx",
	#if defined REQUIRE_PLUGIN
	required = 1,
	#else
	required = 0,
	#endif
};

public __pl_stac_effect_SetNTVOptional()
{
	MarkNativeAsOptional("STAC_Effect");
}