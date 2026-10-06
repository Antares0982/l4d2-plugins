#include <sdktools>
#include <sourcemod>
#pragma semicolon 1
#define VERSION "1.0"

public Plugin myinfo =
{
	name        = "Safehouse Door Is Killing You",
	author      = "Antares",
	description = "Kill player who open and close safehouse door frequently",
	version     = "1.0"
};

Handle PlayerDoorHandle[MAXPLAYERS + 1];
int PlayerDoorCount[MAXPLAYERS + 1];
 Handle kill_limit           = INVALID_HANDLE;
 Handle count_dec_every10sec = INVALID_HANDLE;

public OnPluginStart()
{
	HookEvent("door_open", Event_PlayerOpenCloseDoor, EventHookMode_Pre);
	HookEvent("door_close", Event_PlayerOpenCloseDoor, EventHookMode_Pre);
	kill_limit           = CreateConVar("door_kill_limit", "8", "count limit, open or close the door will increase count. If count equals this limit, player will be killed", FCVAR_REPLICATED | FCVAR_GAMEDLL | FCVAR_NOTIFY, true, 4.0, true, 30.0);
	count_dec_every10sec = CreateConVar("count_dec_every10second", "2", "Every 10 seconds count will decrease this number", FCVAR_REPLICATED | FCVAR_GAMEDLL | FCVAR_NOTIFY, true, 1.0, true, 10.0);
	AutoExecConfig(true, "door_kill");
}

public Action Event_PlayerOpenCloseDoor(Handle event, const String: name[], bool dontBroadcast)
{
	bool isSafeHouseDoor = GetEventBool(event, "checkpoint", false);
	if (!isSafeHouseDoor)
	{
		return Plugin_Continue;
	}
	int playerId = GetEventInt(event, "userid");
	int player   = GetClientOfUserId(playerId);
	PlayerDoorCount[player]++;
	int klimit = GetConVarInt(kill_limit);
	if (PlayerDoorCount[player] >= klimit)
	{
		char playername[64];
		if (!GetClientName(player, playername, 64)) { return Plugin_Continue; }
		ForcePlayerSuicide(player);
		PrintToChatAll("%s 因为玩门被处死了，小朋友们千万不要学他~", playername);
	}
	if (!PlayerDoorHandle[player])
	{
		PlayerDoorHandle[player] = CreateTimer(10.0, Timer_ClearCount, player);
	}
	return Plugin_Continue;
}

public Action Timer_ClearCount(Handle timer, int player)
{
	int dec = GetConVarInt(count_dec_every10sec);
	if (PlayerDoorCount[player] > dec)
	{
		PlayerDoorCount[player] -= dec;
		PlayerDoorHandle[player] = CreateTimer(10.0, Timer_ClearCount, player);
	}
	else
	{
		PlayerDoorCount[player]  = 0;
		PlayerDoorHandle[player] = null;
	}
	return Plugin_Continue;
}
