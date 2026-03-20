%% First Level FFX Analysis for fMRI FAR Task Data 
% Description: This script performs first level analyses on the ICA-AROMA data. 
% It processes multiple subjects sequentially,
% specifying models, estimating parameters, and defining contrasts.
% This one is specifically for ses-1 data, so you need to change it to ses-2
% if you want to process ses-2 data
% It uses an Imp Mask of 0.8 mm
% It includes Instruction as a regressor of non-interest
%
% Author: Original by Christian Kaufmann, adapted by Simon Kirsch, then by
% Muyu Lin, then by Tanja Bekritsky
% Changelog:
%   - Added error logging to file
%   - Improved input validation
%   - Added configuration section for easy parameter adjustment
%   - Optimized resource management
%   - Added progress tracking
%   - Improved documentation

%% Configuration Section
% This section contains all configurable parameters for the analysis
% Modify these values as needed without changing the main processing code

% Subject list - specify which subjects to process


% enter subject IDs   
ffxSubjects = {'' };



% Path configuration:
config = struct();
% here is the folder where fmriprep outputs (.nii) are located (specify which task
% (FAR), which session, whether functional data (func), whether with ICA
% AROMA or not (MNI152NLin6Asym_desc-smoothAROMAnonaggr)
config.baseDirNifti = '//'; 
config.subDirNifti = '';
config.niftiNameEndingWOZip = '';

% here is the folder for first level analysis output will be located. 
config.resultsBaseDirName = '//';

% here is all the SPM stimuli time files. 
config.designparameterDir = '';

config.SPMmatFile = '/SPM.mat';

% fMRI parameters
config.TR = 0.8;           % Repetition time in seconds
config.microtime = 72;     % Number of time bins per scan
config.microtime0 = 36;    % Reference time bin
config.hpf = 128;          % High-pass filter cutoff

% Get current script directory for error logging
scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end
config.errorLogFile = fullfile(scriptDir, 'error_log.txt');
config.progressLogFile = fullfile(scriptDir, 'progress_log.txt');

%% Initialize processing
% Record start time and create log files
totalStartTime = tic;
totalSubjects = length(ffxSubjects);
processingTimes = zeros(totalSubjects, 1);

% Initialize error log file
fid = fopen(config.errorLogFile, 'a');
fprintf(fid, '=== Processing started at %s ===\n', datestr(now));
fclose(fid);

% Initialize progress log file
fid = fopen(config.progressLogFile, 'a');
fprintf(fid, '=== Processing started at %s ===\n', datestr(now));
fprintf(fid, 'Total subjects to process: %d\n', totalSubjects);
fclose(fid);

% Display information
fprintf('Starting processing of %d subjects\n', totalSubjects);
fprintf('Logs will be saved to:\n  %s\n  %s\n', config.errorLogFile, config.progressLogFile);

%% Main processing loop
for noOfSubj = 1:totalSubjects
    subjectID = ffxSubjects{noOfSubj};
    
    % Clear variables from previous iterations to manage memory
    if exist('matlabbatch', 'var')
        clear matlabbatch;
    end
    if exist('SPM', 'var')
        clear SPM;
    end
    
    % Log start of processing for this subject
    fprintf('\nProcessing subject %d/%d: %s\n', noOfSubj, totalSubjects, subjectID);
    sumFFXEstimationDurationTemp = tic; % Measure time
    
    try
        % Input validation: Check if input files exist
        dataPath = [config.baseDirNifti, subjectID, filesep, config.subDirNifti];
        boldFile = [dataPath, subjectID, config.niftiNameEndingWOZip];
        
        if ~exist(boldFile, 'file')
            error('BOLD data not found: %s', boldFile);
        end
        
        % Check if design files exist
        designFiles = {'Explicit', 'Implicit', 'Gender' , 'Instruction'};
        for i = 1:length(designFiles)
            designFile = [config.designparameterDir, designFiles{i}, '_', subjectID, '_ses-1.txt'];
            if ~exist(designFile, 'file')
                error('Design file not found: %s', designFile);
            end
        end
        
        % Create results directory if it doesn't exist
        resultDir = [config.resultsBaseDirName, subjectID];
        if ~exist(resultDir, 'dir')
            mkdir(resultDir);
            fprintf('Created results directory: %s\n', resultDir);
        end
        
        % Setup paths for processing
        dataPathResultsDir = {resultDir};
        SPMmatFileWithDataPath = {[resultDir, config.SPMmatFile]};
        
        % Begin SPM batch configuration
        % Specify Model
        matlabbatch{1}.spm.stats.fmri_spec.dir = dataPathResultsDir;
        matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
        matlabbatch{1}.spm.stats.fmri_spec.timing.RT = config.TR;
        matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = config.microtime;
        matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = config.microtime0;
        
        % Load scans
        matlabbatch{1}.spm.stats.fmri_spec.sess.scans = cellstr(spm_select('expand', boldFile));
        fprintf('Loaded %d scans\n', length(matlabbatch{1}.spm.stats.fmri_spec.sess.scans));
        
        % Load the timing files for each condition
        fprintf('Loading design parameters...\n');

        % model consists of 4 coditions:
        % 1 = Explicit, 2 = Implicit, 3 = Gender, 4 = Instruction (regressor of non-interest)
        
        % Explicit condition
        data_exp = load([config.designparameterDir, 'Explicit_', subjectID, '_ses-1.txt']);
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).name = 'Explicit';
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).onset = data_exp(:,1);
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).duration = data_exp(:,2);
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).tmod = 0;
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).pmod = struct('name', {}, 'param', {}, 'poly', {});
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).orth = 1;
        
        % Implicit condition
        data_imp = load([config.designparameterDir, 'Implicit_', subjectID, '_ses-1.txt']);
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).name = 'Implicit';
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).onset = data_imp(:,1);
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).duration = data_imp(:,2);
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).tmod = 0;
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).pmod = struct('name', {}, 'param', {}, 'poly', {});
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).orth = 1;
        
        % Gender condition
        data_gen = load([config.designparameterDir, 'Gender_', subjectID, '_ses-1.txt']);
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(3).name = 'Gender';
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(3).onset = data_gen(:,1);
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(3).duration = data_gen(:,2);
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(3).tmod = 0;
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(3).pmod = struct('name', {}, 'param', {}, 'poly', {});
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(3).orth = 1;
        
        % Instruction condition (regressor of non-interest)
        data_ins = load([config.designparameterDir, 'Instruction_', subjectID, '_ses-1.txt']);
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(4).name = 'Instruction';
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(4).onset = data_ins(:,1);
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(4).duration = data_ins(:,2);
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(4).tmod = 0;
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(4).pmod = struct('name', {}, 'param', {}, 'poly', {});
        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(4).orth = 1;

        % Additional model parameters
        matlabbatch{1}.spm.stats.fmri_spec.sess.multi_reg = {''};
        matlabbatch{1}.spm.stats.fmri_spec.sess.hpf = config.hpf;
        matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
        matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
        matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
        matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
        matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0.8;
        matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
        matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';
        
        % Estimate Model
        matlabbatch{2}.spm.stats.fmri_est.spmmat = SPMmatFileWithDataPath;
        matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
        matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
        
        % Specify Contrasts
        matlabbatch{3}.spm.stats.con.spmmat = SPMmatFileWithDataPath;
        
        % Define all contrasts
        contrasts = {
        {'Ex>Ge', [1 -1 0 0]},       % 1: Explicit > Gender
        {'Ge>Ex', [-1 1 0 0]},       % 2: Gender > Explicit
        {'Ex>Im', [1 0 -1 0]},       % 3: Explicit > Implicit
        {'Im>Ex', [-1 0 1 0]},       % 4: Implicit > Explicit
        {'Im>Ge', [0 -1 1 0]},       % 5: Implicit > Gender
        {'Ge>Im', [0 1 -1 0]},       % 6: Gender > Implicit
        {'Ex', [1 0 0 0]},           % 7: Explicit
        {'Ge', [0 1 0 0]},           % 8: Gender
        {'Im', [0 0 1 0]}            % 9: Implicit
    };
        
        % Add all contrasts to batch
        for i = 1:length(contrasts)
            matlabbatch{3}.spm.stats.con.consess{i}.tcon.name = contrasts{i}{1};
            matlabbatch{3}.spm.stats.con.consess{i}.tcon.weights = contrasts{i}{2};
            matlabbatch{3}.spm.stats.con.consess{i}.tcon.sessrep = 'none';
        end
        matlabbatch{3}.spm.stats.con.delete = 0;
        
        % Run the batch
        fprintf('Running SPM batch for subject %s...\n', subjectID);
        spm_jobman('run', matlabbatch);
        
        % Verify results exist
        if ~exist([resultDir, config.SPMmatFile], 'file')
            warning('SPM.mat file not created for %s', subjectID);
        end
        
        % Record processing time
        sumFFXEstimationDuration = toc(sumFFXEstimationDurationTemp);
        processingTimes(noOfSubj) = sumFFXEstimationDuration;
        
        % Log success
        fprintf('Successfully processed %s in %0.1f minutes\n', subjectID, sumFFXEstimationDuration/60);
        
        % Update progress log
        fid = fopen(config.progressLogFile, 'a');
        fprintf(fid, 'Subject %s: SUCCESS - Processing time: %0.1f minutes\n', subjectID, sumFFXEstimationDuration/60);
        fclose(fid);
        
    catch ME
        % Handle errors
        errorMessage = sprintf('ERROR with subject %s: %s\n%s\n', ...
            subjectID, ME.message, getReport(ME, 'extended'));
        
        % Print to console
        fprintf('\n%s\n', errorMessage);
        
        % Log to error file
        fid = fopen(config.errorLogFile, 'a');
        fprintf(fid, '\n%s\n', errorMessage);
        fclose(fid);
        
        % Also log to progress file
        fid = fopen(config.progressLogFile, 'a');
        fprintf(fid, 'Subject %s: FAILED - %s\n', subjectID, ME.message);
        fclose(fid);
    end
    
    % Update overall progress
    fprintf('Progress: %d/%d subjects completed (%0.1f%%)\n', ...
        noOfSubj, totalSubjects, (noOfSubj/totalSubjects)*100);
end

%% Finalize processing
totalDuration = toc(totalStartTime);
successCount = sum(processingTimes > 0);
failCount = totalSubjects - successCount;

% Calculate statistics
avgTime = mean(processingTimes(processingTimes > 0)) / 60; % in minutes
totalTimeMin = totalDuration / 60; % in minutes

% Print summary
fprintf('\n=== Processing Complete ===\n');
fprintf('Total subjects: %d\n', totalSubjects);
fprintf('Successfully processed: %d\n', successCount);
fprintf('Failed: %d\n', failCount);
fprintf('Average processing time per subject: %0.1f minutes\n', avgTime);
fprintf('Total processing time: %0.1f minutes (%0.1f hours)\n', totalTimeMin, totalTimeMin/60);

% Log summary
fid = fopen(config.progressLogFile, 'a');
fprintf(fid, '\n=== Processing completed at %s ===\n', datestr(now));
fprintf(fid, 'Total subjects: %d\n', totalSubjects);
fprintf(fid, 'Successfully processed: %d\n', successCount);
fprintf(fid, 'Failed: %d\n', failCount);
fprintf(fid, 'Average processing time per subject: %0.1f minutes\n', avgTime);
fprintf(fid, 'Total processing time: %0.1f minutes (%0.1f hours)\n', totalTimeMin, totalTimeMin/60);
fclose(fid);

% Save batch for reference
% Uncomment if you want to save the last batch configuration
% save('last_batch.mat', 'matlabbatch');