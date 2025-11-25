function out = paired_ttest(file)
% paired_min: minimal paired t-test + Wilcoxon signed-rank from one CSV file
% - Uses last two numeric columns in the file (e.g., Saline vs Ghrelin)
%
% Output:
%   t(df), p for paired t-test
%   z, p for Wilcoxon signed-rank

T = readtable(file);
X = T{:, end-1};
Y = T{:, end};

% Paired t-test
[~, p_t, ~, st] = ttest(X, Y);

% Wilcoxon signed-rank (approximate z)
[p_w, ~, sw] = signrank(X, Y, 'method', 'approximate');

out = struct('t_df', sprintf('t(%d)', st.df), 't', st.tstat, 'p_t', p_t, ...
             'z', sw.zval, 'p_w', p_w);

fprintf('paired t-test: %s = %.2f, p = %.3g\n', out.t_df, out.t, out.p_t);
fprintf('Wilcoxon signed-rank: z = %.2f, p = %.3g\n', out.z, out.p_w);
end
