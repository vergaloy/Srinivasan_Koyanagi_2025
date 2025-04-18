load('main_data');

numMice = nABNs;  % Number of mice for each type
neuron_type = sum(nABNs);  % Total counts of each neuron type
tim = cumsum([0,4,20,4,20,4,20,0.5,5.5]);  %

[mixedEffectsModel, cm] = temp_analysis_correlation_retrival(v, numMice, tim);
mixedEffectsModel
anova(mixedEffectsModel)
