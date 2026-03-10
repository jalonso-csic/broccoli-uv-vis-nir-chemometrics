% ------------------------------------------------------------
% Objective 5 (within-domain prioritisation; decision support)
% Figures (PNG + FIG) + Excel compilation.
%
% Updates:
%   1. Automatic script name detection.
%   2. TWO FACTORS (NO N).
%   3. FIGURE 1 SPLIT INTO TWO PANELS:
%       - Fig 1A: Tier 1 & 2 (strict manual order)
%       - Fig 1B: Tier 3 (selected metabolites ordered by chemical similarity)
%   4. Composite score ranking based on Tier 1 & 2.
%
% Core domain: Pathernon × Ultrasonido (UAE).
% ------------------------------------------------------------
clear; clc; close all;

%% =========================
% 1. AUTOMATIC SCRIPT NAME DETECTION
% =========================
scriptName = mfilename; 
if isempty(scriptName); scriptName = 'BRC10_obj5_Prioritisation_v1'; end
fprintf('Running script: %s\n', scriptName);

%% =========================
% USER PARAMETERS
% =========================
INPUT_XLSX  = 'Matriz_Brocoli_Sin_N.xlsx';
SHEET_NAME  = 'Matriz';

OUTDIR = fullfile(pwd, 'Objetivo_5');
if ~exist(OUTDIR,'dir'); mkdir(OUTDIR); end

CULTIVAR_CORE   = "Pathernon";
EXTRACTION_CORE = "Ultrasonido";
TOPN_PROFILE    = 15;    
RHO_THRESHOLD   = 0.85;  

% ---------------------------------------------------------
% CRITERIA LISTS (variables)
% ---------------------------------------------------------

% LIST 1: TIER 1 and TIER 2 (strict manual order)
CRIT_T1T2 = string([
    "Antihypertensive_act."
    "Total_phenolics"
    "ABTS"
    "DPPH"
    "SUM_GSL_total"
    "SUM_GSL_indolic"
]);

% LIST 2: TIER 3 (ordered by chemical similarity: GSL -> flavonols -> amino acids)
CRIT_T3 = string([
    "Glucobrassicin"
    "Methoxyglucobrassicin_1"
    "Methoxyglucobrassicin_2"
    "Km_3_diglucoside_7_diglucoside"
    "K_3_O_sinapoyldiglucoside"
    "L_Phenylalanine"
]);

% Combination used for the correlation matrix (redundancy audit)
CRIT_FULL = [CRIT_T1T2; CRIT_T3];

% Global ranking (prioritisation) is based on the primary functional profile
CRIT_NONRED = CRIT_T1T2;
WEIGHTS = ones(numel(CRIT_NONRED),1);

%% =========================
% LOAD DATA
% =========================
fprintf('Loading: %s\n', INPUT_XLSX);
opts = detectImportOptions(INPUT_XLSX, 'Sheet', SHEET_NAME);
opts.VariableNamingRule = 'preserve';
T = readtable(INPUT_XLSX, opts);

%% =========================
% IDENTIFY FACTOR COLUMNS (NO N)
% =========================
colVar = pickVarName(T, ["Variedad","Variety","Cultivar"]);
colExt = pickVarName(T, ["Extraccion","Extracción","Extraction"]);
colPart= pickVarName(T, ["Parte","Part"]);
colMat = pickVarName(T, ["Maduracion","Maduración","Maturity"]);

assert(colVar~="" && colExt~="" && colPart~="" && colMat~="", ...
    'Missing required factor columns.');

%% =========================
% FILTER CORE DOMAIN
% =========================
varStr = string(T.(colVar));
extStr = string(T.(colExt));
isCore = strcmpi(strtrim(varStr), CULTIVAR_CORE) & strcmpi(strtrim(extStr), EXTRACTION_CORE);
Tcore  = T(isCore, :);
fprintf('Core subset (%s × %s): n = %d\n', CULTIVAR_CORE, EXTRACTION_CORE, height(Tcore));
assert(height(Tcore) > 0, 'Core subset is empty.');

%% =========================
% CHECK AVAILABLE CRITERIA
% =========================
have = string(Tcore.Properties.VariableNames);

% Alert if missing
missing_t1 = CRIT_T1T2(~ismember(CRIT_T1T2, have));
if ~isempty(missing_t1), warning("Faltan variables T1/T2: " + strjoin(missing_t1, ", ")); end
missing_t3 = CRIT_T3(~ismember(CRIT_T3, have));
if ~isempty(missing_t3), warning("Faltan variables T3: " + strjoin(missing_t3, ", ")); end

CRIT_T1T2 = CRIT_T1T2(ismember(CRIT_T1T2, have));
CRIT_T3   = CRIT_T3(ismember(CRIT_T3, have));
CRIT_FULL = [CRIT_T1T2; CRIT_T3];
CRIT_NONRED = CRIT_T1T2; 

WEIGHTS = WEIGHTS(1:numel(CRIT_NONRED));
WEIGHTS = WEIGHTS(:);

%% =========================
% TRANSLATE FACTORS & COMBINATION LABELS (NO N)
% =========================
PartE = translatePart(string(Tcore.(colPart)));
MatE  = translateMaturity(string(Tcore.(colMat)));

combo = strcat(PartE, " | ", MatE);

%% =========================
% ROBUST Z SCORES
% =========================
Z_t1t2 = nan(height(Tcore), numel(CRIT_T1T2));
for j = 1:numel(CRIT_T1T2)
    Z_t1t2(:,j) = robustZ(double(Tcore.(CRIT_T1T2(j))));
end

Z_t3 = nan(height(Tcore), numel(CRIT_T3));
for j = 1:numel(CRIT_T3)
    Z_t3(:,j) = robustZ(double(Tcore.(CRIT_T3(j))));
end

Zfull = [Z_t1t2, Z_t3];

%% =========================
% GROUP BY COMBINATION
% =========================
G = findgroups(combo);
comboList = splitapply(@(x) x(1), combo, G);
nPerGroup = splitapply(@numel, combo, G);

partG = splitapply(@(x) x(1), PartE, G);
matG  = splitapply(@(x) x(1), MatE,  G);

pmLabel = strcat(partG, " | ", matG); 

% Robust-Z medians
zMed_t1t2 = nan(max(G), numel(CRIT_T1T2));
for j = 1:numel(CRIT_T1T2)
    zMed_t1t2(:,j) = splitapply(@(x) median(x,'omitnan'), Z_t1t2(:,j), G);
end

zMed_t3 = nan(max(G), numel(CRIT_T3));
for j = 1:numel(CRIT_T3)
    zMed_t3(:,j) = splitapply(@(x) median(x,'omitnan'), Z_t3(:,j), G);
end

%% =========================
% COMPOSITE SCORES (based on Tier 1 / Tier 2)
% =========================
W = WEIGHTS ./ max(sum(WEIGHTS), eps);

% Tier 1 / Tier 2 percentiles
P_t1t2 = calcPercentile(zMed_t1t2);
% Tier 3 percentiles
P_t3 = calcPercentile(zMed_t3);

% Score_Z and Score_P use Tier 1 / Tier 2 only for ranking
maskZ = ~isnan(zMed_t1t2);
scoreZ = sum(zMed_t1t2 .* (W'.*maskZ), 2) ./ max(sum(W'.*maskZ,2), eps);

maskP = ~isnan(P_t1t2);
scoreP = sum(P_t1t2 .* (W'.*maskP), 2) ./ max(sum(W'.*maskP,2), eps);

[scoreSorted, ord] = sort(scoreP, 'descend');
comboSorted = comboList(ord);

%% =========================
% Y-AXIS ORDERING FOR THE HEATMAPS
% =========================
partOrder = ["Leaf","Inflorescence","Stem"];
matOrder  = ["Bud","Commercial","Over-mature"];

p = strtrim(string(partG));
m = strtrim(string(matG));

[tfP, partOrdAll] = ismember(lower(p), lower(partOrder));
[tfM, matOrdAll]  = ismember(lower(m), lower(matOrder));
partOrdAll(~tfP) = numel(partOrder) + 1;
matOrdAll(~tfM)  = numel(matOrder)  + 1;

[~, sAll] = sortrows([partOrdAll(:), matOrdAll(:)]);

Yplot = pmLabel(sAll);

%% =========================
% DISPLAY NAMES
% =========================
dispT1T2 = prettyCritNames(CRIT_T1T2);
dispT3   = prettyCritNames(CRIT_T3);
dispFull = [dispT1T2; dispT3];

%% =========================
% FIGURE 1A: Criterion Profile (Tier 1 & 2)
% =========================
Mplot_t1t2 = P_t1t2(sAll, :);

fig1A = figure('Color','w','Position',[80 80 800 650]);
imagesc(Mplot_t1t2); axis tight; caxis([0 1]);

set(gca,'YTick',1:numel(Yplot),'YTickLabel',Yplot, ...
        'XTick',1:numel(dispT1T2),'XTickLabel',dispT1T2, ...
        'FontName','Times New Roman','FontSize',10);
xtickangle(35);

ylabel('Part × maturity (ordered)', 'FontName','Times New Roman','FontSize',12);
title('Criterion-level profiles: Tier 1 & Tier 2', 'FontName','Times New Roman','FontSize',12);
cb = colorbar; ylabel(cb, 'Percentile rank (0–1)', 'FontName','Times New Roman','FontSize',10);

saveBoth(fig1A, OUTDIR, 'Fig_obj5_1A_Profile_Tier1_Tier2');

%% =========================
% FIGURE 1B: Criterion Profile (Tier 3)
% =========================
Mplot_t3 = P_t3(sAll, :);

fig1B = figure('Color','w','Position',[120 120 800 650]);
imagesc(Mplot_t3); axis tight; caxis([0 1]);

set(gca,'YTick',1:numel(Yplot),'YTickLabel',Yplot, ...
        'XTick',1:numel(dispT3),'XTickLabel',dispT3, ...
        'FontName','Times New Roman','FontSize',10);
xtickangle(35);

ylabel('Part × maturity (ordered)', 'FontName','Times New Roman','FontSize',12);
title('Criterion-level profiles: Selected Tier 3 Metabolites', 'FontName','Times New Roman','FontSize',12);
cb = colorbar; ylabel(cb, 'Percentile rank (0–1)', 'FontName','Times New Roman','FontSize',10);

saveBoth(fig1B, OUTDIR, 'Fig_obj5_1B_Profile_Tier3_Selected');

%% =========================
% FIGURE 2: Ranking
% =========================
fig2 = figure('Color','w','Position',[160 160 1000 600]);
barh(scoreSorted);
set(gca,'YDir','reverse', ...
        'YTick',1:numel(scoreSorted), 'YTickLabel',comboSorted, ...
        'FontName','Times New Roman','FontSize',10);
xlabel('Composite prioritisation score (0–1)', 'FontName','Times New Roman','FontSize',12);
title('Objective 5: Within-domain prioritisation (Based on Tier 1 & 2)', 'FontName','Times New Roman','FontSize',12);
grid on;

saveBoth(fig2, OUTDIR, 'Fig_obj5_2_Ranking_CompositePCTL');

%% =========================
% FIGURE 3: Redundancy Audit (all criteria together)
% =========================
rho = corr(Zfull, 'Type','Spearman', 'Rows','pairwise');

fig3 = figure('Color','w','Position',[200 200 860 760]);
imagesc(rho); axis square; caxis([-1 1]);
cb = colorbar; ylabel(cb, 'Spearman \rho', 'FontName','Times New Roman','FontSize',10);

set(gca,'XTick',1:numel(dispFull),'XTickLabel',dispFull, ...
        'YTick',1:numel(dispFull),'YTickLabel',dispFull, ...
        'FontName','Times New Roman','FontSize',10);
xtickangle(40);
title(sprintf('Redundancy audit; |\\rho| threshold = %.2f', RHO_THRESHOLD), ...
      'FontName','Times New Roman','FontSize',12);

saveBoth(fig3, OUTDIR, 'Fig_obj5_S1_RedundancyAudit');

%% =========================
% EXPORT EXCEL
% =========================
XLSX_OUT = fullfile(OUTDIR, "obj5_Prioritisation_Summary.xlsx");

zSorted_T1T2 = zMed_t1t2(ord, :);
pSorted_T1T2 = P_t1t2(ord, :);
zSorted_T3   = zMed_t3(ord, :);
pSorted_T3   = P_t3(ord, :);
nSorted      = nPerGroup(ord);
scoreZ_sorted = scoreZ(ord);

Tsum = table(comboSorted, nSorted, scoreSorted, scoreZ_sorted, ...
    'VariableNames', {'Combination','n','CompositeScore_PCTL','CompositeScore_robustZ'});

% Add Tier 1 / Tier 2 variables to the Excel export
for j = 1:numel(CRIT_T1T2)
    v = "Pctl_" + matlab.lang.makeValidName(char(CRIT_T1T2(j)));
    Tsum.(v) = pSorted_T1T2(:,j);
end
% Add Tier 3 variables to the Excel export
for j = 1:numel(CRIT_T3)
    v = "Pctl_" + matlab.lang.makeValidName(char(CRIT_T3(j)));
    Tsum.(v) = pSorted_T3(:,j);
end

writetable(Tsum, XLSX_OUT, 'Sheet', 'Ranking_All');

topN = min(TOPN_PROFILE, height(Tsum));
writetable(Tsum(1:topN,:), XLSX_OUT, 'Sheet', sprintf('Top_%d', topN));

writeCorrMatrixToXlsx(XLSX_OUT, 'Redundancy_Rho', rho, dispFull);

Tset = table(string(CULTIVAR_CORE), string(EXTRACTION_CORE), string(scriptName), ...
    'VariableNames', {'Cultivar','Extraction','GeneratedByScript'});
writetable(Tset, XLSX_OUT, 'Sheet', 'Settings');

fprintf('\nDone. Generated by: %s\n', scriptName);
fprintf('Outputs in: %s\n', OUTDIR);

%% =========================
% LOCAL FUNCTIONS
% =========================
function P = calcPercentile(zMed)
    P = nan(size(zMed)); 
    for j = 1:size(zMed,2)
        v = zMed(:,j);
        ok = ~isnan(v);
        if sum(ok) >= 3
            r = tiedrank_local(v(ok));
            P(ok,j) = (r - 0.5) ./ sum(ok);
        end
    end
end

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

function z = robustZ(x)
    x = x(:); ok = ~isnan(x); z = nan(size(x));
    if sum(ok) < 5, return; end
    med = median(x(ok));
    mad1 = mad(x(ok), 1);
    if mad1 <= 0 || isnan(mad1), sc = iqr(x(ok))/1.349; else, sc = 1.4826*mad1; end
    if sc <= 0 || isnan(sc); sc = 1; end
    z(ok) = (x(ok) - med) ./ sc;
end

function s = translatePart(x)
    x = strtrim(lower(string(x))); s = strings(size(x));
    for i=1:numel(x)
        if contains(x(i),"inflorescen"), s(i)="Inflorescence";
        elseif contains(x(i),"hoja") || contains(x(i),"leaf"), s(i)="Leaf";
        elseif contains(x(i),"tallo") || contains(x(i),"stem"), s(i)="Stem";
        else, s(i)=titleCase(string(x(i))); end
    end
end

function s = translateMaturity(x)
    x = strtrim(lower(string(x))); s = strings(size(x));
    for i=1:numel(x)
        if contains(x(i),"bot") || contains(x(i),"bud"), s(i)="Bud";
        elseif contains(x(i),"comer"), s(i)="Commercial";
        elseif contains(x(i),"sobre") || contains(x(i),"over"), s(i)="Over-mature";
        else, s(i)=titleCase(string(x(i))); end
    end
end

function out = titleCase(str)
    words = split(str, " ");
    for k=1:numel(words)
        w = words(k);
        if strlength(w) >= 1, words(k) = upper(extractBetween(w,1,1)) + lower(extractAfter(w,1)); end
    end
    out = strjoin(words, " ");
end

function dispNames = prettyCritNames(varNames)
    varNames = string(varNames);
    dispNames = strings(size(varNames));
    for i=1:numel(varNames)
        v = varNames(i);
        vDisp = replace(v, ["SUM_","SUM ","_"], ["",""," "]);
        
        % Handle specific names
        vDisp = replace(vDisp, "GSL indolic", "Indolic glucosinolates");
        vDisp = replace(vDisp, "GSL total",   "Total glucosinolates");
        vDisp = replace(vDisp, "Km 3 diglucoside 7 diglucoside", "Kaempferol 3-diglucoside-7-diglucoside");
        vDisp = replace(vDisp, "K 3 O sinapoyldiglucoside", "Kaempferol 3-O-sinapoyl-diglucoside");
        vDisp = replace(vDisp, "L Phenylalanine", "L-Phenylalanine");
        
        if v == "Antihypertensive_act.", vDisp = "Antihypertensive activity";
        elseif v == "Total_phenolics", vDisp = "Total phenolics";
        end
        dispNames(i) = vDisp;
    end
end

function saveBoth(figH, outdir, baseName)
    savefig(figH, fullfile(outdir, baseName + ".fig"));
    exportgraphics(figH, fullfile(outdir, baseName + ".png"), 'Resolution', 300);
end

function writeCorrMatrixToXlsx(xlsxPath, sheetName, M, labels)
    labels = cellstr(labels(:));
    C = cell(numel(labels)+1, numel(labels)+1);
    C(1,1) = {''}; C(1,2:end) = labels'; C(2:end,1) = labels;
    C(2:end,2:end) = numCell(M);
    writecell(C, xlsxPath, 'Sheet', sheetName);
end

function C = numCell(M)
    C = cell(size(M));
    for i=1:numel(M), C{i}=M(i); end
end

function r = tiedrank_local(x)
    x = x(:); [xs, idx] = sort(x); r = nan(size(x)); n = numel(x); i = 1;
    while i <= n
        j = i; while j < n && xs(j+1) == xs(i), j = j + 1; end
        r(i:j) = (i + j) / 2; i = j + 1;
    end
    r_unsorted = nan(size(r)); r_unsorted(idx) = r; r = r_unsorted;
end