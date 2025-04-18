% Load data from the specified file path
load('data_cfos.mat'); % This is Population vectors data

% Define variables: id, x, numMice, neuron_type
id = [1;1;1;0;0;0];  % IDs indicating types (1 for GNs, 0 for ABNs)
x = [GNs;ABNs];  % Combine GC and ABN data
numMice = [nGNs; nABNs];  % Number of mice for each type
neuron_type = [sum(nGNs); sum(nABNs)];  % Total counts of each neuron type
tim = cumsum([0,4,20,4,20,4,20,0.5,1]);  % Time intervals for analysis



%Including Activity as covariate
[mixedEffectsModel, cm] = temp_analysis_correlation_matlab_size_covariate(x(:, 1:9), numMice, tim);
anova(mixedEffectsModel)