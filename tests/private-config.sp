#define OnPluginStart AliasPluginStart
#include "../newplayerremind.sp"
#undef OnPluginStart

public OnPluginStart()
{
    aliases = new KeyValues("ServerPrivate");
    aliases.JumpToKey("players", true);
    aliases.JumpToKey("STEAM_0:0:0", true);
    aliases.SetString("name", "Test player");
    aliases.SetString("prefix", "Test prefix");
    char actual[64];
    getAlias(actual, sizeof(actual), "STEAM_0:0:0", "name", "Fallback");
    if (!StrEqual(actual, "Test player")) SetFailState("Alias lookup failed");
    getAlias(actual, sizeof(actual), "missing", "name", "Fallback");
    if (!StrEqual(actual, "Fallback")) SetFailState("Missing player fallback failed");
    getAlias(actual, sizeof(actual), "STEAM_0:0:0", "prefix", "Fallback");
    if (!StrEqual(actual, "Test prefix")) SetFailState("Repeated lookup failed");
    getAlias(actual, sizeof(actual), "STEAM_0:0:0", "missing", "Fallback");
    if (!StrEqual(actual, "Fallback")) SetFailState("Missing field fallback failed");
    delete aliases;
    aliases = load_private();
    delete aliases;
    PrintToServer("Private config checks passed");
}
