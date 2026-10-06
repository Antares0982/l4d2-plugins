{
  description = "L4D2 campaign plugins and pinned runtime addons";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      addons = pkgs.callPackage ./package.nix { inherit pkgs; };
    in
    {
      packages.${system} = {
        default = addons;
        l4d2-addons = addons;
      };
      checks.${system}.addons = addons.overrideAttrs (old: {
        installCheckPhase = old.installCheckPhase + ''
          mkdir -p $out/tests
          "$compiler" -i"$includes" -i"$PWD/include" tests/private-config.sp -o$out/tests/private-config.smx
        '';
      });
    };
}
