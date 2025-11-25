% 2-way ANOVA: Long Evans Rats [11/02/2025] [Fig 1]
longTbl = buildLongTable2way(3, false, '', 'Data/LongEvans/Food Center Freq_K.csv', ...
'Data/LongEvans/Toy Alone Freq_K.csv', 'Data/LongEvans/Light Alone Freq_K.csv'); % simple task
barPlotWithPoints(longTbl, 'Task', 'Group', 'Normalized Frequency', 'Simple task');
[p, tbl, stats] = anovan(longTbl.Y, {longTbl.Group, longTbl.Task}, ...
    'model','interaction', 'varnames', {'Group','Task'});

longTbl = buildLongTable2way(3, false, '', 'Data/LongEvans/Food Light ALL Animlas Freq_K', ...
'Data/LongEvans/Toy Light Freq (Border)_K.csv'); % complex task
barPlotWithPoints(longTbl, 'Task', 'Group', 'Normalized Frequency', 'Complex task');
[p, tbl, stats] = anovan(longTbl.Y, {longTbl.Group, longTbl.Task}, ...
    'model','interaction', 'varnames', {'Group','Task'});

% Feeding results summary: Long Evans Rats [11/05/2025]
paired_ttest('Data/FoodConsumption/Fig. 1e Chow Sal v 2x.csv');
unpaired_ttest('Data/FoodConsumption/Fig. 1f FA Apple Consumption OPRM1 WT.csv');
unpaired_ttest('Data/FoodConsumption/Fig. 1g FL Apple Consumption OPRM1 WT.csv');

paired_ttest('Data/LongEvans/Food Center Freq_K.csv');
paired_ttest('Data/LongEvans/Toy Alone Freq_K.csv');
paired_ttest('Data/LongEvans/Light Alone Freq_K.csv');
paired_ttest('Data/LongEvans/Food Light ALL Animlas Freq_K.csv');
paired_ttest('Data/LongEvans/Toy Light Freq (Border)_K.csv');

% 2-way ANOVA: 10xOPRM1 Rats
longTbl = buildLongTable2way(3, false, '', 'Data/10xOPRM1/Food Alone 10x.csv', ...
    'Data/10xOPRM1/Toy Alone 10x.csv', 'Data/10xOPRM1/Light Alone 10x.csv'); % simple task
barPlotWithPoints(longTbl, 'Task', 'Group', 'Normalized Frequency', 'Simple task');
[p, tbl, stats] = anovan(longTbl.Y, {longTbl.Group, longTbl.Task}, ...
    'model','interaction', 'varnames', {'Group','Task'});
[c, m, h, gnames] = multcompare(stats, "Dimension", [1 2]);

longTbl = buildLongTable2way(3, false, '', ...
    'Data/10xOPRM1/Food Light 10x.csv', 'Data/10xOPRM1/Toy Light 10x.csv'); % complex task
barPlotWithPoints(longTbl, 'Task', 'Group', 'Normalized Frequency', 'Complex task');
[p, tbl, stats] = anovan(longTbl.Y, {longTbl.Group, longTbl.Task}, ...
    'model','interaction', 'varnames', {'Group','Task'});
[c, m, h, gnames] = multcompare(stats, "Dimension", [1 2]);

% Not normalized t-test summary: 10xOPRM1 Rats simple and complex tasks [11/05/2025]
unpaired_ttest('Data/10xOPRM1/Food Alone 10x.csv');
unpaired_ttest('Data/10xOPRM1/Toy Alone 10x.csv');
unpaired_ttest('Data/10xOPRM1/Light Alone 10x.csv');
unpaired_ttest('Data/10xOPRM1/Food Light 10x.csv');
unpaired_ttest('Data/10xOPRM1/Toy Light 10x.csv');

% Feeding results summary: 10xOPRM1 Rats [Check again 11/05/2025]
unpaired_ttest('Data/FoodConsumption/EXT Fig. 2g Chow Sal v 10x.csv');
unpaired_ttest('Data/FoodConsumption/EXT Fig. 2h FA Apple Consumption 10X IBU WT.csv');
unpaired_ttest('Data/FoodConsumption/EXT Fig. 2i FL Apple Consumption 10X IBU WT.csv');

% 2-way ANOVA for 2xOPRM1 Rats [11/05/2025]
longTbl = buildLongTable3way(3, false, '', 'Data/2xOPRM1/FA_Controls.csv', ...
'Data/2xOPRM1/TA_Controls.csv', 'Data/2xOPRM1/LA_Controls.csv'); % simple task
barPlotWithPoints(longTbl, 'Dreadds', 'Group', 'Normalized Frequency', 'Simple task');
[p, tbl, stats] = anovan(longTbl.Y, {longTbl.Group, longTbl.Dreadds}, ...
    'model','interaction', 'varnames', {'Group','Dreadds'});
[c, m, h, gnames] = multcompare(stats, "Dimension", [1 2]);

longTbl = buildLongTable3way(3, false, '', ...
    'Data/2xOPRM1/FL_Controls.csv', 'Data/2xOPRM1/TL_Controls.csv'); % complex task
barPlotWithPoints(longTbl, 'Dreadds', 'Group', 'Normalized Frequency', 'Complex task');
[p, tbl, stats] = anovan(longTbl.Y, {longTbl.Group, longTbl.Dreadds}, ...
    'model','interaction', 'varnames', {'Group','Dreadds'});
[c, m, h, gnames] = multcompare(stats, "Dimension", [1 2]);

% % Non-parametric tests
% ix = string(longTbl.Task)=="Task1" & string(longTbl.Dreadds)=="WT";
% x  = longTbl.Y(ix & longTbl.Group=="Saline");
% y  = longTbl.Y(ix & longTbl.Group=="Ghrelin");
% wilcoxon_rs_results(x, y);

% % 2-way ANOVA for 2xOPRM1 Rats [10/17/2025]
% [p, tbl, stats] = anovan(longTbl.Y,{longTbl.Group, longTbl.Dreadds}, ...
%     'model','interaction', 'varnames',{'Group','Dreadds'});

% [c, m, h, gnames] = multcompare(stats, 'Dimension', [1 2]);


% % t-test summary: 2xOPRM1 Rats simple and complex tasks [10/29/2025]
% longTbl = buildLongTable3way(1, false, '', 'Data/2xOPRM1/FA_Controls.csv');
% longTbl = buildLongTable3way(1, false, '', 'Data/2xOPRM1/TA_Controls.csv');
% longTbl = buildLongTable3way(1, false, '', 'Data/2xOPRM1/LA_Controls.csv');

% longTbl = buildLongTable3way(1, false, '', 'Data/2xOPRM1/FL_Controls.csv');
% longTbl = buildLongTable3way(1, false, '', 'Data/2xOPRM1/TL_Controls.csv');

% dreadds1 = [repmat("WT", 1, 5)];
% dreadds2 = ["WT", "Inhibitory", "Inhibitory", "Excitatory", "Excitatory"];

% treatment1 = ["Saline", "Saline", "Ghrelin", "Saline", "Ghrelin"];
% treatment2 = [repmat("Ghrelin", 1, 3), repmat("Saline", 1, 2),];

% for d = 1:numel(dreadds1)
%     ix = string(longTbl.Dreadds)==dreadds1(d) & string(longTbl.Group)==treatment1(d);
%     iy = string(longTbl.Dreadds)==dreadds2(d) & string(longTbl.Group)==treatment2(d);
    
%     x  = longTbl.Y(ix);
%     y  = longTbl.Y(iy);
%     [~, p, ~, stats] = ttest2(x, y, 'Vartype', 'unequal');

%     fprintf("%s-%s vs %s-%s: t(%0.2f) = %.2f, p = %.3f\n", ...
%         dreadds1(d), treatment1(d), dreadds2(d), treatment2(d), ...
%         stats.df, stats.tstat, p);
% end