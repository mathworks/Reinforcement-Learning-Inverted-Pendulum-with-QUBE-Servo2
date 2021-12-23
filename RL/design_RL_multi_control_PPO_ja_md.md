# 「モード選択」強化学習器を設計
# 初期化

```matlab:Code
doTraining = false;    % 学習を行う場合はtrueにする
doParallel = false;    % 並列実行する場合はtrueにする

set_slddVal('rl_data.sldd', 'INV_CONTROLLER_MODE', 'C_MODE.MULTI');
set_slddVal('rl_data.sldd', 'RL_DESIGN_MODE', 'D_MODE.SELECT_MODE');

Tc = 0.005;            % 比例制御器の実行周期[s]
Tf = 10;               % シミュレーション終了時間[s]
Ts = Tc * 4;           % 強化学習エージェントの実行周期[s]

rng('default');

modelName = 'RL_multi_control_system';
agentBlock = [modelName '/RL_select_mode/RL_agent_select_mode'];

% プラントモデルのパラメータを設定
plant_parameters;

% モデルの初期状態
theta0 = 0;
phi0 = 0;
dtheta0 = 0;
dphi0 = 0;

% フィードバック制御のゲイン
theta_gain   = 0.162;
dtheta_gain  = 0.0356;
phi_gain     = 40;
dphi_gain    = 2;
```

# 環境構築


プラントモデルは、Simscape Multibody™で作成した。「pendulumLib.slx」を参照。




観測（observation）を設計する。アームの角度のsin、cos、角速度、振り子の角度のsin、cos、角速度である。



```matlab:Code
numObs = 6;
obsInfo = rlNumericSpec([numObs 1]);
obsInfo.Name = 'Reference_and_sensed_signals';
```



行動（action）を設計する。



```matlab:Code
actInfo  =rlFiniteSetSpec([0, 1]);
actInfo.Name = 'nor_v';
numAct = actInfo.getNumberOfElements;
```



インターフェースの設定をする。



```matlab:Code
env = rlSimulinkEnv(modelName, agentBlock, obsInfo, actInfo);
env.ResetFcn = @resetEnv;
```

# エージェントを作成


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

# 学習の設定

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



並列化の設定



```matlab:Code
trainOpts.UseParallel = doParallel;
trainOpts.ParallelizationOptions.Mode = 'async';
trainOpts.ParallelizationOptions.StepsUntilDataIsSent = 32;
trainOpts.ParallelizationOptions.DataToSendFromWorkers = 'Experiences';
```



もし並列プールが起動していない場合は起動する。



```matlab:Code
if (trainOpts.UseParallel && isempty(gcp('nocreate')))
    parpool;
end
```

# 学習


学習結果は「agent」オブジェクトに反映されている。学習をしない場合はファイルから学習済みエージェントを読み込む。



```matlab:Code
if doTraining
    load('RL_multi_trained_agent_swing_up.mat');
    trainingStats = train(agent_select,env,trainOpts);
else
    load('RL_multi_trained_agent_swing_up.mat');
    load('RL_multi_trained_agent_select_mode.mat');
end
```

# シミュレーション


モデルを実行し、モデルが期待通りの動作をしていることを確認する。



```matlab:Code
open_system(modelName);
% sim(modelName);
```

  


* Copyright 2021 The MathWorks, Inc.*



