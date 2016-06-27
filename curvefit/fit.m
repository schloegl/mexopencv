function [v,gof] = fit(x,z,ft)
% FIT is a fitting function. 
%
% Usage: 
%	... = fit(x, z, type);
%	... = fit([x,y], z, type);
%	[p,g] = fit(...);

% Copyright (C) 2016 Alois Schloegl <alois.schloegl@ist.ac.at>
%
% This program is free software; you can redistribute it and/or modify it under
% the terms of the GNU General Public License as published by the Free Software
% Foundation; either version 3 of the License, or (at your option) any later
% version.
%
% This program is distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
% FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
% details.
%
% You should have received a copy of the GNU General Public License along with
% this program; if not, see <http://www.gnu.org/licenses/>.


if ischar(ft) 
	if strcmp(ft,'poly11')
		assert(size(x,2)==2);
		t = [ones(size(x,1),1), x(:,1:2)];
		
	elseif strcmp(ft,'poly21'),
		assert(size(x,2)==2);
		t = [ones(size(x,1),1), x(:,1:2), x(:,1).^2, x(:,1).*x(:,2)];

	elseif strcmp(ft,'poly21'),
		assert(size(x,2)==2);
		t = [ones(size(x,1),1), x(:,1:2), x(:,1).*x(:,2), x(:,2).^2];

	elseif strncmp(ft,'poly',4) && any(ft(5)=='0123456789') && (length(ft)==5) && (size(x,2)==1) 
		% poly0 - poly9
		d = abs(ft(5))-abs('0');		
		t = repmat(x(:,1),1,d+1) .^ repmat([d:-1:0],size(x,1),1);

	else 
		error('input argument not supported');

	end;

	v = t \ z;
	
	if (nargout > 1)
		gof.dfe  = size(x,1) - length(v);
		gof.sse  = sum((z - t*v).^2);
		gof.rmse = sqrt(gof.sse / gof.dfe);
	end;

else 
	error('input argument not supported');
end;

