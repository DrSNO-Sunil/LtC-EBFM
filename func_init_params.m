%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Model parameters:
%%% User-defined run parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [grid, time, io, phys] = func_init_params()

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Time parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
time.ts = '07-May-2025 00:02'; % Date and time start run
time.te = '29-Jul-2025 00:00'; % Date and time end run
time.TS = datenum(time.ts);                                                 
time.TE = datenum(time.te);                                                  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Forcing time resolution
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
askUser_time = 0; % Set to false if you don't want to be asked (1=yes, 0=no)

if askUser_time
    forcingRes = input('Enter time resolution (1, 3, 6, or 24) [default = 1]: ', 's');
    if isempty(forcingRes)
        forcingRes = '1'; % Default if user just presses Enter
    end
else
    forcingRes = '1'; % Always use 1h without asking
end

switch forcingRes
    case '1'
        time.dt = 0.0417;  % 1 hour in days
    case '3'
        time.dt = 0.125;   % 3 hours in days
    case '6'
        time.dt = 0.25;    % 6 hours in days
    case '24'
        time.dt = 1;       % 24 hours (daily)
    otherwise
        error('Invalid input. Please enter ''1'', ''3'', ''6'', or ''24''.');
end

time.forcingRes = forcingRes;
% Display chosen resolution
fprintf('Time resolution set to %s hours (dt = %.4f days).\n', time.forcingRes, time.dt);

time.tn = round((time.TE-time.TS)/time.dt)+1;                               % nr of timesteps

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input/output parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
io.homedir   = fullfile(pwd);
io.rebootdir = [io.homedir '/Initial_Conditions/'];
% io.outdir    = [io.homedir '/../Output/LtC_3_Month_With_Percolation_Blocking'];

% Ask user where to save output
startDir = fullfile(fileparts(pwd),'Output');
outdir = uigetdir(startDir, 'Select folder to save model output');

% Handle user pressing "Cancel"
if isequal(outdir, 0)
    error('Run cancelled: no output directory selected.');
end

io.outdir = outdir;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Choose grid file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
outdir = fullfile(pwd);
gridDir = fullfile(outdir, 'Grid');
gridDirFull = char(java.io.File(gridDir).getCanonicalPath);
g = dir(fullfile(gridDirFull, '*.mat'));
if isempty(g), error('No grid files found in %s', gridDirFull); end

fprintf('\nAvailable DEM grid files:\n');
for i = 1:numel(g)
    fprintf('%d) %s\n', i, g(i).name);
end

% --- Control whether to ask or use default ---
askUser_Grid  = 0;                                                          % set to false if you always want without prompt (1=yes, 0=no)
defaultChoice = 1;

if askUser_Grid
    n = input(sprintf('Enter the number of the grid file to use [default = %d]: ', defaultChoice));
    if isempty(n)
        n = defaultChoice;
    end
else
    n = defaultChoice;
end

% --- Validation ---
if n < 1 || n > numel(g)
    error('Invalid choice. Please enter a number between 1 and %d.', numel(g));
end
% --- Save chosen grid file ---
io.gridfile = fullfile(gridDirFull, g(n).name);
fprintf('Selected: %s\n', io.gridfile);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Grid parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
grid.utmzone     = 45;                                                      % UTM zone 
grid.max_subZ    = 0.1;                                                     % maximum layer thickness (m)
grid.nl          = 42;                                                      % number of vertical layers
grid.doubledepth = 1;                                                       % if glacier, double vertical layer depth at layer grid.split (1=yes, 0=no)
grid.split       = [15;25;35];                                              % if glacier, vertical layer nr at which layer depth doubles

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Model physics parameters
phys.percolation = 2;                                                       % deep percolation scheme (1 = bucket, 2 = normal dist., 3 = linear dist., 4 = uniform dist.)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Select bootfile based on grid file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
bootfileName = 'Boot_Observed_LtC_3_Month.mat';
bootfilePath = fullfile(io.rebootdir, bootfileName);

if exist(bootfilePath, 'file')
    io.bootfilein    = bootfileName;
    io.bootfileout   = bootfileName;
    io.readbootfile  = 1;                                                   % read initial conditions from file (1=yes, 0=no) % Read initial state
    io.writebootfile = 0;                                                   % write file for rebooting (1=yes, 0=no) % Save final state
    fprintf('Selected bootfile: %s\n', bootfileName);
else
    io.bootfilein    = bootfileName;
    io.bootfileout   = bootfileName;
    io.readbootfile  = 0;                                                   
    io.writebootfile = 1;                                                    
    fprintf('Bootfile not found. Will create: %s\n', bootfileName);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

io.readclimatefromfile = 1;                                                 % read climate data from input files (1=yes, 0=no) 
io.infofile            = 'runinfo.mat';                                     % write file to store run information
io.out_surface         = 1;                                                 % write surface variables to files (1=yes, 0=no)
io.out_subsurface      = 1;                                                 % write subsurface variables to files (1=yes, 0=no)

io.runtimeview         = 0;                                                 % runtime viewer (1=yes, 0=no)
io.runtimeview_freq    = 1;                                                 % frequency of runtime plotting (every n-th time-step)
io.freqout             = 1;                                                 % frequency of storing output (every n-th time-step)

end

