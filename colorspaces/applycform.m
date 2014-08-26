function out=applycform(varargin)
% APPLYCFORM is used for color transformation
%  that has been defined by MAKECFORM
% 
% USAGE:
%   [cform] = makecform (...)
%   out = applycform (img, cform); 
%
% Remark: The format of variable cform is not compatible to the matlab version. 
%
% Requirement:
%    cvtColor.mex from mexopencv

% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3
% of the License, or (at your option) any later version.

% Copyright (C) 2014 by Alois Schloegl <alois.schloegl@ist.ac.at>	
% This is part of his mexopencv https://github.com/schloegl/mexopencv 


if nargin<2,
	error('missing input argument');

elseif nargin==2,
	img   = varargin{1};
	cform = varargin{2}; 
	if isfield(cform,'c_func') && strcmp(cform.c_func,'cvtColor')
		if exist('OCTAVE_VERSION','builtin') && (exist('cvtColor','file')==3),
			%%% Octave
			fun='cvtColor';
		elseif ~isempty(which('cv.cvtColor'))
			%%% Matlab
			fun='cv.cvtColor';
		else
			error('mexopencv:cvtColor is missing or not compiled!');
		end
	end

	try
		out = feval(fun, img, cform.cdata.cforms);
		return;
	catch
		error('color transformation using applycform failed')
	end; 

else
	error('unknown input argument')

end
