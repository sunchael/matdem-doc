%generate seismic wave and make receivers to record data of seismic wave
clear;
load('TempModel/BoxModel2.mat');

d.calculateData();
d.mo.setGPU('off');
B.setUIoutput();
d.getModel();%reset the initial status of the model
d.resetStatus();%initialize model status, which records running information
d.mo.isHeat=1;%calculate heat in the model
d.mo.isCrack=1;

%set the test block size
mZ=d.mo.aZ(1:d.mNum);
P=[0,B.sampleW/4,min(mZ),max(mZ)/3];%left,right,front,back,bottom,
type='*';%*:show figure; no: only define group, no calculation
blockEv=mfs.blockTest(d,P,type);

%save the result
d.clearData(1);
d.recordCalHour('Step3Finish');
save(['TempModel/' B.name '3_speed_R' num2str(B.ballR) '-' num2str(B.distriRate)  'aNum' num2str(d.aNum) '.mat']);
d.calculateData();