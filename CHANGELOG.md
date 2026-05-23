# Changelog

## Scope Fix Build

- Added custom RT scope rendering for TRM optics.
- Added circular PIP-style scope overlay.
- Added visible scope housing/rim.
- Added fallback drawn reticle lines.
- Disabled material reticle rendering by default for the Elcan to avoid square reticle texture artifacts.
- Disabled 3D lens rendering for the Elcan overlay path to prevent stacked scope images.
- Hid the Elcan model while scoped to prevent the optic body from rendering through the overlay.
- Centered the scope overlay on screen.
- Increased Elcan magnification tuning.
- Removed the experimental client PreRender hook after it caused cached/bad scope images.
