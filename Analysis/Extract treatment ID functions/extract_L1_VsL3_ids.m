% Author: Atanu Giri
% Date: 01/23/2025
%
% Extract L1 and L3 ids separately from L1L3 data

function [P2L1L3_Baseline_L1_id, P2L1L3_Baseline_L3_id, ...
    P2L1L3_BL_for_comb_boost_and_alc_L1_id, ...
    P2L1L3_BL_for_comb_boost_and_alc_L3_id, ...
    P2L1L3_Boost_and_alcohol_L1_id, P2L1L3_Boost_and_alcohol_L3_id, ...
    P2L1L3_Post_alcohol_L1_id, P2L1L3_Post_alcohol_L3_id] = ...
    extract_L1_VsL3_ids(conn)

if nargin < 1
    % Connect to database
    datasource = 'live_database';
    conn = database(datasource,'postgres','1234');
end

% P2L1L3 Baseline ids
[P2L1L3_Baseline_L1_id, P2L1L3_Baseline_L3_id] = extractIDs('P2L1L3 Baseline');

% P2L1L3_BL_for_comb_boost_and_alc ids
[P2L1L3_BL_for_comb_boost_and_alc_L1_id, P2L1L3_BL_for_comb_boost_and_alc_L3_id] ...
    = extractIDs('P2L1L3 BL for comb boost and alc');

% P2L1L3_Boost_and_alcohol ids
[P2L1L3_Boost_and_alcohol_L1_id, P2L1L3_Boost_and_alcohol_L3_id] ...
    = extractIDs({'P2L1L3 Boost', 'P2L1L3 Alcohol'});

% P2L1L3 Post alcohol
[P2L1L3_Post_alcohol_L1_id, P2L1L3_Post_alcohol_L3_id] = extractIDs('P2L1L3 Post alcohol');

%% Description of extractIDs
function [grp1ID, grp2ID] = extractIDs(treatmentGroups)
    % Initialize arrays
    allTreatmentIDs = [];

    % Support both string and cell array input
    if ischar(treatmentGroups) || isstring(treatmentGroups)
        treatmentGroups = {treatmentGroups};
    end

    % Collect all treatment IDs
    for i = 1:numel(treatmentGroups)
        ids = treatmentIDfun(treatmentGroups{i}, conn);
        allTreatmentIDs = [allTreatmentIDs; ids(:)];
    end

    % Convert to string for SQL query
    treatmentIDs_str = strjoin(arrayfun(@num2str, allTreatmentIDs, 'UniformOutput', false), ',');

    % Fetch data
    query = sprintf("SELECT id, lightlevel, intensityofcost1, " + ...
        "intensityofcost2, intensityofcost3 " + ...
        "FROM live_table WHERE id IN (%s) ORDER BY id", treatmentIDs_str);
    treatment_data = fetch(conn, query);

    % Cleanup
    treatment_data.lightlevel = str2double(string(treatment_data.lightlevel));
    colsToClean = {'intensityofcost1', 'intensityofcost2', 'intensityofcost3'};

    for i = 1:numel(colsToClean)
        col = colsToClean{i};
        treatment_data.(col) = str2double(regexprep(string(treatment_data.(col)), '[^\d.]', ''));
    end

    % Adjust lightlevel for special conditions
    filter = ismember(treatment_data.intensityofcost3, [320, 290, 218]) ...
        & treatment_data.lightlevel == 2;
    treatment_data.lightlevel(filter) = 3;

    % Separate groups
    grp1Data = treatment_data(treatment_data.lightlevel == 1, :);
    grp2Data = treatment_data(treatment_data.lightlevel == 3 & ...
        treatment_data.intensityofcost3 >= 320, :);

    grp1ID = grp1Data.id;
    grp2ID = grp2Data.id;
end
end