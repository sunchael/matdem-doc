clear;
fs.randSeed(1);
%---------------------start define the struct objects----------------------
ballR=0.015;
Rrate=0.6;
discR=0.5;%radius of bottom disc
rectW=0.3;%width of rectangle
rectH=0.1;%height of rectangle
rectDis2Center=0.15;
rectNum=4;%number of rectangles
totalTime=6;%total time of simulation
rectRotateXYspeed=-360;%degree per second
allRotateXYspeed=120;%degree per second

tubeR=discR;
tubeHeight=rectH*2;
tubeObj=mfs.denseModel0(Rrate,@mfs.makeTube,tubeR,tubeHeight,ballR);
tubeObj=mfs.align2Value('bottom',tubeObj,ballR);

%make the basic rectangle, define .Ts and .RXYs to rotate it
rectObj=mfs.denseModel0(Rrate,@mfs.makeBox,rectW,ballR,rectH,ballR);
rectObj.R(end)=rectObj.R(end)*1.1;%use greater radius to show the direction
rectObj.Ts=[0,1]*totalTime;%see Tool_Motion.Ts
rectObj.RXYs=[0,1]*rectRotateXYspeed*totalTime;%see Tool_Motion.RXYs
rectObj=mfs.addObjCenter(rectObj);%last element is the center of rotation
rectObj=mfs.align2Value('bottom',rectObj,ballR);
rectObj.X=rectObj.X+rectDis2Center;

%rotate the copy the rectangle, include them in the allObj
dAngle=360/rectNum;
for i=1:rectNum
    objName=['rect' num2str(i)];
    newRect=mfs.rotate(rectObj,'XY',dAngle*(i-1));
    newRect.name=objName;
    allObj.(objName)=newRect;
end

%make the disc, which is included in allObj
discObj=mfs.denseModel0(Rrate,@mfs.makeDisc,discR,ballR);
discObj.R(end)=discObj.R(end)*1.1;
discObj=mfs.addObjCenter(discObj);%the center for allObj
discObj.name='disc';%each object must have a name
allObj.disc=discObj;

%the allObj will be rotated when .Ts and .RXYs are defined
allObj.Ts=[0,1]*totalTime;%see Tool_Motion.Ts
allObj.RXYs=[0,1]*allRotateXYspeed*totalTime;%see Tool_Motion.RXYs
allObj.name='all';%each object must have a name
%fs.showObjs(allObj);

%put all objs in a cell array, which will be used in addElement
objCells=f.run('fun/obj2cell.m',allObj);
%---------------------end define the struct objects----------------------

%----------make a Box, and import the objects to the box---------
boxS=discR*2.2;%define the size of the box
frame=[-0.5*boxS,-0.5*boxS,0,0.5*boxS,0.5*boxS,0.3*boxS];%first three value must be zero

B=obj_Box('Mixer');%declare a box object
B.ballR=ballR;%element radius
B.setFrame(frame);%set frame boundary
B.setType('none');%no platen
B.buildInitialModel();

d=B.d;
d.SET.totalTime=totalTime;
d.mo.isOverlapNote=0;
delId=find(d.mo.aX.^2+d.mo.aY.^2>(boxS*0.4).^2);
d.delElement(delId);%delete elements outside the column region

%use rubber to increase step time
matTxt1=load('Mats\rubber.txt');
matTxt1(1)=matTxt1(1)/100;%use small Young's modulus to increase step time
Mats{1,1}=material('rubber',matTxt1,B.ballR);
Mats{1,1}.Id=1;
d.Mats=Mats;
d.mo.aR=d.mo.aR/max(d.mo.aR)*B.ballR;

%add tube to the model
tubeId=d.addElement(1,tubeObj);
d.addGroup('tube',tubeId,1);
d.setClump('tube');
d.addFixId('XYZ',d.GROUP.tube);

%add all objects to the model, and record the Ids of the objects
objIdCell=d.addElement(1,objCells);
allId=[];%record all element Id
for i=1:length(objCells)
    objOne=objCells{i};
    objOneId=objIdCell{i};
    d.addGroup(objOne.name,objOneId,1);%name is gived in obj
    d.setClump(objOne.name);
    allId=[allId;objOneId];
end
d.addGroup('all',allId,1);
%fix groups
d.addFixId('XYZ',d.GROUP.all);
d.minusGroup('sample','all',0.8);
d.groupMat2Model();

%----------end make a Box, and import the objects to the box---------

%balls drop on the mixer 
d.breakGroup();
d.mo.dT=d.mo.dT*4;
d.mo.setGPU('auto');
d.balance('Standard',2);

%set the motion of all group
mAll=Tool_Motion(d,'all');
mAll.Ts=allObj.Ts;%second
mAll.RXYs=allObj.RXYs;%degree
%set the motion of individual group
for i=1:length(objCells)
    objOne=objCells{i};
    if isfield(objOne,'Ts')
        mOne=Tool_Motion(d,objOne.name);
        mOne.Ts=objOne.Ts;
        mOne.RXYs=objOne.RXYs;
    end
end
fs.saveData(B,1);%save the data in the folder TempModel