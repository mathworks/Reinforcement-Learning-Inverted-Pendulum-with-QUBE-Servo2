# Design "mode select" reinforcement learing
# Initialize

```matlab:Code
doTraining = false;    % Set "true" for learning.
doParallel = false;    % Set "true" for parallel learning.

set_slddVal('rl_data.sldd', 'INV_CONTROLLER_MODE', 'C_MODE.MULTI');
set_slddVal('rl_data.sldd', 'RL_DESIGN_MODE', 'D_MODE.SELECT_MODE');

Tc = 0.005;            % Time step for feedback controller. [s]
Tf = 10;               % Simulation stop time. [s]
Ts = Tc * 4;           % Time step for Reinforcement Learning agent. [s]

rng('default');

modelName = 'RL_multi_control_system';
agentBlock = [modelName '/RL_select_mode/RL_agent_select_mode'];

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
actInfo  =rlFiniteSetSpec([0, 1]);
actInfo.Name = 'nor_v';
numAct = actInfo.getNumberOfElements;
```



Define other interfaces.



```matlab:Code
env = rlSimulinkEnv(modelName, agentBlock, obsInfo, actInfo);
env.ResetFcn = @resetEnv;
```

# Define agent


Critic



```matlab:Code
criticLayerSizes = [400 300];

criticNetwork = [
    featureInputLayer(numObs,'Normalization','none','Name','observation')
    fullyConnectedLayer(criticLayerSizes(1),'Name','CriticFC1', ...
    'Weights',sqrt(2/numObs)*(rand(criticLayerSizes(1),numObs)-0.5), ...
    'Bias',1e-3*ones(criticLayerSizes(1),1))
    reluLayer('Name','CriticRelu1')
    fullyConnectedLayer(criticLayerSizes(2),'Name','CriticFC2', ...
    'Weights',sqrt(2/criticLayerSizes(1))*(rand(criticLayerSizes(2),criticLayerSizes(1))-0.5), ...
    'Bias',1e-3*ones(criticLayerSizes(2),1))
    reluLayer('Name','CriticRelu2')
    fullyConnectedLayer(1,'Name','CriticOutput', ...
    'Weights',sqrt(2/criticLayerSizes(2))*(rand(1,criticLayerSizes(2))-0.5), ...
    'Bias',1e-3)];
```



Create the critic representation.



```matlab:Code
criticOpts = rlRepresentationOptions('LearnRate',1e-4);
critic = rlValueRepresentation(criticNetwork,obsInfo,'Observation',{'observation'},criticOpts);
```



Actor



```matlab:Code
actorLayerSizes = [400 300];

actorNetwork = [
    imageInputLayer([numObs 1 1],'Normalization','none','Name','observation')
    fullyConnectedLayer(actorLayerSizes(1), 'Name', 'ActorFC1', ...
    'Weights',2/sqrt(numObs)*(rand(actorLayerSizes(1),numObs)-0.5), ...
    'Bias',2/sqrt(numObs)*(rand(actorLayerSizes(1),1)-0.5))
%     reluLayer('Name', 'ActorRelu1')
    tanhLayer('Name', 'midTanh5')
    fullyConnectedLayer(actorLayerSizes(2), 'Name', 'ActorFC2', ...
    'Weights',2/sqrt(actorLayerSizes(1))*(rand(actorLayerSizes(2),actorLayerSizes(1))-0.5), ...
    'Bias',2/sqrt(actorLayerSizes(1))*(rand(actorLayerSizes(2),1)-0.5))
%     reluLayer('Name', 'ActorRelu2')
    tanhLayer('Name', 'midTanh6')
    fullyConnectedLayer(numAct, 'Name', 'ActorFC3', ...
    'Weights',2*5e-3*(rand(numAct,actorLayerSizes(2))-0.5), ...
    'Bias',2*5e-3*(rand(numAct,1)-0.5))
    tanhLayer('Name','ActorTanh1')
    ];

actorOpts = rlRepresentationOptions('LearnRate',1e-04,'GradientThreshold',1);

actor = rlStochasticActorRepresentation(actorNetwork,obsInfo,actInfo,...
    'Observation',{'observation'},actorOpts);
```



Agent



```matlab:Code
agentOpts = rlPPOAgentOptions(...
    'SampleTime',Ts,...
    'DiscountFactor',0.99,...
    'ExperienceHorizon', floor(Tf/Ts), ...
    'MiniBatchSize', floor(Tf/Ts), ...
    'EntropyLossWeight', 1e-4, ...
    'UseDeterministicExploitation', true);

agent_select = rlPPOAgent(actor, critic, agentOpts);
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
    'StopTrainingValue', 430);
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
    load('RL_multi_trained_agent_swing_up.mat');
    trainingStats = train(agent_select,env,trainOpts);
else
    load('RL_multi_trained_agent_swing_up.mat');
    load('RL_multi_trained_agent_select_mode.mat');
end
```

# Simulation


Run and check that the model can control the pendulum as expected.



```matlab:Code
open_system(modelName);
% sim(modelName);
```

  


* Copyright 2021 The MathWorks, Inc.*



