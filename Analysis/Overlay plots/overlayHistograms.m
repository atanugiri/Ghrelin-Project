function [fig, ax] = overlayHistograms(varargin)
% overlayHistograms - Overlay histograms for multiple input arrays
% Usage:
%   [fig, ax] = overlayHistograms(data1, data2, ..., dataN)
%   legend(ax, {'Label1', 'Label2', ...}) can be used after for custom legend.
%
% Each input should be a 1D numeric array.

    if nargin == 0
        error('At least one input array is required.');
    end

    fig = figure;
    ax = axes(fig);
    hold(ax, 'on');

    colors = lines(nargin);
    
    for i = 1:nargin
        data = varargin{i};
        if ~isnumeric(data) || ~isvector(data)
            error('All inputs must be numeric vectors.');
        end
        histogram(ax, data, ...
            'FaceColor', colors(i,:), ...
            'EdgeColor', colors(i,:), ...
            'FaceAlpha', 0.5);
    end

    hold(ax, 'off');
    xlabel(ax, 'Value');
    ylabel(ax, 'Count');
    title(ax, 'Overlayed Histograms');
end