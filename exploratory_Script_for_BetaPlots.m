%% ===== BETA-extraction for plot =====
clear all;
close all;

%% === SETUP ===
% path to the first level folder
base_dir = '';

% Subject IDs
subjects_FASTER = {''};

subjects_SCOTT = {''};

subjects_TAU = {''};

% depict all subjects in the plot
all_subjects = [subjects_FASTER, subjects_SCOTT, subjects_TAU];
n_subjects = length(all_subjects);

% group assignment (1=FASTER, 2=SCOTT, 3=TAU)
groups = [ones(1, length(subjects_FASTER)), ...
          2*ones(1, length(subjects_SCOTT)), ...
          3*ones(1, length(subjects_TAU))];

% Cluster-Informationen
clusters = struct();
clusters(1).name = 'IMP_Cluster1';
clusters(1).coord = [32, -12, 38];
clusters(1).contrast_num = 9; % con_0009 = IMP>

clusters(2).name = 'EXPNEU_Cluster1';
clusters(2).coord = [-34, 0, 28];
clusters(2).contrast_num = 1; % con_0001 = EXP>NEU

sphere_radius = 6; % 6mm Radius

%% === BETA-extraction (directly from con files) ===
fprintf('\n=== Starte Beta-Extraktion ===\n');

% Ergebnis-Matrix initialisieren
beta_values = struct();

for c = 1:length(clusters)
    beta_values(c).T0 = nan(n_subjects, 1);
    beta_values(c).T1 = nan(n_subjects, 1);
    
    fprintf('\n=== Cluster %d: %s ===\n', c, clusters(c).name);
    fprintf('Koordinaten: [%d, %d, %d]\n', clusters(c).coord);
    
    for s = 1:n_subjects
        subj_id = all_subjects{s};
        
        % paths to Contrast-Images
        con_file_T0 = fullfile(base_dir, 'ses-1', subj_id, ...
                               sprintf('con_%04d.nii', clusters(c).contrast_num));
        con_file_T1 = fullfile(base_dir, 'ses-2', [subj_id '_ses-2'], ...
                               sprintf('con_%04d.nii', clusters(c).contrast_num));
        
        % test whether files exist
        if ~exist(con_file_T0, 'file')
            fprintf('  FEHLT: %s T0\n', subj_id);
            continue;
        end
        if ~exist(con_file_T1, 'file')
            fprintf('  FEHLT: %s T1\n', subj_id);
            continue;
        end
        
        try
            % read T0
            V1 = spm_vol(con_file_T0);
            [Y1, XYZ1] = spm_read_vols(V1);
            
            % MNI-Koordinaten in Voxel-Koordinaten umwandeln
            vox_coord = inv(V1.mat) * [clusters(c).coord'; 1];
            vox_coord = round(vox_coord(1:3));
            
            % Sphere Mask erstellen (im Voxel-Raum)
            [X, Y, Z] = ndgrid(1:V1.dim(1), 1:V1.dim(2), 1:V1.dim(3));
            dist = sqrt((X - vox_coord(1)).^2 + ...
                       (Y - vox_coord(2)).^2 + ...
                       (Z - vox_coord(3)).^2);
            
            % Radius in Voxeln (annähern: 1 Voxel ≈ 2mm, also 6mm ≈ 3 Voxel)
            voxel_radius = sphere_radius / 2;
            mask = dist <= voxel_radius;
            
            % extract beta value (average in Sphere)
            beta_values(c).T0(s) = nanmean(Y1(mask));
            
            % read T1 
            V2 = spm_vol(con_file_T1);
            [Y2, XYZ2] = spm_read_vols(V2);
            
            % Gleiche Mask für T1
            beta_values(c).T1(s) = nanmean(Y2(mask));
            
            fprintf('  %s: T0=%.3f, T1=%.3f\n', subj_id, ...
                    beta_values(c).T0(s), beta_values(c).T1(s));
            
        catch ME
            fprintf('  FEHLER bei %s: %s\n', subj_id, ME.message);
        end
    end
end

fprintf('\n=== extraction done! ===\n');

%% === PLOTTING ===
group_names = {'FASTER', 'SCOTT', 'TAU'};
group_colors = [0 0.4470 0.7410;        % blue
                0.8500 0.3250 0.0980;    % orange
                0.9290 0.6940 0.1250];   % yellow

for c = 1:length(clusters)
    figure('Position', [100, 100, 800, 600]);
    hold on;
    
    % for each group 
    for g = 1:3
        group_idx = find(groups == g);
        
        % individual lines (thin, transparent)
        for idx = group_idx
            if ~isnan(beta_values(c).T0(idx)) && ~isnan(beta_values(c).T1(idx))
                plot([1, 2], [beta_values(c).T0(idx), beta_values(c).T1(idx)], ...
                     '-', 'Color', [group_colors(g,:), 0.3], 'LineWidth', 1);
            end
        end
        
        % group average (thick)
        mean_T0 = nanmean(beta_values(c).T0(group_idx));
        mean_T1 = nanmean(beta_values(c).T1(group_idx));
        se_T0 = nanstd(beta_values(c).T0(group_idx)) / sqrt(sum(~isnan(beta_values(c).T0(group_idx))));
        se_T1 = nanstd(beta_values(c).T1(group_idx)) / sqrt(sum(~isnan(beta_values(c).T1(group_idx))));
        
        plot([1, 2], [mean_T0, mean_T1], '-o', ...
             'Color', group_colors(g,:), 'LineWidth', 3, ...
             'MarkerSize', 10, 'MarkerFaceColor', group_colors(g,:), ...
             'DisplayName', sprintf('%s (n=%d)', group_names{g}, length(group_idx)));
    end
    
    % Layout
    xlim([0.8, 2.2]);
    xticks([1, 2]);
    xticklabels({'Pre (T0)', 'Post (T1)'});
    ylabel('Beta-value (Contrast Estimate)', 'FontSize', 12);
    title(sprintf('%s\n[%d, %d, %d], r=%dmm', ...
          strrep(clusters(c).name, '_', ' '), ...
          clusters(c).coord, sphere_radius), 'FontSize', 14);
    legend('Location', 'best', 'FontSize', 11);
    grid on;
    set(gca, 'FontSize', 11);
    
    % Speichern
    saveas(gcf, sprintf('BetaPlot_%s.png', clusters(c).name));
    fprintf('Plot saved: BetaPlot_%s.png\n', clusters(c).name);
end

fprintf('\n=== Done! Plots saved! ===\n');