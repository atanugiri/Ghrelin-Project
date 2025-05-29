% Author: Atanu Giri
% Date: 02/16/2024
%
% This function fits the response data from a session with desired fit
% model and extracts fitting parameters.
%

function [h, fit_params, R_squared] = sigmoid_fit_fun(y, feature, fitType)

% y = [0.1, 0.3, 0.5, 0.9]; fitType = 1;

% Define fitobjects
fitobjects{1} = @(params, x) params(1) ./ (1 + exp(-params(2) * ...
    (x - params(3)))); % 3 param logistic fit

fitobjects{2} = @(params, x) params(4) + ((params(1) - params(4)) ./ ...
    (1 + (x ./ params(3)).^params(2))); % 4 param logistic fit

fitobjects{3} = @(params, x) params(4) + (params(1)-params(4))*exp( ...
    -exp(-params(2)*(x-params(3)))); % Gompertz model

x = [0.5 2 5 9];

% Starting points
initial_guess = cell(1, numel(fitobjects));
initial_guess{1} = [max(y), 1, median(x)];
initial_guess{2} = [min(y), 1, median(x), max(y)];
initial_guess{3} = [min(y), 1, median(x), max(y)];

lb = cell(1, numel(fitobjects)); ub = cell(1, numel(fitobjects));
% Define lower and upper bounds for parameters
if strcmpi(feature, 'approachavoid')
    lb{1} = [0, -Inf, 0.5]; ub{1} = [1, Inf, 9];
    lb{2} = [0, -Inf, 0.5, 0]; ub{2} = [1, Inf, 9, 1];
    lb{3} = [0, -Inf, 0.5, 0]; ub{3} = [1, Inf, 9, 1];
elseif strcmpi(feature, 'time_in_feeder')
    lb{1} = [0, -Inf, 0.5]; ub{1} = [15, Inf, 9];
    lb{2} = [0, -Inf, 0.5, 0]; ub{2} = [15, Inf, 9, 15];
    lb{3} = [0, -Inf, 0.5, 0]; ub{3} = [15, Inf, 9, 15];
else
    error('Use correct input for feature')
end

% Fit the sigmoid function to the data using nonlinear regression
%     [fitresult{fitIdx}, goodness] = fit(x', y', fitobjects{fitIdx}, ...
%         'StartPoint', initial_guess{fitIdx});

fitobject = fitobjects{fitType};
fit_params = lsqcurvefit(fitobject, initial_guess{fitType}, ...
    x, y, lb{fitType}, ub{fitType});

% Compute the fitted values using the sigmoid function and the fitted parameters
y_fit = fitobject(fit_params, x);

% Compute the total sum of squares (TSS) and residual sum of squares (RSS)
y_mean = mean(y);
TSS = sum((y - y_mean).^2);
RSS = sum((y - y_fit).^2);
R_squared = 1 - (RSS / TSS);

%% Plot the psychometric curve and the fitted sigmoid function
x_values = linspace(min(x), max(x), 100);

y_pred = fitobject(fit_params, x_values);

h = figure;
scatter(x, y, 100, 'o', 'filled');
hold on;
plot(x_values, y_pred, 'linewidth', 2);
xlabel('x');
ylabel('y');
legend('Data', 'Fitted Curve');
hold off;
if strcmpi(feature, 'approachavoid')
    ylim([0, 1]);
elseif strcmpi(feature, 'time_in_feeder')
    ylim([0, 15]);
end
end