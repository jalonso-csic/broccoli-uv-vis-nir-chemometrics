% BRC07_obj4_VIPStability_SelectedTiers_FigsAndBands_SNV_SG2nd_v1.m
% ------------------------------------------------------------
% Objective 4 (Q1-ready) - TWO FACTORS (NO N):
% VIP stability figures + operational band export
%
% Main preprocessing: SNV + Savitzky–Golay 2nd derivative (poly=2, window=11)
%
% What this script produces
%   Figure 1: VIP stability heatmap for Tier 1 + selected Tier 2 + selected Tier 3S
%             (custom manual order applied as requested).
%   Figure 2: VIP stability line profiles for selected Tier 3S indoles.
%   Excel:    Stable nm list + stable contiguous regions (audit/operational output).
%
% VIP stability definition
%   VIP is normalised per model to mean(VIP)=1 across wavelengths:
%       VIP_norm = VIP ./ mean(VIP,2)
%   Stability(λ) = proportion of models with VIP_norm(λ) > 1.
%
% Stable region rule
%   stability >= STAB_THR AND contiguous run length >= MIN_BANDS
% ------------------------------------------------------------
clear; clc;

%% =========================
% USER SETTINGS
% =========================
% If the Obj3 output folder is known, set it here (ASCII path preferred).
% Leave empty "" to auto-detect via common relative paths or via GUI.
OBJ3DIR_MANUAL = "";

% Output folder (required by the manuscript workflow)
OUTDIR = fullfile(pwd, 'Objetivo_4');
if ~exist(OUTDIR,'dir'); mkdir(OUTDIR); end

% Strict manual order requested for Figure 1
Tier1_All = ["Antihypertensive_act.", "Total_phenolics", "ABTS", "DPPH"];
Tier2_Sel = ["SUM_GSL_total", "SUM_GSL_indolic"]; % Amino acids removed
Tier3_Sel = ["Glucobrassicin", "Methoxyglucobrassicin_1", "Methoxyglucobrassicin_2"];

% Stability parameters
STAB_THR  = 0.80;    % <--- Stability threshold changed to 0.80
MIN_BANDS = 25;      % contiguous bands required for a region (1 nm grid)

% Figure styling
FONT_MAIN = 'Times New Roman';
FS_AX     = 10;
FS_LAB    = 12;
FS_TTL    = 12;
PNG_DPI   = 400;

%% =========================
% LOCATE OBJ3 OUT folder
% =========================
OBJ3DIR = string(OBJ3DIR_MANUAL);
if strlength(OBJ3DIR)==0 || ~(exist(OBJ3DIR,'dir')==7)
    % Try common relative locations from the current folder (CELL array!)
    candDirs = { ...
        fullfile(pwd, 'OBJ3_OUT'); ...
        fullfile(pwd, '..', 'OBJ3_OUT'); ...
        fullfile(pwd, 'OBJ3', 'OBJ3_OUT'); ...
        fullfile(pwd, '..', 'OBJ3', 'OBJ3_OUT'); ...
        fullfile(pwd, 'Objetivo_3a'); ...
        fullfile(pwd, 'Objetivo_3b') ...
    };
    found = false;
    for i=1:numel(candDirs)
        if exist(candDirs{i},'dir')==7
            OBJ3DIR = string(candDirs{i});
            found = true;
            break;
        end
    end
    if ~found
        fprintf('\nOBJ3 folder not found automatically.\n');
        tmp = uigetdir(pwd, 'Select your OBJ3 folder');
        assert(~isequal(tmp,0), 'No OBJ3 folder selected.');
        OBJ3DIR = string(tmp);
    end
end
fprintf('OBJ3DIR = %s\n', OBJ3DIR);

%% =========================
% ORDER ENDPOINTS
% =========================
% Automatic R2-based ordering has been disabled in order to preserve
% the requested strict manual order.
labelsRaw = [Tier1_All, Tier2_Sel, Tier3_Sel];
nY = numel(labelsRaw);

%% =========================
% AUTO-DETECT VIPraw MAT FILES (SNV+SG2nd)
% =========================
MAT_T1 = pickMat(char(OBJ3DIR), '*Tier1*SNV*SG2nd*.mat',  'Tier1 VIPraw (SNV+SG2nd)');
MAT_T2 = pickMat(char(OBJ3DIR), '*Tier2*SNV*SG2nd*.mat',  'Tier2 VIPraw (SNV+SG2nd)');
MAT_T3 = pickMat(char(OBJ3DIR), '*Tier3S*SNV*SG2nd*.mat', 'Tier3S VIPraw (SNV+SG2nd)');

% Load VIP stores
VIP1 = loadVipStore(MAT_T1);
VIP2 = loadVipStore(MAT_T2);
VIP3 = loadVipStore(MAT_T3);

%% =========================
% BUILD STABILITY MATRIX (Tier 1 + selected Tier 2 + selected Tier 3)
% =========================
[wl, p] = getWavelengthFromAny(VIP1, VIP2, VIP3, labelsRaw);
StabMat = nan(nY, p);

for i = 1:nY
    y = labelsRaw(i);
    [vip, wl_local] = fetchVIP(VIP1, VIP2, VIP3, y);
    assert(numel(wl_local)==p, 'Wavelength length mismatch for %s', y);
    
    [stab, ~] = vipStability(vip);
    StabMat(i,:) = stab(:)';
end

%% =========================
% FIGURE 1 — HEATMAP (Tier 1 top → Tier 3 bottom)
% =========================
fig1 = figure('Color','w','Units','pixels','Position',[80 80 1450 640]);

imagesc(wl, 1:nY, StabMat);
set(gca,'YDir','reverse');   % row 1 at TOP
caxis([0 1]);
cb = colorbar;
ylabel(cb, 'VIP stability', 'FontName',FONT_MAIN,'FontSize',FS_AX);

yticks(1:nY);
yticklabels(prettyLabels(labelsRaw));
set(gca,'FontName',FONT_MAIN,'FontSize',FS_AX,'TickLabelInterpreter','none');

xlabel('Wavelength (nm)', 'FontName',FONT_MAIN,'FontSize',FS_LAB);
title('VIP stability map (SNV + Savitzky–Golay 2nd derivative) — Tier 1 + selected Tier 2 + selected Tier 3', ...
    'FontName',FONT_MAIN,'FontSize',FS_TTL);

drawnow;
saveas(fig1, fullfile(OUTDIR, 'Fig_OBJ4_VIPStability_Combined_T1_T2sel_T3sel_SNV_SG2nd.fig'));
exportgraphics(fig1, fullfile(OUTDIR, 'Fig_OBJ4_VIPStability_Combined_T1_T2sel_T3sel_SNV_SG2nd.png'), 'Resolution', PNG_DPI);

%% =========================
% FIGURE 2 — LINES (selected Tier 3 indoles)
% =========================
fig2 = figure('Color','w','Units','pixels','Position',[80 80 1450 520]);
hold on;

for i = 1:numel(Tier3_Sel)
    y = Tier3_Sel(i);
    [vip, wl_local] = fetchVIP(VIP1, VIP2, VIP3, y);
    [stab, ~] = vipStability(vip);
    plot(wl_local, stab, 'LineWidth', 1.4, 'DisplayName', prettyLabels(y));
end

% Stability threshold line (now set to 0.80)
yline(STAB_THR, '--', 'LineWidth', 1.0, ...
    'DisplayName', sprintf('Stability threshold (%.2f)', STAB_THR));

ylim([0 1.05]);
xlim([wl(1) wl(end)]);
set(gca,'FontName',FONT_MAIN,'FontSize',FS_AX);
xlabel('Wavelength (nm)', 'FontName',FONT_MAIN,'FontSize',FS_LAB);
ylabel('VIP stability', 'FontName',FONT_MAIN,'FontSize',FS_LAB);
title('VIP stability profiles (SNV + Savitzky–Golay 2nd derivative) — selected Tier 3 indoles', ...
    'FontName',FONT_MAIN,'FontSize',FS_TTL);

lgd = legend('Location','southoutside','NumColumns',2);
set(lgd,'FontName',FONT_MAIN,'FontSize',FS_AX);
box on; grid off;

drawnow;
saveas(fig2, fullfile(OUTDIR, 'Fig_OBJ4_VIPStability_Tier3SelLines_SNV_SG2nd.fig'));
exportgraphics(fig2, fullfile(OUTDIR, 'Fig_OBJ4_VIPStability_Tier3SelLines_SNV_SG2nd.png'), 'Resolution', PNG_DPI);

%% =========================
% EXCEL EXPORT — stable nm + stable regions + counts
% =========================
stableBands   = table();
stableRegions = table();

counts        = table('Size',[nY 4], ...
    'VariableTypes', {'string','double','double','double'}, ...
    'VariableNames', {'Endpoint','nStableNm','nRegions','maxStability'});

for i = 1:nY
    y = labelsRaw(i);
    yLab = string(prettyLabels(y));
    
    [vip, wl_local] = fetchVIP(VIP1, VIP2, VIP3, y);
    [stab, meanVIP] = vipStability(vip);
    
    % nm list
    idx = find(stab >= STAB_THR);
    if ~isempty(idx)
        Tb = table();
        Tb.Endpoint  = repmat(yLab, numel(idx), 1);
        Tb.nm        = wl_local(idx);
        Tb.stability = stab(idx);
        Tb.meanVIP   = meanVIP(idx);
        stableBands  = [stableBands; Tb]; %#ok<AGROW>
    end
    
    % regions
    Tr = regionsFromMask(wl_local, stab, meanVIP, STAB_THR, MIN_BANDS);
    if ~isempty(Tr)
        Tr.Endpoint = repmat(yLab, height(Tr), 1);
        stableRegions = [stableRegions; Tr]; %#ok<AGROW>
    end
    
    counts.Endpoint(i)     = yLab;
    counts.nStableNm(i)    = numel(idx);
    counts.nRegions(i)     = height(Tr);
    counts.maxStability(i) = max(stab, [], 'omitnan');
end

xlsxOut = fullfile(OUTDIR, 'OBJ4_StableBands_SelectedEndpoints_SNV_SG2nd.xlsx');
writetable(stableRegions, xlsxOut, 'Sheet', 'StableRegions');
writetable(stableBands,   xlsxOut, 'Sheet', 'StableBands_nm');
writetable(counts,        xlsxOut, 'Sheet', 'Counts');

fprintf('\nOBJ4 outputs written to:\n  %s\n', OUTDIR);
fprintf('Excel stable bands written to:\n  %s\n\n', xlsxOut);


%% ============================================================
% LOCAL FUNCTIONS
% ============================================================

function matPath = pickMat(folder, pattern, label)
    cand = dir(fullfile(folder, pattern));
    
    % Also search in objective subfolders if the script does not find files
    % directly in the selected root.
    if isempty(cand)
        cand = dir(fullfile(pwd, 'Objetivo_3*', pattern));
    end
    
    if isempty(cand)
        fprintf('\nCould not auto-detect %s MAT in:\n%s\n', label, folder);
        [f,p] = uigetfile('*.mat', ['Select ' label]);
        assert(~isequal(f,0), 'No MAT selected for %s.', label);
        matPath = fullfile(p,f);
    else
        matPath = fullfile(cand(1).folder, cand(1).name);
    end
    fprintf('Using %s: %s\n', label, matPath);
end

function VIP_STORE = loadVipStore(matPath)
    S = load(matPath);
    assert(isfield(S,'VIP_STORE'), 'MAT does not contain VIP_STORE: %s', matPath);
    VIP_STORE = S.VIP_STORE;
end

function [wl, p] = getWavelengthFromAny(VIP1, VIP2, VIP3, labelsRaw)
    wl = [];
    for i=1:numel(labelsRaw)
        yv = matlab.lang.makeValidName(labelsRaw(i));
        if isfield(VIP1, yv); wl = double(VIP1.(yv).wl(:)); break; end
        if isfield(VIP2, yv); wl = double(VIP2.(yv).wl(:)); break; end
        if isfield(VIP3, yv); wl = double(VIP3.(yv).wl(:)); break; end
    end
    assert(~isempty(wl), 'Could not find wavelength vector (wl) in any VIP_STORE.');
    p = numel(wl);
end

function [vip, wl] = fetchVIP(VIP1, VIP2, VIP3, y)
    yv = matlab.lang.makeValidName(y);
    
    if isfield(VIP1, yv)
        vip = double(VIP1.(yv).vip);
        wl  = double(VIP1.(yv).wl(:));
        vip = orientVIP(vip, numel(wl));
        return;
    end
    if isfield(VIP2, yv)
        vip = double(VIP2.(yv).vip);
        wl  = double(VIP2.(yv).wl(:));
        vip = orientVIP(vip, numel(wl));
        return;
    end
    if isfield(VIP3, yv)
        vip = double(VIP3.(yv).vip);
        wl  = double(VIP3.(yv).wl(:));
        vip = orientVIP(vip, numel(wl));
        return;
    end
    
    error('Endpoint not found in VIP stores: %s', y);
end

function vip = orientVIP(vip, p)
    if size(vip,2) ~= p && size(vip,1) == p
        vip = vip.'; % transpose if [p x nModels]
    end
    assert(size(vip,2)==p, 'VIP has unexpected size; expected p=%d columns.', p);
end

function [stab, meanVIP] = vipStability(vip)
    mu = mean(vip, 2, 'omitnan');
    mu(mu==0) = 1;
    
    vipN = vip ./ mu;                    % per-model mean=1
    stab = mean(vipN > 1, 1, 'omitnan'); % [1 x p]
    meanVIP = mean(vipN, 1, 'omitnan');  % [1 x p]
    
    stab = stab(:);
    meanVIP = meanVIP(:);
end

function Tr = regionsFromMask(wl, stab, meanVIP, thr, minBands)
    mask = stab >= thr;
    Tr = table();
    if ~any(mask); return; end
    
    idx = find(mask);
    starts = idx([true; diff(idx) > 1]);
    ends   = idx([diff(idx) > 1; true]);
    
    keep = (ends - starts + 1) >= minBands;
    starts = starts(keep);
    ends   = ends(keep);
    
    if isempty(starts); return; end
    
    nR = numel(starts);
    Tr = table('Size',[nR 8], ...
        'VariableTypes', {'double','double','double','double','double','double','double','double'}, ...
        'VariableNames', {'start_nm','end_nm','width_nm','n_bands','mean_stability','max_stability','mean_VIP','max_meanVIP'});
        
    for r = 1:nR
        s = starts(r); e = ends(r);
        seg = s:e;
        
        Tr.start_nm(r) = wl(s);
        Tr.end_nm(r)   = wl(e);
        Tr.width_nm(r) = wl(e) - wl(s);
        Tr.n_bands(r)  = numel(seg);
        Tr.mean_stability(r) = mean(stab(seg), 'omitnan');
        Tr.max_stability(r)  = max(stab(seg), [], 'omitnan');
        Tr.mean_VIP(r)       = mean(meanVIP(seg), 'omitnan');
        Tr.max_meanVIP(r)    = max(meanVIP(seg), [], 'omitnan');
    end
end

function out = prettyLabels(names)
    names = string(names);
    out = strings(size(names));
    for i=1:numel(names)
        s = names(i);
        
        % Remove SUM_ (labels only)
        s = regexprep(s, '^(?i)SUM_', '');
        % Replace underscores with spaces
        s = replace(s, "_", " ");
        s = strtrim(regexprep(s, '\s+', ' '));
        
        % Targeted pretty names
        if contains(lower(s), "antihypertensive")
            s = "Antihypertensive activity";
        end
        if strcmpi(s, "GSL indolic"); s = "Indolic glucosinolates"; end
        if strcmpi(s, "GSL total");   s = "Total glucosinolates"; end
        
        out(i) = s;
    end
end