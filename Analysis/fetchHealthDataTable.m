function mergedTable = fetchHealthDataTable(featureExpr, idList, conn, distanceRange)

if nargin < 4 || isempty(distanceRange)
    distanceRange = [-Inf, Inf];
elseif numel(distanceRange) ~= 2
    error('distanceRange must be a 2-element vector: [min, max]');
end

% Format ID list
if isnumeric(idList)
    idListStr = strjoin(string(idList), ',');
else
    idListStr = idList;
end

% Check if expression is composite and get variable names
isComposite = ~isvarname(featureExpr);  % crude check, refine if needed
usedVars = getVariableNamesFromExpr(featureExpr);

% Special case: approachavoid
isApproachAvoid = strcmpi(strtrim(featureExpr), 'approachavoid');
if isApproachAvoid
    query = sprintf( ...
        "SELECT g.id, g.distance, l.subjectid, l.referencetime, l.feeder, " + ...
        "l.trialcontrolsettings, l.approachavoid " + ...
        "FROM ghrelin_featuretable g JOIN live_table l ON g.id = l.id " + ...
        "WHERE g.id IN (%s) ORDER BY g.id;", idListStr);
    mergedTable = fetch(conn, query);
    mergedTable.approachavoid = str2double(mergedTable.approachavoid);

else
    % Determine all needed columns
    allVars = unique([usedVars, {'distance'}]);  % always include distance
    varListStr = strjoin(allVars, ', ');

    query = sprintf( ...
        "SELECT g.id, %s, l.subjectid, l.referencetime, l.feeder, " + ...
        "l.trialcontrolsettings FROM ghrelin_featuretable g " + ...
        "JOIN live_table l ON g.id = l.id WHERE g.id IN (%s) ORDER BY g.id;", ...
        varListStr, idListStr);

    mergedTable = fetch(conn, query);

    % Evaluate expression if needed
    if isComposite
        % Ensure variables are numeric
        for v = usedVars
            v = char(v);
            if ~isa(mergedTable.(v), 'double')
                mergedTable.(v) = str2double(mergedTable.(v));
            end
        end

        % Build a local anonymous function to evaluate the expression per row
        exprFcn = @(row) evaluateExprRow(row, featureExpr, usedVars);

        % Apply it row-wise
        mergedTable.(featureExpr) = arrayfun(@(i) exprFcn(mergedTable(i,:)), 1:height(mergedTable))';

    else
        if ~isa(mergedTable.(featureExpr), 'double')
            mergedTable.(featureExpr) = str2double(mergedTable.(featureExpr));
        end

        % This block needs to be changed; this is temporary fix
        if strcmpi(featureExpr, "curvature")
            mergedTable.(featureExpr) = log10(mergedTable.(featureExpr) + 1);
        end

    end
end

% Postprocessing
mergedTable.referencetime = string(datetime(mergedTable.referencetime, 'Format', 'MM/dd/yyyy'));
mergedTable.subjectid = string(mergedTable.subjectid);
mergedTable.trialcontrolsettings = string(mergedTable.trialcontrolsettings);
mergedTable.feeder = str2double(mergedTable.feeder);

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

% Filter based on distanceRange
if ismember('distance', mergedTable.Properties.VariableNames)
    mask = mergedTable.distance >= distanceRange(1) & ...
        mergedTable.distance <= distanceRange(2);
    mergedTable = mergedTable(mask, :);
end
end