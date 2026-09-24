# Tony Mobile Services

A compact Godot 4.4 entrepreneurship game vertical slice. It uses the Compatibility renderer and programmer-created geometry so it remains suitable for older OpenGL-capable Macs, including macOS Mojave-era hardware.

## First shift

1. Review the detailing lead in the upper-right and **Accept** it. You begin with **$300**.
2. Walk to the parked starter car and press **F** to enter. Follow the blue marker and the compass/distance readout.
3. Park at the named customer property, press **F** to exit, approach the visible customer, and press **E** to greet them.
4. Visit each yellow work zone and hold **E**. The dirt panels disappear as the detail is completed.
5. Collect the payout and reputation, then select another detail lead. QuickFuel sells a $25 refill and Biz Supply sells a $200 detailing washer upgrade.
6. Build at least **$2,500** cash and **12 reputation**, then visit Biz Supply to purchase the first commercial pressure-washing rig and begin pressure contracts.

The HUD always shows the current objective, business progress, fuel, speed, equipment, contextual input, and early-game checklist. Progress is autosaved after jobs and purchases. Saves use a temporary file plus a previous-save backup, retain legacy version-2 fields, and safely resume at a fresh lead rather than halfway through a work interaction.

## Controls

| Input | Action |
| --- | --- |
| W/A/S/D | Walk, accelerate/brake, and steer |
| F | Enter or exit the starter car |
| E | Talk, purchase, refuel, or hold to work |

## Validation

Run the dependency-free static integration audit:

```bash
python3 tests/validate_project.py
```

For final release validation, import the project in Godot 4.4, run `main.tscn`, complete at least one detail, reload the project, and verify the saved balance, vehicle position, fuel, and next lead.
