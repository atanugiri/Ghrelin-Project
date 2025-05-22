% Author: Atanu Giri
% Date: 01/02/2024

function [BL_P2L1_id, BL_P2L1L3_id, FD_P2L1_id, initial_task_id, late_task_id, ...
    PF_P2L1_id, PF_P2L1L3_id] ...
= extract_treatment_ids(varargin)
% This function extracts Baseline, Food deprivation, Initial task, and Late
% task Pre-feeding ids

if numel(varargin) < 1
    datasource = 'live_database';
    conn = database(datasource,'postgres','1234');
else
   conn =  varargin{1};
end

dateQuery = "SELECT id, genotype, referencetime, health, tasktypedone, " + ...
    "subjectid FROM live_table ORDER BY id";
allData = fetch(conn, dateQuery);
allData.genotype = string(allData.genotype);
allData.referencetime = datetime(allData.referencetime, 'Format', 'MM/dd/yyyy');
allData.health = string(allData.health);
allData.subjectid = string(allData.subjectid);
allData(allData.subjectid == "none",:) = [];

startDate = datetime('06/16/2022', 'InputFormat', 'MM/dd/yyyy');
endDate = datetime('12/01/2022', 'InputFormat', 'MM/dd/yyyy');

endDate = endDate + days(1);
dataInRange = allData(allData.referencetime >= startDate & allData.referencetime <= endDate, :);

% BL_P2L1_id
BL_genotype_filter = strcmpi(strrep(dataInRange.genotype, ' ',''), ...
    strrep("CRL: Long Evans",' ',''));
BL_health_filter = strcmpi(strrep(dataInRange.health, ' ',''), "N/A");
P2L1_task_filter = strcmpi(strrep(dataInRange.tasktypedone, ' ',''), "P2L1");

BL_start_date = datetime('06/16/2022', 'InputFormat', 'MM/dd/yyyy');
BL_end_date = datetime('06/23/2022', 'InputFormat', 'MM/dd/yyyy');
BL_end_date = BL_end_date + days(1);
BL_dates = dataInRange.referencetime >= BL_start_date & ...
    dataInRange.referencetime <= BL_end_date;

BL_P2L1_data = dataInRange(BL_genotype_filter & BL_health_filter & ...
    P2L1_task_filter & BL_dates, :);
BL_P2L1_id = BL_P2L1_data.id;

% BL_P2L1L3_id
BL_P2L1L3_Q = "SELECT id, health, genotype, tasktypedone, referencetime, " + ...
    "subjectid, gender, notes FROM live_table WHERE genotype = 'CRL: Long Evans' AND " + ...
    "health = 'N/A' AND REPLACE(tasktypedone, ' ', '') = 'P2L1L3' AND " + ...
    "UPPER(subjectid) <> UPPER('none') ORDER BY id";
BL_P2L1L3_data = fetch(conn, BL_P2L1L3_Q);
BL_P2L1L3_id = BL_P2L1L3_data.id;

% FD_P2L1_id
FD_health_filter = strcmpi(strrep(dataInRange.health, ' ',''), ...
    strrep("Food Deprivation",' ',''));

FD_start_date = datetime('08/23/2022', 'InputFormat', 'MM/dd/yyyy');
FD_end_date = datetime('08/25/2022', 'InputFormat', 'MM/dd/yyyy');
FD_end_date = FD_end_date + days(1);
FD_dates = dataInRange.referencetime >= FD_start_date & ...
    dataInRange.referencetime <= FD_end_date;

FD_P2L1_data = dataInRange(BL_genotype_filter & FD_health_filter & ...
    P2L1_task_filter & FD_dates, :);
FD_P2L1_id = FD_P2L1_data.id;

% initial_task_id
IT_health_filter = strcmpi(strrep(dataInRange.health, ' ',''), "N/A");
P2A_task_filter = strcmpi(strrep(dataInRange.tasktypedone, ' ',''), "P2A");

IT_start_date = datetime('09/16/2022', 'InputFormat', 'MM/dd/yyyy');
IT_end_date = datetime('10/03/2022', 'InputFormat', 'MM/dd/yyyy');
IT_end_date = IT_end_date + days(1);
IT_dates = dataInRange.referencetime >= IT_start_date & ...
    dataInRange.referencetime <= IT_end_date;

IT_data = dataInRange(BL_genotype_filter & IT_health_filter & ...
    P2A_task_filter & IT_dates, :);
initial_task_id = IT_data.id;

% late_task_id
LT_genotype_filter = ismember(dataInRange.genotype, ["lg_boost","lg_etoh"]);

LT_start_date = datetime('11/02/2022', 'InputFormat', 'MM/dd/yyyy');
LT_end_date = datetime('12/01/2022', 'InputFormat', 'MM/dd/yyyy');
LT_end_date = LT_end_date + days(1);
LT_dates = dataInRange.referencetime >= LT_start_date & ...
    dataInRange.referencetime <= LT_end_date;

LT_data = dataInRange(LT_genotype_filter & IT_health_filter & ...
    P2A_task_filter & LT_dates, :);
late_task_id = LT_data.id;

% Pre_feeding_P2L1_id
PF_genotype_filter = strcmpi(strrep(dataInRange.genotype, ' ',''), ...
    strrep("CRL: Long Evans",' ',''));
PF_health_filter = strcmpi(strrep(dataInRange.health, ' ',''), "Pre-Feeding");
PF_task_filter = strcmpi(strrep(dataInRange.tasktypedone, ' ',''), "P2L1");
PF_P2L1_data = dataInRange(PF_genotype_filter & PF_health_filter & ...
    PF_task_filter, :);
PF_P2L1_id = PF_P2L1_data.id;

% Pre_feeding_P2L1L3_id
PF_task_filter = strcmpi(strrep(dataInRange.tasktypedone, ' ',''), "P2L1L3");
PF_P2L1L3_data = dataInRange(PF_genotype_filter & PF_health_filter & ...
    PF_task_filter, :);
PF_P2L1L3_id = PF_P2L1L3_data.id;
end