#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#define VERSION "1.0"

public Plugin myinfo = 
{
	name = "Return Damage",
	author = "Antares",
	description = "Return Damage",
	version = "1.0"
};

new Handle:ff_limit=INVALID_HANDLE;
new Handle:ff_incapacitate=INVALID_HANDLE;
new Handle:ff_kick=INVALID_HANDLE;
new Handle:ff_kicklimit=INVALID_HANDLE;
new Handle:ff_returnbotdamage=INVALID_HANDLE;
new Handle:IncapMaxHealth=INVALID_HANDLE;
new friendlyFire[MAXPLAYERS+1];
new totalFriendlyFire[MAXPLAYERS+1];
new DMG_BURN = 8;
public OnPluginStart()
{
	ff_limit = CreateConVar("l4d_damage_fflimit", "5", "dmg limit, friendly fire greater than this limit will cause return damage", FCVAR_REPLICATED|FCVAR_GAMEDLL|FCVAR_NOTIFY, true, 1.0, true, 100.0);
	ff_incapacitate = CreateConVar("l4d_damage_ffincapacitate", "1", "If this parameter = 1, friendly fire will incapacitate player", FCVAR_REPLICATED|FCVAR_GAMEDLL|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	ff_kick = CreateConVar("l4d_damage_ffkick", "0", "If this parameter = 1, server will kick player if friendly fire is higher than friendly fire limit", FCVAR_REPLICATED|FCVAR_GAMEDLL|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	ff_kicklimit = CreateConVar("l4d_damage_ffkicklimit", "2000", "Player who caused friendly fire higher than this parameter will get kicked if ff_kick = 1", FCVAR_REPLICATED|FCVAR_GAMEDLL|FCVAR_NOTIFY, true, 100.0, true, 2000.0);
	ff_returnbotdamage = CreateConVar("l4d_damage_returnbotdmg", "0", "Shoot bot will get hurt if this parameter = 1", FCVAR_REPLICATED|FCVAR_GAMEDLL|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
	AutoExecConfig(true, "return_dmg");
	IncapMaxHealth = FindConVar("survivor_incap_health");
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attackerId = GetEventInt(event, "attacker");
	new attacker = GetClientOfUserId(attackerId);
	new victimId = GetEventInt(event, "userid");
	new victim = GetClientOfUserId(victimId);
	new dmg = GetEventInt(event, "dmg_health");
	new dmgtype = GetEventInt(event, "type");
	new returnbotdmg = GetConVarInt(ff_returnbotdamage);
	if(dmg > 0 && IsClientActual(victim) && (returnbotdmg == 1 || !IsFakeClient(victim)) && IsClientActual(attacker) && victim != attacker && (GetClientTeam(victim) == GetClientTeam(attacker)) && !IsFireDamage(dmgtype))
	{
		friendlyFire[attacker] += dmg;
		totalFriendlyFire[attacker] += dmg;
		new ff = GetConVarInt(ff_limit);
		new ff_inc = GetConVarInt(ff_incapacitate);
		new ffkick = GetConVarInt(ff_kick);
		new ffkicklimit = GetConVarInt(ff_kicklimit);
		if(friendlyFire[attacker]>=ff)
		{
			new health = GetEntProp(attacker, Prop_Send, "m_iHealth");
			new return_dmg=0;
			new Float:floathealthbuff = GetEntPropFloat(attacker, Prop_Send, "m_healthBuffer");
			while(friendlyFire[attacker]>=ff)
			{
				return_dmg++;
				friendlyFire[attacker]-=ff;
			}
			if(ffkick == 1 && totalFriendlyFire[attacker] > ffkicklimit)
			{
				KickClient(attacker);
			}
			else
			{
				if ((health - return_dmg) > 0)
				{
					SetEntProp(attacker, Prop_Send, "m_iHealth", (health - return_dmg));
				}
				else
				{
					if(health + floathealthbuff - return_dmg > 1)
					{
						SetEntProp(attacker, Prop_Send, "m_iHealth", 1);
						SetEntPropFloat(attacker, Prop_Send, "m_healthBuffer", health + floathealthbuff - return_dmg - 1);
					}
					else if(health + floathealthbuff - return_dmg > 1)
					{
						SetEntProp(attacker, Prop_Send, "m_iHealth", 1);
						SetEntPropFloat(attacker, Prop_Send, "m_healthBuffer", 0.0);
					}
					else
					{
						if(ff_inc == 1)
						{
							new IsThirdStrike = GetEntProp(attacker, Prop_Send, "m_bIsOnThirdStrike");
							if(IsThirdStrike == 1)
							{
								ForcePlayerSuicide(attacker);
							}
							else
							{
								new defaultIncapMaxHealth = GetConVarInt(IncapMaxHealth);
								SetEntPropFloat(attacker, Prop_Send, "m_healthBuffer", 0.0);
								SetEntProp(attacker, Prop_Send, "m_isIncapacitated", true, 1);
								SetEntProp(attacker, Prop_Send, "m_iHealth", defaultIncapMaxHealth);
							}
						}
						else
						{
							SetEntProp(attacker, Prop_Send, "m_iHealth", 1);
							SetEntPropFloat(attacker, Prop_Send, "m_healthBuffer", 0.0);
							PrintHintText(attacker, "Don't shoot teammates!");
						}
					}
					
				}
			}
		}
	}
	return Plugin_Continue;
}
public bool:IsClientActual(client)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client)) return false;
	return true;
}
public bool:IsFireDamage(dmgtype)
{
	if(dmgtype & DMG_BURN){return true;}
	return false;
}
public OnClientDisconnect(client)
{
	if (IsClientActual(client))
	{
		totalFriendlyFire[client] = 0;
		friendlyFire[client] = 0;
	}
}
