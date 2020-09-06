#include <sourcemod>
#pragma semicolon 1
#define VERSION "1.0"

public Plugin myinfo = 
{
	name = "Player Join or Quit Notice",
	author = "Antares",
	description = "When there is a new player or one of the players leaves, send a messgae",
	version = "1.0"
};

Handle WelcomeTimers[MAXPLAYERS+1];

public OnPluginStart(){}

public OnClientPutInServer(player)
{
	WelcomeTimers[player] = CreateTimer(15.0, timer_OnPlayerJoin, player);
}

public Action timer_OnPlayerJoin(Handle timer, int player)
{
	char playername[64];
	if(GetClientName(player, playername, 64))
	{
		PrintToChatAll("欢迎新玩家：%s ！", playername);
	}
	else
	{
		PrintToChatAll("出现错误");
	}
	WelcomeTimers[player] = null;
}

public OnClientDisconnect(player)
{
	char playername[64];
	if(GetClientName(player, playername, 64))
	{
		if(!IsFakeClient(player))
		{
			PrintToChatAll("玩家：%s 离开了游戏", playername);
		}
	}
	else
	{
		PrintToChatAll("出现错误");
	}
}

