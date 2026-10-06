# Repository Guidelines

## Project Structure & Module Organization

This repository contains server-side Left 4 Dead 2 SourceMod plugins. Six root-level `.sp` files implement the main plugins; `common.inc` holds shared helpers. `backupPlugin/` contains two optional plugins excluded from default builds. `include/` contains compiler interfaces, not runtime dependencies. `tests/` holds regression checks. `package.nix` and `flake.nix` build plugins and package pinned third-party addons, translations, and gamedata. Manual builds write to ignored `compiled/`.

## Build, Test, and Development Commands

Run commands from the repository root:

- `nix build .#l4d2-addons`: build the deployable `result/addons/` and `result/cfg/` bundle on x86_64 Linux.
- `nix flake check`: compile plugins, verify required artifacts, and compile the private-configuration test plugin.
- `python3 tests/test_ff_static.py`: run friendly-fire ranking regression checks; requires Python 3 and `c++`.
- `./compile.sh`: compile all root-level plugins using the bundled 32-bit Linux compiler, which requires a compatible runtime.
- `make one target=door_kill.sp`: compile one main plugin into `compiled/`.

On NixOS, obtain temporary tools with `nix shell`; do not use `nix-env`.

## Coding Style & Naming Conventions

Match surrounding SourcePawn style: generally tabs, braces on separate lines, and semicolons. Preserve established callback names and local naming conventions; use descriptive plugin filenames such as `door_kill.sp`. Python uses four-space indentation; Nix generally uses two. No formatter or linter is configured. Reuse `common.inc` helpers and inspect all callers before changing shared behavior. Keep new function names within four words and comment blocks within seven words.

## Testing Guidelines

Use small standalone regression checks; there is no test framework or coverage threshold. Name Python checks `tests/test_*.py`. For private configuration changes, follow README instructions to build and load `tests/private-config.sp` on a test server. Compilation does not validate gameplay: exercise changed events in-game, inspect `sm plugins list`, and check SourceMod error logs.

## Commit & Pull Request Guidelines

History is sparse and uses plain descriptive subjects, such as “Package Tank health display with shared addons”; no enforced prefix convention exists. Keep commits focused. PRs should explain behavior changes, affected plugins, validation performed, and dependency or configuration changes. Link relevant issues when available.

## Security & Configuration

Never commit `server-private.cfg` or embed private mappings in Nix inputs. Keep runtime configuration outside builds. Deployment scripts assume author-specific LinuxGSM paths; adapt them before use.
