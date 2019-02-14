`timescale 1ns / 1ps

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
module main(input M_CLOCK,
				input [3:0] IO_PB,
				input [7:0] IO_DSW,
				output [3:0] IO_SSEGD, // IO Board Seven Segment Digits			
				output [7:0] IO_SSEG,  // 7=dp, 6=g, 5=f,4=e, 3=d,2=c,1=b, 0=a
				output IO_SSEG_COL,    // 7 segment colon select
				output [3:0] F_LED, 
				output [7:0] IO_LED,
				output reg [2:0] pixel,
				output vga_h_sync, //Pin 3p11
				output vga_v_sync,  //Pin 3p12
				reg [18:0] addra
				);

/*
	Using coregen clock creator allows me to easily divide my 50MHZ board clock into the appropriate clocks for multiple uses
	and in this case, I needed 25 MHZ for 480p and 40 MHZ for 800x600 sync rates.
		-This module idea was found by completing LAB 7.
*/
  vga480 clock_converter
   (// Clock in ports
    .CLK_IN1(M_CLOCK),      // 50MHZ M_CLOCK feeds in
    // Clock out ports
    .VGA_480_CLK(VGA_480_CLK),     // 25MHZ out to satisfy 480p sync requirements
    .VGA_600_CLK(VGA_600_CLK));    // 40MHZ out to satisfy 600p sync requirements
	 
	bram stored_image (
		.clka(VGA_480_CLK), // input clka			%Matched clock with VGA clock for synchronization
		.wea(wea), // input [0 : 0] wea 				%Write enable is a single bit, but we don't want to write back into this yet.
		.addra(addra), // input [18 : 0] addra		%Address Input to determine what it will output
		.dina(dina), // input [0 : 0] dina			%1 bit data input since we're only working with 1's and 0's
		.douta(data_out) // output [0 : 0] douta	%1 bit data output since we're only workign with 1's and 0's
		);
	
	assign wea = 0; //Initially we don't want to write anything into our BRAM
	 
	//Disabling specific outputs on the board - might need later
	assign IO_SSEG_COL = 1;		   //Deactivate the colon displays
	assign F_LED = 4'b0000;       // deactivate the LEDs on main board
	assign IO_SSEGD = 4'b1111;	   // deactivate the seven segment display
	assign IO_SSEG = 8'b11111111;	// deactivate the seven segment display
	assign IO_LED = 8'b00000000;  // deactivate the LEDs on extension board
	 
	 reg vga_HS, vga_VS;
	 
	 reg [9:0] CounterX;
	 reg [9:0] CounterY;
	 wire CounterXmaxed = (CounterX == 800);
	 wire CounterYmaxed = (CounterY == 525);
	 reg inDisplayArea;
	 
	//reg  [0:0] ram [0:307199]; //Image has 307200 rows
	
	reg [18:0] extraCounter = 0;		 //overall mem access counter from 0 to 301199
	//reg data_out;				 //1 bit output from memory
	//reg [9:0] horizontal_counter = 0; //needs to be at <640...Might use CounterX though
	//reg [15:0] vert_counter = 0;
	
/*	initial begin
		$readmemb("lot_image_test.list", ram);
	end
*/	 

/*
	always @(posedge VGA_480_CLK) begin
		if (wea) ram[addra] <= dina;
		else data_out <= ram[addra];
	end
*/

	//Filter State Machine Counter
	reg [2:0] state = 3'b000; //Start at initial state



	 always @(posedge VGA_480_CLK) begin
		if(CounterXmaxed) CounterX <= 0;
		else CounterX <= CounterX + 1'b1;
	 end
	 always @(posedge VGA_480_CLK) begin
		if(CounterXmaxed) begin
			if(CounterYmaxed) CounterY <= 0;
			else CounterY <= CounterY + 1'b1;
		end
	end
	always @(posedge VGA_480_CLK) begin
		vga_HS <= (CounterX > (640+16) && (CounterX < (640 + 16 +96)));
		vga_VS <= (CounterY > (480+10) && (CounterY < (480 + 10 + 2)));
	end
	always @(posedge VGA_480_CLK) begin
		inDisplayArea <= (CounterX < 640) && (CounterY < 480);
	end
	//Output basic image
	always @(posedge VGA_480_CLK) begin
		addra <= CounterY * 640 + CounterX; //picks the correct address
		//Start of my image counter
		if(inDisplayArea) begin
			if(!IO_PB[3] || !IO_PB[2]) begin
				pixel <= {~data_out,~data_out,~data_out};
			end
			//else pixel <= {data_out,data_out,data_out};
			
			//BEGIN FILTERING STAGE IF BUTTON PRESS
			else if(!IO_PB[1] || !IO_PB[0]) begin
				case(state)
					3'b000: begin //STATE 1
						if(data_out) begin //If pixel is white keep outputting black
							pixel <= {~data_out,~data_out,~data_out};
							state <= 3'b001; //switch to state 2
						end
						else begin			//Return to same state
							pixel <= {data_out,data_out,data_out};
							state <= 3'b000;
						end
					end
					3'b001: begin //STATE 2
						if(data_out) begin
							pixel <= {~data_out,~data_out,~data_out};
							state <= 3'b010; //switch to state 3
						end
						else begin
							pixel <= {data_out,data_out,data_out};
							state <= 3'b000; //go back to state 1
						end
					end
					3'b010: begin //STATE 3
						if(data_out) begin
							pixel <= {data_out,data_out,data_out};
							state <= 3'b011; //White Memory trigger
						end
						else begin
							pixel <= {~data_out,~data_out,~data_out};
							state <= 3'b001;
						end
					end
					3'b011: begin //STATE 4
						if(data_out) begin
							pixel <= {data_out,data_out,data_out};
							state <= 3'b011; //STAY HERE IF WHITE KEEPS APPEARING
						end
						else begin //IF black appears cycle through white stages anyways
							pixel <= {~data_out,~data_out,~data_out};
							state <= 3'b100; //Go to state 5
						end
					end
					3'b100: begin //STATE 5
						if(data_out) begin
							pixel <= {data_out,data_out,data_out};
							state <= 3'b100; //Go back to state 4
						end
						else begin
							pixel <= {~data_out,~data_out,~data_out};
							state <= 3'b101; //Go to final white stage
						end
					end
					3'b101: begin //STATE 6
						if(data_out) begin
							pixel <= {data_out,data_out,data_out};
							state <= 3'b100; //Go back to state 5 if another white appears
						end
						else begin //Black memory trigger
							pixel <= {data_out,data_out,data_out};
							state <= 3'b000; //Go back to state 1
						end
					end
				default: pixel <= {data_out, data_out, data_out};
				endcase
			end
			else pixel <= {data_out, data_out, data_out};
			
		end
		else	pixel <= 3'b000; //Otherwise output black for sync zones
	end
	
	always @(posedge VGA_480_CLK) begin
					
	
	end
	
	//Inverting the v/h_sync signals to appropriately match the inputs required by the monitor
	assign vga_h_sync = ~vga_HS;
	assign vga_v_sync = ~vga_VS;
	

endmodule

/* Discarded code graveyard:
				//pixel <= 3'b111;

					if(hor_counter < 28800) begin
						pixel[2] <= ram[57599-hor_counter];
						pixel[1] <= ram[57599-hor_counter];
						pixel[0] <= ram[57599-hor_counter];
						hor_counter <= hor_counter + 1'b1;
					end
					else if(hor_counter < 57600 && hor_counter >= 28800) begin
						pixel[2] <= ram[hor_counter-28800];
						pixel[1] <= ram[hor_counter-28800];
						pixel[0] <= ram[hor_counter-28800];
						hor_counter <= hor_counter + 1'b1;
					end

					else begin
						pixel[2] <= ram[28799];
						pixel[1] <= ram[28799];
						pixel[0] <= ram[28799];
						hor_counter <= 0;
					end */
					//if(hor_counter < 56599) begin
						
						//hor_counter <= hor_counter + 1'b1;
					//end
					/*else begin
						pixel[2] <= ram[56599];
						pixel[1] <= ram[56599];
						pixel[0] <= ram[56599];
						hor_counter <= 0;
					end 				
*/