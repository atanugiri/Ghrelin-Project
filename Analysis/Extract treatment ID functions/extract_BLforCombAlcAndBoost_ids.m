% Author: Atanu Giri
% Date: 05/03/2024
%
% Extracts ids for control/baseline to compare with combined alcohol and
% boost group for same animals in those groups.
%

function [P2L1_BLforCombAlcAndBoost_id, P2L1L3_BLforCombAlcAndBoost_id] = ...
    extract_BLforCombAlcAndBoost_ids(varargin)

if numel(varargin) < 1
    datasource = 'live_database';
    conn = database(datasource,'postgres','1234');
else
    conn =  varargin{1};
end

%% P2L1 combined boost and alcohol baseline
% Combined Boost Alcohol L1
[boost_L1_id, ~, ~] = extract_boost_ids(conn, 'noPrint');
[~, alcohol_L1_id, ~, ~] = extract_alcohol_ids(conn, 'noPrint');
boost_alcohol_L1_id = vertcat(boost_L1_id, alcohol_L1_id);
boost_alcohol_L1_data = dataSummary(boost_alcohol_L1_id);
boost_alcohol_L1_animals = unique(string(boost_alcohol_L1_data.subjectid));
boost_alcohol_L1_animals = strjoin(boost_alcohol_L1_animals, "','");

P2L1_BLforCombAlcAndBoost_Q = sprintf("SELECT id, health, genotype, tasktypedone, referencetime, " + ...
    "subjectid, gender, notes FROM live_table WHERE subjectid IN ('%s') AND " + ...
    "genotype = 'CRL: Long Evans' AND health = 'N/A' AND REPLACE(tasktypedone, ' ', '') " + ...
    "= 'P2L1' ORDER BY id", boost_alcohol_L1_animals);
P2L1_BLforCombAlcAndBoost_Data = fetch(conn, P2L1_BLforCombAlcAndBoost_Q);

% Remove learning period
P2L1_BLforCombAlcAndBoost_Data.referencetime = datetime(P2L1_BLforCombAlcAndBoost_Data.referencetime, ...
    'Format', 'MM/dd/yyyy');
start_date = datetime('11/24/2021', 'InputFormat', 'MM/dd/yyyy');
end_date = datetime('12/13/2021', 'InputFormat', 'MM/dd/yyyy');
end_date = end_date + days(1);
dateFilter = P2L1_BLforCombAlcAndBoost_Data.referencetime >= start_date & ...
    P2L1_BLforCombAlcAndBoost_Data.referencetime <= end_date;
P2L1_BLforCombAlcAndBoost_Data(dateFilter, :) = [];

% Match the range of date and number of sessions (Optional)
start_date = datetime('06/01/2022', 'InputFormat', 'MM/dd/yyyy');
end_date = datetime('06/23/2022', 'InputFormat', 'MM/dd/yyyy');
end_date = end_date + days(1);
dateFilter = P2L1_BLforCombAlcAndBoost_Data.referencetime >= start_date & ...
    P2L1_BLforCombAlcAndBoost_Data.referencetime <= end_date;
P2L1_BLforCombAlcAndBoost_Data = P2L1_BLforCombAlcAndBoost_Data(dateFilter, :);

P2L1_BLforCombAlcAndBoost_id = P2L1_BLforCombAlcAndBoost_Data.id;

% Data summary
if numel(varargin) <= 1 % To supress output using 'noPrint'
    printTableSummary(P2L1_BLforCombAlcAndBoost_Data);
end


%% P2L1L3 combined boost and alcohol baseline
% Combined Boost Alcohol L1L3
[~, boost_L1L3_id, ~] = extract_boost_ids(conn, 'noPrint');
[~, ~, alcohol_L1L3_id, ~] = extract_alcohol_ids(conn, 'noPrint');
boost_alcohol_L1L3_id = vertcat(boost_L1L3_id, alcohol_L1L3_id);
boost_alcohol_L1L3_data = dataSummary(boost_alcohol_L1L3_id);
boost_alcohol_L1L3_animals = unique(string(boost_alcohol_L1L3_data.subjectid));
boost_alcohol_L1L3_animals = strjoin(boost_alcohol_L1L3_animals, "','");

P2L1L3_BLforCombAlcAndBoost_Q = sprintf("SELECT id, health, genotype, tasktypedone, referencetime, " + ...
    "subjectid, gender, notes FROM live_table WHERE subjectid IN ('%s') AND " + ...
    "genotype = 'CRL: Long Evans' AND health = 'N/A' AND REPLACE(tasktypedone, ' ', '') " + ...
    "= 'P2L1L3' ORDER BY id", boost_alcohol_L1L3_animals);
P2L1L3_BLforCombAlcAndBoost_Data = fetch(conn, P2L1L3_BLforCombAlcAndBoost_Q);

dateFilter = P2L1L3_BLforCombAlcAndBoost_Data.referencetime >= start_date & ...
    P2L1L3_BLforCombAlcAndBoost_Data.referencetime <= end_date;
P2L1L3_BLforCombAlcAndBoost_Data = P2L1L3_BLforCombAlcAndBoost_Data(dateFilter, :);

P2L1L3_BLforCombAlcAndBoost_id = P2L1L3_BLforCombAlcAndBoost_Data.id;

% Data summary
if numel(varargin) <= 1 % To supress output using 'noPrint'
    printTableSummary(P2L1L3_BLforCombAlcAndBoost_Data);
end



%% Description of dataSummary
    function data = dataSummary(idArray)
        id_list = strjoin(arrayfun(@num2str, idArray, 'UniformOutput', false), ',');

        query = sprintf("SELECT id, health, genotype, tasktypedone, referencetime, " + ...
            "subjectid, gender, notes FROM live_table WHERE id IN (%s) ORDER BY id", id_list);

        data = fetch(conn, query);
    end
end