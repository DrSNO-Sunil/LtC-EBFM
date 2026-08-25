%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Energy Balance + Firn  Model (EBFM) for LtC

% Written by Ward van Pelt (2012), updated for Abramov Glacier by Marlene 
% Kronenberg (2022), and set up for Western Cwm LtC by Sunil N. Oulkar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars;
tic;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Model setup
[grid,time,io,phys]         = func_init_params();
[C]                         = func_init_constants();
[grid]                      = func_init_grid(grid,io);
[A,clim,insol,OUT]          = func_init_arrays(C,grid,io);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Save final restart
func_createbootfile(A,io);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Time loop
starttime                   = datetime("now");    

for t=1:time.tn
    
    % Print time to screen
    [time] = func_printtime(t,time);
    % fprintf('This message is sent at time %s\n', datestr(now));
    
    % Read and prepare climate input
    [clim,A] = func_loadclimate_LtC_3_Month(C,grid,clim,t,time,A);
    
    % Surface energy balance model
    [A,insol] = func_energybalance(C,A,clim,insol,t,time,grid);
    
    % Snow/firn model
    % [A] = func_snowmodel_Without_Percolation_Blocking(C,A,clim,time.dt,grid,time,phys);
    [A] = func_snowmodel_With_Percolation_Blocking(C,A,clim,time.dt,grid,time,phys);
      
    % Mass balance
    [A] = func_massbalance(A,clim,C);

    % Runtime viewer
    func_runtimeviewer(A,io,t,grid,insol);
    
    % Write output to files   
    A.gridzmask = grid.z_mask;  
    A.gridz = grid.z(grid.ind);       
    [OUT,io] = func_writetofile(OUT,io,A,grid,t,time,C);
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
msg = '✅ SIMULATION WAS SUCCESSFUL ✅';
border = repmat('=', 1, length(msg) + 4);

fprintf('\n%s\n', border);
fprintf('| %s |\n', msg);
toc;
fprintf('%s\n\n', border);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

