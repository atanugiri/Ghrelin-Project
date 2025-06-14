function varNames = getVariableNamesFromExpr(expr)
% Extract variable names from a mathematical expression string.

% Remove numbers, parentheses, and operators
tokens = regexp(expr, '[a-zA-Z_][a-zA-Z_0-9]*', 'match');
% Remove MATLAB functions like 'mean', 'log' etc. if needed
protectedWords = ["mean", "log", "exp", "min", "max", "sqrt"];
varNames = setdiff(unique(tokens), protectedWords);
end