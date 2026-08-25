%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Load hourly LtC AWS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [clim,A] = func_loadclimate_LtC_3_Month(C,grid,clim,t,time,A)

% Read climate input from file(s)

persistent EBFM_ClimateData

if isempty(EBFM_ClimateData)
    % Go to Climate_Forcing folder
    outdir = fullfile(pwd);
    dataDir = fullfile(outdir,'\Forcing_Data');
    dataDirFull = char(java.io.File(dataDir).getCanonicalPath);
    switch time.forcingRes
        case '1'
            S = load(fullfile(dataDirFull,'EBFM_ClimateData_LtC_3_Month.mat'));
        otherwise
            error('Unknown forcingRes: %s', time.forcingRes);
    end
    EBFM_ClimateData = S.EBFM_ClimateData;
    % Ensure start time
    EBFM_ClimateData = sortrows(EBFM_ClimateData);
    % Keep only required period so that it will run for that period 
    EBFM_ClimateData = EBFM_ClimateData(EBFM_ClimateData.TIMESTAMP >= time.ts,:);
    EBFM_ClimateData.PRECIP_BaseCamp(1:1) = 0.00034;
    % Precompute month (avoids repeated month() calls)
    EBFM_ClimateData.Month = month(EBFM_ClimateData.TIMESTAMP);
end

tt = t;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Air Temperature [K]
clim.T(:) = EBFM_ClimateData.AirTC_Avg(tt);

%% Precipitation [m w.e.]
clim.P(:) = EBFM_ClimateData.PRECIP_BaseCamp(tt);

%% Cloud cover [fraction]
clim.C(:) = max(min(EBFM_ClimateData.Model_cloud_cover(tt),1.0),0.0);                                

%% Relative humidity [fraction]
clim.RH(:) = EBFM_ClimateData.RH(tt)/1d2;

%% Air pressure [Pa] % Pressure lapse rate (Pa m-1)
elev_LtC   = 6464; % Elevation of MT. EVEREST CAMP II AWS (6464 M ASL) at 27.9810 N, 86.9023 E,
clim.Pres_lapse = -1.4474e-04;  
clim.Pres(:) = EBFM_ClimateData.PRESS(tt) * exp(clim.Pres_lapse*(grid.z_mask-elev_LtC));   

%% Wind speed [m s-1] 
clim.WS(:) = EBFM_ClimateData.WS_AVG(tt);

%% Incoming shortwave radiation [% W m^-2]
clim.SWin(:) = EBFM_ClimateData.SWin_Avg(tt);   

%% Incoming Longwave radiation [% W m^-2]
clim.LWin(:) = EBFM_ClimateData.LWin_Avg(tt); 

%% Outgoing Longwave radiation [% W m^-2]
clim.LWin(:) = EBFM_ClimateData.LWout_Avg(tt); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Potential temperature lapse rate [K m-1]
clim.Theta_lapse(:) = 0.0055;  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Derived climate fields

C.rainsnowT = 273.75; % temperature of snow to rain transition (K)

% Snowfall / Rainfall
clim.snow = clim.P .* (clim.T < C.rainsnowT-1);
clim.rain = clim.P .* (clim.T > C.rainsnowT+1);
clim.snow = clim.snow + clim.P .* (C.rainsnowT-clim.T+1)./2 .* (clim.T < C.rainsnowT+1 & clim.T > C.rainsnowT-1);
clim.rain = clim.rain + clim.P .* (1+clim.T-C.rainsnowT)./2 .* (clim.T < C.rainsnowT+1 & clim.T > C.rainsnowT-1);

% Annual snow accumulation (yearsnow)
A.ys = (1.0-1.0/(365.0/time.dt)).*A.ys + clim.P.*1d3;
logys = log(A.ys);
clim.yearsnow = repmat(A.ys,[1 grid.nl]);
clim.logyearsnow = repmat(logys,[1 grid.nl]);

% Vapor pressure (VP) / specific humidity (q)
VPsat = C.VP0.*exp(C.Lv/C.Rv.*(1.0./273.15-1.0./clim.T)) .* (clim.T>=273.15) + ...
        C.VP0.*exp(C.Ls/C.Rv.*(1.0./273.15-1.0./clim.T)) .* (clim.T<273.15);
clim.VP = clim.RH .* VPsat;
clim.q = clim.RH .* (VPsat .* C.eps ./ clim.Pres);

  
clim.VP = clim.RH .* VPsat;
clim.q = clim.RH .* (VPsat .* C.eps ./ clim.Pres);
% Air density (Dair)
clim.Dair = clim.Pres./C.Rd./clim.T;

% Time since last snow fall event (timelastsnow)
A.timelastsnow(clim.snow/(time.dt*24*3600)>C.Pthres) = time.TCUR;
if t==1
    A.timelastsnow(:) = time.TCUR; 
end

% Potential temperature (Theta)
clim.Theta = clim.T.*(C.Pref./clim.Pres).^(C.Rd/C.Cp);

A.climT = clim.T;
A.climP = clim.P;
A.climC = clim.C;
A.climRH = clim.RH;
A.climWS = clim.WS;
A.climPres = clim.Pres;
A.climsnow = clim.snow;
A.climrain = clim.rain;
A.climPreslapse = clim.Pres_lapse;
A.climPotlapse = clim.Theta_lapse;
A.climq = clim.q; 
A.climVP = clim.VP;

end