%-----------------------------------------------------------------------
% Job saved on 20-Mar-2026 17:11:36 by cfg_util (rev $Rev: 8183 $)
% spm SPM - SPM25 (25.01.02)
% cfg_basicio BasicIO - Unknown
%-----------------------------------------------------------------------
matlabbatch{1}.spm.stats.factorial_design.dir = {''};%enter desired directory for specific contrast
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).name = 'treatment';
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).levels = 3;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).dept = 0;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).variance = 1;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).gmsca = 0;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).ancova = 0;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(2).name = 'timepoint';
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(2).levels = 2;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(2).dept = 1;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(2).variance = 1;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(2).gmsca = 0;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(2).ancova = 0;
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(1).levels = [1
                                                                    1];
%% enter paths to respective .con files of subjects' previous first level analysis
% FASTER pre, ses-1
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(1).scans = {''};
%%
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(2).levels = [1
                                                                    2];
%% FASTER post, ses-2
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(2).scans = {''};
%%
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(3).levels = [2
                                                                    1];
%% SCOTT pre, ses-1
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(3).scans = {''};
%%
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(4).levels = [2
                                                                    2];
%% SCOTT post, ses-2
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(4).scans = {''};
%% TAU pre, ses-1
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(5).levels = [3
                                                                    1];
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(5).scans = {''};
% TAU post, ses-2
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(6).levels = [3
                                                                    2];
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(6).scans = {''};
matlabbatch{1}.spm.stats.factorial_design.des.fd.contrasts = 1;
matlabbatch{1}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{1}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.im = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.em = {''};
matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;
matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('Factorial design specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
matlabbatch{3}.spm.stats.con.spmmat(1) = cfg_dep('Model estimation: SPM.mat File', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
matlabbatch{3}.spm.stats.con.consess{1}.fcon.name = 'TREATMENT';
matlabbatch{3}.spm.stats.con.consess{1}.fcon.weights = [1 1 -1 -1 0 0
                                                        0 0 1 1 -1 -1];
matlabbatch{3}.spm.stats.con.consess{1}.fcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.consess{2}.tcon.name = 'FASTER > SCOTT';
matlabbatch{3}.spm.stats.con.consess{2}.tcon.weights = [1 1 -1 -1 0 0];
matlabbatch{3}.spm.stats.con.consess{2}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.consess{3}.tcon.name = 'FASTER < SCOTT';
matlabbatch{3}.spm.stats.con.consess{3}.tcon.weights = [-1 -1 1 1 0 0];
matlabbatch{3}.spm.stats.con.consess{3}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.consess{4}.tcon.name = 'FASTER > TAU';
matlabbatch{3}.spm.stats.con.consess{4}.tcon.weights = [1 1 0 0 -1 -1];
matlabbatch{3}.spm.stats.con.consess{4}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.consess{5}.tcon.name = 'FASTER < TAU';
matlabbatch{3}.spm.stats.con.consess{5}.tcon.weights = [-1 -1 0 0 1 1];
matlabbatch{3}.spm.stats.con.consess{5}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.consess{6}.tcon.name = 'SCOTT > TAU';
matlabbatch{3}.spm.stats.con.consess{6}.tcon.weights = [0 0 1 1 -1 -1];
matlabbatch{3}.spm.stats.con.consess{6}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.consess{7}.tcon.name = 'SCOTT < TAU';
matlabbatch{3}.spm.stats.con.consess{7}.tcon.weights = [0 0 -1 -1 1 1];
matlabbatch{3}.spm.stats.con.consess{7}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.consess{8}.fcon.name = 'TIME';
matlabbatch{3}.spm.stats.con.consess{8}.fcon.weights = [-1 1 -1 1 -1 1];
matlabbatch{3}.spm.stats.con.consess{8}.fcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.consess{9}.tcon.name = 'POST > PRE';
matlabbatch{3}.spm.stats.con.consess{9}.tcon.weights = [-1 1 -1 1 -1 1];
matlabbatch{3}.spm.stats.con.consess{9}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.consess{10}.tcon.name = 'POST < PRE';
matlabbatch{3}.spm.stats.con.consess{10}.tcon.weights = [1 -1 1 -1 1 -1];
matlabbatch{3}.spm.stats.con.consess{10}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.consess{11}.tcon.name = 'FASTER POST > PRE';
matlabbatch{3}.spm.stats.con.consess{11}.tcon.weights = [-1 1 0 0 0 0];
matlabbatch{3}.spm.stats.con.consess{11}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.consess{12}.tcon.name = 'FASTER POST < PRE';
matlabbatch{3}.spm.stats.con.consess{12}.tcon.weights = [1 -1 0 0 0 0];
matlabbatch{3}.spm.stats.con.consess{12}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.consess{13}.tcon.name = 'SCOTT POST > PRE';
matlabbatch{3}.spm.stats.con.consess{13}.tcon.weights = [0 0 -1 1 0 0];
matlabbatch{3}.spm.stats.con.consess{13}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.consess{14}.tcon.name = 'SCOTT POST < PRE';
matlabbatch{3}.spm.stats.con.consess{14}.tcon.weights = [0 0 1 -1 0 0];
matlabbatch{3}.spm.stats.con.consess{14}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.consess{15}.tcon.name = 'TAU POST > PRE';
matlabbatch{3}.spm.stats.con.consess{15}.tcon.weights = [0 0 0 0 -1 1];
matlabbatch{3}.spm.stats.con.consess{15}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.consess{16}.tcon.name = 'TAU POST < PRE';
matlabbatch{3}.spm.stats.con.consess{16}.tcon.weights = [0 0 0 0 1 -1];
matlabbatch{3}.spm.stats.con.consess{16}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.consess{17}.fcon.name = 'TREATMENT X TIME';
matlabbatch{3}.spm.stats.con.consess{17}.fcon.weights = [-1 1 0 0 1 -1
                                                         0 0 -1 1 1 -1];
matlabbatch{3}.spm.stats.con.consess{17}.fcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.consess{18}.tcon.name = 'FASTER_DIFF > SCOTT_DIFF';
matlabbatch{3}.spm.stats.con.consess{18}.tcon.weights = [-1 1 1 -1 0 0];
matlabbatch{3}.spm.stats.con.consess{18}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.consess{19}.tcon.name = 'FASTER_DIFF < SCOTT_DIFF';
matlabbatch{3}.spm.stats.con.consess{19}.tcon.weights = [1 -1 -1 1 0 0];
matlabbatch{3}.spm.stats.con.consess{19}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.consess{20}.tcon.name = 'FASTER_DIFF > TAU_DIFF';
matlabbatch{3}.spm.stats.con.consess{20}.tcon.weights = [-1 1 0 0 1 -1];
matlabbatch{3}.spm.stats.con.consess{20}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.consess{21}.tcon.name = 'FASTER_DIFF < TAU_DIFF';
matlabbatch{3}.spm.stats.con.consess{21}.tcon.weights = [1 -1 0 0 -1 1];
matlabbatch{3}.spm.stats.con.consess{21}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.consess{22}.tcon.name = 'SCOTT_DIFF > TAU_DIFF';
matlabbatch{3}.spm.stats.con.consess{22}.tcon.weights = [0 0 -1 1 1 -1];
matlabbatch{3}.spm.stats.con.consess{22}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.consess{23}.tcon.name = 'SCOTT_DIFF < TAU_DIFF';
matlabbatch{3}.spm.stats.con.consess{23}.tcon.weights = [0 0 1 -1 -1 1];
matlabbatch{3}.spm.stats.con.consess{23}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.delete = 0;
