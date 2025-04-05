% Author: Atanu Giri
% Date: 01/16/2025
%
% 'treatmentGroup' is health group the user wants to analyze.
% 'tonePhase' can be 'pre' or 'post'.
% 'animalList' can be specific animals user wants to analyze.
%
function time_in_each_feeder = analyzeConditionalPlacePreferance(treatmentGroup, tonePhase, animalList)

% treatmentGroup = 'P2A Boost and alcohol';
% varargin = {};
% tonePhase = 'pre';
% animalList = {'aladdin', 'jafar', 'jimi', 'jr', 'mike', 'scar', 'sully'};

if nargin < 3
    animalList = {};
end

conn = database('live_database', 'postgres', '1234');

treatmentIDs = treatmentIDfun(treatmentGroup, conn);
treatmentIDs_str = strjoin(arrayfun(@num2str, treatmentIDs, 'UniformOutput', false), ',');

% Fetch norm_x, norm_y, norm_t
treatment_data = fetchHealthDataTable('approachavoid', treatmentIDs_str, conn);

% Additional query
addQuery = sprintf("SELECT id, norm_x, norm_y, norm_t " + ...
    "FROM ghrelin_featuretable WHERE id IN (%s) ORDER BY id", treatmentIDs_str);
addData = fetch(conn, addQuery);

treatment_data = innerjoin(treatment_data,addData,'Keys','id');

addLTquery = sprintf("SELECT id, mazenumber " + ...
    "FROM live_table WHERE id IN (%s) ORDER BY id", treatmentIDs_str);
addLTdata = fetch(conn, addLTquery);
addLTdata.mazenumber = regexprep(string(addLTdata.mazenumber), 'maze\s*(\d+)', '$1');
addLTdata.mazenumber = str2double(addLTdata.mazenumber);

treatment_data = innerjoin(treatment_data,addLTdata,'Keys','id');

% L1 and L3 task in L1L3 will naturally have 20 trials
trtGroupsToExclude = {'P2L1L3 BL for comb boost and alc L1', ...
    'P2L1L3 BL for comb boost and alc L3','P2L1L3 Boost and alcohol L1', ...
    'P2L1L3 Boost and alcohol L3', 'P2L1L3 Post alcohol L1', ...
    'P2L1L3 Post alcohol L3'};

if ~ismember(treatmentGroup,trtGroupsToExclude)
    treatment_data = cleanBadSessionsFromTable(treatment_data, 'approachavoid'); % Remove bad sessions
end

% Filter treatment_data if animalList is provided
if ~isempty(animalList)
    treatment_data = treatment_data(ismember(treatment_data.subjectid, animalList), :);
end

% Placeholder for time
time_in_each_feeder = zeros(4,4); % maze(1 -> 4) x conc(9 -> 0.5) matrix

% Plot for each maze separately
for maze = unique(treatment_data.mazenumber)'
    currentMazeData = treatment_data(treatment_data.mazenumber == maze, :);

    % Placeholder for timestamp and corrdinates of current maze
    X = []; Y = []; t = [];

    for trial = 1:size(currentMazeData,1)

        % Placeholder for current trial data
        tempX = []; tempY = []; tempT = [];
        cols = {'norm_x', 'norm_y', 'norm_t'};

        for col = 1:numel(cols)
            pgArray = currentMazeData.(cols{col}){trial};        % Extract the PgArray
            matlabArray = pgArray.getArray();  % Convert to MATLAB array
            % Convert Java array to MATLAB cell array
            matlabCellArray = cell(matlabArray);
            % Convert cell array to a MATLAB double array
            matlabDoubleArray = cell2mat(matlabCellArray);

            if col == 1
                tempX = matlabDoubleArray;
            elseif col == 2
                tempY = matlabDoubleArray;
            elseif col == 3
                tempT = matlabDoubleArray;
            end
        end

        if strcmpi(tonePhase, 'post')
            filter = tempT > 12 & tempT <= 20;
        elseif strcmpi(tonePhase, 'pre')
            filter = tempT <= 5;
        end

        tempX = tempX(filter); tempY = tempY(filter); tempT = tempT(filter);

        X = [X; tempX]; Y = [Y; tempY]; t = [t; tempT];
    end

    [timeInConc9, timeInConc5, timeInConc2, timeInConc0_5] = ...
        extractTimeInFeederFromCoordinates(X, Y, maze);

    figure;
    plot(X, Y, '.');
    hold on;
    if maze == 1
        mazeMethods(2);
    elseif maze == 2
        mazeMethods(1);
    else
        mazeMethods(maze);
    end
    title(sprintf('Maze_%s_%s_tone', num2str(maze), tonePhase), 'Interpreter','none');

    time_in_each_feeder(maze, :) = [timeInConc9, timeInConc5, timeInConc2, ...
        timeInConc0_5] ./size(currentMazeData,1);
end