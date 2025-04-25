%% Analysis Pipeline: Recreate Key Calcium Imaging Processing Results from Srinivasan, Koyanagi et all 2025.

%% ------------------------------------------------------------------------
% Section 1: Load and Prepare Data
% -------------------------------------------------------------------------

% Load population vector activity data
load('Average_PV_REM');  % Contains GNs, ABNs, nGNs, nABNs

% Define groups and concatenate data
x = [GNs; ABNs];                        % Neuronal activity (rows = neurons, cols = epochs)
numMice = [nGNs; nABNs];               % Number of mice per group
tim = cumsum([0, 4, 20, 4, 20, 4, 20, 0.5, 1]);  % Time intervals for regression

% Normalize activity by total firing per neuron
Xn = x ./ sum(x, 2) * 100;

%% ------------------------------------------------------------------------
% Section 2: Plot Normalized Activity Distribution (Figure 1G)
% -------------------------------------------------------------------------

figure;
distributionPlot(Xn(1:363,:), 'histOpt', 1.1, 'divFactor', 1, 'distWidth', 0.5, ...
    'widthDiv', [2 1], 'histOri', 'left', 'color', 'b', 'showMM', 0);  % GNs

distributionPlot(gca, Xn(364:end,:), 'histOpt', 1.1, 'divFactor', 1, 'distWidth', 0.5, ...
    'widthDiv', [2 2], 'histOri', 'right', 'color', 'r', 'showMM', 0);  % ABNs
ylim([0 50]);

%% ------------------------------------------------------------------------
% Section 3: Mixed-Effects Regression on Normalized Activity (Fig 1H)
% -------------------------------------------------------------------------

tic;
[mixedEffectsModel_activty, anovaTable, pValues] = fitlmePermute(Xn(:, 1:9), numMice, tim);
toc;
disp('Mixed-Effects Model (Normalized Activity):');
disp(mixedEffectsModel_activty);
disp('ANOVA Table:');
disp(anovaTable);
disp('Random-permutation P-values:');
disp(pValues);

%% ------------------------------------------------------------------------
% Section 4: REM Effect – PV Correlation Analysis (Figures 1I–K)
% -------------------------------------------------------------------------

[mixedEffectsModel, cm] = temp_analysis_correlation_matlab(x, numMice, tim);
disp('Mixed-Effects Model (PV Correlation):');
disp(mixedEffectsModel);
F = anova(mixedEffectsModel);
disp('ANOVA Table:');
disp(F);

lab = {'A1', 'A2', 'A3', 'A4', 'A5', 'A6', 'A7', 'postS', 'REM'};

figure;
heatmap(mean(cm(:, :, 1:3), 3), 'XData', lab, 'YData', lab);
colormap(red_blue_colormap(0.1)); clim([-1 1]); title('Similarity GNs');

figure;
heatmap(mean(cm(:, :, 4:6), 3), 'XData', lab, 'YData', lab);
colormap(red_blue_colormap(0.1)); clim([-1 1]); title('Similarity ABNs');

%% ------------------------------------------------------------------------
% Section 5: Regression Including Neuron Count Covariate (Ext. Fig 2b)
% -------------------------------------------------------------------------

[mixedEffectsModel, cm] = temp_analysis_correlation_matlab_size_covariate(x, numMice, tim);
disp('Mixed-Effects Model (with size covariate):');
disp(mixedEffectsModel);
F = anova(mixedEffectsModel);
disp('ANOVA Table:');
disp(F);

%% ------------------------------------------------------------------------
% Section 6: Random Downsampling of GNs to Match ABNs (Ext. Fig 2c)
% -------------------------------------------------------------------------

rep = 1000;
R = nan(3, 2, rep);

for s = progress(1:rep)
    [GN_sur, sur_n] = random_downsample_GNs(GNs, nABNs, nGNs);
    x = [GN_sur; ABNs];
    numMice = [sur_n'; nABNs];
    [mixedEffectsModel, ~] = temp_analysis_correlation_matlab(x, numMice, tim);
    m = double(mixedEffectsModel.Coefficients(:, 2));
    R(:,:,s) = [m(5)*24, (m(5)+m(8))*24; m(2), m(2)+m(6); m(3), m(3)+m(7)];
end

Averga = mean(R, 3);
Upper_ci = prctile(R, 97.5, 3);
Lower_ci = prctile(R, 2.5, 3);
s = mean((squeeze(R(:,1,:)) - squeeze(R(:,2,:))) > 0, 2);
P_interactions = min([s, 1-s], [], 2) * 2 + 1 / rep;
P_main_effects = mean(cat(2, squeeze(R(:,1,:)), squeeze(R(:,2,:))) > 0, 2) * 2 + 1 / rep;

disp('Bootstrap Mean Effects:'); disp(Averga);
disp('95% CI Upper:'); disp(Upper_ci);
disp('95% CI Lower:'); disp(Lower_ci);
disp('Interaction P-values:'); disp(P_interactions);
disp('Main Effect P-values:'); disp(P_main_effects);

%% ------------------------------------------------------------------------
% Section 7: Equal Sampling Relative to REM Duration (Ext. Fig 2e)
% -------------------------------------------------------------------------

clear all; load('PV_all_data.mat');
rep = 1000;
numMice = [nGNs; nABNs];
tim = cumsum([0, 4, 20, 4, 20, 4, 20, 0.5, 1]);
R = nan(3, 2, rep);

for s = progress(1:rep)
    x = get_x_equally_sample(ABNs, GNs);
    [mixedEffectsModel, ~] = temp_analysis_correlation_matlab(x, numMice, tim);
    m = double(mixedEffectsModel.Coefficients(:, 2));
    R(:,:,s) = [m(5)*24, (m(5)+m(8))*24; m(2), m(2)+m(6); m(3), m(3)+m(7)];
end

Averga = mean(R, 3);
Upper_ci = prctile(R, 97.5, 3);
Lower_ci = prctile(R, 2.5, 3);
s = mean((squeeze(R(:,1,:)) - squeeze(R(:,2,:))) > 0, 2);
P_interactions = min([s, 1-s], [], 2) * 2 + 1 / rep;
P_main_effects = mean(cat(2, squeeze(R(:,1,:)), squeeze(R(:,2,:))) > 0, 2) * 2 + 1 / rep;

disp('Bootstrap Mean Effects (REM-equalized):'); disp(Averga);
disp('95% CI Upper:'); disp(Upper_ci);
disp('95% CI Lower:'); disp(Lower_ci);
disp('Interaction P-values:'); disp(P_interactions);
disp('Main Effect P-values:'); disp(P_main_effects);

%% ------------------------------------------------------------------------
% Section 8: Retrieval Effect Analysis (Ext. Fig 2f)
% -------------------------------------------------------------------------

clear all; load('Average_PV_retrieval');
tim = cumsum([0, 4, 20, 4, 20, 4, 20, 0.5, 5.5]);
[mixedEffectsModel_retrieval, ~] = temp_analysis_correlation_retrival(v, nABNs, tim);
disp('Mixed-Effects Model: Retrieval');
disp(mixedEffectsModel_retrieval);
anova_retrieval = anova(mixedEffectsModel_retrieval);
disp('ANOVA Table:');
disp(anova_retrieval);
