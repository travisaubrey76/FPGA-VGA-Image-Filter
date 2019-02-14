# FPGA-VGA-Image-Filter
/*
Author: Travis Aubrey*
Project Notes: Currently have the ability to send signals to an external monitor. 
	Update 1: I was able to send color signals to the screen easily following tutorials online. However, I am
				 struggling with being able to send an image.
	Update 2: I opted to utilize Matlab to do some initial image processing to compress and image to the correct
				 resolution as well as extract only the colors that I am able to show on this device.
	Update 3: A huge problem I encountered came with my image contents being written into a .list file containing 
				 only 1's and 0's were that the contents were too large for this board to handle.
	Update 4: I found out that it's onlt *too large* because I was instantiating my "ram" without using a bram module
				 so my board was utilizing all of it's available LUT's to create logic ram and thus had a very low hard
				 limit to how much memory I can thrust into those LUT's. To counteract this, I opted to crop my image 
				 into a smaller 240x240 and display it on the screen.
	Update 5: I was successfully able to display my image on the screen however there are some major hiccups. Using the LUT's
				 seems to have introduced some additional error in my vsync and hsync properties. In essence, my image (supposed
				 to be static) is moving and mirrored. I have an idea that this is due to only a fraction of the screen being used
				 whereas I have my vsync and hsycn generated to utilize the entire screen. Also, I beleive the mirrored property of
				 my image comes from how I address the pixels in my instatiated ram register block.
	Update 6: I did some research online and it looks like the way I have my image stored is causing the indexing problems. This
				 also explains my perpetual *warning: Index values do not match size of my ram*. I will now look into creating a bram
				 and storing the original 640x480 file in that. At this point, i've spent roughly 20 hours in this project.
				 
				 From the manual (pg 8):
					Xilinx Spartan-6 XC6SLX9 FPGA in a 144 pin TQFP package
					9,152 logic cell equivalents
					Thirty-two 18K-bit block RAMSs (576K bits) 
					
					-by instantiating my ram the way I have been, I have been capped to the 9,152 cell limit...which is abymsmically 
					 small for this type of image processing work.
					-By switching to Bram I am able to increase my capabiltiies more than 60-fold.


Credit/Awknogledgement:
	-First Reference for basic Hsync and Vsync code found from: https://www.fpga4fun.com/PongGame.html
*/

Any copying is strictly prohibited, please email me if you need help or would like the project zip file @ travisaubrey76@gmail.com
