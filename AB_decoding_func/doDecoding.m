function [ dataOut ] = doDecoding(cfg, data)
% DODECODING does a svm based decoding analysis on EEG data 
%  use as:
% cfg = [];
% cfg.svmmethod = 'LS'
% cfg.method = %searchlight %wholebrain 
% cfg.condition =  
% cfg.timesteps = % time steps to do decoding
% cfg.channelsteps = % channels to do decoding on {''}
% cfg.freqsteps
% cfg.permutations % the number of permutations per datapoint of interest
% cfg.calcNull


cfg.chanIdx = ismember(data.label, {'FCz','Cz','Pz'});
 



for i = 1:nperm
    for j = 1:length(cfg.timesteps)-1
        
    

cond1= find(ismember(labels,106));
cond2= find(ismember(labels,107));

tmp1 = randperm(length(cond1));
tmp2 = randperm(length(cond2));

trialsTrain = [cond1(tmp1(1:300)) ;cond2(tmp2(1:300))]';
trialsTest =  find(~ismember(1:length(labels),cfg.trialsTrain));
labelsTrain = labels(cfg.trialsTrain);
labelsTest = labels(cfg.trialsTest);
timeIdx = data.time > cfg.timesteps(j) & data.time < cfg.timesteps(j+1);
dataTrain = data.trial(cfg.trialsTrain,cfg.chanIdx ,cfg.timeIdx );
dataTest = data.trial(cfg.trialsTest,cfg.chanIdx ,cfg.timeIdx );

%
tmp = reshape(dataTrain,size(cfg.dataTrain,1),...
    size(cfg.dataTrain,2)*size(cfg.dataTrain,3));


model = svmtrain(tmp, cfg.labelsTrain,'kernel_function','linear', 'method','LS');

tmp = reshape(cfg.dataTest,size(cfg.dataTest,1),size(cfg.dataTest,2)*size(cfg.dataTest,3));
[score] = svmclassify(model,tmp);

performance(i,j) = sum((score == cfg.labelsTest) / numel(cfg.labelsTest));
sprintf('%s  %s',num2str(i),num2str(j))

    end 
end



% bookkeeping here
dataOut.data = performance
dataOut.label = cfg.channelsteps
dataOut.time = cfg.timesteps
dataOut.

end

