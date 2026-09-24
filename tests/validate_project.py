#!/usr/bin/env python3
"""Dependency-free integrity checks for the small Godot project."""

from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]


def check_scene() -> None:
    scene = ROOT / "main.tscn"
    section = ""
    keys: set[str] = set()
    for number, line in enumerate(scene.read_text().splitlines(), 1):
        if line.startswith("["):
            section, keys = line, set()
        elif "=" in line and not line.startswith(";"):
            key = line.split("=", 1)[0].strip()
            assert key not in keys, f"duplicate {key!r} in {section} at line {number}"
            keys.add(key)
    for resource in re.findall(r'path="res://([^"]+)"', scene.read_text()):
        assert (ROOT / resource).exists(), f"missing scene resource: {resource}"


def check_project_contract() -> None:
    project = (ROOT / "project.godot").read_text()
    assert 'run/main_scene="res://main.tscn"' in project
    assert 'renderer/rendering_method="gl_compatibility"' in project
    for action in ("move_forward", "move_back", "move_left", "move_right", "interact", "vehicle"):
        assert re.search(rf"^{action}=", project, re.MULTILINE), f"missing input: {action}"


def check_gameplay_contract() -> None:
    main = (ROOT / "main.gd").read_text()
    required = (
        'var cash := 300', '"save_version": 3', 'user://savegame.backup.json',
        'customer_met = true', '_complete_service()', '_refuel()', '_use_supply_store()',
        'PRESSURE WASHING', '$2,500 + 12 REP',
    )
    for fragment in required:
        assert fragment in main, f"missing gameplay contract: {fragment}"

    # Base offers alone must make the next branch attainable in a reasonable run.
    offers = [int(value) for value in re.findall(r'"pay":(\d+)', main.split('const DETAIL_JOBS :=', 1)[1].split(']', 1)[0])]
    assert len(offers) == 8
    cash = 300
    for job in range(32):
        cash += offers[job % len(offers)]
        if (job + 1) % 3 == 0:
            cash -= 35
        if cash >= 2500 and job + 1 >= 12:
            break
    assert cash >= 2500 and job + 1 <= 32, "pressure-washing unlock is not economically reachable"


if __name__ == "__main__":
    check_scene()
    check_project_contract()
    check_gameplay_contract()
    print("Project structure, compatibility, gameplay, save, and progression checks passed.")
