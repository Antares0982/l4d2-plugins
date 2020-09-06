#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#define VERSION "1.1"

public Plugin myinfo = 
{
	name = "Friendly Fire Add Health",
	author = "Antares",
	description = "Friendly fire will increase your health",
	version = "1.0"
};

public OnPluginStart()
{
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	new attackerId = GetEventInt(event, "attacker");
	new attacker = GetClientOfUserId(attackerId);
	new victimId = GetEventInt(event, "userid");
	new victim = GetClientOfUserId(victimId);
	new dmg = GetEventInt(event, "dmg_health");
	new victimhealth = GetEntProp(victim, Prop_Send, "m_iHealth");
	if(dmg > 0 && IsClientActual(victim) && IsClientActual(attacker) && victim != attacker && (GetClientTeam(victim) == GetClientTeam(attacker)) && (GetEntProp(victim, Prop_Send, "m_isIncapacitated") == 0 || victimhealth > 200))
	{
		new CurrentReviveCount = GetEntProp(attacker, Prop_Send, "m_currentReviveCount");
		new Float:healthbuff = GetEntPropFloat(attacker, Prop_Send, "m_healthBuffer");
		if(CurrentReviveCount > 0)
		{
			new Float:dmgfloat = dmg * 1.0;
			healthbuff+=dmgfloat;
			if(healthbuff > 100.0){SetEntPropFloat(attacker, Prop_Send, "m_healthBuffer", 100.0);}
			else{SetEntPropFloat(attacker, Prop_Send, "m_healthBuffer", healthbuff);}
		}
		else
		{
			new health = GetEntProp(attacker, Prop_Send, "m_iHealth");
			if(dmg + health > 100)
			{
				SetEntProp(attacker, Prop_Send, "m_iHealth", 100);
				SetEntPropFloat(attacker, Prop_Send, "m_healthBuffer", 0.0);
			}
			else if(dmg * 1.0 + healthbuff + health * 1.0 > 100.0)
			{
				SetEntProp(attacker, Prop_Send, "m_iHealth", health + dmg);
				SetEntPropFloat(attacker, Prop_Send, "m_healthBuffer", 100.0 - health * 1.0 - dmg * 1.0);
			}
			else
			{
				SetEntProp(attacker, Prop_Send, "m_iHealth", health + dmg);
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
