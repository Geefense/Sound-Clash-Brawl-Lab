# DJ character slot

Drop real rigged DJ / selector characters here (`.fbx`, `.glb` or `.gltf`).

`DJBooth3D` calls `CharacterModelSlots.spawn_into(self, CharacterModelSlots.DJ_DIR, 2, 1.62)`
on build. Until a file exists the booth shows its rim-lit 2.5D silhouette DJs; the moment
a model is present it is instanced behind the deck instead of the silhouette for that slot.

- Two slots are filled, in sorted filename order (`DJ_a.fbx` → slot 1, `DJ_b.fbx` → slot 2).
- The model is scaled from its own bounding box to 1.62 m tall and its feet are put on the
  booth's floor line, so no DCC scale setup is required.
- The first animation in the file is started automatically (keep a looping idle as the
  first clip, or name it `idle`).
- Author the character facing +Z (Mixamo's default) so it faces the arena camera.
- Keep the files small: this folder ships inside the Web export.
