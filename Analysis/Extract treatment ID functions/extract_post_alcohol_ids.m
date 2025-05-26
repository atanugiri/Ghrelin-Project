% Author: Atanu Giri
% Date: 06/18/2024
%
% Extracts ids for alcohol for different task types.
%
function [P2L1_post_alcohol_id, P2L1L3_post_alcohol_id] = extract_post_alcohol_ids(varargin)

if numel(varargin) < 1
    datasource = 'live_database';
    conn = database(datasource,'postgres','1234');
else
    conn =  varargin{1};
end

% Fetch alcohol animals
boost_L1_id = treatmentIDfun('P2L1 Boost');
alcohol_L1_id = treatmentIDfun('P2L1 Alcohol');
boost_alcohol_L1_id = [boost_L1_id; alcohol_L1_id];

boost_L1L3_id = treatmentIDfun('P2L1L3 Boost');
alcohol_L1L3_id = treatmentIDfun('P2L1L3 Alcohol');
boost_alcohol_L1L3_id = [boost_L1L3_id; alcohol_L1L3_id];

% P2L1 Alcohol animals
boost_alcohol_L1_data = dataSummary(boost_alcohol_L1_id);
boost_alcohol_L1_animals = unique(string(boost_alcohol_L1_data.subjectid));
boost_alcohol_L1_animals = strjoin(boost_alcohol_L1_animals, "','");

% P2L1L3 Alcohol animals
boost_alcohol_L1L3_data = dataSummary(boost_alcohol_L1L3_id);
boost_alcohol_L1L3_animals = unique(string(boost_alcohol_L1L3_data.subjectid));
boost_alcohol_L1L3_animals = strjoin(boost_alcohol_L1L3_animals, "','");

% P2L1 post alcohol
post_alcohol_L1_Q = sprintf("SELECT id, health, genotype, tasktypedone, referencetime, " + ...
    "subjectid, gender, notes FROM live_table WHERE subjectid IN ('%s') AND " + ...
    "REPLACE(tasktypedone, ' ', '') = 'P2L1' ORDER BY id", boost_alcohol_L1_animals);
post_alcohol_L1_data = fetch(conn, post_alcohol_L1_Q);
post_alcohol_L1_data.referencetime = datetime(post_alcohol_L1_data.referencetime, ...
    'Format', 'MM/dd/yyyy');
post_alcohol_L1_data = sortrows(post_alcohol_L1_data, 'referencetime');

start_date = datetime('12/01/2022', 'InputFormat', 'MM/dd/yyyy');
start_date = start_date + days(1);
post_alcohol_L1_data = post_alcohol_L1_data(post_alcohol_L1_data. ...
    referencetime >= start_date, :);
post_alcohol_L1_data = post_alcohol_L1_data(ismember(post_alcohol_L1_data.health, ...
{'sal', 'sal(2x)'}), :);
P2L1_post_alcohol_id = post_alcohol_L1_data.id;

% P2L1L3 post alcohol
post_alcohol_L1L3_Q = sprintf("SELECT id, health, genotype, tasktypedone, referencetime, " + ...
    "subjectid, gender, notes FROM live_table WHERE subjectid IN ('%s') AND " + ...
    "REPLACE(tasktypedone, ' ', '') = 'P2L1L3' ORDER BY id", boost_alcohol_L1L3_animals);
post_alcohol_L1L3_data = fetch(conn, post_alcohol_L1L3_Q);
post_alcohol_L1L3_data.referencetime = datetime(post_alcohol_L1L3_data.referencetime, ...
    'Format', 'MM/dd/yyyy');
post_alcohol_L1L3_data = sortrows(post_alcohol_L1L3_data, 'referencetime');

start_date = datetime('12/01/2022', 'InputFormat', 'MM/dd/yyyy');
start_date = start_date + days(1);
post_alcohol_L1L3_data = post_alcohol_L1L3_data(post_alcohol_L1L3_data. ...
    referencetime >= start_date, :);
post_alcohol_L1L3_data = post_alcohol_L1L3_data(ismember(post_alcohol_L1L3_data.health, ...
{'sal', 'sal(2x)'}), :);
P2L1L3_post_alcohol_id = post_alcohol_L1L3_data.id;

% Data summary
if numel(varargin) <= 1 % To supress output using 'noPrint'
    printTableSummary(post_alcohol_L1L3_data);
end


%% Description of dataSummary
    function data = dataSummary(idArray)
        id_list = strjoin(arrayfun(@num2str, idArray, 'UniformOutput', false), ',');

        query = sprintf("SELECT id, health, genotype, tasktypedone, referencetime, " + ...
            "subjectid, gender, notes FROM live_table WHERE id IN (%s) ORDER BY id", id_list);

        data = fetch(conn, query);
    end
end