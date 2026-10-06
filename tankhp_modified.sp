#include <../common>
#include <sourcemod>
#pragma semicolon 1
#define VERSION "1.0"

Handle hBasicTankHP;
Handle hAddTankHP;
int    TankBasicHP;
int    TankAddHP;

public Plugin myinfo =
{
	name        = "L4D2 Tank hp",
	description = "L4D2 Tank hp",
	author      = "Ryanx",
	version     = "1.0",
	url         = ""
};

public OnPluginStart()
{
	CreateConVar("L4D2_TANK_HP_version", "1.0", "注意：以下数值相加后是普通难度Tank血量，专家的要再乘2", 8512, false, 0.0, false, 0.0);
	hBasicTankHP = CreateConVar("l4d2_basic_hp", "4000", "Tank基本生命值（小于等于4个玩家时）", 0, true, 1.0, true, 100000.0);
	hAddTankHP   = CreateConVar("l4d2_add_hp", "1000", "大于4个玩家时，每多一名玩家Tank增加生命值，注意，专家难度最终该值乘2，简单难度乘0.75", 0, true, 0.0, true, 100000.0);
	TankBasicHP  = GetConVarInt(hBasicTankHP);
	TankAddHP    = GetConVarInt(hAddTankHP);
	HookEvent("player_activate", Event_PlayerAct);
	HookEvent("player_disconnect", Event_RPlayerDisct);
	AutoExecConfig(true, "l4d2_tank_hp");
}

public OnMapStart()
{
	TankBasicHP = GetConVarInt(hBasicTankHP);
	TankAddHP   = GetConVarInt(hAddTankHP);
}

public Action Event_PlayerAct(Handle event, char[] name, bool dontBroadcast)
{
	int checkhplayer = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsFakeClient(checkhplayer))
	{
		CreateTimer(0.1, TankHPsetStartDelays);
	}
	return Plugin_Continue;
}

public Action Event_RPlayerDisct(Handle event, char[] name, bool dontBroadcast)
{
	new checkhplayer = GetClientOfUserId(GetEventInt(event, "userid"));
	if (checkhplayer && !IsFakeClient(checkhplayer))
	{
		CreateTimer(3.0, TankHPsetStartDelays);
	}
	return Plugin_Continue;
}

public Action TankHPsetStartDelays(Handle timer)
{
	char GameDIFF[32];
	TankBasicHP = GetConVarInt(hBasicTankHP);
	TankAddHP   = GetConVarInt(hAddTankHP);
	int SetTankHP;            // 代码中实际设定的tank hp，实际进行游戏时，L4D2会根据难度修改最终值
	int DisplayTrueTankHP;    // 根据游戏难度，用于输出到聊天框的真实tank hp
	int numPlayers = 0;

	for (int i = 1; i <= MaxClients; ++i)
	{
		if (is_client_survivor_human_player(i))
		{
			numPlayers++;
		}
	}

	if (numPlayers <= 4)
	{
		numPlayers = 4;
	}
	SetTankHP = TankAddHP * (numPlayers - 4) + TankBasicHP;
	SetConVarInt(FindConVar("z_tank_health"), SetTankHP);

	// 根据难度计算最终 tank hp 用于提示文字
	GetConVarString(FindConVar("z_difficulty"), GameDIFF, 32);
	if (StrEqual(GameDIFF, "Easy"))
	{
		float f_HP        = 0.75 * float(SetTankHP);
		DisplayTrueTankHP = RoundFloat(f_HP);
	}
	else if (StrEqual(GameDIFF, "Impossible"))
	{
		DisplayTrueTankHP = SetTankHP * 2;
	}
	else
	{
		DisplayTrueTankHP = SetTankHP;
	}

	PrintToChatAll("\x04[!提示!]\x05 幸存者人数改变了,\x03 %s \x05难度 Tank血量现在是\x03 %d", GameDIFF, DisplayTrueTankHP);
	return Plugin_Continue;
}
