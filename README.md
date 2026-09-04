# Quick Swap Belt

Factorio 2.0+ mod foundation for a future quick belt-swap feature.

The planned behavior is defined in [the Korean feature specification](docs/FEATURE_SPEC.md).

## What is included

- Valid Factorio 2.0 manifest in `info.json`.
- Four namespaced mouse-wheel inputs, rebindable in Controls.
- Dynamic catalogue for belts, pipes, and electric poles, including compatible
  content from other mods.
- English localisation and a Mod Portal-compatible changelog.
- No DLC-specific feature flags and no direct edits to another mod's prototypes.
  It can therefore load in vanilla Factorio 2.0 and with Space Age or other mods.

The mod swaps the held belt, underground belt, or splitter according to the
[feature specification](docs/FEATURE_SPEC.md). It uses each placed entity's
`belt_speed`, so vanilla, Space Age, and compatible mod-added tiers stay
separate. Shift-wheel also swaps pipes with underground pipes, and steps
through electric poles from wooden poles up to substations without wrapping;
unavailable intermediate poles are skipped. Character control in game view
consumes only matching inventory items. TAB/map view and remote control ignore
inventory and select only force-unlocked items while preserving the remote
cursor quality already selected through Factorio. Vanilla wheel behavior remains
available when no swap occurs, including cycling blueprints in a blueprint
book. After a successful swap, the zoom limits are temporarily locked at the
current level so the camera does not move, then restored on the following tick.
Swapping uses the amount actually available (up to the target item's stack
limit) and returns the original stack to inventory. When the target exists in
multiple qualities, it always uses the highest quality available for that item.

## Install for development

1. Place this folder in Factorio's `mods` directory as `quick-swap-belt`, or
   package it as `quick-swap-belt_0.2.8.zip` with these files at the archive root.
2. Start Factorio, enable **Quick Swap Belt**, then load or create a save.
3. Hold a belt, pipe, underground pipe, or electric pole and use
   `Shift + mouse wheel`. `Control + mouse wheel` changes belt tiers.

The Controls menu names these bindings **Quick item swap** (Shift-wheel by
default) and **Belt tier swap** (Control-wheel by default). Each wheel direction
can be rebound independently by the player.

When releasing, update both `info.json` and `changelog.txt`; name the archive
`quick-swap-belt_<version>.zip`.

## Factorio-version support

Factorio permits a mod manifest to name only one major game version. The source
manifest targets every 2.0.x release. Use the packaging script to create a
separate, installable archive for each supported major version:

```powershell
.\tools\package.ps1 -FactorioVersion 2.0 # produces version 0.2.8
.\tools\package.ps1 -FactorioVersion 2.1 # produces version 0.2.9
```

The resulting archives are written to `dist\Factorio-2.0` and
`dist\Factorio-2.1`. Install only the archive matching the game version; both
archives use the same internal mod name and must not be enabled together.

## Compatibility rules for future work

- Prefix every new prototype, setting, custom input, GUI element, and remote
  interface with `quick-swap-belt-`.
- Treat other mods and DLC content as optional: guard every lookup before use
  and avoid assuming a specific belt tier or item exists.
- Keep persistent data as simple serializable values in `storage`; use
  migrations when changing its shape.
- Keep all simulation-affecting code deterministic for multiplayer and replays.

## Official references

- [Modding tutorial](https://wiki.factorio.com/Tutorial:Modding_tutorial)
- [Mod structure and `info.json`](https://lua-api.factorio.com/latest/auxiliary/mod-structure.html)
- [Data lifecycle](https://lua-api.factorio.com/latest/auxiliary/data-lifecycle.html)
- [Persistent runtime storage](https://lua-api.factorio.com/latest/auxiliary/storage.html)
- [Custom input prototype](https://lua-api.factorio.com/latest/prototypes/CustomInputPrototype.html)
