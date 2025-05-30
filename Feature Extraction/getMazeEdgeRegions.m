function edgeStruct = getMazeEdgeRegions(quadrant, center_size)
%
% getMazeEdgeRegions: Return feeder, center and nest zone edges for a given maze quadrant.
%
%   edgeStruct = getMazeEdgeRegions(quadrant, center_size) returns a structure containing
%   the x- and y-coordinate boundaries (edges) of the four feeder zones, central zone 
%   and the nest for a maze, based on the specified quadrant orientation.
%
%   Input:
%     - quadrant     : Integer (1 to 4), representing the spatial orientation of the maze.
%     - center_size  : (Optional) Width and height of the central zone square (default = 0.5).
%
%   Output:
%     - edgeStruct : A structure with the following fields, each containing a 1x2 cell:
%         • Feeder1 : {x_range, y_range} for Feeder 1 (concentration 9)
%         • Feeder2 : {x_range, y_range} for Feeder 2 (concentration 5)
%         • Feeder3 : {x_range, y_range} for Feeder 3 (concentration 2)
%         • Feeder4 : {x_range, y_range} for Feeder 4 (concentration 0.5)
%         • Center  : {x_range, y_range} for the central zone
%         • Nest    : {x_range, y_range} for the strip comprising 5% and 9%
%
%   Notes:
%     - The coordinate edges are defined in normalized maze space.
%     - The feeder–concentration mapping is:
%         Feeder 1 → 9
%         Feeder 2 → 5
%         Feeder 3 → 2
%         Feeder 4 → 0.5
%
%   Example:
%     edgeStruct = getMazeEdgeRegions(2);
%     [x_edge, y_edge] = edgeStruct.Feeder3{:};  % Access x/y for Feeder 3
%
%   Author: Atanu Giri
%   Date  : 05/27/2025


if nargin < 2
    center_size = 0.5;
end

switch quadrant
    case 1
        x_edge_for_9 = [0.75 1.05]; y_edge_for_9 = [-0.05 0.25];
        x_edge_for_5 = [-0.05 0.25]; y_edge_for_5 = [-0.05 0.25];
        x_edge_for_2 = [-0.05 0.25]; y_edge_for_2 = [0.75 1.05];
        x_edge_for_0_5 = [0.75 1.05]; y_edge_for_0_5 = [0.75 1.05];

        x_edge_for_center = [(0.5 - center_size/2) (0.5 + center_size/2)];
        y_edge_for_center = [(0.5 - center_size/2) (0.5 + center_size/2)];

        x_edge_for_nest = [-0.05 1.05]; y_edge_for_nest = [-0.05 0.25];

    case 2
        x_edge_for_9 = [-1.05 -0.75]; y_edge_for_9 = [0.75 1.05];
        x_edge_for_5 = [-1.05 -0.75]; y_edge_for_5 = [-0.05 0.25];
        x_edge_for_2 = [-0.25 0.05]; y_edge_for_2 = [-0.05 0.25];
        x_edge_for_0_5 = [-0.25 0.05]; y_edge_for_0_5 = [0.75 1.05];

        x_edge_for_center = [(-0.5 - center_size/2) (-0.5 + center_size/2)];
        y_edge_for_center = [(0.5 - center_size/2) (0.5 + center_size/2)];

        x_edge_for_nest = [-1.05, -0.75]; y_edge_for_nest = [-0.05 1.05];

    case 3
        x_edge_for_9 = [-0.25 0.05]; y_edge_for_9 = [-1.05 -0.75];
        x_edge_for_5 = [-1.05 -0.75]; y_edge_for_5 = [-1.05 -0.75];
        x_edge_for_2 = [-1.05 -0.75]; y_edge_for_2 = [-0.25 0.05];
        x_edge_for_0_5 = [-0.25 0.05]; y_edge_for_0_5 = [-0.25 0.05];

        x_edge_for_center = [(-0.5 - center_size/2) (-0.5 + center_size/2)];
        y_edge_for_center = [(-0.5 - center_size/2) (-0.5 + center_size/2)];

        x_edge_for_nest = [-1.05 0.05]; y_edge_for_nest = [-1.05 -0.75];
        
    case 4
        x_edge_for_9 = [-0.05 0.25]; y_edge_for_9 = [-0.25 0.05];
        x_edge_for_5 = [0.75 1.05]; y_edge_for_5 = [-0.25 0.05];
        x_edge_for_2 = [0.75 1.05]; y_edge_for_2 = [-1.05 -0.75];
        x_edge_for_0_5 = [-0.05 0.25]; y_edge_for_0_5 = [-1.05 -0.75];

        x_edge_for_center = [(0.5 - center_size/2) (0.5 + center_size/2)];
        y_edge_for_center = [(-0.5 - center_size/2) (-0.5 + center_size/2)];

        x_edge_for_nest = [-0.05 1.05]; y_edge_for_nest = [-0.25 0.05];
        
end

edgeStruct.Feeder1 = {x_edge_for_9, y_edge_for_9};
edgeStruct.Feeder2 = {x_edge_for_5, y_edge_for_5};
edgeStruct.Feeder3 = {x_edge_for_2, y_edge_for_2};
edgeStruct.Feeder4 = {x_edge_for_0_5, y_edge_for_0_5};
edgeStruct.Center  = {x_edge_for_center, y_edge_for_center};
edgeStruct.Nest    = {x_edge_for_nest, y_edge_for_nest};

end