% 05/19/2025
conn = database('live_database','postgres','1234');

% Saline
sal_id = treatmentIDfun('P2L1 Saline', conn);
sal_id_str = strjoin(string(sal_id), ',');
sal_id_q = sprintf( ...
"SELECT g.id, g.distance_until_limiting_time_stamp, l.mazenumber " + ...
"FROM ghrelin_featuretable g " + ...
"INNER JOIN live_table l ON g.id = l.id " + ...
"WHERE g.id IN (%s) " + ...
"ORDER BY g.id", ...
sal_id_str);
sal_Data = fetch(conn, sal_id_q);
sal_Data.distance_until_limiting_time_stamp = str2double(sal_Data.distance_until_limiting_time_stamp);
sal_Data.mazenumber = string(sal_Data.mazenumber);
sal_data_maze1 = sal_Data(sal_Data.mazenumber == 'maze 1', :);
sal_data_maze1 = sal_data_maze1(sal_data_maze1.distance_until_limiting_time_stamp > 0.75 & ...
    sal_data_maze1.distance_until_limiting_time_stamp < 3, :);

% Ghrelin
ghr_id = treatmentIDfun('P2L1 Ghrelin', conn);
ghr_id_str = strjoin(string(ghr_id), ',');
ghr_id_q = sprintf( ...
"SELECT g.id, g.distance_until_limiting_time_stamp, l.mazenumber " + ...
"FROM ghrelin_featuretable g " + ...
"INNER JOIN live_table l ON g.id = l.id " + ...
"WHERE g.id IN (%s) " + ...
"ORDER BY g.id", ...
ghr_id_str);
ghr_Data = fetch(conn, ghr_id_q);
ghr_Data.distance_until_limiting_time_stamp = str2double(ghr_Data.distance_until_limiting_time_stamp);
ghr_Data.mazenumber = string(ghr_Data.mazenumber);
ghr_data_maze1 = ghr_Data(ghr_Data.mazenumber == 'maze 1', :);
ghr_data_maze1 = ghr_data_maze1(ghr_data_maze1.distance_until_limiting_time_stamp > 0.75 & ...
    ghr_data_maze1.distance_until_limiting_time_stamp < 2, :);

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
[T1, T2] = masterPsychometricBarPlot('timein_all_conc', [], ...
    'timein_all_conc', 'trial', [], [], {'P2L1 Saline'}, {'P2L1 Ghrelin'});
p = ranksum(T1, T2);

%% Curvature
[T1, T2] = masterPsychometricBarPlot('curvature', [], 'curvature', ...
    'trial', [], 0.75, {'P2L1 Saline'}, {'P2L1 Ghrelin'});

%% Nest example
