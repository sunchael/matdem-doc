clear;
fs.randSeed(1);%change number to get different random model
%---------------------define parameters----------------------
ballRSample=0.1;%0.1 big ball, 0.03 small ball
bowlH=2;bowlR=2;
frame=[-bowlR,-bowlR,0,bowlR,bowlR,bowlH];
%---------------------end define parameters----------------------
%----------make a Box, and pack balls---------
B=obj_Box('TriDig');%declare a box object
B.ballR=ballRSample;%element radius
B.setFrame(frame);
B.buildInitialModel();

d=B.d;
d.SET.bowlR=bowlR;%record the bowl size
d.SET.bowlH=bowlH;

B.gravitySediment();
%----------end make a Box, and pack balls---------

d.showData('aR');
d.mo.setGPU('off');
save(['TempModel/' B.name '1.mat'],'B','d');
save(['TempModel/' B.name '1R' num2str(B.ballR) '-distri' num2str(B.distriRate)  'aNum' num2str(d.aNum) '.mat']);
