# Experiment for the controller with RL
# Initialize

```matlab:Code
model_name = 'RL_multi_control_system_Exp';

set_slddVal('rl_data.sldd', 'RL_DESIGN_MODE', 'D_MODE.SELECT_MODE');

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

# Extract policies from the trained agents

```matlab:Code
load('RL_multi_trained_agent_swing_up.mat');
load('RL_multi_trained_agent_select_mode.mat');

projectObj = currentProject;
cd(projectObj.RootFolder + filesep + "Source");
generatePolicyFunction(agent_swing, 'MATFileName', "policy_swing.mat");
generatePolicyFunction(agent_select, 'MATFileName', "policy_select.mat");
cd(projectObj.RootFolder);
```



Trim the layers of SAC policy.



```matlab:Code
load("policy_swing.mat");
policy = cut_unnecessary_layers_for_SAC_policy(policy);
cd(projectObj.RootFolder + filesep + "Source");
save("policy_swing.mat", 'policy');
cd(projectObj.RootFolder);
```



Chenge the model configuration for experiment.



```matlab:Code
load_system('RL_multi_controller_deploy');
load_system('PID_controller');
setActiveConfigSet('RL_multi_controller_deploy', 'Config_raspi');
setActiveConfigSet('PID_controller', 'Config_raspi');
open_system(model_name);
save_system(model_name, [], 'SaveDirtyReferencedModels', true);
```

# Experiment


Run the model and check the results.


  


* Copyright 2021 The MathWorks, Inc.*



