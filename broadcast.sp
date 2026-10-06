#include <../common>
#include <sourcemod>
#pragma semicolon 1
#define VERSION "1.0"

public Plugin myinfo =
{
	name        = "Broadcasting",
	author      = "Antares",
	description = "Broadcast message to everyone",
	version     = "1.0"
};

Handle WelcomeHint[MAXPLAYERS + 1];
char   stored_mission_name[64];    // mission name
ArrayList privateTips;
char advertisement[512];
char welcome[512];
char   tips[][] = {
    "在本服务器，短时间内反复开关安全门多次会被处死，具体多少次你可以试试～",
    "在本服务器，Tank的生命值随着玩家数量增加而增加",
    "在本服务器，bot会自动吸取其附近很小范围的道具并在之后交给你",
    "在本服务器，可以使用R键将包、药、投掷等物资交给队友，或与bot交换",
    "专家或写实模式中被witch击倒就会死亡，被队友击倒的话反而能提高生存几率",
    "止痛药与肾上腺素获得的虚血随时间衰减，衰减速度逐渐变慢",
    "写实模式下喷子没有近距离伤害加成，秒妹需要多来几枪",
    "witch被惊扰后，可以通过将witch点燃来把它的目标转移到自己身上，保护队友；witch已经丧失目标后不要点燃它",
    "阻挡witch的前进路线超过几秒后，会被witch攻击，请让开witch的路",
    "专家模式下hunter挠一下是40点伤害，在常规特感中有最高的平A输出",
    "写实模式下狙打身体不可以一枪打死普通僵尸",
    "马格南在写专打普通僵尸任何部位都是一枪秒杀",
    "燃烧对特感造成的每秒伤害是其生命上限的固定百分比",
    "一代图普通僵尸的拳法和二代的有一些区别",
    "Jimmy Gibbs Junior（车手僵尸）有3000HP，击中玩家时致盲，且免疫火、土雷和胆汁，但会被马格南、近战、爆炸秒杀",
    "堕落生还者的头盔可以使命中头部的子弹偏移，因此很难爆头",
    "堕落生还者拥有1000的生命值，被马格南、M60攻击可能需要两次才能死亡，近战武器可以秒杀",
    "机关等造成的尸潮，普通僵尸不会被小丑吸引",
    "工人僵尸免疫土雷、胆汁，但不免疫氧气罐",
    "防弹僵尸在正面仅受电锯、爆炸、火焰伤害，其他全部免疫",
    "开发者说糖的气味对witch有一种奇特的吸引力",
    "手电筒的光惊扰witch的范围是人走过惊扰范围的4倍",
	"站立的witch几乎不会受到手电筒的影响",
    "witch挠一下对特感造成250点伤害",
    "惊扰witch后如果先倒地或挂边了，witch在追逐到后会稍等片刻后才开始快速挥砍造成伤害。专家模式下一次挥砍造成300伤害，困难模式68",
    "非写实的专家难度一枪秒妹必须让喷子的全部弹丸完全击中头部",
    "当witch爬上某个东西之后有生还者在面前，无论是否是追逐对象witch都会立刻攻击",
    "燃烧、高爆惊扰witch会造成短时间眩晕，可以趁此机会逃跑",
    "火焰伤害杀死witch需要的时间是固定的15秒",
    "Zoey, Ellis喜欢狙，Francis, Coach喜欢喷子，其他人喜欢冲锋枪、步枪",
};

public OnPluginStart()
{
	KeyValues settings = load_private();
	privateTips = new ArrayList(ByteCountToCells(512));
	strcopy(advertisement, sizeof(advertisement), "欢迎游玩本服务器！");
	strcopy(welcome, sizeof(welcome), "欢迎游玩本服务器！");
	if (settings.JumpToKey("broadcast"))
	{
		settings.GetString("message", advertisement, sizeof(advertisement), "欢迎游玩本服务器！");
		settings.GetString("hint", welcome, sizeof(welcome), "欢迎游玩本服务器！");
		if (settings.JumpToKey("tips") && settings.GotoFirstSubKey())
		{
			do
			{
				char tip[512];
				settings.GetString("text", tip, sizeof(tip));
				if (tip[0]) privateTips.PushString(tip);
			}
			while (settings.GotoNextKey());
		}
	}
	delete settings;
	// global data
	stored_mission_name[0] = 0;
	// timer
	CreateTimer(300.0, Timer_PrintMessage, _, TIMER_REPEAT);

	// CreateTimer(120.0, Timer_randomTip, _, TIMER_REPEAT);
	// event hook
	HookEvent("door_unlocked", Event_door_unlock);
	HookEvent("bot_player_replace", Event_PlayerPlayRole, EventHookMode_Pre);
	HookEvent("player_left_start_area", Event_LeftStartArea, EventHookMode_Pre);
	HookEvent("witch_killed", Event_WitchKill, EventHookMode_Pre);
}

void internalRandomTip()
{
	int index = GetRandomInt(0, sizeof(tips) + privateTips.Length - 1);
	char tip[512];
	if (index < sizeof(tips)) strcopy(tip, sizeof(tip), tips[index]);
	else privateTips.GetString(index - sizeof(tips), tip, sizeof(tip));
	PrintToChatAll("\x04Tips: %s", tip);
}

public Action Timer_randomTip(Handle timer)
{
	internalRandomTip();
	return Plugin_Continue;
}

public Action Timer_PrintMessage(Handle timer)
{
	PrintToChatAll("%s", advertisement);
	return Plugin_Continue;
}

public Action Event_door_unlock(Handle event, const char[] name, bool dontbroadcast)
{
	if (GetEventBool(event, "checkpoint")) { internalRandomTip(); }
	return Plugin_Continue;
}

public Action Event_PlayerPlayRole(Handle event, const char[] name, bool dontBroadcast)
{
	new playerId        = GetEventInt(event, "player");
	new player          = GetClientOfUserId(playerId);
	WelcomeHint[player] = CreateTimer(60.0, Timer_PrintHintToPlayer, player);
	return Plugin_Continue;
}

public Action Timer_PrintHintToPlayer(Handle timer, int player)
{
	PrintHintText(player, "%s", welcome);
	WelcomeHint[player] = null;
	return Plugin_Continue;
}

public Action Event_LeftStartArea(Handle event, const char[] name, bool dontBroadcast)
{
	PrintToChatAll("\x04已经有玩家离开安全区域！\x01");
	PrintHintTextToAll("已经有玩家离开安全区域！");
	internalRandomTip();
	return Plugin_Continue;
}

public Action Event_WitchKill(Handle event, const char[] name, bool dontBroadcast)
{
	bool oneshot = GetEventBool(event, "oneshot");
	if (!oneshot) return Plugin_Continue;
	int  killerid = GetEventInt(event, "userid");
	int  killer   = GetClientOfUserId(killerid);
	char killer_name[64];
	if (!GetClientName(killer, killer_name, 64)) return Plugin_Continue;
	PrintToChatAll("\x05%s \x04一枪秒妹成功～鼓掌鼓掌\x01", killer_name);
	return Plugin_Continue;
}

public void OnClientConnected(int client)
{
	char currentMission[64];
	get_mission(currentMission);
	if (strcmp(currentMission, stored_mission_name, false) != 0)
	{
		// not equal
		strcopy(stored_mission_name, 64, currentMission);
		PrintToChatAll("\x04当前的地图是 \x05%s\x01", stored_mission_name);
	}
}