function [mixedEffectsModel, cm] = temp_analysis_correlation_matlab(x, numMice, tim)
% temp_analysis_correlation_matlab
%
% Perform mixed-effects linear regression on population vector (PV)
% correlations across sessions and groups.
%
% Inputs:
%   x        - matrix [neurons x sessions], PV activity data
%   numMice  - vector [nGroups x 1], number of mice in each group
%   tim      - vector [1 x nSessions], cumulative time of each session
%
% Outputs:
%   mixedEffectsModel - fitted linear mixed-effects model
%   cm                - session-wise PV correlation matrices per mouse

% Get pairwise PV correlation vectors and mouse labels
[C, N] = get_corr_by_mouse(x, numMice);

% Generate long-format table with predictors and correlation values
dataTable = generateDataTable(C, N, size(x, 2), tim);

% Define linear mixed-effects model with interaction terms
modelFormula = [
    'PV_correlation ~ Time * NeuronCategory + ' ...
    'PostS * NeuronCategory + REM * NeuronCategory + ' ...
    '(1 + PostS + REM + NeuronCategory | MouseID)'
];

% Fit the mixed-effects model
mixedEffectsModel = fitlme(dataTable, modelFormula, ...
    'DummyVarCoding', 'reference', ...
    'FitMethod', 'reml', ...
    'CovariancePattern', 'Diagonal');

% Convert PV correlation vectors into full matrices for visualization
for i = 1:size(C, 2)
    cm(:, :, i) = 1 - squareform(1 - C(:, i));  % Convert distance vector to similarity matrix
end

end


function [C, N] = get_corr_by_mouse(x, numMice)
% Computes pairwise correlations between sessions for each mouse.

k = 0;
for i = 1:length(numMice)
    % Extract data for current mouse (rows = neurons, columns = sessions)
    R = x(k + 1 : k + numMice(i), :);
    
    % Compute pairwise distances (1 - Pearson correlation) across sessions
    C(:, i) = 1 - pdist(R', 'correlation');
    
    % Store mouse index label for each correlation entry
    N(:, i) = ones(size(C, 1), 1) * i;
    
    % Update row index
    k = k + numMice(i);
end
end


function dataTable = generateDataTable(C, N, d2, tim)
% Generates a table for mixed-effects model input.
% C, N = [nPairs x nMice] matrices of correlations and mouse labels
% d2    = number of sessions
% tim   = cumulative session times

[cd1, cd2] = size(C);  % nPairs x nMice

% Mouse ID categorical variable
mouse = N;

% REM session label: only the final session is REM (value = 1)
REM = zeros(1, d2); REM(end) = 1;
REM = pdist(REM')';  % Label pairs of sessions
REM = repmat(REM, [1, cd2]);

% Post-shock session label: last two sessions are post-shock
postS = zeros(1, d2); postS(end-1:end) = 1;
postS = pdist(postS')';
postS = repmat(postS, [1, cd2]);

% Time difference between each session pair
recordingDay = pdist(tim')';
recordingDay = repmat(recordingDay, [1, cd2]);

% Neuron category: first 3 mice = group 0 (e.g., GNs), last 3 mice = group 1 (e.g., ABNs)
neuronCategory = ones(cd1, 1) * [0, 0, 0, 1, 1, 1];

% Construct the table
dataTable = table( ...
    categorical(mouse(:)), ...
    categorical(postS(:)), ...
    categorical(REM(:)), ...
    categorical(neuronCategory(:)), ...
    C(:), ...
    recordingDay(:), ...
    'VariableNames', {'MouseID', 'PostS', 'REM', 'NeuronCategory', 'PV_correlation', 'Time'} ...
);
end