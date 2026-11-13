ufs.setTitle('MatDEM钻地弹撞击地面实时模拟');
clear;
load('TempModel/MissileExplosion3D2.mat');
d.calculateData();
d.mo.setGPU('off');
B.setUIoutput();
d=B.d;
d.getModel();%d.setModel();%reset the initial status of the model
d.resetStatus();%initialize model status, which records running information
d.mo.isShear=0;
d.mo.isClump=2;
d.mo.isHeat=1;%calculate heat in the model
visRate=0.01;
d.mo.mVis=d.mo.mVis*visRate;
isBoom1 = 1;
isBoom2 = 1;
isBoom3 = 1;
bombExpandRate = 1.5
%discId=d.GROUP.Disc;
missileId=d.GROUP.missile
d.setStandarddT();
d.mo.dT=d.mo.dT*4;%increase step time to increase computing speed


%d.mo.mVX(missileId)=577;rate
missile1Id=d.GROUP.missile1
missile2Id=d.GROUP.missile2
missile3Id=d.GROUP.missile3
d.mo.mVZ(missileId)=-1000;
d.addFixId('X',d.GROUP.missile)
B.isClump(d.GROUP.tunnel)=0
d.showB=0;
d.status.legendLocation='West';


%-----------------------set viscous layers
visRate0=15;%visRate can be an 1*6 array
Hrate=1/6;
gName='sample';
S0=d.group2Obj(gName);
F=mfs.getObjFrame(S0);%get frame of the object
%TH define layer thickness, [left,right,front,back,bottom,top]
if d.is2D==1
TH=[F.width,F.width,F.length,F.length,F.height,F.height].*[Hrate/2,Hrate/2,0,0,Hrate,0];%2D
else
TH=[F.width,F.width,F.length,F.length,F.height,F.height].*[Hrate/2,Hrate/2,Hrate/2,Hrate/2,Hrate,0];%3D
end
%TH=B.ballR*2*[0,30,0,0,0,0];%use ball number to define the layer
TW=B.ballR*2*ones(size(TH))*3;%define layer triangle width

visId=casefs.makeSerraVisBlock(d,gName,TW,TH,visRate0);
%d.show('mVis')
d.showFilter('SlideX',0.5,1,'mVis')

%----------set the drawing of result during iterations
setappdata(0,'simpleFigure',1);
setappdata(0,'ballRate',0.01);
showType='mV';
%----------end set the drawing of result during iterations
topSample = max(d.mo.aZ(d.GROUP.sample))
gpuStatus=d.mo.setGPU('auto');
totalCircle=1000;
d.tic(totalCircle);
fName=['data/step/' B.name num2str(B.ballR) '-' num2str(B.distriRate) 'loopNum'];
save([fName '0.mat']);%return;

displacementZ = [min(d.mo.aZ(missile1Id))];
velocityZ = [mean(d.mo.mVZ(missile1Id))];

for i=1:totalCircle
    d.mo.setGPU(gpuStatus);
    d.balance('Standard',0.001);
    if(isBoom1 == 1)
        displacementZ = [displacementZ;min(d.mo.aZ(missile1Id))];
        velocityZ = [velocityZ;mean(d.mo.mVZ(missile1Id))];
    end
    if( mean(d.mo.aZ(missile1Id) < topSample-30 )&& isBoom1 == 1)
        d.mo.aR(missile1Id)=d.mo.aR(missile1Id)*bombExpandRate;%increase bomb element size
        isBoom1 = 0 ;
        %B.isClump(missile1Id) = 0
        d.removeFixId('X',missile1Id)
        nfilter = mfs.groupConnectFilter(d.mo.nBall,d.GROUP.missile1,d.GROUP.missile1);
        d.mo.nClump(nfilter) = 0
    end
    if( mean(d.mo.aZ(missile2Id) < topSample-30 )&& isBoom2 == 1)
        d.mo.aR(missile2Id)=d.mo.aR(missile2Id)*bombExpandRate;%increase bomb element size
        isBoom2 = 0 ;
        B.isClump(missile2Id) = 0
        d.removeFixId('X',missile2Id)
        nfilter = mfs.groupConnectFilter(d.mo.nBall,d.GROUP.missile2,d.GROUP.missile2);
        d.mo.nClump(nfilter) = 0
    end
    if( mean(d.mo.aZ(missile3Id) < topSample-30 )&& isBoom3 == 1)
        d.mo.aR(missile3Id)=d.mo.aR(missile3Id)*bombExpandRate;%increase bomb element size
        isBoom3 = 0 ;
        B.isClump(missile3Id) = 0
        d.removeFixId('X',missile3Id)
        nfilter = mfs.groupConnectFilter(d.mo.nBall,d.GROUP.missile3,d.GROUP.missile3);
        d.mo.nClump(nfilter) = 0
    end
    %d.showFilter('Group',{'missile','tunnel'},'mV')
    d.showFilter('SlideY',0.5,1,'mV');
    d.showFilter('SlideX',0.5,1,'mV');
    d.figureNumber=d.show(showType);%result will be shown in one figure
    d.show('mV')
    view(0,0)
    clim([0,300]);
    d.clearData(1);
    save([fName num2str(i) '.mat']);
    d.calculateData();
    pause(0.05);
    d.toc();%show the note of time
end
d.mo.setGPU('off');
d.clearData(1);
d.recordCalHour('BoxCrush3Finish');
save(['TempModel/' B.name '3.mat'],'d');
save(['TempModel/' B.name '3R' num2str(B.ballR) '-' num2str(B.distriRate)  'aNum' num2str(d.aNum) '.mat']);
d.calculateData();