% ------------------------------------------------------------
% Objective 5 (within-domain prioritisation; decision support)
% Figures (PNG + FIG) + Excel compilation.
%
% Updates:
%   1. Automatic script name detection (requires saving file first).
%   2. Removed "(Tier 3)" text from Indolic marker index label.
%   3. Output folder: "Objetivo_5".
%   4. EXCLUDED "Extraction_yield" completely.
%   5. Logic: Composite score based on percentile ranks (0-1).
%
% Core domain: Pathernon × Ultrasonido (UAE).
% ------------------------------------------------------------
clear; clc; close all;

%% =========================
% 1. AUTOMATIC SCRIPT NAME DETECTION
% =========================
% NOTA: MATLAB te pedirá guardar el archivo antes de ejecutarlo.
% Una vez guardado, esta función coge el nombre automáticamente.
scriptName = mfilename; 
if isempty(scriptName); scriptName = 'BRC10_Prioritisation_ManualRun'; end
fprintf('Running script: %s\n', scriptName);

%% =========================
% USER PARAMETERS
% =========================
INPUT_XLSX  = 'Matriz_Brocoli_SUM_1nm_ASCII.xlsx';
SHEET_NAME  = 'Matriz';

% Output folder
OUTDIR = fullfile(pwd, 'Objetivo_5');
if ~exist(OUTDIR,'dir'); mkdir(OUTDIR); end

CULTIVAR_CORE   = "Pathernon";
EXTRACTION_CORE = "Ultrasonido";

TOPN_PROFILE    = 15;    % number of top combinations shown in criterion heatmap
RHO_THRESHOLD   = 0.85;  % shown in redundancy-audit title

% Criteria used for redundancy audit (full set)
% NOTE: Extraction_yield removed.
CRIT_FULL = string([
    "Total_phenolics"
    "DPPH"
    "ABTS"
    "Antihypertensive_act."
    "SUM_GSL_indolic"
    "SUM_Amino_acids"
    "SUM_GSL_total"
    "Indolic_marker_index_T3"   % Sum of 3 indolic compounds
]);

% Non-redundant criteria used for prioritisation
% NOTE: Extraction_yield removed.
CRIT_NONRED = string([
    "Total_phenolics"
    "DPPH"
    "ABTS"
    "Antihypertensive_act."
    "SUM_GSL_indolic"
    "SUM_Amino_acids"
]);

% Equal weights
WEIGHTS = ones(numel(CRIT_NONRED),1);

%% =========================
% LOAD DATA
% =========================
fprintf('Loading: %s\n', INPUT_XLSX);
opts = detectImportOptions(INPUT_XLSX, 'Sheet', SHEET_NAME);
opts.VariableNamingRule = 'preserve';
T = readtable(INPUT_XLSX, opts);

%% =========================
% IDENTIFY FACTOR COLUMNS
% =========================
colVar = pickVarName(T, ["Variedad","Variety","Cultivar"]);
colExt = pickVarName(T, ["Extraccion","Extracción","Extraction"]);
colPart= pickVarName(T, ["Parte","Part"]);
colMat = pickVarName(T, ["Maduracion","Maduración","Maturity"]);
colN2  = pickVarName(T, ["Aplicacion_N2","Aplicación_N2","Aplicación N2","N2","Nitrogen"]);

assert(colVar~="" && colExt~="" && colPart~="" && colMat~="" && colN2~="", ...
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
% CREATE Tier-3 indolic marker index (T3)
% =========================
needT3 = ~ismember("Indolic_marker_index_T3", string(Tcore.Properties.VariableNames));
if needT3
    req = ["Glucobrassicin","Methoxyglucobrassicin_1","Methoxyglucobrassicin_2"];
    ok = all(ismember(req, string(Tcore.Properties.VariableNames)));
    if any(contains(CRIT_FULL, "Indolic_marker_index_T3"))
        assert(ok, 'Tier-3 indolic compounds not found to build Indolic_marker_index_T3.');
        Tcore.("Indolic_marker_index_T3") = ...
            double(Tcore.("Glucobrassicin")) + double(Tcore.("Methoxyglucobrassicin_1")) + double(Tcore.("Methoxyglucobrassicin_2"));
    end
end

%% =========================
% KEEP ONLY AVAILABLE CRITERIA
% =========================
have = string(Tcore.Properties.VariableNames);
CRIT_FULL   = CRIT_FULL(ismember(CRIT_FULL, have));
CRIT_NONRED = CRIT_NONRED(ismember(CRIT_NONRED, have));

assert(numel(CRIT_NONRED) >= 2, 'Too few criteria available.');
WEIGHTS = WEIGHTS(1:numel(CRIT_NONRED));
WEIGHTS = WEIGHTS(:);

%% =========================
% TRANSLATE FACTORS
% =========================
PartE = translatePart(string(Tcore.(colPart)));
MatE  = translateMaturity(string(Tcore.(colMat)));
N2E   = translateYesNo(string(Tcore.(colN2)));
combo = strcat(PartE, " | ", MatE, " | ", N2E);

%% =========================
% ROBUST Z SCORES
% =========================
Zfull = nan(height(Tcore), numel(CRIT_FULL));
for j = 1:numel(CRIT_FULL)
    y = double(Tcore.(CRIT_FULL(j)));
    Zfull(:,j) = robustZ(y);
end

Znr = nan(height(Tcore), numel(CRIT_NONRED));
for j = 1:numel(CRIT_NONRED)
    y = double(Tcore.(CRIT_NONRED(j)));
    Znr(:,j) = robustZ(y);
end

%% =========================
% GROUP BY COMBINATION
% =========================
G = findgroups(combo);
comboList = splitapply(@(x) x(1), combo, G);
nPerGroup = splitapply(@numel, combo, G);

partG = splitapply(@(x) x(1), PartE, G);
matG  = splitapply(@(x) x(1), MatE,  G);
n2G   = splitapply(@(x) x(1), N2E,   G);
pmLabel = strcat(partG, " | ", matG); 

% Raw robust medians
rawMed = nan(max(G), numel(CRIT_NONRED));
for j = 1:numel(CRIT_NONRED)
    y = double(Tcore.(CRIT_NONRED(j)));
    rawMed(:,j) = splitapply(@(x) median(x,'omitnan'), y, G);
end

% Z robust medians
zMed = nan(max(G), numel(CRIT_NONRED));
for j = 1:numel(CRIT_NONRED)
    zMed(:,j) = splitapply(@(x) median(x,'omitnan'), Znr(:,j), G);
end

%% =========================
% COMPOSITE SCORES (Percentile-based)
% =========================
W = WEIGHTS(:);
W = W ./ max(sum(W), eps);

% A) Score_Z (audit)
maskZ = ~isnan(zMed);
scoreZ = sum(zMed .* (W'.*maskZ), 2) ./ max(sum(W'.*maskZ,2), eps);

% B) Percentiles
P = nan(size(zMed)); 
for j = 1:size(zMed,2)
    v = zMed(:,j);
    ok = ~isnan(v);
    if sum(ok) >= 3
        r = tiedrank_local(v(ok));
        P(ok,j) = (r - 0.5) ./ sum(ok);
    end
end
maskP = ~isnan(P);
scoreP = sum(P .* (W'.*maskP), 2) ./ max(sum(W'.*maskP,2), eps);

[scoreSorted, ord] = sort(scoreP, 'descend');
comboSorted = comboList(ord);
scoreZ_sorted = scoreZ(ord);

%% =========================
% DISPLAY NAMES (Tier 3 Removed)
% =========================
dispFull = prettyCritNames(CRIT_FULL);
dispNR   = prettyCritNames(CRIT_NONRED);

%% =========================
% FIGURE 1: Criterion Profile
% =========================
partOrder = ["Leaf","Inflorescence","Stem"];
matOrder  = ["Bud","Commercial","Over-mature"];
p = strtrim(string(partG));
m = strtrim(string(matG));
n = strtrim(string(n2G));
[tfP, partOrdAll] = ismember(lower(p), lower(partOrder));
[tfM, matOrdAll]  = ismember(lower(m), lower(matOrder));
partOrdAll(~tfP) = numel(partOrder) + 1;
matOrdAll(~tfM)  = numel(matOrder)  + 1;

idxNo  = find(strcmpi(n, "No"));
idxYes = find(strcmpi(n, "Yes"));
[~, sNo]  = sortrows([partOrdAll(idxNo),  matOrdAll(idxNo)]);
[~, sYes] = sortrows([partOrdAll(idxYes), matOrdAll(idxYes)]);
idxNoPlot  = idxNo(sNo);
idxYesPlot = idxYes(sYes);

Mno  = P(idxNoPlot, :);
Myes = P(idxYesPlot, :);
Yno  = pmLabel(idxNoPlot);
Yyes = pmLabel(idxYesPlot);

fig1 = figure('Color','w','Position',[80 80 1250 720]);
t = tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

nexttile;
imagesc(Mno); axis tight; caxis([0 1]);
set(gca,'YTick',1:numel(Yno),'YTickLabel',Yno, ...
        'XTick',1:numel(dispNR),'XTickLabel',dispNR, ...
        'FontName','Times New Roman','FontSize',10);
xtickangle(35);
ylabel('Part × maturity (ordered)', 'FontName','Times New Roman','FontSize',12);
xlabel('Criteria', 'FontName','Times New Roman','FontSize',12);
title('N₂ = No', 'FontName','Times New Roman','FontSize',12);

nexttile;
imagesc(Myes); axis tight; caxis([0 1]);
set(gca,'YTick',1:numel(Yyes),'YTickLabel',Yyes, ...
        'XTick',1:numel(dispNR),'XTickLabel',dispNR, ...
        'FontName','Times New Roman','FontSize',10);
xtickangle(35);
ylabel('Part × maturity (ordered)', 'FontName','Times New Roman','FontSize',12);
xlabel('Criteria', 'FontName','Times New Roman','FontSize',12);
title('N₂ = Yes', 'FontName','Times New Roman','FontSize',12);

cb = colorbar; cb.Layout.Tile = 'east';
ylabel(cb, 'Percentile rank (0–1)', 'FontName','Times New Roman','FontSize',10);
title(t, 'Objective 5: Criterion-level profiles', 'FontName','Times New Roman','FontSize',12);

saveBoth(fig1, OUTDIR, 'Fig_obj5_CriterionProfile_ByN2_PCTL_Ordered');

%% =========================
% FIGURE 2: Ranking
% =========================
fig2 = figure('Color','w','Position',[120 120 1100 800]);
barh(scoreSorted);
set(gca,'YDir','reverse', ...
        'YTick',1:numel(scoreSorted), 'YTickLabel',comboSorted, ...
        'FontName','Times New Roman','FontSize',10);
xlabel('Composite prioritisation score (0–1)', 'FontName','Times New Roman','FontSize',12);
title('Objective 5: Within-domain prioritisation', 'FontName','Times New Roman','FontSize',12);
grid on;
saveBoth(fig2, OUTDIR, 'Fig_obj5_Ranking_CompositePCTL');

%% =========================
% FIGURE 3: Redundancy Audit
% =========================
rho = corr(Zfull, 'Type','Spearman', 'Rows','pairwise');
fig3 = figure('Color','w','Position',[160 160 860 760]);
imagesc(rho); axis square; caxis([-1 1]);
cb = colorbar; ylabel(cb, 'Spearman \rho', 'FontName','Times New Roman','FontSize',10);
set(gca,'XTick',1:numel(dispFull),'XTickLabel',dispFull, ...
        'YTick',1:numel(dispFull),'YTickLabel',dispFull, ...
        'FontName','Times New Roman','FontSize',10);
xtickangle(40);
title(sprintf('Redundancy audit; |\\rho| threshold = %.2f', RHO_THRESHOLD), ...
      'FontName','Times New Roman','FontSize',12);
saveBoth(fig3, OUTDIR, 'Fig_S_obj5_RedundancyAudit');

%% =========================
% EXPORT EXCEL
% =========================
XLSX_OUT = fullfile(OUTDIR, "obj5_Prioritisation_Summary.xlsx");

rawSorted = rawMed(ord, :);
zSorted   = zMed(ord, :);
pSorted   = P(ord, :);
nSorted   = nPerGroup(ord);

Tsum = table(comboSorted, nSorted, scoreSorted, scoreZ_sorted, ...
    'VariableNames', {'Combination','n','CompositeScore_PCTL','CompositeScore_robustZ'});

for j = 1:numel(CRIT_NONRED)
    v = "Raw_" + matlab.lang.makeValidName(char(CRIT_NONRED(j)));
    Tsum.(v) = rawSorted(:,j);
    v = "Zmed_" + matlab.lang.makeValidName(char(CRIT_NONRED(j)));
    Tsum.(v) = zSorted(:,j);
    v = "Pctl_" + matlab.lang.makeValidName(char(CRIT_NONRED(j)));
    Tsum.(v) = pSorted(:,j);
end

writetable(Tsum, XLSX_OUT, 'Sheet', 'Ranking_All');
% FIX: Ensure topN does not exceed table rows
topN = min(TOPN_PROFILE, height(Tsum));
writetable(Tsum(1:topN,:), XLSX_OUT, 'Sheet', sprintf('Top_%d', topN));
writeCorrMatrixToXlsx(XLSX_OUT, 'Redundancy_Rho', rho, dispFull);

% Settings sheet
Tset = table(string(CULTIVAR_CORE), string(EXTRACTION_CORE), string(scriptName), ...
    'VariableNames', {'Cultivar','Extraction','GeneratedByScript'});
writetable(Tset, XLSX_OUT, 'Sheet', 'Settings');

fprintf('\nDone. Generated by: %s\n', scriptName);
fprintf('Outputs in: %s\n', OUTDIR);

%% =========================
% LOCAL FUNCTIONS
% =========================
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

function s = translateYesNo(x)
    x = strtrim(lower(string(x))); s = strings(size(x));
    for i=1:numel(x)
        if x(i)=="si" || x(i)=="sí" || x(i)=="yes" || x(i)=="1", s(i)="Yes";
        elseif x(i)=="no" || x(i)=="0", s(i)="No";
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
        vDisp = replace(vDisp, "GSL indolic", "Indolic glucosinolates");
        vDisp = replace(vDisp, "GSL total",   "Total glucosinolates");
        vDisp = replace(vDisp, "Amino acids", "Amino acids");
        if v == "Antihypertensive_act.", vDisp = "Antihypertensive activity";
        elseif v == "Extraction_yield", vDisp = "Extraction yield";
        elseif v == "Total_phenolics", vDisp = "Total phenolics";
        % --- MODIFICACIÓN: Eliminada la etiqueta "(Tier 3)" ---
        elseif v == "Indolic_marker_index_T3", vDisp = "Indolic marker index"; 
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
    C(2:end,2:end) = num2cell(M);
    writecell(C, xlsxPath, 'Sheet', sheetName);
end

function r = tiedrank_local(x)
    x = x(:); [xs, idx] = sort(x); r = nan(size(x)); n = numel(x); i = 1;
    while i <= n
        j = i; while j < n && xs(j+1) == xs(i), j = j + 1; end
        r(i:j) = (i + j) / 2; i = j + 1;
    end
    r_unsorted = nan(size(r)); r_unsorted(idx) = r; r = r_unsorted;
end