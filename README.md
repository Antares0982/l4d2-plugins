# l4d2-plugins

L4D2 服务端 SourceMod 插件源码，包含 6 个主插件和 `backupPlugin/` 下的 2 个备用插件。玩家无需安装这些插件；第三方地图资源需要另行准备。

## 主插件

| 源码 | 用途与默认行为 | 额外运行依赖 |
| --- | --- | --- |
| [acs.sp](acs.sp) | 自动轮换战役、投票决定下一张地图；合作模式通关后等待 62 秒换图。支持合作、对抗、清道夫和生存模式的地图列表。 | Mission Manager、ACS 翻译文件；可选 Proper Changelevel |
| [broadcast.sp](broadcast.sp) | 每 300 秒发送服务器广告；广播离开安全区、一枪击杀 Witch、当前战役等信息；安全门解锁等事件触发随机提示，接管 Bot 后延迟 60 秒显示欢迎信息。 | Mission Manager |
| [newplayerremind.sp](newplayerremind.sp) | 连接后延迟 15 秒欢迎真人玩家，区分管理员；退出时发送通知。从私有配置读取 SteamID、专属昵称。 | 无独立第三方依赖 |
| [door_kill.sp](door_kill.sp) | 惩罚反复操作安全门：开、关各计一次，计数达到 8 时处死玩家；每 10 秒减 2。 | SDKTools |
| [ff_static.sp](ff_static.sp) | 统计真人之间的同队伤害、击倒和击杀，显示“黑枪王”；默认每 60 秒以及团灭、通关时广播。 | Mission Manager、SDKTools |
| [tankhp_modified.sp](tankhp_modified.sp) | 根据人数修改 `z_tank_health`，基础值为 `4000 + max(人数 - 4, 0) × 1000`。 | 无独立第三方依赖 |

ACS 的 `mapvote`、`mapvotes` 控制台命令分别打开下一图投票和查看票数，只在符合条件的地图上可投票。聊天命令 `!chmap`、`!chmap2` 默认关闭；将 `acs_chmap_policy` 设为 `1` 后启用，弃权按反对票处理。ACS 会在 `addons/sourcemod/configs/` 下生成各模式的 `missioncycle.*.txt` 和合作模式的 `finale.coop.txt`。

广播间隔仍在源码中。专属昵称、玩家相关提示和欢迎广播读取
`addons/sourcemod/configs/server-private.cfg`；缺少此文件时使用普通玩家名和
通用欢迎消息，不包含个人映射。部署配置可以用 agenix 加密保存此文件，
运行时以服务账户可读的 0600 权限安装，不能写入 Nix 字符串或插件构建输入。

配置结构如下，使用 SourceMod KeyValues 格式，支持转义；修改后重启插件：

```text
"ServerPrivate"
{
    "players"
    {
        "STEAM_0:0:0" { "name" "Example player" "prefix" "玩家" }
    }
    "broadcast"
    {
        "message" "欢迎游玩本服务器！"
        "hint" "欢迎游玩本服务器！"
        "tips" { "0" { "text" "Example tip" } }
    }
}
```

友伤统计按 SteamID 保存在内存中，通关时清空，也会在客户端连接时检查战役是否变化并清空；不是数据库持久化。定时广播的间隔在插件启动时读取一次，不会随着 ConVar 修改自动更新。

Tank 插件在真人加入、退出后延迟重新计算人数，不会增加服务器人数上限，也不会直接修改已生成 Tank 的实体血量。当前人数判断使用队伍编号 `< 3`，因此包括旁观者和生还者，不包括 Bot；简单、专家难度的血量提示分别按基础值乘 0.75、2 计算。

## 备用插件

以下插件不在 `./compile.sh` 的默认编译范围内，需要单独编译、安装。

### [return_dmg.sp](backupPlugin/return_dmg.sp)

对真人队友造成伤害后反伤，排除火焰伤害。依赖 SourceMod 自带的 SDKTools、SDKHooks。

| ConVar | 默认值 | 当前行为 |
| --- | --- | --- |
| `l4d_damage_fflimit` | `5` | 每累计此数值的友伤，攻击者扣 1 点血；不足部分保留到后续伤害。 |
| `l4d_damage_ffincapacitate` | `1` | 允许反伤导致倒地，黑白状态下可导致死亡；设为 `0` 时保留至少 1 点实血。 |
| `l4d_damage_ffkick` | `0` | 设为 `1` 后启用友伤过多踢人。 |
| `l4d_damage_ffkicklimit` | `2000` | 累计友伤超过此值，在反伤结算时踢人；断开连接后计数清空。 |
| `l4d_damage_returnbotdmg` | `0` | 当前无实际作用：共享的 `is_client_actual()` 已排除 Bot，设为 `1` 也不会对攻击 Bot 的行为反伤。 |

### [ff_add_health.sp](backupPlugin/ff_add_health.sp)

娱乐插件：对真人队友造成伤害时，攻击者按伤害值回血。依赖 SDKTools，无独立配置文件。

- 未倒地过或使用急救包重置倒地次数后，增加实血，实血最多 100，并移除使总血量超过 100 的虚血。
- 倒地次数大于 0 时增加虚血；代码仅将虚血限制为 100，没有按实血加虚血的总和限制为 100。
- 受害者倒地时，事件发生后的剩余血量必须大于 200 才能触发吸血，等于 200 也不触发。
- 攻击者和受害者都必须是真人，攻击 Bot 不会回血。

## 依赖与配套插件

### 基础环境

先安装 [Metamod:Source](https://www.metamodsource.net/)，再安装 [SourceMod](https://www.sourcemod.net/downloads.php)，选择适合服务器系统的版本，按[官方安装说明](https://wiki.alliedmods.net/Installing_SourceMod)合并到服务器的 `left4dead2/` 目录。SDKTools 随 SourceMod 提供；[SDKHooks 已集成到 SourceMod](https://wiki.alliedmods.net/SDKHooks)，无需单独下载旧版扩展。

### Mission Manager 与换图

- [L4D2 Mission Manager](https://github.com/rikka0w0/l4d2_mission_manager)：`acs`、`broadcast`、`ff_static` 的必需依赖。安装 `l4d2_mission_manager.smx`，以及上游配套的 `gamedata/l4d2_mission_manager.txt`、地图和战役名称翻译文件。
- [ACS 翻译文件](https://github.com/rikka0w0/l4d2_mission_manager/tree/master/translations)：安装 `acs.phrases.txt`，需要中文时同时安装 `chi/` 下的对应文件。`common.phrases.txt` 和 `basevotes.phrases.txt` 由 SourceMod 提供。
- [Proper Changelevel](https://forums.alliedmods.net/showthread.php?t=319156)：可选的 `l4d2_changelevel.smx` 及配套 gamedata，用于更完整地处理换图。当前 ACS 将其标记为可选，未安装时使用脚本关闭命令和 `ForceChangeLevel()`。

仓库中的 `include/l4d2_mission_manager.inc`、`include/l4d2_changelevel.inc` 只是编译接口，不是依赖插件本体；本仓库不包含上述第三方插件及翻译、gamedata。其他插件虽然通过 `common.inc` 引用了 Mission Manager 接口，但没有调用战役查询的插件不需要它作为运行依赖。

### Gear Transfer：Bot 拾取与按 R 传递物资

Silvers 发布的公开 SourceMod 插件 **[L4D & L4D2 Gear Transfer](https://forums.alliedmods.net/showthread.php?t=137616)**（`l4d_gear_transfer.smx`）同时提供以下功能，与 `broadcast.sp` 中的两条物资提示相符：

- Bot 自动拾取附近物资，并自动交给缺少该类物资的玩家。
- 瞄准另一名生还者，按换弹键（默认 R）或推击键传递物资；可以与 Bot 拿取、交换物资。
- 支持投掷物、急救包、电击器、药品和特殊弹药包。

这是可选配套插件，需另行安装；`broadcast.sp` 只显示提示，不提供这些功能。仅凭提示文案不能确认原服务器实际安装的插件版本。

按[作者发布帖](https://forums.alliedmods.net/showthread.php?t=137616)下载插件和 `translations_gear_transfer.zip`，将 `.smx` 放入 `left4dead2/addons/sourcemod/plugins/`，将翻译包中的 `translations/` 合并到 `left4dead2/addons/sourcemod/`。

配置生成在 `left4dead2/cfg/sourcemod/l4d_gear_transfer.cfg`。发布帖所列配置中，`l4d_gear_transfer_method 2` 表示仅换弹键传递，`3` 表示推击和换弹键均可；`l4d_gear_transfer_dist_grab`、`l4d_gear_transfer_dist_give` 分别控制拾取、交付距离，默认均为 `150.0` 游戏单位。不同旧版的枚举值可能不同，应以所安装版本生成的配置为准。

## 编译与部署

### Nix flake

在 x86_64-linux 上运行：

```sh
nix build .#l4d2-addons
nix flake check
```

`packages.x86_64-linux.default` 和 `l4d2-addons` 提供可合并到
`left4dead2/` 的 `addons/`、`cfg/` 目录。构建六个主插件，不包含
`backupPlugin/`；同时打包固定版本的 Metamod、SourceMod、L4DToolZ、
Mission Manager、Left4DHooks、Gear Transfer、MultiSlots、CreateSurvivorBot
和 Proper Changelevel，以及所需翻译和 gamedata。另从固定版本源码编译
`hp_tank_show`：Tank 受伤时在头顶显示由绿变红的血量指示条，
使用已有 Left4DHooks 依赖，不改变 `tankhp_modified` 的人数血量规则。

`package.nix` 固定第三方下载地址及哈希；自写插件直接从本仓库源码编译，
不使用内置旧版 `spcomp`。修改源码后重新构建；更新依赖时修改对应地址和
哈希，并运行 `nix flake check`。此检查验证编译和必要产物，不代替游戏内验证。

`nix build .#checks.x86_64-linux.addons` 额外生成
`result/tests/private-config.smx`。将它临时放到测试服务器的 SourceMod
`plugins/`，执行 `sm plugins load private-config`，应输出
`Private config checks passed`；随后卸载并删除。此检查使用虚构映射验证
昵称查找、默认值和重复查询，也检查服务端私有配置能否解析，不输出其内容。

其他 flake 可将 `github:Antares0982/l4d2-plugins`
声明为 input，让其 `inputs.nixpkgs.follows = "nixpkgs"`，再引用
`inputs.l4d2-plugins.packages.x86_64-linux.default`。消费方通过自己的 `flake.lock` 锁定插件版本，运行
`nix flake update l4d2-plugins` 才更新源码。这里不管理 Steam 服务端、人数
ConVar、地图、用户或密钥，这些由部署配置管理。

### 手动编译

仓库自带 `spcomp` 和 `include/`。自带编译器是 32 位 Linux 程序，需要可运行它的环境；也可使用适合本机系统的 SourceMod 编译器，并配置本仓库的 include 搜索路径。

在仓库根目录编译全部主插件：

```sh
./compile.sh
```

输出位于 `compiled/`。单独编译主插件可用 `./compile.sh door_kill.sp`。备用插件可直接指定输出文件，避免脚本将源文件子目录拼入输出路径：

```sh
mkdir -p compiled
./spcomp -iinclude backupPlugin/return_dmg.sp -ocompiled/return_dmg.smx
./spcomp -iinclude backupPlugin/ff_add_health.sp -ocompiled/ff_add_health.smx
```

将选用的 `.smx` 复制到 `left4dead2/addons/sourcemod/plugins/`，补齐第三方依赖及其资源后重启服务器。在服务端控制台检查：

```text
meta list
sm version
sm plugins list
sm exts list
sm_lmm_list coop
```

最后一条仅适用于安装了 Mission Manager 的服务器。加载失败时查看 `left4dead2/addons/sourcemod/logs/` 下的错误日志。

以下配置在插件成功加载并执行配置阶段后自动生成于 `left4dead2/cfg/sourcemod/`：

| 配置文件 | 主要 ConVar |
| --- | --- |
| `acs.cfg` | `acs_voting_system_enabled`、`acs_chmap_policy`、`acs_next_map_menu_options` 等 |
| `door_kill.cfg` | `door_kill_limit`（8）、`count_dec_every10second`（2） |
| `ff_static.cfg` | `l4d_friendly_fire_loop_time`（60.0，计时器仅在插件启动时读取） |
| `l4d2_tank_hp.cfg` | `l4d2_basic_hp`（4000）、`l4d2_add_hp`（1000） |
| `return_dmg.cfg` | `l4d_damage_fflimit` 等反伤配置，仅安装该备用插件时生成 |

### 仓库辅助脚本

- `compile.sh` / `Makefile`：编译插件，默认只处理根目录的 `.sp`。
- `install_plugin.sh`：将指定文件安装到 `$HOME/serverfiles/left4dead2/addons/sourcemod/plugins/`。
- `update_all_plugins.sh`：拉取仓库、编译并安装 `compiled/` 下所有 `.smx`，包括此前单独编译的备用插件。
- `console_refresh.sh`：通过 `$HOME/l4d2server c` 打开 LinuxGSM 控制台，提示手动输入 `sm plugins refresh`，不会自动执行刷新。
- `changedefaultmap.py`：从地图列表随机选择符合条件的起始地图，修改 LinuxGSM 默认地图；路径写死在 `/home/l4d2/` 下。

这些脚本使用作者的服务器目录和 LinuxGSM 布局，使用前需要适配自己的路径。LinuxGSM 不是插件运行依赖。

## SourcePawn 函数说明

| 函数或标志 | 含义 |
| --- | --- |
| `IsFakeClient(client)` | 判断是否为 Bot；调用前应确认客户端索引有效。 |
| `GetClientTeam(client)` | L4D2 中通常为 `1` 旁观者、`2` 生还者、`3` 感染者；不是随局交换编号。 |
| `OnClientDisconnect(client)` | 客户端断开连接时调用的回调。 |
| `CreateTimer(interval, callback, data, flags)` | 创建计时器；向回调传递 `data`，返回计时器句柄。 |
| `TIMER_REPEAT` | 重复触发，直到停止或销毁。 |
| `TIMER_FLAG_NO_MAPCHANGE` | 换图时销毁计时器，不跨地图保留。组合标志使用按位或 `\|`。 |
