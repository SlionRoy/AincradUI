# Aincrad system-wide scaling research (iPhone 8 / iOS 16.7.16)

State: **read-only research** as of v1.9.1. The menu's native-to-target resolution is *a mathematical preview only*; it does **not** apply any framebuffer changes.

## Compatibility status
- Device: iPhone 8, arm64, iOS 16.7.16, Dopamine rootless.
- Re:Scale 2 changes backboardd runtime behavior and is explicitly not guaranteed on every iOS version. Source: https://github.com/SniperGER/ReScale2
- ResSet16 explicitly states it does not work above iOS 16.1.2. Source: https://github.com/sourcelocation/ResSet16/releases
- Therefore neither can be assumed compatible with iOS 16.7.16.

## Requirements before enabling real system zoom
1. Verify runtime backboardd hook symbol and signature on **this exact OS/device**. Do not guess selectors.
2. Keep all changes in RAM with a strict model-specific allowlist, never write IOMobileGraphicsFamily preferences or persistent canvas files.
3. Backup/record the original geometry before applying any change. Bounds-check aspect ratio, even pixel dimensions, and logical display-scale compatibility.
4. Design an out-of-process startup watchdog that disables hooks after crash/restart; a SpringBoard-only watchdog is insufficient because backboardd can fail before SpringBoard.
5. Verify recovery through an untweaked boot / Dopamine jailbreak tweaks disabled path **before first write test**.
6. Test one conservative resolution adjustment at a time, explicitly opting in. Provide on-screen countdown and automatic revert only after a verified backboardd-safe rollback method exists.
7. If verification fails, leave the write pathway absent entirely. Never use undocumented persistent modifications as a substitute.

## Version v1.9.1
Read-only system canvas preview: native width/height divided by local interface scale; rounded to even pixels. This is a rough target, **not** a compatibility guarantee and **not** active system scaling.
