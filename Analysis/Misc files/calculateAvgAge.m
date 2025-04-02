% Author: Atanu Giri
% Date: 11/24/2024
%

datasource = 'live_database';
conn = database(datasource,'postgres','1234');

% BL age
[P2L1_BL, P2L1L3_BL] = extract_BLforCombAlcAndBoost_ids(conn);
P2L1_id_list = strjoin(arrayfun(@num2str, P2L1_BL, 'UniformOutput', false), ',');
P2L1L3_id_list = strjoin(arrayfun(@num2str, P2L1L3_BL, 'UniformOutput', false), ',');

query = sprintf("SELECT subjectid, MIN(birthdate) AS birthdate, " + ...
    "MIN(referencetime) AS referencetime " + ...
    "FROM live_table WHERE id IN (%s) GROUP BY subjectid", P2L1_id_list);
data = fetch(conn, query);
data.referencetime = datetime(data.referencetime, "Format", 'dd/MM/uuuu');

% Calculate age in months
age_in_months = calmonths(between(data.birthdate, data.referencetime, 'months'));
avg_age = mean(age_in_months);
std_err = std(age_in_months);

query = sprintf("SELECT subjectid, MIN(birthdate) AS birthdate, " + ...
    "MIN(referencetime) AS referencetime " + ...
    "FROM live_table WHERE id IN (%s) GROUP BY subjectid", P2L1L3_id_list);
data = fetch(conn, query);
data.referencetime = datetime(data.referencetime, "Format", 'dd/MM/uuuu');

% Calculate age in months
age_in_months = calmonths(between(data.birthdate, data.referencetime, 'months'));
avg_age = mean(age_in_months);
std_err = std(age_in_months);

% Acute alcohol age
[~, ~, boost_alcohol_P2A_id] = extract_combined_boost_alcohol_ids(conn);
id_list = strjoin(arrayfun(@num2str, boost_alcohol_P2A_id, 'UniformOutput', false), ',');

query = sprintf("SELECT subjectid, MIN(birthdate) AS birthdate, " + ...
    "MIN(referencetime) AS referencetime " + ...
    "FROM live_table WHERE id IN (%s) GROUP BY subjectid", id_list);

data = fetch(conn, query);
data.referencetime = datetime(data.referencetime, "Format", 'dd/MM/uuuu');

% Calculate age in months
age_in_months = calmonths(between(data.birthdate, data.referencetime, 'months'));
avg_age = mean(age_in_months);
std_err = std(age_in_months);