function longTbl = buildLongTable1way(normType, saveToExcel, fileName, varargin)
% buildLongTable1way
% Pool k files; each file has 6 columns in this fixed order:
%   [Saline-WT, Ghrelin-WT, Saline-Inhib, Ghrelin-Inhib, Saline-Excit, Ghrelin-Excit]
% Returns a long table for 1-way ANOVA with variables:
%   Y, Condition (6 levels). No Task/File factor included.
%
% Inputs:
%   normType    : 1 = raw (default)
%                 2 = z-score vs column 1 (Saline-WT) within each file
%                 3 = min-max across all 6 columns within each file
%   saveToExcel : true/false (default false) → writes 'long_data' sheet
%   fileName    : base name for Excel (ignored if saveToExcel=false)
%   varargin    : one or more file paths; each file contributes 6 columns
%
% Output:
%   longTbl : table with variables Y (double), Condition (categorical)

if nargin < 1 || isempty(normType),    normType = 1; end
if nargin < 2 || isempty(saveToExcel), saveToExcel = false; end
if nargin < 3, fileName = ''; end
assert(nargin >= 4, 'Provide at least one file after (normType, saveToExcel, fileName).');

condLabels = {'Saline-WT','Ghrelin-WT', ...
              'Saline-Inhib','Ghrelin-Inhib', ...
              'Saline-Excit','Ghrelin-Excit'};

Y = []; C = {};   % values and 6-level condition labels

for fi = 1:numel(varargin)
    Ti  = readtable(varargin{fi}, 'VariableNamingRule','preserve');
    raw = Ti{:,:};
    if size(raw,2) < 6
        error('File %s has fewer than 6 columns.', varargin{fi});
    end

    % Take first 6 columns and coerce to numeric
    X = zeros(height(Ti), 6);
    for c = 1:6
        X(:,c) = toNumericCol(raw(:,c));
    end

    % Per-file normalization (if requested)
    Xn = normalizeTask(X, normType);

    % Append each column as a condition, dropping NaNs/Inf
    for c = 1:6
        y = Xn(:,c);
        y = y(isfinite(y));
        if isempty(y), continue; end
        Y = [Y; y]; %#ok<AGROW>
        C = [C; repmat(condLabels(c), numel(y), 1)]; %#ok<AGROW>
    end
end

Condition = categorical(C, condLabels);   % fixed, stable order
longTbl   = table(Y, Condition);

if saveToExcel
    if isempty(fileName), fileName = 'oneWay6_long'; end
    writetable(longTbl, [fileName '.xlsx'], 'Sheet','long_data');
end
end

% -------- Helpers (same behavior as your 3-way version) --------
function Xn = normalizeTask(X, normType)
switch normType
    case 2
        mu = mean(X(:,1), 'omitnan');
        sd = std(X(:,1), 'omitnan'); sd = max(sd, eps);
        Xn = (X - mu) ./ sd;
    case 3
        mn = min(X(:)); mx = max(X(:)); rng = max(mx - mn, eps);
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
