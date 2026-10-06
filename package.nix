{ pkgs }:
let
  sources = builtins.mapAttrs (_: spec: pkgs.fetchurl spec) {
    sm = {
      url = "https://github.com/alliedmodders/sourcemod/releases/download/1.12.0.7255/sourcemod-1.12.0-git7255-linux.tar.gz";
      hash = "sha256-Ar51Ldwl00SjeYAN+TlaKEerhbcazqkWf9yoFjAQ1bk=";
    };
    mm = {
      url = "https://github.com/alliedmodders/metamod-source/releases/download/1.12.0.1227/mmsource-1.12.0-git1227-linux.tar.gz";
      hash = "sha256-1wqo5rjIiipv93Cq3I4HDoozGuT7kaAZ89wZ01LAT14=";
    };
    toolz = {
      url = "https://github.com/lakwsh/l4dtoolz/releases/download/2.5.1/l4dtoolz-2.5.1-main.zip";
      hash = "sha256-hsVGGmn9dWuMkNSFU6cRGj14FAEqoL08UQquVZH7EEk=";
    };
    mission = {
      url = "https://github.com/rikka0w0/l4d2_mission_manager/archive/8df00f7626b6a7261ccae9533b8d979ebda6402e.tar.gz";
      hash = "sha256-rdvgbEMCKsPfKT7nt3+oSx3luSR9PxXlvC4GCgu02FI=";
    };
    hooks = {
      url = "https://github.com/SilvDev/Left4DHooks/archive/5c9d6a6dad39881329664e4ad6f105d286b6b0af.tar.gz";
      hash = "sha256-MszTGNgq2PkqSq4LcJl+Tt/6UD4WLOuL02tU/m2C6rk=";
    };
    gear = {
      url = "https://github.com/SilvDev/Gear_Transfer/archive/3a09b1b3a8a2a34a31e1308c598894296d7e6183.tar.gz";
      hash = "sha256-zA/ZdRAe5T2jd38QsY7IqvO7KmubeIsmyt6oGFPELSM=";
    };
    multi = {
      url = "https://github.com/fbef0102/L4D1_2-Plugins/archive/04dc048dc013c86ab4df07927f5b369f829c851f.tar.gz";
      hash = "sha256-ldTRJsEfEM/fmmJG+2Pn0bopRx4pQH47C1s8a/fLmn8=";
    };
    change = {
      url = "https://github.com/LuxLuma/Left-4-fix/archive/a3016b7c182049ca77ad3f817a7124ed812d5880.tar.gz";
      hash = "sha256-eWCrLE1Uho5vf4sN4FKO9GdzD423qJs+Suxxm07JIco=";
    };
  };
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "l4d2-addons";
  version = "2026-10-03";
  src = pkgs.lib.fileset.toSource {
    root = ./.;
    fileset = pkgs.lib.fileset.unions [
      ./acs.sp
      ./broadcast.sp
      ./newplayerremind.sp
      ./door_kill.sp
      ./ff_static.sp
      ./tankhp_modified.sp
      ./common.inc
      ./tests/private-config.sp
      ./include/l4d2_mission_manager.inc
      ./include/l4d2_changelevel.inc
    ];
  };
  nativeBuildInputs = [
    pkgs.patchelf
    pkgs.unzip
  ];
  dontFixup = true;
  buildPhase = ''
    runHook preBuild
    mkdir sm mm toolz mission hooks gear multi change compiled
    tar xf ${sources.sm} -C sm
    tar xf ${sources.mm} -C mm
    unzip -q ${sources.toolz} -d toolz
    tar xf ${sources.mission} -C mission --strip-components=1
    tar xf ${sources.hooks} -C hooks --strip-components=1
    tar xf ${sources.gear} -C gear --strip-components=1
    tar xf ${sources.multi} -C multi --strip-components=1
    tar xf ${sources.change} -C change --strip-components=1
    chmod +w sm/addons/sourcemod/scripting/spcomp64
    patchelf --set-interpreter ${pkgs.stdenv.cc.bintools.dynamicLinker} \
      --set-rpath ${pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]} \
      sm/addons/sourcemod/scripting/spcomp64
    compiler="$PWD/sm/addons/sourcemod/scripting/spcomp64"
    includes="$PWD/sm/addons/sourcemod/scripting/include"
    for plugin in acs broadcast newplayerremind door_kill ff_static tankhp_modified; do
      "$compiler" -i"$includes" -i"$PWD/include" "$plugin.sp" -o"compiled/$plugin.smx"
    done
    "$compiler" -i"$includes" -i"$PWD/mission/scripting/include" \
      mission/scripting/l4d2_mission_manager.sp -ocompiled/l4d2_mission_manager.smx
    "$compiler" -i"$includes" gear/scripting/l4d_gear_transfer.sp -ocompiled/l4d_gear_transfer.smx
    "$compiler" -i"$includes" "change/left 4 fix/l4d2_levelchanging/scripting/l4d2_changelevel.sp" \
      -ocompiled/l4d2_changelevel.smx
    "$compiler" -i"$includes" -i"$PWD/hooks/sourcemod/scripting/include" \
      multi/hp_tank_show/scripting/hp_tank_show.sp -ocompiled/hp_tank_show.smx
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r mm/addons sm/addons sm/cfg $out/
    cp toolz/l4dtoolz.so toolz/l4dtoolz.vdf $out/addons/
    dest=$out/addons/sourcemod
    cp compiled/*.smx $dest/plugins/
    cp -r mission/gamedata mission/translations $dest/
    cp -r gear/translations $dest/
    cp -r hooks/sourcemod/{plugins,gamedata,data} $dest/
    for plugin in l4dmultislots l4d_CreateSurvivorBot; do
      cp multi/$plugin/plugins/$plugin.smx $dest/plugins/
    done
    cp -r multi/l4dmultislots/translations multi/l4d_CreateSurvivorBot/gamedata $dest/
    cp "change/left 4 fix/l4d2_levelchanging/gamedata/l4d2_changelevel.txt" $dest/gamedata/
    rm $dest/plugins/nextmap.smx $dest/plugins/reservedslots.smx
    rm -r $dest/scripting
    sed -i '/"DisableAutoUpdate"/s/"no"/"yes"/' $dest/configs/core.cfg
    runHook postInstall
  '';
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    for plugin in acs broadcast newplayerremind door_kill ff_static tankhp_modified \
      l4d2_mission_manager l4d_gear_transfer l4d2_changelevel \
      left4dhooks l4dmultislots l4d_CreateSurvivorBot hp_tank_show; do
      test -s "$out/addons/sourcemod/plugins/$plugin.smx"
    done
    test -s "$out/addons/l4dtoolz.so"
    test -s "$out/addons/sourcemod/translations/acs.phrases.txt"
    test ! -e "$out/addons/sourcemod/plugins/return_dmg.smx"
    test ! -e "$out/addons/sourcemod/plugins/ff_add_health.smx"
    runHook postInstallCheck
  '';
  meta.platforms = [ "x86_64-linux" ];
}
