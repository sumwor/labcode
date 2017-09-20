function D = loadtiffseq(pathname,filename)

info=imfinfo(strcat(pathname,filename));
nX = info(1).Width;
nY = info(1).Height;
nZ = numel(info);
D=zeros(nY,nX,nZ,'uint16');  %pre-generate an empty array

%code below tested 3.37sec
%http://www.matlabtips.com/how-to-load-tiff-stacks-fast-really-fast/
TifLink = Tiff(strcat(pathname,filename), 'r');
for i=1:nZ
   TifLink.setDirectory(i);
   D(:,:,i)=TifLink.read();
end
TifLink.close();

% %code below tested 5.02sec
% %http://blogs.mathworks.com/steve/2009/04/02/matlab-r2009a-imread-and-multipage-tiffs/
% for i=1:nZ
%     D(:,:,i)=imread(strcat(pathname,filename),i,'Info',info);
% end