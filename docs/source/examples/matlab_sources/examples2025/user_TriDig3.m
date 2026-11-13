clear;
load('TempModel/TriDig2.mat');
d.mo.setGPU('off');%close the GPU calculation
d.getModel();%get xyz from d.mo

d.resetStatus();%initialize model status, which records running information
d.setStandarddT();%set standard step time
d.mo.dT=d.mo.dT*4;%increase the step time, used default value for high-precision computing
d.mo.mVis=d.mo.mVis*0.1;%use low viscosity

%--------------define the first motion of bucket
T1=2;
M1.Ts=[0;0.5;1]*T1;%second
M1.Xs=[0;0.4;0.6]*d.SET.bowlR;%meter
M1.Zs=[0;-0.2;0.5]*d.SET.bowlH;%meter
M1.RXZs=[0;90;180];%degree
mBucket=Tool_Motion(d.tri{2},'bucket');%define motion in d
mBucket.add(M1);
%--------------end define the first motion of bucket
%--------------define the second motion of bucket
T2=2;%time of second step
M2.Ts=[0;0.5;1]*T2;%time reset to zero due to d.resetStatus
M2.Xs=[0;0.5;1];%meter
M2.Zs=[0;0.4;0.4];%meter
M2.RXZs=[0;-90;-120];%degree
mBucket.add(M2);
%--------------end define the second motion of bucket
%--------------define the first motion of box
mBox=Tool_Motion(d.tri{2},'box');%define the motion of right side box
mBox.Ts=T1+[0,0.8]*T2;%second
mBox.Xs=[0,-1]*d.SET.bowlR/2;
%--------------end define the first motion of bucket

totalT=T1+T2;
totalCircle=40;
[time,~]=d.balance('Time');%get the real time of one standard balance
StandardBalanceRate=totalT/time/totalCircle;
gpuStatus=d.mo.setGPU('auto');

fName=['data/step/' d.name num2str(B.ballR) 'loopNum'];
save([fName '0.mat']);
for i=1:totalCircle
    d.mo.setGPU(gpuStatus);
    d.balance('Standard',StandardBalanceRate);

    d.showB=1;
    clf;
    d.showData('aR');
    d.showTri();
    d.mo.setGPU('off');
    save([fName num2str(i) '.mat']);%save data
end
%---------end numerical simulation
save(['TempModel/' B.name '3.mat'],'B','d');
save(['TempModel/' B.name '3R' num2str(B.ballR) '-distri' num2str(B.distriRate)  'aNum' num2str(d.aNum) '.mat']);