function longTbl = buildLongTableCombined3way(normType, saveToExcel, fileName, varargin)
% buildLongTable3way
% Returns a long-format table for 3-way ANOVA:
%   Y, Group={Saline,Ghrelin}, Dreadds={WT,Inhibitory,Excitatory}, Task
%
% Inputs:
%   normType    : 1=raw (default), 2=z-score vs col1, 3=min-max (per task)
%   saveToExcel : true/false (default false) → writes 'long_data' sheet
%   fileName    : base name for Excel (ignored if saveToExcel=false)
%   varargin    : one or more CSV/XLSX files; each file = one Task
%
% Each file must have ≥6 columns in this order:
%   [Saline-WT, Ghrelin-WT, Saline-Inhib, Ghrelin-Inhib, Saline-Excit, Ghrelin-Excit]

if nargin < 1 || isempty(normType),    normType = 1; end
if nargin < 2 || isempty(saveToExcel), saveToExcel = false; end
if nargin < 3, fileName = ''; end
assert(nargin >= 4, 'Provide at least one file after (normType, saveToExcel, fileName).');

grpLabels = {'Saline','Ghrelin'};                % (Ghrelin = your 2× IBU)
dreLabels = {'WT','Inhibitory','Excitatory'};
col2fact  = [1 1; 2 1; 1 2; 2 2; 1 3; 2 3];       % [Group Dreadds] per column

% --- Step 1: Read all files and collect their data ---
allData = cell(6, 1);  % 6 columns: Saline-WT, Ghrelin-WT, Saline-Inhib, Ghrelin-Inhib, Saline-Excit, Ghrelin-Excit
for c = 1:6
    allData{c} = {};
end
taskLabels = {};

for fi = 1:numel(varargin)
    Ti  = readtable(varargin{fi}, 'VariableNamingRule','preserve');
    raw = Ti{:,:};
    if size(raw,2) < 6
        error('File %s has fewer than 6 columns.', varargin{fi});
    end
    X = zeros(height(Ti), 6);
    for c = 1:6, X(:,c) = toNumericCol(raw(:,c)); end
    
    % Store each column's data
    for c = 1:6
        allData{c}{fi} = X(:,c);
    end
    
    % Task label = file base name
    [~, baseName, ~] = fileparts(string(varargin{fi}));
    taskLabels{fi} = string(baseName);
end

% --- Step 2: Combine columns horizontally (mean across files) ---
% All files must have same number of rows
numRows = numel(allData{1}{1});
for c = 1:6
    for fi = 2:numel(allData{c})
        if numel(allData{c}{fi}) ~= numRows
            error('All input files must have the same number of rows for column-wise combining.');
        end
    end
end

% Combine: mean across files for each data point
combinedData = zeros(numRows, 6);
for row = 1:numRows
    for c = 1:6
        vals = zeros(1, numel(varargin));
        for fi = 1:numel(varargin)
            vals(fi) = allData{c}{fi}(row);
        end
        % Mean across files (ignoring NaN)
        combinedData(row, c) = mean(vals, 'omitnan');
    end
end

% --- Step 3: Normalize the combined data ---
Xn = normalizeTask(combinedData, normType);

% --- Step 4: Build long table ---
Y = []; G = {}; D = {}; T = {};
for c = 1:6
    y = Xn(:,c);
    y = y(isfinite(y));           % drop NaNs/Inf
    if isempty(y), continue; end
    gLevel = col2fact(c,1);
    dLevel = col2fact(c,2);
    
    % Use combined label for task
    taskLabel = strjoin(string(taskLabels), '+');
    
    Y = [Y; y]; %#ok<AGROW>
    G = [G; repmat(grpLabels(gLevel), numel(y), 1)]; %#ok<AGROW>
    D = [D; repmat(dreLabels(dLevel), numel(y), 1)]; %#ok<AGROW>
    T = [T; repmat({char(taskLabel)}, numel(y), 1)]; %#ok<AGROW>
end

Group   = categorical(G, grpLabels);                    % fixed order
Dreadds = categorical(D, dreLabels);                    % fixed order
Task    = categorical(T, unique(T,'stable'), 'Ordinal', true);  % Task1..k in file order
longTbl = table(Y, Group, Dreadds, Task);

if saveToExcel
    if isempty(fileName), fileName = 'threeWayAnova_long'; end
    writetable(longTbl, [fileName '.xlsx'], 'Sheet','long_data');
end
end

% ---- Helpers ----
function Xn = normalizeTask(X, normType)
switch normType
    case 2
        mu = mean(X(:,1), 'omitnan');
        sd = std(X(:,1), 'omitnan');
        sd = max(sd, eps);
        Xn = (X - mu) ./ sd;
    case 3
        mn = min(X(:));
        mx = max(X(:));
        rng = max(mx - mn, eps);
        Xn = (X - mn) ./ rng;
    otherwise
        Xn = X;
end
end

function v = toNumericCol(x)
if istable(x), x = x{:,:}; end
if iscell(x)
    try x = cellfun(@str2double, x);
    catch, x = string(x);
    end
end
if ischar(x),        x = string(x); end
if isstring(x),      x = str2double(x); end
if iscategorical(x), x = double(x); end
if islogical(x),     x = double(x); end
if ~isfloat(x),      x = double(x); end
v = x(:); if isempty(v), v = zeros(0,1); end
end
