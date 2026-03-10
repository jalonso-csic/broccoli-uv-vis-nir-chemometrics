% BRC06c_obj3_Tier3_PLSR_NestedCV_SNV_SG1st_vs_SG2nd_v1.m
% ------------------------------------------------------------
% Objective 3 — Tier 3 screening (audit-ready) - TWO FACTORS (NO N)
% Same nested-CV PLS-R pipeline as Obj3, but applied to Tier 3 endpoints
% (numeric, non-spectral, non-factor; excluding Tier 1 and Tier 2), within
% the Pathernon × Ultrasonido (UAE) core.
%
% Preprocessing comparison:
%   (A) SNV + Savitzky–Golay 1st derivative (poly=2, window=11, Δ=1 nm)
%   (B) SNV + Savitzky–Golay 2nd derivative (poly=2, window=11, Δ=1 nm)
%
% Outputs are written to: ./Objetivo_3b
% ------------------------------------------------------------
clear; clc;

%% =========================
% USER PARAMETERS (EDIT)
% =========================
INPUT_XLSX  = 'Matriz_Brocoli_Sin_N.xlsx';
SHEET_NAME  = 'Matriz';

OUTDIR      = fullfile(pwd, 'Objetivo_3b');
if ~exist(OUTDIR,'dir'); mkdir(OUTDIR); end

% Core definition
CULTIVAR_CORE   = "Pathernon";
EXTRACTION_CORE = "Ultrasonido";

% Tier 1 (primary endpoints) — exact matrix headers (without Extraction_yield)
TIER1_LIST = string(["Total_phenolics","DPPH","ABTS","Antihypertensive_act."]);

% Tier 2 (class aggregates) — exact matrix headers
TIER2_LIST = string([
    "SUM_Amino_acids"
    "SUM_N_related"
    "SUM_OrgAcids"
    "SUM_GSL_aliphatic"
    "SUM_GSL_indolic"
    "SUM_GSL_breakdown"
    "SUM_Flavonols"
    "SUM_CQA"
    "SUM_Coumaroyl"
    "SUM_Sinapate_esters"
    "SUM_FA_saturated"
    "SUM_FA_unsaturated"
    "SUM_Oxylipins_oxygenated"
    "SUM_GSL_total"
    "SUM_Phenylpropanoids_total"
    "SUM_Lipids_total"
    "SUM_Phenolics_MS"
]);

% Optional: exclude some Tier 3 patterns (leave empty to include all)
% Examples:
%   EXCLUDE_REGEX = ["^B_cereus_","^S_aureus_","^L_innocua_"];
EXCLUDE_REGEX = string.empty(1,0);

% Y quality control (same as Obj.3)
MIN_N_NONNAN = 20;
MAX_NAN_FRAC = 0.30;

% Outer CV (repeated)
K_OUTER   = 5;
R_REPEATS = 50;
BASE_SEED = 12345;

% Inner CV for LV selection
K_INNER    = 4;
LV_MAX_CAP = 15;
LV_POLICY  = "minRMSE";

% Guardrail (recommended)
ENFORCE_PART_COVERAGE = true;
MAX_TRIES_FOLDS = 300;

% SG derivative parameters (SNV + SG 1st/2nd derivative)
SG_POLY_ORDER  = 2;
SG_FRAME_LEN   = 11; % odd
DELTA_NM       = 1;

% Standardise X after preprocessing (TRAIN statistics)
SCALE_X = true;

% Practical switches (Tier 3 can be computationally heavy)
WRITE_PREDICTIONS = false; % set true if you want the full audit trail per Y
SAVE_VIPRAW        = true;  % set false if you only want metrics now

%% =========================
% LOAD DATA (PRESERVE NAMES)
% =========================
fprintf('Loading: %s\n', INPUT_XLSX);
opts = detectImportOptions(INPUT_XLSX, 'Sheet', SHEET_NAME);
opts.VariableNamingRule = 'preserve';
T = readtable(INPUT_XLSX, opts);
fprintf('Rows: %d | Cols: %d\n', height(T), width(T));

%% =========================
% IDENTIFY FACTORS ROBUSTLY - N REMOVED
% =========================
colCodigo   = pickVarName(T, ["Codigo","Código","CODIGO","Code"]);
colVariedad = pickVarName(T, ["Variedad","Variety","Cultivar"]);
colParte    = pickVarName(T, ["Parte","Part"]);
colMad      = pickVarName(T, ["Maduracion","Maduración","Maturity"]);
colExt      = pickVarName(T, ["Extraccion","Extracción","Extraction"]);

assert(colVariedad~="" && colExt~="" && colParte~="" && colMad~="", ...
    'Missing required factor columns. Check matrix headers.');

factorCols = unique([colCodigo,colVariedad,colParte,colMad,colExt]);
factorCols = factorCols(factorCols ~= "");

%% =========================
% FILTER CORE
% =========================
varietyStr = string(T.(colVariedad));
extrStr    = string(T.(colExt));
isCore = strcmpi(strtrim(varietyStr), CULTIVAR_CORE) & strcmpi(strtrim(extrStr), EXTRACTION_CORE);
Tcore  = T(isCore, :);
fprintf('Core subset (Variedad=%s, Extraccion=%s): n = %d\n', CULTIVAR_CORE, EXTRACTION_CORE, height(Tcore));
assert(height(Tcore) >= MIN_N_NONNAN, 'Core subset too small for MIN_N_NONNAN.');

%% =========================
% EXTRACT X (SPECTRA) + WAVELENGTH VECTOR
% =========================
allNames = string(Tcore.Properties.VariableNames);
isSpec   = startsWith(allNames, "nm_");
specNames = allNames(isSpec);
assert(~isempty(specNames), 'No spectral columns found (expected "nm_*").');
Xraw = double(table2array(Tcore(:, specNames)));

wl = nan(numel(specNames),1);
for j=1:numel(specNames)
    tok = regexp(specNames(j), 'nm_(\d+)', 'tokens', 'once');
    if ~isempty(tok); wl(j) = str2double(tok{1}); end
end

%% =========================
% FACTORS & STRATA - N REMOVED
% =========================
Part = categorical(string(Tcore.(colParte)));
Mat  = categorical(string(Tcore.(colMad)));
strata = Mat; % stratification based on maturity only

%% =========================
% DEFINE TIER3S AUTOMATICALLY (QC + exclusions)
% =========================
[yTier3S, skipY] = buildTier3SList(Tcore, factorCols, TIER1_LIST, TIER2_LIST, ...
                                  MIN_N_NONNAN, MAX_NAN_FRAC, EXCLUDE_REGEX);

fprintf('Tier3S endpoints to model (after QC): %d\n', numel(yTier3S));

% Export included list + skipped list
writetable(table(yTier3S(:), 'VariableNames',{'Tier3S_Endpoint'}), fullfile(OUTDIR,'OBJ3S_Tier3S_Included.xlsx'));
writetable(skipY, fullfile(OUTDIR,'OBJ3S_Tier3S_Skipped.xlsx'));

%% =========================
% CONFIGS
% =========================
configs = struct([]);
configs(1).name = "SNV_SG1st";
configs(1).preprocessFcn = @(X) preprocess_snv_sg(X, SG_POLY_ORDER, SG_FRAME_LEN, 1, DELTA_NM);
configs(2).name = "SNV_SG2nd";
configs(2).preprocessFcn = @(X) preprocess_snv_sg(X, SG_POLY_ORDER, SG_FRAME_LEN, 2, DELTA_NM);

%% =========================
% RUN TIER3S
% =========================
runTier3S("Tier3S", yTier3S);
fprintf('\nOBJ3_TIER3S finished. Outputs in: %s\n', OUTDIR);

%% ============================================================
% LOCAL DRIVER
% ============================================================
function runTier3S(tierName, yList)
    OUTDIR      = evalin('base','OUTDIR');
    Tcore       = evalin('base','Tcore');
    Xraw        = evalin('base','Xraw');
    wl          = evalin('base','wl');
    Part        = evalin('base','Part');
    strata      = evalin('base','strata');
    configs     = evalin('base','configs');
    
    MIN_N_NONNAN = evalin('base','MIN_N_NONNAN');
    MAX_NAN_FRAC = evalin('base','MAX_NAN_FRAC');
    
    K_OUTER   = evalin('base','K_OUTER');
    R_REPEATS = evalin('base','R_REPEATS');
    BASE_SEED = evalin('base','BASE_SEED');
    K_INNER   = evalin('base','K_INNER');
    LV_MAX_CAP = evalin('base','LV_MAX_CAP');
    LV_POLICY  = evalin('base','LV_POLICY');
    ENFORCE_PART_COVERAGE = evalin('base','ENFORCE_PART_COVERAGE');
    MAX_TRIES_FOLDS = evalin('base','MAX_TRIES_FOLDS');
    SCALE_X = evalin('base','SCALE_X');
    
    WRITE_PREDICTIONS = evalin('base','WRITE_PREDICTIONS');
    SAVE_VIPRAW       = evalin('base','SAVE_VIPRAW');

    for c = 1:numel(configs)
        cfgName = configs(c).name;
        fprintf('\n=== OBJ3_TIER3S | %s | %s ===\n', tierName, cfgName);
        
        outSummary = table('Size',[0 16], ...
            'VariableTypes', {'string','double','double','double','double','double','double', ...
                              'double','double','double','double','double','double','double','double','double'}, ...
            'VariableNames', {'Y','n','R2_pooled','RMSE_pooled','MAE_pooled','Bias_pooled','RPD_pooled', ...
                              'R2_mean','R2_sd','RMSE_mean','RMSE_sd','MAE_mean','MAE_sd','Bias_mean','Bias_sd','LV_median'});
                          
        outRepeatsAll = table('Size',[0 8], ...
            'VariableTypes', {'string','double','double','double','double','double','double','double'}, ...
            'VariableNames', {'Y','repeat','R2','RMSE','MAE','Bias','RPD','LV_median'});
            
        VIP_STORE = struct();
        predBook = fullfile(OUTDIR, sprintf('OBJ3S_Predictions_%s_%s.xlsx', tierName, cfgName));
        if exist(predBook,'file'); delete(predBook); end

        for iY = 1:numel(yList)
            yName = yList(iY);
            if ~ismember(yName, string(Tcore.Properties.VariableNames))
                warning('%s Y not found in matrix: %s (skipping)', tierName, yName);
                continue;
            end
            
            yv = double(Tcore.(yName));
            nanFrac = mean(isnan(yv));
            nOK = sum(~isnan(yv));
            
            if nanFrac > MAX_NAN_FRAC || nOK < MIN_N_NONNAN || std(yv(~isnan(yv)))==0
                warning('Skipping Y=%s due to QC (nanFrac=%.2f, nOK=%d)', yName, nanFrac, nOK);
                continue;
            end
            
            valid = ~isnan(yv) & ~isundefined(Part) & ~isundefined(strata);
            X = Xraw(valid,:);
            y = yv(valid);
            part_v   = Part(valid);
            strata_v = strata(valid);
            
            params = struct();
            params.Kouter = K_OUTER;
            params.R      = R_REPEATS;
            params.baseSeed = BASE_SEED;
            params.Kinner = K_INNER;
            params.lvMaxCap = LV_MAX_CAP;
            params.lvPolicy = LV_POLICY;
            params.enforcePartCoverage = ENFORCE_PART_COVERAGE;
            params.maxTriesFolds = MAX_TRIES_FOLDS;
            params.scaleX = SCALE_X;
            
            [predLong, repMetrics, pooledMetrics, vipAll, lvAll] = ...
                runNestedPLSR(X, y, strata_v, part_v, configs(c).preprocessFcn, params);
                
            % Summary
            outSummary = [outSummary; { ...
                yName, numel(y), pooledMetrics.R2, pooledMetrics.RMSE, pooledMetrics.MAE, pooledMetrics.Bias, pooledMetrics.RPD, ...
                mean(repMetrics.R2), std(repMetrics.R2), ...
                mean(repMetrics.RMSE), std(repMetrics.RMSE), ...
                mean(repMetrics.MAE), std(repMetrics.MAE), ...
                mean(repMetrics.Bias), std(repMetrics.Bias), ...
                median(lvAll) ...
                }]; %#ok<AGROW>
                
            repMetrics.Y = repmat(yName, height(repMetrics), 1);
            outRepeatsAll = [outRepeatsAll; repMetrics(:, {'Y','repeat','R2','RMSE','MAE','Bias','RPD','LV_median'})]; %#ok<AGROW>
            
            % Predictions: optional
            if WRITE_PREDICTIONS
                writetable(predLong, predBook, 'Sheet', safeSheet(yName));
            end
            
            % Raw VIP: optional
            if SAVE_VIPRAW
                VIP_STORE.(matlab.lang.makeValidName(yName)).vip = vipAll;
                VIP_STORE.(matlab.lang.makeValidName(yName)).wl  = wl;
                VIP_STORE.(matlab.lang.makeValidName(yName)).lv  = lvAll;
            end
        end
        
        writetable(outSummary, fullfile(OUTDIR, sprintf('OBJ3S_Summary_%s_%s.xlsx', tierName, cfgName)), 'Sheet', 'Summary');
        writetable(outRepeatsAll, fullfile(OUTDIR, sprintf('OBJ3S_RepeatMetrics_%s_%s.xlsx', tierName, cfgName)), 'Sheet', 'RepeatMetrics');
        if SAVE_VIPRAW
            save(fullfile(OUTDIR, sprintf('OBJ3S_VIPraw_%s_%s.mat', tierName, cfgName)), 'VIP_STORE', '-v7.3');
        end
    end
end

function sh = safeSheet(name)
    name = char(name);
    name = regexprep(name, '[:\\/?*\[\]]', '_');
    if numel(name) > 31; sh = name(1:31); else; sh = name; end
end

%% =========================
% TIER3S BUILDER (QC + exclusion)
% =========================
function [tier3, skipY] = buildTier3SList(Tcore, factorCols, tier1, tier2, minN, maxNanFrac, excludeRegex)
    allNames = string(Tcore.Properties.VariableNames);
    isSpec   = startsWith(allNames, "nm_");
    isFactor = ismember(allNames, string(factorCols));
    yNamesAll = allNames(~isSpec & ~isFactor);
    
    tier3 = strings(0);
    skipY = table('Size',[0 3], 'VariableTypes',{'string','string','double'}, ...
                  'VariableNames',{'Y','Reason','nOK'});
                  
    for i = 1:numel(yNamesAll)
        yn = yNamesAll(i);
        
        % Remove Tier 1 / Tier 2
        if any(strcmpi(yn, tier1)) || any(strcmpi(yn, tier2))
            continue;
        end
        
        % Optional regex exclusions
        if ~isempty(excludeRegex)
            if any(arrayfun(@(rx) ~isempty(regexp(yn, rx, 'once')), excludeRegex))
                skipY = [skipY; {yn, "Excluded by EXCLUDE_REGEX", NaN}]; %#ok<AGROW>
                continue;
            end
        end
        
        yv = Tcore.(yn);
        
        if ~isnumeric(yv)
            skipY = [skipY; {yn, "Non-numeric", NaN}]; %#ok<AGROW>
            continue;
        end
        
        yv = double(yv);
        nanFrac = mean(isnan(yv));
        nOK = sum(~isnan(yv));
        
        if nanFrac > maxNanFrac
            skipY = [skipY; {yn, sprintf("Too many NaNs (%.1f%%)", 100*nanFrac), nOK}]; %#ok<AGROW>
            continue;
        end
        if nOK < minN
            skipY = [skipY; {yn, sprintf("Too few usable rows (n=%d)", nOK), nOK}]; %#ok<AGROW>
            continue;
        end
        if std(yv(~isnan(yv))) == 0
            skipY = [skipY; {yn, "Constant (zero variance)", nOK}]; %#ok<AGROW>
            continue;
        end
        
        tier3(end+1,1) = yn; %#ok<AGROW>
    end
end

%% ============================================================
% CORE FUNCTIONS
% ============================================================
function name = pickVarName(T, candidates)
    vars = string(T.Properties.VariableNames);
    name = "";
    for c = candidates
        idx = find(strcmpi(vars, c), 1);
        if ~isempty(idx); name = vars(idx); return; end
    end
    for c = candidates
        idx = find(contains(lower(vars), lower(c)), 1);
        if ~isempty(idx); name = vars(idx); return; end
    end
end

function Xsnv = preprocess_snv(X)
    mu = mean(X, 2, 'omitnan');
    sd = std(X, 0, 2, 'omitnan');
    sd(sd==0) = 1;
    Xsnv = (X - mu) ./ sd;
end

function Xout = preprocess_snv_sg(X, polyOrd, frameLen, derivOrd, delta)
    Xsnv = preprocess_snv(X);
    Xout = sg_derivative_rows(Xsnv, polyOrd, frameLen, derivOrd, delta);
end

function Xd = sg_derivative_rows(X, k, f, deriv, delta)
    if mod(f,2)==0; error('SG_FRAME_LEN must be odd.'); end
    [~, g] = sgolay(k, f);
    halfWin = (f-1)/2;
    dFilt = factorial(deriv) * g(:, deriv+1) / (delta^deriv);
    
    Xd = nan(size(X));
    for i=1:size(X,1)
        xi = X(i,:);
        leftPad  = fliplr(xi(2:halfWin+1));
        rightPad = fliplr(xi(end-halfWin:end-1));
        xpad = [leftPad, xi, rightPad];
        yi = conv(xpad, fliplr(dFilt').', 'same');
        yi = yi(halfWin+1:end-halfWin);
        Xd(i,:) = yi;
    end
end

function [predLong, repMetrics, pooledMetrics, vipAll, lvAll] = runNestedPLSR(X, y, strata, part, preprocessFcn, params)
    n = numel(y);
    K = params.Kouter;
    R = params.R;
    
    predLong = table('Size',[0 6], ...
        'VariableTypes', {'double','double','double','double','double','double'}, ...
        'VariableNames', {'row','repeat','fold','y_true','y_pred','LV'});
        
    repMetrics = table('Size',[R 7], ...
        'VariableTypes', {'double','double','double','double','double','double','double'}, ...
        'VariableNames', {'repeat','R2','RMSE','MAE','Bias','RPD','LV_median'});
        
    vipAll = [];
    lvAll  = [];
    
    for r = 1:R
        rng(params.baseSeed + r, 'twister');
        foldID = makeStratifiedFolds(strata, K, part, params.enforcePartCoverage, params.maxTriesFolds);
        
        yhat_r = nan(n,1);
        lv_r   = nan(n,1);
        
        for k = 1:K
            testIdx  = (foldID == k);
            trainIdx = ~testIdx;
            
            Xtr = X(trainIdx,:); ytr = y(trainIdx);
            Xte = X(testIdx,:);  yte = y(testIdx);
            
            Xtr_p = preprocessFcn(Xtr);
            Xte_p = preprocessFcn(Xte);
            
            if params.scaleX
                [Xtr_p, muX, sdX] = centreScale(Xtr_p);
                Xte_p = applyCentreScale(Xte_p, muX, sdX);
            end
            
            lvMax = min(params.lvMaxCap, size(Xtr_p,1)-2);
            lvMax = max(1, min(lvMax, size(Xtr_p,2)));
            
            lvSel = selectLV_innerCV(Xtr_p, ytr, params.Kinner, lvMax);
            
            [~,~,~,~,beta,PCTVAR,~,stats] = plsregress(Xtr_p, ytr, lvSel);
            ypred = [ones(size(Xte_p,1),1), Xte_p] * beta;
            
            rowsTest = find(testIdx);
            yhat_r(testIdx) = ypred;
            lv_r(testIdx)   = lvSel;
            
            vip = vip_plsr(stats, PCTVAR, size(Xtr_p,2));
            vipAll = [vipAll, vip(:)]; %#ok<AGROW>
            lvAll  = [lvAll; lvSel]; %#ok<AGROW>
            
            tmp = table(rowsTest, repmat(r, numel(rowsTest),1), repmat(k, numel(rowsTest),1), yte, ypred, repmat(lvSel, numel(rowsTest),1), ...
                'VariableNames', {'row','repeat','fold','y_true','y_pred','LV'});
            predLong = [predLong; tmp]; %#ok<AGROW>
        end
        
        m = computeMetrics(y, yhat_r);
        repMetrics.repeat(r)   = r;
        repMetrics.R2(r)       = m.R2;
        repMetrics.RMSE(r)     = m.RMSE;
        repMetrics.MAE(r)      = m.MAE;
        repMetrics.Bias(r)     = m.Bias;
        repMetrics.RPD(r)      = m.RPD;
        repMetrics.LV_median(r)= median(lv_r, 'omitnan');
    end
    
    pooledMetrics = computeMetrics(predLong.y_true, predLong.y_pred);
end

function foldID = makeStratifiedFolds(strata, K, part, enforcePartCoverage, maxTries)
    n = numel(strata);
    foldID = zeros(n,1);
    
    for t = 1:maxTries
        foldID(:) = 0;
        cats = categories(strata);
        for i=1:numel(cats)
            idx = find(strata == cats{i});
            idx = idx(randperm(numel(idx)));
            for j=1:numel(idx)
                foldID(idx(j)) = mod(j-1, K) + 1;
            end
        end
        
        if ~enforcePartCoverage; return; end
        
        ok = true;
        partsAll = categories(part);
        for k=1:K
            trainIdx = (foldID ~= k);
            pTrain = categories(removecats(part(trainIdx)));
            if numel(pTrain) < numel(partsAll)
                ok = false; break;
            end
        end
        if ok; return; end
    end
    error('Could not create stratified folds satisfying Part coverage after %d tries.', maxTries);
end

function lvSel = selectLV_innerCV(Xtr, ytr, Kinner, lvMax)
    n = numel(ytr);
    cv = cvpartition(n, 'KFold', Kinner);
    rmse = nan(lvMax,1);
    
    for lv = 1:lvMax
        yhat = nan(n,1);
        for k=1:Kinner
            tr = training(cv,k);
            te = test(cv,k);
            [~,~,~,~,beta] = plsregress(Xtr(tr,:), ytr(tr), lv);
            yhat(te) = [ones(sum(te),1), Xtr(te,:)] * beta;
        end
        rmse(lv) = sqrt(mean((ytr - yhat).^2, 'omitnan'));
    end
    [~, lvSel] = min(rmse);
end

function [Xcs, muX, sdX] = centreScale(X)
    muX = mean(X, 1, 'omitnan');
    sdX = std(X, 0, 1, 'omitnan');
    sdX(sdX==0) = 1;
    Xcs = (X - muX) ./ sdX;
end

function Xcs = applyCentreScale(X, muX, sdX)
    Xcs = (X - muX) ./ sdX;
end

function vip = vip_plsr(stats, PCTVAR, p)
    W = stats.W;
    LV = size(W,2);
    if size(PCTVAR,1) >= 2
        yExp = PCTVAR(2,1:LV);
    else
        yExp = ones(1,LV)/LV;
    end
    denom = sum(yExp); if denom==0; denom=eps; end
    vip = zeros(p,1);
    for j=1:p
        vip(j) = sqrt( p * sum( yExp(:) .* (W(j,:).^2)' ) / denom );
    end
end

function m = computeMetrics(y, yhat)
    y = y(:); yhat = yhat(:);
    ok = ~isnan(y) & ~isnan(yhat);
    y = y(ok); yhat = yhat(ok);
    
    SSE = sum((y - yhat).^2);
    SST = sum((y - mean(y)).^2);
    m.R2   = 1 - SSE / max(SST, eps);
    m.RMSE = sqrt(mean((y - yhat).^2));
    m.MAE  = mean(abs(y - yhat));
    m.Bias = mean(yhat - y);
    m.RPD  = std(y) / max(m.RMSE, eps);
end