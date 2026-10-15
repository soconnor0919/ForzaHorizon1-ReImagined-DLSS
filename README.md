# NVIDIA DLSS for Forza Horizon 1: ReImagined

An experimental launcher mod that adds DLSS Super Resolution and optional neural rendering to
[Forza Horizon 1: ReImagined](https://github.com/Dyotson/ForzaHorizon1-ReImagined). It runs as a
process-local ReShade Vulkan layer; it does not register a system-wide layer or modify the game
runtime.

![DLSS settings in the ReImagined launcher](docs/mod-loader.png)

## Status

The bridge has initialized successfully on an RTX 5060 Ti at 2560x1440. DLSS Super Resolution
created its feature in Native/DLAA mode and processed frames. ReImagined does not yet export game
motion vectors, depth, camera jitter, or a HUD mask to the bridge. The optical-flow fallback works,
but moving cars and floating labels can blur or ghost. Native 1440p (DLAA) is therefore the default.

Native/DLAA adds an antialiasing pass to a fully rendered frame; it is not a performance
mode. The current source-resolution override downsamples the finished game image inside
the bridge. It does **not** lower ReImagined's render scale or save the game's rendering
work. See [measured performance and limitations](docs/performance.md).

Frame generation is disabled. Neural rendering remains experimental and requires an additional
NVIDIA runtime that this repository does not distribute.

## Install

This repository contains the ReImagined manifest, configuration, source patch, and local packaging
tool. It deliberately excludes NVIDIA runtime DLLs and other third-party binaries.

1. Supply a local runtime folder containing these files:
   - `ReShade64.dll` and `ReShade64.json`
   - `standalone-dlssnr.addon64`
   - `nvngx.dll`
   - `nvngx_dlss.dll`
   - optionally `nvngx_dlssnr.dll` for neural rendering
2. Build a local install package:

   ```powershell
   .\tools\package-local.ps1 -RuntimeFolder C:\path\to\your\runtime
   ```

3. In the ReImagined launcher, open **Settings > Mods**, select **Install from ZIP**, and choose the
   generated archive in `dist`.

The ZIP is for local testing. Do not redistribute third-party binaries unless their applicable
licenses expressly permit your distribution.

## Presets

| Setting | Bridge working input | Purpose |
|---|---:|---|
| Native 1440p (DLAA) | 2560x1440 | Full-resolution antialiasing; adds GPU work |
| Quality | 1920x1080 | Downsampled bridge input; game rendering is unchanged |
| Balanced | 1600x900 | Smaller bridge input; game rendering is unchanged |
| Performance | 1280x720 | Smallest listed bridge input; game rendering is unchanged |

These names currently describe reconstruction inside the bridge, not integrated game
rendering presets. They should not be interpreted as a promise of higher frame rates.

The launcher writes the chosen values to `ReShade.ini` immediately before starting the game.
The package includes a disabled no-op ReShade technique so Vulkan still reaches the effects
boundary used by the bridge when the player has no shader collection installed.

## Source

`patches/0001-reimagined-vulkan-bridge.patch` records the local changes made on top of
[DLSS5 ReShade AIO 2.2.4](https://github.com/kibblerz/DLSS5-Reshade-AIO). The add-on is Apache-2.0;
its `LICENSE`, `NOTICE`, and third-party notices are included here. ReShade and NVIDIA software keep
their own licenses and are not relicensed by this repository.
