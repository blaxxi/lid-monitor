# LidMonitor

A tiny macOS menu-bar app that watches your MacBook's lid angle and dims the
machine when you start to close it — turn the volume down, drop the brightness,
optionally pause playback. Open the lid back up and everything snaps back to
where it was.

[![CI](https://github.com/blaxxi/lid-monitor/actions/workflows/ci.yml/badge.svg)](https://github.com/blaxxi/lid-monitor/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)](https://www.apple.com/macos/)

## Features

- **Live lid-angle readout** in the menu bar popover, sourced from the HID
  lid-angle sensor present on modern MacBooks.
- **Dim mode** that auto-engages below a user-configurable threshold:
  - Drops system output volume to a target level.
  - Drops display brightness to a target level.
  - Optionally pauses any playing media (Music, Spotify, browser video, …).
  - Restores the previous volume + brightness on release.
- **Launch at login** toggle backed by `SMAppService`.
- **No background daemon, no kernel extensions, no networking.** Sits in the
  menu bar, polls the lid sensor every 0.5 s, and that's it.

## Requirements

- macOS 13 (Ventura) or later.
- A MacBook with a hardware lid-angle sensor (most M1/M2/M3 generation
  notebooks). Older Macs will still install the app, but the angle readout
  will show `—` and dim mode won't trigger.

## Install

### From a release

1. Grab the latest `LidMonitor.app.zip` from the
   [Releases](https://github.com/blaxxi/lid-monitor/releases) page.
2. Unzip and drag `LidMonitor.app` into `/Applications`.
3. First launch: right-click → **Open** (the build is ad-hoc signed, so
   Gatekeeper will ask for confirmation once).

### From source

```sh
git clone https://github.com/blaxxi/lid-monitor.git
cd lid-monitor
./build.sh --install
```

`build.sh` runs `swift build -c release`, assembles the `.app` bundle, ad-hoc
signs it, and (with `--install`) copies it to `/Applications` and launches it.

## How it works

```
LidMonitor (orchestrator)
├── ClamshellMonitor  ← IOPMrootDomain "AppleClamshellState" notifications
├── LidAngleSensor    ← IOHIDManager polling Apple's lid-angle HID sensor
├── DimController     ← state machine: capture → dim → restore
└── Preferences       ← UserDefaults-backed settings
```

System effects are isolated:

- **Volume** — CoreAudio (`kAudioHardwareServiceDeviceProperty_VirtualMainVolume`)
- **Brightness** — `DisplayServicesGetBrightness` / `DisplayServicesSetBrightness`
  via `dlopen` of the private `DisplayServices` framework.
- **Media pause** — `MRMediaRemoteSendCommand` via `dlopen` of the private
  `MediaRemote` framework.

The two private frameworks are loaded lazily; if Apple ever pulls them, the
corresponding feature degrades gracefully (logged via `os.Logger`) without
crashing the app.

## Project layout

```
Sources/LidMonitor/
  App.swift              · @main + scene
  ContentView.swift      · root popover view
  AngleHero.swift        · gradient angle readout + quit button
  DimBadge.swift         · "dimmed below N°" pill
  SettingsCard.swift     · settings rows (threshold, sliders, toggles)
  Theme.swift            · shared gradients
  LidMonitor.swift       · orchestrator
  Preferences.swift      · UserDefaults model
  ClamshellMonitor.swift · IOPM clamshell observer
  LidAngleSensor.swift   · HID lid-angle polling
  DimController.swift    · dim/restore state machine
  SystemControls.swift   · CoreAudio + DisplayServices + MediaRemote
  LaunchAtLogin.swift    · SMAppService wrapper
  Logging.swift          · os.Logger categories
Resources/
  Info.plist             · app bundle manifest
  AppIcon.icns           · generated app icon
tools/
  make_icon.swift        · regenerates AppIcon.icns from SF Symbols
build.sh                 · release build + bundle + ad-hoc sign + install
```

## Privacy

LidMonitor never makes a network request, never reads or writes outside its
own `UserDefaults` domain, and never asks for Accessibility, Screen Recording,
or any other TCC permission. The only system surfaces it touches are the
volume, the brightness, and the currently-playing media transport — and only
when you cross the threshold you set.

## License

[MIT](LICENSE) © 2026 blaxxi
