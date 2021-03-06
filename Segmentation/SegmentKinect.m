%Move Kinect and Lab files in same folder as this script 
%(or change code according to file paths)
tic;

filenames = dir('*.lab');

%Check labels
test = checklabels(filenames);
if test
    error('Correct your label files before segmenting!');
end

filenames = dir('*.txt');


mkdir('segmented');

if iscell(filenames)
    nfiles = size(filenames,2);
elseif isstruct(filenames)
    nfiles = size(filenames,1);
else
    nfiles = 1;
end

for f = 1:nfiles
    
    %%% Load file
    if iscell(filenames)
        filename = filenames{f}(1:end-4);
    elseif isstruct(filenames)
        filename = filenames(f).name(1:end-4);
    else
        filename = filenames(1:end-4);
    end
    
    %%% Parse labels
    [index, label] = parselab([filename '.lab']);
    
    %%% Parse Kinect data
    [frames, data] = parsekinect([filename '.txt']);
    
    %Convert indexes to ms
    index = index*1000 + frames(1);
    
    %%% Initialize parameters
    nseg = size(index,1);
    
    gesturetypes = {'ex1','ex2','ex3','ex4','ex5l','ex5r','tech1l','tech1r','tech2l',...
        'tech2r','tech3l','tech3r','tech4l','tech4r','tech5l','tech5r','tech6l','tech6r'...
        ,'tech7l','tech7r','tech8l','tech8r'};
    newgesturetypes = {'G01D01','G02D01','G03D01','G04D01','G05D01','G05D02',...
        'G06D01','G06D02','G07D01','G07D02','G08D01','G08D02',...
        'G09D01','G09D02','G10D01','G10D02','G11D01','G11D02',...
        'G12D01','G12D02','G13D01','G13D02'};
    samplecounts = zeros(length(gesturetypes),1);
    
    %%% Extract segment data
        for s=1:nseg
                        
            if s<nseg
                [m,beginning] = min(abs(frames-index(s)));
                [m,ending] = min(abs(frames-index(s+1)));
                segmentdata = data(beginning:ending,:);
                segmentframes = frames(beginning:ending,:);
            else
                [m,beginning] = min(abs(frames-index(s)));
                segmentdata = data(beginning:end,:);
                segmentframes = frames(beginning:end,:);                
            end            
            
            %check label
            labeltype = find(ismember(gesturetypes,label{s}));
            
            if isempty(labeltype) && label{s}~='_'
                error(['Unkown label "' label{s} '" in file ' filename ...
                    '. Use CheckLabels.m and correct manually you label files before using this script']);
            end
            
            if ~isempty(labeltype)
                
                samplecounts(labeltype) = samplecounts(labeltype) + 1;
                segname = [filename newgesturetypes{labeltype} sprintf('S%02d',samplecounts(labeltype))];
                fname = segname;
                
                %save segment
                segmentpath = 'segmented';
                writekinect(segmentpath, fname, segmentdata, segmentframes);
            end           
            
        end
end

fclose('all');
toc;

%% Visualization Example - Requires the MoCap Toolbox and MoCap Toolbox extension, 
%available at:
% https://github.com/titsitits/MocapRecovery/tree/master/MoCapToolboxExtension

% close all;
% filename = dir(['segmented/*.txt']);
% id = 120;
% disp(filename(id).name);
% [frames,data] = parsekinect([filename(id).folder '\' filename(id).name]);
% tmptrack.data = data;
% tmptrack.freq = 30;
% tmptrack.nMarkers = 25;
% tmptrack.type = 'MoCap data';
% tmptrack.nFrames = size(data,1);
% p = mcinitanimpar;
% %p.conn = mcautomaticbones2(tmptrack);
% mc3dplot(tmptrack,p,[],1);
