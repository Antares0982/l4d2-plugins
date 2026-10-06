#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <../common>
#pragma semicolon 1
#define VERSION "1.0"

public Plugin myinfo =
{
	name        = "Friendly Fire Return Damage",
	author      = "Antares",
	description = "Friendly Fire will give return damage to the attacker",
	version     = "1.0"
};

Handle ff_limit           = INVALID_HANDLE;
Handle ff_incapacitate    = INVALID_HANDLE;
Handle ff_kick            = INVALID_HANDLE;
Handle ff_kicklimit       = INVALID_HANDLE;
Handle ff_returnbotdamage = INVALID_HANDLE;
Handle IncapMaxHealth     = INVALID_HANDLE;
int    friendlyFire[MAXPLAYERS + 1];
int    totalFriendlyFire[MAXPLAYERS + 1];

public OnPluginStart()
{
	ff_limit           = CreateConVar("l4d_damage_fflimit", "5", "dmg limit, friendly fire greater than this limit will cause return damage", FCVAR_REPLICATED | FCVAR_GAMEDLL | FCVAR_NOTIFY, true, 1.0, true, 100.0);
	ff_incapacitate    = CreateConVar("l4d_damage_ffincapacitate", "1", "If this parameter = 1, friendly fire will incapacitate attacker", FCVAR_REPLICATED | FCVAR_GAMEDLL | FCVAR_NOTIFY, true, 0.0, true, 1.0);
	ff_kick            = CreateConVar("l4d_damage_ffkick", "0", "If this parameter = 1, server will kick player if total friendly fire is higher than friendly fire limit", FCVAR_REPLICATED | FCVAR_GAMEDLL | FCVAR_NOTIFY, true, 0.0, true, 1.0);
	ff_kicklimit       = CreateConVar("l4d_damage_ffkicklimit", "2000", "Player who caused total friendly fire higher than this parameter will get kicked if ff_kick = 1", FCVAR_REPLICATED | FCVAR_GAMEDLL | FCVAR_NOTIFY, true, 100.0, true, 2000.0);
	ff_returnbotdamage = CreateConVar("l4d_damage_returnbotdmg", "0", "Shoot bot will get hurt if this parameter = 1", FCVAR_REPLICATED | FCVAR_GAMEDLL | FCVAR_NOTIFY, true, 0.0, true, 1.0);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);    // 不使用friendly_fire事件是因为friendly_fire事件没有伤害数值
	AutoExecConfig(true, "return_dmg");
	IncapMaxHealth = FindConVar("survivor_incap_health");
}

public Action Event_PlayerHurt(Handle event, const char[] name, bool dontBroadcast)
{
	int attackerId   = GetEventInt(event, "attacker");
	int attacker     = GetClientOfUserId(attackerId);
	int victimId     = GetEventInt(event, "userid");
	int victim       = GetClientOfUserId(victimId);
	int dmg          = GetEventInt(event, "dmg_health");
	int dmgtype      = GetEventInt(event, "type");
	int returnbotdmg = GetConVarInt(ff_returnbotdamage);

	// 判断是否符合条件
	if (!(dmg > 0 && is_client_actual(victim) && (returnbotdmg == 1 || !IsFakeClient(victim)) && is_client_actual(attacker) && victim != attacker && (GetClientTeam(victim) == GetClientTeam(attacker)) && !IsFireDamage(dmgtype))) { return Plugin_Continue; }

	friendlyFire[attacker] += dmg;
	totalFriendlyFire[attacker] += dmg;
	int ff          = GetConVarInt(ff_limit);
	int ff_inc      = GetConVarInt(ff_incapacitate);
	int ffkick      = GetConVarInt(ff_kick);
	int ffkicklimit = GetConVarInt(ff_kicklimit);
	if (friendlyFire[attacker] < ff) { return Plugin_Continue; }

	int   health          = GetEntProp(attacker, Prop_Send, "m_iHealth");
	int   return_dmg      = 0;
	float floathealthbuff = GetEntPropFloat(attacker, Prop_Send, "m_healthBuffer");

	// 计算反伤
	return_dmg += friendlyFire[attacker] / ff;
	friendlyFire[attacker] = friendlyFire[attacker] % ff;

	// kick 就不算反伤了
	if (ffkick == 1 && totalFriendlyFire[attacker] > ffkicklimit)
	{
		char atker_name[64];
		if (GetClientName(attacker, atker_name, 64))
		{
			PrintToChatAll("\x04玩家：%s 因为对队友造成太多友伤被踢出游戏\x01", atker_name);
		}
		KickClient(attacker);
		return Plugin_Continue;
	}

	// 血量还够
	if (health - return_dmg > 0)
	{
		SetEntProp(attacker, Prop_Send, "m_iHealth", health - return_dmg);
		return Plugin_Continue;
	}

	// 血量不够，处理击倒或者死亡的逻辑

	// 虚血还够，不击倒
	if (health + floathealthbuff - return_dmg > 1)
	{
		SetEntProp(attacker, Prop_Send, "m_iHealth", 1);
		SetEntPropFloat(attacker, Prop_Send, "m_healthBuffer", health + floathealthbuff - return_dmg - 1);
		return Plugin_Continue;
	}

	// 血+虚血扣完之后小于1但是没倒地，将虚血扣完
	if (health + floathealthbuff - return_dmg > 0)
	{
		SetEntProp(attacker, Prop_Send, "m_iHealth", 1);
		SetEntPropFloat(attacker, Prop_Send, "m_healthBuffer", 0.0);
		return Plugin_Continue;
	}

	// 倒地的处理，ff_inc为true需要击倒玩家
	if (ff_inc != 0)
	{
		// 是否濒死状态，濒死则处死
		int IsThirdStrike = GetEntProp(attacker, Prop_Send, "m_bIsOnThirdStrike");
		if (IsThirdStrike != 0)
		{
			// 处死
			ForcePlayerSuicide(attacker);
			PrintHintText(attacker, "你因为友伤的反伤死亡了，请注意不要攻击队友");
			char atker_name[64];
			if (GetClientName(attacker, atker_name, 64))
			{
				PrintToChatAll("\x04玩家：%s 因为对队友造成太多友伤，反伤死亡了\x01", atker_name);
			}
		}
		else
		{
			// 击倒
			int defaultIncapMaxHealth = GetConVarInt(IncapMaxHealth);
			SetEntPropFloat(attacker, Prop_Send, "m_healthBuffer", 0.0);
			SetEntProp(attacker, Prop_Send, "m_isIncapacitated", true, 1);
			SetEntProp(attacker, Prop_Send, "m_iHealth", defaultIncapMaxHealth);
			PrintHintText(attacker, "你因为友伤的反伤倒地了，请注意不要攻击队友");
			char atker_name[64];
			if (GetClientName(attacker, atker_name, 64))
			{
				PrintToChatAll("\x04玩家：%s 因为对队友造成太多友伤，反伤倒地了\x01", atker_name);
			}
		}
	}
	else
	{
		// ff_inc为false，不会击倒玩家，但清除所有血
		SetEntProp(attacker, Prop_Send, "m_iHealth", 1);
		SetEntPropFloat(attacker, Prop_Send, "m_healthBuffer", 0.0);
		PrintHintText(attacker, "请注意不要攻击队友");
	}

	return Plugin_Continue;
}

public bool IsFireDamage(int dmgtype)
{
	return 0 != (dmgtype & DMG_BURN);
}

public bool IsBlastDamage(int dmgtype)
{
	return 0 != (dmgtype & DMG_BLAST);
}

public OnClientDisconnect(int client)
{
	if (client >= 1 && client <= MaxClients)
	{
		totalFriendlyFire[client] = 0;
		friendlyFire[client]      = 0;
	}
}
