function mergedTable = fetchHealthDataTable(feature, idList, varargin)
% fetchHealthDataTable Fetches merged health and feature data for given IDs.
%
% Usage:
%   mergedTable = fetchHealthDataTable(feature, idList)
%   mergedTable = fetchHealthDataTable(feature, idList, conn)
%   mergedTable = fetchHealthDataTable(feature, idList, conn, threshold)
%
% Optional:
%   - conn (database connection)
%   - distanceThreshold (scalar, applies only if feature ≠ 'approachavoid')

% Handle connection and optional distance range
if nargin < 3 || isempty(varargin{1})
    conn = database('live_database', 'postgres', '1234');
else
    conn = varargin{1};
end

% Check if a distance range is supplied
if numel(varargin) >= 2 && ~isempty(varargin{2})
    distanceRange = varargin{2};  % Should be a 2-element vector [min, max]
    if numel(distanceRange) ~= 2
        error('distanceRange must be a 2-element vector: [min, max]');
    end
else
    distanceRange = [-Inf, Inf];  % Default: no filtering
end

% Convert idList to comma-separated string if needed
if isnumeric(idList)
    idListStr = strjoin(string(idList), ',');
else
    idListStr = idList;
end

% Query for live_table
liveQuery = sprintf( ...
    "SELECT id, subjectid, referencetime, gender, feeder, trialname, " + ...
    "health, trialcontrolsettings, tasktypedone, approachavoid " + ...
    "FROM live_table WHERE id IN (%s) ORDER BY id;" , idListStr);
liveData = fetch(conn, liveQuery);

% Determine if feature is 'approachavoid'
isApproachAvoid = strcmpi(feature, 'approachavoid');

% Query for ghrelin_featuretable only if needed
if ~isApproachAvoid
    featureQuery = sprintf( ...
        "SELECT id, distance_until_limiting_time_stamp, %s " + ...
        "FROM ghrelin_featuretable WHERE id IN (%s) ORDER BY id;", ...
        feature, idListStr);
    featureData = fetch(conn, featureQuery);
    mergedTable = innerjoin(liveData, featureData, 'Keys', 'id');
else
    mergedTable = liveData;
end

% Data cleanup
mergedTable.referencetime = string(datetime(mergedTable.referencetime, 'Format', 'MM/dd/yyyy'));
mergedTable.subjectid = string(mergedTable.subjectid);
mergedTable.gender = string(mergedTable.gender);
mergedTable.health = string(mergedTable.health);
mergedTable.trialcontrolsettings = string(mergedTable.trialcontrolsettings);
mergedTable.tasktypedone = string(mergedTable.tasktypedone);
mergedTable.trialname = str2double(regexprep(string(mergedTable.trialname), 'Trial\s*(\d+)', '$1'));
mergedTable.feeder = str2double(mergedTable.feeder);

% Convert numeric columns
if ~ismember(feature, {'approachavoid', 'distance_until_limiting_time_stamp'}) && ...
        ~isa(mergedTable.(feature), 'double')
    mergedTable.(feature) = str2double(mergedTable.(feature));
end

% Filter based on distance range
if ~isApproachAvoid
    mergedTable = mergedTable( ...
        mergedTable.distance_until_limiting_time_stamp >= distanceRange(1) & ...
        mergedTable.distance_until_limiting_time_stamp <= distanceRange(2), :);
end

% Assign realFeederId
patterns = ["Diagonal", "Grid", "Horizontal", "Radial"];
feederIds = [1, 2, 3, 4];
mergedTable.realFeederId = nan(height(mergedTable), 1);

for i = 1:numel(patterns)
    mask = contains(mergedTable.trialcontrolsettings, patterns(i), 'IgnoreCase', true);
    mergedTable.realFeederId(mask) = feederIds(i);
end
fallbackMask = isnan(mergedTable.realFeederId);
mergedTable.realFeederId(fallbackMask) = mergedTable.feeder(fallbackMask);
end