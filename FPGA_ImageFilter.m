% Author: Travis Aubrey
% Red ID: 814041534
% Date: 12/18/2017
% Course: CompE470L
% Assignment: Final Project

%Aknowledgement: Image RGB extraction to 8bit hexa from here https://www.instructables.com/id/Image-from-FPGA-to-VGA/
%                Coe file creation credit goes to this video: https://www.youtube.com/watch?v=RDMVaeRJJUQ
clear all
close all
clc

%read the image
I = imread('lot_image.png');
j = imresize(I, [480 640]);
figure;
imshow(I);
title('Original Image');
figure;
imshow(j);
title('Resized');



		
%Extract RED, GREEN and BLUE components from the image
R = j(:,:,1);			
G = j(:,:,2);
B = j(:,:,3);

%make the numbers to be of double format for 
R = double(R);	
G = double(G);
B = double(B);

%Raise each member of the component by appropriate value. 
R = R.^(3/8); % 8 bits -> 3 bits
G = G.^(3/8); % 8 bits -> 3 bits
B = B.^(1/4); % 8 bits -> 2 bits

%tranlate to integer
R = uint8(R); % float -> uint8
G = uint8(G);
B = uint8(B);

%minus one cause sometimes conversion to integers rounds up the numbers wrongly
R = R-1; % 3 bits -> max value is 111 (bin) -> 7 (dec)(hex)
G = G-1;
B = B-1; % 11 (bin) -> 3 (dec)(hex)

%shift bits and construct one Byte from 3 + 3 + 2 bits
G = bitshift(G, 3); % 3 << G (shift by 3 bits)
B = bitshift(B, 6); % 6 << B (shift by 6 bits)
COLOR = R+G+B;      % R + 3 << G + 6 << B

%save variable COLOR to a file in HEX format for the chip to read
fileID = fopen ('lot_image.list', 'w');
for i = 1:size(COLOR(:), 1)-1
    fprintf (fileID, '%x\n', COLOR(i)); % COLOR (dec) -> print to file (hex)
end
fprintf (fileID, '%x', COLOR(size(COLOR(:), 1))); % COLOR (dec) -> print to file (hex)
fclose (fileID);

%translate to hex to see how many lines
COLOR_HEX = dec2hex(COLOR);

[IND32,map] = rgb2ind(j,32);
figure
imagesc(IND32)
colormap(map)
title('32 colors');
axis image

[IND16,map] = rgb2ind(j,16);
figure
imagesc(IND16)
colormap(map)
title('16 colors');
axis image

%Creates my image in 640x480
[IND2,map] = rgb2ind(j,2); 
figure 
imagesc(IND2)
colormap(map)
title('2 Colors');
axis image

%NEED TO CROP MY IMAGE CAUSE FPGA DOESN"T HAVE ENOUGH RAM
IND2_cropped = imcrop(IND2,map,[60 200 239 239]);
figure;
imagesc(IND2_cropped);colormap(map); title('Cropped Image');

%saving my newly created 8bit image file to a .bin file for Xilinx to use
fileID = fopen ('lot_image.bin', 'w');
if (fileID > 0)
    fwrite(fileID,IND2_cropped, 'uint8');

    fclose(fileID);
end

%save 8-bit image to a .txt file in case I need this file instead of the
%binary file.
fileID = fopen ('lot_image.txt', 'w');
for i = 1:size(IND2_cropped(:), 1)-1
    if (IND2_cropped(i) == 0)
        fprintf (fileID, '0\n');
    elseif (IND2_cropped(i) == 1)
        fprintf (fileID, '1\n');
    elseif (IND2_cropped(i) == 2)
        fprintf (fileID, '2\n');
    elseif (IND2_cropped(i) == 3)
        fprintf (fileID, '3\n');
    elseif (IND2_cropped(i) == 4)
        fprintf (fileID, '4\n');
    elseif (IND2_cropped(i) == 5)
        fprintf (fileID, '5\n');
    elseif (IND2_cropped(i) == 6)
        fprintf (fileID, '6\n');
    else
        fprintf (fileID, '7\n');
    end
end
fprintf (fileID, '5'); %I already know the final digit is a 5
fclose (fileID);

%save variable COLOR to a file in HEX format for the chip to read
fileID = fopen ('lot_image_test.list', 'w');
for i = 1:size(IND2_cropped(:), 1)-1
    fprintf (fileID, '%x\n', IND2_cropped(i)); % COLOR (dec) -> print to file (hex)
end
fprintf (fileID, '%x', IND2_cropped(size(IND2_cropped(:), 1))); % COLOR (dec) -> print to file (hex)
fclose (fileID);

%Create a .coe file for xilinx to use -using IND2 which is my resized image
%in black and white.
fid = fopen('lot_image.coe','w'); %if it doesn't exist, then create
fprintf(fid, '%s\n','MEMORY_INITIALIZATION_RADIX=2;');
fprintf(fid, '%s\n','MEMORY_INITIALIZATION_VECTOR=;');
for i = 1:size(IND2,1)
    for j = 1:size(IND2, 2)
        fprintf(fid, '%s',[dec2bin(IND2(i,j,1),1)]);
        if(i == size(IND2,1) && j == size(IND2,2))
            fprintf(fid, '%s',';');
        else
            fprintf(fid, '%s\n', ',');
        end
    end
end
fclose(fid);