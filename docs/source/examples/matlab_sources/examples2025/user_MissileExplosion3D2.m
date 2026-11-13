%set the material of the model
clear
load('TempModel/BoxCrash1R2.5-distri0.2aNum584471.mat');
%load('TempModel/MissileExplosion3D1.mat');
B.setUIoutput();%set the output
d=B.d;
d.calculateData();%calculate data
d.mo.setGPU('off');%close the GPU calculation
d.getModel();%get xyz from d.mo
%---------------delete elements on the top
mZ=d.mo.aZ(1:d.mNum);%get the Z of elements
topLayerFilter=mZ>max(mZ)*0.5;
d.delElement(find(topLayerFilter));%delete elements according to id

sampleId = d.GROUP.sample;
ballR = mean(d.mo.aR(sampleId))
CC = find(d.mo.aX(sampleId)>235-2*ballR &d.mo.aX(sampleId)<265+2*ballR & (d.mo.aX(sampleId)-250).^2+(d.mo.aZ(sampleId)-40).^2<225+45*ballR & d.mo.aZ(sampleId)>40)
cc = find(d.mo.aX(sampleId)>235-2*ballR &d.mo.aX(sampleId)<265+2*ballR &d.mo.aZ(sampleId)<40 & d.mo.aZ(sampleId)>30-2*ballR)
CC =[CC;cc]
d.delElement(CC)

%--------------assign new material
matTxt=load('Mats\StrongRock.txt');%load material file
Mats{1,1}=material('StrongRock',matTxt,B.ballR);
Mats{1,1}.Id=1;
matTxt2=load('Mats\WeakRock.txt');
Mats{2,1}=material('WeakRock',matTxt2,B.ballR);
Mats{2,1}.Id=2;
d.Mats=Mats;%assign new material
%d.groupMat2Model({'sample'},1);%apply the new material

%----------make disc sample------------
%{
sampleId=d.GROUP.sample;
sX=d.aX(sampleId);sZ=d.aZ(sampleId);sR=d.aR(sampleId);
discCX=mean(sX);discCZ=mean(sZ);
discR=20;
discFilter=(d.aX-discCX).^2+(d.aZ-discCZ).^2<discR^2;
%d.setData();d.data.showFilter=discFilter;d.show('aR');
d.addGroup('Disc0',find(discFilter));%add a new group
discObj=d.group2Obj('Disc0');

discId=d.addElement('StrongRock',discObj);%mat Id, obj
d.addGroup('Disc',discId);%add a new group
disZ=max(sZ+sR)-min(discObj.Z-discObj.R);
d.moveGroup('Disc',0,0,disZ);%move the group
%}


%cc = find(d.mo.aZ(CC)<100 & d.mo.aZ(CC)>50)
%d.addGroup('mid',CC)
%d.showFilter()
%d.showFilter('Group','mid','aR')
%d.show('aR')






dipD=90;dipA=60;strongT=10;weakT=6;%dipD: dip direction of layer; dipA: dip angle of layer
weakFilter=mfs.getWeakLayerFilter(d.mo.aX,d.mo.aY,d.mo.aZ,dipD,dipA,strongT,weakT);%make weak layer filter of the box model
sampleId=d.getGroupId('sample');
aWFilter=false(size(weakFilter));
aWFilter(sampleId)=true;
sampleWfilter=aWFilter&weakFilter;
d.addGroup('WeakLayer',find(sampleWfilter));%define a WeakLayer group

ballR = 2
Rrate=0.9
lineX=[235+ballR;265-ballR;265-ballR;7.5*sqrt(3)+250-ballR;257.5-ballR;250;242.5+ballR;-7.5*sqrt(3)+250+ballR;235+ballR;235+ballR];
lineY=zeros(size(lineX));
lineZ=[30+ballR;30+ballR;40;47.5-ballR;40+7.5*sqrt(3)-ballR;55-ballR;40+7.5*sqrt(3)-ballR;47.5-ballR;40;30+ballR];
curveObj2=mfs.make3DCurve(lineX,lineY,lineZ,ballR,Rrate)

lineX=[235;265;265;7.5*sqrt(3)+250;257.5;250;242.5;-7.5*sqrt(3)+250;235;235];
lineY=zeros(size(lineX));
lineZ=[30;30;40;47.5;40+7.5*sqrt(3);55;40+7.5*sqrt(3);47.5;40;30];
curveObj3=mfs.make3DCurve(lineX,lineY,lineZ,ballR,Rrate)

curveObj=mfs.combineObj(curveObj2,curveObj3);

curveObj3D = mfs.make3Dfrom2D(curveObj,B.sampleL,ballR,'Y',Rrate)
fs.showObj(curveObj3D)


tunnelId = d.addElement('StrongRock',curveObj3D);
type=[1;1;1]
%TConeBoxObj=mfs.makeTruncatedCone(2,5,10,2,0.7,type)
figure;
TConeBoxObj=mfs.makeTruncatedCone(1,3,4,1.5,0.7,type)

colObj = mfs.makeColumnBox(3,16,1.5,0.7,type)
colObj.Z = colObj.Z + 2.5;

obj1=mfs.combineObj(colObj,TConeBoxObj)
obj2 = obj1
obj2.X = obj2.X + 100;
obj3 = obj2
obj3.X = obj3.X +100;
obj=mfs.combineObj(obj1,obj2,obj3)
fs.showObj(obj)
missile1Id = d.addElement('StrongRock',obj1);
missile2Id = d.addElement('StrongRock',obj2);
missile3Id = d.addElement('StrongRock',obj3);
missileId = [missile1Id;missile2Id;missile3Id]
d.addGroup('missile',missileId)
d.addGroup('missile1',missile1Id)
d.addGroup('missile2',missile2Id)
d.addGroup('missile3',missile3Id)
d.moveGroup('missile',150,200,200)
d.setClump('missile')
B.isClump('missile') = 2
%d.rotateGroup('missile','XZ',30);
d.addFixId('X',missileId);


d.addGroup('tunnel',tunnelId)
d.setClump('tunnel')
B.isClump('tunnel') = 2

%d.minusGroup('sample','tunnel',0.4);

%coneTubeObj=mfs.makeConeTube(3,10,10,1)
%---------assign material to layers and balance the model
d.setGroupMat('WeakLayer','WeakRock');%material of WeakLayer group is WeakRock
d.groupMat2Model({'WeakLayer'},1);%assign material to WeakLayer group, material Id of other elements is 1


d.balanceBondedModel0();%balance the bonded model without friction
d.show('aMatId');
d.clearData(1);%clear dependent data
d.recordCalHour('Step2Finish');
save(['TempModel/' B.name '2.mat'],'B','d');
save(['TempModel/' B.name '2R' num2str(B.ballR) '-distri' num2str(B.distriRate)  'aNum' num2str(d.aNum) '.mat']);
d.calculateData();