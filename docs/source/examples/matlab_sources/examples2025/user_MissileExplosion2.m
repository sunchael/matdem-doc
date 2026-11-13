%set the material of the model
clear
load('TempModel/MissileExplosion1.mat');
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

ballR = 0.25
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


tunnelId = d.addElement('StrongRock',curveObj);
missleL = 3
missleH = 7
ballR = 0.25
rate = 0.7
width = missleL
length =missleH
xNum=ceil(width/(2*ballR))/0.7;
zNum=ceil(length/(2*ballR))/0.7;
dx=(width-2*ballR)/(xNum-1);
dy=(length-2*ballR)/(zNum-1);
if xNum<=1
    xNum=1;dx=0;
end
if zNum<=1
    zNum=1;dy=0;
end
xList=ballR+(0:xNum-1)*dx;
zList=ballR+(0:zNum-1)*dy;
[X,Z]=meshgrid(xList,zList);
rect.X=X(:);rect.Z=Z(:);
rect.Y=zeros(size(rect.X))
rect.R=ones(size(rect.X))*ballR;
rect.width=width;rect.length=length;
figure
fs.showObj(rect)

triL = 3;
triH = 3;
midCenterX=triL/2
midCenterY=0+ballR
yNum=ceil(triH/(2*ballR))/0.7
obj.X=[];
obj.Z=[];
for i = 1:yNum
    width = (triH-(i-1)*(2*ballR)*rate)*triL/triH
    xNum =  ceil(width/(2*ballR))/rate
    num = ceil(xNum / 2)

    midCenterY = midCenterY-(2*ballR)*rate
    for j = 1:num
        xList=[]
        zList=[]
        if j==1
            xList=[midCenterX];
            zList=[midCenterY];
        else
            xList=[midCenterX-(j-1)*rate*2*ballR;midCenterX+(j-1)*rate*2*ballR];
            zList=[midCenterY;midCenterY];
        end

        %{
        if num*2 >xNum
            
            if j==1
                xList=[midCenterX];
                yList=[midCenterY];
            else
                xList=[midCenterX-(j-1)*rate*2*ballR;midCenterX+(j-1)*rate*2*ballR];
                yList=[midCenterY;midCenterY];
            end
        else
            xList=[midCenterX-(j-1.5)*rate*2*ballR;midCenterX+(j-1.5)*rate*2*ballR];
            yList=[midCenterY;midCenterY];
            if j==num
                xList=[xList;midCenterX-(j-2.5)*rate*2*ballR;midCenterX+(j-2.5)*rate*2*ballR];
                yList=[yList;midCenterY;midCenterY];
            end
        end
        %}
        obj.X=[obj.X;xList];
        obj.Z=[obj.Z;zList];
    end

end
obj.Y=zeros(size(obj.X));
obj.R=ones(size(obj.X))*ballR

missile1=mfs.combineObj(rect,obj)
missile2=mfs.combineObj(rect,obj)
missile3=mfs.combineObj(rect,obj)
fs.showObj(missile1)
missile1Id = d.addElement('StrongRock',missile1);
missile2Id = d.addElement('StrongRock',missile2);
missile3Id = d.addElement('StrongRock',missile3);
d.addGroup('missile1',missile1Id)
d.addGroup('missile2',missile2Id)
d.addGroup('missile3',missile3Id)
d.moveGroup('missile1',150,0,200)
d.moveGroup('missile2',250,0,200)
d.moveGroup('missile3',350,0,200)
missileId = [missile1Id;missile2Id;missile3Id]
d.addGroup('missile',missileId)
d.setClump('missile')
B.isClump('missile') = 2
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