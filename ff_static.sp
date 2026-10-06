#include <../common>
#include <l4d2_mission_manager>
#include <sdktools>
#include <sourcemod>
#pragma semicolon 1
#define VERSION "1.0"

public Plugin myinfo =
{
	name        = "Friendly Fire Static",
	author      = "Antares",
	description = "Show friendly fire statics",
	version     = "1.0"
};

enum struct FFdata
{
	int totalFriendlyFire;
	int incapFriend;
	int killFriend;
}

// int  totalFriendlyFire[MAXPLAYERS + 1];
// int  incapFriend[MAXPLAYERS + 1];
// int  killFriend[MAXPLAYERS + 1];

char      stored_mission_name[64];
StringMap steamid_ffdata_map;    // char[] -> FFdata
Handle    static_show_loop_time = INVALID_HANDLE;

public OnPluginStart()
{
	steamid_ffdata_map    = CreateTrie();
	//
	static_show_loop_time = CreateConVar("l4d_friendly_fire_loop_time", "60.0", "Time, in seconds, friendly fire static will show again after shown once", _, true, 1.0, true, 300.0);

	AutoExecConfig(true, "ff_static");
	// empty it
	stored_mission_name[0] = 0;

	CreateTimer(GetConVarFloat(static_show_loop_time), Timer_showFriendlyFire, _, TIMER_REPEAT);
	// hooks
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("mission_lost", Event_ShowFriendlyFire);
	// hook incap_start because incap event does not have its life before incap
	HookEvent("player_incapacitated_start", Event_IncapFriend, EventHookMode_Pre);
	HookEvent("player_death", Event_player_dead);
	HookEvent("finale_win", Event_finale_win, EventHookMode_Pre);
	// HookEvent("map_transition", Event_map_transition, EventHookMode_Pre);
}

void PrintData(int client, FFdata data)
{
	if (data.totalFriendlyFire == 0 && data.incapFriend == 0 && data.killFriend == 0) return;
	char client_name[64];
	if (!GetClientName(client, client_name, 64)) return;
	char ff[64];
	char incap[64];
	char kill[64];
	// ff
	if (data.totalFriendlyFire != 0) { Format(ff, 64, "\t\x04友伤 \x05%d", data.totalFriendlyFire); }
	else ff[0] = 0;
	// incap
	if (data.incapFriend != 0) { Format(incap, 64, "\t\x04击倒队友 \x05%d", data.incapFriend); }
	else incap[0] = 0;
	// kill
	if (data.killFriend != 0) { Format(kill, 64, "\t\x04杀死队友 \x05%d", data.killFriend); }
	else kill[0] = 0;

	PrintToChatAll("\x04玩家 \x05%s%s%s%s\x01", client_name, ff, incap, kill);
}

void updateFFData(char[] steamid, FFdata data)
{
	int buffer[3];
	// if (!GetTrieValue(steamid_ffdata_map, steamid, dataref))
	if (!GetTrieArray(steamid_ffdata_map, steamid, buffer, 3))
	{
		// not set, set new data
		buffer[0] = data.totalFriendlyFire;
		buffer[1] = data.incapFriend;
		buffer[2] = data.killFriend;
		if (!SetTrieArray(steamid_ffdata_map, steamid, buffer, 3))
		{
			PrintToChatAll("Error: 存储友伤数据失败");
		}
	}
	else {
		buffer[0] += data.totalFriendlyFire;
		buffer[1] += data.incapFriend;
		buffer[2] += data.killFriend;
		if (!SetTrieArray(steamid_ffdata_map, steamid, buffer, 3))
		{
			PrintToChatAll("Error: 存储友伤数据失败");
		}
	}
}

void readFFData(int client, FFdata data)
{
	char steamid[64];
	int  buffer[3];
	if (!is_client_actual(client) || IsFakeClient(client))
	{
		// PrintToChatAll("无效用户%d", client);
		data.totalFriendlyFire = 0;
		data.incapFriend       = 0;
		data.killFriend        = 0;
		return;
	}
	if (!get_steamid_safe(client, steamid, 64))
	{
		data.totalFriendlyFire = 0;
		data.incapFriend       = 0;
		data.killFriend        = 0;
		return;
	}
	//
	if (!GetTrieArray(steamid_ffdata_map, steamid, buffer, 3))
	{
		return;
	}
	data.totalFriendlyFire = buffer[0];
	data.incapFriend       = buffer[1];
	data.killFriend        = buffer[2];
}

// 判断黑枪王是谁。返回[1, MAXPLAYERS]范围的整数表示黑枪王的client，
// 返回0表示没有找到黑枪王。
int determine_most_friendlyfire(FFdata[] dataarray)
{
	int maxk  = 0;
	int maxc  = 0;
	int maxd  = 0;
	int index = 0;
	for (int i = 1; i <= MAXPLAYERS; ++i)
	{
		if (!is_client_actual(i)) continue;
		int kills = dataarray[i].killFriend;
		int incaps = dataarray[i].incapFriend;
		int damage = dataarray[i].totalFriendlyFire;
		if (kills > maxk
		    || (kills == maxk && incaps > maxc)
		    || (kills == maxk && incaps == maxc && damage > maxd))
		{
			maxk  = kills;
			maxc  = incaps;
			maxd  = damage;
			index = i;
		}
	}
	return index;
}

// internal function
public InternalShowFriendlyFire()
{
	// if no friendly fire, don't print anything
	FFdata dataarray[MAXPLAYERS + 1];
	for (int i = 1; i <= MAXPLAYERS; ++i)
	{
		readFFData(i, dataarray[i]);
	}
	for (int i = 1; i <= MAXPLAYERS; ++i)
	{
		if (dataarray[i].totalFriendlyFire != 0 || dataarray[i].incapFriend != 0 || dataarray[i].killFriend != 0) break;
		if (i == MAXPLAYERS)
		{
			return;
		}
	}
	// begin main logic
	PrintToChatAll("\x04目前友伤统计：\x01");

	for (int i = 1; i <= MAXPLAYERS; ++i)
	{
		char client_name[64];
		if (is_client_actual(i) && !IsFakeClient(i) && GetClientName(i, client_name, 64))
		{
			PrintData(i, dataarray[i]);
		}
	}

	// 获取黑枪王
	int maxone = determine_most_friendlyfire(dataarray);
	if (maxone != 0)
	{
		char client_name[64];
		if (GetClientName(maxone, client_name, 64))
		{
			PrintToChatAll("\x04黑枪王：\x05%s\x01", client_name);
		}
	}
}

void internalClearData()
{
	ClearTrie(steamid_ffdata_map);
	steamid_ffdata_map = CreateTrie();
	PrintToChatAll("友伤数据刷新");
}

// event hooks
public Action Event_ShowFriendlyFire(Handle event, const char[] name, bool dontBroadcast)
{
	InternalShowFriendlyFire();
	return Plugin_Continue;
}

public Action Event_PlayerHurt(Handle event, const char[] name, bool dontBroadcast)
{
	int attackerId = GetEventInt(event, "attacker");
	int attacker   = GetClientOfUserId(attackerId);
	int victimId   = GetEventInt(event, "userid");
	int victim     = GetClientOfUserId(victimId);
	int dmg        = GetEventInt(event, "dmg_health");
	if (!(dmg > 0 && is_human_player_friendly_fire(victim, attacker))) { return Plugin_Continue; }
	// steamid
	char steamid[64];
	get_steamid_safe(attacker, steamid, 64);
	// add
	FFdata temp_data;
	temp_data.totalFriendlyFire = dmg;
	temp_data.incapFriend       = 0;
	temp_data.killFriend        = 0;
	updateFFData(steamid, temp_data);
	return Plugin_Continue;
}

public Action Event_IncapFriend(Handle event, const char[] name, bool dontBroadcast)
{
	int attackerId = GetEventInt(event, "attacker");
	int attacker   = GetClientOfUserId(attackerId);
	int victimId   = GetEventInt(event, "userid");
	int victim     = GetClientOfUserId(victimId);
	if (!(is_client_actual(victim) && !IsFakeClient(victim) && is_client_actual(attacker) && victim != attacker && (GetClientTeam(victim) == GetClientTeam(attacker)))) { return Plugin_Continue; }
	// calculate current life
	int   life       = GetEntProp(victim, Prop_Send, "m_iHealth");
	float healthbuff = GetEntPropFloat(victim, Prop_Send, "m_healthBuffer");
	life += RoundFloat(healthbuff);
	// steamid
	char steamid[64];
	get_steamid_safe(attacker, steamid, 64);
	// add
	FFdata temp_data;
	temp_data.totalFriendlyFire = life;
	temp_data.incapFriend       = 1;
	temp_data.killFriend        = 0;
	updateFFData(steamid, temp_data);
	return Plugin_Continue;
}

public Action Event_player_dead(Handle event, const char[] name, bool dontBroadcast)
{
	int attackerId = GetEventInt(event, "attacker");
	int attacker   = GetClientOfUserId(attackerId);
	int victimId   = GetEventInt(event, "userid");
	int victim     = GetClientOfUserId(victimId);
	if (!is_human_player_friendly_fire(victim, attacker)) { return Plugin_Continue; }
	// steamid
	char steamid[64];
	get_steamid_safe(attacker, steamid, 64);
	// add
	FFdata temp_data;
	temp_data.totalFriendlyFire = 0;
	temp_data.incapFriend       = 0;
	temp_data.killFriend        = 1;
	updateFFData(steamid, temp_data);
	return Plugin_Continue;
}

public Action Event_finale_win(Handle event, const char[] name, bool dontBroadcast)
{
	InternalShowFriendlyFire();
	internalClearData();
	return Plugin_Continue;
}

// timer
public Action Timer_showFriendlyFire(Handle timer)
{
	InternalShowFriendlyFire();
	return Plugin_Continue;
}

// forward
public void OnClientConnected(int client)
{
	char currentMission[64];
	get_mission(currentMission);
	if (strcmp(currentMission, stored_mission_name, false) != 0)
	{
		// not equal
		strcopy(stored_mission_name, 64, currentMission);
		internalClearData();
	}
}
