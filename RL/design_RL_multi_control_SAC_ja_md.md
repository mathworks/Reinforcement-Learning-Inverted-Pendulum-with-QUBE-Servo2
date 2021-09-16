# 「振り上げ」強化学習器を設計
# 初期化

```matlab:Code
doTraining = false;    % 学習を行う場合はtrueにする
doParallel = false;    % 並列実行する場合はtrueにする

set_slddVal('rl_data.sldd', 'INV_CONTROLLER_MODE', 'C_MODE.MULTI');
set_slddVal('rl_data.sldd', 'RL_DESIGN_MODE', 'D_MODE.SWING_UP');

Tc = 0.005;            % フィードバック制御の実行周期[s]
Tf = 10;               % シミュレーション終了時間[s]
Ts = Tc * 4;           % 強化学習エージェントの実行周期[s]

rng('default');

modelName = 'RL_multi_control_system';
agentBlock = [modelName '/RL_swing_up/RL_agent_swing_up'];

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
numAct = 1;
actInfo = rlNumericSpec([numAct 1],'LowerLimit',-1,'UpperLimit',1);
actInfo.Name = 'nor_v';
```



インターフェースの設定をする。



```matlab:Code
env = rlSimulinkEnv(modelName, agentBlock, obsInfo, actInfo);
% env.ResetFcn = @resetEnv;
```

# エージェントを作成


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
    'StopTrainingValue', 7000);
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
    trainingStats = train(agent_swing,env,trainOpts);
else
    load('RL_multi_trained_agent_swing_up.mat');
end
```

# シミュレーション


モデルを実行し、モデルが期待通りの動作をしていることを確認する。



```matlab:Code
open_system(modelName);
% sim(modelName);
```

  


* Copyright 2021 The MathWorks, Inc.*



