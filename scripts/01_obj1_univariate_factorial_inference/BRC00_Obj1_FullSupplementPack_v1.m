function BRC00_Obj1_FullSupplementPack_v1(opts)
% BRC00_Obj1_FullSupplementPack_v1
% ------------------------------------------------------------
% OBJ1 – Full package for Section 3.1 (Tier 1 + Tier 2 + Tier 3)
% Single-root, audit-ready outputs under:
%   <PWD>/Objetivo_1/
%
% Generates:
%   (1) Tier 1–2 drivers: Fig. 1 (eta2p heatmap) + tables (eta2p + q_BH)
%   (2) Tier 3 supplementary pack: full ANOVA outputs + top-K per term
%       + Fig. S2 (top-30 heatmap)
%
% IMPORTANT:
% - MATLAB function names cannot contain '-' (hyphen).
% - Output files do use "Obj1-".
% - Figures are exported as .fig + .png (PDF optional).
% ------------------------------------------------------------

if nargin < 1, opts = struct(); end

% -------------------- DEFAULTS --------------------
opts = setDefault(opts, "xlsxPath", "Matriz_Brocoli_Sin_N.xlsx");
opts = setDefault(opts, "dataSheet", "Matriz");

opts = setDefault(opts, "tier1Sheet", "Tier 1");
opts = setDefault(opts, "tier2Sheet", "Tier 2");
opts = setDefault(opts, "tier3Sheet", "Tier 3"); % expected columns: Var1=varname, Var2=label

opts = setDefault(opts, "outRoot", fullfile(pwd, "Objetivo_1"));

% Screening settings
opts = setDefault(opts, "minNNonMissing", 20);
opts = setDefault(opts, "maxMissingFrac", 0.30);
opts = setDefault(opts, "minVariance", 0); % retain if variance > minVariance

% FDR policy
% Tier1+Tier2: BH within each tier across all term-tests (endpoint × term)
% Tier3: BH across all term-tests in Tier3
opts = setDefault(opts, "exportPDF", false);
opts = setDefault(opts, "pngDPI", 300);

% Tier 3 compact outputs
opts = setDefault(opts, "tier3TopKPerTerm", 10);
opts = setDefault(opts, "tier3TopNHeatmap", 30);

% -------------------- RUN PACKS --------------------
run_Obj1_Tier12_Drivers(opts);
run_Obj1_Tier3_SupplementaryPack(opts);

fprintf("\nOBJ1 FULL PACK DONE.\nRoot folder: %s\n", opts.outRoot);

end

% =====================================================================
% (A) OBJ1 – Tier 1 + Tier 2 drivers (Figure 1 + Tables S1/S2 backbone)
% =====================================================================
function run_Obj1_Tier12_Drivers(opts)

% Output folders
outDir = fullfile(opts.outRoot, "results", "Obj1-FactorialDrivers_Tier1_Tier2");
figDir = fullfile(outDir, "figures");
logDir = fullfile(outDir, "logs");
if ~exist(outDir,"dir"), mkdir(outDir); end
if ~exist(figDir,"dir"), mkdir(figDir); end
if ~exist(logDir,"dir"), mkdir(logDir); end

outXlsx = fullfile(outDir, "Obj1-FactorialDrivers_Tier1_Tier2.xlsx");
outFig  = fullfile(figDir, "Obj1-Fig1_eta2p_heatmap_Tier1_Tier2.fig");
outPng  = fullfile(figDir, "Obj1-Fig1_eta2p_heatmap_Tier1_Tier2.png");
outPdf  = fullfile(figDir, "Obj1-Fig1_eta2p_heatmap_Tier1_Tier2.pdf");

% Factor columns
candPart = ["Parte","Part"];
candMat  = ["Maduracion","Maduración","Maturity"];

% Type III model (2 factors: main effects + interaction)
modelTerms = [ ...
    1 0;  % Part
    0 1;  % Maturity
    1 1]; % Part*Maturity

termNames = ["Part","Maturity","Part×Maturity"];
nTerms = numel(termNames);

% -------------------- LOAD DATA --------------------
T = readtable(opts.xlsxPath, "Sheet", opts.dataSheet, "VariableNamingRule","modify");
vnames = string(T.Properties.VariableNames);
N = height(T);

colPart = pickFirstExisting(vnames, candPart);
colMat  = pickFirstExisting(vnames, candMat);

assert(colPart~="", "Part factor column not found.");
assert(colMat~="",  "Maturity factor column not found.");

Part = categorical(string(T.(colPart)));
Mat  = categorical(string(T.(colMat)));

% -------------------- LOAD TIER 1 LIST --------------------
T1 = readtable(opts.xlsxPath, "Sheet", opts.tier1Sheet, "ReadVariableNames", false, "VariableNamingRule","preserve");
tier1_vars_raw   = string(T1.Var1);
tier1_labels_raw = string(T1.Var2);
ok = strlength(tier1_vars_raw)>0;
tier1_vars_raw   = tier1_vars_raw(ok);
tier1_labels_raw = tier1_labels_raw(ok);

tier1_vars   = string(matlab.lang.makeValidName(tier1_vars_raw));
tier1_labels = tier1_labels_raw;

% Explicitly exclude Extraction_yield
rm = (tier1_vars == "Extraction_yield");
tier1_vars(rm)   = [];
tier1_labels(rm) = [];

missing1 = tier1_vars(~ismember(tier1_vars, vnames));
if ~isempty(missing1)
    error("Tier 1 variables missing in data sheet: %s", strjoin(missing1, ", "));
end

% -------------------- LOAD TIER 2 LIST --------------------
T2 = readtable(opts.xlsxPath, "Sheet", opts.tier2Sheet, "ReadVariableNames", false, "VariableNamingRule","preserve");
tier2_vars_raw   = string(T2.Var2); % SUM_* variable names
tier2_labels_raw = string(T2.Var4); % English label
ok = strlength(tier2_vars_raw)>0;
tier2_vars_raw   = tier2_vars_raw(ok);
tier2_labels_raw = tier2_labels_raw(ok);

tier2_vars   = string(matlab.lang.makeValidName(tier2_vars_raw));
tier2_labels = tier2_labels_raw;

missing2 = tier2_vars(~ismember(tier2_vars, vnames));
if ~isempty(missing2)
    error("Tier 2 variables missing in data sheet: %s", strjoin(missing2, ", "));
end

% -------------------- USABILITY SCREEN --------------------
C = [ ...
    table(repmat("Tier1",numel(tier1_vars),1), tier1_vars(:), tier1_labels(:), ...
    'VariableNames',{'Tier','Var','Label'}); ...
    table(repmat("Tier2",numel(tier2_vars),1), tier2_vars(:), tier2_labels(:), ...
    'VariableNames',{'Tier','Var','Label'}) ...
];

[C, R] = usabilityScreen_table(T, C, opts);

writetable(C(C.Tier=="Tier1",:), outXlsx, "Sheet", "Tier1_candidates");
writetable(C(C.Tier=="Tier2",:), outXlsx, "Sheet", "Tier2_candidates");

% Paper-friendly order for Tier 1 + Tier 2
R = applyPaperFriendlyOrder_T12(R);
writetable(R, outXlsx, "Sheet", "Retained_endpoints");

fprintf("[Obj1 Tier1-2] Retained endpoints: %d (Tier1=%d; Tier2=%d)\n", ...
    height(R), sum(R.Tier=="Tier1"), sum(R.Tier=="Tier2"));

% -------------------- TYPE III ANOVA PER ENDPOINT --------------------
Tidy = table();
etaMat = nan(height(R), nTerms);
pMat   = nan(height(R), nTerms);

for i = 1:height(R)
    y0 = double(T.(R.Var(i)));
    oky = isfinite(y0);

    y = y0(oky);
    P1 = Part(oky);
    M1 = Mat(oky);

    if numel(y) < opts.minNNonMissing, continue; end

    [p, tbl] = anovan(y, {P1, M1}, ...
        "model", modelTerms, ...
        "sstype", 3, ...
        "varnames", {'Part','Maturity'}, ...
        "display","off");

    SS = cell2mat(tbl(2:end-1, 2)); % terms + Error
    DF = cell2mat(tbl(2:end-1, 3));
    MS = cell2mat(tbl(2:end-1, 4));
    F  = cell2mat(tbl(2:end-1, 5));
    p_terms = p(:);

    SS_error = SS(end);
    DF_error = DF(end);
    MS_error = MS(end);

    for t = 1:nTerms
        SS_term = SS(t);
        DF_term = DF(t);
        MS_term = MS(t);
        F_term  = F(t);
        p_term  = p_terms(t);

        eta2p = SS_term / (SS_term + SS_error);

        Tidy = [Tidy; table( ...
            R.Tier(i), R.Var(i), R.Label(i), numel(y), ...
            termNames(t), SS_term, DF_term, MS_term, F_term, p_term, ...
            SS_error, DF_error, MS_error, eta2p, ...
            'VariableNames',{'Tier','Var','Label','N_used','Term','SS','DF','MS','F','p','SS_error','DF_error','MS_error','eta2p'})]; %#ok<AGROW>

        etaMat(i,t) = eta2p;
        pMat(i,t)   = p_term;
    end
end

writetable(Tidy, outXlsx, "Sheet", "ANOVA_Tidy");

% -------------------- BH–FDR (WITHIN TIER, ACROSS ALL TERM TESTS) --------------------
qMat = nan(size(pMat));

for tierName = ["Tier1","Tier2"]
    idx = (R.Tier == tierName);
    p_vec = pMat(idx,:);
    p_vec = p_vec(:);
    q_vec = bh_fdr_validtests(p_vec);   % valid tests only
    qMat(idx,:) = reshape(q_vec, sum(idx), nTerms);
end

% -------------------- EXPORT WIDE MATRICES (TABLE S1/S2 BACKBONE) --------------------
rowNamesWide = strcat(string(R.Tier), " | ", string(R.Label));

EtaWide = array2table(etaMat, 'VariableNames', cellstr(termNames));
EtaWide.Endpoint = rowNamesWide;
EtaWide = movevars(EtaWide, "Endpoint", "Before", 1);

QWide = array2table(qMat, 'VariableNames', cellstr(termNames));
QWide.Endpoint = rowNamesWide;
QWide = movevars(QWide, "Endpoint", "Before", 1);

writetable(EtaWide, outXlsx, "Sheet", "ANOVA_Wide_eta2p");
writetable(QWide,  outXlsx, "Sheet", "ANOVA_Wide_q");

% -------------------- FIGURE 1 (HEATMAP) --------------------
plotLabels = cleanPlotLabels_T12(R);

fig = figure('Color','w','Position',[100 100 980 720]); %#ok<NASGU>
imagesc(etaMat);
axis tight;
caxis([0 1]);

ax = gca;
set(ax, 'YTick', 1:height(R), 'YTickLabel', cellstr(plotLabels), ...
        'XTick', 1:nTerms, 'XTickLabel', cellstr(termNames), ...
        'TickLabelInterpreter','none', ...
        'TickLength', [0 0]);

xtickangle(30);
colorbar;
title('Obj1 – Type III ANOVA partial eta-squared (ηp²)');

% Visual separators
hold on;
sep = [4, 7, 11, 17];
for s = sep
    if s < height(R)
        yline(s+0.5, 'k-', 'LineWidth', 0.75);
    end
end
hold off;

savefig(outFig);
exportgraphics(gcf, outPng, 'Resolution', opts.pngDPI);
if opts.exportPDF
    exportgraphics(gcf, outPdf);
end
close(gcf);

writeTextLog(fullfile(logDir, "Obj1-Tier12_run_config.txt"), opts);

fprintf("[Obj1 Tier1-2] DONE. Excel: %s | Fig: %s\n", outXlsx, outPng);

end

% =====================================================================
% (B) OBJ1 – Tier 3 supplementary pack
% =====================================================================
function run_Obj1_Tier3_SupplementaryPack(opts)

% Output folders
outDir = fullfile(opts.outRoot, "results", "Obj1-Tier3_SupplementaryPack");
figDir = fullfile(outDir, "figures");
logDir = fullfile(outDir, "logs");
if ~exist(outDir,"dir"), mkdir(outDir); end
if ~exist(figDir,"dir"), mkdir(figDir); end
if ~exist(logDir,"dir"), mkdir(logDir); end

outXlsx = fullfile(outDir, "Obj1-Tier3_SupplementaryPack.xlsx");

outFig  = fullfile(figDir, "Obj1-FigS2_Tier3_eta2p_heatmap_top30.fig");
outPng  = fullfile(figDir, "Obj1-FigS2_Tier3_eta2p_heatmap_top30.png");
outPdf  = fullfile(figDir, "Obj1-FigS2_Tier3_eta2p_heatmap_top30.pdf");

% Factor columns
candPart = ["Parte","Part"];
candMat  = ["Maduracion","Maduración","Maturity"];

% Type III model (2 factors: main effects + interaction)
modelTerms = [ ...
    1 0;  % Part
    0 1;  % Maturity
    1 1]; % Part*Maturity

termNames = ["Part","Maturity","Part×Maturity"];
nTerms = numel(termNames);

TOPK_PER_TERM = opts.tier3TopKPerTerm;  
TOPN_HEATMAP  = opts.tier3TopNHeatmap;  

% -------------------- LOAD DATA --------------------
T = readtable(opts.xlsxPath, "Sheet", opts.dataSheet, "VariableNamingRule","modify");
vnames = string(T.Properties.VariableNames);
N = height(T);

colPart = pickFirstExisting(vnames, candPart);
colMat  = pickFirstExisting(vnames, candMat);

assert(colPart~="", "Part factor column not found.");
assert(colMat~="",  "Maturity factor column not found.");

Part = categorical(string(T.(colPart)));
Mat  = categorical(string(T.(colMat)));

% -------------------- LOAD TIER 3 LIST --------------------
% Expected columns: Var1=varname, Var2=label
T3 = readtable(opts.xlsxPath, "Sheet", opts.tier3Sheet, "ReadVariableNames", false, "VariableNamingRule","preserve");
tier3_vars_raw   = string(T3.Var1);
tier3_labels_raw = string(T3.Var2);

ok = strlength(tier3_vars_raw)>0;
tier3_vars_raw   = tier3_vars_raw(ok);
tier3_labels_raw = tier3_labels_raw(ok);

tier3_vars   = string(matlab.lang.makeValidName(tier3_vars_raw));
tier3_labels = tier3_labels_raw;

missing3 = tier3_vars(~ismember(tier3_vars, vnames));
if ~isempty(missing3)
    error("Tier 3 variables missing in data sheet: %s", strjoin(missing3, ", "));
end

% Family inference used as a labeling aid
family_auto = inferFamily(tier3_labels, tier3_vars);

Dict = table(tier3_vars(:), tier3_labels(:), family_auto(:), ...
    'VariableNames',{'Metabolite_var','Metabolite_label','Family_auto'});
writetable(Dict, outXlsx, "Sheet", "Metabolite_dictionary");

% -------------------- USABILITY SCREEN --------------------
C = table(repmat("Metabolite-level", numel(tier3_vars), 1), tier3_vars(:), tier3_labels(:), family_auto(:), ...
    'VariableNames',{'Block','Var','Label','Family_auto'});

[C, R] = usabilityScreen_table(T, C, opts);

writetable(C, outXlsx, "Sheet", "Usability_screen");
writetable(R, outXlsx, "Sheet", "Retained_metabolites");

fprintf("[Obj1 Tier3] Retained metabolites: %d / %d\n", height(R), height(C));

% -------------------- TYPE III ANOVA PER METABOLITE --------------------
Tidy = table();
etaMat = nan(height(R), nTerms);
pMat   = nan(height(R), nTerms);

for i = 1:height(R)
    y0 = double(T.(R.Var(i)));
    oky = isfinite(y0);

    y = y0(oky);
    P1 = Part(oky);
    M1 = Mat(oky);

    if numel(y) < opts.minNNonMissing, continue; end

    [p, tbl] = anovan(y, {P1, M1}, ...
        "model", modelTerms, ...
        "sstype", 3, ...
        "varnames", {'Part','Maturity'}, ...
        "display","off");

    SS = cell2mat(tbl(2:end-1, 2)); % terms + Error
    DF = cell2mat(tbl(2:end-1, 3));
    MS = cell2mat(tbl(2:end-1, 4));
    F  = cell2mat(tbl(2:end-1, 5));
    p_terms = p(:);

    SS_error = SS(end);
    DF_error = DF(end);
    MS_error = MS(end);

    for t = 1:nTerms
        SS_term = SS(t);
        DF_term = DF(t);
        MS_term = MS(t);
        F_term  = F(t);
        p_term  = p_terms(t);

        eta2p = SS_term / (SS_term + SS_error);

        Tidy = [Tidy; table( ...
            R.Var(i), R.Label(i), R.Family_auto(i), numel(y), ...
            termNames(t), SS_term, DF_term, MS_term, F_term, p_term, ...
            SS_error, DF_error, MS_error, eta2p, ...
            'VariableNames',{'Metabolite_var','Metabolite_label','Family_auto','N_used','Term','SS','DF','MS','F','p','SS_error','DF_error','MS_error','eta2p'})]; %#ok<AGROW>

        etaMat(i,t) = eta2p;
        pMat(i,t)   = p_term;
    end
end

writetable(Tidy, outXlsx, "Sheet", "ANOVA_Tidy");

% -------------------- BH–FDR ACROSS ALL TERM TESTS IN TIER 3 --------------------
p_vec = pMat(:);
q_vec = bh_fdr_validtests(p_vec);        % valid tests only
qMat  = reshape(q_vec, size(pMat));

% -------------------- WIDE MATRICES --------------------
rowNames = strcat(string(R.Family_auto), " | ", string(R.Label));

EtaWide = array2table(etaMat, 'VariableNames', cellstr(termNames));
EtaWide.Endpoint = rowNames;
EtaWide.Metabolite_var = R.Var;
EtaWide = movevars(EtaWide, ["Endpoint","Metabolite_var"], "Before", 1);

QWide = array2table(qMat, 'VariableNames', cellstr(termNames));
QWide.Endpoint = rowNames;
QWide.Metabolite_var = R.Var;
QWide = movevars(QWide, ["Endpoint","Metabolite_var"], "Before", 1);

writetable(EtaWide, outXlsx, "Sheet", "ANOVA_Wide_eta2p");
writetable(QWide,  outXlsx, "Sheet", "ANOVA_Wide_q");

% -------------------- COMPACT TABLE: TOP-K PER TERM --------------------
TopByTerm = table();
for t = 1:nTerms
    eta = etaMat(:,t);
    q   = qMat(:,t);

    [~, idx] = sort(eta, "descend");
    idx = idx(isfinite(eta(idx)));

    k = min(TOPK_PER_TERM, numel(idx));
    sel = idx(1:k);

    tmp = table( ...
        repmat(termNames(t), k, 1), (1:k)', ...
        R.Family_auto(sel), R.Var(sel), R.Label(sel), ...
        eta(sel), q(sel), ...
        'VariableNames', {'Term','Rank','Family_auto','Metabolite_var','Metabolite_label','eta2p','q'});

    TopByTerm = [TopByTerm; tmp]; %#ok<AGROW>
end

TopByTerm = sortrows(TopByTerm, {'Term','eta2p'}, {'ascend','descend'});
writetable(TopByTerm, outXlsx, "Sheet", "S3_Top10_byTerm");

% -------------------- FIG S2: HEATMAP TOP-N BY max(eta2p) --------------------
maxEta = max(etaMat, [], 2, "omitnan");
[~, idxMax] = sort(maxEta, "descend");
idxMax = idxMax(isfinite(maxEta(idxMax)));

nH = min(TOPN_HEATMAP, numel(idxMax));
selH = idxMax(1:nH);

% Order by family, then by maxEta for readability
tmpOrder = table(string(R.Family_auto(selH)), maxEta(selH), 'VariableNames', {'Family','MaxEta'});
[~, ord] = sortrows(tmpOrder, {'Family','MaxEta'}, {'ascend','descend'});
selH = selH(ord);

% Abbreviations
labelsH_raw = string(R.Label(selH));
labelsH = strings(size(labelsH_raw));
for i = 1:numel(labelsH_raw)
    labelsH(i) = getAbbreviation(labelsH_raw(i));
end

fig = figure('Color','w','Position',[100 100 980 720]); %#ok<NASGU>
imagesc(etaMat(selH,:));
axis tight;
caxis([0 1]);

ax = gca;
set(ax, 'YTick', 1:numel(selH), 'YTickLabel', cellstr(labelsH), ...
        'XTick', 1:nTerms, 'XTickLabel', cellstr(termNames), ...
        'TickLabelInterpreter','none', ...
        'TickLength', [0 0]);

xtickangle(30);
colorbar;
title(sprintf('Obj1 – Type III ANOVA ηp² (Top %d metabolites)', nH));

% Family separators
fam = string(R.Family_auto(selH));
hold on;
for i = 2:numel(fam)
    if fam(i) ~= fam(i-1)
        yline(i-0.5, 'k-', 'LineWidth', 0.75);
    end
end
hold off;

savefig(outFig);
exportgraphics(gcf, outPng, 'Resolution', opts.pngDPI);
if opts.exportPDF
    exportgraphics(gcf, outPdf);
end
close(gcf);

writeTextLog(fullfile(logDir, "Obj1-Tier3_run_config.txt"), opts);

fprintf("[Obj1 Tier3] DONE. Excel: %s | FigS2: %s\n", outXlsx, outPng);

end

% =====================================================================
% COMMON HELPERS
% =====================================================================

function [C, R] = usabilityScreen_table(T, C, opts)
N = height(T);

n_nonmiss  = zeros(height(C),1);
missing_fr = zeros(height(C),1);
var_y      = zeros(height(C),1);
retain     = false(height(C),1);

for i = 1:height(C)
    y = double(T.(C.Var(i)));
    oky = isfinite(y);

    n_nonmiss(i)  = sum(oky);
    missing_fr(i) = 1 - n_nonmiss(i)/N;

    if n_nonmiss(i) > 1
        var_y(i) = var(y(oky), 0);
    else
        var_y(i) = 0;
    end

    retain(i) = (n_nonmiss(i) >= opts.minNNonMissing) && ...
                (missing_fr(i) <= opts.maxMissingFrac) && ...
                (var_y(i) > opts.minVariance);
end

C.n_nonmissing = n_nonmiss;
C.missing_frac = missing_fr;
C.variance     = var_y;
C.retain       = retain;

R = C(C.retain,:);
end

function R = applyPaperFriendlyOrder_T12(R)
desiredVars = string([ ...
    "Antihypertensive_act_", "ABTS", "DPPH", "Total_phenolics", ...
    "SUM_Amino_acids", "SUM_N_related", "SUM_OrgAcids", ...
    "SUM_GSL_total", "SUM_GSL_aliphatic", "SUM_GSL_indolic", "SUM_GSL_breakdown", ...
    "SUM_Phenylpropanoids_total", "SUM_Phenolics_MS", "SUM_Flavonols", "SUM_CQA", "SUM_Coumaroyl", "SUM_Sinapate_esters", ...
    "SUM_Lipids_total", "SUM_FA_saturated", "SUM_FA_unsaturated", "SUM_Oxylipins_oxygenated" ...
]);

ord = [];
for k = 1:numel(desiredVars)
    idx = find(string(R.Var) == desiredVars(k));
    if ~isempty(idx)
        ord(end+1) = idx(1); %#ok<AGROW>
    end
end
rest = setdiff(1:height(R), ord, 'stable');
ord = [ord, rest];

R = R(ord,:);
end

function plotLabels = cleanPlotLabels_T12(R)
plotLabels = string(R.Label);
plotLabels = regexprep(plotLabels, '^\s*Sum of\s+', '');
plotLabels = regexprep(plotLabels, '\s*\((MS-based\s+)?sum\)\s*$', '', 'ignorecase');
plotLabels = regexprep(plotLabels, '\s*\(CQA\)\s*$', '');
plotLabels(string(R.Var)=="SUM_Phenolics_MS") = "Total phenolics (MS-based)";
plotLabels = regexprep(plotLabels, '\s{2,}', ' ');
plotLabels = strtrim(plotLabels);
plotLabels = arrayfun(@capFirstChar, plotLabels);
end

function q = bh_fdr_validtests(p)
p = p(:);
q = nan(size(p));

ok = isfinite(p);
p0 = p(ok);
m  = numel(p0);
if m == 0, return; end

[ps, idx] = sort(p0, 'ascend');
ranks = (1:m)';

q_sorted = ps .* (m ./ ranks);
for i = m-1:-1:1
    q_sorted(i) = min(q_sorted(i), q_sorted(i+1));
end
q_sorted = min(q_sorted, 1);

q0 = nan(size(p0));
q0(idx) = q_sorted;
q(ok) = q0;
end

function name = pickFirstExisting(vnames, candidates)
name = "";
for c = 1:numel(candidates)
    if any(vnames == candidates(c))
        name = candidates(c);
        return;
    end
end
end

function opts = setDefault(opts, field, value)
if ~isfield(opts, field) || isempty(opts.(field))
    opts.(field) = value;
end
end

function s = capFirstChar(s)
s = string(s);
if strlength(s) == 0, return; end
c = char(s);
c(1) = upper(c(1));
s = string(c);
end

function writeTextLog(filePath, opts)
fid = fopen(filePath, "w");
if fid < 0, return; end
fprintf(fid, "OBJ1 RUN CONFIG (audit)\n");
fprintf(fid, "xlsxPath: %s\n", opts.xlsxPath);
fprintf(fid, "dataSheet: %s\n", opts.dataSheet);
fprintf(fid, "minNNonMissing: %d\n", opts.minNNonMissing);
fprintf(fid, "maxMissingFrac: %.3f\n", opts.maxMissingFrac);
fprintf(fid, "minVariance: %g\n", opts.minVariance);
fprintf(fid, "exportPDF: %d\n", opts.exportPDF);
fprintf(fid, "pngDPI: %d\n", opts.pngDPI);
fprintf(fid, "tier3TopKPerTerm: %d\n", opts.tier3TopKPerTerm);
fprintf(fid, "tier3TopNHeatmap: %d\n", opts.tier3TopNHeatmap);
fclose(fid);
end

function abbr = getAbbreviation(full_name)
n = lower(strtrim(string(full_name)));
abbr = string(full_name);

if contains(n, "9-hydroxy-10e, 12 z") || contains(n, "9-hotre")
    abbr = "9-HOTrE"; return;
end
if contains(n, "aminocyclopropane") || strcmpi(n, "acc")
    abbr = "ACC"; return;
end
end

function fam = inferFamily(labels, vars)
labels = lower(string(labels));
vars   = lower(string(vars)); %#ok<NASGU>

fam = strings(numel(labels),1);
fam(:) = "Other/unknown";

% Amino acids
aa = ["l-histidine","l-tyrosine","l-phenylalanine","l-tryptophan","l-methionine", ...
      "l-leucine","l-isoleucine","l-valine","l-proline","l-lysine","l-arginine", ...
      "l-glutamine","l-glutamic","l-aspartic","l-serine","l-threonine","l-alanine","l-glycine","l-cysteine"];
isAA = false(size(labels));
for k = 1:numel(aa)
    isAA = isAA | contains(labels, aa(k));
end
isAA = isAA | startsWith(labels, "l-") | startsWith(labels, "d-") | contains(labels, "amino");

% Glucosinolates + breakdown
isGSL = contains(labels,"gluco") | contains(labels,"sinigrin") | (contains(labels,"sulf") & contains(labels,"gluco"));
isGSL = isGSL | contains(labels,"isothiocyan") | contains(labels,"nitrile") | contains(labels,"thiocyan");
isGSL = isGSL | (contains(labels,"indole") & contains(labels,"gluco"));

% Phenylpropanoids/phenolics
isPP = contains(labels,"caffeoyl") | contains(labels,"coumar") | contains(labels,"sinap") | contains(labels,"ferul") | ...
       contains(labels,"quinic") | contains(labels,"flav") | contains(labels,"kaempfer") | contains(labels,"quercet") | ...
       contains(labels,"luteolin") | contains(labels,"apigenin");

% Lipids/oxylipins
isLipid = contains(labels,"fatty") | contains(labels,"linole") | contains(labels,"linolen") | contains(labels,"oleic") | ...
          contains(labels,"palmit") | contains(labels,"stear") | contains(labels,"oxylipin") | contains(labels,"jasmon");

% Organic acids (non-phenolic)
isOrg = contains(labels,"acid") & ~isPP;

% Carbohydrates/derivatives
isCarb = contains(labels,"glucoside") | contains(labels,"diglucoside") | contains(labels,"fructosyl") | ...
         contains(labels,"glucose") | contains(labels,"sucrose") | contains(labels,"hexose");

% Apply priority: GSL > PP > Lipid > AA > Organic > Carb
fam(isCarb)  = "Carbohydrates/derivatives";
fam(isOrg)   = "Organic acids";
fam(isAA)    = "Amino acids";
fam(isLipid) = "Lipids/oxylipins";
fam(isPP)    = "Phenylpropanoids/phenolics";
fam(isGSL)   = "Glucosinolates";

end