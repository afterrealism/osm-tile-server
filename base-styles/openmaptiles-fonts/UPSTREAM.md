# Upstream Provenance

URL: https://github.com/openmaptiles/fonts
Tag: v2.0
Commit: a4f9e7cf18aa382945c0a912f3022ba94a0b1d52
Vendored: 2026-07-19
Local modifications: None at initial vendoring.
Upstream pushes: Prohibited; changes are maintained only in this repository.
2026-08-04: package.json: fontnik 0.5.0 -> 0.7.7 (0.5.0 cannot compile against
Node >= 20 V8 API); added package-lock.json, installs use npm ci.
2026-08-04: generate.js: honors an optional FONT_FAMILIES env allowlist
(comma-separated family names); no behavior change when unset.
