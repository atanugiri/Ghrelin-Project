function [accOutlier, jerkOutlier] = accelerationAndJerkOulierFun(id, varargin)
% Author: Atanu Giri
% Date: 12/20/2023 (Modified: 05/19/2025)
%
% This algorithm calculates the number of outliers by analyzing subject's
% acceleration and jerkness using a moving median method.
%
% Usage:
% [acc, jerk] = accelerationAndJerkOulierFun(id)
% [acc, jerk] = accelerationAndJerkOulierFun(id, conn, true)

% Handle optional inputs
if numel(varargin) < 1
    datasource = 'live_database';
    conn = database(datasource, 'postgres', '1234');
else
    conn = varargin{1};
end

% Default: do not plot
plotFlag = false;
if numel(varargin) >= 2
    plotFlag = varargin{2};
end

% Combined query from both tables
query = sprintf( ...
    "SELECT g.id, norm_t, norm_x, norm_y, " + ...
    "l.playstarttrialtone FROM ghrelin_featuretable g " + ...
    "JOIN live_table l ON g.id = l.id " + ...
    "WHERE g.id = %d", ...
    id);
subject_data = fetch(conn, query);

try
    % Parse playstarttrialtone
    playTone = str2double(subject_data.playstarttrialtone);
    if isnan(playTone)
        playTone = 2;
    end

    % Parse norm_t, norm_x, norm_y as numeric arrays
    for colName = ["norm_t", "norm_x", "norm_y"]
        rawStr = string(subject_data.(colName));
        cleanedStr = regexprep(rawStr, '[{}]', '');
        splitStr = split(cleanedStr, ',');
        subject_data.(colName){1} = str2double(splitStr);
    end

    limitingTimeIndex = 20;

    % Create coordinate table
    data = table(subject_data.norm_t{1}, subject_data.norm_x{1}, ...
        subject_data.norm_y{1}, 'VariableNames', {'t', 'X', 'Y'});

    % Present cost (PC) range: playTone–20 sec
    pcFilter = data.t >= playTone & data.t <= limitingTimeIndex;
    t = data.t(pcFilter);
    X = data.X(pcFilter);
    Y = data.Y(pcFilter);

    % Calculate velocity
    Vx = diff(X) ./ diff(t); % X velocity
    Vy = diff(Y) ./ diff(t); % Y velocity
    Vx = [0; Vx]; % Pad
    Vy = [0; Vy];

    % Calculate acceleration
    Ax = diff(Vx) ./ diff(t); % X acceleration
    Ay = diff(Vy) ./ diff(t); % Y acceleration
    Ax = [0; Ax];
    Ay = [0; Ay];

    % Total acceleration magnitude
    A = sqrt(Ax.^2 + Ay.^2);

    % Acceleration outliers
    accOutlierTF = isoutlier(A, "movmedian", 5);
    accOutlier = sum(accOutlierTF);

    % Calculate jerk
    Jx = diff(Ax) ./ diff(t);
    Jy = diff(Ay) ./ diff(t);
    Jx = [0; Jx];
    Jy = [0; Jy];

    J = sqrt(Jx.^2 + Jy.^2);
    jerkOutlier = sum(isoutlier(J, "movmedian", 5));

    %% Optional Plotting
    if plotFlag
        figure;
        plot(t, A, 'b', 'LineWidth', 2);
        hold on;
        accOutlierVal = A(accOutlierTF);
        accOutlierTime = t(accOutlierTF);
        scatter(accOutlierTime, accOutlierVal, 'filled', 'MarkerFaceColor', 'r');
        title(sprintf("ID = %d", id), 'Interpreter', 'latex');
        xlabel('Time (s)', 'FontSize', 25, 'Interpreter', 'latex');
        ylabel('Acceleration', 'FontSize', 25, 'Interpreter', 'latex');
        hold off;
        axis tight; axis equal;
    end

catch
    fprintf("An error occurred for id = %d\n", id);
    accOutlier = NaN;
    jerkOutlier = NaN;
end

end