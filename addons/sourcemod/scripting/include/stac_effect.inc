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

//functag public STAC_Effect(Handle:plugin, numParams);

/**
 * Executes a beacon on the client
 *
 * @param	client	Client index
 *
 * @noreturn
 * @error	Client not in game.
 */
native STACEffect_Beacon(client);

/**
 * Blinds a client
 *
 * @param	client	Client index
 *
 * @noreturn
 * @error	Client not in game
 */
native STACEffect_Blind(client);

/**
 * Sets a client on fire
 *
 * @param	client	Client index
 *
 * @noreturn
 * @error	Client not in game
 */
native STACEffect_Burn(client);

/**
 * Drugs a client
 *
 * @param	client	Client index
 * 
 * @noreturn
 * @error	Client not in game
 */
native STACEffect_Drug(client);

/**
 * Blows up a client
 *
 * @param	client	Client index
 * 
 * @noreturn
 * @error	Client not in game
 */
native STACEffect_Explode(client);

/**
 * Turns a client into a firebomb
 *
 * @param	client	Client index
 * 
 * @noreturn
 * @error	Client not in game
 */
native STACEffect_FireBomb(client);

/**
 * Freezes a client
 *
 * @param	client	Client index
 * 
 * @noreturn
 * @error	Client not in game
 */
native STACEffect_Freeze(client);

/**
 * Turns a client into a freezebomb
 *
 * @param	client	Client index
 * 
 * @noreturn
 * @error	Client not in game
 */
native STACEffect_FreezeBomb(client);

/**
 * Turns a client into a timebomb
 *
 * @param	client	Client index
 * 
 * @noreturn
 * @error	Client not in game
 */
native STACEffect_TimeBomb(client);

public __pl_stac_effect_SetNTVOptional()
{
	MarkNativeAsOptional("STACEffect_Beacon");
	MarkNativeAsOptional("STACEffect_Blind");
	MarkNativeAsOptional("STACEffect_Burn");
	MarkNativeAsOptional("STACEffect_Drug");
	MarkNativeAsOptional("STACEffect_Explode");
	MarkNativeAsOptional("STACEffect_FireBomb");
	MarkNativeAsOptional("STACEffect_Freeze");
	MarkNativeAsOptional("STACEffect_FreezeBomb");
	MarkNativeAsOptional("STACEffect_TimeBomb");
}