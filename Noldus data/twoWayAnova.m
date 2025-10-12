function [p, tbl, stats, pair] = twoWayAnova(normType, saveToExcel, fileName, varargin)
% twoWayAnova  (pooled 1-way ANOVA across files) + t-test + Wilcoxon RS
% Usage examples (same as before):
% [p, tbl, stats] = twoWayAnova(3, true, 'Black_animal_simple', ...
%     "Food Center Freq_K.csv","Light Alone Freq_K.csv","Toy Alone Freq_K.csv");
% [p, tbl, stats] = twoWayAnova(3, true, 'Black_animal_complex', ...
%     "Food Light ALL Animlas Freq_K.csv","Toy Light Freq (Border)_K.csv");
% [p, tbl, stats] = twoWayAnova(3, true, 'White_animal_simple', ...
%     "FA + Controls.csv","LA + Controls.csv","TA + Controls.csv");
%
% Returns:
%   p, tbl, stats  - anovan outputs (1-way on Treatment)
%   pair           - struct with pooled pairwise stats (ttest2 + ranksum)
%
% Behavior:
%   - Reads all files, normalizes each by `normType`, selects two columns
%     (defaults to first two; you can enter indices once when prompted),
%     pools them as Group A (e.g., Saline) and Group B (e.g., Ghrelin),
%     runs 1-way ANOVA on Treatment, and also reports t-test & Wilcoxon.
%
% Note:
%   With exactly two groups, 1-way ANOVA F is equivalent to t^2; we still
%   report all three (ANOVA, t-test, ranksum) since your PI asked for both.

pair = struct();  % optional 4th output

% ---------- Read first file to show columns ----------
T0 = readtable(varargin{1});
varNames = T0.Properties.VariableNames;

fprintf('\nColumns in first file:\n');
for i = 1:numel(varNames)
    fprintf('  %2d: %s\n', i, varNames{i});
end
def = '[1 2]';
idxStr = input(sprintf('Indices for the TWO groups to compare (default %s): ', def), 's');
if isempty(idxStr), idx = eval(def); else, idx = eval(idxStr); end
assert(numel(idx)==2, 'Please specify exactly two column indices (e.g., [1 2]).');
gA_idx = idx(1); gB_idx = idx(2);

% ---------- Accumulate data across files ----------
A = []; B = [];
for i = 1:numel(varargin)
    Ti = readtable(varargin{i});
    Xi = Ti{:, [gA_idx, gB_idx]};
    Xi = normalizeData(Xi, normType);      % apply your normalization
    A  = [A; Xi(:,1)]; %#ok<AGROW>
    B  = [B; Xi(:,2)]; %#ok<AGROW>
end

% ---------- Long format for ANOVA ----------
A = A(:); B = B(:);
mask = isfinite(A) & isfinite(B);  % keep finite entries
% (If columns have differing NaN patterns you might prefer independent masks;
% but for pooled comparison this “both finite” rule is simple & conservative.)

YA = A(mask); YB = B(mask);
Y  = [YA; YB];
Treatment = categorical([repmat("GroupA", numel(YA), 1); repmat("GroupB", numel(YB), 1)]);

% Optional save to Excel
if saveToExcel
    dataTable = table(Y, Treatment, 'VariableNames', {'Y','Treatment'});
    writetable(dataTable, [fileName, '.xlsx']);
    disp('Data saved to Excel.');
end

% ---------- 1-way ANOVA on Treatment ----------
[p, tbl, stats] = anovan(Y, {Treatment}, 'varnames', {'treatment'});

% ---------- Pairwise stats on pooled vectors ----------
% t-test (Welch, unequal variances)
[~, p_t, ~, S] = ttest2(YA, YB, 'Vartype','unequal');
t_val = S.tstat;
% Wilcoxon rank-sum (z + W); compute U and rank-biserial too
[p_rs, ~, srs] = ranksum(YA, YB, 'method','approximate');  % robust & fast
n1 = numel(YA); n2 = numel(YB);
W  = srs.ranksum;
U  = W - n1*(n1+1)/2;
rb = 1 - (2*U)/(n1*n2);        % rank-biserial
% Effect size (optional): Hedges' g
g = hedges_g(YA, YB);

pair = struct( ...
    'colA', varNames{gA_idx}, 'colB', varNames{gB_idx}, ...
    'n1', n1, 'n2', n2, ...
    'median1', median(YA,'omitnan'), 'median2', median(YB,'omitnan'), ...
    'ttest_t', t_val, 'ttest_p', p_t, 'hedges_g', g, ...
    'ranksum_z', srs.zval, 'ranksum_p', p_rs, 'W', W, 'U', U, 'rank_biserial', rb);

% ---------- Helpers ----------
function normData = normalizeData(tempData, normType)
    switch normType
        case 2  % Z-score using column 1 as reference
            refCol  = tempData(:,1);
            refMean = mean(refCol, 'omitnan');
            refStd  = std(refCol,  'omitnan');
            normData = (tempData - refMean) ./ refStd;
        case 3  % Min-max over the matrix
            refMin = min(tempData(:));
            refMax = max(tempData(:));
            normData = (tempData - refMin) ./ max(refMax - refMin, eps);
        otherwise
            normData = tempData;
    end
end

function g = hedges_g(a, b)
    a = a(:); b = b(:);
    a = a(isfinite(a)); b = b(isfinite(b));
    if numel(a)<2 || numel(b)<2, g = NaN; return; end
    na = numel(a); nb = numel(b);
    va = var(a,1);  vb = var(b,1);   % population var; pooled below w/ (n-1)
    sp2 = ((na-1)*va + (nb-1)*vb) / (na + nb - 2);
    if ~isfinite(sp2) || sp2<=0, g = NaN; return; end
    d = (mean(a) - mean(b)) / sqrt(sp2);
    J = 1 - (3 / (4*(na+nb) - 9));   % small-sample correction
    g = J * d;
end

end
