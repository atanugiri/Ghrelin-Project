function [feeder1_edge, feeder2_edge, feeder3_edge, feeder4_edge] = feederEdgesByQuadrant(quadrant)
% feederEdgesByQuadrant  Return feeder zone edges for a given maze quadrant.
%
%   [f1, f2, f3, f4] = feederEdgesByQuadrant(quadrant) returns the x- and y-coordinate
%   boundaries (edges) of the four feeder zones for a maze, based on the quadrant index.
%
%   Input:
%     - quadrant : Integer (1 to 4) representing the spatial orientation of the maze.
%
%   Output:
%     - feeder1_edge : {x_range, y_range} for Feeder 1 (concentration 9)
%     - feeder2_edge : {x_range, y_range} for Feeder 2 (concentration 5)
%     - feeder3_edge : {x_range, y_range} for Feeder 3 (concentration 2)
%     - feeder4_edge : {x_range, y_range} for Feeder 4 (concentration 0.5)
%
%   Notes:
%     - The coordinate edges are defined in normalized space.
%     - The feeder–concentration mapping is:
%         Feeder 1 → 9
%         Feeder 2 → 5
%         Feeder 3 → 2
%         Feeder 4 → 0.5
%
%   Example:
%     [f1, f2, f3, f4] = feederEdgesByQuadrant(1);
%     % Returns feeder edges for quadrant 1
%
%   Author: Atanu Giri
%   Date  : 05/27/2025

switch quadrant
    case 1
        x_edge_for_9 = [0.75 1.05]; y_edge_for_9 = [-0.05 0.25];
        x_edge_for_5 = [-0.05 0.25]; y_edge_for_5 = [-0.05 0.25];
        x_edge_for_2 = [-0.05 0.25]; y_edge_for_2 = [0.75 1.05];
        x_edge_for_0_5 = [0.75 1.05]; y_edge_for_0_5 = [0.75 1.05];

    case 2
        x_edge_for_9 = [-1.05 -0.75]; y_edge_for_9 = [0.75 1.05];
        x_edge_for_5 = [-1.05 -0.75]; y_edge_for_5 = [-0.05 0.25];
        x_edge_for_2 = [-0.25 0.05]; y_edge_for_2 = [-0.05 0.25];
        x_edge_for_0_5 = [-0.25 0.05]; y_edge_for_0_5 = [0.75 1.05];

    case 3
        x_edge_for_9 = [-0.25 0.05]; y_edge_for_9 = [-1.05 -0.75];
        x_edge_for_5 = [-1.05 -0.75]; y_edge_for_5 = [-1.05 -0.75];
        x_edge_for_2 = [-1.05 -0.75]; y_edge_for_2 = [-0.25 0.05];
        x_edge_for_0_5 = [-0.25 0.05]; y_edge_for_0_5 = [-0.25 0.05];

    case 4
        x_edge_for_9 = [-0.05 0.25]; y_edge_for_9 = [-0.25 0.05];
        x_edge_for_5 = [0.75 1.05]; y_edge_for_5 = [-0.25 0.05];
        x_edge_for_2 = [0.75 1.05]; y_edge_for_2 = [-1.05 -0.75];
        x_edge_for_0_5 = [-0.05 0.25]; y_edge_for_0_5 = [-1.05 -0.75];
end

feeder1_edge = {x_edge_for_9, y_edge_for_9};
feeder2_edge = {x_edge_for_5, y_edge_for_5};
feeder3_edge = {x_edge_for_2, y_edge_for_2};
feeder4_edge = {x_edge_for_0_5, y_edge_for_0_5};
end