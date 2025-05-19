function mazeMethods(mazeIndex, feeder, feederSize, zoneSize, highlightOffer, highlightCenter)
% Author: Atanu Giri
% Date: 11/17/2023 (Modified: 05/16/2025)
%
% This method chooses the maze in which the trial is taking place.
% It shades feeder zones and (optionally) highlights the offer and central zones.
%
% Parameters:
% mazeIndex     - Maze quadrant (1 to 4)
% feederSize    - Size of feeder rectangles (default 0.25)
% zoneSize      - Size of central zone (default 0.5)
% feeder        - Which feeder to highlight (1 to 4)
% highlightOffer - (optional) whether to highlight the offer zone (default = true)
% highlightCenter - (optional) whether to highlight the central zone (default = true)

if nargin < 6
    highlightCenter = true;
end
if nargin < 5
    highlightOffer = true;
end
if nargin < 4 || isempty(zoneSize)
    zoneSize = 0.5;
end
if nargin < 3 || isempty(feederSize)
    feederSize = 0.25;
end
if nargin < 2
    feeder = [];
end

grayFace = [0.3 0.3 0.3];
yellowFace = [1 1 0 0.3];
xWidth = (feederSize + 0.05);
yWidth = xWidth;

% Rectangle positions based on maze
switch mazeIndex
    case 1
        r1 = rectangle('Position', [(1 - feederSize) -0.05 xWidth yWidth], 'EdgeColor', 'none', 'FaceColor', grayFace, 'FaceAlpha', 0.3);
        r2 = rectangle('Position', [-0.05 -0.05 xWidth yWidth], 'EdgeColor', 'none', 'FaceColor', grayFace, 'FaceAlpha', 0.3);
        r3 = rectangle('Position', [-0.05 (1 - feederSize) xWidth yWidth], 'EdgeColor', 'none', 'FaceColor', grayFace, 'FaceAlpha', 0.3);
        r4 = rectangle('Position', [(1 - feederSize) (1 - feederSize) xWidth yWidth], 'EdgeColor', 'none', 'FaceColor', grayFace, 'FaceAlpha', 0.3);
        xMid = 0.5; yMid = 0.5;

    case 2
        r1 = rectangle('Position', [-1.05 (1 - feederSize) xWidth yWidth], 'EdgeColor', 'none', 'FaceColor', grayFace, 'FaceAlpha', 0.3);
        r2 = rectangle('Position', [-1.05 -0.05 xWidth yWidth], 'EdgeColor', 'none', 'FaceColor', grayFace, 'FaceAlpha', 0.3);
        r3 = rectangle('Position', [-feederSize -0.05 xWidth yWidth], 'EdgeColor', 'none', 'FaceColor', grayFace, 'FaceAlpha', 0.3);
        r4 = rectangle('Position', [-feederSize (1 - feederSize) xWidth yWidth], 'EdgeColor', 'none', 'FaceColor', grayFace, 'FaceAlpha', 0.3);
        xMid = -0.5; yMid = 0.5;

    case 3
        r1 = rectangle('Position', [-feederSize -1.05 xWidth yWidth], 'EdgeColor', 'none', 'FaceColor', grayFace, 'FaceAlpha', 0.3);
        r2 = rectangle('Position', [-1.05 -1.05 xWidth yWidth], 'EdgeColor', 'none', 'FaceColor', grayFace, 'FaceAlpha', 0.3);
        r3 = rectangle('Position', [-1.05 -feederSize xWidth yWidth], 'EdgeColor', 'none', 'FaceColor', grayFace, 'FaceAlpha', 0.3);
        r4 = rectangle('Position', [-feederSize -feederSize xWidth yWidth], 'EdgeColor', 'none', 'FaceColor', grayFace, 'FaceAlpha', 0.3);
        xMid = -0.5; yMid = -0.5;

    case 4
        r1 = rectangle('Position', [-0.05 -feederSize xWidth yWidth], 'EdgeColor', 'none', 'FaceColor', grayFace, 'FaceAlpha', 0.3);
        r2 = rectangle('Position', [(1 - feederSize) -feederSize xWidth yWidth], 'EdgeColor', 'none', 'FaceColor', grayFace, 'FaceAlpha', 0.3);
        r3 = rectangle('Position', [(1 - feederSize) -1.05 xWidth yWidth], 'EdgeColor', 'none', 'FaceColor', grayFace, 'FaceAlpha', 0.3);
        r4 = rectangle('Position', [-0.05 -1.05 xWidth yWidth], 'EdgeColor', 'none', 'FaceColor', grayFace, 'FaceAlpha', 0.3);
        xMid = 0.5; yMid = -0.5;

    otherwise
        warning('Unexpected maze number.');
        return;
end

helperPlot;  % plots text + highlights offer if enabled

if highlightCenter
    x1 = xMid - zoneSize/2; 
    y1 = yMid - zoneSize/2;
    rectangle('Position', [x1 y1 zoneSize zoneSize], 'EdgeColor', 'none', ...
        'FaceColor', [1 0 0 0.2]);
end

    %% Nested helper function
    function helperPlot
        r = [r1, r2, r3, r4];
        textPositions = [
            r1.Position(1)+xWidth/2, r1.Position(2)+yWidth/2;
            r2.Position(1)+xWidth/2, r2.Position(2)+yWidth/2;
            r3.Position(1)+xWidth/2, r3.Position(2)+yWidth/2;
            r4.Position(1)+xWidth/2, r4.Position(2)+yWidth/2;
        ];
        textLabels = {'9%', '5%', '2%', '0.5%'};

        for i = 1:4
            text(textPositions(i,1), textPositions(i,2), textLabels{i}, ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
                'Color', 'r', 'FontWeight', 'bold');
        end

        if highlightOffer && ~isempty(feeder)
            set(r(feeder), 'FaceColor', yellowFace);
        end
    end
end
