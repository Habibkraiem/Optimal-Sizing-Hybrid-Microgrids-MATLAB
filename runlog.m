function runlog(msg, err)
% RUNLOG  Appends a time-stamped line to results/run_progress.txt.
f = fullfile(pwd, 'results', 'run_progress.txt');
fid = fopen(f, 'a');
fprintf(fid, '[%s] %s\n', datestr(now, 'yyyy-mm-dd HH:MM'), msg);
if nargin > 1
    fprintf(fid, '      %s\n', err.message);
    for k = 1:min(3, numel(err.stack))
        fprintf(fid, '      at %s line %d\n', err.stack(k).name, err.stack(k).line);
    end
end
fclose(fid);
fprintf('[%s] %s\n', datestr(now, 'HH:MM'), msg);
end
