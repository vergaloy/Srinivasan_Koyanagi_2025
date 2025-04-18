% Load data from the specified file path
load('data_cfos.mat'); % This is Population vectors data

% Define variables: id, x, numMice, neuron_type
id = [1;1;1;0;0;0];  % IDs indicating types (1 for GNs, 0 for ABNs)
x = [GNs;ABNs];  % Combine GC and ABN data
numMice = [nGNs; nABNs];  % Number of mice for each type
neuron_type = [sum(nGNs); sum(nABNs)];  % Total counts of each neuron type
tim = cumsum([0,4,20,4,20,4,20,0.5,1]);  % Time intervals for analysis

% Normalize the data as percentages
Xn = x ./ sum(x, 2) * 100;

%% Plot mean activities for Fig 1G
figure;
% Plot distribution of normalized activities for GNs
distributionPlot(Xn(1:363, 1:9), 'histOpt', 1.1, 'divFactor', 1, 'distWidth', 0.5, ...
    'widthDiv', [2 1], 'histOri', 'left', 'color', 'b', 'showMM', 0)

% Plot distribution of normalized activities for ABNs
distributionPlot(gca, Xn(364:end, 1:9), 'histOpt', 1.1, 'divFactor', 1, 'distWidth', 0.5, ...
    'widthDiv', [2 2], 'histOri', 'right', 'color', 'r', 'showMM', 0)

% Set y-axis limit
ylim([0 50])

% Perform Mixed effect linear regression with random permutations for Fig 1G-H
tic;
[mixedEffectsModel_activty, anovaTable, pValues] = fitlmePermute(Xn(:, 1:9), numMice, tim);
toc;
anovaTable
fprintf(1, 'Random-permutation P-values:\n');
pValues
drawnow;

% Perform Mixed effect linear regression for the PV correlation for Fig
% 1J-K
[mixedEffectsModel, cm] = temp_analysis_correlation_matlab(x(:, 1:9), numMice, tim);

% Obtain F-scores results from ANOVA on the mixed effects model.
% Statistical results Fig 1K
F = anova(mixedEffectsModel)

% Labels for the heatmap
lab = {'A1', 'A2', 'A3', 'A4', 'A5', 'A6', 'A7', 'postS', 'REM'};

% Data Fig 1I: PV correlation matrix for GNs
figure;
h1 = heatmap(mean(cm(:,:,1:3), 3), 'XData', lab, 'YData', lab);
thr = 0.1;
colormap(h1, red_blue_colormap(thr)); clim([-1 1]); title('Similarity GNs');

% Data Fig 1I: PV correlation matrix for ABNs
figure;
h1 = heatmap(mean(cm(:,:,4:6), 3), 'XData', lab, 'YData', lab);
thr = 0.1;
colormap(h1, red_blue_colormap(thr)); clim([-1 1]); title('Similarity ABNs');
