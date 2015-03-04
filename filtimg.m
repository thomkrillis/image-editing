function [imgout] = filtimg(imgin,v,varargin)
% FILTIMG   Filter an image pixelwise by colour values.
%           Stopped pixels are set to black by default.
%
%    F = FILTIMG(I,V) returns uint8 image F filtered from uint8 image I
%    by vector V of lower and upper limits of red, green, and blue colour
%    values, respectively, from 0 to 256 (e.g. V = [80,256,0,112,120,200])
%    for default option 0.
%
%    F = FILTIMG(I,V,H,W) returns F filtered from I(1:H,1:W,:) by vector V.
%
%    F = FILTIMG(I,V,'c',C) returns F filtered from I by vector V where the
%    RGB values, 0 to 255, of stopped pixels are set to vector C
%    (e.g. C = [255,0,0]).
%
%    F = FILTIMG(I,V,'o',O) returns F filtered from I by vector V using the
%    option specified by O.
%
%        Option 0 (default): Specify the lower and upper limits of red,
%        green, and blue colour values, respectively, from 0 to 256
%        (e.g. V = [80,256,0,112,120,200]).
%
%        Option 1: Specify the lower and upper limits of the ratios of
%        colour values R-to-G, G-to-B, and B-to-R, respectively, from 0 to
%        inf (e.g. V = [0.15,2,1.2,3.1,0.3,1.1]).
%
%        Option 2: Specify the lower and upper limits of the sum of the
%        colour values, from 0 to 766 (e.g. V = [0,300]). Lower range
%        favours darker pixels and more extreme colour differences, while
%        higher range favours brighter and near-white pixels.
%
%        Option 3: Specify the lower and upper limits of the average
%        difference between the colour values, from 0 to 170 (e.g. V =
%        [0,30]). Lower range favours more similar colour values, near
%        grayscale, while higher range favours pixels whose colour stands
%        out.

%Parse function inputs
p = inputParser;
%classes
imgchk = {'uint8'};
numchk = {'numeric'};
%attributes
imgdim = {'3d'};
nempty = {'nonempty'};
len = {'numel',3};
optionchk = {'scalar','>=',0,'<',4};

addRequired(p,'imgin',@(x)validateattributes(x,imgchk,imgdim))
addRequired(p,'v',@(x)validateattributes(x,numchk,nempty))
addOptional(p,'h',size(imgin,1),@(x)validateattributes(x,numchk,nempty))
addOptional(p,'w',size(imgin,2),@(x)validateattributes(x,numchk,nempty))
addParameter(p,'c',[0,0,0],@(x)validateattributes(x,numchk,len))
addParameter(p,'o',0,@(x)validateattributes(x,numchk,optionchk))
parse(p,imgin,v,varargin{:})

%Set defaults if optional inputs are left out
h = p.Results.h;
w = p.Results.w;
c = p.Results.c;
o = p.Results.o;
v = num2cell(v);
switch length(v)
    case 6
        [l1,u1,l2,u2,l3,u3] = deal(v{:});
        if o ~= 0 && o ~= 1
            error('Invalid length of second input for this option.');
        end
    case 2
        [l,u] = deal(v{:});
        if o ~= 2 && o ~= 3
            error('Invalid length of second input for this option.');
        end
    otherwise
        error('Invalid vector length for second input.');
end

imgout = imgin(1:h,1:w,:);

%values for RGB values of stopped pixels 0 to 255
c = num2cell(c);
[r,g,b] = deal(c{:});

switch o
    case 0
        %Uses hard pixel value ranges
                
        %mxn logicals for which pixels to remove
        stopped = imgout(:,:,1) < l1 | imgout(:,:,1) > u1...
            | imgout(:,:,2) < l2 | imgout(:,:,2) > u2...
            | imgout(:,:,3) < l3 | imgout(:,:,3) > u3;
    case 1
        %Uses colour ratios
        imgoutdouble = im2double(imgout);
        
        imgoutrg = imgoutdouble(:,:,1)./imgoutdouble(:,:,2);
        imgoutgb = imgoutdouble(:,:,2)./imgoutdouble(:,:,3);
        imgoutbr = imgoutdouble(:,:,3)./imgoutdouble(:,:,1);
        
        %mxn logicals for which pixels to remove
        stopped = imgoutrg < l1 | imgoutrg > u1...
            | imgoutgb < l2 | imgoutgb > u2...
            | imgoutbr < l3 | imgoutbr > u3;
    case 2
        %Impose range on sum of colour values
        stopped = sum(imgout,3) < l | sum(imgout,3) > u;
    case 3
        %Impose range on abs mean difference of colour values per pixel        
        imgoutmax = max(imgout,[],3);
        imgoutmin = min(imgout,[],3);
        
        imgoutdiff = (2/3).*(imgoutmax - imgoutmin);
        
        stopped = imgoutdiff < l | imgoutdiff > u;
end

%remove pixels
if ~isequal(c,[0,0,0])
    imgoutr = imgout(:,:,1);
    imgoutg = imgout(:,:,2);
    imgoutb = imgout(:,:,3);
    
    imgoutr(stopped) = r;
    imgoutg(stopped) = g;
    imgoutb(stopped) = b;
    
    imgout = cat(3,imgoutr,imgoutg,imgoutb);
else
    imgout(cat(3,stopped,stopped,stopped)) = 0;
end

figure()
imshow(imgout);
end