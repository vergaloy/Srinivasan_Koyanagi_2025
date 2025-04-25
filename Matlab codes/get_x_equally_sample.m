function x = get_x_equally_sample(ABNs, GNs)
% This function equalizes sample size between groups (ABNs and GNs)
% by randomly sampling columns from each neuron's data so that each
% group contributes the same number of samples as the REM group.
%
% Inputs:
%   ABNs - cell array of data from ABN group (e.g., N cells x 1, each cell contains [n x T] matrix)
%   GNs  - cell array of data from GN group
%
% Output:
%   x    - matrix of averaged samples, one per neuron, equalized across groups

% Concatenate the two input groups into a single cell array
T = [GNs; ABNs];

x = [];
for i = 1:size(T, 1)
    % Get the number of timepoints in the REM (reference) group (last column of each row)
    pnt = size(T{i, end}, 2);  % Assume REM is always the last column
    
    % Create a function that samples 'pnt' columns from the input matrix,
    % then averages across the sampled columns (column-wise mean)
    fun = @(x) mean(datasample(x, pnt, 2, 'Replace', false), 2);
    
    % Apply the function to each condition in the current row (e.g., Wake, NREM, REM)
    % using cellfun and collect the resulting column vectors
    m = cellfun(fun, T(i, :), 'UniformOutput', false);
    
    % Concatenate the results horizontally and add to output
    x = [x; cat(2, m{:})];
end