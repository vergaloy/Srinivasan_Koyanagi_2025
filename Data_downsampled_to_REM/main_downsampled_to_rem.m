load('activity_all_data.mat')
id=[2:7,9:11];

% Get imaged REM
cellfun(@(x) size(x,2)/6/60,ABNs(:,end));
cellfun(@(x) size(x,2)/10/60,GNs(:,end));

% Define variables: id, x, numMice, neuron_type
ses_id = [1;1;1;0;0;0];  % IDs indicating types (1 for GNs, 0 for ABNs)

numMice = [nGNs; nABNs];  % Number of mice for each type
neuron_type = [sum(nGNs); sum(nABNs)];  % Total counts of each neuron type
tim = cumsum([0,4,20,4,20,4,20,0.5,1]);  %

rep=1000;
R=nan(3,2,rep);
for s=progress(1:rep)
    x=get_x_equally_sample(ABNs,GNs);
    [mixedEffectsModel, cm] = temp_analysis_correlation_matlab(x(:, 1:9), numMice, tim);
    % Obtain F-scores results from ANOVA on the mixed effects model
    m=double(mixedEffectsModel.Coefficients(:,2));
    R(:,:,s)=[m(5)*24,(m(5)+m(8))*24;m(2),m(2)+m(6);m(3),m(3)+m(7)];
end

Averga=mean(R,3)
Upper_ci=prctile(R,97.5,3)
Lower_ci=prctile(R,2.5,3)


s=mean((squeeze(R(:,1,:))-squeeze(R(:,2,:)))>0,2);

%% Interactions
P_interactions=min([s,1-s],[],2)*2+1/rep

%% Main effects 

P_main_effects=mean(cat(2,squeeze(R(:,1,:)),squeeze(R(:,2,:)))>0,2)*2+1/rep
