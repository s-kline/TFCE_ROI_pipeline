function [filenames] = find_filenames(directory, fileid)
% FIND_FILENAMES erstellt Cell Array of Strings mit gesuchten Dateinamen
%
% Sucht im Verzeichnis directory nach Dateien, 
% die der "dir" Befehl bei der Eingabe 'strcat(directory, fileid)' ausgibt
% und gibt die Dateinamen als String-Array filenames zurück.
% 
% Beispielinput: 
% directory = '\\BION-S01\user\Kruse\0164sw\subjektive_daten'
% fileid = '\*.txt'
%
% Autor: onnO Kruse, 01.10.2013
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

name = strcat(directory, fileid);

files = dir(name);

filenames = cell(length(files), 1);

for dir_position = 1:length(files)
    filenames{dir_position} = files(dir_position).name;
end
