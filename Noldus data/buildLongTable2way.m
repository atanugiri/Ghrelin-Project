function longTbl = buildLongTable2way(normType, saveToExcel, fileName, varargin)
% buildLongTable2way
% Returns a long-format table for 2-way ANOVA across tasks:
%   Variables: Y, Group={Saline,Ghrelin}, Task={file1,file2,...}
%
% Inputs:
%   normType    : 1=raw (default), 2=z-score vs col1 (Saline, per file), 3=min-max (per file)
%   saveToExcel : true/false (default false) → writes 'long_data_2way' sheet
%   fileName    : base name for Excel (ignored if saveToExcel=false)
%   varargin    : one or more CSV/XLSX files; each file has 2 columns:
%                 [Saline, Ghrelin]
%
% Notes:
%   • Each file is treated as a Task level (Task = file base name).
%   • Normalization (when requested) is performed per file, then data are pooled.
%
% Output:
%   longTbl : table with variables Y, Group, Task
%
% Example:
%   longTbl = buildLongTable2way(2, true, 'SimpleTasks_long', ...
%       "Food_Only.csv","Light_Only.xlsx","Toy_Only.csv");

if nargin < 1 || isempty(normType),    normType = 1; end
if nargin < 2 || isempty(saveToExcel), saveToExcel = false; end
if nargin < 3, fileName = ''; end
assert(nargin >= 4, 'Provide at least one file after (normType, saveToExcel, fileName).');

grpLabels = {'Saline','Ghrelin'};

Y = []; 
G = {}; 
T = {};

for fi = 1:numel(varargin)
    thisFile = varargin{fi};
    Ti  = readtable(thisFile, 'VariableNamingRule','preserve');
    raw = Ti{:,:};
    if size(raw,2) < 2
        error('File %s must have at least 2 columns: [Saline, Ghrelin].', string(thisFile));
    end

    % Coerce first 2 columns to numeric vector columns
    X = zeros(height(Ti), 2);
    for c = 1:2
        X(:,c) = toNumericCol(raw(:,c));
    end

    % --- Per-file normalization, then pool ---
    Xn = normalizeTask(X, normType);

    % Drop NaN/Inf row-wise per column, then append with factors
    for c = 1:2
        y = Xn(:,c);
        y = y(isfinite(y));
        if isempty(y), continue; end

        gLevel = c; % 1=Saline, 2=Ghrelin

        % Task label = file base name (without extension)
        [~, baseName, ~] = fileparts(string(thisFile));
        taskLabel = string(baseName);

        Y = [Y; y]; %#ok<AGROW>
        G = [G; repmat(grpLabels(gLevel), numel(y), 1)]; %#ok<AGROW>
        T = [T; repmat(taskLabel,          numel(y), 1)]; %#ok<AGROW>
    end
end

Group = categorical(G, grpLabels);           % fixed order
Task  = categorical(T, unique(T,'stable'));  % keep file order
longTbl = table(Y, Group, Task);

if saveToExcel
    if isempty(fileName), fileName = 'twoWayAnova_long'; end
    writetable(longTbl, [fileName '.xlsx'], 'Sheet','long_data_2way');
end
end

% ---- Helpers ----
function Xn = normalizeTask(X, normType)
% Per-file normalization using ONLY data from this file (columns 1–2)
switch normType
    case 2  % z-score vs Saline (col 1)
        mu = mean(X(:,1), 'omitnan');
        sd = std(X(:,1), 'omitnan');
        sd = max(sd, eps);
        Xn = (X - mu) ./ sd;
    case 3  % min-max using all values in this file (both groups)
        xF = X(isfinite(X));
        if isempty(xF)
            Xn = X; 
        else
            mn  = min(xF);
            mx  = max(xF);
            rng = max(mx - mn, eps);
            Xn  = (X - mn) ./ rng;
        end
    otherwise  % raw
        Xn = X;
end
end

function v = toNumericCol(x)
if istable(x), x = x{:,:}; end
if iscell(x)
    try
        x = cellfun(@str2double, x);
    catch
        x = string(x);
    end
end
if ischar(x),        x = string(x); end
if isstring(x),      x = str2double(x); end
if iscategorical(x), x = double(x); end
if islogical(x),     x = double(x); end
if ~isfloat(x),      x = double(x); end
v = x(:); if isempty(v), v = zeros(0,1); end
end
