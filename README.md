# Aincrad UI v0.1 — EXPERIMENTAL

Experimental SpringBoard-only Dopamine Rootless tweak for iPhone 8 / iOS 16.7.16.

**Not validated on device.** iOS 16 SpringBoard may ignore orientation hooks; icon grid reflow is NOT implemented. The tweak is **disabled by default**. Do not rely on this as a stable landscape solution.

Features under test:
- Allow landscape orientation from SpringBoard root controllers
- Hide the complete Dock view (icons + background) when enabled
- Never target third-party applications

Build: GitHub Actions -> Actions -> Build Aincrad UI -> Artifacts. Package uses architecture iphoneos-arm64.

Before enabling: Disable Atria layout modifications; retain ability to enter safe mode. Do not install on a primary phone.

Settings file on device: /var/mobile/Library/Preferences/com.aincrad.ui.plist
Keys: Enabled (boolean, default false), HideDock (boolean, default true). Must respring to reload settings.

To disable: remove or set Enabled=false and respring. If SpringBoard repeatedly crashes, use Dopamine's tweaks-off option / safe mode and uninstall in Sileo.

This project does not modify protected system files, forcibly rotate other apps, or alter thermal management.

This is a proof-of-concept, not a verified iOS 16 landscape implementation.
