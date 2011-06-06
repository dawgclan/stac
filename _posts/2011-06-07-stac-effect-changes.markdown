---
layout: post
title: STAC Effects Changes
author: FlyingMongoose
---

So, last night, Rothgar and I were discussing and we established an inherent flaw in my "including all of these effects in one big file". It contradicts one of our biggeest goals.
Efficiency.

Basically one major part of STAC is we want to make it as clean, neat, and tidy as possible for not only the end user, but for us in developing expansions of the system, and while it's nice to have all of these effects in one place, what if you're only running one "fun" punishment?

Well in that method that means ALL of the effects are being loaded into memory, and possibly never being used, or lets say your mod you're running doesn't have the proper reference to a file we utilize for sound effects or models, then it just won't work.

So we had to scrap that method, however, we still wanted to continue to provide the ability to call upon these functions from within ANY plugin. So our new method should resolve this issue as well as provide the natives necessary for performing these tasks.

And so we have this new method, within the stac-explode punishment I have added the following. A simple solution to a complex problem.

	public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
	{
		RegPluginLibrary("stac-explode");
		CreateNative("STACEffect_Explode", Native_STACEffect_Explode);
		return APLRes_Success;
	}
	
	public Native_STACEffect_Explode(Handle:plugin, numParams)
	{
		new iClient = GetNativeCell(1);
		if(IsClientInGame(iClient))
		{
			PerformExplode(iClient);
		}
	}

This now gives the user access to the following native.

	native STACEffect_Explode(client);
	
So, lets say, for example, I want to slay the player in cstrike for a team attack, and I want it to slay no matter what but if possble utilize the explode effect. Simple.

	new bool:g_bAllowExplodeEffect = false;
	
	public OnPluginStart()
	{
		if(LibraryExists("stac-explode"))
			OnLibraryAdded("stac-explode");
	}
	
	public OnLibraryAdded(const String:name[])
	{
		if(StrEqual(name, "stac-explode"))
			g_bAllowExplodeEffect = true;
	}
	
	public STAC_OnPlayerHurt(attacker,victim)
	{
		if(GetClientTeam(attacker) == GetClientTeam(victim))
			SlayPlayer(iAttacker);
	}
	
	SlayPlayer(client)
	{
		if(g_bAllowExplodeEffect)
			STACEffect_Explode(client);
		else
			ForcePlayerSuicide(client);
	}

Here is the list of series of events
1. We define a boolean and set it to false by default
2. We check to see if the library "stac-explode" exists, and if it does we call the "OnLibrraryAdded" function, passing "stac-explode"
3. Within OnLibraryAdded, which we define below that we check again to see if "stac-explode" really is loaded, and if so, we allow the explode effect boolean to be true.
4. Then, within the player_hurt event (as passed by the STAC base), we see if the victim and attacker team's are the same, if they are, we execute the "SlayPlayer" function on the attacker.
5. Within the SlayPlayer function we check to see if the allow explode effect boolean is true, if it is, then we go ahead and calle the effect provided to use by stac-explode, if not we just slay using the SourceMod's default slay function.

Obviously a lot of this stuff is very mod/game specific, however this is as generic as I can get it. Each unique punishment will have it's own native no matter what. However, if a punishment is not loaded, you will not be able to use it's defined native.