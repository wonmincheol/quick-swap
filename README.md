# Quick Swap

Factorio 2.0+ mod for quickly swapping belts, pipes, and electric poles with
the mouse wheel.

The implemented behavior is documented in
[the Korean feature specification](docs/FEATURE_SPEC.md).

## What is included

- A native Factorio logistics-style editor opened from the top-left Quick Swap button.
- Personal groups with exactly ten columns and automatically growing rows.
- Click a slot to select an unlocked regular building item; right-click to clear it.
- Group rename, enable/disable, delete, up/down ordering, and independent horizontal/vertical wrapping.
- Four directional shortcuts displayed using the game's current key-binding localisation.
- Apply saves the draft; Cancel discards it. Closing a dirty window asks before discarding.
- Default belt, pipe, and electric-pole groups, including compatible mod prototypes.
- Shift-wheel moves horizontally; Ctrl-wheel moves vertically. Wheel up means right/down.
- Empty, locked, missing, and unavailable slots are skipped within the same row or column.
- The first enabled group containing the held item wins; swapping never falls through to another group.
- Character mode requires unlocked items in inventory and chooses the highest available quality.
- Map/remote mode uses unlocked cursor ghosts and preserves the selected quality.
- Successful swaps suppress wheel zoom; otherwise vanilla wheel actions remain available.

The implementation and acceptance checklist are documented in
[the custom group specification](docs/CUSTOM_GROUPS_SPEC.md). GUI configuration is
stored per player in the save. No row or group count limit is imposed. Very large
grids currently create all their slot widgets; rendering virtualization is a future optimization.
Special stacks (blueprints, tools, tagged items, inventory-bearing or spoilable items) and tile
placement items are excluded. Regular items with an entity placement result are supported.

## Install for development

1. Place this folder in Factorio's `mods` directory as `quick-swap`, or run the
   packaging script to create `quick-swap_0.3.4.zip`. The archive contains a
   top-level `quick-swap_0.3.4` directory, as Factorio expects.
2. Start Factorio, enable **Quick Swap**, then load or create a save.
3. Click **Quick Swap** at the top left to edit groups, then **Apply**.
4. Hold a registered building item and use Shift-wheel (horizontal) or Ctrl-wheel (vertical).

Each wheel direction can be rebound independently in the Controls menu.

When releasing, update both `info.json` and `changelog.txt`; name the archive
`quick-swap_<version>.zip`.

## Factorio-version support

Factorio permits a mod manifest to name only one major game version. The source
manifest targets every 2.0.x release. Use the packaging script to create a
separate, installable archive for each supported major version:

```powershell
.\tools\package.ps1 -FactorioVersion 2.0 # produces version 0.3.4
.\tools\package.ps1 -FactorioVersion 2.1 # produces version 0.3.5
```

The resulting archives are written to `dist\Factorio-2.0` and
`dist\Factorio-2.1`. Install only the archive matching the game version; both
archives use the same internal mod name and must not be enabled together.

## Compatibility rules for future work

- Prefix every new prototype, setting, custom input, GUI element, and remote
  interface with `quick-swap-`.
- Treat other mods and DLC content as optional: guard every lookup before use
  and avoid assuming a specific belt tier or item exists.
- Keep persistent data as simple serializable values in `storage`; use
  migrations when changing its shape.
- Keep all simulation-affecting code deterministic for multiplayer and replays.

## Acknowledgements

This mod was developed in collaboration with OpenAI Codex, which assisted with
implementation review, documentation consistency checks, and release-package
validation.

## Official references

- [Modding tutorial](https://wiki.factorio.com/Tutorial:Modding_tutorial)
- [Mod structure and `info.json`](https://lua-api.factorio.com/latest/auxiliary/mod-structure.html)
- [Data lifecycle](https://lua-api.factorio.com/latest/auxiliary/data-lifecycle.html)
- [Persistent runtime storage](https://lua-api.factorio.com/latest/auxiliary/storage.html)
- [Custom input prototype](https://lua-api.factorio.com/latest/prototypes/CustomInputPrototype.html)
