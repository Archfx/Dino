`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:30:38 03/19/2013 
// Design Name: 
// Module Name:    vga640x480 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module vga640x480(
	input wire pix_en,		//pixel clock: 25MHz
	input wire game_clk,
	input wire clk,			//100MHz
	input wire rst,			//asynchronous reset
	input wire btnS,
	input wire btnU,
	input wire btnL,
	input wire btnR,
	output wire hsync,		//horizontal sync out
	output wire vsync,		//vertical sync out
	output reg [2:0] red,	//red vga output
	output reg [2:0] green, //green vga output
	output reg [1:0] blue	//blue vga output
	);

// video structure constants
parameter hpixels = 800;// horizontal pixels per line
parameter vlines = 521; // vertical lines per frame
parameter hpulse = 96; 	// hsync pulse length
parameter vpulse = 2; 	// vsync pulse length
parameter hbp = 144; 	// end of horizontal back porch
parameter hfp = 784; 	// beginning of horizontal front porch
parameter vbp = 31; 		// end of vertical back porch
parameter vfp = 511; 	// beginning of vertical front porch


// active horizontal video is therefore: 784 - 144 = 640
// active vertical video is therefore: 511 - 31 = 480

// Note: Top of screen is 0 + vbp

parameter numAliens = 5;
parameter winningScore = numAliens * 10;
parameter topBarPos = 200 + vbp;
parameter leftBarPos = hbp + 200;
parameter rightBarPos = hfp - 200;

integer playerPosY = -70 + vfp;
integer playerPosX = 320 + hbp;
integer bulletPosX = 0;
integer bulletPosY = 0;

integer score = 0;

reg [10:0] alienPosXArray[0:numAliens-1];
reg [10:0] alienPosYArray[0:numAliens-1];
//parameter initialAlienX[0:numAliens-1];
//parameter initialAlienY[0:numAliens-1];

// For alien movement.
reg[7:0] alienTranslationCnt = 0;
reg[12:0] translation = 0;
reg[3:0] deadAliens = 2;
reg alienRight = 1;
reg[3:0] alienSpeed = 'b0110; // logical right shift to double speed



////// DEBOUNCING ////////
//reg [3:0] btnS_buff;
//reg game_clk_debounce;
//reg btnS_vld;
//////////////////////////

initial
begin
	alienPosXArray[0] = 200 + hbp;
	alienPosXArray[1] = 240 + hbp;
	alienPosXArray[2] = 280 + hbp;
	alienPosXArray[3] = 200 + hbp;
	alienPosXArray[4] = 280 + hbp;

	alienPosYArray[0] = 220 + vbp;
	alienPosYArray[1] = 220 + vbp;
	alienPosYArray[2] = 220 + vbp;
	alienPosYArray[3] = 600;//250 + vbp;
	alienPosYArray[4] = 600;//250 + vbp;
	
	//btnS_buff[0] = 0;
	//btnS_buff[1] = 0;
	//btnS_buff[2] = 0;
end



// registers for storing the horizontal & vertical counters
reg [9:0] hc;
reg [9:0] vc;

// flags
reg spawnBullet;
reg gameover = 0;
//reg pauseFlag;

// iterators
reg[6:0] i;
reg[6:0] j;
reg[6:0] k;
// Horizontal & vertical counters --
// this is how we keep track of where we are on the screen.
// ------------------------
// Sequential "always block", which is a block that is
// only triggered on signal transitions or "edges".
// posedge = rising edge  &  negedge = falling edge
// Assignment statements can only be used on type "reg" and need to be of the "non-blocking" type: <=
always @(posedge clk)
begin
	if(btnU 	&& deadAliens < numAliens)
		if(bulletPosY <= topBarPos)
			spawnBullet <= 1;
	else if (bulletPosY > vbp)
		spawnBullet <= 0;
	
	// If aliens touch player then he dies.
	if(alienPosYArray[0] > playerPosY - 8 && alienPosYArray[0] < vfp ||
		alienPosYArray[1] > playerPosY - 8 && alienPosYArray[1] < vfp ||
	   alienPosYArray[2] > playerPosY - 8 && alienPosYArray[2] < vfp || 
	   alienPosYArray[3] > playerPosY - 8 && alienPosYArray[3] < vfp ||
	   alienPosYArray[4] > playerPosY - 8 && alienPosYArray[4] < vfp)
		gameover <= 1;
	
	// reset condition
	if (rst == 1)
	begin
		hc <= 0;
		vc <= 0;
		spawnBullet <= 0;
		//btnS_vld <= 0;
		//game_clk_debounce = 0;
		//pauseFlag <= 0;
	end
	else if (pix_en == 1)
	begin
		// keep counting until the end of the line
		if (hc < hpixels - 1)
			hc <= hc + 1;
		else
		begin
			hc <= 0;
			if (vc < vlines - 1)
				vc <= vc + 1;
			else
				vc <= 0;
		end
	end
	
	//if(btnS_vld)
	//	pauseFlag <= ~pauseFlag;
	
	/////// DEBOUNCING ////////
	//game_clk_debounce = game_clk;
	//btnS_vld <= ~btnS_buff[0] & btnS_buff[1]; //& game_clk_debounce;
	///////////////////////////
end

always @(posedge game_clk or posedge spawnBullet)
begin

	if(spawnBullet)
	begin
		bulletPosX <= playerPosX + 9;
		bulletPosY <= playerPosY - 7;
	end 
   else //if (!pauseFlag)
	begin
		alienTranslationCnt <= alienTranslationCnt + 1;
		if(alienTranslationCnt == alienSpeed) //1)
		begin
			if(translation < 150)
				translation <= translation + 1;
			alienTranslationCnt <= 0;
			for(k = 0; k < numAliens; k = k + 1)
			begin
				if(translation < 144)
				begin	
					 // Putting this line here makes the synthesis take forever for some reason.
					if(alienRight)
						alienPosXArray[k] <= alienPosXArray[k] + 1;
					else
						alienPosXArray[k] <= alienPosXArray[k] - 1;
				end
				else // Move aliens down.
				begin
					translation <= 0;
					alienRight <= ~alienRight;
					alienPosYArray[k] <= alienPosYArray[k] + 10;
				end
			end
		end
				
		if(btnL && playerPosX != leftBarPos) // Move left.
			playerPosX <= playerPosX - 1;
		if(btnR && playerPosX != rightBarPos - 18) // Move right.
			playerPosX <= playerPosX + 1;
			
		// When player wins, travel upwards.
		if(deadAliens >= numAliens)
			playerPosY <= playerPosY - 1;
			
		// Advance to next level once the player reaches the top.
		if(playerPosY < vbp)
		begin
			alienPosXArray[0] <= 200 + hbp;
			alienPosXArray[1] <= 240 + hbp;
			alienPosXArray[2] <= 280 + hbp;
			alienPosXArray[3] <= 200 + hbp;
			alienPosXArray[4] <= 280 + hbp;

			alienPosYArray[0] <= 220 + vbp;
			alienPosYArray[1] <= 220 + vbp;
			alienPosYArray[2] <= 220 + vbp;
			alienPosYArray[3] <= 250 + vbp;
			alienPosYArray[4] <= 250 + vbp;
			
			playerPosY <= -70 + vfp;
			
			deadAliens <= 0;
			translation <= 0;
			alienRight <= 1;
			alienSpeed <= alienSpeed >> 1;
		end
			
		if(bulletPosY >= 0)
			bulletPosY <= bulletPosY - 1;
			
		// Kill alien once it comes into contact with a bullet.
		for(j = 0; j < numAliens; j = j + 1)
		begin
			if(bulletPosX > alienPosXArray[j] - 4 && bulletPosX <= alienPosXArray[j] + 14 &&
					bulletPosY - 8 <= alienPosYArray[j] && bulletPosY >= alienPosYArray[j])
			begin
				alienPosYArray[j] <= 600;
				bulletPosY <= 0;
				bulletPosX <= 0;
				score <= score + 10;
				deadAliens <= deadAliens + 1;
			end
		end
	end
end

// generate sync pulses (active low)
// ----------------
// "assign" statements are a quick way to
// give values to variables of type: wire
assign hsync = (hc < hpulse) ? 0:1;
assign vsync = (vc < vpulse) ? 0:1;

// display 100% saturation colorbars
// ------------------------
// Combinational "always block", which is a block that is
// triggered when anything in the "sensitivity list" changes.
// The asterisk implies that everything that is capable of triggering the block
// is automatically included in the sensitivty list.  In this case, it would be
// equivalent to the following: always @(hc, vc)
// Assignment statements can only be used on type "reg" and should be of the "blocking" type: =
always @(*)
begin
	//////////// Debouncing ////////
	//btnS_buff <= {btnS,btnS_buff[2:1]};
	////////////////////////////////
	
	// first check if we're within vertical active video range
	if (vc >= vbp && vc < vfp)
	begin
		if(gameover)
		begin
			red = 3'b111;
			green = 3'b000;
			blue = 2'b00;
		end
		// Draw bars at the sides of the screen.
		else if(hc >= rightBarPos || hc <= leftBarPos)
		begin
			red = 3'b111;
			green = 3'b000;
			blue = 2'b11;
		end
		// Draw bullet.
		else if (hc >= (bulletPosX) && hc < (bulletPosX + 2)
			&& vc >= (bulletPosY - 10) && vc < (bulletPosY))
		begin
			red = 3'b111;
			green = 3'b111;
			blue = 2'b000;
		end
		// Draw player sprite.
		/*else if (hc >= (playerPosX) && hc < (playerPosX + 18)
				&& vc >= (playerPosY - 7) && vc < (playerPosY))
		begin
			red = 3'b000;
			green = 3'b111;
			blue = 2'b00;
		end
		else if (hc >= (playerPosX + 7) && hc < (playerPosX + 11)
				&& vc >= (playerPosY - 10) && vc < (playerPosY - 7))
		begin
			red = 3'b000;
			green = 3'b111;
			blue = 2'b00;
		end*/
		else if ((vc == playerPosX + 6'd4  && hc == playerPosY + 6'd10 ) || (vc == playerPosX + 6'd4  && hc == playerPosY + 6'd11 ) || (vc == playerPosX + 6'd4  && hc == playerPosY + 6'd12 ) || (vc == playerPosX + 6'd4  && hc == playerPosY + 6'd13 ) || (vc == playerPosX + 6'd4  && hc == playerPosY + 6'd14 ) || (vc == playerPosX + 6'd4  && hc == playerPosY + 6'd15 ) || (vc == playerPosX + 6'd4  && hc == playerPosY + 6'd16 ) || (vc == playerPosX + 6'd5  && hc == playerPosY + 6'd10 ) || (vc == playerPosX + 6'd5  && hc == playerPosY + 6'd11 ) || (vc == playerPosX + 6'd5  && hc == playerPosY + 6'd12 ) || (vc == playerPosX + 6'd5  && hc == playerPosY + 6'd13 ) || (vc == playerPosX + 6'd5  && hc == playerPosY + 6'd14 ) || (vc == playerPosX + 6'd5  && hc == playerPosY + 6'd15 ) || (vc == playerPosX + 6'd5  && hc == playerPosY + 6'd16 ) || (vc == playerPosX + 6'd6  && hc == playerPosY + 6'd10 ) || (vc == playerPosX + 6'd6  && hc == playerPosY + 6'd11 ) || (vc == playerPosX + 6'd6  && hc == playerPosY + 6'd12 ) || (vc == playerPosX + 6'd6  && hc == playerPosY + 6'd13 ) || (vc == playerPosX + 6'd6  && hc == playerPosY + 6'd14 ) || (vc == playerPosX + 6'd6  && hc == playerPosY + 6'd15 ) || (vc == playerPosX + 6'd6  && hc == playerPosY + 6'd16 ) || (vc == playerPosX + 6'd7  && hc == playerPosY + 6'd10 ) || (vc == playerPosX + 6'd7  && hc == playerPosY + 6'd11 ) || (vc == playerPosX + 6'd7  && hc == playerPosY + 6'd12 ) || (vc == playerPosX + 6'd7  && hc == playerPosY + 6'd13 ) || (vc == playerPosX + 6'd7  && hc == playerPosY + 6'd14 ) || (vc == playerPosX + 6'd7  && hc == playerPosY + 6'd15 ) || (vc == playerPosX + 6'd7  && hc == playerPosY + 6'd16 ) || (vc == playerPosX + 6'd8  && hc == playerPosY + 6'd10 ) || (vc == playerPosX + 6'd8  && hc == playerPosY + 6'd11 ) || (vc == playerPosX + 6'd8  && hc == playerPosY + 6'd12 ) || (vc == playerPosX + 6'd8  && hc == playerPosY + 6'd13 ) || (vc == playerPosX + 6'd8  && hc == playerPosY + 6'd14 ) || (vc == playerPosX + 6'd9  && hc == playerPosY + 6'd4 ) || (vc == playerPosX + 6'd9  && hc == playerPosY + 6'd9 ) || (vc == playerPosX + 6'd9  && hc == playerPosY + 6'd10 ) || (vc == playerPosX + 6'd9  && hc == playerPosY + 6'd11 ) || (vc == playerPosX + 6'd9  && hc == playerPosY + 6'd12 ) || (vc == playerPosX + 6'd10  && hc == playerPosY + 6'd4 ) || (vc == playerPosX + 6'd10  && hc == playerPosY + 6'd5 ) || (vc == playerPosX + 6'd10  && hc == playerPosY + 6'd8 ) || (vc == playerPosX + 6'd10  && hc == playerPosY + 6'd9 ) || (vc == playerPosX + 6'd10  && hc == playerPosY + 6'd10 ) || (vc == playerPosX + 6'd10  && hc == playerPosY + 6'd11 ) || (vc == playerPosX + 6'd10  && hc == playerPosY + 6'd12 ) || (vc == playerPosX + 6'd10  && hc == playerPosY + 6'd13 ) || (vc == playerPosX + 6'd11  && hc == playerPosY + 6'd4 ) || (vc == playerPosX + 6'd11  && hc == playerPosY + 6'd5 ) || (vc == playerPosX + 6'd11  && hc == playerPosY + 6'd6 ) || (vc == playerPosX + 6'd11  && hc == playerPosY + 6'd7 ) || (vc == playerPosX + 6'd11  && hc == playerPosY + 6'd8 ) || (vc == playerPosX + 6'd11  && hc == playerPosY + 6'd9 ) || (vc == playerPosX + 6'd11  && hc == playerPosY + 6'd10 ) || (vc == playerPosX + 6'd11  && hc == playerPosY + 6'd11 ) || (vc == playerPosX + 6'd11  && hc == playerPosY + 6'd12 ) || (vc == playerPosX + 6'd11  && hc == playerPosY + 6'd13 ) || (vc == playerPosX + 6'd12  && hc == playerPosY + 6'd5 ) || (vc == playerPosX + 6'd12  && hc == playerPosY + 6'd6 ) || (vc == playerPosX + 6'd12  && hc == playerPosY + 6'd7 ) || (vc == playerPosX + 6'd12  && hc == playerPosY + 6'd8 ) || (vc == playerPosX + 6'd12  && hc == playerPosY + 6'd9 ) || (vc == playerPosX + 6'd12  && hc == playerPosY + 6'd10 ) || (vc == playerPosX + 6'd12  && hc == playerPosY + 6'd11 ) || (vc == playerPosX + 6'd12  && hc == playerPosY + 6'd12 ) || (vc == playerPosX + 6'd13  && hc == playerPosY + 6'd5 ) || (vc == playerPosX + 6'd13  && hc == playerPosY + 6'd6 ) || (vc == playerPosX + 6'd13  && hc == playerPosY + 6'd7 ) || (vc == playerPosX + 6'd13  && hc == playerPosY + 6'd8 ) || (vc == playerPosX + 6'd13  && hc == playerPosY + 6'd9 ) || (vc == playerPosX + 6'd13  && hc == playerPosY + 6'd10 ) || (vc == playerPosX + 6'd13  && hc == playerPosY + 6'd11 ) || (vc == playerPosX + 6'd13  && hc == playerPosY + 6'd12 ) || (vc == playerPosX + 6'd14  && hc == playerPosY + 6'd6 ) || (vc == playerPosX + 6'd14  && hc == playerPosY + 6'd7 ) || (vc == playerPosX + 6'd14  && hc == playerPosY + 6'd8 ) || (vc == playerPosX + 6'd14  && hc == playerPosY + 6'd9 ) || (vc == playerPosX + 6'd14  && hc == playerPosY + 6'd10 ) || (vc == playerPosX + 6'd14  && hc == playerPosY + 6'd11 ) || (vc == playerPosX + 6'd15  && hc == playerPosY + 6'd7 ) || (vc == playerPosX + 6'd15  && hc == playerPosY + 6'd8 ) || (vc == playerPosX + 6'd15  && hc == playerPosY + 6'd10 ) || (vc == playerPosX + 6'd16  && hc == playerPosY + 6'd7 ) || (vc == playerPosX + 6'd16  && hc == playerPosY + 6'd8 ) || (vc == playerPosX + 6'd16  && hc == playerPosY + 6'd11 ))
		begin
			red = 3'b000;
			green = 3'b111;
			blue = 2'b00;
		end
		else
		// Draw black.
		begin
			red = 3'b000;
			green = 3'b000;
			blue = 2'b00;
		end
		
		// Score.
		if((hc >= hbp + 100 && hc < hbp + 150 &&
			vc <= topBarPos + 5 && vc > topBarPos + 5 - (score/50 * 4))
		||(hc >= hbp + 100 && hc < hbp + 100 + score % 50 &&
    		vc <= topBarPos + 5 && vc > topBarPos + 1 - (score/50 * 4)))
		begin
			red = 3'b000;
			green = 3'b111;
			blue = 2'b00;
		end
		
		// Draw S
		if( ((vc == topBarPos + 15 || vc == topBarPos + 16 || 
			  vc == topBarPos + 19 || vc == topBarPos + 20 ||
			  vc == topBarPos + 23 || vc == topBarPos + 24) &&
			  (hc > hbp + 100 && hc < hbp + 109)) ||
			  ((vc == topBarPos + 17 || vc == topBarPos + 18) &&
			  (hc == hbp + 101 || hc == hbp + 102)) || 
			  ((vc == topBarPos + 21 || vc == topBarPos + 22) &&
			  (hc == hbp + 107 || hc == hbp + 108)))
			begin
				red = 3'b111;
				green = 3'b111;
				blue = 2'b11;
			end
		// Draw C.
		if(((hc > hbp + 110 && hc < hbp + 119) &&
		(vc == topBarPos + 15 || vc == topBarPos + 16 ||
		vc == topBarPos + 23 || vc == topBarPos + 24)) ||
		((vc > topBarPos + 14 && vc < topBarPos + 25) &&
		(hc == hbp + 111 || hc == hbp + 112)))
		begin
				red = 3'b111;
				green = 3'b111;
				blue = 2'b11;
			end
		// Draw O.
		if(((vc == topBarPos + 15 || vc == topBarPos + 16 ||
		vc == topBarPos + 23 || vc == topBarPos + 24)
		&& (hc > hbp + 120 && hc < hbp + 129)) ||
		((vc > topBarPos + 14 && vc < topBarPos + 25)
		&& (hc == hbp + 121 || hc == hbp + 122 ||
		hc == hbp + 127 || hc == hbp + 128)))
			begin
				red = 3'b111;
				green = 3'b111;
				blue = 2'b11;
			end
		// Draw R.
		if(((hc > hbp + 130 && hc < hbp + 133) &&
		(vc >= topBarPos + 15 && vc <= topBarPos + 24)) ||
		((hc >= hbp + 135 && hc < hbp + 137) &&
		(vc >= topBarPos + 15 && vc <= topBarPos + 20)) ||
		((hc >= hbp + 137 && hc < hbp + 139) &&
		(vc >= topBarPos + 20 && vc <= topBarPos + 24))||
		((vc == topBarPos + 15 || vc == topBarPos + 16) &&
		(hc > hbp + 130 && hc < hbp + 137)) ||
		((vc == topBarPos + 19 || vc == topBarPos + 20) &&
		(hc > hbp + 130 && hc < hbp + 139)))
		begin
				red = 3'b111;
				green = 3'b111;
				blue = 2'b11;
			end
		// Draw E.
		if(((vc == topBarPos + 15 || vc == topBarPos + 16
		|| vc == topBarPos + 19 || vc == topBarPos + 20
		|| vc == topBarPos + 23 || vc == topBarPos + 24)
		&& (hc > hbp + 140 && hc < hbp + 149)) ||
		((vc > topBarPos + 14 && vc < topBarPos + 25)
		&& (hc == hbp + 141 || hc == hbp + 142)))
			begin
				red = 3'b111;
				green = 3'b111;
				blue = 2'b11;
			end
		// Draw ground
		if ((vc == 400 +  6'd87  && hc ==  6'd322 ) || (vc == 400 +  6'd87  && hc ==  6'd323 ) || (vc == 400 +  6'd87  && hc ==  6'd324 ) || (vc == 400 +  6'd87  && hc ==  6'd325 ) || (vc == 400 +  6'd87  && hc ==  6'd326 ) || (vc == 400 +  6'd87  && hc ==  6'd327 ) || (vc == 400 +  6'd87  && hc ==  6'd328 ) || (vc == 400 +  6'd87  && hc ==  6'd329 ) || (vc == 400 +  6'd87  && hc ==  6'd330 ) || (vc == 400 +  6'd87  && hc ==  6'd331 ) || (vc == 400 +  6'd87  && hc ==  6'd332 ) || (vc == 400 +  6'd87  && hc ==  6'd333 ) || (vc == 400 +  6'd87  && hc ==  6'd334 ) || (vc == 400 +  6'd87  && hc ==  6'd335 ) || (vc == 400 +  6'd87  && hc ==  6'd336 ) ||(vc == 400 +  6'd87  && hc ==  6'd337 ) || (vc == 400 +  6'd87  && hc ==  6'd338 ) || (vc == 400 +  6'd87  && hc ==  6'd339 ) || (vc == 400 +  6'd87  && hc ==  6'd340 ) || (vc == 400 +  6'd87  && hc ==  6'd341 ) || (vc == 400 +  6'd87  && hc ==  6'd342 ) || (vc == 400 +  6'd87  && hc ==  6'd343 ) || (vc == 400 +  6'd87  && hc ==  6'd344 ) || (vc == 400 +  6'd87  && hc ==  6'd345 ) || (vc == 400 +  6'd87  && hc ==  6'd346 ) || (vc == 400 +  6'd87  && hc ==  6'd347 ) || (vc == 400 +  6'd87  && hc ==  6'd348 ) || (vc == 400 +  6'd87  && hc ==  6'd349 ) || (vc == 400 +  6'd87  && hc ==  6'd350 ) || (vc == 400 +  6'd87  && hc ==  6'd351 ) || (vc == 400 +  6'd87  && hc ==  6'd352 ) || (vc == 400 +  6'd87  && hc ==  6'd353 ) || (vc == 400 +  6'd87  && hc ==  6'd354 ) || (vc == 400 +  6'd87  && hc ==  6'd355 ) || (vc == 400 +  6'd87  && hc ==  6'd356 ) || (vc == 400 +  6'd87  && hc ==  6'd357 ) || (vc == 400 +  6'd87  && hc ==  6'd358 ) || (vc == 400 +  6'd87  && hc ==  6'd359 ) || (vc == 400 +  6'd87  && hc ==  6'd360 ) || (vc == 400 +  6'd87  && hc ==  6'd361 ) || (vc == 400 +  6'd87  && hc ==  6'd362 ) || (vc == 400 +  6'd87  && hc ==  6'd363 ) || (vc == 400 +  6'd87  && hc ==  6'd364 ) || (vc == 400 +  6'd87  && hc ==  6'd365 ) || (vc == 400 +  6'd87  && hc ==  6'd366 ) || (vc == 400 +  6'd87  && hc ==  6'd367 ) || (vc == 400 +  6'd87  && hc ==  6'd368 ) || (vc == 400 +  6'd87  && hc ==  6'd369 ) || (vc == 400 +  6'd87  && hc ==  6'd370 ) || (vc == 400 +  6'd87  && hc ==  6'd371 ) || (vc == 400 +  6'd87  && hc ==  6'd372 ) || (vc == 400 +  6'd87  && hc ==  6'd373 ) || (vc == 400 +  6'd87  && hc ==  6'd374 ) || (vc == 400 +  6'd87  && hc ==  6'd375 ) || (vc == 400 +  6'd87  && hc ==  6'd376 ) || (vc == 400 +  6'd87  && hc ==  6'd377 ) || (vc == 400 +  6'd87  && hc ==  6'd378 ) || (vc == 400 +  6'd87  && hc ==  6'd379 ) || (vc == 400 +  6'd87  && hc ==  6'd380 ) || (vc == 400 +  6'd87  && hc ==  6'd381 ) || (vc == 400 +  6'd87  && hc ==  6'd382 ) || (vc == 400 +  6'd87  && hc ==  6'd383 ) || (vc == 400 +  6'd87  && hc ==  6'd384 ) || (vc == 400 +  6'd87  && hc ==  6'd385 ) || (vc == 400 +  6'd87  && hc ==  6'd386 ) || (vc == 400 +  6'd87  && hc ==  6'd387 ) || (vc == 400 +  6'd87  && hc ==  6'd388 ) || (vc == 400 +  6'd87  && hc ==  6'd389 ) || (vc == 400 +  6'd87  && hc ==  6'd390 ) || (vc == 400 +  6'd87  && hc ==  6'd391 ) || (vc == 400 +  6'd87  && hc ==  6'd392 ) || (vc == 400 +  6'd87  && hc ==  6'd393 ) || (vc == 400 +  6'd87  && hc ==  6'd394 ) || (vc == 400 +  6'd87  && hc ==  6'd395 ) || (vc == 400 +  6'd87  && hc ==  6'd396 ) || (vc == 400 +  6'd87  && hc ==  6'd397 ) || (vc == 400 +  6'd87  && hc ==  6'd398 ) || (vc == 400 +  6'd87  && hc ==  6'd399 ) || (vc == 400 +  6'd87  && hc ==  6'd400 ) || (vc == 400 +  6'd87  && hc ==  6'd401 ) || (vc == 400 +  6'd87  && hc ==  6'd402 ) || (vc == 400 +  6'd87  && hc ==  6'd403 ) || (vc == 400 +  6'd87  && hc ==  6'd404 ) || (vc == 400 +  6'd87  && hc ==  6'd405 ) || (vc == 400 +  6'd87  && hc ==  6'd406 ) || (vc == 400 +  6'd87  && hc ==  6'd407 ) || (vc == 400 +  6'd87  && hc ==  6'd408 ) || (vc == 400 +  6'd87  && hc ==  6'd409 ) || (vc == 400 +  6'd87  && hc ==  6'd410 ) || (vc == 400 +  6'd87  && hc ==  6'd411 ) || (vc == 400 +  6'd87  && hc ==  6'd412 ) || (vc == 400 +  6'd87  && hc ==  6'd413 ) || (vc == 400 +  6'd87  && hc ==  6'd414 ) || (vc == 400 +  6'd87  && hc ==  6'd415 ) || (vc == 400 +  6'd87  && hc ==  6'd416 ) || (vc == 400 +  6'd87  && hc ==  6'd417 ) || (vc == 400 +  6'd87  && hc ==  6'd418 ) || (vc == 400 +  6'd87  && hc ==  6'd419 ) || (vc == 400 +  6'd87  && hc ==  6'd420 ) || (vc == 400 +  6'd87  && hc ==  6'd421 ) || (vc == 400 +  6'd87  && hc ==  6'd422 ) || (vc == 400 +  6'd87  && hc ==  6'd423 ) || (vc == 400 +  6'd87  && hc ==  6'd424 ) || (vc == 400 +  6'd87  && hc ==  6'd425 ) || (vc == 400 +  6'd87  && hc ==  6'd426 ) || (vc == 400 +  6'd87  && hc ==  6'd427 ) || (vc == 400 +  6'd87  && hc ==  6'd428 ) || (vc == 400 +  6'd87  && hc ==  6'd429 ) || (vc == 400 +  6'd87  && hc ==  6'd430 ) || (vc == 400 +  6'd87  && hc ==  6'd431 ) || (vc == 400 +  6'd87  && hc ==  6'd432 ) || (vc == 400 +  6'd87  && hc ==  6'd433 ) || (vc == 400 +  6'd87  && hc ==  6'd434 ) || (vc == 400 +  6'd87  && hc ==  6'd435 ) || (vc == 400 +  6'd87  && hc ==  6'd436 ) || (vc == 400 +  6'd87  && hc ==  6'd437 ) || (vc == 400 +  6'd87  && hc ==  6'd438 ) || (vc == 400 +  6'd87  && hc ==  6'd439 ) || (vc == 400 +  6'd87  && hc ==  6'd440 ) || (vc == 400 +  6'd87  && hc ==  6'd441 ) || (vc == 400 +  6'd87  && hc ==  6'd442 ) || (vc == 400 +  6'd87  && hc ==  6'd443 ) || (vc == 400 +  6'd87  && hc ==  6'd444 ) || (vc == 400 +  6'd87  && hc ==  6'd445 ) || (vc == 400 +  6'd87  && hc ==  6'd446 ) || (vc == 400 +  6'd87  && hc ==  6'd447 ) || (vc == 400 +  6'd87  && hc ==  6'd448 ) || (vc == 400 +  6'd87  && hc ==  6'd449 ) || (vc == 400 +  6'd87  && hc ==  6'd450 ) || (vc == 400 +  6'd87  && hc ==  6'd451 ) || (vc == 400 +  6'd87  && hc ==  6'd452 ) || (vc == 400 +  6'd87  && hc ==  6'd453 ) || (vc == 400 +  6'd87  && hc ==  6'd454 ) || (vc == 400 +  6'd87  && hc ==  6'd455 ) || (vc == 400 +  6'd87  && hc ==  6'd456 ) || (vc == 400 +  6'd87  && hc ==  6'd457 ) || (vc == 400 +  6'd87  && hc ==  6'd458 ) || (vc == 400 +  6'd87  && hc ==  6'd459 ) || (vc == 400 +  6'd87  && hc ==  6'd460 ) || (vc == 400 +  6'd87  && hc ==  6'd461 ) || (vc == 400 +  6'd87  && hc ==  6'd462 ) || (vc == 400 +  6'd87  && hc ==  6'd463 ) || (vc == 400 +  6'd87  && hc ==  6'd464 ) || (vc == 400 +  6'd87  && hc ==  6'd465 ) || (vc == 400 +  6'd87  && hc ==  6'd466 ) || (vc == 400 +  6'd87  && hc ==  6'd467 ) || (vc == 400 +  6'd87  && hc ==  6'd468 ) || (vc == 400 +  6'd87  && hc ==  6'd469 ) || (vc == 400 +  6'd87  && hc ==  6'd470 ) || (vc == 400 +  6'd87  && hc ==  6'd471 ) || (vc == 400 +  6'd87  && hc ==  6'd472 ) || (vc == 400 +  6'd87  && hc ==  6'd473 ) || (vc == 400 +  6'd87  && hc ==  6'd474 ) || (vc == 400 +  6'd87  && hc ==  6'd475 ) || (vc == 400 +  6'd87  && hc ==  6'd476 ) || (vc == 400 +  6'd87  && hc ==  6'd477 ) || (vc == 400 +  6'd87  && hc ==  6'd478 ) || (vc == 400 +  6'd87  && hc ==  6'd479 ) || (vc == 400 +  6'd87  && hc ==  6'd480 ) || (vc == 400 +  6'd87  && hc ==  6'd481 ) || (vc == 400 +  6'd87  && hc ==  6'd482 ) || (vc == 400 +  6'd87  && hc ==  6'd483 ) || (vc == 400 +  6'd87  && hc ==  6'd484 ) || (vc == 400 +  6'd87  && hc ==  6'd485 ) || (vc == 400 +  6'd87  && hc ==  6'd486 ) || (vc == 400 +  6'd87  && hc ==  6'd487 ) || (vc == 400 +  6'd87  && hc ==  6'd488 ) || (vc == 400 +  6'd87  && hc ==  6'd489 ) || (vc == 400 +  6'd87  && hc ==  6'd490 ) || (vc == 400 +  6'd87  && hc ==  6'd491 ) || (vc == 400 +  6'd87  && hc ==  6'd492 ) || (vc == 400 +  6'd87  && hc ==  6'd493 ) || (vc == 400 +  6'd87  && hc ==  6'd494 ) || (vc == 400 +  6'd87  && hc ==  6'd495 ) || (vc == 400 +  6'd87  && hc ==  6'd496 ) || (vc == 400 +  6'd87  && hc ==  6'd497 ) || (vc == 400 +  6'd87  && hc ==  6'd498 ) || (vc == 400 +  6'd87  && hc ==  6'd499 ) || (vc == 400 +  6'd87  && hc ==  6'd500 ) || (vc == 400 +  6'd87  && hc ==  6'd501 ) || (vc == 400 +  6'd87  && hc ==  6'd502 ) || (vc == 400 +  6'd87  && hc ==  6'd503 ) || (vc == 400 +  6'd87  && hc ==  6'd504 ) || (vc == 400 +  6'd87  && hc ==  6'd505 ) || (vc == 400 +  6'd87  && hc ==  6'd506 ) || (vc == 400 +  6'd87  && hc ==  6'd507 ) || (vc == 400 +  6'd87  && hc ==  6'd508 ) || (vc == 400 +  6'd87  && hc ==  6'd509 ) || (vc == 400 +  6'd87  && hc ==  6'd510 ) || (vc == 400 +  6'd87  && hc ==  6'd511 ) || (vc == 400 +  6'd87  && hc ==  6'd512 ) || (vc == 400 +  6'd87  && hc ==  6'd513 ) || (vc == 400 +  6'd87  && hc ==  6'd514 ) || (vc == 400 +  6'd87  && hc ==  6'd515 ) || (vc == 400 +  6'd87  && hc ==  6'd516 ) || (vc == 400 +  6'd87  && hc ==  6'd517 ) || (vc == 400 +  6'd87  && hc ==  6'd518 ) || (vc == 400 +  6'd87  && hc ==  6'd519 ) || (vc == 400 +  6'd87  && hc ==  6'd520 ) || (vc == 400 +  6'd87  && hc ==  6'd521 ) || (vc == 400 +  6'd87  && hc ==  6'd522 ) || (vc == 400 +  6'd87  && hc ==  6'd523 ) || (vc == 400 +  6'd87  && hc ==  6'd524 ) || (vc == 400 +  6'd87  && hc ==  6'd525 ) || (vc == 400 +  6'd87  && hc ==  6'd526 ) || (vc == 400 +  6'd87  && hc ==  6'd527 ) || (vc == 400 +  6'd87  && hc ==  6'd528 ) || (vc == 400 +  6'd87  && hc ==  6'd529 ) || (vc == 400 +  6'd87  && hc ==  6'd530 ) || (vc == 400 +  6'd87  && hc ==  6'd531 ) || (vc == 400 +  6'd87  && hc ==  6'd532 ) || (vc == 400 +  6'd87  && hc ==  6'd533 ) || (vc == 400 +  6'd87  && hc ==  6'd534 ) || (vc == 400 +  6'd87  && hc ==  6'd535 ) || (vc == 400 +  6'd87  && hc ==  6'd536) || (vc == 400 +  6'd87  && hc ==  6'd537 ) || (vc == 400 +  6'd87  && hc ==  6'd538 ) || (vc == 400 +  6'd87  && hc ==  6'd539 ) || (vc == 400 +  6'd87  && hc ==  6'd540 ) || (vc == 400 +  6'd87  && hc ==  6'd541 ) || (vc == 400 +  6'd87  && hc ==  6'd542 ) || (vc == 400 +  6'd87  && hc ==  6'd543 ) || (vc == 400 +  6'd87  && hc ==  6'd544 ) || (vc == 400 +  6'd87  && hc ==  6'd545 ) || (vc == 400 +  6'd87  && hc ==  6'd546 ) || (vc == 400 +  6'd87  && hc ==  6'd547 ) || (vc == 400 +  6'd87  && hc ==  6'd548 ) || (vc == 400 +  6'd87  && hc ==  6'd549 ) || (vc == 400 +  6'd87  && hc ==  6'd550 ) || (vc == 400 +  6'd87  && hc ==  6'd551 ) || (vc == 400 +  6'd87  && hc ==  6'd552 ) || (vc == 400 +  6'd87  && hc ==  6'd553 ) || (vc == 400 +  6'd87  && hc ==  6'd554 ) || (vc == 400 +  6'd87  && hc ==  6'd555 ) || (vc == 400 +  6'd87  && hc ==  6'd556 ) || (vc == 400 +  6'd87  && hc ==  6'd557 ) || (vc == 400 +  6'd87  && hc ==  6'd558 ) || (vc == 400 +  6'd87  && hc ==  6'd559 ) || (vc == 400 +  6'd87  && hc ==  6'd560 ) || (vc == 400 +  6'd87  && hc ==  6'd561 ) || (vc == 400 +  6'd87  && hc ==  6'd562 ) || (vc == 400 +  6'd87  && hc ==  6'd563 ) || (vc == 400 +  6'd87  && hc ==  6'd564 ) || (vc == 400 +  6'd87  && hc ==  6'd565 ) || (vc == 400 +  6'd87  && hc ==  6'd566 ) || (vc == 400 +  6'd87  && hc ==  6'd567 ) || (vc == 400 +  6'd87  && hc ==  6'd568 ) || (vc == 400 +  6'd87  && hc ==  6'd569 ) || (vc == 400 +  6'd87  && hc ==  6'd570 ) || (vc == 400 +  6'd87  && hc ==  6'd571 ) || (vc == 400 +  6'd87  && hc ==  6'd572 ) || (vc == 400 +  6'd87  && hc ==  6'd573 ) || (vc == 400 +  6'd87  && hc ==  6'd574 ) || (vc == 400 +  6'd87  && hc ==  6'd575 ) || (vc == 400 +  6'd87  && hc ==  6'd576 ) || (vc == 400 +  6'd87  && hc ==  6'd577 ) || (vc == 400 +  6'd87  && hc ==  6'd578 ) || (vc == 400 +  6'd87  && hc ==  6'd579 ) || (vc == 400 +  6'd87  && hc ==  6'd580 ) || (vc == 400 +  6'd87  && hc ==  6'd581 ) || (vc == 400 +  6'd87  && hc ==  6'd582 ) || (vc == 400 +  6'd87  && hc ==  6'd583 ) || (vc == 400 +  6'd87  && hc ==  6'd584 ) || (vc == 400 +  6'd87  && hc ==  6'd585 ) || (vc == 400 +  6'd87  && hc ==  6'd586 ) || (vc == 400 +  6'd87  && hc ==  6'd587 ) || (vc == 400 +  6'd87  && hc ==  6'd588 ) || (vc == 400 +  6'd87  && hc ==  6'd589 ) || (vc == 400 +  6'd87  && hc ==  6'd590 ) || (vc == 400 +  6'd87  && hc ==  6'd591 ) || (vc == 400 +  6'd87  && hc ==  6'd592 ) || (vc == 400 +  6'd87  && hc ==  6'd593 ) || (vc == 400 +  6'd87  && hc ==  6'd594 ) || (vc == 400 +  6'd87  && hc ==  6'd595 ) || (vc == 400 +  6'd87  && hc ==  6'd596 ) || (vc == 400 +  6'd87  && hc ==  6'd597 ) || (vc == 400 +  6'd87  && hc ==  6'd598 ) || (vc == 400 +  6'd87  && hc ==  6'd599 ) || (vc == 400 +  6'd87  && hc ==  6'd600 ) || (vc == 400 +  6'd87  && hc ==  6'd601 ) || (vc == 400 +  6'd87  && hc ==  6'd602 ) || (vc == 400 +  6'd87  && hc ==  6'd603 ) || (vc == 400 +  6'd87  && hc ==  6'd604 ) || (vc == 400 +  6'd87  && hc ==  6'd605 ) || (vc == 400 +  6'd87  && hc ==  6'd606 ) || (vc == 400 +  6'd87  && hc ==  6'd607 ) || (vc == 400 +  6'd87  && hc ==  6'd608 ) || (vc == 400 +  6'd87  && hc ==  6'd609 ) || (vc == 400 +  6'd87  && hc ==  6'd610 ) || (vc == 400 +  6'd87  && hc ==  6'd611 ) || (vc == 400 +  6'd87  && hc ==  6'd612 ) || (vc == 400 +  6'd87  && hc ==  6'd613 ) || (vc == 400 +  6'd87  && hc ==  6'd614 ) || (vc == 400 +  6'd87  && hc ==  6'd615 ) || (vc == 400 +  6'd87  && hc ==  6'd616 ) || (vc == 400 +  6'd87  && hc ==  6'd617 ) || (vc == 400 +  6'd87  && hc ==  6'd618 ) || (vc == 400 +  6'd87  && hc ==  6'd619 ) || (vc == 400 +  6'd87  && hc ==  6'd620 ) || (vc == 400 +  6'd87  && hc ==  6'd621 ) || (vc == 400 +  6'd87  && hc ==  6'd622 ) || (vc == 400 +  6'd87  && hc ==  6'd623 ) || (vc == 400 +  6'd87  && hc ==  6'd624 ) || (vc == 400 +  6'd87  && hc ==  6'd625 ) || (vc == 400 +  6'd87  && hc ==  6'd626 ) || (vc == 400 +  6'd87  && hc ==  6'd627 ) || (vc == 400 +  6'd87  && hc ==  6'd628 ) || (vc == 400 +  6'd87  && hc ==  6'd629 ) || (vc == 400 +  6'd87  && hc ==  6'd630 ) || (vc == 400 +  6'd87  && hc ==  6'd631 ) || (vc == 400 +  6'd87  && hc ==  6'd632 ) || (vc == 400 +  6'd87  && hc ==  6'd633 ) || (vc == 400 +  6'd87  && hc ==  6'd634 ) || (vc == 400 +  6'd87  && hc ==  6'd635 ) || (vc == 400 +  6'd87  && hc ==  6'd636 ) || (vc == 400 +  6'd87  && hc ==  6'd637 ) || (vc == 400 +  6'd87  && hc ==  6'd638 ) || (vc == 400 +  6'd87  && hc ==  6'd639 ) || (vc == 400 +  6'd92  && hc ==  6'd77 ) || (vc == 400 +  6'd92  && hc ==  6'd78 ) || (vc == 400 +  6'd92  && hc ==  6'd79 ) || (vc == 400 +  6'd92  && hc ==  6'd80 ) || (vc == 400 +  6'd92  && hc ==  6'd81 ) || (vc == 400 +  6'd92  && hc ==  6'd82 ) || (vc == 400 +  6'd92  && hc ==  6'd83 ) || (vc == 400 +  6'd92  && hc ==  6'd217 ) || (vc == 400 +  6'd92  && hc ==  6'd218 ) || (vc == 400 +  6'd92  && hc ==  6'd219 ) || (vc == 400 +  6'd92  && hc ==  6'd220 ) || (vc == 400 +  6'd92  && hc ==  6'd221 ) || (vc == 400 +  6'd92  && hc ==  6'd222 ) || (vc == 400 +  6'd92  && hc ==  6'd455 ) || (vc == 400 +  6'd92  && hc ==  6'd456 ) || (vc == 400 +  6'd92  && hc ==  6'd457 ) || (vc == 400 +  6'd92  && hc ==  6'd458 ) || (vc == 400 +  6'd92  && hc ==  6'd459 ) || (vc == 400 +  6'd92  && hc ==  6'd460 ) || (vc == 400 +  6'd92  && hc ==  6'd461 ) || (vc == 400 +  6'd92  && hc ==  6'd462 ) || (vc == 400 +  6'd93  && hc ==  6'd77 ) || (vc == 400 +  6'd93  && hc ==  6'd78 ) || (vc == 400 +  6'd93  && hc ==  6'd79 ) || (vc == 400 +  6'd93  && hc ==  6'd80 ) || (vc == 400 +  6'd93  && hc ==  6'd81 ) || (vc == 400 +  6'd93  && hc ==  6'd82 ) || (vc == 400 +  6'd93  && hc ==  6'd83 ) || (vc == 400 +  6'd93  && hc ==  6'd218 ) || (vc == 400 +  6'd93  && hc ==  6'd219 ) || (vc == 400 +  6'd93  && hc ==  6'd220 ) || (vc == 400 +  6'd93  && hc ==  6'd221 ) || (vc == 400 +  6'd93  && hc ==  6'd222 ) || (vc == 400 +  6'd93  && hc ==  6'd455 ) || (vc == 400 +  6'd93  && hc ==  6'd456 ) || (vc == 400 +  6'd93  && hc ==  6'd457 ) || (vc == 400 +  6'd93  && hc ==  6'd458 ) || (vc == 400 +  6'd93  && hc ==  6'd459 ) || (vc == 400 +  6'd93  && hc ==  6'd460 ) || (vc == 400 +  6'd93  && hc ==  6'd461 ) || (vc == 400 +  6'd93  && hc ==  6'd462 ) || (vc == 400 +  6'd94  && hc ==  6'd135 ) || (vc == 400 +  6'd94  && hc ==  6'd136 ) || (vc == 400 +  6'd94  && hc ==  6'd137 ) || (vc == 400 +  6'd94  && hc ==  6'd138 ) || (vc == 400 +  6'd94  && hc ==  6'd197 ) || (vc == 400 +  6'd94  && hc ==  6'd198 ) || (vc == 400 +  6'd94  && hc ==  6'd255 ) || (vc == 400 +  6'd94  && hc ==  6'd256 ) || (vc == 400 +  6'd94  && hc ==  6'd395 ) || (vc == 400 +  6'd94  && hc ==  6'd396 ) || (vc == 400 +  6'd94  && hc ==  6'd397 ) || (vc == 400 +  6'd94  && hc ==  6'd398 ) || (vc == 400 +  6'd94  && hc ==  6'd472 ) || (vc == 400 +  6'd94  && hc ==  6'd473 ) || (vc == 400 +  6'd94  && hc ==  6'd508 ) || (vc == 400 +  6'd94  && hc ==  6'd509 ) || (vc == 400 +  6'd94  && hc ==  6'd510 ) || (vc == 400 +  6'd94  && hc ==  6'd511 ) || (vc == 400 +  6'd94  && hc ==  6'd512 ) || (vc == 400 +  6'd94  && hc ==  6'd513 ) || (vc == 400 +  6'd94  && hc ==  6'd615 ) || (vc == 400 +  6'd94  && hc ==  6'd616 ) || (vc == 400 +  6'd94  && hc ==  6'd617 ) || (vc == 400 +  6'd94  && hc ==  6'd618 ) || (vc == 400 +  6'd94  && hc ==  6'd619 ) || (vc == 400 +  6'd95  && hc ==  6'd135 ) || (vc == 400 +  6'd95  && hc ==  6'd136 ) || (vc == 400 +  6'd95  && hc ==  6'd137 ) || (vc == 400 +  6'd95  && hc ==  6'd138 ) || (vc == 400 +  6'd95  && hc ==  6'd197 ) || (vc == 400 +  6'd95  && hc ==  6'd255 ) || (vc == 400 +  6'd95  && hc ==  6'd396 ) || (vc == 400 +  6'd95  && hc ==  6'd397 ) || (vc == 400 +  6'd95  && hc ==  6'd398 ) || (vc == 400 +  6'd95  && hc ==  6'd472 ) || (vc == 400 +  6'd95  && hc ==  6'd473 ) || (vc == 400 +  6'd95  && hc ==  6'd508 ) || (vc == 400 +  6'd95  && hc ==  6'd509 ) || (vc == 400 +  6'd95  && hc ==  6'd510 ) || (vc == 400 +  6'd95  && hc ==  6'd511 ) || (vc == 400 +  6'd95  && hc ==  6'd512 ) || (vc == 400 +  6'd95  && hc ==  6'd615 ) || (vc == 400 +  6'd95  && hc ==  6'd616 ) || (vc == 400 +  6'd95  && hc ==  6'd617 ) || (vc == 400 +  6'd95  && hc ==  6'd618 ) || (vc == 400 +  6'd95  && hc ==  6'd619 ) || (vc == 400 +  6'd96  && hc ==  6'd227 ) || (vc == 400 +  6'd96  && hc ==  6'd228 ) || (vc == 400 +  6'd96  && hc ==  6'd354 ) || (vc == 400 +  6'd96  && hc ==  6'd355 ) || (vc == 400 +  6'd96  && hc ==  6'd562 ) || (vc == 400 +  6'd96  && hc ==  6'd563 ) || (vc == 400 +  6'd96  && hc ==  6'd564 ) || (vc == 400 +  6'd96  && hc ==  6'd565 ) || (vc == 400 +  6'd97  && hc ==  6'd227 ) || (vc == 400 +  6'd97  && hc ==  6'd355 ) || (vc == 400 +  6'd97  && hc ==  6'd563 ) || (vc == 400 +  6'd97  && hc ==  6'd564 ) || (vc == 400 +  6'd98  && hc ==  6'd51 ) || (vc == 400 +  6'd98  && hc ==  6'd52 ) || (vc == 400 +  6'd98  && hc ==  6'd53 ) || (vc == 400 +  6'd98  && hc ==  6'd127 ) || (vc == 400 +  6'd98  && hc ==  6'd128 ) || (vc == 400 +  6'd98  && hc ==  6'd146 ) || (vc == 400 +  6'd98  && hc ==  6'd147 ) || (vc == 400 +  6'd98  && hc ==  6'd148 ) || (vc == 400 +  6'd98  && hc ==  6'd149 ) || (vc == 400 +  6'd98  && hc ==  6'd150 ) || (vc == 400 +  6'd98  && hc ==  6'd151 ) || (vc == 400 +  6'd98  && hc ==  6'd285 ) || (vc == 400 +  6'd98  && hc ==  6'd286 ) || (vc == 400 +  6'd98  && hc ==  6'd292 ) || (vc == 400 +  6'd98  && hc ==  6'd293 ) || (vc == 400 +  6'd98  && hc ==  6'd294 ) || (vc == 400 +  6'd98  && hc ==  6'd295 ) || (vc == 400 +  6'd98  && hc ==  6'd322 ) || (vc == 400 +  6'd98  && hc ==  6'd323 ) || (vc == 400 +  6'd98  && hc ==  6'd324 ) || (vc == 400 +  6'd98  && hc ==  6'd325 ) || (vc == 400 +  6'd98  && hc ==  6'd326 ) || (vc == 400 +  6'd98  && hc ==  6'd327 ) || (vc == 400 +  6'd99  && hc ==  6'd23 ) || (vc == 400 +  6'd99  && hc ==  6'd285 ) || (vc == 400 +  6'd99  && hc ==  6'd422 ) || (vc == 400 +  6'd99  && hc ==  6'd426 ) || (vc == 400 +  6'd99  && hc ==  6'd574 ) || (vc == 400 +  6'd99  && hc ==  6'd577 ) || (vc == 400 +  6'd99  && hc ==  6'd580 ) || (vc == 400 +  6'd99  && hc ==  6'd596 ) || (vc == 400 +  6'd100  && hc ==  6'd22 ) || (vc == 400 +  6'd100  && hc ==  6'd23 ) || (vc == 400 +  6'd100  && hc ==  6'd422 ) || (vc == 400 +  6'd100  && hc ==  6'd423 ) || (vc == 400 +  6'd100  && hc ==  6'd424 ) || (vc == 400 +  6'd100  && hc ==  6'd425 ) || (vc == 400 +  6'd100  && hc ==  6'd426 ) || (vc == 400 +  6'd100  && hc ==  6'd573 ) || (vc == 400 +  6'd100  && hc ==  6'd574 ) || (vc == 400 +  6'd100  && hc ==  6'd575 ) || (vc == 400 +  6'd100  && hc ==  6'd576 ) || (vc == 400 +  6'd100  && hc ==  6'd577 ) || (vc == 400 +  6'd100  && hc ==  6'd578 ) || (vc == 400 +  6'd100  && hc ==  6'd579 ) || (vc == 400 +  6'd100  && hc ==  6'd580 ) || (vc == 400 +  6'd100  && hc ==  6'd596 ) || (vc == 400 +  6'd100  && hc ==  6'd597 ))
		begin
			red = 3'b111;
			green = 3'b111;
			blue = 2'b11;
		end
		for(i = 0; i < numAliens; i = i + 1)
		begin
				if((hc > alienPosXArray[i] + 1 &&  hc <  alienPosXArray[i] + 9   &&
				  vc <  alienPosYArray[i] - 1  &&  vc >  alienPosYArray[i] - 6   &&
				!(vc == alienPosYArray[i] - 4  && (hc == alienPosXArray[i] + 3  ||  hc == alienPosXArray[i] + 7 ))) ||
				((hc == alienPosXArray[i]      ||  hc == alienPosXArray[i] + 10)&& (vc <  alienPosYArray[i] && vc > alienPosYArray[i] - 4)) ||
				((hc == alienPosXArray[i] + 1  ||  hc == alienPosXArray[i] + 9) && (vc == alienPosYArray[i] - 3 || vc == alienPosYArray[i] - 4)) ||
				 (hc >  alienPosXArray[i] + 2  &&  hc <  alienPosXArray[i] + 8  &&  hc != alienPosXArray[i] + 5  && vc == alienPosYArray[i]) ||
				 ((hc == alienPosXArray[i] + 2  || hc == alienPosXArray[i] + 8)  &&  vc == alienPosYArray[i] - 1) ||
				 ((hc == alienPosXArray[i] + 3  || hc == alienPosXArray[i] + 7) && vc == alienPosYArray[i] - 6 ))
				
				begin
					red = 3'b111;
					green = 3'b111;
					blue = 2'b11;
				end
			end
		
	end
	// we're outside active vertical range so display black
	else
	begin
		red = 3'b000;
		green = 3'b000;
		blue = 2'b00;
	end
	
end

endmodule
