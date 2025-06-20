% pop_ADJUST_interface() - running ADJUST algorithm on EEG data
%
% Usage:
%   >> [ALLEEG,EEG,CURRENTSET,com] = pop_ADJUST_interface (
%   ALLEEG,EEG,CURRENTSET );
%
% Inputs and outputs:
%   ALLEEG     - array of EEG dataset structures
%   EEG        - current dataset structure or structure array
%   CURRENTSET - index(s) of the current EEG dataset(s) in ALLEEG
%
%
% Copyright (C) 2009-2014 Andrea Mognon (1) and Marco Buiatti (2), 
% (1) Center for Mind/Brain Sciences, University of Trento, Italy
% (2) INSERM U992 - Cognitive Neuroimaging Unit, Gif sur Yvette, France
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%
%
% REVISION HISTORY:
% 09/04/14: Filter/Gross Artifact Rejection/ICA have been removed (MB).


function [ALLEEG,EEG,CURRENTSET,com] = pop_ADJUST_interface ( ALLEEG,EEG,CURRENTSET )

% the command output is a hidden output that does not have to
% be described in the header

com = ''; % this initialization ensure that the function will return something
          % if the user press the cancel button            

% display help if not enough arguments
% ------------------------------------
if nargin < 1
	help pop_ADJUST_interface;
	return;
end;	

%% select operations to be done: display list

% messages={'Filter the data';'Remove Gross Artifacts and Perform ICA'; 'Run ADJUST'};
% 
% [Selection,ok] = listdlg('ListString',messages,'Name','ADJUST User Interface',...
%     'PromptString','Select operations to be done:',...
%     'OKString','Start Processing','SelectionMode','multiple','ListSize',[300 100]);

disp(' ')
disp (['Running ADJUST on dataset ' strrep(EEG.filename, '.set', '') '.set'])
promptstr    = { 'Enter Report file name (in quote): '};
inistr       = { '''report.txt''' };
result       = inputdlg2( promptstr, 'ADJUST User Interface', 1,  inistr, 'pop_ADJUST_interface');
if length( result ) == 0 return; end;

report   	 = eval( [ '[' result{1} ']' ] );

[EEG] = interface_ADJ (EEG,report);

% return the string command
% -------------------------
com = sprintf('pop_ADJUST_interface( %s );', EEG.filename);

return;
