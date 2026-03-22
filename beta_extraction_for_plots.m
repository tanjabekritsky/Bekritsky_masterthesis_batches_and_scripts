%% ROI extraction for beta plots

clear all; close all; clc;

%% ===== EINSTELLUNGEN =====

% path to first level analysis FFX
base_path = '';

% Output-path
output_dir = '';

% subject IDs
faster_subs = {''};

scott_subs = {''};

tau_subs = {''};

% ROI-Definitionen
rois = struct();

% IMP> Kontrast ROIs
rois(1).name = 'IMP_Cluster1_R_WhiteMatter';
rois(1).peak = [32, -12, 38];
rois(1).radius = 8;
rois(1).contrast = 'con_0009'; % IMP>

rois(2).name = 'IMP_Cluster2_R_WhiteMatter';
rois(2).peak = [22, 18, 36];
rois(2).radius = 8;
rois(2).contrast = 'con_0009';

rois(3).name = 'IMP_Cluster3_L_Precentral';
rois(3).peak = [-34, -24, 50];
rois(3).radius = 8;
rois(3).contrast = 'con_0009';

% EXP>NEU Kontrast ROI
rois(4).name = 'EXP_Cluster1_L_WhiteMatter';
rois(4).peak = [-34, 0, 28];
rois(4).radius = 8;
rois(4).contrast = 'con_0001'; % EXP>NEU

%% ===== SETUP =====

fprintf('\n%s\n', repmat('=', 1, 70));
fprintf('ROBUSTE ROI-EXTRAKTION MIT ZWISCHENSPEICHERUNG\n');
fprintf('%s\n\n', repmat('=', 1, 70));

% Erstelle Output-Verzeichnis
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% Kombiniere alle Probanden
all_subjects = [faster_subs, scott_subs, tau_subs];
groups = [repmat({'Faster'}, 1, length(faster_subs)), ...
          repmat({'Scott'}, 1, length(scott_subs)), ...
          repmat({'TAU'}, 1, length(tau_subs))];

n_subjects = length(all_subjects);

fprintf('Anzahl Probanden: %d (Faster: %d, Scott: %d, TAU: %d)\n\n', ...
        n_subjects, length(faster_subs), length(scott_subs), length(tau_subs));

%% ===== ROI-MASKEN ERSTELLEN (nur wenn nicht vorhanden) =====

fprintf('Prüfe ROI-Masken...\n');

% Lade Beispiel-Image für Dimensionen
example_img = fullfile(base_path, 'ses-1', all_subjects{1}, [rois(1).contrast '.nii']);

if ~exist(example_img, 'file')
    error('Kann Beispiel-Image nicht finden: %s', example_img);
end

V_example = spm_vol(example_img);

for r = 1:length(rois)
    mask_file = fullfile(output_dir, [rois(r).name '_mask.nii']);
    
    % Prüfe ob Maske schon existiert
    if exist(mask_file, 'file')
        fprintf('  ✓ ROI %d/%d: %s (existiert bereits)\n', r, length(rois), rois(r).name);
        V_mask = spm_vol(mask_file);
        rois(r).mask = spm_read_vols(V_mask);
        rois(r).mask_file = mask_file;
    else
        fprintf('  → ROI %d/%d: %s (erstelle neu)\n', r, length(rois), rois(r).name);
        
        % Erstelle Maske
        mask = zeros(V_example.dim);
        [X, Y, Z] = ndgrid(1:V_example.dim(1), 1:V_example.dim(2), 1:V_example.dim(3));
        vox_coords = [X(:), Y(:), Z(:), ones(numel(X), 1)]';
        mni_coords = V_example.mat * vox_coords;
        distances = sqrt(sum((mni_coords(1:3,:) - rois(r).peak').^2, 1));
        mask(distances <= rois(r).radius) = 1;
        
        % Speichere Maske
        V_mask = V_example;
        V_mask.fname = mask_file;
        V_mask.dt = [2 0];
        spm_write_vol(V_mask, mask);
        
        rois(r).mask = mask;
        rois(r).mask_file = mask_file;
        
        fprintf('    -> %d Voxel\n', sum(mask(:)));
    end
end

fprintf('\n');

%% ===== EXTRAHIERE WERTE FÜR JEDE ROI (mit Zwischenspeicherung) =====

for r = 1:length(rois)
    
    csv_file = fullfile(output_dir, [rois(r).name '_beta_values.csv']);
    
    % PRÜFE OB CSV SCHON EXISTIERT
    if exist(csv_file, 'file')
        fprintf('%s\n', repmat('=', 1, 70));
        fprintf('✓ ROI %d/%d: %s - EXISTIERT BEREITS, ÜBERSPRINGE!\n', r, length(rois), rois(r).name);
        fprintf('%s\n\n', repmat('=', 1, 70));
        continue; % SPRINGE ZUR NÄCHSTEN ROI!
    end
    
    fprintf('%s\n', repmat('=', 1, 70));
    fprintf('ROI %d/%d: %s\n', r, length(rois), rois(r).name);
    fprintf('Kontrast: %s\n', rois(r).contrast);
    fprintf('%s\n\n', repmat('=', 1, 70));
    
    % Bestimme Spaltenname basierend auf Kontrast
    if strcmp(rois(r).contrast, 'con_0009')
        col_prefix = 'IMP';
    else
        col_prefix = 'EXPNEU';
    end
    
    % Initialisiere Daten-Matrix
    data_matrix = cell(n_subjects, 5); % SubjectID, Group, pre, post, diff
    
    % Timer starten
    tic;
    
    % Für jeden Probanden
    for s = 1:n_subjects
        sub_id = all_subjects{s};
        
        try
            % Pfade zu Kontrast-Images
            con_pre = fullfile(base_path, 'ses-1', sub_id, [rois(r).contrast '.nii']);
            con_post = fullfile(base_path, 'ses-2', [sub_id '_ses-2'], [rois(r).contrast '.nii']);
            
            % Prüfe Existenz
            if ~exist(con_pre, 'file')
                warning('Datei nicht gefunden: %s', con_pre);
                data_matrix(s,:) = {sub_id, groups{s}, NaN, NaN, NaN};
                continue;
            end
            if ~exist(con_post, 'file')
                warning('Datei nicht gefunden: %s', con_post);
                data_matrix(s,:) = {sub_id, groups{s}, NaN, NaN, NaN};
                continue;
            end
            
            % Lade Images
            V_pre = spm_vol(con_pre);
            V_post = spm_vol(con_post);
            img_pre = spm_read_vols(V_pre);
            img_post = spm_read_vols(V_post);
            
            % Extrahiere ROI-Werte
            mask_idx = find(rois(r).mask > 0);
            val_pre = mean(img_pre(mask_idx), 'omitnan');
            val_post = mean(img_post(mask_idx), 'omitnan');
            val_diff = val_post - val_pre;
            
            % Speichere in Matrix
            data_matrix(s,:) = {sub_id, groups{s}, val_pre, val_post, val_diff};
            
        catch ME
            warning('Fehler bei Subject %s: %s', sub_id, ME.message);
            data_matrix(s,:) = {sub_id, groups{s}, NaN, NaN, NaN};
        end
        
        % Progress Update (alle 5 Probanden)
        if mod(s, 5) == 0
            elapsed = toc;
            remaining = (elapsed / s) * (n_subjects - s);
            fprintf('  Progress: %d/%d (noch ca. %.1f Min)\n', s, n_subjects, remaining/60);
        end
    end
    
    fprintf('  ✓ Alle %d Probanden verarbeitet!\n\n', n_subjects);
    
    % SPEICHERE CSV SOFORT!
    T = cell2table(data_matrix, ...
        'VariableNames', {'SubjectID', 'Group', [col_prefix '_pre'], [col_prefix '_post'], [col_prefix '_diff']});
    
    writetable(T, csv_file);
    
    fprintf('  💾 GESPEICHERT: %s\n', [rois(r).name '_beta_values.csv']);
    fprintf('  ⏱  Dauer: %.1f Minuten\n\n', toc/60);
    
    % Auch als MAT speichern (Backup)
    mat_file = fullfile(output_dir, [rois(r).name '_backup.mat']);
    save(mat_file, 'data_matrix', 'groups', 'all_subjects');
    
end

%% ===== ZUSAMMENFASSUNG =====

fprintf('%s\n', repmat('=', 1, 70));
fprintf('✅ FERTIG! ALLE ROIs VERARBEITET!\n');
fprintf('%s\n\n', repmat('=', 1, 70));

fprintf('Erstellte Dateien im Ordner:\n%s\n\n', output_dir);

% Liste alle CSV-Dateien auf
csv_files = dir(fullfile(output_dir, '*_beta_values.csv'));
for i = 1:length(csv_files)
    fprintf('  ✓ %s\n', csv_files(i).name);
end

fprintf('\n%s\n', repmat('=', 1, 70));
fprintf('NÄCHSTER SCHRITT: R-Permutationsanalyse!\n');
fprintf('%s\n\n', repmat('=', 1, 70));

% Speichere Workspace
save(fullfile(output_dir, 'extraction_complete.mat'));
fprintf('💾 Workspace gespeichert: extraction_complete.mat\n\n');

%% ===== HILFSFUNKTION: QUICK CHECK =====
% Zeige Übersicht der extrahierten Daten

fprintf('Schnell-Check der Daten:\n\n');
for i = 1:length(csv_files)
    csv_path = fullfile(output_dir, csv_files(i).name);
    T = readtable(csv_path);
    fprintf('  %s:\n', csv_files(i).name);
    fprintf('    Probanden: %d\n', height(T));
    fprintf('    Gruppen: %s\n', strjoin(unique(T.Group), ', '));
    
    % Check für NaNs
    diff_col = T.Properties.VariableNames{end}; % letzte Spalte ist _diff
    n_missing = sum(isnan(T.(diff_col)));
    if n_missing > 0
        fprintf('    ⚠️  WARNUNG: %d Probanden mit fehlenden Werten!\n', n_missing);
    else
        fprintf('    ✓ Alle Werte vorhanden!\n');
    end
    fprintf('\n');
end

fprintf('🎉 ALLES FERTIG! Du kannst jetzt mit R weitermachen!\n\n');
