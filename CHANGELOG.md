# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-05-05

### Added
- Menu-bar app showing live lid angle, sourced from the HID lid-angle sensor on
  supported MacBooks.
- "Dim mode": when the lid drops below a configurable threshold, drop output
  volume + display brightness to user-set levels and (optionally) pause media
  playback. Original levels are restored when the lid opens back up.
- Glass-morphism popover with gradient angle readout, threshold stepper,
  volume / brightness sliders, "Pause media" toggle, and "Launch at login"
  toggle (`SMAppService`).
- Auto-detection of the HID sensor's logical-max angle for future calibration.
- Custom app icon, ad-hoc-signed `.app` bundle, install script.

[Unreleased]: https://github.com/blaxxi/lid-monitor/compare/v0.1.0...HEAD
[0.1.0]:      https://github.com/blaxxi/lid-monitor/releases/tag/v0.1.0
