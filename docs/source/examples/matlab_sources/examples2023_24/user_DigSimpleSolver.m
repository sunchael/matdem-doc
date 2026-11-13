classdef user_DigSimpleSolver < matlab.System
    % untitled Add summary here
    %
    % This template includes the minimum set of functions required
    % to define a System object with discrete state.

    % Public, tunable properties
    properties (Nontunable)
        dt = 0.1
    end
    properties

    end
    properties (DiscreteState)

    end

    % Pre-computed constants
    properties (Access = private)
        d
        balanceNum=0
        q1PreAngle=0
        q1AngleDiff=0
        box1Cx
        box1Cy
        box1Cz
        fName=['data\step\DigSimple']
        num=0
    end

    methods (Access = protected)
        function setupImpl(obj)
            [obj.d,obj.balanceNum,obj.box1Cx,obj.box1Cy,obj.box1Cz]=user_DigSimpleInitialization();
            % Perform one-time calculations, such as computing constants
        end

        function y = stepImpl(obj,q1CurAngle)
            % Implement algorithm. Calculate y as a function of input u and
            % discrete states.
            y = 0;
            obj.q1AngleDiff=q1CurAngle-obj.q1PreAngle;
            obj.q1PreAngle = q1CurAngle;
            obj.d.rotateGroup('DigObj3D','XZ',obj.q1AngleDiff,obj.box1Cx,obj.box1Cy,obj.box1Cz);
            if(mod(obj.balanceNum,5)==0)
                d=obj.d;
                save([obj.fName num2str(obj.num) '.mat'],'d');
                %obj.d.show('mV');
                obj.num=obj.num+1;
            end
            obj.d.mo.setKNKS
            obj.d.balance(5);
            obj.d.recordStatus();
            figureNumber=obj.d.show('Displacement');%define figureNumber, figure will shown in one form during iterations
            obj.d.figureNumber=figureNumber;
            clim([0,1])
            %obj.d.toc();%show the note of time
            
            obj.d.clearData(1);%clear data before saving
            %save([fName num2str(i+totalCircle) '.mat']);
            obj.d.calculateData();%calculate the data for further c
            obj.balanceNum=obj.balanceNum+1;

        end

        function resetImpl(obj)
            % Initialize / reset discrete-state properties
        end
        function out = getOutputSizeImpl(obj)
            % Return size for each output port
            out = [1 1];

            % Example: inherit size from first input port
            % out = propagatedInputSize(obj,1);
        end

        function out = getOutputDataTypeImpl(obj)
            % Return data type for each output port
            out = "double";

            % Example: inherit data type from first input port
            % out = propagatedInputDataType(obj,1);
        end

        function out = isOutputComplexImpl(obj)
            % Return true for each output port with complex data
            out = false;

            % Example: inherit complexity from first input port
            % out = propagatedInputComplexity(obj,1);
        end

        function out = isOutputFixedSizeImpl(obj)
            % Return true for each output port with fixed size
            out = true;

            % Example: inherit fixed-size status from first input port
            % out = propagatedInputFixedSize(obj,1);
        end
        
        function sts = getSampleTimeImpl(obj)
            % Specify discrete sample time
            sts = obj.createSampleTime("Type", "Discrete", "SampleTime", obj.dt);
        end
    end
end
