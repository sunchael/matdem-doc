% run in afterBalance, obj refer to *d.mo*
sId=obj.dem.GROUP.sample;
nBall=obj.nBall(sId,:);

% See also SoilCrack case 
% neighbor difference and transfer coefficient
% the coefficient can be a function of element properties 
SET=obj.SET;
nVDiff=SET.aVW(nBall)-SET.aVW(sId);
nK=SET.nK;

% neighbor/transfer distance
nDX=obj.aX(nBall)-obj.aX(sId);
nDY=obj.aY(nBall)-obj.aY(sId);
nDZ=obj.aZ(nBall)-obj.aZ(sId);
nDD=sqrt(nDX.^2+nDY.^2+nDZ.^2);
nR=min(obj.aR(nBall),obj.aR(sId));

% ignore transfer caculation 
aFilter=false(obj.aNum);
aFilter(obj.dem.GROUP.sample)=true;
nFilter=aFilter(nBall);
nFilter=nFilter & (nR>=SET.minR);
nK=nK.*nFilter;

% volume flow
nVFlow=nK.*nVDiff./nDD.*(pi*nR.^2)*obj.dT;
sVFlow=sum(nVFlow,2);

% update volume based on Volume Conservation
obj.aR(sId)=(obj.aR(sId).^3+3/(4*pi)*sVFlow).^(1/3);
solidId=obj.dem.GROUP.solid;
Vrate=(obj.dem.aR./obj.aR).^3;
obj.SET.aVW(solidId)=1-Vrate(solidId);
obj.bFilter(obj.dem.GROUP.liquid,:)=true;
