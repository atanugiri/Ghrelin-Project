% Author: Atanu Giri
% Date: 03/14/2024

[featureForEachMale, featureForEachFemale] = masterPsychometricFunctionPlot( ...
    'distance', 'y', 'P2L1 Saline', 'P2L1 Ghrelin');


controlMale = featureForEachMale{1};
treatmentMale = featureForEachMale{2};

controlFemale = featureForEachFemale{1};
treatmentFemale = featureForEachFemale{2};

% Combine data
responseData = vertcat(controlMale, treatmentMale, controlFemale, treatmentFemale);

% Create factor vectors for Gender, Group, and Concentration
gender = [repmat({'Male'}, size(controlMale, 1), size(controlMale, 2)); ...
    repmat({'Male'}, size(treatmentMale, 1), size(treatmentMale, 2)); ...
    repmat({'Female'}, size(controlFemale, 1), size(controlFemale, 2)); ...
    repmat({'Female'}, size(treatmentFemale, 1), size(treatmentFemale, 2))];

group = [repmat({'Control'}, size(controlMale, 1), size(controlMale, 2)); ...
    repmat({'Treatment'}, size(treatmentMale, 1), size(treatmentMale, 2)); ...
    repmat({'Control'}, size(controlFemale, 1), size(controlFemale, 2)); ...
    repmat({'Treatment'}, size(treatmentFemale, 1), size(treatmentFemale, 2))];

concentration = repelem(1:4, (size(controlMale, 1) + size(treatmentMale, 1) + ...
    size(controlFemale, 1) + size(treatmentFemale, 1)), 1);

% Perform 3-way ANOVA
[~, tbl, ~] = anovan(responseData(:), {gender(:), group(:), concentration(:)}, ...
    'varnames', {'gender', 'group', 'concentration'}, 'model', 'interaction', 'display','off');
anovaTable = cell2table(tbl);


