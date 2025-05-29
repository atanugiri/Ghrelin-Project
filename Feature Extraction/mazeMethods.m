function mazeMethods(quadrant, feeder, centerSize, highlightOffer, highlightCenter)
% Author: Atanu Giri
% Date: 11/17/2023 (Modified: 05/16/2025)
%
% This method chooses the maze in which the trial is taking place.
% It shades feeder zones and (optionally) highlights the offer and central zones.
%
% Parameters:
% quadrant      - Maze quadrant (1 to 4)
% feeder        - Which feeder to highlight (1 to 4)
% centerSize    - Size of central zone (default 0.5)
% highlightOffer  - (optional) whether to highlight the offer zone (default = true)
% highlightCenter - (optional) whether to highlight the central zone (default = true)

if nargin < 5
    highlightCenter = true;
end
if nargin < 4
    highlightOffer = true;
end
if nargin < 3 || isempty(centerSize)
    centerSize = 0.5;
end
if nargin < 2
    feeder = [];
end

% Get feeder and center zone edges
edgeStruct = getMazeEdgeRegions(quadrant, centerSize);

% Plot each feeder rectangle
feederNames = {'Feeder1', 'Feeder2', 'Feeder3', 'Feeder4'};
grayFace = [0.3 0.3 0.3];
yellowFace = [1 1 0 0.3];
r = gobjects(1, 4);

for i = 1:4
    [xEdge, yEdge] = edgeStruct.(feederNames{i}){:};
    pos = [xEdge(1), yEdge(1), diff(xEdge), diff(yEdge)];
    r(i) = rectangle('Position', pos, 'EdgeColor', 'none', ...
        'FaceColor', grayFace, 'FaceAlpha', 0.3);
end

textLabels = {'9%', '5%', '2%', '0.5%'};
for i = 1:4
    [xEdge, yEdge] = edgeStruct.(feederNames{i}){:};
    xCenter = mean(xEdge); yCenter = mean(yEdge);
    text(xCenter, yCenter, textLabels{i}, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', ...
        'Color', 'r', 'FontWeight', 'bold');
end

if highlightOffer && ~isempty(feeder)
    set(r(feeder), 'FaceColor', yellowFace);
end

if highlightCenter
    [xCenter, yCenter] = edgeStruct.Center{:};
    rectangle('Position', [xCenter(1), yCenter(1), diff(xCenter), diff(yCenter)], ...
        'EdgeColor', 'none', 'FaceColor', [1 0 0 0.2]);
end

end