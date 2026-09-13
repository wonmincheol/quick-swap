"""Run integration checks in an isolated Factorio user directory.

Usage: python tools/test_runtime.py /path/to/factorio.exe
Only the staging copy of the mod is instrumented. User mods/saves are untouched.
"""
import json
import pathlib
import shutil
import subprocess
import sys
import tempfile
import time
import os

root = pathlib.Path(__file__).resolve().parents[1]
exe = pathlib.Path(sys.argv[1]).resolve()
data = exe.parents[2] / "data"
version = json.loads((data / "base/info.json").read_text())["version"]
with tempfile.TemporaryDirectory(prefix="quick-swap-test-") as directory:
    work = pathlib.Path(directory)
    mods = work / "mods"
    mod = mods / "quick-swap"
    mod.mkdir(parents=True)
    for name in ("control.lua", "data.lua", "info.json"):
        shutil.copy2(root / name, mod / name)
    for name in ("scripts", "locale", "tests"):
        shutil.copytree(root / name, mod / name)
    manifest = json.loads((mod / "info.json").read_text())
    manifest["factorio_version"] = ".".join(version.split(".")[:2])
    (mod / "info.json").write_text(json.dumps(manifest), encoding="utf-8")
    control = (mod / "control.lua").read_text(encoding="utf-8")
    control = 'local smoke = require("tests.smoke")\n' + control
    control += '''
local check_reload = false
script.on_load(function() check_reload = storage.quick_swap_test_saved == true end)
script.on_nth_tick(1, function()
  if check_reload then
    check_reload = false
    assert(groups.get(1).config.groups[1].id == 2)
    assert(groups.find(groups.get(1).config, 1).cells[1] == "transport-belt")
    assert(gui.is_open(game.players[1]))
    log("QUICK_SWAP_RELOAD_PASSED")
  end
  if not storage.quick_swap_test_done and game.players[1] then
    storage.quick_swap_test_done = true
    smoke.run(game.players[1])
  end
  if storage.quick_swap_test_done and not storage.quick_swap_test_saved and game.tick >= 120 then
    storage.quick_swap_test_saved = true
    game.auto_save("quick-swap-validation")
  end
  if storage.quick_swap_test_done and not storage.quick_swap_test_screenshot and game.tick >= 240 then
    storage.quick_swap_test_screenshot = true
    local player = game.players[1]
    game.take_screenshot { player = player, resolution = player.display_resolution,
      show_gui = true, path = "quick-swap-ui.png" }
  end
end)
'''
    if "--rebound" in sys.argv:
        control += '''
script.on_event(defines.events.on_string_translated, function(event)
  local axis = storage.quick_swap_translation_ids and storage.quick_swap_translation_ids[event.id]
  if not axis then return end
  local first, second = axis == "horizontal" and "F6" or "F8", axis == "horizontal" and "F7" or "F9"
  assert(event.translated and event.result:find(first, 1, true) and event.result:find(second, 1, true), event.result)
  storage.quick_swap_translation_count = (storage.quick_swap_translation_count or 0) + 1
  if storage.quick_swap_translation_count == 2 then log("QUICK_SWAP_REBOUND_LABELS_PASSED") end
end)
script.on_nth_tick(30, function()
  if not storage.quick_swap_translation_ids and game.players[1] then
    storage.quick_swap_translation_ids = {}
    for _, axis in ipairs({ "horizontal", "vertical" }) do
      local id = game.players[1].request_translation({ "quick-swap.keys-" .. axis })
      storage.quick_swap_translation_ids[id] = axis
    end
  end
end)
'''
    (mod / "control.lua").write_text(control, encoding="utf-8")
    mod_list = [{"name": p.parent.name, "enabled": p.parent.name == "base"}
                for p in data.glob("*/info.json") if p.parent.name != "core"]
    if "--space-age" in sys.argv:
        for entry in mod_list: entry["enabled"] = True
    mod_list.append({"name": "quick-swap", "enabled": True})
    (mods / "mod-list.json").write_text(json.dumps({"mods": mod_list}))
    config = work / "config.ini"
    config.write_text(f"[path]\nread-data={data.as_posix()}\nwrite-data={work.as_posix()}\n")
    if "--rebound" in sys.argv:
        with config.open("a") as handle:
            handle.write("[controls]\nquick-swap-cycle-kind-next=F6\nquick-swap-cycle-kind-previous=F7\n"
                         "quick-swap-cycle-tier-next=F8\nquick-swap-cycle-tier-previous=F9\n")
    result = subprocess.run([str(exe), "--config", str(config), "--mod-directory", str(mods),
        "--create", str(work / "test.zip")], capture_output=True, text=True, timeout=180)
    output = result.stdout + result.stderr
    print(output)
    if result.returncode:
        raise SystemExit(1)
    # A graphical client is necessary: headless map creation has no LuaPlayer.
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 0
    env = dict(os.environ, SteamAppId="427520", SteamGameId="427520")
    process = subprocess.Popen([str(exe), "--config", str(config), "--mod-directory", str(mods),
        "--load-game", str(work / "test.zip")], stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL, startupinfo=startup, env=env)
    try:
        deadline = time.monotonic() + 150
        while time.monotonic() < deadline:
            log = work / "factorio-current.log"
            output = log.read_text(encoding="utf-8", errors="replace") if log.exists() else ""
            if "QUICK_SWAP_TESTS_PASSED" in output or "Error while running" in output or process.poll() is not None:
                break
            time.sleep(0.5)
        print(output)
        if "QUICK_SWAP_TESTS_PASSED" not in output:
            raise SystemExit(1)
        screenshot = work / "script-output/quick-swap-ui.png"
        for _ in range(20):
            if screenshot.exists() and screenshot.stat().st_size > 100:
                time.sleep(1)
                break
            time.sleep(0.5)
        if screenshot.exists():
            destination = root / "dist/tests"
            destination.mkdir(parents=True, exist_ok=True)
            name = "space-age-ui" if "--space-age" in sys.argv else "base-ui"
            if "--rebound" in sys.argv: name += "-rebound"
            shutil.copy2(screenshot, destination / (name + ".png"))
        if "--rebound" in sys.argv:
            output = (work / "factorio-current.log").read_text(encoding="utf-8", errors="replace")
            if "QUICK_SWAP_REBOUND_LABELS_PASSED" not in output:
                print(output)
                raise RuntimeError("Rebound labels were not verified")
            print("QUICK_SWAP_REBOUND_LABELS_PASSED")
    finally:
        if process.poll() is None:
            process.terminate()
            process.wait(timeout=15)
    saves = list((work / "saves").glob("*quick-swap-validation*.zip"))
    if not saves:
        raise RuntimeError("Validation save was not created")
    result = subprocess.run([str(exe), "--config", str(config), "--mod-directory", str(mods),
        "--benchmark", str(saves[0]), "--benchmark-ticks", "1", "--benchmark-runs", "1"],
        capture_output=True, text=True, timeout=120)
    print(result.stdout + result.stderr)
    if result.returncode or "QUICK_SWAP_RELOAD_PASSED" not in result.stdout:
        raise SystemExit(1)
