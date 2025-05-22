% Author: Atanu Giri
% Date: 02/11/2024
%
% Returns the id list of the input health group.
%
function id = treatmentIDfun(treatment, conn)

if nargin < 2
    datasource = 'live_database';
    conn = database(datasource,'postgres','1234');
end

% Print all health groups
fprintf("Health groups:\n");
fprintf("P2L1 Baseline, P2L1L3 Baseline, P2L1 Food deprivation, Initial task, Late task, \n" + ...
    "P2L1 Prefeeding, P2L1L3 Prefeeding, Oxy, Incubation, \n" + ...
    "P2L1 Saline, P2L1 Ghrelin, P2L1L3 Saline, P2L1L3 Ghrelin, \n" + ...
    "Sal toyrat, Ghr toyrat, Sal toystick, Ghr toystick, Sal skewer, Ghr skewer, \n" + ...
    "P2L1 Alcohol bl, P2L1L3 Alcohol bl, P2L1 Boost bl, P2L1L3 Boost bl\n" + ...
    "P2L1 Boost, P2L1L3 Boost, P2A Boost, \n" + ...
    "Alcohol bl, P2L1 Alcohol, P2L1L3 Alcohol, P2A Alcohol, \n" + ...
    "P2L1 BL for comb boost and alc, P2L1L3 BL for comb boost and alc, \n" + ...
    "P2L1 Sal alcohol, P2L1L3 Sal alcohol, P2A Sal alcohol, \n" + ...
    "P2L1 Sal alc and sal boost, P2L1L3 Sal alc and sal boost, P2A Sal alc and sal boost, \n" + ...
    "P2L1 Ghr alcohol, P2L1L3 Ghr alcohol, P2A Ghr alcohol, \n" + ...
    "P2L1 Ghr alc and ghr boost, P2L1L3 Ghr alc and ghr boost, P2A Ghr alc and ghr boost, \n" + ...
    "Sal repeat, Ghr repeat, \n" + ...
    "P2L1 Post alcohol, P2L1L3 Post alcohol, \n" + ...
    "P2L1 Alc injection, P2L1L3 Alc injection, \n" + ...
    "P2L1L3 Baseline L1, P2L1L3 Baseline L3, \n" + ...
    "P2L1L3 BL for comb boost and alc L1, P2L1L3 BL for comb boost and alc L3, \n" + ...
    "P2L1L3 Boost and alcohol L1, P2L1L3 Boost and alcohol L3, \n" + ...
    "P2L1L3 Post alcohol L1, P2L1L3 Post alcohol L3\n");

%% Output from extract_treatment_ids function
if strcmpi(treatment, "P2L1 Baseline")
    [id, ~, ~, ~, ~, ~, ~] = extract_treatment_ids(conn);
elseif strcmpi(treatment, "P2L1L3 Baseline")
    [~, id, ~, ~, ~, ~, ~] = extract_treatment_ids(conn);
elseif strcmpi(treatment, "P2L1 Food deprivation")
    [~, ~, id, ~, ~, ~, ~] = extract_treatment_ids(conn);
elseif strcmpi(treatment, "Initial task")
    [~, ~, ~, id, ~, ~, ~] = extract_treatment_ids(conn);
elseif strcmpi(treatment, "Late task")
    [~, ~, ~, ~, id, ~, ~] = extract_treatment_ids(conn);
elseif strcmpi(treatment, "P2L1 Prefeeding")
    [~, ~, ~, ~, ~, id, ~] = extract_treatment_ids(conn);    
elseif strcmpi(treatment, "P2L1L3 Prefeeding")
    [~, ~, ~, ~, ~, ~, id] = extract_treatment_ids(conn);

    %% Output from getOxyIncubIds function
elseif strcmpi(treatment, "Oxy")
    [id, ~] = getOxyIncubIds(conn);
elseif strcmpi(treatment, "Incubation")
    [~, id] = getOxyIncubIds(conn);

    %% Output from extract_sal_ghr_ids function
elseif strcmpi(treatment, "P2L1 Saline")
    [id, ~, ~, ~] = extract_sal_ghr_ids(conn);
elseif strcmpi(treatment, "P2L1 Ghrelin")
    [~, id, ~, ~] = extract_sal_ghr_ids(conn);
elseif strcmpi(treatment, "P2L1L3 Saline")
    [~, ~, id, ~] = extract_sal_ghr_ids(conn);
elseif strcmpi(treatment, "P2L1L3 Ghrelin")
    [~, ~, ~, id] = extract_sal_ghr_ids(conn);

    %% Output from extract_toy_expt_ids function
elseif strcmpi(treatment, "Sal toyrat")
    [id, ~, ~, ~, ~, ~] = extract_toy_expt_ids(conn);
elseif strcmpi(treatment, "Ghr toyrat")
    [~, id, ~, ~, ~, ~] = extract_toy_expt_ids(conn);
elseif strcmpi(treatment, "Sal toystick")
    [~, ~, id, ~, ~, ~] = extract_toy_expt_ids(conn);
elseif strcmpi(treatment, "Ghr toystick")
    [~, ~, ~, id, ~, ~] = extract_toy_expt_ids(conn);
elseif strcmpi(treatment, "Sal skewer")
    [~, ~, ~, ~, id, ~] = extract_toy_expt_ids(conn);
elseif strcmpi(treatment, "Ghr skewer")
    [~, ~, ~, ~, ~, id] = extract_toy_expt_ids(conn);

    %% Output from extract_BLforAlcAndBoost_ids function
elseif strcmpi(treatment, "P2L1 Alcohol bl")
    [id, ~, ~, ~] = extract_BLforAlcAndBoost_ids(conn);
elseif strcmpi(treatment, "P2L1L3 Alcohol bl")
    [~, id, ~, ~] = extract_BLforAlcAndBoost_ids(conn);
elseif strcmpi(treatment, "P2L1 Boost bl")
    [~, ~, id, ~] = extract_BLforAlcAndBoost_ids(conn);
elseif strcmpi(treatment, "P2L1L3 Boost bl")
    [~, ~, ~, id] = extract_BLforAlcAndBoost_ids(conn);

    %% Output from extract_boost_ids function
elseif strcmpi(treatment, "P2L1 Boost")
    [id, ~, ~] = extract_boost_ids(conn);
elseif strcmpi(treatment, "P2L1L3 Boost")
    [~, id, ~] = extract_boost_ids(conn);
elseif strcmpi(treatment, "P2A Boost")
    [~, ~, id] = extract_boost_ids(conn);

    %% Output from extract_alcohol_ids function
elseif strcmpi(treatment, "Alcohol bl")
    [id, ~, ~, ~] = extract_alcohol_ids(conn);
elseif strcmpi(treatment, "P2L1 Alcohol")
    [~, id, ~, ~] = extract_alcohol_ids(conn);
elseif strcmpi(treatment, "P2L1L3 Alcohol")
    [~, ~, id, ~] = extract_alcohol_ids(conn);
elseif strcmpi(treatment, "P2A Alcohol")
    [~, ~, ~, id] = extract_alcohol_ids(conn);

    %% Output from extract_BLforCombAlcAndBoost_ids function
elseif strcmpi(treatment, "P2L1 BL for comb boost and alc")
    [id, ~] = extract_BLforCombAlcAndBoost_ids(conn);
elseif strcmpi(treatment, "P2L1L3 BL for comb boost and alc")
    [~, id] = extract_BLforCombAlcAndBoost_ids(conn);

    %% Output from extract_sal_alcohol_ids function
elseif strcmpi(treatment, "P2L1 Sal alcohol")
    [id, ~, ~, ~, ~, ~] = extract_sal_alcohol_ids(conn);
elseif strcmpi(treatment, "P2L1L3 Sal alcohol")
    [~, id, ~, ~, ~, ~] = extract_sal_alcohol_ids(conn);
elseif strcmpi(treatment, "P2A Sal alcohol")
    [~, ~, id, ~, ~, ~] = extract_sal_alcohol_ids(conn);
elseif strcmpi(treatment, "P2L1 Sal alc and sal boost")
    [~, ~, ~, id, ~, ~] = extract_sal_alcohol_ids(conn);
elseif strcmpi(treatment, "P2L1L3 Sal alc and sal boost")
    [~, ~, ~, ~, id, ~] = extract_sal_alcohol_ids(conn);
elseif strcmpi(treatment, "P2A Sal alc and sal boost")
    [~, ~, ~, ~, ~, id] = extract_sal_alcohol_ids(conn);

    %% Output from extract_ghr_alcohol_ids function
elseif strcmpi(treatment, "P2L1 Ghr alcohol")
    [id, ~, ~, ~, ~, ~] = extract_ghr_alcohol_ids(conn);
elseif strcmpi(treatment, "P2L1L3 Ghr alcohol")
    [~, id, ~, ~, ~, ~] = extract_ghr_alcohol_ids(conn);
elseif strcmpi(treatment, "P2A Ghr alcohol")
    [~, ~, id, ~, ~, ~] = extract_ghr_alcohol_ids(conn);
elseif strcmpi(treatment, "P2L1 Ghr alc and ghr boost")
    [~, ~, ~, id, ~, ~] = extract_ghr_alcohol_ids(conn);
elseif strcmpi(treatment, "P2L1L3 Ghr alc and ghr boost")
    [~, ~, ~, ~, id, ~] = extract_ghr_alcohol_ids(conn);
elseif strcmpi(treatment, "P2A Ghr alc and ghr boost")
    [~, ~, ~, ~, ~, id] = extract_ghr_alcohol_ids(conn);

    %% Output from extract_new_sal_ghr_ids function
elseif strcmpi(treatment, "Sal repeat")
    [id, ~] = extract_new_sal_ghr_ids(conn);
elseif strcmpi(treatment, "Ghr repeat")
    [~, id] = extract_new_sal_ghr_ids(conn);

    %% Output from extract_post_alcohol_ids function
elseif strcmpi(treatment,"P2L1 Post alcohol")
    [id, ~] = extract_post_alcohol_ids(conn);
elseif strcmpi(treatment, "P2L1L3 Post alcohol")
    [~,id] = extract_post_alcohol_ids(conn);

    %% Output from extract_alc_injection_ids function
elseif strcmpi(treatment, "P2L1 Alc injection")
    [id, ~] = extract_alc_injection_ids(conn);
elseif strcmpi(treatment, "P2L1L3 Alc injection")
    [~, id] = extract_alc_injection_ids(conn);

    %% Output from extract_L1_VsL3_ids function
elseif strcmpi(treatment, "P2L1L3 Baseline L1")
    id = extract_L1_VsL3_ids(conn);
elseif strcmpi(treatment, "P2L1L3 Baseline L3")
    [~, id] = extract_L1_VsL3_ids(conn);
elseif strcmpi(treatment, "P2L1L3 BL for comb boost and alc L1")
    [~, ~, id] = extract_L1_VsL3_ids(conn);
elseif strcmpi(treatment, "P2L1L3 BL for comb boost and alc L3")
    [~, ~, ~, id] = extract_L1_VsL3_ids(conn);
elseif strcmpi(treatment, "P2L1L3 Boost and alcohol L1")
    [~, ~, ~, ~, id] = extract_L1_VsL3_ids(conn);
elseif strcmpi(treatment, "P2L1L3 Boost and alcohol L3")
    [~, ~, ~, ~, ~, id] = extract_L1_VsL3_ids(conn);
elseif strcmpi(treatment, "P2L1L3 Post alcohol L1")
    [~, ~, ~, ~, ~, ~, id] = extract_L1_VsL3_ids(conn);
elseif strcmpi(treatment, "P2L1L3 Post alcohol L3")
    [~, ~, ~, ~, ~, ~, ~, id] = extract_L1_VsL3_ids(conn);

else
    disp("Treatment group not found.\n")
end
end