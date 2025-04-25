function [mixedEffectsModel,cm]=temp_analysis_correlation_retrival(x,numMice,tim)
% temp_analysis_correlation_matlab(x(:, 1:9),numMice)
[d1,d2]=size(x);
[C,N]=get_corr_by_mouse(x,numMice);
dataTable = generateDataTable(C,N,d2,tim);
%%

modelFormula=['PV_correlation~Time +PostS+Retrival' ...
    '+(PostS+Retrival|MouseID)'];

mixedEffectsModel = fitlme(dataTable, modelFormula, 'DummyVarCoding', 'reference', ...
    'FitMethod', 'reml','CovariancePattern', 'Diagonal');


for i=1:size(C,2)
    cm(:,:,i)=1-squareform(1-C(:,i));
end



end


function [C,N]=get_corr_by_mouse(x,numMice)
k=0;
for i=1:size(numMice,1)
    % xr = get_spearman_residuals(x(k+1:k+numMice(i),:));
    % R=xr-mean(xr,2);
    R=x(k+1:k+numMice(i),:);
    C(:,i)=1-pdist(R','correlation');
    k=k+numMice(i);
    N(:,i)=ones(size(C,1),1)*i;
end

end


function dataTable = generateDataTable(C,N,d2,tim)
% Generate a table from input data
[cd1,cd2]=size(C);
% Generate predictor variables
mouse=N;

Retrival=zeros(1,d2); Retrival(end)=1;Retrival=pdist(Retrival')';Retrival=repmat(Retrival,[1,cd2]);  % Wake (0) or REM sleep (1) session indicator

postS=zeros(1,d2); postS(end-1:end)=1;postS=pdist(postS')';postS=repmat(postS,[1,cd2]); % Pre (0) or Post (1) shock session indicator

recordingDay=pdist(tim')';recordingDay=repmat(recordingDay,[1,cd2]);

dataTable = table(categorical(mouse(:)), ...
    categorical(postS(:)), categorical(Retrival(:)),C(:),recordingDay(:), ...
    'VariableNames',{'MouseID','PostS','Retrival','PV_correlation','Time'});
end

