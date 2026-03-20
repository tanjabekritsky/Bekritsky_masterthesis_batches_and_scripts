% =========================================================
% Whole-brain baseline group differences (PRE only)
% 3-group one-way ANOVA implemented as full factorial with
% one factor (treatment) and three levels
% =========================================================

clear matlabbatch

% -------------------------
% Paths
% -------------------------
outdir  = '';% desired ouput directory
ffxdir  = '';%directory of respective con files
confile = '';   % con_xxxx.nii (.con file for respective contrast)

if ~exist(outdir, 'dir')
    mkdir(outdir);
end

% -------------------------
% Subject IDs from confirmatory batch
% Use zero-padded 5-digit IDs to match folder names
% -------------------------
FASTER_ids = {''};

SCOTT_ids = {''};

TAU_ids = { ''};

% -------------------------
% Build PRE scan paths
% -------------------------
mk_scan = @(id) sprintf('%s/ses-1/sub-%s/%s,1', ffxdir, id, confile);

FASTER_pre = cellfun(mk_scan, FASTER_ids, 'UniformOutput', false)';
SCOTT_pre  = cellfun(mk_scan, SCOTT_ids,  'UniformOutput', false)';
TAU_pre    = cellfun(mk_scan, TAU_ids,    'UniformOutput', false)';

% Optional sanity checks
assert(numel(FASTER_pre) == 13, 'Unexpected number of FASTER scans.');
assert(numel(SCOTT_pre)  == 26, 'Unexpected number of SCOTT scans.');
assert(numel(TAU_pre)    == 6,  'Unexpected number of TAU scans.');

all_scans = [FASTER_pre; SCOTT_pre; TAU_pre];
for i = 1:numel(all_scans)
    nii = erase(all_scans{i}, ',1');
    if ~exist(nii, 'file')
        error('Missing file: %s', nii);
    end
end

% =========================================================
% 1) Factorial design specification
% =========================================================
matlabbatch{1}.spm.stats.factorial_design.dir = {outdir};

% One factor: treatment
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).name = 'treatment';
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).levels = 3;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).dept = 0;      % independent groups
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).variance = 1;  % unequal variance
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).gmsca = 0;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).ancova = 0;

% Cell 1 = FASTER
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(1).levels = [1];
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(1).scans  = FASTER_pre;

% Cell 2 = SCOTT
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(2).levels = [2];
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(2).scans  = SCOTT_pre;

% Cell 3 = TAU
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(3).levels = [3];
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(3).scans  = TAU_pre;

% Let SPM create the default factor contrast as well
matlabbatch{1}.spm.stats.factorial_design.des.fd.contrasts = 1;

% No covariates
matlabbatch{1}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{1}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});

% Masking / globals
matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.im = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.em = {''};

matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;

% =========================================================
% 2) Model estimation
% =========================================================
matlabbatch{2}.spm.stats.fmri_est.spmmat = {fullfile(outdir, 'SPM.mat')};
matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;

% =========================================================
% 3) Contrasts
% Cell order = [FASTER  SCOTT  TAU]
% =========================================================
matlabbatch{3}.spm.stats.con.spmmat = {fullfile(outdir, 'SPM.mat')};

% Omnibus F-test: any baseline group difference
matlabbatch{3}.spm.stats.con.consess{1}.fcon.name = 'Any baseline group difference';
matlabbatch{3}.spm.stats.con.consess{1}.fcon.weights = [ ...
     1 -1  0
     1  0 -1];
matlabbatch{3}.spm.stats.con.consess{1}.fcon.sessrep = 'none';

% Pairwise t-contrasts
matlabbatch{3}.spm.stats.con.consess{2}.tcon.name = 'FASTER > SCOTT';
matlabbatch{3}.spm.stats.con.consess{2}.tcon.weights = [ 1 -1  0];
matlabbatch{3}.spm.stats.con.consess{2}.tcon.sessrep = 'none';

matlabbatch{3}.spm.stats.con.consess{3}.tcon.name = 'FASTER < SCOTT';
matlabbatch{3}.spm.stats.con.consess{3}.tcon.weights = [-1  1  0];
matlabbatch{3}.spm.stats.con.consess{3}.tcon.sessrep = 'none';

matlabbatch{3}.spm.stats.con.consess{4}.tcon.name = 'FASTER > TAU';
matlabbatch{3}.spm.stats.con.consess{4}.tcon.weights = [ 1  0 -1];
matlabbatch{3}.spm.stats.con.consess{4}.tcon.sessrep = 'none';

matlabbatch{3}.spm.stats.con.consess{5}.tcon.name = 'FASTER < TAU';
matlabbatch{3}.spm.stats.con.consess{5}.tcon.weights = [-1  0  1];
matlabbatch{3}.spm.stats.con.consess{5}.tcon.sessrep = 'none';

matlabbatch{3}.spm.stats.con.consess{6}.tcon.name = 'SCOTT > TAU';
matlabbatch{3}.spm.stats.con.consess{6}.tcon.weights = [ 0  1 -1];
matlabbatch{3}.spm.stats.con.consess{6}.tcon.sessrep = 'none';

matlabbatch{3}.spm.stats.con.consess{7}.tcon.name = 'SCOTT < TAU';
matlabbatch{3}.spm.stats.con.consess{7}.tcon.weights = [ 0 -1  1];
matlabbatch{3}.spm.stats.con.consess{7}.tcon.sessrep = 'none';

matlabbatch{3}.spm.stats.con.delete = 0;
