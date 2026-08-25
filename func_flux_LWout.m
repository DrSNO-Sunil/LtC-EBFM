%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Compute outgoing shortwave radiation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [LWout] = func_flux_LWout(C,Tsurf)

    %% LWout observed data
    if isfield(clim, 'LWout')
         LWout = clim.LWout;
    else
        % Blackbody emission of thermal radiation
        LWout = C.boltz.*Tsurf.^4;
    end
end