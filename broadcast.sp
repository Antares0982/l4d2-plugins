#include <sourcemod>
#pragma semicolon 1
#define VERSION "1.0"

Handle WelcomeHint[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "Broadcasting",
	author = "Antares",
	description = "Broadcast message to everyone",
	version = "1.0"
};

public OnPluginStart()
{
    CreateTimer(120.0, Timer_PrintMessage, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	HookEvent("bot_player_replace", Event_PlayerPlayRole, EventHookMode_Pre);
}

public Action Event_PlayerPlayRole(Handle event, const String:name[], bool:dontBroadcast)
{
	new playerId = GetEventInt(event, "player");
	new player = GetClientOfUserId(playerId);
	WelcomeHint[player] = CreateTimer(60.0, Timer_PrintHintToPlayer, player);
	return Plugin_Continue;
}

public Action Timer_PrintHintToPlayer(Handle timer, int player)
{
	PrintHintText(player, "吸血插件已经关闭，请不要攻击队友！");
	WelcomeHint[player] = null;
}

public Action Timer_PrintMessage(Handle timer)
{
    PrintToChatAll("\x04 吸血插件已经关闭，请不要攻击队友！\x01 ");
}