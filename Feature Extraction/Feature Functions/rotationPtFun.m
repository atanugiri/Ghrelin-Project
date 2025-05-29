% Author: Atanu Giri
% Date: 12/26/2023
% This function returns the total total number of rotation pts in trajectory

function [rotationPts_method1, rotationPts_method2, rotationPts_method3, ...
    rotationPts_method4] = rotationPtFun(id, varargin)
% id = 265215;
% make connection with database
if numel(varargin) < 1
    datasource = 'live_database';
    conn = database(datasource,'postgres','1234');
else
    conn =  varargin{1};
end

% write query
query = sprintf("SELECT id, playstarttrialtone, coordinatetimes2, " + ...
    "truedirection FROM live_table WHERE id = %d;", id); %id
subject_data = fetch(conn,query);

featureTableQuery = sprintf("SELECT id, distance " + ...
    "FROM ghrelin_featuretable WHERE id = %d", id);
featureTableData = fetch(conn, featureTableQuery);

subject_data = innerjoin(featureTableData, subject_data, 'Keys', 'id');

try
    % convert char to double in playstarttrialtone column
    subject_data.playstarttrialtone = str2double(subject_data.playstarttrialtone);
    if isnan(subject_data.playstarttrialtone)
        subject_data.playstarttrialtone = 2;
    end

    % Accessing PGArray data as double
    for column = size(subject_data,2) - 1:size(subject_data,2)
        stringAllRows = string(subject_data.(column));
        regAllRows = regexprep(stringAllRows,'{|}','');
        splitAllRows = split(regAllRows,',');
        doubleData = str2double(splitAllRows);
        subject_data.(column){1} = doubleData;
    end

    % includes the data before playstarttrialtone
    badDataWithTone = table(subject_data.coordinatetimes2{1}, ...
        subject_data.truedirection{1},'VariableNames',{'t','direction'});
    cleanedDataWithTone = badDataWithTone;

    idx = all(isfinite(cleanedDataWithTone{:,:}),2);
    cleanedDataWithTone = cleanedDataWithTone(idx,:);

    startingCoordinatetimes = subject_data.playstarttrialtone;

    mask = cleanedDataWithTone.t > startingCoordinatetimes & cleanedDataWithTone.t <= 20;
    direction = cleanedDataWithTone.direction(mask);

    % Apply sliding window to find stopping points
    % User-adjustable parameters
    windowSize = [3,5,10,15]; % Window to scan the array with.
    directionChange = [180,180,180,180];

    rotationPts = zeros(1,numel(windowSize));
    bulbIndexes = cell(1,numel(windowSize));

    % Scan array looking for clustered points all within the defined box width.
    for method = 1:numel(windowSize)
        bulbIndexes{method} = false(numel(direction), 1);
        for k = 2 : numel(direction) - windowSize(method)
            % See if all x and y points in the window are within the box.
            DirectionWindow = direction(k : k + windowSize(method) - 1);
            if range(DirectionWindow) > directionChange(method)
                bulbIndexes{method}(k : k + windowSize(method) - 1) = true;
            end
        end
        [labeledBulb, rotationPt] = bwlabel(bulbIndexes{method});
        rotationPts(method) = rotationPt/subject_data.distance;
    end

    rotationPts_method1 = rotationPts(1);
    rotationPts_method2 = rotationPts(2);
    rotationPts_method3 = rotationPts(3);
    rotationPts_method4 = rotationPts(4);

catch
    sprintf("An error occured for id = %d\n", id);
end

end