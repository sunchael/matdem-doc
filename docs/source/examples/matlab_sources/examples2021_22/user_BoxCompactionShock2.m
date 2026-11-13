%（1）名义振幅：分别取0.6mm、1.0mm、1.5mm、2.0mm；
%（2）振动频率：分别选取30Hz、35Hz、40Hz、45Hz、50Hz；
%（3）静压力：分别为6.73kPa、10.55kPa、14.37kPa、18.26kPa；
%（4）振动压实时间：依据规范，分别测试1min、2min、3min、4min、
clear;
load('TempModel/BoxCompactionShock1.mat');
d.calculateData();
d.mo.setGPU('off');
B.setUIoutput();
d=B.d;
d.getModel();%d.setModel();%reset the initial status of the model
d.resetStatus();%initialize model status, which records running information

[~,topId]=mfs.splitGroup(d,'sample','aZ',0.2);
d.delElement(topId);
topLimit=max(d.mo.aZ(d.GROUP.sample)+d.mo.aR(d.GROUP.sample));
dZ=topLimit-min(d.mo.aZ(d.GROUP.topPlaten)-d.mo.aR(d.GROUP.topPlaten));
d.moveGroup('topPlaten',0,0,dZ);

d.mo.isHeat=1;%calculate heat in the model
visRate=0.1;
d.mo.mVis=d.mo.mVis*visRate;

staticPressure=-10.55e3;
shockA=1e-3;
shockF=35;%hertz
shockM=abs(staticPressure*B.ballR*2*B.sampleW/9.8);

tId=d.GROUP.topPlaten;
shockPlatenFilter=(d.mo.aX(tId)>0)&(d.mo.aX(tId)<B.sampleW);
shockId=tId(shockPlatenFilter);
d.addGroup('Shocker',shockId);
vM=shockM/length(shockId);
vGZ0=vM*-9.8;
maxAddGZ=-vM*shockA*(2*pi*shockF)^2;
d.mo.mM(shockId)=vM;
d.mo.aMUp(:)=0.3;
d.mo.dT=d.mo.dT*1;

%---------------------define the source of the wave
totalBalanceNum=200000;%data number of the wave
totalT=totalBalanceNum*d.mo.dT;%total time of the wave

period=1e-4;%period of the wave
Ts=(0:totalBalanceNum)*d.mo.dT;
Values=vGZ0+maxAddGZ*sin((2*pi)*shockF*Ts);
Values(Values>0)=0;
plot(Ts,Values);xlabel('Ts [s]');ylabel('Value');return

waveProp='mGZ';
d.addTimeProp('Shocker',waveProp,Ts,Values);%assign the AZ to elements of LeftLine
d.addRecordProp('Shocker',waveProp);%declare recording mAZ
%---------------------end define the source of the wave

%-------------------define the receiver
receiverNum=6;%receiver number
centerx=B.sampleW/2;%center position of the receiver
centery=0;
centerz=B.sampleH*0.8/receiverNum;
R=B.ballR*4;%radius of the receiver
gNames={};
prop1='mAZ';%record the property 1
prop2='aZ';%record the property 2
for i=1:receiverNum
    gName=['Receiver' num2str(i)];
    gNames=[gNames(:);gName];
    f.run('fun/defineSphereGroup.m',d,gName,centerx,centery,centerz*i,R);
    d.addRecordProp(gName,prop1);%declare recording mAZ
    d.addRecordProp(gName,prop2);%declare recording mAZ
end
figure;
subplot(2,1,1);
d.setGroupId();
d.showFilter('Group',gNames,'aR');
subplot(2,1,2);
plot(Ts,Values);xlabel('Ts [second]');ylabel('GZ of the Shocker [N]');title('GZ of the Shocker');

%-------------------end define the receiver

porosities=[];Ts=[];
gpuStatus=d.mo.setGPU('auto');
totalCircle=60;
d.tic(totalCircle);
fName=['data/step/' B.name num2str(B.ballR) '-' num2str(B.distriRate) 'loopNum'];
d.figureNumber=d.show('aR');

for i=1:totalCircle
    d.mo.setGPU(gpuStatus);
    d.balance('Standard',0.5);
    pZ=min(d.mo.aZ(d.GROUP.topPlaten))-B.ballR*5;
    porosity=mfs.getPorosity(B,pZ);
    porosities=[porosities;porosity];
    Ts=[Ts;d.mo.totalT];
    d.setData();
    %d.showFilter('Group',{'Shocker'});
    %d.data.AZ0=d.mo.mGZ./d.mo.mM;
    d.show('mVZ');
    d.clearData(1);
    save([fName num2str(i) '.mat']);
    d.calculateData();
    d.toc();%show the note of time
end
d.mo.setGPU('off');

%show the curves
curveFigure=figure;
for i=1:receiverNum
    subplot(6,2,i*2-1);
    d.status.show(['PROPReceiver' num2str(i) '_' prop1]);
    subplot(6,2,i*2);
    d.status.show(['PROPReceiver' num2str(i) '_' prop2]);
end
set(curveFigure, 'position', get(0,'ScreenSize'));
figure;d.status.show(['PROPShocker_' waveProp]);%declare recording mAZ
figure;plot(Ts,porosities);
xlabel('Time[s]');ylabel('Porosity');

d.clearData(1);
d.recordCalHour('BoxCrush3Finish');
save(['TempModel/' B.name '3.mat'],'d');
save(['TempModel/' B.name '3R' num2str(B.ballR) '-' num2str(B.distriRate)  'aNum' num2str(d.aNum) '.mat']);
d.calculateData();