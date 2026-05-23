# TRM Weapon Base Scope Fix

GitHub-ready Garry's Mod addon package for the TRM Weapon Base scope/customization work.

## Install

1. Download the repo as a ZIP or use the release ZIP.
2. Place the `trm_weapon_base_scope_fix` folder inside:

```text
garrysmod/addons/
```

3. Restart Garry's Mod.

The folder should contain `addon.json`, `lua`, `materials`, and `models` directly at the addon root.

## What This Build Changes

- Adds a custom render-target scope path for magnified optics.
- Adds a PIP-style circular scope overlay.
- Adds a darker scope housing/rim so the optic has a visible outline.
- Adds drawn reticle fallback lines instead of relying on broken square INS2/TFA reticle materials.
- Hides the physical Elcan model while scoped to prevent the optic body and square lens material from showing through the overlay.
- Centers the Elcan overlay on screen while aiming.
- Tunes the Elcan for stronger magnification:
  - `Magnification = 4`
  - `FOV = 18`
  - `Aim.Scale = 1.15`
- Removes the earlier experimental `PreRender` scope hook that caused bad cached scope images.
- Removes the noisy square overlay material pass.

## Main Edited Files

```text
lua/trmbase/attachments/base/att_optic.lua
lua/trmbase/attachments/reticles/att_ins_elcan.lua
```

## Notes

This is still a compatibility patch over TRM's existing attachment/render model. It is not a full ARC9 port. ARC9 was used as a reference for how RT scopes are structured, but this addon remains TRM-based and drag-and-droppable into GMod.

If the scope feels too zoomed in or too weak, tune the Elcan values in:

```text
lua/trmbase/attachments/reticles/att_ins_elcan.lua
```

Useful values:

```lua
Magnification = 4,
FOV = 18,
ScreenScale = 0.62,
```

Lower `FOV` means more magnification. Higher `ScreenScale` means a larger on-screen scope image.
