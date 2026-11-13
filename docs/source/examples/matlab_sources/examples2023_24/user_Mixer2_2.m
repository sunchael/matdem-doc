%set the material of the model
clear
[B,d]=fs.loadData('Mixer1.mat');%load data
d.resetStatus();%initialize model status, which records running information
d.setStandarddT();

%----------make a Box, and import the objects to the box---------
totalTime=d.SET.totalTime;
d.mo.aMUp(:)=0.5;%set the friction coefficient of element
d.mo.setShear('on');

% liquid and solid group
v0=median(d.mo.aX(d.GROUP.sample));
liquidFilter=d.mo.aX(d.GROUP.sample)<v0;% left, right
d.addGroup('liquid',d.GROUP.sample(liquidFilter));
d.addGroup('solid',d.GROUP.sample(~liquidFilter));
% liquid and solid parameter
d.mo.aMUp(d.GROUP.liquid)=0;
d.mo.SET.minR=B.ballR*0.1;% set minimum radius of liquid element
d.mo.SET.aVW=d.mo.aX*0;
d.mo.SET.aVW(d.GROUP.liquid)=1;% init volume fraction, liquid 1, solid 0
d.mo.SET.nK=50*B.ballR.^2;% transfer coefficient, 10, 50, 100
d.mo.afterBalance=fileread('TwoPhaseTransfer.m');% deal with transfer logic in afterBalance

%add monitoring points
monitorId=randperm(length(d.GROUP.sample),20);
d.addGroup('monitor',monitorId,1);
d.addRecordProp('monitor','*aX');%add a * before properties to record all elements
d.addRecordProp('monitor','*aY');
d.addRecordProp('monitor','*aZ');

%set the numerical simulation
d.mo.dT=d.mo.dT*4;
showType='aR';
d.figureNumber=d.show(showType);
d.SET.StandardBalanceNum=20;
standardBalanceTime=d.balance('Time');%time of one standard balance

%run the simulation and save the data
gpuStatus=d.mo.setGPU('auto');
totalCircle=60;

d.tic(totalCircle);
fName=['data/step/' B.name num2str(B.ballR) '-' num2str(B.distriRate) 'ZloopNum'];
standardBalanceRate=totalTime/totalCircle/standardBalanceTime;
save([fName '0.mat']);%return;
for i=1:totalCircle
    d.mo.setGPU(gpuStatus);
    d.balance('Standard',standardBalanceRate);
    % d.show(showType);
    d.setGroupId();
    d.showFilter('SlideY',0.5,1);
    d.figureNumber=d.show('SETaVW');
    drawnow

    d.clearData(1);
    save([fName num2str(i) '.mat']);
    d.calculateData();
    d.toc();%show the note of time
end
%show the trace of the monitoring points
casefs.showMonitorTrace(d,'monitor');

fs.saveData(B,2);%as the data in the folder TempModel
