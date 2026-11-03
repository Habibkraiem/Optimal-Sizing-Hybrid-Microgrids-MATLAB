# Data in this folder

| File | Content | Source |
| --- | --- | --- |
| `nasa_power_30.98_41.04_2023.csv` | Hourly weather for Arar, Saudi Arabia (30.98 N, 41.04 E), 2023: GHI, air temperature, wind at 10 m and 50 m | NASA POWER (downloaded with `download_nasa_power.m`) |
| `site_profiles_v1.mat` | Weather + synthetic load + first EV profile (timetable `TT`, 8,760 h) | Built by `build_site_profiles.m` |
| `site_profiles.mat` | Same, with the chronological EV profile of Chapter 2 (used by every script of the book) | Built by `rebuild_ev_profile.m` |

**Acknowledgment (required by NASA POWER):** The data was obtained from the National Aeronautics and Space
Administration (NASA) Langley Research Center (LaRC) Prediction of Worldwide Energy Resource (POWER) Project,
funded through the NASA Earth Science/Applied Science Program. Hourly data, version 2.x, accessed in October 2026.
See https://power.larc.nasa.gov/docs/referencing/ for the exact citation format.

The household load and the EV sessions are synthetic (Chapter 2); replace them with measured data for a real study.
