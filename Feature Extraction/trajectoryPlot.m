% Author: Atanu Giri
% Date: 11/19/2022
% This function generates plots of trajectory when id is provided. The plot
% is normalized for uniform representation of all trials.

%% This function call coordinateNormalization and mazeMethods functions.

function h = trajectoryPlot(id)
% close all; clc;
% id = 102377;
% make connection with database
datasource = 'live_database';
conn = database(datasource,'postgres','1234');
% write query
query = sprintf("SELECT id, subjectid, trialname, referencetime, " + ...
    "playstarttrialtone, mazenumber, feeder, coordinatetimes2, xcoordinates2, " + ...
    "ycoordinates2 FROM live_table WHERE id = %d;", id);
subject_data = fetch(conn,query);

% convert all table entries from string to usable format
subject_data.playstarttrialtone = str2double(subject_data.playstarttrialtone);
subject_data.feeder = str2double(subject_data.feeder);
% remove space from mazenumber
subject_data.mazenumber = char(lower(strrep(subject_data.mazenumber,' ','')));

% Accessing PGArray data as double
for column = size(subject_data,2) - 2:size(subject_data,2)
    stringAllRows = string(subject_data.(column));
    regAllRows = regexprep(stringAllRows,'{|}','');
    splitAllRows = split(regAllRows,',');
    doubleData = str2double(splitAllRows);
    subject_data.(column){1} = doubleData;
end

% includes the data before playstarttrialtone
rawData = table(subject_data.coordinatetimes2{1}, subject_data.xcoordinates2{1}, ...
        subject_data.ycoordinates2{1}, 'VariableNames',{'t','X','Y'});

% remove nan entries
validIdx = all(isfinite(rawData{:,:}),2);
cleanedData = rawData(validIdx,:);

% invoke coordinateNormalization function to normalize the coordinates
[normX, normY] = coordinateNormalization(cleanedData.X, cleanedData.Y, id);
cleanedDataWithTone = table(cleanedData.t, normX, normY, 'VariableNames',{'t','X','Y'});

% set playstarttrialtone and exclude the data before playstarttrialtone
startingCoordinatetimes = subject_data.playstarttrialtone;
xNormalized = cleanedDataWithTone.X(cleanedDataWithTone.t >= startingCoordinatetimes);
yNormalized = cleanedDataWithTone.Y(cleanedDataWithTone.t >= startingCoordinatetimes);

% plot normalized data
h = figure;
% p1 = plot(xWithTone,yWithTone,'Color',[0.9 0.7 0.1],'LineWidth',1.5);
hold on;
p2 = plot(xNormalized,yNormalized,'b','MarkerSize',10,'LineWidth',1.5);
validX = xNormalized(~isnan(xNormalized));
validY = yNormalized(~isnan(xNormalized));
mrkr1 = plot(validX(1),validY(1),'g.','MarkerSize',30);
mrkr2 = plot(validX(end),validY(end),'r.','MarkerSize',30);
% set figure limit
maze = {'maze2','maze1','maze3','maze4'};
figureLimit = {{[-0.2 1.2],[-0.2 1.2]},{[-1.2 0.2],[-0.2 1.2]}, ...
    {[-1.2 0.2],[-1.2 0.2]},{[-0.2 1.2],[-1.2 0.2]}};
% get the index in maze array
mazeIndex = find(ismember(maze,subject_data.mazenumber));
feeder = subject_data.feeder;
xlim(figureLimit{mazeIndex}{1}); ylim(figureLimit{mazeIndex}{2});
% shade feeder zones by calling mazeMethods
mazeMethods(mazeIndex,feeder);
% gray patch
grayPatch = patch(nan,nan,'k');grayPatch.FaceColor = [0.3 0.3 0.3];
grayPatch.FaceAlpha = 0.3;grayPatch.EdgeColor = "none";
% yellow patch
yellowPatch = patch(nan,nan,'k');yellowPatch.FaceColor = [1 1 0];
yellowPatch.FaceAlpha = 0.3;yellowPatch.EdgeColor = "none";
% red patch
redPatch = patch(nan,nan,'k');redPatch.FaceColor = [1 0 0];
redPatch.FaceAlpha = 0.2;redPatch.EdgeColor = "none";

% add legend
% legend([p1,p2,mrkr1,mrkr2,grayPatch,yellowPatch,redPatch], ...
%     {'movement before tone','trajectory','initial location','final location', ...
%     'feeders','offer','central zone'},'Location','best','Interpreter','latex');

legend([p2,mrkr1,mrkr2,grayPatch,yellowPatch,redPatch], ...
    {'trajectory','initial location','final location', ...
    'feeders','offer','central zone'},'Location','best','Interpreter','latex');

xlabel('x(Normalized)',Interpreter='latex',FontSize=14);
ylabel('y(Normalized)',Interpreter='latex',FontSize=14);

% title of graph
sgtitle(sprintf('trajectory id:%d',id));
fig_name = sprintf('trajectory id_%d',id);
print(h,fig_name,'-dpng','-r400');
% savefig(h,sprintf('%s.fig',fig_name));
end