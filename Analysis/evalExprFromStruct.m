function val = evalExprFromStruct(expr, S)
% Evaluates an expression string using fields from struct S as variables

fns = fieldnames(S);
for i = 1:numel(fns)
    eval(sprintf('%s = S.%s;', fns{i}, fns{i}));
end

val = eval(expr);  % Example: time_in_nest / distance
end