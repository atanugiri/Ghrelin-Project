function val = evaluateExprRow(row, expr, vars)
% Safe row-wise math expression evaluation
% Inputs:
%   row  - one row of the table
%   expr - string like 'a/b - c'
%   vars - cell array of variable names used in expr

% Build a struct for evaluation
S = struct();
for i = 1:numel(vars)
    varName = vars{i};
    S.(varName) = row.(varName);
end

% Evaluate using dynamic fieldnames
try
    val = evalExprFromStruct(expr, S);
catch e
    warning(sprintf("Failed to evaluate row: %s", e.message));
    val = NaN;
end
end