# QUBE - Servo 2 を用いた倒立振子の強化学習制御設計及び実装


[English documents are [here](/quanserservo2_control_index_md.md)]


# 目的


本デモモデルは、Quanser社の倒立振子装置"QUBE - Servo 2"を用いて、倒立振子制御を設計している。また、プラントモデリング、制御器設計、コード生成、検証、実機試験までのワークフローを体験することができる。


# 必要なツールボックス

   -  MATLAB® 
   -  Simulink® 
   -  Stateflow® 
   -  Simscape™, Simscape Electrical™, Simscape Multibody™ 
   -  Deep Learning Toolbox™ 
   -  Reinforcement Learning Toolbox™ 
   -  MATLAB Coder, Simulink Coder, Embedded Coder® 

# 必要なサポートパッケージ

   -  MATLAB Support Package for Raspberry Pi Hardware 
   -  Simulink Support Package for Raspberry Pi Hardware 
   -  MATLAB Coder Interface for Deep Learning Libraries 
   -  MEX コンパイラ 

# 備考


強化学習のライブスクリプトでは、並列計算を行うコマンドも用意している。そのコマンドを使う場合は、Parallel Computing Toolbox™が必要となる。


# 1. PID制御


振り子が倒立した角度の近傍では、プラントモデルの線形近似が可能である。その角度近傍でフィードバック制御を行い、倒立を維持する制御を構築する。また、振り子が真下を向いている時は、その近傍で振り子の振れ止めを行う制御を構築する。




[PID制御を用いて倒立振子制御を設計](../PID/design_PID_control_ja_md.md)


# 2. 強化学習


QUBE - Serve 2 の倒立を実現させるためには、以下の要件を満たす必要がある。



   1.  <img src="https://latex.codecogs.com/gif.latex?\inline&space;0\left\lbrack&space;\deg&space;\right\rbrack"/>で静止している振り子を振動させる 
   1.  振り子を<img src="https://latex.codecogs.com/gif.latex?\inline&space;180\left\lbrack&space;\deg&space;\right\rbrack"/>近辺まで持ち上げる 
   1.  振り子の角度を<img src="https://latex.codecogs.com/gif.latex?\inline&space;180\left\lbrack&space;\deg&space;\right\rbrack"/>に維持する 
   1.  モーターの角度は<img src="https://latex.codecogs.com/gif.latex?\inline&space;\pm&space;150\left\lbrack&space;\deg&space;\right\rbrack"/>を超えてはいけない（ハードウェア制約） 



これらを満たす制御システムを実現するため、「1. PID制御」で構築したフィードバック制御器と、「振り上げ」動作を実現する強化学習器と、「モード選択」を実現する強化学習器を組み合わせたシステムを構築する。




このシステムを構築した理由としては、単一の強化学習制御器では、要件を全て満たした機能を設計することが難しいためである。どの点が難しいのか、については、以下のドキュメントに詳細をまとめている。




[深層強化学習が苦手とする動作について](../RL/RL_design_difficulty_ja_md.md)




モデルの構造については、「RL_multi_control_system.slx」を参照すること。


## 2.1. 「振り上げ」強化学習器


「振り上げ」動作を実現させるため、SACエージェントを用いて現在の観測から最適な指令値を求める方策を設計する。




[「振り上げ」強化学習器を設計](../RL/design_RL_multi_control_SAC_ja_md.md)


## 2.2. 「モード選択」強化学習器


「モード選択」強化学習器は、フィードバック制御器に入力する指令値を、固定値の<img src="https://latex.codecogs.com/gif.latex?\inline&space;180\left\lbrack&space;\deg&space;\right\rbrack"/>にするか、「振り上げ」からの指令値にするかを選択する。PPOエージェントを用いてこの機能を持つ方策を設計する。




[「モード選択」強化学習器を設計](../RL/design_RL_multi_control_PPO_ja_md.md)


# 3. コード生成と検証


強化学習エージェントから学習済みの方策を抽出し、実装用のモデルを構築する。実機試験を行う前に、そのモデルを用いてSIL、PIL検証を行い、生成コードの実行結果に問題がないことを確認する。




[強化学習を用いた制御器のコード生成と検証](../RL/SIL_PIL_for_RL_multi_control_ja_md.md)


# 4. 実機テスト


Raspberry Pi と倒立振子装置"QUBE - Servo 2"を接続し、エクスターナルモードでRaspberry Piを実行する。




[強化学習を用いた制御器の実機テスト](../RL/Exp_RL_multi_control_ja_md.md)


# 過去バージョン


過去のバージョンのファイル一式は、以下から得ることができる。ただし、過去のモデルには、古い時期に作成したサンプルしか含まれていないことに注意すること。




GitHubからクローンしている場合には、以下の該当バージョンに戻すことで、過去バージョンファイルを得ることができる。


  


R2021a: [v1.0.1](https://github.com/mathworks/Reinforcement-Learning-Inverted-Pendulum-with-QUBE-Servo2/archive/refs/tags/v1.0.1.zip)


  


* Copyright 2021 The MathWorks, Inc.*



