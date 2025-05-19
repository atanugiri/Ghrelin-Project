% id = 4985;
% 
% 
% [accOutlierMoveMedian,jerkOutlierMoveMedian, h1, accOutlierTime] = ...
%     accelerationAndJerkOulierFun(id);
% set(gcf, 'Windowstyle', 'docked');
% h2 = trajectoryPlot(id, accOutlierTime);
% set(gcf, 'Windowstyle', 'docked');

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

figure;
ids = [96208, 96223, 96231, 96287, 96311, 96323, 96347, 96359, 96363, ...
    96367, 98154];
for id = ids
    trajectoryPlot(id, gcf);
end
hold on;
mazeMethods(2);

% Ghrelin
% ghr_id = treatmentIDfun('P2L1 Ghrelin', conn);
% ghr_id_str = strjoin(string(ghr_id), ',');
% ghr_id_q = sprintf( ...
% "SELECT g.id, g.distance_until_limiting_time_stamp, l.mazenumber " + ...
% "FROM ghrelin_featuretable g " + ...
% "INNER JOIN live_table l ON g.id = l.id " + ...
% "WHERE g.id IN (%s) " + ...
% "ORDER BY g.id", ...
% ghr_id_str);
% ghr_Data = fetch(conn, ghr_id_q);
% ghr_Data.distance_until_limiting_time_stamp = str2double(ghr_Data.distance_until_limiting_time_stamp);
% ghr_Data.mazenumber = string(ghr_Data.mazenumber);
% ghr_data_maze1 = ghr_Data(ghr_Data.mazenumber == 'maze 1', :);
% ghr_data_maze1 = ghr_data_maze1(ghr_data_maze1.distance_until_limiting_time_stamp > 0.75 & ...
%     ghr_data_maze1.distance_until_limiting_time_stamp < 2, :);
% 
% figure;
% ids = [94713, 95085, 95089, 95117, 99494, 99606, 99622, 99654, 100234, 100442];
% for id = ids
%     trajectoryPlot(id, gcf);
% end