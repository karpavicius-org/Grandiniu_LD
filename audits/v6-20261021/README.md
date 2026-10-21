# Accepted LD1–LD12 v6 — 2026-10-21

The student sources in this commit reproduce the accepted v6 ZIP. ACCEPTED_RELEASE.json records its SHA-256 and all 217 member hashes. The compiled Windows DLL remains in that separately delivered ZIP; studentui/bin is intentionally excluded by the existing repository policy. No core algorithms, workflows or launchers were changed for this commit.

Linux native model and all12 GUI-to-HTML flows passed in the preceding session using a separately built native .so; the bounded repeat confirms all12 first-trial measurements. The distributed ZIP itself contains only the Windows DLL: its unmodified Linux launcher fails with missing bin/ldcore.so. macOS also requires a separately built ldcore.dylib; no native macOS runtime or SDK is available here, so no macOS execution PASS is asserted. Windows11 startup was confirmed by the user, not executed on this Linux host. See OS_PORTABILITY.json.

MODEL64.json covers 12×64 configurations. FINAL_DATA.json and NUMERICAL.json cover all12 real-input flows, independent equations / actual cable-graph MNA, and teacher12/12 import. REPORTS.json covers36 standalone HTML reports, responsive layout and three print-layout samples. COMPATIBILITY.json and AUTOREFRESH.json cover old v5 data. WIRES.json covers51 graphs/437 cables. SOURCE_BOUNDARIES.json records the colour-only post-flow change and final LD7/LD10 replay. Raw test attempts were retained locally; these summaries do not reclassify failed attempts as successful.

The accepted v5 and v6 ZIPs are unchanged. This is a source/evidence checkpoint; it does not claim a single cross-platform binary package. CI was not invoked.
