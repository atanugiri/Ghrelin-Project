%% Noldus data analysis
% 1-way ANOVA results
[p, tbl, stats] = twoWayAnova(3, true, 'Black_animal_simple', ...
    "Food Center Freq_K.csv", "Light Alone Freq_K.csv", "Toy Alone Freq_K.csv");
[p, tbl, stats] = twoWayAnova(3, true, 'Black_animal_complex', ...
    'Food Light ALL Animlas Freq_K.csv', "Toy Light Freq (Border)_K.csv", ...
    "EM LE (open-closed)+PIX_K.csv");
[p, tbl, stats] = twoWayAnova(3, true, 'White_animal_simple', ...
    'FA + Controls.csv', "LA + Controls.csv", "TA + Controls.csv");
[p, tbl, stats] = twoWayAnova(3, true, 'White_animal_complex', ...
    'FL + Controls.csv', 'TL + Controls.csv', 'EM (time in open - time in closed).csv');

%% Ghrelin_featuretable data analysis
% 05/19/2025
conn = database('live_database','postgres','1234');

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
[T1, T2] = masterPsychometricBarPlot('time_in_nest', [], '', 'trial', ...
    [], [], 'P2L1 Saline', 'P2L1 Ghrelin');
p = ranksum(T1, T2);
saveToExcel('time_in_nest', T1, T2, {'Saline', 'Ghrelin'});

% Time outside nest
[T1, T2] = masterPsychometricBarPlot('18 - time_in_nest', [], '', 'trial', ...
    [], [], 'P2L1 Saline', 'P2L1 Ghrelin');
p = ranksum(T1, T2);
saveToExcel('time_outside_nest', T1, T2, {'Saline', 'Ghrelin'});


% acceleration outlier
accelerationAndJerkOulierFun(96243, conn, true); % Saline
accelerationAndJerkOulierFun(94689, conn, true); % Ghrelin

[T1, T2] = masterPsychometricBarPlot('acc_outlier/distance', [], '', ...
    'trial', [], [], 'P2L1 Saline', 'P2L1 Ghrelin');
p = ranksum(T1, T2);
saveToExcel('number_of_high_acc', T1, T2, {'Saline', 'Ghrelin'});


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


% 05/23/2025
% Pre-feeding (PF)
conn = database('live_database','postgres','1234');
P2L1_PF_id = treatmentIDfun('P2L1 Prefeeding', conn);
P2L1L3_PF_id = treatmentIDfun('P2L1L3 Prefeeding', conn);
PF_id = [P2L1_PF_id; P2L1L3_PF_id];
PF_id_str = join(string(PF_id), ',');

PF_data_query = sprintf("SELECT g.id, g.norm_x, g.norm_y, l.mazenumber, " + ...
    "l.referencetime, l.xcoordinates2, l.ycoordinates2 FROM ghrelin_featuretable g JOIN " + ...
    "live_table l ON g.id = l.id WHERE g.id IN (%s)", PF_id_str);
PF_data = fetch(conn, PF_data_query);

PF_data.mazenumber = string(PF_data.mazenumber);
tokens = regexp(PF_data.mazenumber, '\d+', 'match');
PF_data.mazenumber = cellfun(@(x) str2double(x{1}), tokens);

%
empty_data_flag = cellfun(@(x) isempty(x), PF_data.norm_x);
empty_data = PF_data(empty_data_flag, :);

maze_data = cell(1,4);

for maze = 1:4
    maze_filter = empty_data.mazenumber == maze;
    maze_data{maze} = empty_data(maze_filter, :);
end
figure;
for maze = 1:4
    for i = 1:10 %height(maze_data{maze})
        id = maze_data{maze}.id(i);
        trajectoryScatterPlotRaw(id, gcf)
    end
end

% 05/28/2025
sal_id = treatmentIDfun('P2L1 Saline', conn);
sal_id_str = join(string(sal_id), ',');
sal_q = sprintf("SELECT g.id, g.is_across, l.approachavoid, l.mazenumber, " + ...
    "l.feeder FROM ghrelin_featuretable g INNER JOIN live_table l " + ...
    "ON g.id = l.id WHERE g.id IN (%s)", sal_id_str);
sal_data = fetch(conn, sal_q);
sal_data.approachavoid = str2double(string(sal_data.approachavoid));
sal_data.feeder = str2double(string(sal_data.feeder));
sal_isacross_data = sal_data(sal_data.is_across == 1, :);
sal_isacross_id = sal_isacross_data.id;

ghr_id = treatmentIDfun('P2L1 Ghrelin', conn);
ghr_id_str = join(string(ghr_id), ',');
ghr_q = sprintf("SELECT g.id, g.is_across, l.approachavoid, l.mazenumber, " + ...
    "l.feeder FROM ghrelin_featuretable g INNER JOIN live_table l " + ...
    "ON g.id = l.id WHERE g.id IN (%s)", ghr_id_str);
ghr_data = fetch(conn, ghr_q);
ghr_data.approachavoid = str2double(string(ghr_data.approachavoid));
ghr_data.feeder = str2double(string(ghr_data.feeder));
ghr_isacross_data = ghr_data(ghr_data.is_across == 1, :);
ghr_isacross_id = ghr_isacross_data.id;

[T1, T2] = masterPsychometricFunctionPlot('curvature', [], 'curvature', ...
    'trial', [], sal_isacross_id, ghr_isacross_id);
[T1, T2] = masterPsychometricBarPlot('curvature', [], '', 'trial', [], [-Inf 0.75], ...
sal_isacross_id, ghr_isacross_id);

sal_isacross_data.mazenumber = string(sal_isacross_data.mazenumber);
ghr_isacross_data.mazenumber = string(ghr_isacross_data.mazenumber);

sal_isacross_data_maze1 = sal_isacross_data(sal_isacross_data.mazenumber == "maze 1", :);
ghr_isacross_data_maze1 = ghr_isacross_data(ghr_isacross_data.mazenumber == "maze 1", :);

figure;
for i = 1:3
    trajectoryPlot(sal_isacross_data_maze1.id(i), gcf);
end



% Saline vs Ghrelin
sal_id = treatmentIDfun('P2L1 Saline', conn);
ghr_id = treatmentIDfun('P2L1 Ghrelin', conn);

sal_q = sprintf("SELECT id, curvature FROM ghrelin_featuretable WHERE " + ...
    "id in (%s)", strjoin(string(sal_id), ','));
sal_data = fetch(conn, sal_q);

clipThresh = prctile(sal_data.curvature, 99); % Compute clipping threshold
validIdx = sal_data.curvature < clipThresh; % Logical mask for clipped data
sal_id = sal_data.id(validIdx);

ghr_q = sprintf("SELECT id, curvature FROM ghrelin_featuretable WHERE " + ...
    "id in (%s)", strjoin(string(ghr_id), ','));
ghr_data = fetch(conn, ghr_q);

clipThresh = prctile(ghr_data.curvature, 99); % Compute clipping threshold
validIdx = ghr_data.curvature < clipThresh; % Logical mask for clipped data
ghr_id = ghr_data.id(validIdx);

[T1, T2] = masterPsychometricBarPlot('curvature', [], '', 'trial', [], ...
    [0.75 Inf], sal_id, ghr_id);


% Curvature analysis (06/10/25)
BL_curv_q = sprintf("SELECT curvature FROM ghrelin_featuretable WHERE id IN (%s)", strjoin(string(P2L1_BL_id), ','));
BL_curv_data = fetch(conn, BL_curv_q);
FD_curv_q = sprintf("SELECT curvature FROM ghrelin_featuretable WHERE id IN (%s)", strjoin(string(P2L1_FD_id), ','));
FD_curv_data = fetch(conn, FD_curv_q);
PF_curv_q = sprintf("SELECT curvature FROM ghrelin_featuretable WHERE id IN (%s)", strjoin(string(P2L1_PF_id), ','));
PF_curv_data = fetch(conn, PF_curv_q);
sal_curv_q = sprintf("SELECT curvature FROM ghrelin_featuretable WHERE id IN (%s)", strjoin(string(P2L1_sal_id), ','));
sal_curv_data = fetch(conn, sal_curv_q);
ghr_curv_q = sprintf("SELECT curvature FROM ghrelin_featuretable WHERE id IN (%s)", strjoin(string(P2L1_ghr_id), ','));
ghr_curv_data = fetch(conn, ghr_curv_q);

[fig, ax] = overlayHistograms(BL_curv_data.curvature, FD_curv_data.curvature, PF_curv_data.curvature);
legend(ax, {'BL', 'FD', 'PF'});