clear;
fs.randSeed(6);%change it to get a different model
type=1;%1: tiny sample (~30s); 2: small sample (~8min); 3: big sample (several hours)
%------------------set the grain size and box size------------------
grainDensity=2650;%density of the grains
moNum=4;%divided into 'moNum' size groups (childModel)
hRate=1.02;% box is bigger a bit, 1.0~1.2
is2D=1;
if is2D==1
totalM=250e-3;%total mass of the sample
sampleW=0.152;sampleL=0;%width and length of the model, height will be determined by totalM
else
totalM=1600e-3;%total mass of the sample
sampleW=0.1;sampleL=0.1;%width and length of the model, height will be determined by totalM
end
%minmum diameter, maximum diameter, and mass rate
grainSizeDistribution=[4,8,0.2;8,16,0.2;16,32,0.2;32,64,0.2]*0.5e-3;

%determine the grain radius (grainR) according to the above data
grainR=mfs.getGradationDiameter(grainSizeDistribution,totalM/grainDensity)/2;
%determine the box size
SET=mfs.getBoxSample(grainR,sampleW,sampleL,hRate);
SET.moNum=moNum;%divided into 'moNum' size groups
%------------------end set the grain size and box size------------------

%--------------initializing Box model------------
B=obj_Box;%build a box object
B.name='BoxCompactionShock';
B.GPUstatus='auto';
B.setType('topPlaten');
B.PexpandRate=2;
B.buildInitialModel(SET);%B.show();
B.setUIoutput();

if B.sampleL==0
    B.convert2D(B.ballR);%change ball properties to 2D
end
d=B.d;
d.mo.setShear('on');
d.mo.aMUp(:)=0.7;
d.showB=1;

%--------------end initializing Box model------------
B.gravitySediment();
d.status.dispEnergy();%display the energy of the model
d.setData();
pZ=min(d.mo.aZ(d.GROUP.topPlaten))-B.ballR*5;
porosity=mfs.getPorosity(B,pZ);
d.show();

%------------return and save result--------------
d.mo.setGPU('off');
d.clearData(1);%clear dependent data
d.recordCalHour('Step1Finish');
save(['TempModel/' B.name '1.mat'],'B','d');
save(['TempModel/' B.name '1R' num2str(B.ballR) '-distri' num2str(B.distriRate)  'aNum' num2str(d.aNum) '.mat']);
d.calculateData();%because data is clear, it will be re-calculated