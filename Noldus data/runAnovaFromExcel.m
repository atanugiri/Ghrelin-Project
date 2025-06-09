function [anovaTbl, posthocTbl] = runAnovaFromExcel(filePath, sheet)
% runAnovaFromExcel - Perform one-way ANOVA and Tukey post-hoc from Excel
% Writes results to '<inputname>_anova_results.xlsx'
%
% INPUT:
%   filePath - full path to Excel file
%   sheet    - optional: specify sheet name or number
%
% OUTPUT:
%   anovaTbl    - ANOVA results as a table
%   posthocTbl  - Post-hoc test results as a table

    if nargin < 2
        sheet = 1;
    end

    % Read data
    T = readtable(filePath, 'Sheet', sheet);

    % Prepare long format
    allData = [];
    groupLabels = {};
    colNames = T.Properties.VariableNames;

    for i = 1:numel(colNames)
        colData = T{:, i};
        colData = colData(~isnan(colData));  % Remove NaNs
        allData = [allData; colData];
        groupLabels = [groupLabels; repmat(colNames(i), numel(colData), 1)];
    end

    % ANOVA
    [p, tbl, stats] = anova1(allData, groupLabels, 'off');
    anovaTbl = cell2table(tbl(2:end,:), 'VariableNames', tbl(1,:));

    % Post-hoc if significant
    posthocTbl = [];
    if p < 0.05
        result = multcompare(stats, 'Display', 'off');
        posthocTbl = array2table(result, ...
            'VariableNames', {'Group1', 'Group2', 'LowerCI', 'MeanDiff', 'UpperCI', 'pValue'});
        groupNames = stats.gnames;
        posthocTbl.Group1 = groupNames(posthocTbl.Group1);
        posthocTbl.Group2 = groupNames(posthocTbl.Group2);
    end

    % Save to Excel
    [folder, name, ~] = fileparts(filePath);
    outputFile = fullfile(folder, sprintf('%s_anova_results.xlsx', name));
    writetable(anovaTbl, outputFile, 'Sheet', 'ANOVA');

    if ~isempty(posthocTbl)
        writetable(posthocTbl, outputFile, 'Sheet', 'Posthoc');
    end

    fprintf('Results saved to: %s\n', outputFile);
end
