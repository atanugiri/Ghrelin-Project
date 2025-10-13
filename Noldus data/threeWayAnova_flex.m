function out = threeWayAnova_flex(normType, saveToExcel, fileName, varargin)
% threeWayAnova_flex (compact)
% 3-way ANOVA across k "task" files with 6 columns:
%   [Saline-WT, IBU-WT, Saline-Inhib, IBU-Inhib, Saline-Excit, IBU-Excit]
% Factors:
%   Group   = {Saline, IBU}
%   Dreadds = {WT, Inhibitory, Excitatory}
%   Task    = {Task1, Task2, ...}   (one per file)
%
% Normalization per task:
%   normType: 1=raw (default), 2=z-score vs col1 (Saline-WT), 3=min-max
%
% Outputs:
%   out.long     : long-format table (Y, Group, Dreadds, Task)
%   out.anovan   : struct with p, tbl, stats
%   out.mc       : post-hoc comparisons (see fields below)
%
% Post-hoc included:
%   out.mc.main.Group / Dreadds / Task                (Tukey)
%   out.mc.interact.GxD / GxT / DxT                   (Tukey over the pair)
%   out.mc.simple.byTask(t).GxD / Group / Dreadds
%   out.mc.simple.byDreadds(d).GxT / Group / Task
%   out.mc.simple.byGroup(g).DxT / Dreadds / Task

if nargin < 1 || isempty(normType),    normType    = 1; end
if nargin < 2 || isempty(saveToExcel), saveToExcel = false; end
if nargin < 3, fileName = ''; end
assert(nargin >= 4, 'Provide at least one file after (normType, saveToExcel, fileName).');

grpLabels = {'Saline','Ghrelin'};  % Ghrelin=2× IBU
dreLabels = {'WT','Inhibitory','Excitatory'};
col2fact  = [1 1; 2 1; 1 2; 2 2; 1 3; 2 3];  % [Group Dreadds] per column

% -------- Build long table --------
Y = []; G = {}; D = {}; T = {};
for fi = 1:numel(varargin)
    Ti  = readtable(varargin{fi}, 'VariableNamingRule','preserve');
    raw = Ti{:,:};
    if size(raw,2) < 6, error('File %s has fewer than 6 columns.', varargin{fi}); end
    X = zeros(height(Ti),6);
    for c = 1:6, X(:,c) = toNumericCol(raw(:,c)); end
    Xn = normalizeTask(X, normType);   % per-task normalization

    for c = 1:6
        y = Xn(:,c); y = y(isfinite(y));
        if isempty(y), continue; end
        gLevel = col2fact(c,1); dLevel = col2fact(c,2);
        Y = [Y; y]; %#ok<AGROW>
        G = [G; repmat(grpLabels(gLevel), numel(y), 1)]; %#ok<AGROW>
        D = [D; repmat(dreLabels(dLevel), numel(y), 1)]; %#ok<AGROW>
        T = [T; repmat({sprintf('Task%d', fi)}, numel(y), 1)]; %#ok<AGROW>
    end
end
Group   = categorical(G, grpLabels);
Dreadds = categorical(D, dreLabels);
Task    = categorical(T);
nTask = numel(Task);   % or: nTask = numel(varargin);
longTbl = table(Y, Group, Dreadds, Task);

if saveToExcel
    if isempty(fileName), fileName = 'threeWayAnova_data'; end
    writetable(longTbl, [fileName '.xlsx'], 'Sheet','long_data');
end

% -------- 3-way ANOVA (full) --------
[p_all, tbl_all, stats_all] = anovan(longTbl.Y, ...
    {longTbl.Group, longTbl.Dreadds, longTbl.Task}, ...
    'model','full', 'varnames', {'Group','Dreadds','Task'}, 'display','on');

% -------- Post-hoc (pick what you need from out.mc) --------
mc = struct();

% (A) Main effects
mc.main = struct();
mc.main.Group   = safe_multcompare(stats_all, 'Dimension', 1);
mc.main.Dreadds = safe_multcompare(stats_all, 'Dimension', 2);
mc.main.Task    = safe_multcompare(stats_all, 'Dimension', 3);

% (B) Two-way interactions averaged over the 3rd factor
mc.interact = struct();
mc.interact.GxD = safe_multcompare(stats_all, 'Dimension', [1 2]);
mc.interact.GxT = safe_multcompare(stats_all, 'Dimension', [1 3]);
mc.interact.DxT = safe_multcompare(stats_all, 'Dimension', [2 3]);

% -------- (C) Simple effects: condition on the 3rd factor --------
mc.simple = struct();

% common empty slot with fixed field order
slot = simple_slot();   % see helper below

% C1) Within each Task → Group×Dreadds (+ simple main effects)
tLevels = categories(longTbl.Task);
mc.simple.byTask = repmat(slot, numel(tLevels), 1);
for i = 1:numel(tLevels)
    sub = longTbl(longTbl.Task==tLevels{i}, :);
    tmp = simple_effects_two_way(sub, {'Group','Dreadds'}, ...
                                 'level', tLevels{i}, 'pair','GxD');
    mc.simple.byTask(i) = fill_simple_slot(slot, tmp);  % safe copy
end

% C2) Within each Dreadds → Group×Task (+ simple main effects)
dLevels = categories(longTbl.Dreadds);
mc.simple.byDreadds = repmat(slot, numel(dLevels), 1);
for i = 1:numel(dLevels)
    sub = longTbl(longTbl.Dreadds==dLevels{i}, :);
    tmp = simple_effects_two_way(sub, {'Group','Task'}, ...
                                 'level', dLevels{i}, 'pair','GxT');
    mc.simple.byDreadds(i) = fill_simple_slot(slot, tmp);
end

% C3) Within each Group → Dreadds×Task (+ simple main effects)
gLevels = categories(longTbl.Group);
mc.simple.byGroup = repmat(slot, numel(gLevels), 1);
for i = 1:numel(gLevels)
    sub = longTbl(longTbl.Group==gLevels{i}, :);
    tmp = simple_effects_two_way(sub, {'Dreadds','Task'}, ...
                                 'level', gLevels{i}, 'pair','DxT');
    mc.simple.byGroup(i) = fill_simple_slot(slot, tmp);
end

% -------- Package & print (with correct df) --------
out = struct();
out.long   = longTbl;
out.anovan = struct('p', p_all, 'tbl', tbl_all, 'stats', stats_all);
out.mc     = mc;

disp('=== 3-WAY ANOVA (Group × Dreadds × Task) ===');
local_print_anova_summary_noeta(tbl_all, nTask);

% Optional Excel export of ANOVA table
if saveToExcel
    try
        headers = string(tbl_all(1,:));
        body    = tbl_all(2:end,:);
        T_ano   = cell2table(body, 'VariableNames', matlab.lang.makeValidName(cellstr(headers)));
        writetable(T_ano, [fileName '.xlsx'], 'Sheet','anovan_table');
    catch
        warning('Could not write ANOVA table to Excel (non-fatal).');
    end
end
end

% ===== Helpers =====
function Xn = normalizeTask(X, normType)
switch normType
    case 2
        mu = mean(X(:,1),'omitnan'); sd = std(X(:,1),'omitnan'); sd = max(sd, eps);
        Xn = (X - mu) ./ sd;
    case 3
        mn = min(X(:)); mx = max(X(:)); rng = max(mx-mn, eps);
        Xn = (X - mn) ./ rng;
    otherwise
        Xn = X;
end
end

function v = toNumericCol(x)
if istable(x), x = x{:,:}; end
if iscell(x)
    try x = cellfun(@str2double, x); catch, x = string(x); end
end
if ischar(x),        x = string(x); end
if isstring(x),      x = str2double(x); end
if iscategorical(x), x = double(x); end
if islogical(x),     x = double(x); end
if ~isfloat(x),      x = double(x); end
v = x(:); if isempty(v), v = zeros(0,1); end
end

function MC = safe_multcompare(stats, varargin)
% Wrap multcompare to always return [] on failure, with Display off.
try
    MC = multcompare(stats, varargin{:}, 'Display','off');
catch
    MC = [];
end
end

function s = simple_effects_two_way(subTbl, facPair, varargin)
% Run a 2-way ANOVA on the sub-table and return post-hoc for:
%   - the interaction (multcompare on both dims)
%   - each main effect
p = inputParser;
addParameter(p,'level',''); addParameter(p,'pair','');
parse(p,varargin{:});

fa = facPair{1}; fb = facPair{2};
[Xa, Xb] = deal(subTbl.(fa), subTbl.(fb));

[~, ~, st] = anovan(subTbl.Y, {Xa, Xb}, ...
    'model','interaction', 'varnames', {fa, fb}, 'display','off');

s = struct('level', p.Results.level, ...
           'GxD',[], 'GxT',[], 'DxT',[], ...
           'Group',[], 'Dreadds',[], 'Task',[]);
% Interaction over the pair
s.(p.Results.pair) = safe_multcompare(st, 'Dimension', [1 2]);
% Simple main effects within this slice
if strcmp(fa,'Group')     || strcmp(fb,'Group'),     s.Group   = safe_multcompare(st, 'Dimension', strcmp(fa,'Group')+strcmp(fb,'Group')); end
if strcmp(fa,'Dreadds')   || strcmp(fb,'Dreadds'),   s.Dreadds = safe_multcompare(st, 'Dimension', strcmp(fa,'Dreadds')+strcmp(fb,'Dreadds')); end
if strcmp(fa,'Task')      || strcmp(fb,'Task'),      s.Task    = safe_multcompare(st, 'Dimension', strcmp(fa,'Task')+strcmp(fb,'Task')); end
end

function local_print_anova_summary_noeta(tbl, nTask)
% Prints ANOVAN table with correct dfs (no partial-eta^2 column).
% nTask = number of Task levels in your data.

headers = string(tbl(1,:));
body    = tbl(2:end,:);
srcCol  = 1;

% Try to locate columns; be liberal with header names.
idxDF = find(strcmpi(strtrim(headers),'df') | contains(lower(headers),'df'), 1);
idxF  = find(strcmpi(strtrim(headers),'F')  | contains(headers,' F'), 1);
idxP  = find(contains(lower(headers),'prob') & contains(lower(headers),'f'), 1);
if isempty(idxP), idxP = find(contains(lower(headers),'p'), 1); end

srcStr = string(body(:,srcCol));
isErr  = ismember(lower(srcStr), {'error','residual'});
isTot  = ismember(lower(srcStr), {'total'});

% Factor levels
nG = 2; nD = 3; nT = nTask;

fprintf('\nEffect                          df        F         p\n');
fprintf('------------------------------------------------------\n');
for i = 1:size(body,1)
    if isErr(i) || isTot(i), continue; end
    name = string(srcStr(i));

    % df from table if available
    df = NaN;
    if ~isempty(idxDF)
        val = body{i, idxDF};
        if isnumeric(val), df = val;
        elseif ischar(val) || isstring(val), df = str2double(string(val));
        end
    end

    % Fallback: compute df from factor-level counts
    if isnan(df)
        low = lower(strtrim(name));
        g = contains(low,'group'); d = contains(low,'dreadds'); t = contains(low,'task');
        if     g && d && t, df = (nG-1)*(nD-1)*(nT-1);
        elseif g && d,      df = (nG-1)*(nD-1);
        elseif g && t,      df = (nG-1)*(nT-1);
        elseif d && t,      df = (nD-1)*(nT-1);
        elseif g,           df = (nG-1);
        elseif d,           df = (nD-1);
        elseif t,           df = (nT-1);
        end
    end

    Fval = NaN; if ~isempty(idxF), Fval = body{i, idxF}; end
    if ischar(Fval) || isstring(Fval), Fval = str2double(string(Fval)); end
    pval = NaN; if ~isempty(idxP), pval = body{i, idxP}; end
    if ischar(pval) || isstring(pval), pval = str2double(string(pval)); end

    fprintf('%-28s %4.0f   %9.3f   %7.4f\n', name, df, Fval, pval);
end
fprintf('------------------------------------------------------\n\n');
end

function s = simple_slot()
% Fixed schema and field order for simple-effects entries
s = struct('level','', ...
           'GxD',[], 'GxT',[], 'DxT',[], ...
           'Group',[], 'Dreadds',[], 'Task',[]);
end

function out = fill_simple_slot(slot, src)
% Copy known fields from src into the fixed-slot struct 'slot'
out = slot;
f = fieldnames(slot);
for k = 1:numel(f)
    if isfield(src, f{k})
        out.(f{k}) = src.(f{k});
    end
end
end
