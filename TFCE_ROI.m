%-----------------------------------------------------------------------
% author: s-kline
% takes regular SPM second level models and runs a TFCE analysis on them using Christian Gasers toolbox
% multiple ROIs can be specified in a directory
% you can replicate your parametric ROI analysis with non-parametric TFCE statistics without extra work! 
%-----------------------------------------------------------------------

%run TFCE job with ROI masks and save results

clear all
pipeline_path = 'D:\0188ok\0188ok_picpercept\SPM8batch_Tools_AB_beta\zusatztools\TFCE_ROI_pipeline'; % Pfad der ROI Batchpipeline --> Hier ändern

perms = 5000; %number of permutations, 5000 is default
wholebrain = 1; %1 if you want wholebrain results too, 0 if not
alpha = 0.05; %only TFCE values with p below this are reported 

clusterthr = 0; %cluster-forming threshold used for T-tests 

%correction = 'FWE'; %for TFCE
%correction = 'FDR';
%correction = 'none';

mat_directories = {
'D:\0188ok\0188ok_picpercept\slevel\Testosteron\MultReg_HTestoC_negGTneu_No26\'
'D:\0188ok\0188ok_picpercept\slevel\Testosteron\MultReg_HTestoC_neuGTpos_No26\'
%'D:\0188ok\0188ok_picpercept\slevel\Testosteron\MultReg_HTestoC_negGTneu\'
%'D:\0188ok\0188ok_picpercept\slevel\Testosteron\MultReg_HTestoC_neuGTpos\'
%'D:\0188ok\0188ok_picpercept\slevel\Testosteron\MultReg_HTestoC_negposGTneu\'
%'D:\0188ok\0188ok_picpercept\slevel\Testosteron\MultReg_HTestoC_negGTpos\'
%'D:\0188ok\0188ok_picpercept\slevel\Testosteron\MultReg_HTestoC_neuGTsex\'
    };

%%

job_directory = strcat(pipeline_path, '\running\');
output_roi_directory = strcat(pipeline_path, '\OUTPUT\');
masks_resultsfile_suffix = 'Ergebnis_TAB.txt';

mask_directory = strcat(pipeline_path, '\Masken\');
nii_masks = find_filenames(mask_directory, '*.nii');
img_masks = find_filenames(mask_directory, '*.img');
masks = union(nii_masks, img_masks); % die ganzen masklisten etc müssen außerhalb der loop weil sonst für jeden Kontrast immer doppelt resliced wird
n_masks = length(masks); % is 0 if no mask files are in the dir


%%
for mat = 1:length(mat_directories)
    spmmat_directory = mat_directories{mat}; % Ordner, in dem die Ergebnisse in Form der SPM.mat liegen
    dir_breaks = strfind(spmmat_directory, '\');
    titel = strcat('0188ok-',spmmat_directory(dir_breaks(length(dir_breaks)-1)+1:dir_breaks(length(dir_breaks))-1)); % Titel der Studie, der später als Dateiname der Ganzkopf-Ergebnisse auftaucht.

    [con_nr, con_title] = xlsread(strcat(spmmat_directory, '\Kontraste.xlsx'));
    

    n_jobs = length(con_nr);
 
    %% Ausführung beginnt 
    
    wholebrain_results_TFCE = cell(1, n_jobs);
    wholebrain_results_T = cell(1, n_jobs);
    title_contrast_array_TFCE = cell(1, n_jobs);
    title_contrast_array_T = cell(1, n_jobs);

    addpath(pipeline_path)

    spm fmri

    for j = 1:n_jobs % contrasts loop, two iterations for most analyses (neg and pos corr)
   
        if wholebrain == 1;
            
            % batch: estimate wholebrain TFCE model 
            matlabbatch{1}.spm.tools.tfce_estimate.spmmat = {strcat(spmmat_directory,'SPM.mat')};
            matlabbatch{1}.spm.tools.tfce_estimate.mask(1) = {strcat(spmmat_directory,'mask.nii')};
            matlabbatch{1}.spm.tools.tfce_estimate.conspec.titlestr = con_title{j};
            matlabbatch{1}.spm.tools.tfce_estimate.conspec.contrasts = con_nr(j);
            matlabbatch{1}.spm.tools.tfce_estimate.conspec.n_perm = perms;  
            matlabbatch{1}.spm.tools.tfce_estimate.nuisance_method = 2;
            matlabbatch{1}.spm.tools.tfce_estimate.tbss = 0;
            matlabbatch{1}.spm.tools.tfce_estimate.E_weight = 0.5;
            matlabbatch{1}.spm.tools.tfce_estimate.singlethreaded = 0;

            % save wholebrain TFCE batch and run
            save(strcat(job_directory,'TFCE_',con_title{j},'.mat'),'matlabbatch');                     
            spm_jobman('serial',matlabbatch);

            %access TFCE results and store in cell array
            SPM = load(strcat(spmmat_directory,'SPM.mat'));
            
            %get both TFCE and T statistic out of the SPM and store
            for s = 1:2
                if s == 1;
                    statstype = 'TFCE';
                    p = 1 - alpha;
                    correction = 'FWE';
                    title_contrast = strcat('nonparam_',statstype,con_title{j});
                elseif s == 2;
                    statstype = 'T';
                    p = 0;
                    correction = 'FWE';
                    title_contrast = strcat('nonparam_',statstype,con_title{j});

                end;
                xSPM.swd = spmmat_directory;
                xSPM.title = title_contrast; %strcat('nonparam_',statstype,con_title{j});
                xSPM.Ic = j; %indices of contrast
                xSPM.pm = []; %p-value for masking (uncorrected)
                xSPM.Ex = []; %flag for exclusive or inclusive masking
                
                %queried by the results function to skip user input
                xSPM.u = p;        % 1 - alpha for TFCE, 1 for T
                xSPM.thresDesc = correction; % type of correction (FWE, FDR, none)
                xSPM.stat = statstype;  % type of statistic (T or TFCE)    
                xSPM.inv = 0;           % invert the contrast (0 or 1)
                xSPM.k = clusterthr;    % cluster-forming threshold for T

                [hReg,xSPM] = cg_tfce_results('Setup',xSPM);
                
                if statstype == 'TFCE';
                    title_contrast_array_TFCE{j}{1} = title_contrast;
                    wholebrain_results_TFCE{j}{1} = cg_tfce_list('List',xSPM,hReg);
                    titel = strcat('0188ok-',title_contrast);
                    write_roibatch_results(strcat(output_roi_directory, 'wholebrain\'), title_contrast_array_TFCE{j}, titel, wholebrain_results_TFCE{j});
                
                elseif statstype == 'T'
                    %title_contrast = xSPM.title
                    title_contrast_array_T{j}{1} = title_contrast;
                    wholebrain_results_T{j}{1} = cg_tfce_list('List',xSPM,hReg);
                    titel = strcat('0188ok-',title_contrast);
                    write_roibatch_results(strcat(output_roi_directory, 'wholebrain\'), title_contrast_array_T{j}, titel, wholebrain_results_T{j});
                end
                
             
                clear title_contrast
                
            end; %saveloop runs two times for TFCE and T
            s = 1;
        
        end % wholebrain analysis
        clear matlabbatch
        clear xSPM
        
        try % if mask dir is not empty
            mask_results_TFCE{j} = cell(1, n_masks);
            mask_results_T{j} = cell(1, n_masks);
			
            for r = 1:n_masks % loop through masks
                try
                    mask_file = strcat(mask_directory, masks{r}); %specify mask file
                    disp(strcat('Now running analysis with mask: ', masks{r}))

                    % batch: reslice mask to use in TFCE estimation
                    matlabbatch{1}.spm.spatial.realign.write.data = {
                        strcat(spmmat_directory, 'mask.nii,1')
                        mask_file
                        };
                    matlabbatch{1}.spm.spatial.realign.write.roptions.which = [1 0];
                    matlabbatch{1}.spm.spatial.realign.write.roptions.interp = 4;
                    matlabbatch{1}.spm.spatial.realign.write.roptions.wrap = [0 0 0];
                    matlabbatch{1}.spm.spatial.realign.write.roptions.mask = 1;
                    matlabbatch{1}.spm.spatial.realign.write.roptions.prefix = 'r';

                    % batch: estimate ROI TFCE model 
                    matlabbatch{2}.spm.tools.tfce_estimate.spmmat = {strcat(spmmat_directory,'SPM.mat')};
                    matlabbatch{2}.spm.tools.tfce_estimate.mask(1) = cfg_dep('Realign: Reslice: Resliced Images', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','rfiles'));
                    matlabbatch{2}.spm.tools.tfce_estimate.conspec.titlestr = con_title{j};
                    matlabbatch{2}.spm.tools.tfce_estimate.conspec.contrasts = con_nr(j);
                    matlabbatch{2}.spm.tools.tfce_estimate.conspec.n_perm = perms;  
                    matlabbatch{2}.spm.tools.tfce_estimate.nuisance_method = 2;
                    matlabbatch{2}.spm.tools.tfce_estimate.tbss = 0;
                    matlabbatch{2}.spm.tools.tfce_estimate.E_weight = 0.5;
                    matlabbatch{2}.spm.tools.tfce_estimate.singlethreaded = 0;

                    % save masked TFCE batch and run
                    save(strcat(job_directory,'TFCE_',con_title{j},'_',masks{r},'.mat'),'matlabbatch');                     
                    spm_jobman('serial',matlabbatch);

                    %access TFCE results and store in cell array
                    SPM = load(strcat(spmmat_directory,'SPM.mat'));
                    
                    %get both TFCE and T statistic out of the SPM and store
                    for s = 1:2 
                        if s == 1;
                            statstype = 'TFCE';
                            p = 1 - alpha
                            correction = 'FWE'
                            title_contrast = strcat('nonparam_',statstype,con_title{j});
                        elseif s == 2;
                            statstype = 'T';
                            p = 0
                            correction = 'FWE'
                            title_contrast = strcat('nonparam_',statstype,con_title{j});
                            %add extent threshold
                        end;
                        xSPM.swd = spmmat_directory;
                        xSPM.title = title_contrast;
                        xSPM.Ic = j; %indices of contrast
                        xSPM.pm = []; %p-value for masking (uncorrected)
                        xSPM.Ex = []; %flag for exclusive or inclusive masking
                        %queried by the results function to skip userinput
                        xSPM.u = p;        % 1-p value
                        xSPM.thresDesc = correction; % type of correction (FWE, FDR, none)
                        xSPM.stat = statstype;  % type of statistic (T or TFCE)    
                        xSPM.inv = 0;           % invert the contrast (0 or 1)
                        xSPM.k = clusterthr;    % cluster-forming threshold for T

                        %title_contrast = xSPM.title;
                        [hReg,xSPM] = cg_tfce_results('Setup',xSPM);
                        
                        if statstype == 'TFCE';
                            mask_results_TFCE{j}{r} = cg_tfce_list('List',xSPM,hReg); %save results in mask array
                            mask_results_TFCE{j}{r}.mask = masks{r};
                            TFCE_title = title_contrast;
                            
                        elseif statstype == 'T';
                            mask_results_T{j}{r} = cg_tfce_list('List',xSPM,hReg); %save results in mask array
                            mask_results_T{j}{r}.mask = masks{r};
                            T_title = title_contrast;
                            
                        end;
                        clear title_contrast
                    end; %saveloop
                    s = 1;
                
                catch exception2
                  disp(exception2)
                  disp(masks{r})
                  %cd(old_cd)
                end
                clear matlabbatch
            end
            write_roibatch_results(output_roi_directory, TFCE_title, 1, mask_results_TFCE{j});
            write_roibatch_results(output_roi_directory, T_title, 1, mask_results_T{j});

            
            clear SPM hReg xSPM
            catch exception1
                disp(exception1)
                disp(con_title{j})
        end
    end
end     
