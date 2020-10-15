function [] = write_roibatch_results(OUTPUT_ROI_TAB_pfad, Titel_Kontrast, maske, all_results)
% WRITE_ROIBATCH_RESULTS Schreibt eine Tabelle mit Ergebnissen aller
% Masken.

% OUTPUT_ROI_TAB_pfad = output_roi_directory;
% Titel_Kontrast = title_contrast;
% maske = 1
% all_results = mask_results{1}

if maske ~= 1
    TabDat_maske_Datei=strcat(maske,'_Ergebnis_TAB.txt'); %wenn maske nicht 1 ist, wird da der titel o.ä. eingesetzt
else
    TabDat_maske_Datei=strcat(Titel_Kontrast,'_Ergebnis_TAB.txt');
end
    

n_data = length(all_results);
groessedertabelleinspalten = 14;
TABELLE_alle_MASKEN_ein_KONTRAST={};

OUTPUT_ROI_TAB_Datei=strcat(OUTPUT_ROI_TAB_pfad, TabDat_maske_Datei);

for m = 1:n_data 
    Gesamttab={};
    TabDat_maske = all_results{m}; %m-ter Eintrag in results
    
    if maske == 1
        try
            Maskenfinddings = TabDat_maske.mask;
        catch
            warning(strcat('Fehler in Maske ', num2str(m)))
            pause
            continue
        end
    end
    
    if isempty(TabDat_maske.dat) && sum(maske) == 1
        Gesamttab_korrekt = cell(1,groessedertabelleinspalten);
        NICHTSMELDUNG = strcat('Fuer die Maske "',Maskenfinddings, '" im Kontrast "', Titel_Kontrast, '" konnten keine suprathreshold cluster gefunden werden' )
        Gesamttab_korrekt(1,1) = {NICHTSMELDUNG};
    elseif isempty(TabDat_maske.dat) && sum(maske) ~= 1
        Gesamttab_korrekt=cell(1,groessedertabelleinspalten);      %m-ter Eintrag in titel_kontrast (array)
        NICHTSMELDUNG = strcat('Fuer den Kontrast "', Titel_Kontrast{m}, '" konnten keine suprathreshold cluster gefunden werden' )
        Gesamttab_korrekt(1,1)={NICHTSMELDUNG};
    else
        % Ausgabe ab hier
        
        % OUTPUT_ROI TABELLE
        TabDat_maske.dat(1:end-1)
        Tab_datzeileXYZ = TabDat_maske.dat{end}';
        Gesamttab = cat(1,TabDat_maske.hdr,TabDat_maske.dat); %alle Inhalte
        Gesamttab_toprows=Gesamttab(1:2,1:end-1); % top rows ohne koordinaten
        Gesamttab_ohnexyz=cat(1,Gesamttab_toprows, Gesamttab(3:end,1:end-1)); %tabelle ohne koordinaten
        
        % KORREKTUR DER KOORDINATENAUSGABE

        groesse_TAB=size(Gesamttab_ohnexyz,1); %Koordinatenzeilen (ohne hdr)
        KORREKTUR_ding = cell(groesse_TAB,3); %cell, wo die einzelnen Koordinaten reinkommen
        
        KOORDINAT = Gesamttab(:,end);  %letzte Spalte des Gesamttab (hdr und Koordinaten)
        KORREKTUR_ding(1,:) = [{'X'},{'Y'},{'Z'}];
        %KORREKTUR_ding(3,:) = [{'mm'},{'mm'},{'mm'}];
        
        %for j = 4:length(KOORDINAT)
        for j = 2:length(KOORDINAT) %hdr-Zeile überspringen   
            
            exploder = KOORDINAT{j}';
            T_exploder = {exploder(:,1),exploder(:,2),exploder(:,3)};
            %T_exploder = {exploder(1,:),exploder(2,:),exploder(3,:)};
            KORREKTUR_ding(j,:) = T_exploder;
        end
        
        
        Gesamttab_korrekt = cat(2, Gesamttab_ohnexyz, KORREKTUR_ding);
        Gesamttab_korrekt(1,end-2:end) = {'MNI'};
        % INFOteil
        
        if maske == 1
            Gesamttab_korrekt(1,1) = {Titel_Kontrast};
            Gesamttab_korrekt(1,2) = {Maskenfinddings};
        else
            Gesamttab_korrekt(1,1) = {Titel_Kontrast{m}};
        end
        
        NICHTSMELDUNG = [];
    end
    
    
    % OPTISCHE VERBESSERUNG
    
    LEERZEILE = cell(1, size(Gesamttab_korrekt,2));
    
    % ZUSAMMENFUEGEN:
    
    TABELLE_alle_MASKEN_ein_KONTRAST = cat(1, TABELLE_alle_MASKEN_ein_KONTRAST, Gesamttab_korrekt, LEERZEILE);
    
    % PS-Datei speichern:
    

end


cellwriter(OUTPUT_ROI_TAB_Datei,TABELLE_alle_MASKEN_ein_KONTRAST)
OUTPUT_ROI_TAB_Datei_xls=strcat(OUTPUT_ROI_TAB_Datei(1:end-3),'xls');
xlswrite(OUTPUT_ROI_TAB_Datei_xls, TABELLE_alle_MASKEN_ein_KONTRAST)