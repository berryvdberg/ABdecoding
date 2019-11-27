global RUN
addpath(RUN.fieldtrip)
subjects = find(RUN.include);
 
 session = 1;
 
for iSub = 1:length(subjects)
    disp('#==============#')
    disp(['subject    ' num2str(iSub)])
    disp('#==============#')
     
     load(fullfile('../dataPreproc', ['trialStruct' RUN.subjectID{subjects(iSub)} 'session' num2str(session) 'cue.mat']))
     load(fullfile('../dataPreproc', ['data' RUN.subjectID{subjects(iSub)} 'session' num2str(session) 'cue.mat']))
        
    artefactEEG = any([trialStruct.artheog ...
        trialStruct.artThresh],2);
     
    cfg = [];
    cfg.demean = 'yes';
    cfg.baselinewindow = [-0.2 0];
    %   cfg.toilim = [-0.2 1.5];
    cfg.lpfilter = 'yes';
    %cfg.reref = 'yes';
    %cfg.refchannel = {'RM' 'LM'};
    cfg.lpfreq = 20;
    cfg.lpfiltord =4;
    cfg.lpfiltdir = 'twopass';
    data = ft_preprocessing(cfg,data);
     
     
     
    cfg = []; cfg.keeptrials = 'yes';
    cfg.trials = ~artefactEEG & ismember(trialStruct.trialType,[106 107]);
    labels = trialStruct.trialType(cfg.trials);
    data = ft_timelockanalysis(cfg,data);
     
    %% select trials
    nperm = 50;
     cfg = [];
    cfg.timesteps = 0:0.1:1.3;
     performance = zeros(length(cfg.timesteps)-1,nperm)';
 
    for i = 1:nperm
        for j = 1:length(cfg.timesteps)-1
             
            cond1= find(ismember(labels,106));
            cond2= find(ismember(labels,107));
             
            tmp1 = randperm(length(cond1));
            tmp2 = randperm(length(cond2));        
            
            cfg.trialsTrain = [cond1(tmp1(1:300)) ;cond2(tmp2(1:300))]';
            cfg.trialsTest =  find(~ismember(1:length(labels),cfg.trialsTrain));
            cfg.labelsTrain = labels(cfg.trialsTrain);
            cfg.labelsTest = labels(cfg.trialsTest);
            cfg.timeIdx = data.time > cfg.timesteps(j) & data.time < cfg.timesteps(j+1);
            cfg.chanIdx = ismember(data.label, {'FCz','Cz','Pz'});
             
            cfg.dataTrain = data.trial(cfg.trialsTrain,cfg.chanIdx ,cfg.timeIdx );
            cfg.dataTest = data.trial(cfg.trialsTest,cfg.chanIdx ,cfg.timeIdx );
            %
            tmp = reshape(cfg.dataTrain,size(cfg.dataTrain,1),...
                size(cfg.dataTrain,2)*size(cfg.dataTrain,3));
             
             
            model = svmtrain(tmp, cfg.labelsTrain,'kernel_function','linear', 'method','LS');
             
            tmp = reshape(cfg.dataTest,size(cfg.dataTest,1),size(cfg.dataTest,2)*size(cfg.dataTest,3));
            [score] = svmclassify(model,tmp);
             
            performance(i,j) = sum((score == cfg.labelsTest) / numel(cfg.labelsTest));
            sprintf('%s  %s',num2str(i),num2str(j))
        
        end
    end
     
   
    
    
output{iSub} = performance;
     
         figure;imagesc(performance)
            xticks = linspace(1,size(performance,2),numel(cfg.timesteps));
            set(gca,'Xtick',xticks,'xticklabel',cfg.timesteps)
         
         figure;plot(squeeze(mean(performance,1)))
            xticks = linspace(1,size(performance,2),numel(cfg.timesteps));
            set(gca,'Xtick',xticks,'xticklabel',cfg.timesteps)
               
            
            
             
            
            
            
end

%% VISUALIZATION AND STATS
% to do 

gaDecoding = zeros(size(output,2),size(output{1},2));

for iSub = 1:size(output,2)
    gaDecoding(iSub,:) = squeeze(mean(output{iSub},1));
end



[~,~,~,t] = ttest(gaDecoding(:,1) - gaDecoding(:,3))

figure;plot(squeeze(mean(gaDecoding,1)))
xticks = linspace(1,size(gaDecoding,2),numel(cfg.timesteps));
set(gca,'Xtick',xticks,'xticklabel',cfg.timesteps)


            
             

