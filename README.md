# Reinforcement Learning: training and deploying a policy to control inverted pendulum with QUBE - Servo2


【日本語の資料は[こちら](/common/quanserservo2_control_index_ja_md.md)】


# Objective


This demo models show how to design inverted pendulum controller with "QUBE - Servo 2" of Quanser. And they also show the workflow of plant modeling, control design, code generation, verification, and deployment.


# Required Toolboxes

   -  MATLAB® 
   -  Simulink® 
   -  Stateflow® 
   -  Simscape™, Simscape Electrical™, Simscape Multibody™ 
   -  Deep Learning Toolbox™ 
   -  Reinforcement Learning Toolbox™ 
   -  MATLAB Coder, Simulink Coder, Embedded Coder® 

# Required Add-Ons

   -  MATLAB Support Package for Raspberry Pi Hardware 
   -  Simulink Support Package for Raspberry Pi Hardware 
   -  MATLAB Coder Interface for Deep Learning Libraries 
   -  MEX Compiler 

# Note


Live scripts for Reinforcement Learning have some commands to train in parallel. The commands are invalid by default. If you want to use them, Parallel Computing Toolbox™ is required.


# 1. PID Control


The plant model can be linearized around the operating point where the pendulum is inverted. A feedback controller is designed to keep the pendulum inverted. On the ather hand, when the pendulum angle is downward, a steady controller is desinged to keep the pendulum right under.




[Design inverted pendulum with PID controller](/PID/design_PID_control_md.md)


# 2. Reinforcement Learning


Requirements for invert the QUBE - Serve 2:



   1.  Oscillate the pendulum whicn is steady at <img src="https://latex.codecogs.com/gif.latex?\inline&space;0\left\lbrack&space;\deg&space;\right\rbrack"/>. 
   1.  Bring up the pendulum around <img src="https://latex.codecogs.com/gif.latex?\inline&space;180\left\lbrack&space;\deg&space;\right\rbrack"/>. 
   1.  Keep the angle of pendulum at <img src="https://latex.codecogs.com/gif.latex?\inline&space;180\left\lbrack&space;\deg&space;\right\rbrack"/>. 
   1.  The motor angle does not exceed the <img src="https://latex.codecogs.com/gif.latex?\inline&space;\pm&space;150\left\lbrack&space;\deg&space;\right\rbrack"/>. (Hardware Constraints) 



In order to realize the control system satisfying above, Combine the feedback controller created in "1. PID Control", "swing up" reinforcement learing, and "mode select" reinforcement learing.




The reason for building this system is that it is difficult to design a function that meets all the requirements with a single Reinforcement Learning controller. The following document explains the details.




[What task is difficult for Deep Reinforcement Learning?](/RL/RL_design_difficulty_md.md)




For more information about the modeling, refer to the "RL_multi_control_system.slx".


## 2.1. "swing up" reinforcement learing


Design SAC agent to get the optimal policy which can swing up the pendulum with the reference for the feedback controller.




[Design "swing up" reinforcement learing](/RL/design_RL_multi_control_SAC_md.md)


## 2.2. "mode select" reinforcement learing


"mode select" reinforcement learing changes the reference for the feedback controller between constant <img src="https://latex.codecogs.com/gif.latex?\inline&space;180\left\lbrack&space;\deg&space;\right\rbrack"/> and the output of "swing up" reinforcement learing. PPO agent is used to get the policy for this "mode select" action.




[Design "mode select" reinforcement learing](/RL/design_RL_multi_control_PPO_md.md)


# 3. Code generation and verification


Extract the trained policy from the agents, and create a model for deploying controller. Then verify the code execution with SIL and PIL before doing experiment.




[Code generation and verification for the controller with RL](/RL/SIL_PIL_for_RL_multi_control_md.md)


# 4. Experiment


Connect Raspberry Pi and QUBE - Servo 2, and run the Raspberry Pi with External Mode.




[Experiment for the controller with RL](/RL/Exp_RL_multi_control_md.md)


# Old version


A set of files for past versions can be downloaded from the following link. However, the past files only contain samples created in the old days.




If you have cloned from GitHub, the past version can be obtained by reverting to the corresponding version below.


  


R2021a: [v1.0.1](https://github.com/mathworks/Reinforcement-Learning-Inverted-Pendulum-with-QUBE-Servo2/archive/refs/tags/v1.0.1.zip)


  


* Copyright 2021 The MathWorks, Inc.*



