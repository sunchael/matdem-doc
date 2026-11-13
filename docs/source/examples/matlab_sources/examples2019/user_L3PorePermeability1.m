%step1: packing the elements
clear;
fs.randSeed(1);%random model seed, 1,2,3...
B=obj_Box;%declare a box object
B.name='PorePermeability';
%--------------initial model------------
B.GPUstatus='auto';%program will test the CPU and GPU speed, and choose the quicker one
B.ballR=0.0005;
B.isShear=0;
B.isClump=0;%if isClump=1, particles are composed of several balls
B.distriRate=0.2;%define distribution of ball radius, 
B.sampleW=0.0309*2;%width, length, height, average radius
B.sampleL=0;%when L is zero, it is a 2-dimensional model
B.sampleH=0.05;
B.boundaryRrate=0.999999;
B.BexpandRate=2;%boundary is 4-ball wider than 
B.PexpandRate=1;
B.isSample=1;
B.setType('Fluid');
B.buildInitialModel();%B.show();
d=B.d;%d.breakGroup('sample');d.breakGroup('lefPlaten');
%you may change the size distribution of elements here, e.g. d.mo.aR=d.aR*0.95;
d.showB=1;
%--------------end initial model------------

%---------- gravity sedimentation
B.gravitySediment(1);%you may use B.gravitySediment(10); to increase sedimentation time (10)
%------------return and save result--------------

d.status.dispEnergy();%display the energy of the model
d.show('-aR');
d.mo.bFilter(:)=1;
d.mo.zeroBalance();
d.Rrate=1;
d.mo.setGPU('off');
d.clearData(1);%clear dependent data
d.recordCalHour('Step1Finish');
save(['TempModel/' B.name '1.mat'],'B','d');
save(['TempModel/' B.name '1R' num2str(B.ballR) '-distri' num2str(B.distriRate)  'aNum' num2str(d.aNum) '.mat']);
d.calculateData();
%d.show('-Id');