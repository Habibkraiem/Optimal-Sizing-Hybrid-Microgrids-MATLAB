# Optimal Sizing of Hybrid Microgrids with MATLAB – companion code (v1.0)

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.23921752.svg)](https://doi.org/10.5281/zenodo.23921752)

Companion code for the book *Optimal Sizing of Hybrid Microgrids with MATLAB: PV, Wind, Battery and EV Charging
Stations Solved with PSO and Metaheuristics, Step by Step* (Habib Kraiem, first edition, 2026).
This repository's release **v1.0.1** is the exact version that produced every number and figure printed in the book.

- **Book:** on Amazon, [paperback](https://www.amazon.com/dp/B0HQB1H34Q) (ISBN 9798167661820) and [Kindle eBook](https://www.amazon.com/dp/B0HQ87RSPS); DRM-free PDF + EPUB on [Leanpub](https://leanpub.com/microgrid-sizing-matlab) (free sample: Chapters 1–3).
- **Archived version and DOI:** Zenodo, [10.5281/zenodo.23921752](https://doi.org/10.5281/zenodo.23921752) (all versions; v1.0.1 is [10.5281/zenodo.23921753](https://doi.org/10.5281/zenodo.23921753)).
- **Errata:** see [ERRATA.md](ERRATA.md); report errors through the Issues tab.
- **Cite:** see [CITATION.cff](CITATION.cff) (GitHub shows a "Cite this repository" button).

## Quick start

1. Unzip the folder and open it in MATLAB. Tested with **MATLAB R2022b** on Windows; R2020a or newer is needed
   (`exportgraphics`, `xline`).
2. Run `run_all_tests` (about ten minutes). Each test prints `PASS` or `FAIL`; the last line gives the totals.
   If `data/site_profiles.mat` does not exist, the tests first create **synthetic demo data** with `make_demo_data`.
3. Run `run_book` to regenerate every result of the book (several hours with 4 parallel workers; progress in
   `results/run_progress.txt`). Compare your `results/*.txt` with the files in `expected_results/` (see [CHANGELOG.md](CHANGELOG.md) for the one file to regenerate).
4. For your own site: edit the SITE block of `build_site_profiles.m` (coordinates, year), run it once
   (internet needed for NASA POWER), and replace every value in `load_parameters.m` with datasheet values and local prices.

## Requirements

| Item | Needed for |
| --- | --- |
| Base MATLAB R2020a+ | everything |
| Parallel Computing Toolbox (optional) | `parfor` in the long runs; without it they run serially (slower), results identical |
| Statistics and Machine Learning Toolbox | `ranksum`, `kruskalwallis`, `tiedrank`, `prctile` in `ch09_fill_values.m` only |
| MATPOWER (free, https://matpower.org) | IEEE 33-bus data `case33bw` in Chapter 10 |

## What `run_book` runs, and the expected outputs

| Step | Output (in `results/`) | Book |
| --- | --- | --- |
| `rebuild_ev_profile` | `ev_check.txt`, `ev_sessions.csv` | Section 2.4 |
| `run_all_tests` | `tests_log.txt` (all PASS) | Preface |
| `ch03_wind_curve` | `ch03_wind_curve.txt` | Section 3.2 |
| `ch08_benchmark` | `ch08_benchmark.txt` | Section 8.4 |
| `main` | `case_study_runs.mat`, `best_design.mat`, `main_log.txt` | Section 9.5 |
| `ch09_fill_values` | `ch09_values.txt`, `all_runs.csv` (every run, seeds 1–30) | Section 9.5 |
| `ch09_checks` | `ch09_checks.txt` (verification table) | Section 9.6 |
| `ch09_pareto`, `ch09_figures` | `pareto.mat`, figures | Section 9.5 |
| `ch09_penalty` | `ch09_penalty.txt` | Section 9.6 |
| `ch06_rounding` | `ch06_rounding.txt` | Sections 6.4, 9.6 |
| `ch04_worked_example` | `ch04_worked_day.txt` | Section 4.6 |
| `ch10_base_case`, `ch10_placement`, `ch10_weights`, `ch10_fullyear` | `ch10_values.txt`, `ch10_weights.txt`, `ch10_fullyear.txt` | Chapter 10 |
| `ch11_sensitivity`, `ch11_montecarlo`, `ch11_reliability` | `ch11_sensitivity.txt`, `ch11_montecarlo.txt`, `ch11_reliability.txt` | Chapter 11 |

All random numbers come from fixed seeds (`rng`), so a rerun gives the same numbers on the same MATLAB
version. Another MATLAB version or a different number of parallel workers can change the last digits of
optimizer results; the conclusions do not change.

## Three kinds of code in the book

- **Complete files**: every listing that starts with a file name comment (for example `% models/battery_step.m`)
  is in this package, identical or longer.
- **Fragments**: short listings without a file name illustrate one idea; the complete version is in the file
  named in the text.
- **Exercises**: functions you are asked to write in the exercises are not provided.

## Folder structure

| Folder / file | Content | Chapter |
| --- | --- | --- |
| `data/` | `download_nasa_power`, `build_load_profile`, `ev_sessions_year`, `ev_queue_check`, `ev_profile_mc` (quick periodic sketch only), data files | 2 |
| `models/` | `pv_model`, `poa_irradiance`, `wind_model`, `battery_step`, `smart_charge` | 3 |
| `ems/` | `simulate_year` (rule-based dispatch), `energy_audit` | 4 |
| `optim/` | `component_npc`, `evaluate_design`, `define_problem`, `fitness`, `design_result`, `pso`, `ga_real`, `gwo`, `rda`, `BudgetFitness`, `pareto_front` | 5–8 |
| `network/` | `bfs_loadflow`, `load_ieee33`, `apply_der`, `fitness_placement` | 10 |
| `reliability/` | `updown_series`, `simulate_year_av`, `perturb`, `sample_costs`, `load_weather_years` | 11 |
| `load_parameters.m` | All technical and economic parameters | 3–5, 9 |
| `load_optimizer_settings.m` | Settings of the four algorithms for a given evaluation budget | 7–8 |
| `ch*.m`, `main.m` | Chapter scripts | 1–11 |
| `run_all_tests.m`, `run_book.m` | Tests and master script | all |

## Notes

- `rda.m` is a **simplified educational version** of the Red Deer Algorithm. For research, use an implementation
  that follows the original paper (Fathollahi-Fard et al., *Soft Computing*, 2020).
- `ev_profile_mc.m` wraps sessions inside one day and is kept only to sketch a mean day; never use it for an annual simulation.
- `load_weather_years` uses files `data/weather_YYYY.mat` if you add them (several NASA POWER years); otherwise
  the Monte Carlo of Chapter 11 samples load, EV behaviour and costs with the single case-study year.

## Licence

MIT Licence, see `LICENSE`. Weather data from NASA POWER are public; cite them as described in Chapter 2.
