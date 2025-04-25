function [mixedEffectsModel, anovaTable, pValues] = fitlmePermute(inputData, numMice,tim)
    % This function fits a linear mixed-effects model with random permutation testing.

    % Number of permutations for statistical testing
    numPermutations = 1000;

    % Generate a table from the input data and mouse information
    dataTable = generateDataTable(inputData, numMice, tim);

    % Define the formula for the linear mixed-effects model
    modelFormula = 'Activity ~ Time*NeuronCategory + PostS*NeuronCategory + REM*NeuronCategory + (Time*NeuronCategory + PostS*NeuronCategory + REM*NeuronCategory | MouseID)';

    % Extract the number of recording sessions
    numSessions = size(inputData, 2);

    % Fit the linear mixed-effects model with REML estimation
    mixedEffectsModel = fitlme(dataTable, modelFormula, 'DummyVarCoding', 'reference','CovariancePattern', 'Diagonal','FitMethod','REML');
    % Obtain F-scores for each term in the model from ANOVA table
    anovaTable = anova(mixedEffectsModel);
    fScores = double(anovaTable(:, 2));  % Remove first row (Sum of Squares)

    % Extract residuals from the fitted model
    res= reshape(residuals(mixedEffectsModel), [], numSessions);

    % Pre-allocate memory for storing F-scores from permutations
    fScoresPermute = zeros(length(fScores), numPermutations);

    % Perform parallel loop for permutation testing
    parfor i = 1:numPermutations
        % Shuffle residuals to create surrogate data
        shuffledResiduals = reshape(res(randperm(numel(res))),size(res));

        % Generate a table from shuffled data for permutation test
        shuffledDataTable = generateDataTable(shuffledResiduals, numMice,tim);

        % Fit the model to the shuffled data (surrogate data)
        surrogateModel = fitlme(shuffledDataTable, modelFormula, 'DummyVarCoding', 'reference','CovariancePattern', 'Diagonal');

        % Get F-scores from the ANOVA table of the surrogate model
        surrogateAnovaTable = anova(surrogateModel);
        fScoresPermute(:, i) = double(surrogateAnovaTable(:, 2));
    end

    % Calculate p-values by comparing F-scores from the real model to the permutation distribution
    pValues = (sum(fScoresPermute - fScores > 0, 2) + 1) / (size(fScoresPermute, 2) + 1);
end


function dataTable = generateDataTable(inputData, numMice, tim)
    % Generate a table from input data
    
    % Categorize neuron types (ABN or GN based on mouse group)
    neuron_type=[sum(numMice(1:3));sum(numMice(4:6))];

    % Extract table dimensions from input data
    session_n=size(inputData,2);
    neuron_n=size(inputData,1);

    % Generate predictor variables
    mouse=repelem(1:length(numMice),numMice)'*ones(1,session_n);
    n_id=(1:neuron_n)'*ones(1,session_n);
    REM=ones(neuron_n,1)*[zeros(1,8),1]; % Wake (0) or REM sleep (1) session indicator
    postS=ones(neuron_n,1)*[zeros(1,7),1,1]; % Pre (0) or Post (1) shock session indicator
    recordingDay=ones(neuron_n,1)*tim;
    neuronCategory=repelem(1:length(neuron_type),neuron_type)'*ones(1,session_n)-1; % Categorical ABN/GN

    % Create a table with relevant variables
    dataTable = table(categorical(mouse(:)),categorical(n_id(:)), ...
        categorical(postS(:)), categorical(REM(:)),categorical(neuronCategory(:)),inputData(:),recordingDay(:), ...
        'VariableNames',{'MouseID','NeuronID','PostS','REM','NeuronCategory','Activity','Time'});
end
