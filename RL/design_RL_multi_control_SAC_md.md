# Design "swing up" reinforcement learing
# Initialize

```matlab:Code
doTraining = false;    % Set "true" for learning.
doParallel = false;    % Set "true" for parallel learning.

set_slddVal('rl_data.sldd', 'INV_CONTROLLER_MODE', 'C_MODE.MULTI');
set_slddVal('rl_data.sldd', 'RL_DESIGN_MODE', 'D_MODE.SWING_UP');

Tc = 0.005;            % Time step for feedback controller. [s]
Tf = 10;               % Simulation stop time. [s]
Ts = Tc * 4;           % Time step for Reinforcement Learning agent. [s]

rng('default');

modelName = 'RL_multi_control_system';
agentBlock = [modelName '/RL_swing_up/RL_agent_swing_up'];

% Define plant parameters
plant_parameters;

% Initial condition
theta0 = 0;
phi0 = 0;
dtheta0 = 0;
dphi0 = 0;

% Gains for feedback controller.
theta_gain   = 0.162;
dtheta_gain  = 0.0356;
phi_gain     = 40;
dphi_gain    = 2;
```

# Environment


Plant model is created with Simscape Multibody™. Refer to the "pendulumLib.slx".




Define observation. Observations are sine, cosine of DC motor angle, sine, cosine of pendulum angle, and angular speed of the DC motor and pendulum.



```matlab:Code
numObs = 6;
obsInfo = rlNumericSpec([numObs 1]);
obsInfo.Name = 'Reference_and_sensed_signals';
```



Define action.  



```matlab:Code
numAct = 1;
actInfo = rlNumericSpec([numAct 1],'LowerLimit',-1,'UpperLimit',1);
actInfo.Name = 'nor_v';
```



Define other interfaces.



```matlab:Code
env = rlSimulinkEnv(modelName, agentBlock, obsInfo, actInfo);
% env.ResetFcn = @resetEnv;
```

# Define agent


Critic



```matlab:Code
statePath1 = [
    featureInputLayer(numObs,'Normalization','none','Name','observation')
    fullyConnectedLayer(400,'Name','CriticStateFC1')
    reluLayer('Name','CriticStateRelu1')
    fullyConnectedLayer(300,'Name','CriticStateFC2')
    ];
actionPath1 = [
    featureInputLayer(numAct,'Normalization','none','Name','action')
    fullyConnectedLayer(300,'Name','CriticActionFC1')
    ];
commonPath1 = [
    additionLayer(2,'Name','add')
    reluLayer('Name','CriticCommonRelu1')
    fullyConnectedLayer(1,'Name','CriticOutput')
    ];

criticNet = layerGraph(statePath1);
criticNet = addLayers(criticNet,actionPath1);
criticNet = addLayers(criticNet,commonPath1);
criticNet = connectLayers(criticNet,'CriticStateFC2','add/in1');
criticNet = connectLayers(criticNet,'CriticActionFC1','add/in2');

criticOptions = rlRepresentationOptions('Optimizer','adam','LearnRate',1e-3,...
    'GradientThreshold',1,'L2RegularizationFactor',2e-4);
critic1 = rlQValueRepresentation(criticNet,obsInfo,actInfo,...
    'Observation',{'observation'},'Action',{'action'},criticOptions);
critic2 = rlQValueRepresentation(criticNet,obsInfo,actInfo,...
    'Observation',{'observation'},'Action',{'action'},criticOptions);
```



Actor



```matlab:Code
statePath = [
    featureInputLayer(numObs,'Normalization','none','Name','observation')
    fullyConnectedLayer(400, 'Name','commonFC1')
    reluLayer('Name','CommonRelu')];
meanPath = [
    fullyConnectedLayer(300,'Name','MeanFC1')
    reluLayer('Name','MeanRelu')
    fullyConnectedLayer(numAct,'Name','Mean')
    ];
stdPath = [
    fullyConnectedLayer(300,'Name','StdFC1')
    reluLayer('Name','StdRelu')
    fullyConnectedLayer(numAct,'Name','StdFC2')
    softplusLayer('Name','StandardDeviation')];

concatPath = concatenationLayer(1,2,'Name','GaussianParameters');

actorNetwork = layerGraph(statePath);
actorNetwork = addLayers(actorNetwork,meanPath);
actorNetwork = addLayers(actorNetwork,stdPath);
actorNetwork = addLayers(actorNetwork,concatPath);
actorNetwork = connectLayers(actorNetwork,'CommonRelu','MeanFC1/in');
actorNetwork = connectLayers(actorNetwork,'CommonRelu','StdFC1/in');
actorNetwork = connectLayers(actorNetwork,'Mean','GaussianParameters/in1');
actorNetwork = connectLayers(actorNetwork,'StandardDeviation','GaussianParameters/in2');

actorOpts = rlRepresentationOptions('LearnRate',1e-04,'GradientThreshold',1);

actor = rlStochasticActorRepresentation(actorNetwork,obsInfo,actInfo,...
    'Observation',{'observation'},actorOpts);
```



Agent



```matlab:Code
agentOpts = rlSACAgentOptions(...
    'SampleTime',Ts,...
    'TargetSmoothFactor',1e-3,...
    'ExperienceBufferLength',1e6,...
    'DiscountFactor',0.99,...
    'MiniBatchSize',128, ...
    "UseDeterministicExploitation", true);

agent_swing = rlSACAgent(actor,[critic1, critic2],agentOpts);
```

# Learning options

```matlab:Code
maxEpisodes = 10000;
maxSteps = floor(Tf/Ts);
trainOpts = rlTrainingOptions(...
    'MaxEpisodes',maxEpisodes,...
    'MaxStepsPerEpisode',maxSteps,...
    'ScoreAveragingWindowLength',50,...
    'Verbose',false,...
    'Plots','training-progress',...
    'StopTrainingCriteria','AverageReward',...
    'StopTrainingValue', 7000);
%     'SaveAgentCriteria','EpisodeReward',...
%     'SaveAgentValue', 0);
```



Define parallelization.



```matlab:Code
trainOpts.UseParallel = doParallel;
trainOpts.ParallelizationOptions.Mode = 'async';
trainOpts.ParallelizationOptions.StepsUntilDataIsSent = 32;
trainOpts.ParallelizationOptions.DataToSendFromWorkers = 'Experiences';
```



Start parpool if there is no pool.



```matlab:Code
if (trainOpts.UseParallel && isempty(gcp('nocreate')))
    parpool;
end
```

# Learning


After learning, the result is in agent object. If it doesn't do training, load the trained data from the file.



```matlab:Code
if doTraining
    trainingStats = train(agent_swing,env,trainOpts);
else
    load('RL_multi_trained_agent_swing_up.mat');
end
```

# Simulation


Run and check that the model can control the pendulum as expected.



```matlab:Code
open_system(modelName);
% sim(modelName);
```

  


* Copyright 2021 The MathWorks, Inc.*



