# Badminton Rally Prototype

Godot 4 prototype focused on the in-match loop from the reference recording: a side-view badminton rally with keyboard movement, timed hits, stamina, scoring, and a simple AI opponent.

Current focus is only the playable level. Menus, login rewards, equipment progression, and other out-of-match systems are intentionally left out for now.

## Run

Open this folder with Godot 4 and run `res://scenes/Main.tscn`, or from macOS:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

## Controls

- Move along the single battle line: `A/D` or left/right arrows
- Aim shot lane/arc while hitting: `W/S` or up/down arrows
- Serve / high clear: `Space` or `J`
- Drop shot: `K`
- Smash: `L`
- Special smash: `I` when the energy bar is full

The player moves only along one horizontal battle line, matching the reference game's 2D play inside a pseudo-3D court. Move near the shuttle before hitting. Hit quality is judged from horizontal positioning, so clean contact produces stronger and more accurate shots. Stamina drains on shots and while moving, then recovers during slower movement. Regular hits build energy; a full energy bar enables a faster special smash.

Hold a direction while hitting to bias the target: left/right changes depth along the battle line, up/down changes the visual shot lane/arc. A preview reticle on the opponent side shows the current shot intent.

## Implemented Match Features

- Pseudo-3D side-view badminton stage with perspective court lines, center net post, landing marker, shuttle trail, and simple character/racket drawing.
- One-dimensional keyboard movement along the player-side battle line, plus three shot types: clear, drop, smash.
- AI opponent that moves toward the shuttle and chooses shots based on player position and stamina.
- Score to 7, rally counter, stamina bars, energy bars, floating hit-quality feedback, and screen shake on strong smash shots.
- Skill shot loop with a full-energy special smash and a visual hit window when the shuttle is playable.
- Swing/recovery states, racket swipe arcs, motion ghosts, footstep ripples, and hit-spark effects for stronger in-match feedback.
- Directional shot aiming with an opponent-court target preview.
- Optional generated arena background support at `res://assets/generated/images/badminton-arena-bg-3.png`, `.png`, or `.jpg`.
- Stick-figure skeletal debug mode for validating badminton stance, run phase, jump lift, racket windup, hit frame, and follow-through before final art is attached.
- AIART modular character part sheets for the player and rival under `res://assets/generated/images/modular-*-parts*.png`.

## Skeletal Animation Direction

The current default character display is a stick-figure rig prototype (`USE_RIG_CHARACTERS := true`) rather than final art. This is intentional for validating motion before binding polished body-part sprites.

The rig is tuned toward the reference pose:

- Side-view badminton stance on a single horizontal battle line.
- Light crouch with bent knees and a compact front/back foot stance.
- Racket ready near the chest/head side.
- Swing sequence: ready -> windup behind/above body -> high forward contact -> downward follow-through.
- Hit resolution occurs on the animation hit frame instead of immediately when the shot key is pressed.

Generated modular art sheets:

- Player candidates: `assets/generated/images/modular-player-badminton-parts*.png`
- Rival candidates: `assets/generated/images/modular-rival-demon-parts*.png`
- Auto-cut transparent test parts: `assets/generated/rig/parts/player_part_*.png` and `assets/generated/rig/parts/rival_part_*.png`

Best current candidates for future slicing:

- Player: `modular-player-badminton-parts-4.png`
- Rival: `modular-rival-demon-parts-3.png` or `modular-rival-demon-parts-4.png`

The current rig can draw these auto-cut parts on top of the stick-figure joints (`USE_RIG_PART_ART := true`). This is a coarse binding pass for validating the pipeline. Final production still needs curated cutouts and per-part pivot points so each limb rotates from the correct shoulder, elbow, hip, knee, wrist, and ankle anchor.

## Validate

```bash
HOME="$PWD/.godot_home" /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit
HOME="$PWD/.godot_home" /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/smoke_test.gd
HOME="$PWD/.godot_home" /Applications/Godot.app/Contents/MacOS/Godot --path . --script res://tests/render_snapshot.gd
```

The render snapshot command saves a verification image under Godot's app userdata directory and must run without `--headless`, because the headless renderer has no readable viewport texture.
