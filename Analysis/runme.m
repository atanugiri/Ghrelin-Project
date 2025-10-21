%% Noldus data analysis
% 1-way ANOVA results
[p, tbl, stats] = twoWayAnova(3, true, 'Black_animal_simple', ...
    "Food Center Freq_K.csv", "Light Alone Freq_K.csv", "Toy Alone Freq_K.csv");
[p, tbl, stats] = twoWayAnova(3, true, 'Black_animal_complex', ...
    'Food Light ALL Animlas Freq_K.csv', "Toy Light Freq (Border)_K.csv");
[p, tbl, stats] = twoWayAnova(3, true, 'White_animal_simple', ...
    'FA + Controls.csv', "LA + Controls.csv", "TA + Controls.csv");
[p, tbl, stats] = twoWayAnova(3, true, 'White_animal_complex', ...
    'FL + Controls.csv', 'TL + Controls.csv');

%% Ghrelin_featuretable data analysis
% 05/19/2025
conn = database('live_database','postgres','1234');

[T1, T2] = masterPsychometricBarPlot('approachavoid', [], 'approachavoid', 'trial', ...
    [], [], 'P2L1 Saline', 'P2L1 Ghrelin');
[~, p, ~, stat] = ttest2(T1, T2);

% Saline
sal_id = treatmentIDfun('P2L1 Saline', conn);
sal_id_str = strjoin(string(sal_id), ',');
sal_id_q = sprintf( ...
    "SELECT g.id, g.distance, l.mazenumber " + ...
    "FROM ghrelin_featuretable g " + ...
    "INNER JOIN live_table l ON g.id = l.id " + ...
    "WHERE g.id IN (%s) " + ...
    "ORDER BY g.id", ...
    sal_id_str);
sal_Data = fetch(conn, sal_id_q);
sal_Data.mazenumber = string(sal_Data.mazenumber);
sal_data_maze1 = sal_Data(sal_Data.mazenumber == 'maze 1', :);
sal_data_maze1 = sal_data_maze1(sal_data_maze1.distance > 0.75 & ...
    sal_data_maze1.distance < 3, :);

% Ghrelin
ghr_id = treatmentIDfun('P2L1 Ghrelin', conn);
ghr_id_str = strjoin(string(ghr_id), ',');
ghr_id_q = sprintf( ...
    "SELECT g.id, g.distance, l.mazenumber " + ...
    "FROM ghrelin_featuretable g " + ...
    "INNER JOIN live_table l ON g.id = l.id " + ...
    "WHERE g.id IN (%s) " + ...
    "ORDER BY g.id", ...
    ghr_id_str);
ghr_Data = fetch(conn, ghr_id_q);
ghr_Data.mazenumber = string(ghr_Data.mazenumber);
ghr_data_maze1 = ghr_Data(ghr_Data.mazenumber == 'maze 1', :);
ghr_data_maze1 = ghr_data_maze1(ghr_data_maze1.distance > 0.75 & ...
    ghr_data_maze1.distance < 2, :);


% Saline scatterplot
figure;
for i = 1:20
    trajectoryScatterPlot(sal_data_maze1.id(i), gcf);
end
mazeMethods(2);

% Ghrelin scatterplot
figure;
for i = 1:20
    trajectoryScatterPlot(ghr_data_maze1.id(i), gcf);
end
mazeMethods(2);

% Time inside nest
[T1, T2] = masterPsychometricBarPlot('time_in_nest', [], 'time_in_nest', 'trial', ...
    [], [], 'P2L1 Saline', 'P2L1 Ghrelin');
[~, p, ~, stat] = ttest2(T1, T2);
saveToExcel('time_in_nest', T1, T2, {'Saline', 'Ghrelin'});

% vals = [T1(:); T2(:)];
% groups = [repmat({'Saline'}, numel(T1), 1); 
%           repmat({'Ghrelin'},  numel(T2), 1)];

figure;
x1 = ones(size(T1));   % group position 1
x2 = 2*ones(size(T2)); % group position 2

hold on
b1 = boxchart(x1, T1, 'BoxFaceColor', [0 0.4470 0.7410]); % blue
b2 = boxchart(x2, T2, 'BoxFaceColor', [0.8500 0.3250 0.0980]); % orange
hold off

% Time outside nest
[T1, T2] = masterPsychometricBarPlot('18.1 - time_in_nest', [], '', 'trial', ...
    [], [], 'P2L1 Saline', 'P2L1 Ghrelin');
[~, p, ~, stat] = ttest2(T1, T2);
saveToExcel('time_outside_nest', T1, T2, {'Saline', 'Ghrelin'});

vals = [T1(:); T2(:)];
groups = [repmat({'Saline'}, numel(T1), 1); 
          repmat({'Ghrelin'},  numel(T2), 1)];

figure;
x1 = ones(size(T1));   % group position 1
x2 = 2*ones(size(T2)); % group position 2

hold on
b1 = boxchart(x1, T1, 'BoxFaceColor', [0 0.4470 0.7410]); % blue
b2 = boxchart(x2, T2, 'BoxFaceColor', [0.8500 0.3250 0.0980]); % orange
hold off

% Trajectories
% Ghrelin
ids = [95085, 95117, 99606, 99622, 99654, 100234];
figure;
for id = ids
    trajectoryPlot(id, gcf);
end
mazeMethods(2);

% Saline
ids = [96208, 96231, 96287, 96311, 96323, 96347];
figure;
for id = ids
    trajectoryPlot(id, gcf);
end
mazeMethods(2);

% Curvature
[T1, T2] = masterPsychometricBarPlot('curvature', [], 'curvature', 'trial', ...
    [], [0.75 Inf], 'P2L1 Saline', 'P2L1 Ghrelin');
[~, p, ~, stat] = ttest2(T1, T2);
saveToExcel('RECORD_curvature', T1, T2, {'Saline', 'Ghrelin'});

% vals = [T1(:); T2(:)];
% groups = [repmat({'Saline'}, numel(T1), 1); 
%           repmat({'Ghrelin'},  numel(T2), 1)];

% Velocity
[T1, T2] = masterPsychometricBarPlot('velocity', [], 'velocity', 'trial', ...
    [], [], 'P2L1 Saline', 'P2L1 Ghrelin');
[~, p, ~, stat] = ttest2(T1, T2);
saveToExcel('RECORD_velocity', T1, T2, {'Saline', 'Ghrelin'});

% vals = [T1(:); T2(:)];
% groups = [repmat({'Saline'}, numel(T1), 1); 
%           repmat({'Ghrelin'},  numel(T2), 1)];

figure;
x1 = ones(size(T1));   % group position 1
x2 = 2*ones(size(T2)); % group position 2

hold on
boxchart(x1, T1, 'BoxFaceColor', [0 0.4470 0.7410]); % blue
boxchart(x2, T2, 'BoxFaceColor', [0.8500 0.3250 0.0980]); % orange
hold off


% Curvature
sal_curv = []; sal_dist = [];
for id = 1:length(P2L1_sal_id)
    [curvature, distance] = computeTrajectoryCurvature(P2L1_sal_id(id), conn, ...
        20, true, 5);
    sal_curv = [sal_curv; curvature];
    sal_dist = [sal_dist; distance];
end

ghr_curv = []; ghr_dist = [];
for id = 1:length(P2L1_ghr_id)
    [curvature, distance] = computeTrajectoryCurvature(P2L1_ghr_id(id), conn, ...
        20, true, 5);
    ghr_curv = [ghr_curv; curvature];
    ghr_dist = [ghr_dist; distance];
end

fprintf("sal_curv_mean = %s\n", mean(sal_curv, 'omitmissing'));
fprintf("ghr_curv_mean = %s\n", mean(ghr_curv, 'omitmissing'));

sal_curv_filt_d_0_75 = sal_curv(sal_dist >= 0.75);
ghr_curv_filt_d_0_75 = ghr_curv(sal_dist >= 0.75);

fprintf("sal_curv_filt_mean = %s\n", mean(sal_curv_filt_d_0_75, 'omitmissing'));
fprintf("ghr_curv_filt_mean = %s\n", mean(ghr_curv_filt_d_0_75, 'omitmissing'));

sal_curv_mean = mean(sal_curv_filt_d_0_75, 'omitmissing');
ghr_curv_mean = mean(ghr_curv_filt_d_0_75, 'omitmissing');

sal_curv_se = std(sal_curv_filt_d_0_75)/sqrt(length(sal_curv_filt_d_0_75));
ghr_curv_se = std(ghr_curv_filt_d_0_75)/sqrt(length(ghr_curv_filt_d_0_75));

% Data
hold on;
bar(1, sal_curv_mean, 'FaceColor', [0.2 0.2 0.8]);  % first bar
bar(2, ghr_curv_mean, 'FaceColor', [0.8 0.2 0.2]);  % second bar

errorbar([1, 2], [sal_curv_mean, ghr_curv_mean], ...
         [sal_curv_se, ghr_curv_se], 'k.', 'LineWidth', 1.5);

xlim([0 3]);
hold off;

T = table(sal_curv_filt_d_0_75, ghr_curv_filt_d_0_75, ...
          'VariableNames', {'Saline','Ghrelin'});

% Write to Excel
writetable(T, 'curvature_data.xlsx');

% 3-way ANOVA for 2xOPRM1 Rats [10/17/2025]
longTbl = buildLongTable3way(3, true, 'White2xComplexTask3WayANOVA', ...
    'Data/2xOPRM1/FL_Controls.csv', 'Data/2xOPRM1/TL_Controls.csv');
[p_all, tbl_all, stats_all] = anovan(longTbl.Y, ...
{longTbl.Group, longTbl.Dreadds, longTbl.Task}, ...
'model','full', 'varnames', {'Group','Dreadds','Task'}, 'display','on');
M_GxD = multcompare(stats_all, 'Dimension', [1 2], 'Display','off');
M_DxT = multcompare(stats_all, 'Dimension', [2 3], 'Display','off');

% 1-way ANOVA for 2xOPRM1 Rats [10/17/2025]
longTbl = buildLongTable1way(3, false, '', 'Data/2xOPRM1/FA_Controls.csv', ...
    'Data/2xOPRM1/LA_Controls.csv', 'Data/2xOPRM1/TA_Controls.csv'); % simple task
longTbl = buildLongTable1way(3, false, '', 'Data/2xOPRM1/FL_Controls.csv', ...
    'Data/2xOPRM1/TL_Controls.csv'); % complex task

[p, tbl, stats] = anova1(longTbl.Y, longTbl.Condition, 'off');
mc = multcompare(stats, 'Display','on');    % Tukey post-hoc

% Plot 1-way ANOVA
conds = categories(longTbl.Condition);
nCond = numel(conds);

means = zeros(1, nCond);
sems  = zeros(1, nCond);
figure; hold on;

for i = 1:nCond
    y = longTbl.Y(longTbl.Condition == conds{i});
    means(i) = mean(y, 'omitnan');
    sems(i)  = std(y, 'omitnan') / sqrt(numel(y));
    bar(i, means(i));
    errorbar(i, means(i), sems(i), 'k.', 'LineWidth', 1);
    jitterX = i + 0.1 * (rand(size(y)) - 0.5);
    scatter(jitterX, y, 20, 'k', 'filled');
end

hold off;





