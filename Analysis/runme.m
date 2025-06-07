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

figure;
for i = 1:20
    trajectoryScatterPlot(sal_data_maze1.id(i), gcf);
end
mazeMethods(2);

figure;
for i = 1:20
    trajectoryScatterPlot(ghr_data_maze1.id(i), gcf);
end
mazeMethods(2);

%% acceleration outlier
accelerationAndJerkOulierFun(96243, conn, true); % Saline
accelerationAndJerkOulierFun(94689, conn, true); % Ghrelin


%% Trajectories
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

%% Cumulative time in feeders
% [T1, T2] = masterPsychometricBarPlot('timein_all_conc', [], ...
%     'timein_all_conc', 'trial', [], [], {'P2L1 Saline'}, {'P2L1 Ghrelin'});
% p = ranksum(T1, T2);

%% Curvature
% [T1, T2] = masterPsychometricBarPlot('curvature', [], 'curvature', ...
%     'trial', [], 0.75, {'P2L1 Saline'}, {'P2L1 Ghrelin'});
% p = ranksum(T1, T2);

%% Nest example
% figure;
% for i = 1:20
%     trajectoryScatterPlot(sal_data_maze1.id(i), gcf);
% end
% figure;
% for i = 1:20
%     trajectoryScatterPlot(ghr_data_maze1.id(i), gcf);
% end


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

% 05/29/2025
t0_5_sal = []; t0_5_ghr = [];
t2_sal = []; t2_ghr = [];
t5_sal = []; t5_ghr = [];
t9_sal = []; t9_ghr = [];

[T1, T2] = masterPsychometricFunctionPlot('timein_conc9', [], '', 'trial', [], ...
    'P2L1 Saline', 'P2L1 Ghrelin');

t0_5_sal = [t0_5_sal; mean(T1{1})];
t2_sal = [t2_sal; mean(T1{2})];
t5_sal = [t5_sal; mean(T1{3})];
t9_sal = [t9_sal; mean(T1{4})];

t0_5_ghr = [t0_5_ghr; mean(T2{1})];
t2_ghr = [t2_ghr; mean(T2{2})];
t5_ghr = [t5_ghr; mean(T2{3})];
t9_ghr = [t9_ghr; mean(T2{4})];

[T1, T2] = masterPsychometricFunctionPlot('timein_conc5', [], '', 'trial', [], ...
    'P2L1 Saline', 'P2L1 Ghrelin');

t0_5_sal = [t0_5_sal; mean(T1{1})];
t2_sal = [t2_sal; mean(T1{2})];
t5_sal = [t5_sal; mean(T1{3})];
t9_sal = [t9_sal; mean(T1{4})];

t0_5_ghr = [t0_5_ghr; mean(T2{1})];
t2_ghr = [t2_ghr; mean(T2{2})];
t5_ghr = [t5_ghr; mean(T2{3})];
t9_ghr = [t9_ghr; mean(T2{4})];

[T1, T2] = masterPsychometricFunctionPlot('timein_conc2', [], '', 'trial', [], ...
    'P2L1 Saline', 'P2L1 Ghrelin');

t0_5_sal = [t0_5_sal; mean(T1{1})];
t2_sal = [t2_sal; mean(T1{2})];
t5_sal = [t5_sal; mean(T1{3})];
t9_sal = [t9_sal; mean(T1{4})];

t0_5_ghr = [t0_5_ghr; mean(T2{1})];
t2_ghr = [t2_ghr; mean(T2{2})];
t5_ghr = [t5_ghr; mean(T2{3})];
t9_ghr = [t9_ghr; mean(T2{4})];

[T1, T2] = masterPsychometricFunctionPlot('timein_conc0_5', [], '', 'trial', [], ...
    'P2L1 Saline', 'P2L1 Ghrelin');

t0_5_sal = [t0_5_sal; mean(T1{1})];
t2_sal = [t2_sal; mean(T1{2})];
t5_sal = [t5_sal; mean(T1{3})];
t9_sal = [t9_sal; mean(T1{4})];

t0_5_ghr = [t0_5_ghr; mean(T2{1})];
t2_ghr = [t2_ghr; mean(T2{2})];
t5_ghr = [t5_ghr; mean(T2{3})];
t9_ghr = [t9_ghr; mean(T2{4})];

[T1, T2] = masterPsychometricFunctionPlot('time_in_center', [], '', 'trial', [], ...
    'P2L1 Saline', 'P2L1 Ghrelin');

t0_5_sal = [t0_5_sal; mean(T1{1})];
t2_sal = [t2_sal; mean(T1{2})];
t5_sal = [t5_sal; mean(T1{3})];
t9_sal = [t9_sal; mean(T1{4})];

t0_5_ghr = [t0_5_ghr; mean(T2{1})];
t2_ghr = [t2_ghr; mean(T2{2})];
t5_ghr = [t5_ghr; mean(T2{3})];
t9_ghr = [t9_ghr; mean(T2{4})];

% Data matrix: rows = offer concentrations, columns = time spent in zones
stackData = [t0_5_sal(:)';  % Offer at 0.5%
             t2_sal(:)';    % Offer at 2%
             t5_sal(:)';    % Offer at 5%
             t9_sal(:)'];   % Offer at 9%

% X-axis labels
offerLabels = {'0.5%', '2%', '5%', '9%'};

% Create the stacked bar plot
figure;
bar(stackData, 'stacked');
set(gca, 'XTickLabel', offerLabels, 'FontSize', 12);
xlabel('Offered Concentration');
ylabel('Time Spent (s)');
legend({'Feeder 9%', 'Feeder 5%', 'Feeder 2%', 'Feeder 0.5%', 'Center'}, ...
       'Location', 'northeastoutside');
title('Time Spent per Zone (Saline)', 'FontWeight', 'bold');

% 06/06/2025
% With log transform and wo clipping
[T1, T2, T3] = masterPsychometricBarPlot('curvature', [], '', 'trial', [], ...
    [0.75 Inf], 'P2L1 Baseline', 'P2L1 Food deprivation', 'P2L1 Prefeeding');

figure; hold on;

% Custom colors
baselineColor = [0.2, 0.6, 0.8];     % bluish
foodDeprColor = [0.9, 0.4, 0.4];     % reddish
prefeedingColor = [0.95, 0.7, 0.2];  % orange/yellowish

histogram(T1, 'Normalization', 'probability', ...
    'FaceAlpha', 0.5, 'DisplayName', 'Baseline', 'FaceColor', baselineColor);
histogram(T2, 'Normalization', 'probability', ...
    'FaceAlpha', 0.5, 'DisplayName', 'Food deprivation', 'FaceColor', foodDeprColor);
histogram(T3, 'Normalization', 'probability', ...
    'FaceAlpha', 0.5, 'DisplayName', 'Prefeeding', 'FaceColor', prefeedingColor);

legend;
xlabel('log_{10}(Curvature + 1)');
ylabel('Probability');
title('Histogram of Curvature (Log Transformed)');

% With log transform and with clipping
P2L1_BL_id = treatmentIDfun('P2L1 Baseline', conn);
P2L1_FD_id = treatmentIDfun('P2L1 Food deprivation', conn);
P2L1_PF_id = treatmentIDfun('P2L1 Prefeeding', conn);

P2L1_BL_q = sprintf("SELECT id, curvature FROM ghrelin_featuretable WHERE " + ...
    "id in (%s)", strjoin(string(P2L1_BL_id), ','));
P2L1_BL_data = fetch(conn, P2L1_BL_q);

clipThresh = prctile(P2L1_BL_data.curvature, 99); % Compute clipping threshold
validIdx = P2L1_BL_data.curvature < clipThresh; % Logical mask for clipped data
P2L1_BL_id = P2L1_BL_data.id(validIdx);


P2L1_FD_q = sprintf("SELECT id, curvature FROM ghrelin_featuretable WHERE " + ...
    "id in (%s)", strjoin(string(P2L1_FD_id), ','));
P2L1_FD_data = fetch(conn, P2L1_FD_q);

clipThresh = prctile(P2L1_FD_data.curvature, 99); % Compute clipping threshold
validIdx = P2L1_FD_data.curvature < clipThresh; % Logical mask for clipped data
P2L1_FD_id = P2L1_FD_data.id(validIdx);


P2L1_PF_q = sprintf("SELECT id, curvature FROM ghrelin_featuretable WHERE " + ...
    "id in (%s)", strjoin(string(P2L1_PF_id), ','));
P2L1_PF_data = fetch(conn, P2L1_PF_q);

clipThresh = prctile(P2L1_PF_data.curvature, 99); % Compute clipping threshold
validIdx = P2L1_PF_data.curvature < clipThresh; % Logical mask for clipped data
P2L1_PF_id = P2L1_PF_data.id(validIdx);

[T1, T2, T3] = masterPsychometricBarPlot('curvature', [], '', 'trial', [], ...
    [0.75 Inf], P2L1_BL_id, P2L1_FD_id, P2L1_PF_id);


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