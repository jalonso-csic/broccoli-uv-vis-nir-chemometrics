function BRC_obj2_Section32_SpectralStructure_run_v1()
% BRC_obj2_Section32_SpectralStructure_run_v1
% -------------------------------------------------------------------------
% Objective 2 — Section 3.2 reanalysis (audit-ready) - TWO FACTORS ONLY
% Outputs (all under ./Objetivo_2):
%   Tables/obj2_section32_outputs.xlsx
%   Figures/*.fig + *.png  (main)
%   Supplementary/*.fig + *.png
%   Code/BRC_obj2_Section32_SpectralStructure_run_v1.m (self-archived)
%   obj2_section32_log.txt
% -------------------------------------------------------------------------
%% =========================
% USER SETTINGS
%% =========================
TARGET_SCRIPT_NAME = 'BRC_obj2_Section32_SpectralStructure_run_v1.m';
OUTROOT            = fullfile(pwd, 'Objetivo_2');
INPUT_XLSX = 'Matriz_Brocoli_Sin_N.xlsx';
SHEET_NAME = '';  % '' = auto (first sheet)

% Optional manifest (Sample_ID) — will only be used if Sample_ID exists in matrix
USE_ANALYSISSET_MANIFEST = true;
ANALYSISSET_CSV          = 'analysis_set_retained.csv';

% Permutations
SEED0  = 123;
N_PERM = 4999;

% SG parameters
SG_POLY_ORDER = 2;
SG_FRAME_LEN  = 11;  % odd

% PCA export
N_PCS_EXPORT = 10;

% Plot style
FONT_NAME = 'Times New Roman';
FS_AX  = 10;
FS_LAB = 12;

%% =========================
% FORCE LIGHT EXPORT
%% =========================
forceLightTheme();

%% =========================
% FOLDERS
%% =========================
if ~exist(OUTROOT,'dir'); mkdir(OUTROOT); end
DIR_CODE  = fullfile(OUTROOT,'Code');
DIR_TABLE = fullfile(OUTROOT,'Tables');
DIR_FIGS  = fullfile(OUTROOT,'Figures');
DIR_SUPP  = fullfile(OUTROOT,'Supplementary');

if ~exist(DIR_CODE,'dir');  mkdir(DIR_CODE);  end
if ~exist(DIR_TABLE,'dir'); mkdir(DIR_TABLE); end
if ~exist(DIR_FIGS,'dir');  mkdir(DIR_FIGS);  end
if ~exist(DIR_SUPP,'dir');  mkdir(DIR_SUPP);  end

selfArchiveThisFile(DIR_CODE, TARGET_SCRIPT_NAME);

LOGFILE = fullfile(OUTROOT,'obj2_section32_log.txt');
if exist(LOGFILE,'file'); delete(LOGFILE); end
diary(LOGFILE);

fprintf('=== Objective 2 / Section 3.2 reanalysis (Two Factors) ===\n');
fprintf('Input: %s\n', INPUT_XLSX);
fprintf('Output root: %s\n', OUTROOT);
fprintf('Seed: %d | nPerm: %d\n', SEED0, N_PERM);
fprintf('SG poly: %d | SG window: %d\n\n', SG_POLY_ORDER, SG_FRAME_LEN);

%% =========================
% READ DATA
%% =========================
T = readtable_safely(INPUT_XLSX, SHEET_NAME);

% Robust factor-column detection
colPart = pickVarName(T, {'parte','part'});
colMat  = pickVarName(T, {'madur','matur'});

assert(~isempty(colPart), 'Could not detect Part/Parte column.');
assert(~isempty(colMat),  'Could not detect Maturity/Maduracion column.');

% Strict Sample_ID detection only
colSample = pickVarName_strict(T, {'Sample_ID','SampleID','sample_id','sampleid'});

fprintf('Detected columns:\n');
fprintf('  Part     : %s\n', colPart);
fprintf('  Maturity : %s\n', colMat);

if ~isempty(colSample)
    fprintf('  SampleID : %s\n\n', colSample);
else
    fprintf('  SampleID : (not found)\n\n');
end

%% =========================
% OPTIONAL manifest filter
%% =========================
manifestUsed = false;
if USE_ANALYSISSET_MANIFEST && exist(ANALYSISSET_CSV,'file')
    if isempty(colSample)
        warning('Manifest exists but Sample_ID column not found in matrix. Skipping manifest filter.');
    else
        S = readtable(ANALYSISSET_CSV);
        if ~any(strcmpi(S.Properties.VariableNames,'Sample_ID'))
            error('Manifest must contain a column named Sample_ID.');
        end
        keep = ismember(string(T.(colSample)), string(S.Sample_ID));
        fprintf('Manifest found: %s\n', ANALYSISSET_CSV);
        fprintf('Keeping %d/%d rows matched by Sample_ID.\n\n', sum(keep), height(T));
        T = T(keep,:);
        manifestUsed = true;
    end
else
    fprintf('NOTE: Manifest not used (missing or disabled): %s\n\n', ANALYSISSET_CSV);
end

assert(height(T) >= 10, 'Too few rows after filtering.');

%% =========================
% EXTRACT SPECTRA nm_* & TRANSLATE FACTORS
%% =========================
[wl, Xraw, specNames] = extractSpectra_nm(T); %#ok<ASGLU>
dx = checkUniformGrid(wl);

% Translate to English immediately so legends and tables are automatic
Part = categorical(englishPartLabels(T.(colPart))); Part = removecats(Part);
Mat  = categorical(englishMatLabels(T.(colMat)));   Mat  = removecats(Mat);

fprintf('n = %d | p = %d | dx = %.6g nm\n\n', size(Xraw,1), size(Xraw,2), dx);

%% =========================
% PREPROCESS
%% =========================
X_snv = snv_rows(Xraw);
X_sg1 = sg_derivative_rows(X_snv, SG_POLY_ORDER, SG_FRAME_LEN, 1, dx);
X_sg2 = sg_derivative_rows(X_snv, SG_POLY_ORDER, SG_FRAME_LEN, 2, dx);

% Autoscale for PCA / inference
[X_snv_z, muS, sdS] = autoscale_cols(X_snv); %#ok<ASGLU>
[X_sg2_z, ~,   ~  ] = autoscale_cols(X_sg2);

%% =========================
% FIG 2 (main): mean spectra by Part (SNV vs SG1)
%% =========================
fig = figure('Color','w','Units','pixels','Position',[80 80 1200 520], 'InvertHardcopy','on');
tlo = tiledlayout(fig,1,2,'TileSpacing','compact','Padding','compact');

nexttile; hold on;
plotMeanByGroup(wl, X_snv, Part, 1.4);
xlabel('Wavelength (nm)','FontName',FONT_NAME,'FontSize',FS_LAB);
ylabel('SNV-normalised spectra (a.u.)','FontName',FONT_NAME,'FontSize',FS_LAB);
title('(A) SNV','FontName',FONT_NAME,'FontSize',FS_LAB);
set(gca,'FontName',FONT_NAME,'FontSize',FS_AX,'Color','w'); grid on;
legend(categories(Part),'Location','best','Box','off');

nexttile; hold on;
plotMeanByGroup(wl, X_sg1, Part, 1.4);
xlabel('Wavelength (nm)','FontName',FONT_NAME,'FontSize',FS_LAB);
ylabel('SNV + SG 1st derivative (a.u.)','FontName',FONT_NAME,'FontSize',FS_LAB);
title('(B) SNV + SG 1st derivative','FontName',FONT_NAME,'FontSize',FS_LAB);
set(gca,'FontName',FONT_NAME,'FontSize',FS_AX,'Color','w'); grid on;
legend(categories(Part),'Location','best','Box','off');

title(tlo,'Mean spectra by plant part','FontName',FONT_NAME,'FontSize',FS_LAB);

robustSaveFig(fig, fullfile(DIR_FIGS,'Fig2_MeanSpectra_Part_SNV_vs_SG1'));

%% =========================
% FIG 3 (main): PCA by Part (SNV vs SG2)
%% =========================
ws = warning('off','stats:pca:ColRankDefX');

rng(SEED0,'twister');
nComp = min([N_PCS_EXPORT, size(X_snv_z,1)-1, size(X_snv_z,2)]);
[~, score_snv, ~, ~, expl_snv] = pca(X_snv_z,'Centered',false,'Algorithm','svd','NumComponents',nComp);

rng(SEED0,'twister');
nComp2 = min([N_PCS_EXPORT, size(X_sg2_z,1)-1, size(X_sg2_z,2)]);
[~, score_sg2, ~, ~, expl_sg2] = pca(X_sg2_z,'Centered',false,'Algorithm','svd','NumComponents',nComp2);
warning(ws);

fig = figure('Color','w','Units','pixels','Position',[80 80 1200 520], 'InvertHardcopy','on');
tlo = tiledlayout(fig,1,2,'TileSpacing','compact','Padding','compact');

nexttile;
gscatter(score_snv(:,1), score_snv(:,2), Part);
xlabel(sprintf('PC1 (%.1f%%)', expl_snv(1)),'FontName',FONT_NAME,'FontSize',FS_LAB);
ylabel(sprintf('PC2 (%.1f%%)', expl_snv(2)),'FontName',FONT_NAME,'FontSize',FS_LAB);
title('(A) PCA scores (SNV)','FontName',FONT_NAME,'FontSize',FS_LAB);
set(gca,'FontName',FONT_NAME,'FontSize',FS_AX,'Color','w'); grid on;
legend('Location','best','Box','off');

nexttile;
gscatter(score_sg2(:,1), score_sg2(:,2), Part);
xlabel(sprintf('PC1 (%.1f%%)', expl_sg2(1)),'FontName',FONT_NAME,'FontSize',FS_LAB);
ylabel(sprintf('PC2 (%.1f%%)', expl_sg2(2)),'FontName',FONT_NAME,'FontSize',FS_LAB);
title('(B) PCA scores (SNV + SG 2nd derivative)','FontName',FONT_NAME,'FontSize',FS_LAB);
set(gca,'FontName',FONT_NAME,'FontSize',FS_AX,'Color','w'); grid on;
legend('Location','best','Box','off');

title(tlo,'PCA score space by plant part','FontName',FONT_NAME,'FontSize',FS_LAB);

robustSaveFig(fig, fullfile(DIR_FIGS,'Fig3_PCA_Part_SNV_vs_SG2'));

%% =========================
% SUPP FIG S2: mean spectra by Maturity (SNV)
%% =========================
fig = figure('Color','w','Units','pixels','Position',[80 80 600 520], 'InvertHardcopy','on');

hold on;
plotMeanByGroup(wl, X_snv, Mat, 1.3);
xlabel('Wavelength (nm)','FontName',FONT_NAME,'FontSize',FS_LAB);
ylabel('SNV-normalised spectra (a.u.)','FontName',FONT_NAME,'FontSize',FS_LAB);
title('Mean spectra by Maturity (SNV)','FontName',FONT_NAME,'FontSize',FS_LAB);
set(gca,'FontName',FONT_NAME,'FontSize',FS_AX,'Color','w'); grid on;
legend(categories(Mat),'Location','best','Box','off');

% Figure numbering updated from FigS1 to FigS2
robustSaveFig(fig, fullfile(DIR_SUPP,'FigS2_MeanSpectra_Maturity_SNV'));

%% =========================
% SUPP FIG S3: PCA by Maturity (SNV vs SG2)
%% =========================
fig = figure('Color','w','Units','pixels','Position',[80 80 1200 450], 'InvertHardcopy','on');
tlo = tiledlayout(fig,1,2,'TileSpacing','compact','Padding','compact');

nexttile;
gscatter(score_snv(:,1), score_snv(:,2), Mat);
xlabel(sprintf('PC1 (%.1f%%)', expl_snv(1)),'FontName',FONT_NAME,'FontSize',FS_LAB);
ylabel(sprintf('PC2 (%.1f%%)', expl_snv(2)),'FontName',FONT_NAME,'FontSize',FS_LAB);
title('Maturity — SNV','FontName',FONT_NAME,'FontSize',FS_LAB);
set(gca,'FontName',FONT_NAME,'FontSize',FS_AX,'Color','w'); grid on;
legend('Location','best','Box','off');

nexttile;
gscatter(score_sg2(:,1), score_sg2(:,2), Mat);
xlabel(sprintf('PC1 (%.1f%%)', expl_sg2(1)),'FontName',FONT_NAME,'FontSize',FS_LAB);
ylabel(sprintf('PC2 (%.1f%%)', expl_sg2(2)),'FontName',FONT_NAME,'FontSize',FS_LAB);
title('Maturity — SNV + SG2','FontName',FONT_NAME,'FontSize',FS_LAB);
set(gca,'FontName',FONT_NAME,'FontSize',FS_AX,'Color','w'); grid on;
legend('Location','best','Box','off');

title(tlo,'PCA score space by Maturity (supplementary)','FontName',FONT_NAME,'FontSize',FS_LAB);

% Figure numbering updated from FigS2 to FigS3
robustSaveFig(fig, fullfile(DIR_SUPP,'FigS3_PCA_Maturity_SNV_vs_SG2'));

%% =========================
% TABLES: PCA explained variance
%% =========================
tblPCA_SNV = makePCAexplainedTable(expl_snv, N_PCS_EXPORT, 'SNV');
tblPCA_SG2 = makePCAexplainedTable(expl_sg2, N_PCS_EXPORT, 'SNV_SG2');

%% =========================
% TABLES: Freedman–Lane multivariate factorial test (X space)
%% =========================
terms = defineTerms();

rng(SEED0,'twister');
res_SNV = runFreedmanLaneMANOVA_fast(X_snv_z, Part, Mat, terms, N_PERM);
res_SNV.q_BH = bh_fdr(res_SNV.p_perm);

rng(SEED0,'twister');
res_SG2 = runFreedmanLaneMANOVA_fast(X_sg2_z, Part, Mat, terms, N_PERM);
res_SG2.q_BH = bh_fdr(res_SG2.p_perm);

%% =========================
% EXPORT EXCEL
%% =========================
OUTXLSX = fullfile(DIR_TABLE,'obj2_section32_outputs.xlsx');
if exist(OUTXLSX,'file'); delete(OUTXLSX); end

meta = table();
meta.Item  = {'InputFile';'Sheet';'nRows';'nSpectralVars';'WavelengthMin_nm';'WavelengthMax_nm';'dx_nm'; ...
              'Permutations';'Seed';'SG_poly';'SG_window';'ManifestUsed';'ManifestFile';'ScriptArchivedAs'};
meta.Value = {INPUT_XLSX; SHEET_NAME; num2str(size(Xraw,1)); num2str(size(Xraw,2)); ...
              num2str(min(wl)); num2str(max(wl)); num2str(dx); num2str(N_PERM); num2str(SEED0); ...
              num2str(SG_POLY_ORDER); num2str(SG_FRAME_LEN); logicalToText(manifestUsed); ANALYSISSET_CSV; TARGET_SCRIPT_NAME};

writetable(meta, OUTXLSX, 'Sheet','Meta');
writetable(designLevelCounts(Part, Mat), OUTXLSX, 'Sheet','DesignLevels');
writetable(makeMeanSDtable(wl, X_snv), OUTXLSX, 'Sheet','MeanSD_SNV');
writetable(makeMeanSDtable(wl, X_sg1), OUTXLSX, 'Sheet','MeanSD_SNV_SG1');
writetable(makeMeanByGroupTable(wl, X_snv, Part, 'Part'), OUTXLSX, 'Sheet','MeanByPart_SNV');
writetable(makeMeanByGroupTable(wl, X_sg1, Part, 'Part'), OUTXLSX, 'Sheet','MeanByPart_SNV_SG1');
writetable(makeMeanByGroupTable(wl, X_snv, Mat,  'Maturity'), OUTXLSX, 'Sheet','MeanByMaturity_SNV');

writetable(tblPCA_SNV, OUTXLSX, 'Sheet','PCA_Explained_SNV');
writetable(tblPCA_SG2, OUTXLSX, 'Sheet','PCA_Explained_SNV_SG2');

writetable(res_SNV, OUTXLSX, 'Sheet','Table4_SNV');
writetable(res_SG2, OUTXLSX, 'Sheet','Table5_SNV_SG2');

fprintf('\nDONE.\nExcel: %s\nMain figs: %s\nSupp figs: %s\nLog: %s\n', OUTXLSX, DIR_FIGS, DIR_SUPP, LOGFILE);
diary off;

end % end main function

%% ========================================================================
% LOCAL FUNCTIONS
%% ========================================================================

function forceLightTheme()
    try
        set(groot,'defaultFigureColor','w');
        set(groot,'defaultAxesColor','w');
        set(groot,'defaultTextColor','k');
        set(groot,'defaultAxesXColor','k');
        set(groot,'defaultAxesYColor','k');
        set(groot,'defaultAxesZColor','k');
    catch
    end
end

function txt = logicalToText(x)
    if x; txt = 'true'; else; txt = 'false'; end
end

function selfArchiveThisFile(codeDir, targetName)
    if ~exist(codeDir,'dir'); mkdir(codeDir); end
    dest = fullfile(codeDir, targetName);
    try
        thisFull = mfilename('fullpath'); % without extension
        if ~isempty(thisFull) && exist([thisFull '.m'],'file')
            copyfile([thisFull '.m'], dest);
            fprintf('Script archived (copy): %s\n', dest);
            return;
        end
    catch
    end
    warning('Script could not be auto-archived (copy).');
end

function T = readtable_safely(infile, sheetName)
    if ~exist(infile,'file')
        error('Input file not found: %s', infile);
    end
    if isempty(sheetName)
        try
            sh = sheetnames(infile);
            sheetName = sh{1};
        catch
            sheetName = 1;
        end
    end
    try
        opts = detectImportOptions(infile,'Sheet',sheetName);
        try
            opts.VariableNamingRule = 'preserve';
        catch
        end
        T = readtable(infile, opts);
    catch
        T = readtable(infile);
    end
end

function name = pickVarName(T, candidates)
    vars = string(T.Properties.VariableNames);
    name = '';
    for i=1:numel(candidates)
        c = lower(string(candidates{i}));
        idx = find(strcmpi(vars, c), 1);
        if ~isempty(idx)
            name = char(vars(idx));
            return;
        end
    end
    lvars = lower(vars);
    for i=1:numel(candidates)
        c = lower(string(candidates{i}));
        idx = find(contains(lvars, c), 1);
        if ~isempty(idx)
            name = char(vars(idx));
            return;
        end
    end
end

function name = pickVarName_strict(T, candidates)
    vars = string(T.Properties.VariableNames);
    name = '';
    for i=1:numel(candidates)
        idx = find(strcmpi(vars, string(candidates{i})), 1);
        if ~isempty(idx)
            name = char(vars(idx));
            return;
        end
    end
end

function [wl, Xraw, specNames] = extractSpectra_nm(T)
    allNames  = string(T.Properties.VariableNames);
    isSpec    = startsWith(allNames, "nm_");
    specNames = allNames(isSpec);
    assert(~isempty(specNames), 'No spectral columns found. Expected nm_### columns.');

    wl = nan(numel(specNames),1);
    for i=1:numel(specNames)
        tok = regexp(specNames(i), '^nm_(\d+)$', 'tokens', 'once');
        assert(~isempty(tok), 'Bad spectral column name: %s', specNames(i));
        wl(i) = str2double(tok{1});
    end

    [wl, ord] = sort(wl, 'ascend');
    specNames = specNames(ord);
    Xraw = double(table2array(T(:, specNames)));
end

function dx = checkUniformGrid(wl)
    d = diff(wl(:));
    dx = median(d);
    if any(abs(d - dx) > 1e-9)
        warning('Wavelength grid not perfectly uniform. Using median dx=%.6g', dx);
    end
end

function Xs = snv_rows(X)
    mu = mean(X, 2, 'omitnan');
    sd = std(X, 0, 2, 'omitnan');
    sd(sd==0) = 1;
    Xs = (X - mu) ./ sd;
end

function [Xa, mu, sd] = autoscale_cols(X)
    mu = mean(X, 1, 'omitnan');
    sd = std(X, 0, 1, 'omitnan');
    sd(sd==0) = 1;
    Xa = (X - mu) ./ sd;
end

function Xd = sg_derivative_rows(X, polyOrder, frameLen, derivOrder, dx)
    if mod(frameLen,2) == 0
        error('Savitzky–Golay frameLen must be odd.');
    end
    if ~(derivOrder==1 || derivOrder==2)
        error('Only 1st or 2nd derivative supported.');
    end
    [~, G] = sgolay(polyOrder, frameLen);
    h = factorial(derivOrder) / (dx^derivOrder) * G(:, derivOrder+1);
    half = (frameLen-1)/2;
    Xd = zeros(size(X));
    for i = 1:size(X,1)
        x = X(i,:);
        left  = x(half:-1:1);
        right = x(end:-1:end-half+1);
        xpad  = [left, x, right];
        y = conv(xpad, flipud(h), 'valid');
        Xd(i,:) = y;
    end
end

function plotMeanByGroup(wl, X, g, lw)
    lv = categories(g);
    for i = 1:numel(lv)
        idx = (g == lv{i});
        mu = mean(X(idx,:), 1, 'omitnan');
        plot(wl, mu, 'LineWidth', lw);
    end
end

function labels = englishPartLabels(labelsIn)
    labels = string(labelsIn);
    for i=1:numel(labels)
        s = lower(strtrim(labels(i)));
        if any(strcmp(s, ["hoja","hojas","leaf","leaves"]))
            labels(i) = "Leaf";
        elseif any(strcmp(s, ["inflorescencia","inflorescence","floret","florets"]))
            labels(i) = "Floret";
        elseif any(strcmp(s, ["tallo","stem","stems"]))
            labels(i) = "Stem";
        end
    end
    labels = cellstr(labels);
end

% Translation helper for Maturity labels
function labels = englishMatLabels(labelsIn)
    labels = string(labelsIn);
    for i=1:numel(labels)
        s = lower(strtrim(labels(i)));
        if contains(s, "inmadur") || contains(s, "immature")
            labels(i) = "Immature";
        elseif contains(s, "comercial") || contains(s, "commercial") || contains(s, "óptimo") || contains(s, "optimo")
            labels(i) = "Commercial";
        elseif contains(s, "sobre") || contains(s, "over") || contains(s, "senescent")
            labels(i) = "Overmature";
        else
            % Fallback: capitalise the first letter for unrecognised labels
            c = char(labels(i));
            if ~isempty(c)
                c(1) = upper(c(1));
                labels(i) = string(c);
            end
        end
    end
    labels = cellstr(labels);
end

function robustSaveFig(fig, basePathNoExt)
    drawnow;
    ax = findall(fig,'Type','axes');
    for i=1:numel(ax)
        try
            ax(i).Toolbar.Visible = 'off';
        catch
        end
        try
            axtoolbar(ax(i),{});
        catch
        end
        try
            set(ax(i),'Color','w');
        catch
        end
    end
    try
        set(fig,'Color','w','InvertHardcopy','on');
    catch
    end

    try
        savefig(fig, [basePathNoExt '.fig']);
    catch
        try
            saveas(fig, [basePathNoExt '.fig']);
        catch
            warning('SaveFIG failed: %s', basePathNoExt);
        end
    end

    try
        print(fig, [basePathNoExt '.png'], '-dpng', '-r400');
    catch
        warning('PNG export failed: %s', basePathNoExt);
    end
    close(fig);
end

function terms = defineTerms()
    terms = struct();
    terms(1).name = 'Part';
    terms(2).name = 'Maturity';
    terms(3).name = 'Part×Maturity';
end

function Z = buildDesign(Part, Mat, include)
    Z = ones(numel(Part),1);
    Dp = dummyvar(Part); Dp = Dp(:,2:end);
    Dm = dummyvar(Mat);  Dm = Dm(:,2:end);
    
    if include.includePart; Z = [Z, Dp]; end 
    if include.includeMat;  Z = [Z, Dm]; end 
    if include.includePM; Z = [Z, interactionDummy(Dp, Dm)]; end 
end

function Dint = interactionDummy(D1, D2)
    [n, p1] = size(D1);
    p2 = size(D2,2);
    Dint = zeros(n, p1*p2);
    k = 1;
    for i=1:p1
        for j=1:p2
            Dint(:,k) = D1(:,i) .* D2(:,j);
            k = k + 1;
        end
    end
end

function resTbl = runFreedmanLaneMANOVA_fast(X, Part, Mat, terms, nPerm)
    n = size(X,1);
    incFull = struct('includePart',true,'includeMat',true,'includePM',true);
    Zfull = buildDesign(Part, Mat, incFull);

    [Qf, ~] = qr(Zfull, 0);
    Pf = Qf*Qf';
    dfFull = rank(Zfull);
    dfErr  = n - dfFull;
    XhatFull = Pf * X;
    Efull    = X - XhatFull;
    SSEfull  = sum(Efull.^2, 'all');
    SST      = sum(X.^2, 'all');

    resTbl = table('Size',[numel(terms) 10], ...
        'VariableTypes', {'cell','double','double','double','double','double','double','double','double','double'}, ...
        'VariableNames', {'Term','df_term','df_error','SS_term','SS_error','F','p_perm','R2','eta2p','nPerm'});

    for t=1:numel(terms)
        termName = terms(t).name;
        incRed = incFull;
        switch termName
            case 'Part';            incRed.includePart = false;
            case 'Maturity';        incRed.includeMat  = false;
            case 'Part×Maturity';   incRed.includePM   = false;
            otherwise
                error('Unknown term: %s', termName);
        end

        Zred = buildDesign(Part, Mat, incRed);
        [Qr, ~] = qr(Zred, 0);
        Pr = Qr*Qr';
        dfRed  = rank(Zred);
        dfTerm = dfFull - dfRed;

        XhatRed   = Pr * X;
        SStermObs = sum((XhatFull - XhatRed).^2, 'all');
        Fobs      = (SStermObs/dfTerm) / (SSEfull/dfErr);

        Ered0 = X - XhatRed;

        Fperm = zeros(nPerm,1);
        for b=1:nPerm
            idx = randperm(n);
            Xb  = XhatRed + Ered0(idx,:);
            XhatFull_b = Pf * Xb;
            SSEfull_b  = sum((Xb - XhatFull_b).^2, 'all');
            
            XhatRed_b  = Pr * Xb;
            SSterm_b   = sum((XhatFull_b - XhatRed_b).^2, 'all');

            Fperm(b) = (SSterm_b/dfTerm) / (SSEfull_b/dfErr);
        end

        pPerm = (1 + sum(Fperm >= Fobs)) / (1 + nPerm);

        resTbl.Term{t}     = termName;
        resTbl.df_term(t)  = dfTerm;
        resTbl.df_error(t) = dfErr;
        resTbl.SS_term(t)  = SStermObs;
        resTbl.SS_error(t) = SSEfull;
        resTbl.F(t)        = Fobs;
        resTbl.p_perm(t)   = pPerm;
        resTbl.R2(t)       = SStermObs / SST;
        resTbl.eta2p(t)    = SStermObs / (SStermObs + SSEfull);
        resTbl.nPerm(t)    = nPerm;

        fprintf('Term %-14s | F=%.3f | p_perm=%.4g | R2=%.3f | eta2p=%.3f\n', ...
            termName, Fobs, pPerm, resTbl.R2(t), resTbl.eta2p(t));
    end
end

function q = bh_fdr(p)
    p = p(:);
    q = NaN(size(p));
    ok = ~isnan(p);
    p0 = p(ok);
    [ps, idx] = sort(p0, 'ascend');
    m = numel(ps);
    if m==0; return; end

    qs = ps .* (m ./ (1:m)');
    for i=m-1:-1:1
        qs(i) = min(qs(i), qs(i+1));
    end
    qs(qs>1) = 1;

    q0 = NaN(size(p0));
    q0(idx) = qs;
    q(ok) = q0;
end

function tbl = makePCAexplainedTable(expl, nPC, cfgName)
    nPC = min(nPC, numel(expl));
    tbl = table();
    tbl.CFG = repmat({cfgName}, nPC, 1);
    tbl.PC  = (1:nPC)';
    tbl.Explained_pct  = expl(1:nPC);
    tbl.Cumulative_pct = cumsum(expl(1:nPC));
end

function tbl = makeMeanSDtable(wl, X)
    mu = mean(X, 1, 'omitnan');
    sd = std(X, 0, 1, 'omitnan');
    tbl = table(wl(:), mu(:), sd(:), 'VariableNames', {'Wavelength_nm','Mean','SD'});
end

function tbl = makeMeanByGroupTable(wl, X, g, gName)
    lv = categories(g);
    M = NaN(numel(lv), numel(wl));
    for i=1:numel(lv)
        idx = (g == lv{i});
        M(i,:) = mean(X(idx,:), 1, 'omitnan');
    end
    tbl = array2table(M, 'VariableNames', compose('nm_%d', wl));
    tbl = addvars(tbl, string(lv(:)), 'Before', 1, 'NewVariableNames', gName);
end

function tbl = designLevelCounts(Part, Mat)
    tbl = table();
    tbl.Factor = {'Part'; 'Maturity'};
    tbl.Levels = {strjoin(string(categories(Part)), ', '); ...
                  strjoin(string(categories(Mat)),  ', ')};
    tbl.Counts = {strjoin(string(countcats(Part))', ', '); ...
                  strjoin(string(countcats(Mat))',  ', ')};
end