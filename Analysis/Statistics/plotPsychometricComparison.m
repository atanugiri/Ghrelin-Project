function [p_values, p_combined_ranksum, p_combined_ttest] = ...
    plotPsychometricComparison(T1, T2, groupLabels, featureName, plotType)
% plotPsychometricComparison - Compare and plot trial-level feature data between two groups
%
% Inputs:
%   T1, T2        - 1x4 cell arrays of trial-level feature values per concentration
%   groupLabels   - Cell array of 2 strings, e.g., {'Saline', 'Ghrelin'}
%   featureName   - String, e.g., 'approach_rate'
%   plotType      - 'box' or 'violin' (default: 'box')
%
% Outputs:
%   p_values              - 1x4 vector of p-values from Wilcoxon rank-sum test (per concentration)
%   p_combined_ranksum    - Single p-value comparing all trials (Wilcoxon rank-sum)
%   p_combined_ttest      - Single p-value comparing all trials (Welch's t-test)
%
% Author: Atanu Giri
% Date: 05/12/2025
% 
if nargin < 5
    plotType = 'box';
end

numConcs = 4;
values = [];
group = {};
concentration = [];
p_values = zeros(1, numConcs);

% For combined analysis
allVals1 = [];
allVals2 = [];

for c = 1:numConcs
    vals1 = T1{c};
    vals2 = T2{c};

    vals1 = vals1(isfinite(vals1));
    vals2 = vals2(isfinite(vals2));

    % Store for combined tests
    allVals1 = [allVals1; vals1(:)];
    allVals2 = [allVals2; vals2(:)];

    % Store p-value per concentration
    p_values(c) = ranksum(vals1, vals2);

    % Collect for plotting
    values = [values; vals1(:); vals2(:)];
    group = [group; repmat({groupLabels{1}}, numel(vals1), 1); ...
                    repmat({groupLabels{2}}, numel(vals2), 1)];
    concentration = [concentration; repmat(c, numel(vals1) + numel(vals2), 1)];
end

% Combined statistics
allVals1 = allVals1(isfinite(allVals1));
allVals2 = allVals2(isfinite(allVals2));
p_combined_ranksum = ranksum(allVals1, allVals2);
[~, p_combined_ttest] = ttest2(allVals1, allVals2);

% Plot
figure;
hold on;

if strcmpi(plotType, 'box')
    boxchart(categorical(concentration), values, 'GroupByColor', group);
elseif strcmpi(plotType, 'violin')
    violinplot(values, {concentration, group}, ...
               'GroupOrder', {1, 2, 3, 4}, 'ShowMean', true);
else
    error('Unknown plot type. Use ''box'' or ''violin''.');
end

xlabel('Concentration');
ylabel(featureName, 'Interpreter', 'none');
title(sprintf('%s by Group', featureName), 'Interpreter', 'none');
legend(groupLabels, 'Interpreter', 'none');
set(gca, 'FontSize', 14);
xticklabels({'0.5', '2', '5', '9'});

% Annotate p-values above each concentration
for c = 1:numConcs
    xpos = c;
    ypos = max(values(concentration == c)) * 1.05;
    text(xpos, ypos, sprintf('p = %.3g', p_values(c)), ...
         'HorizontalAlignment', 'center', 'FontSize', 10);
end

% Annotate combined p-values below the plot
annotation('textbox', [0.15, 0.01, 0.8, 0.05], 'String', ...
    sprintf('Combined p (rank-sum): %.3g, Combined p (t-test): %.3g', ...
    p_combined_ranksum, p_combined_ttest), ...
    'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'FontSize', 11);

end