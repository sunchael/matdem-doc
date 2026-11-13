function [d,balanceNum,box1Cx,box1Cy,box1Cz] = user_DigSimpleInitialization()
%build the geometrical model
if exist('TempModel\DigSimple2.mat','file')~=0
    
    load('TempModel\DigSimple2.mat');
    d.show('aR');
    balanceNum=5;
    DigObj3DId=d.GROUP.DigObj3D;
    box1Cx=gather(d.mo.aX(DigObj3DId(end)));
    box1Cy=gather(d.mo.aY(DigObj3DId(end)));
    box1Cz=gather(d.mo.aZ(DigObj3DId(end)));

else
    %% Initialize
    clear;
    fs.randSeed(1);%build random model
    B=obj_Box;%build a box object
    B.name='DigSimple';
    B.GPUstatus='auto';
    %--------------initial model------------
    B.ballR=0.1;
    B.isClump=0;
    B.distriRate=0.2;
    B.sampleW=8.0;
    B.sampleL=2.0;
    B.sampleH=6.0;
    %B.BexpandRate=4;
    %B.PexpandRate=4;
    B.type='topPlaten';
    %B.type='TriaxialCompression';
    B.setType();
    B.buildInitialModel();%B.show();
    B.setUIoutput();

    d=B.d;%d.breakGroup('sample');d.breakGroup('lefPlaten');
    %--------------end initial model------------
    B.gravitySediment();
    B.compactSample(1);%iput is compaction time
    %mfs.reduceGravity(d,10);

    %------------return and save result--------------
    d.status.dispEnergy();%display the energy of the model

    d.mo.setGPU('off');
    d.clearData(1);%clear dependent data
    d.recordCalHour('DigSimple1Finish');
    save(['TempModel/' B.name '1.mat'],'B','d');
    save(['TempModel/' B.name '1R' num2str(B.ballR) '-distri' num2str(B.distriRate)  'aNum' num2str(d.aNum) '.mat']);
    d.calculateData();
    load('TempModel/DigSimple1.mat');
    B.setUIoutput();
    d=B.d;
    d.calculateData();%calculate data after loading the .mat file
    d.mo.setGPU('off');%close the GPU before handling the model
    d.getModel();%get X,Y,Z,R.. from d.mo

    %------------------remove top elements
    mZ=d.mo.aZ(1:d.mNum);
    topLayerFilter=mZ>max(mZ)*0.5;
    d.delElement(find(topLayerFilter));

    %--------------set material, define strong and weak rock
    matTxt=load('Mats/StrongRock.txt');
    Mats{1,1}=material('StrongRock',matTxt,B.ballR);
    Mats{1,1}.Id=1;
    matTxt2=load('Mats/WeakRock.txt');
    Mats{2,1}=material('WeakRock',matTxt2,B.ballR);
    Mats{2,1}.Id=2;
    d.Mats=Mats;%assign the material to the model
    d.groupMat2Model({'sample'},1);
    sampleId=d.GROUP.sample;
    StartaX=3
    StartaZ=3.3

    lineX=[StartaX;StartaX+0.5;StartaX+1.28];
    lineY=zeros(size(lineX));
    lineZ=[StartaZ;StartaZ+0.624;StartaZ];
    DigObj1=f.run('fun/make3DCurve.m',lineX,lineY,lineZ,B.ballR,1);
    DigObj1 = mfs.rotate(DigObj1,'YZ',90);
    DigObj3D=mfs.make3Dfrom2D(DigObj1, 0.8, 0.04);
    DigObj3D = mfs.rotate(DigObj3D,'YZ',270);
    DigObj3D.X=[DigObj3D.X;StartaX];
    DigObj3D.Y=[DigObj3D.Y;(max(d.aY(sampleId))+min(d.aY(sampleId)))/2];
    DigObj3D.Z=[DigObj3D.Z;StartaZ];
    DigObj3D.R=[DigObj3D.R;mean(DigObj3D.R)];
    DigObj3DId=d.addElement(1,DigObj3D);
    d.addGroup('DigObj3D',DigObj3DId);
    d.setClump('DigObj3D')
    d.moveGroup('DigObj3D',0,(((max(d.aY(sampleId))+min(d.aY(sampleId))))/2),0);

    Dig2Rx=gather(d.mo.aX(DigObj3DId(end)));
    Dig2Ry=gather(d.mo.aY(DigObj3DId(end)));
    Dig2Rz=gather(d.mo.aZ(DigObj3DId(end)));
    d.removeGroupForce(d.GROUP.DigObj3D,[d.GROUP.topB;d.GROUP.rigB])
        d.mo.isFix=1;
    d.addFixId('X',DigObj3DId);%fix the X-coordinate of the hob
    d.addFixId('Y',DigObj3DId);%fix the Y-coordinate of the hob
    d.mo.zeroBalance();
    d.rotateGroup('DigObj3D','XZ',27.66,Dig2Rx,Dig2Ry,Dig2Rz);

    %d.show('StressZZ');return;
    d.balanceBondedModel0();%setGPU Auto
    d.mo.bFilter(:)=0;
    %d.balance('Standard');%==d.balance(50,d.SET.packNum);
    d.balance();
    %d.balanceBondedModel();%bonded all elements and balance the model with element friction
    d.balanceBondedModel0();%bonded all elements and balance the model without element friction
    d.addFixId('Z',DigObj3DId);%fix the Y-coordinate of the hob
    %d.defineWallElement('DigObj3D');
    d.show('aR');
    d.mo.setGPU('off');
    d.clearData(1);
    d.recordCalHour('DigSimple2Finish');
    box1Cx=gather(d.mo.aX(DigObj3DId(end)));
    box1Cy=gather(d.mo.aY(DigObj3DId(end)));
    box1Cz=gather(d.mo.aZ(DigObj3DId(end)));
    d.mo.mVX(:)=0;d.mo.mVY(:)=0;d.mo.mVZ(:)=0;
    balanceNum=5;
    d.mo.bFilter(:)=1;%bond all elements
    d.mo.zeroBalance();
    %save([fName '0.mat']);%return;
    gpuStatus=d.mo.setGPU('auto');
    save(['TempModel/' B.name '2.mat'],'B','d');
    save(['TempModel/' B.name '2R' num2str(B.ballR) '-distri' num2str(B.distriRate)  'aNum' num2str(d.aNum) '.mat']);
    d.calculateData();
end
end