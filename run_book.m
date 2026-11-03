% RUN_BOOK  Regenerates every number and figure of the book (edition 1.0).
% Run from the MicrogridSizing folder: >> run_book
% Each step is protected: an error is logged in results/run_progress.txt
% and the next step still runs. Takes several hours on 4 parallel workers.
% Expected outputs: the results/*.txt files listed in README.md.
addpath(genpath(pwd));
if ~exist('results','dir'), mkdir('results'); end
runlog('=== run_book started (book edition 1.0)');
runlog('start rebuild_ev_profile');
try, rebuild_ev_profile; runlog('done  rebuild_ev_profile'); catch err__, runlog('FAILED rebuild_ev_profile', err__); end
close all force; diary off;
runlog('start run_all_tests');
try, if exist('results/tests_log.txt','file'), delete('results/tests_log.txt'); end; diary('results/tests_log.txt'); run_all_tests; diary off; runlog('done  run_all_tests'); catch err__, runlog('FAILED run_all_tests', err__); end
close all force; diary off;
runlog('start ch03_wind_curve');
try, ch03_wind_curve; runlog('done  ch03_wind_curve'); catch err__, runlog('FAILED ch03_wind_curve', err__); end
close all force; diary off;
runlog('start ch08_benchmark');
try, ch08_benchmark; runlog('done  ch08_benchmark'); catch err__, runlog('FAILED ch08_benchmark', err__); end
close all force; diary off;
runlog('start main');
try, main; runlog('done  main'); catch err__, runlog('FAILED main', err__); end
close all force; diary off;
runlog('start ch09_fill_values');
try, ch09_fill_values; runlog('done  ch09_fill_values'); catch err__, runlog('FAILED ch09_fill_values', err__); end
close all force; diary off;
runlog('start ch09_checks');
try, ch09_checks; runlog('done  ch09_checks'); catch err__, runlog('FAILED ch09_checks', err__); end
close all force; diary off;
runlog('start ch09_pareto');
try, ch09_pareto; runlog('done  ch09_pareto'); catch err__, runlog('FAILED ch09_pareto', err__); end
close all force; diary off;
runlog('start ch09_figures');
try, ch09_figures; runlog('done  ch09_figures'); catch err__, runlog('FAILED ch09_figures', err__); end
close all force; diary off;
runlog('start ch09_penalty');
try, ch09_penalty; runlog('done  ch09_penalty'); catch err__, runlog('FAILED ch09_penalty', err__); end
close all force; diary off;
runlog('start ch06_rounding');
try, ch06_rounding; runlog('done  ch06_rounding'); catch err__, runlog('FAILED ch06_rounding', err__); end
close all force; diary off;
runlog('start ch04_worked_example');
try, ch04_worked_example; runlog('done  ch04_worked_example'); catch err__, runlog('FAILED ch04_worked_example', err__); end
close all force; diary off;
runlog('start ch10_base_case');
try, ch10_base_case; runlog('done  ch10_base_case'); catch err__, runlog('FAILED ch10_base_case', err__); end
close all force; diary off;
runlog('start ch10_placement');
try, ch10_placement; runlog('done  ch10_placement'); catch err__, runlog('FAILED ch10_placement', err__); end
close all force; diary off;
runlog('start ch10_weights');
try, ch10_weights; runlog('done  ch10_weights'); catch err__, runlog('FAILED ch10_weights', err__); end
close all force; diary off;
runlog('start ch10_fullyear');
try, ch10_fullyear; runlog('done  ch10_fullyear'); catch err__, runlog('FAILED ch10_fullyear', err__); end
close all force; diary off;
runlog('start ch11_sensitivity');
try, ch11_sensitivity; runlog('done  ch11_sensitivity'); catch err__, runlog('FAILED ch11_sensitivity', err__); end
close all force; diary off;
runlog('start ch11_montecarlo');
try, ch11_montecarlo; runlog('done  ch11_montecarlo'); catch err__, runlog('FAILED ch11_montecarlo', err__); end
close all force; diary off;
runlog('start ch11_reliability');
try, ch11_reliability; runlog('done  ch11_reliability'); catch err__, runlog('FAILED ch11_reliability', err__); end
close all force; diary off;
runlog('=== run_book finished');
fid = fopen('results/run_done.txt', 'w'); fprintf(fid, 'book edition 1.0 | %s\n', datestr(now)); fclose(fid);
