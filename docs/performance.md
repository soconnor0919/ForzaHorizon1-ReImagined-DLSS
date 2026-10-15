# Performance investigation, 2026-10-15

The present integration adds processing after ReImagined renders the game. It is not
currently a renderer-integrated Super Resolution implementation.

## Findings

1. Native mode creates DLAA at 2560x1440. Preset L added about 12–14 ms of measured
   D3D12 GPU reconstruction time per processed frame. There is no lower-resolution
   game-rendering pass to offset that cost. Neural rendering and frame generation
   were disabled in these tests.
2. `SourceResolutionOverride` changes `ResolvePipelineSourceResolution`'s working
   dimensions. For Vulkan, `RecordVulkanFrameCopy` then blits the already-rendered
   capture to those dimensions before reconstruction. Selecting "Quality" therefore
   rendered 1440p, downsampled the finished capture to 1080p, and reconstructed it to
   1440p. It did not reduce the game's render scale. Reconstruction itself fell to
   roughly 8 ms, but the game retained its rendering cost and the extra downsample.
3. The process-local ReShade layer has overhead even without the add-on. The add-on
   additionally copies shared images between Vulkan and D3D12, synchronizes fences,
   estimates motion using optical flow, and displays through a separate proxy.
   Source-frame FPS and proxy FPS are separate measurements. Native proxy telemetry
   showed skipped frames and roughly 40–45 ms handoff latency before throttling.
4. The adaptive pressure governor adds a second limiter independent of the game's
   120 FPS cap. In the native test its target fell to 25 FPS, then oscillated around
   25–30 FPS. Source and processed-output rates diverged when it increased the cap.

The tests establish costs and locate the stalls in the bridge path. They do not yet
identify the particular synchronization operation responsible for every long stall.

## Checks

RTX 5060 Ti, patched Vulkan presenter, 2560x1440 fullscreen output, render scale 2,
120 FPS game cap, 16x anisotropic filtering. Each run loaded a fresh copy of the same
save and left the car at the "Drive to the festival" spawn. The user's separate FH2
test remained running throughout the comparison, so these are shared-load results.
All add-on settings and binaries were copied into isolated benchmark folders; the
installed mod and saved launcher preferences were not changed.

| Configuration | Game/source FPS | Output observation |
| --- | ---: | --- |
| DLSS/ReShade absent | 38.5 | 38.5 Vulkan presents/sec |
| DLSS off again; Ultrawide loaded at 16:9 | 37.0 | 37.0 Vulkan presents/sec; long bridge stalls absent |
| ReShade, no add-on loaded | 35.6 | 35.6 Vulkan presents/sec |
| Native DLAA, preset L | 26.8 | Proxy telemetry fluctuated around 15–25 FPS late in the run |
| 1080p bridge input, preset L | 9.3 | Large stalls; proxy samples also dropped sharply |
| Native DLAA, preset K | No steady sample | Stopped advancing frames at about 21 seconds |
| Native DLAA, optical flow disabled | No improvement | Large stalls persisted; not a recommended workaround |

Game/source values use per-frame CSV samples from seconds 55–70 of each run, after
the capture at about 50 seconds. Proxy observations come from the add-on's separate
rolling counters, logged every five seconds; they are not averaged CSV presentation
rates. The low-rate bridge runs were unstable and are not usable performance presets.
The installed add-on and the local build artifact had identical SHA-256 hashes.
The add-on was not rebuilt for this investigation. The final off control also loaded
the Ultrawide mod at 16:9, where its camera widening is inactive; it is a recovery
check rather than an exact repeat of the first row.

## What needs to change

For a performance-oriented SR mode, the launcher/runtime must lower the actual game
rendering resolution before reconstruction, then provide the resulting color and
game motion/depth data to the reconstruction pass. HUD handling must remain separate
to preserve text clarity. The present source-resolution override alone cannot do that.

The Vulkan/D3D12 capture and proxy synchronization also needs profiling and repair.
Turning optical flow off did not solve it, and replacing preset L with K stalled in
this test. Neither is a validated fix. Keep those diagnostic results distinct from
the already-installed SDK presenter pipeline-cache fix.
