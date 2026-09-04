# Quick Swap Belt

Factorio 2.0+ mod foundation for a future quick belt-swap feature.

The planned behavior is defined in [the Korean feature specification](docs/FEATURE_SPEC.md).

## What is included

- Valid Factorio 2.0 manifest in `info.json`.
- Four namespaced mouse-wheel inputs, rebindable in Controls.
- Dynamic belt catalogue that includes standard compatible content from other mods.
- English localisation and a Mod Portal-compatible changelog.
- No DLC-specific feature flags and no direct edits to another mod's prototypes.
  It can therefore load in vanilla Factorio 2.0 and with Space Age or other mods.

The mod swaps the held belt, underground belt, or splitter according to the
[feature specification](docs/FEATURE_SPEC.md). It uses each placed entity's
`belt_speed`, so vanilla, Space Age, and compatible mod-added tiers stay
separate. Character control consumes only matching inventory items; remote
control can select force-unlocked candidates. The wheel binding is consumed by
the mod so it does not also zoom the view. Swapping uses the amount actually
available (up to the target item's stack limit) and returns the original belts
to inventory.

## Install for development

1. Place this folder in Factorio's `mods` directory as `quick-swap-belt`, or
   package it as `quick-swap-belt_0.2.6.zip` with these files at the archive root.
2. Start Factorio, enable **Quick Swap Belt**, then load or create a save.
3. Hold a belt, underground belt, or splitter and use `Shift + mouse wheel` or
   `Control + mouse wheel`.

When releasing, update both `info.json` and `changelog.txt`; name the archive
`quick-swap-belt_<version>.zip`.

## Factorio-version support

Factorio permits a mod manifest to name only one major game version. The source
manifest targets every 2.0.x release. Use the packaging script to create a
separate, installable archive for each supported major version:

```powershell
.\tools\package.ps1 -FactorioVersion 2.0 # produces version 0.2.6
.\tools\package.ps1 -FactorioVersion 2.1 # produces version 0.2.7
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
