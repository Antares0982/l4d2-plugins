#include <l4d2_mission_manager>

stock KeyValues load_private()
{
	KeyValues settings = new KeyValues("ServerPrivate");
	settings.SetEscapeSequences(true);
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/server-private.cfg");
	if (FileExists(path) && !settings.ImportFromFile(path))
	{
		SetFailState("Invalid server-private.cfg");
	}
	return settings;
}

/**
 * Retrieves current mission name. Default length 64.
 *
 * @param buffer          Buffer to store mission name, size = 64.
 */
stock void get_mission(char[] buffer)
{
	char mapname[64];
	GetCurrentMap(mapname, 64);
	int mission_index;
	LMM_FindMapIndexByName(LMM_GetCurrentGameMode(), mission_index, mapname);
	LMM_GetMissionName(LMM_GetCurrentGameMode(), mission_index, buffer, 64);
}

/**
 * Retrieves a client's SteamID safely.
 *
 * @param client        Player index.
 * @param buffer          Buffer to store the client's auth id.
 * @param maxlen        Maximum length of string buffer (includes NULL terminator).
 * @return              True on success, false otherwise.
 */
stock bool get_steamid_safe(int client, char[] buffer, int maxlen)
{
	if (IsFakeClient(client))
	{
		return false;
	}
	return GetClientAuthId(client, AuthId_Steam2, buffer, maxlen);
}

/**
 * judge if client number actual (valid, and not a Bot)
 *
 * @param client        Client number to check.
 * @return              True on actual, false otherwise.
 */
stock bool is_client_actual(int client)
{
	return client >= 1 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client);
}

/**
 * judge if victim and attacker are different human players.
 *
 * @param victim        Victim client number.
 * @param attacker      Attacker client number.
 * @return              True on human player friendly fire, false otherwise.
 */
stock bool is_human_player_friendly_fire(int victim, int attacker)
{
	return is_client_actual(victim) && is_client_actual(attacker) && victim != attacker && (GetClientTeam(victim) == GetClientTeam(attacker));
}

/**
 * judge if client is human player, and in survivor team.
 *
 * @param client        Client number to check.
 * @return              True on survivor team human player, false otherwise.
 */
stock bool is_client_survivor_human_player(int client){
	return IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) < 3;
}