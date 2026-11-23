# Crowd character slot

Drop real rigged crowd characters here (`.fbx`, `.glb` or `.gltf`).

`CrowdController3D` calls `CharacterModelSlots.spawn_into(...)` on build and gives the
imported models the first slots of the two loyalty banks, hiding the rim-lit 2.5D
silhouette bodies for those spectators. Any spectators beyond the number of files keep the
silhouette, so a single delivered character still upgrades the yard.

- Assignment is in sorted filename order, so one file is reused across its slots when fewer
  than 20 variants exist.
- Each model is scaled from its own bounding box to that spectator's height (1.55–1.90 m)
  and its feet are put on the crowd row's floor line.
- The first animation in the file is started automatically (a looping skank/idle works best).
- Author the character facing +Z (Mixamo's default) so it faces the arena camera.
- Keep the files small: this folder ships inside the Web export.
