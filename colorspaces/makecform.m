function out=makecform(varargin)
% MAKECFORM is used to define the color transformation method
%  that can be applied in APPLYCFORM
% 
% USAGE:
%   [cform] = makecform(...)
%   applycform(img, cform); 
%
% Remark: The format of variable cform is not compatible to the matlab version. 
%
% Currently, the following conversion are supported 
%   makecform('srgb2lab')
%   makecform('lab2srgb')
%   makecform('srgb2xyz')
%   makecform('xyz2srgb')
%
% Requirement:
%    cvtColor.mex from mexopencv

% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 3
% of the License, or (at your option) any later version.

% Copyright (C) 2014 by Alois Schloegl <alois.schloegl@ist.ac.at>	
% This is part of mexopencv https://github.com/schloegl/mexopencv 


p=fileparts(fileparts(which(mfilename)));
if exist('cvtColor','file')~=3
	% without '-end' argument some octave core functions 
    % (e.g. imread, imwrite, line, rectangle, resize) might be shadowed.
 	addpath(fullfile(p,'+cv'),'-end');
end
if exist('cvtColor','file')~=3
	%% try to compile cvtColor.mex
	error('mexopencv:cvtColor is missing or not compiled!');
end

out.argin=varargin; 


if nargin<1,
	error('missing input argument');

elseif nargin==1
	%% name of color conversion in Matlab
	T = {'lab2lch',   'lch2lab',   'upvpl2xyz',   'xyz2upvpl',
	     'uvl2xyz',   'xyz2uvl',   'xyl2xyz',     'xyz2xyl',
	     'xyz2lab',   'lab2xyz',   'srgb2xyz',    'xyz2srgb',
	     'srgb2lab',  'lab2srgb',  'srgb2cmyk',   'cmyk2srgb' }; 

	%% corresponding color conversion name in OpenCV
	U = {'', '', '', '', 
             '', '', '', '', 
	     '', '', 'RGB2XYZ', 'XYZ2RGB', 
	     'RGB2Lab', 'Lab2RGB', '', ''
	    };

	ix = strmatch(varargin{1},T,'exact');
	if any(ix)
		out.c_func='cvtColor';
		if isempty(U{ix})
			error('conversion is not supported');
		else
			out.cdata.cforms=U{ix};
		end
	else
		error('unknown input argument')
	end; 
else
	warning('unsupported input arguments');
	disp(varargin);
end

