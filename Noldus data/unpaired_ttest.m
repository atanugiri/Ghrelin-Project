function out = unpaired_ttest(file)
% unpaired_min: Welch's t-test + Wilcoxon rank-sum (W, U, p) from one CSV
% - Uses last two numeric columns as independent groups A and B

T = readtable(file);
A = T{:, end-1};
B = T{:, end};

% Welch's t-test (unequal variances)
[~, p_t, ~, st] = ttest2(A, B, 'Vartype', 'unequal');

% Wilcoxon rank-sum (Mann–Whitney U)
[p_rs, ~, srs] = ranksum(A, B, 'method', 'approximate');  % srs.ranksum = W (for A)
W = srs.ranksum;
n1 = numel(A);
U = W - n1*(n1+1)/2;

out = struct('t_df', sprintf('t(%g)', st.df), 't', st.tstat, 'p_t', p_t, ...
             'W', W, 'U', U, 'p_rs', p_rs);

fprintf('Welch''s t-test: t(%.2f) = %.2f, p = %.3f\n', st.df, st.tstat, p_t);
fprintf('Wilcoxon rank-sum: W = %.2f, p = %.3f\n', W, p_rs);
end
