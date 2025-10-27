function result = wilcoxon_rs_results(x, y)
% WILCOXON_RS_RESULTS  Report full Wilcoxon rank-sum (Mann–Whitney U) test output.
% Usage:
%   result = wilcoxon_rs_results(x, y)
% Inputs:
%   x, y  - numeric vectors of independent samples
% Output:
%   result - struct with p, W, U, z, n1, n2, rank-biserial r, and Cliff’s delta
%
% Example:
%   wilcoxon_rs_results(Saline, Ghrelin);

x = x(:); y = y(:);
nx = numel(x); ny = numel(y);

% Choose exact vs approximate method
if min(nx,ny) < 10 && nx + ny < 20
    [p,~,stats] = ranksum(x, y, 'method','exact');
else
    [p,~,stats] = ranksum(x, y, 'method','approximate');
end

% --- Core stats ---
W = stats.ranksum;                    % Sum of ranks for first group
U = W - nx*(nx+1)/2;                  % Mann–Whitney U
if isfield(stats,'zval')
    z = stats.zval;
else
    % approximate z if missing
    muU = nx*ny/2;
    sigmaU = sqrt(nx*ny*(nx+ny+1)/12);
    z = (U - muU) / sigmaU;
end

% --- Effect sizes ---
r_rb  = 1 - 2*U/(nx*ny);              % rank-biserial correlation
delta = (2*U)/(nx*ny) - 1;            % Cliff’s delta

% --- Store results ---
result = struct( ...
    'n1', nx, 'n2', ny, ...
    'p', p, 'W', W, 'U', U, 'z', z, ...
    'r_rb', r_rb, 'delta', delta );

% --- Print summary ---
fprintf('Wilcoxon rank-sum test (two-sided):\n');
fprintf('  n1 = %d, n2 = %d\n', nx, ny);
fprintf('  W = %.1f, U = %.1f, z = %.3f, p = %.4g\n', W, U, z, p);
fprintf('  Effect sizes: rank-biserial r = %.3f, Cliff''s δ = %.3f\n\n', r_rb, delta);
end
