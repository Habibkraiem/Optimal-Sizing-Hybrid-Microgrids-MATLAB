# Changelog

## v1.0.1 – book edition (2026-11-03)

Archived on Zenodo: DOI 10.5281/zenodo.23921752 (all versions), 10.5281/zenodo.23921753 (v1.0.1).

First public release. This is the exact version that produced every number and figure printed in the first
edition of *Optimal Sizing of Hybrid Microgrids with MATLAB* (Habib Kraiem, 2026).

- Complete code of Chapters 1 to 11: component models, energy management, economics, PSO, GA, GWO and a
  simplified Red Deer Algorithm, the Arar case study, IEEE 33-bus placement, sensitivity, Monte Carlo and
  reliability analysis.
- `run_all_tests.m`: 31 tests (all PASS with MATLAB R2022b; the IEEE 33-bus test is skipped if MATPOWER is not on the path).
- `run_book.m`: regenerates every result of the book (about 14 hours with 4 parallel workers).
- `expected_results/`: the output files of the run used for the book, for comparison.
- Known difference: `results/ch09_checks.txt` must be regenerated with the corrected `ch09_checks.m`
  (the EV departure-energy check now accepts the one session limited by its dwell time); it is therefore not in
  `expected_results/`.
