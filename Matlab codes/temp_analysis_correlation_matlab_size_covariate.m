function [mixedEffectsModel, cm] = temp_analysis_correlation_matlab_size_covariate(x, numMice, tim)
% Performs mixed-effects regression on pairwise PV correlation data
% Includes the number of neurons (size) per mouse as a fixed-effect covariate
%
% Inputs:
%   x        - neuron activity matrix [neurons x sessions]
%   numMice  - vector [nGroups x 1] with number of neurons per mouse
%   tim      - vector with cumulative time points for each session
%
% Outputs:
%   mixedEffectsModel - fitted linear mixed-effects model object
%   cm                - reconstructed PV correlation matrices for each mouse

% Get size of the input matrix
[d1, d2] = size(x);

% Compute pairwise PV correlation vectors and corresponding mouse IDs
[C, N] = get_corr_by_mouse(x, numMice);

% Generate a long-format data table for the mixed model
dataTable = generateDataTable(C, N, d2, tim, numMice);

% Define mixed-effects model formula
% Includes fixed effects: time × group, post-shock × group, REM × group, and neuron size
% Includes random intercept and slopes per mouse
modelFormula = [ ...
    'PV_correlation ~ Time * NeuronCategory + ' ...
    'PostS * NeuronCategory + REM * NeuronCategory + size + ' ...
    '(1 + PostS + REM + NeuronCategory | MouseID)' ...
    ];

% Fit the mixed-effects model
mixedEffectsModel = fitlme(dataTable, modelFormula, ...
    'DummyVarCoding', 'reference', ...
    'FitMethod', 'reml', ...
    'CovariancePattern', 'Diagonal');

% Reconstruct full correlation matrices (symmetrical) from 1D pdist output
for i = 1:size(C, 2)
    cm(:, :, i) = 1 - squareform(1 - C(:, i));
end
end

function [C, N] = get_corr_by_mouse(x, numMice)
% Compute pairwise PV correlation distances for each mouse

k = 0;  % Row index offset
for i = 1:length(numMice)
    % Extract rows (neurons) for the i-th mouse
    R = x(k + 1 : k + numMice(i), :);

    % Compute 1 - Pearson correlation distance across session vectors
    C(:, i) = 1 - pdist(R', 'correlation');

    % Store corresponding mouse index for each distance
    N(:, i) = ones(size(C, 1), 1) * i;

    % Update offset
    k = k + numMice(i);
end
end

function dataTable = generateDataTable(C, N, d2, tim, numMice)
% Build the long-format data table for regression
% Includes mouse ID, session condition flags, group labels, and covariates

[cd1, cd2] = size(C);  % cd1 = # of pairwise session combinations

% Mouse ID labels
mouse = N;

% Centered neuron count per mouse as covariate
sz = repmat(numMice', [cd1, 1]);
sz = sz(:);
sz = sz - mean(sz);  % center around mean

% REM indicator: only the last session is REM
REM = zeros(1, d2); REM(end) = 1;
REM = pdist(REM')'; REM = repmat(REM, [1, cd2]);

% Post-shock indicator: last two sessions are post-shock
postS = zeros(1, d2); postS(end-1:end) = 1;
postS = pdist(postS')'; postS = repmat(postS, [1, cd2]);

% Continuous time difference (between sessions)
recordingDay = pdist(tim')'; recordingDay = repmat(recordingDay, [1, cd2]);

% Neuron group labels (0 = GN, 1 = ABN), fixed for 3 GN and 3 ABN mice
neuronCategory = ones(cd1, 1) * [0, 0, 0, 1, 1, 1];

% Assemble the full table
dataTable = table( ...
    categorical(mouse(:)), ...
    categorical(postS(:)), ...
    categorical(REM(:)), ...
    categorical(neuronCategory(:)), ...
    C(:), ...
    recordingDay(:), ...
    sz(:), ...
    'VariableNames', {'MouseID', 'PostS', 'REM', 'NeuronCategory', 'PV_correlation', 'Time', 'size'} ...
    );
end