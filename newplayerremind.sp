#include <../common>
#include <sourcemod>
#pragma semicolon 1
#define VERSION "1.0"

public Plugin myinfo =
{
	name        = "Player Join or Quit Notice",
	author      = "Antares",
	description = "When there is a new player or one of the players leaves, send a messgae",
	version     = "1.0"
};

Handle      WelcomeTimers[MAXPLAYERS + 1];
KeyValues aliases;

public OnPluginStart()
{
	aliases = load_private();
}

public OnClientConnected(player)
{
	WelcomeTimers[player] = CreateTimer(15.0, timer_OnPlayerJoin, player);
}

void getAlias(char[] buffer, int maxlen, const char[] steamid, const char[] key, const char[] fallback)
{
	strcopy(buffer, maxlen, fallback);
	aliases.Rewind();
	if (aliases.JumpToKey("players") && aliases.JumpToKey(steamid))
	{
		aliases.GetString(key, buffer, maxlen, fallback);
	}
}

void getPrefixBySteamID(char[] buffer, char[] steamid)
{
	bool admin = FindAdminByIdentity(AUTHMETHOD_STEAM, steamid) != INVALID_ADMIN_ID;
	getAlias(buffer, 16, steamid, "prefix", admin ? "管理员" : "玩家");
}

void getDisplayNameBySteamID(char[] buffer, char[] steamid, char[] original_name)
{
	getAlias(buffer, 64, steamid, "name", original_name);
}

void internalOnPlayerJoin(int player)
{
	if (!IsClientInGame(player) || IsFakeClient(player))
	{
		return;
	}

	char auth_id[64];
	char playername[64];

	if (!get_steamid_safe(player, auth_id, 64) || !GetClientName(player, playername, 64))
	{
		return;
	}

	char prefix[16];
	char displayname[64];
	getPrefixBySteamID(prefix, auth_id);

	getDisplayNameBySteamID(displayname, auth_id, playername);

	// print
	PrintToChatAll("欢迎%s：%s！", prefix, displayname);
}

public Action timer_OnPlayerJoin(Handle timer, int player)
{
	internalOnPlayerJoin(player);
	WelcomeTimers[player] = null;
	return Plugin_Continue;
}

public OnClientDisconnect(player)
{
	char playername[64];
	if (GetClientName(player, playername, 64))
	{
		if (!IsFakeClient(player))
		{
			PrintToChatAll("玩家：%s 离开了游戏", playername);
		}
	}
}