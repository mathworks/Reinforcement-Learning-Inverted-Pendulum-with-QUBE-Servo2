% Copyright 2021 The MathWorks, Inc.
function policy_new = cut_unnecessary_layers_for_SAC_policy(policy)
%%
lgraph = layerGraph(policy);
lgraph = removeLayers(lgraph,{'StdFC1','StdRelu','StdFC2','StandardDeviation','GaussianParameters','loss'});
regressionlayer = regressionLayer('Name','routput');
lgraph2 = addLayers(lgraph,regressionlayer);
lgraph2 = connectLayers(lgraph2,'Mean','routput');
policy_new = assembleNetwork(lgraph2);

end

