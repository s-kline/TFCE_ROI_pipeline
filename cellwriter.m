function []= cellwriter (Dateispez,Schreibcell)
% AB 05.02.08
% Diese Funktion schreibt cell-arrays (auch mit string und char gemischt) in Tab-Delimiter-Text-Dateien. 
% 
% Inputs :
% 1. Dateispez = Dateipfad mit -Name
% 2. Schreibcell  = der zu schreibende Cell-Array
% Field With & Precision kann man auch einstellen



fid = fopen(Dateispez, 'wt');

s=size(Schreibcell,2);
z=size(Schreibcell,1);


    for i=1:z
         for j = 1:s   
                sp=Schreibcell(i,j);
                 if j==s
                                if isnumeric(cell2mat(sp))==1
                                    spa=cell2mat(sp);
                                    fprintf(fid, '%d \n', spa);
%                                     VORSICHT--> SPEZIELLE EINSTELLUNG NUR
%                                     FUER DIESES PROGRAMM!!!
                                else
                                    spa=char(sp);
                                    fprintf(fid, '%s \n', spa)  ;
                                end        
                else
                 
                         if isnumeric(cell2mat(sp))==1
                        spa=cell2mat(sp);
                        fprintf(fid, '%g \t', spa);
                         

                        elseif isnumeric(cell2mat(sp))==0
                        spa=char(sp);
                        fprintf(fid, '%s \t', spa) ;

                      
                         end
                end 
        end

end
fclose(fid);
return