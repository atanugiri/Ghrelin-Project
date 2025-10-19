function out = twoWayAnova_flex(normType, saveToExcel, fileName, varargin)
% twoWayAnova_flex
% Flexible ANOVA utility for 2-group comparisons across k tasks (files).
% - You pick TWO columns once (e.g., [1 2], [1 3], [1 4], ...).
% - Each file is a Task; labels auto-assigned as Task1, Task2, ...
% - Normalization: 2=z-score vs group1; 3=min-max; otherwise raw.
%
% Outputs:
%   out.data       : long table (Y, Group, Task)
%   out.twoway     : anovan outputs for Group, Task, Interaction
%   out.allgroups  : anovan outputs for one-way across all 2*k groups
%   out.pooled     : t-test, Wilcoxon RS, Kruskal–Wallis, KS + rich stats
%   out.paired     : paired t-test and Wilcoxon signed-rank (if applicable)
%
% Example:
%   out = twoWayAnova_flex(3, false, '', "FileA.csv","FileB.csv","FileC.csv");

% ---------- Choose columns once ----------
T0 = readtable(varargin{1}, 'VariableNamingRule','preserve');
varNames = T0.Properties.VariableNames;
fprintf('\nColumns in first file:\n');
for i = 1:numel(varNames), fprintf('  %2d: %s\n', i, varNames{i}); end
def = '[1 2]';
idxStr = input(sprintf('Indices for the TWO groups to compare (default %s): ', def), 's');
if isempty(idxStr), idx = eval(def); else, idx = eval(idxStr); end
assert(numel(idx)==2, 'Please specify exactly two column indices, e.g., [1 3].');
gA_idx = idx(1); gB_idx = idx(2);

% ---------- Build long-format + paired accumulators ----------
Y = zeros(0,1);
Group = strings(0,1);
Task  = strings(0,1);

pairA_all = zeros(0,1);
pairB_all = zeros(0,1);
pairTask  = strings(0,1);

for fi = 1:numel(varargin)
    Ti = readtable(varargin{fi}, 'VariableNamingRule','preserve');

    % Coerce both selected columns to numeric columns
    colA = toNumericCol(Ti{:, gA_idx});
    colB = toNumericCol(Ti{:, gB_idx});

    % Normalize together, then split
    X  = [colA, colB];
    X  = normalizeData(X, normType);
    a0 = X(:,1);         % originals (unfiltered) for pairing decision
    b0 = X(:,2);

    % ===== PAIRED path (only if same length) =====
    if numel(a0) == numel(b0)
        pairmask = isfinite(a0) & isfinite(b0);   % pairwise-complete rows
        if any(pairmask)
            ap = a0(pairmask);
            bp = b0(pairmask);
            pairA_all = [pairA_all; ap];
            pairB_all = [pairB_all; bp];
            pairTask  = [pairTask; repmat("Task"+fi, numel(ap), 1)];
        end
    end

    % ===== INDEPENDENT path (always) =====
    a = a0(isfinite(a0)); if isempty(a), a = zeros(0,1); end
    b = b0(isfinite(b0)); if isempty(b), b = zeros(0,1); end

    Y     = [Y; a; b];
    Group = [Group; repmat("Group1", numel(a), 1); repmat("Group2", numel(b), 1)];
    Task  = [Task;  repmat("Task"+fi, numel(a)+numel(b), 1)];
end

Group = categorical(Group, ["Group1","Group2"]);
Task  = categorical(Task);
dataTable = table(Y, Group, Task);

if saveToExcel
    if isempty(fileName), fileName = 'twoWayAnova_data'; end
    writetable(dataTable, [fileName, '.xlsx']);
end

% ---------- (1) Two-way ANOVA: Group × Task (with interaction) ----------
[p2, tbl2, stats2] = anovan(dataTable.Y, ...
    {dataTable.Group, dataTable.Task}, ...
    'model', 'interaction', 'varnames', {'group','task'});

% Extract pretty numbers for printing
[group_df, group_F, group_p] = pickRow(tbl2, 'group');
[task_df,  task_F,  task_p ] = pickRow(tbl2, 'task');
[inter_df, inter_F, inter_p] = pickRow(tbl2, 'group:task');
[error_df]                   = pickErrorDF(tbl2);

% ---------- (2) One-way across all bars (2*k groups) ----------
combo = categorical(strcat(string(dataTable.Task), "_", string(dataTable.Group)));
[p1, tbl1, stats1] = anovan(dataTable.Y, {combo}, 'varnames', {'task_group'});
[between_df, between_F, between_p] = pickRow(tbl1, 'task_group');
[within_df] = pickErrorDF(tbl1);

% ---------- (3) Pooled stats: Group1 vs Group2 (independent) ----------
YA = dataTable.Y(dataTable.Group=="Group1");
YB = dataTable.Y(dataTable.Group=="Group2");
n1 = numel(YA); n2 = numel(YB);

% Descriptives (parametric & nonparametric)
meanA = mean(YA,'omitnan');  sdA = std(YA,'omitnan');
meanB = mean(YB,'omitnan');  sdB = std(YB,'omitnan');
medA  = median(YA,'omitnan'); iqrA = iqr(YA);
medB  = median(YB,'omitnan'); iqrB = iqr(YB);

% Welch t-test (unequal variances) with df + CI
[~, p_t, ci_t, S] = ttest2(YA, YB, 'Vartype','unequal');  % ci_t = [lo hi]
t_val = S.tstat; t_df = S.df;

% Wilcoxon rank-sum (Mann–Whitney U) + effect sizes
[p_rs, ~, srs] = ranksum(YA, YB, 'method','approximate'); % z in srs.zval
W = srs.ranksum;                         % sum of ranks for group1
U = W - n1*(n1+1)/2;                     % Mann–Whitney U for group1
rb = 1 - (2*U)/(n1*n2);                  % rank-biserial correlation ([-1,1])
delta = (2*U)/(n1*n2) - 1;               % Cliff's delta

% Kruskal–Wallis (non-parametric one-way for 2 groups)
groupLabels = [repmat("Group1", n1,1); repmat("Group2", n2,1)];
Ypooled     = [YA; YB];
[p_kw, tbl_kw] = kruskalwallis(Ypooled, groupLabels, 'off');
KW_H = tbl_kw{2,5}; % H statistic

% Kolmogorov–Smirnov two-sample
[~, p_ks, ks_stat] = kstest2(YA, YB);

% ---------- (4) Paired tests (only if we actually collected pairs) ----------
n_pairs = numel(pairA_all);
if n_pairs >= 2
    % Paired t-test
    [~, p_tpaired, ci_tpaired, S_pair] = ttest(pairA_all, pairB_all);
    tpaired  = S_pair.tstat;
    dfpaired = S_pair.df;

    % Cohen's d_z (paired)
    diffs = pairA_all - pairB_all;
    dz = mean(diffs, 'omitnan') / std(diffs, 'omitnan');

    % Wilcoxon signed-rank (paired)
    [p_wsr, ~, sgn] = signrank(pairA_all, pairB_all, 'method','exact');
    Wsr = sgn.signedrank;
    zsr = sgn.zval;

    paired_out = struct( ...
        'n_pairs', n_pairs, ...
        't_tstat', tpaired, 't_df', dfpaired, 't_ci', ci_tpaired, 't_p', p_tpaired, ...
        'cohens_dz', dz, ...
        'signrank_W', Wsr, 'signrank_z', zsr, 'signrank_p', p_wsr);
else
    paired_out = struct('n_pairs', n_pairs);  % not enough pairs
end

% ---------- Package outputs (build once) ----------
out = struct();
out.data      = dataTable;
out.twoway    = struct('p', p2, 'tbl', tbl2, 'stats', stats2);
out.allgroups = struct('p', p1, 'tbl', tbl1, 'stats', stats1);
out.pooled    = struct( ...
    'n1', n1, 'n2', n2, ...
    'meanA', meanA, 'sdA', sdA, 'meanB', meanB, 'sdB', sdB, ...
    'medianA', medA, 'iqrA', iqrA, 'medianB', medB, 'iqrB', iqrB, ...
    't_tstat', t_val, 't_df', t_df, 't_ci', ci_t, 't_p', p_t, ...
    'ranksum_U', U, 'ranksum_W', W, 'ranksum_z', srs.zval, 'ranksum_p', p_rs, ...
    'cliffs_delta', delta, 'rank_biserial', rb, ...
    'kruskalwallis_H', KW_H, 'kruskalwallis_p', p_kw, ...
    'ks_D', ks_stat, 'ks_p', p_ks);
out.paired    = paired_out;

% ---------- Pretty console print ----------
fprintf('\n==== Two-way ANOVA (Group × Task) ====\n');
fprintf('  Group main effect:        F(%d, %d) = %.3f, p = %.4f\n', group_df, error_df, group_F, group_p);
fprintf('  Task main effect:         F(%d, %d) = %.3f, p = %.4f\n', task_df,  error_df, task_F,  task_p);
fprintf('  Group × Task interaction: F(%d, %d) = %.3f, p = %.4f\n', inter_df, error_df, inter_F, inter_p);

fprintf('\n==== One-way across all bars (for legend) ====\n');
fprintf('  One-way ANOVA: F(%d, %d) = %.3f, p = %.4f  (factor = Task×Group, %d levels)\n', ...
    between_df, within_df, between_F, between_p, between_df+1);

fprintf('\n==== Pooled comparisons (Group1 vs Group2) ====\n');
fprintf('  Welch t-test:        t(%0.2f) = %.3f, p = %.4f, CI95 = [%.3f, %.3f]\n', t_df, t_val, p_t, ci_t(1), ci_t(2));
fprintf('                      Group1: mean±SD = %.3f±%.3f (n=%d); Group2: %.3f±%.3f (n=%d)\n', ...
        meanA, sdA, n1, meanB, sdB, n2);
fprintf('  Rank-sum (Mann–Whitney): W = %.0f, z = %.3f, p = %.4f; Cliff''s Δ = %.3f; r_rb = %.3f\n', ...
        W, srs.zval, p_rs, delta, rb);
fprintf('                      Medians [IQR] → G1: %.3f [%.3f], G2: %.3f [%.3f]\n', medA, iqrA, medB, iqrB);
fprintf('  Kruskal–Wallis:      H = %.3f, p = %.4f\n', KW_H, p_kw);
fprintf('  Kolmogorov–Smirnov:  D = %.3f, p = %.4f\n', ks_stat, p_ks);

if n_pairs >= 2
    fprintf('\n==== Paired comparisons (if applicable) ====\n');
    fprintf('  Paired t-test:        t(%0.2f) = %.3f, p = %.4f, CI95 = [%.3f, %.3f]; Cohen''s d_z = %.3f  (n_pairs = %d)\n', ...
        dfpaired, tpaired, p_tpaired, ci_tpaired(1), ci_tpaired(2), dz, n_pairs);
    fprintf('  Signed-rank (paired): W = %.0f, z = %.3f, p = %.4f  (n_pairs = %d)\n', ...
        Wsr, zsr, p_wsr, n_pairs);
else
    fprintf('\n==== Paired comparisons ====\n');
    fprintf('  Paired tests:         not enough valid pairs (n_pairs = %d)\n', n_pairs);
end
fprintf('\n');

% ================= Helpers (inline) =================
function Xn = normalizeData(X, type)
    switch type
        case 2 % z-score vs Group1
            mu = mean(X(:,1),'omitnan'); sd = std(X(:,1),'omitnan');
            Xn = (X - mu) ./ max(sd, eps);
        case 3 % min-max across both columns
            mn = min(X(:)); mx = max(X(:));
            Xn = (X - mn) ./ max(mx - mn, eps);
        otherwise
            Xn = X;
    end
end

function v = toNumericCol(x)
    % Robustly coerce to numeric column (double)
    if istable(x),       x = x{:,:};      end
    if iscell(x),        x = string(x);   end
    if ischar(x),        x = string(x);   end
    if isstring(x),      x = str2double(x); end
    if iscategorical(x), x = double(x);   end
    if islogical(x),     x = double(x);   end
    if ~isfloat(x),      x = double(x);   end
    v = x(:);
    if isempty(v),       v = zeros(0,1);  end
end

function [df, Fval, pval] = pickRow(tbl, rowname)
    % Robustly pull df, F, p from anovan cell table by looking up headers.
    headers = string(tbl(1,:));
    srcCol = find(strcmpi(headers,'Source'), 1);
    dfCol  = find(strcmpi(headers,'d.f.') | strcmpi(headers,'df'), 1);
    FCol   = find(strcmpi(headers,'F'), 1);
    pCol   = find(strcmpi(headers,'Prob>F') | contains(lower(headers),'prob'), 1);

    df = NaN; Fval = NaN; pval = NaN;
    for r = 2:size(tbl,1)
        lab = string(tbl{r,srcCol});
        if strcmpi(strtrim(lab), strtrim(string(rowname)))
            df   = safeNum(tbl{r,dfCol});
            Fval = safeNum(tbl{r,FCol});
            pval = safeNum(tbl{r,pCol});
            return
        end
    end
end

function err_df = pickErrorDF(tbl)
    headers = string(tbl(1,:));
    srcCol = find(strcmpi(headers,'Source'), 1);
    dfCol  = find(strcmpi(headers,'d.f.') | strcmpi(headers,'df'), 1);
    err_df = NaN;
    for r = 2:size(tbl,1)
        lab = string(tbl{r,srcCol});
        if strcmpi(strtrim(lab), "Error")
            err_df = safeNum(tbl{r,dfCol});
            return
        end
    end
end

function y = safeNum(x)
    if isnumeric(x), y = x; else, y = str2double(string(x)); end
end

end
