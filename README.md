# spacebam (Astibam)

A vector-style Asteroids clone built in Godot 4.7, with no external art or audio assets — everything is drawn procedurally at runtime.

Download a prebuilt Windows binary from the [Releases](https://github.com/cndrbrbr/spacebam/releases) page, or open the project in Godot 4.7+ and run it.

## Controls

| Action  | Keys              |
|---------|-------------------|
| Rotate  | ←/→ or A/D        |
| Thrust  | ↑ or W            |
| Fire    | Space             |
| Restart | R (after game over) |

## Project structure

```
astibam/
├── project.godot
├── scenes/
│   ├── Main.tscn       # game root: HUD, spawning, state machine
│   ├── Player.tscn      # ship
│   ├── Asteroid.tscn     # rock
│   └── Bullet.tscn       # projectile
└── scripts/
    ├── Main.gd
    ├── Player.gd
    ├── Asteroid.gd
    ├── Bullet.gd
    └── Game.gd            # autoload singleton
```

## Implementation

### Rendering

There are no sprites or textures. Every entity (ship, rocks, bullets) draws itself each frame with `_draw()` calls (`draw_colored_polygon`, `draw_polyline`, `draw_circle`), then requests a redraw with `queue_redraw()` after its state changes. The ship is a 4-point polygon; a second triangle is drawn behind it as an engine flame only while thrust is held. Asteroids are irregular polygons generated at spawn time (see below) rather than fixed shapes, so no two rocks look alike.

### Movement & wraparound

The ship and asteroids use manual Newtonian-ish movement rather than Godot's physics engine: a `velocity` vector is accumulated each `_physics_process` step and applied to `position` directly, with a drag multiplier (`velocity *= DRAG`) each frame so the ship coasts and decelerates instead of stopping instantly. Rotation and thrust are read straight from `Input.is_physical_key_pressed()` rather than the project's input map, so the controls work without any InputMap configuration in `project.godot`.

Screen wraparound is implemented per-entity: whenever `position` moves past the viewport bounds (`get_viewport_rect().size`), it's teleported to the opposite edge. Asteroids and bullets wrap the same way, with a margin equal to their radius so a rock doesn't visibly pop in/out at the edge.

### Collision via Area2D layers, not physics bodies

Everything is an `Area2D` (not `CharacterBody2D`/`RigidBody2D`), since the game only needs overlap detection, not physical response (bouncing, mass, friction). Three collision layers separate the actors:

| Actor    | Layer | Mask (what it detects) |
|----------|-------|-------------------------|
| Player   | 1     | 2 (asteroids)           |
| Asteroid | 2     | 4 (bullets)             |
| Bullet   | 4     | 0 (detected, not detecting) |

The player listens for its own `area_entered` signal to detect death; asteroids listen for `area_entered` to detect being shot. This keeps each script responsible only for reacting to its own hits, rather than a central collision manager polling every pair.

### Asteroid splitting

Asteroids have three size tiers (`3` large → `1` small) with per-tier radius, speed, and score value. Shape is generated procedurally in `_generate_shape()`: 10 vertices spaced evenly around a circle, each perturbed by a random radius multiplier (0.75–1.15×), producing a jagged rock outline instead of a perfect polygon. On being hit, `_break_apart()` awards score via the `Game` singleton and, if the tier is above the smallest, spawns two smaller asteroids at the same position with velocities derived from the parent's velocity rotated by a random angle — giving the classic "shot rock fragments outward" behavior — before `queue_free()`-ing itself.

Splitting asteroids instantiate their own scene recursively (`load("res://scenes/Asteroid.tscn")`), using `load()` rather than `preload()` to avoid a circular-resource-loading issue when a script preloads the very scene it's attached to.

### Game state

A single autoload singleton, `Game` (`scripts/Game.gd`), holds `score` and `lives` and exposes `score_changed`, `lives_changed`, and `game_over` signals. `Main.gd` is the only listener — it updates the HUD labels and shows the game-over message — keeping game state decoupled from whichever scene happens to be displaying it.

`Main.gd` also drives the wave loop: it spawns asteroids just outside the viewport edges, and each `_process()` tick checks whether the `"asteroids"` group is empty; when it is, the next wave spawns with one more asteroid than the last (`INITIAL_ASTEROIDS + wave`), increasing difficulty over time. Restart is handled by manually edge-detecting the R key each frame (comparing against the previous frame's state) rather than an input-map action, consistent with how movement input is read.

### Build

The project ships an `export_presets.cfg` for a self-contained Windows Desktop (x86_64) export, produced headlessly via:

```
Godot --headless --path . --export-release "Windows Desktop" build/windows/astibam.exe
```

`build/` is git-ignored; release binaries are published as GitHub Release assets instead of being committed to the repo.
