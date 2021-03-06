/* This is an example of how to create animation using the VGA Adapter designed for the DE2 board.
 *
 * This circuit takes four images from memory (stored in animation.mif), where each image is one frame
 * of the animation. The circuit then draws one of these images on the screen such that the top left corner of the image
 * is located at (x_current, y_current). After an image is drawn it is erased and redrawn in a new location
 * by changing x_current and y_current. When the coordiantes of the top left corner are changed the
 * image to be drawn also changes, thus creating an animation.
 *
 * The input to this circuit are a 50MHz clock, called CLOCK_50, and an asynchronous reset, called resetN.
 * The outputs are x,y,color and write_En which indicate when and where to draw a pixel on the screen. These
 * outputs should be directly connected to the VGAAdapter.
 *
 * FSM Author: Tomasz Czajkowski
 * Date: November 27, 2006.
 */

module test_plotting(CLOCK_50, resetN, collision, x, y, color, write_En,negx,negy,posx,posy,backspace,score,test,lives_lost);
	parameter IMAGE_WIDTH = 5'd16;
	parameter IMAGE_WIDTH_COUNTER_BITS = 4;
	parameter IMAGE_HEIGHT = 5'd16;
	parameter IMAGE_HEIGHT_COUNTER_BITS = 4;
	parameter BITS_TO_ADDRESS_IMAGE = 8;
	parameter SCREEN_WIDTH = 8'd160;
	parameter SCREEN_HEIGHT = 7'd120;
	parameter IMAGE_ID_BITS = 2; 
	parameter IMAGE_FROG = "frog.mif";
	parameter IMAGE_CAR = "car.mif";
	parameter IMAGE_SCORE1 = "score1.mif";
	parameter IMAGE_SCORE2 = "score2.mif";
	parameter IMAGE_SCORE3 = "score3.mif";
	parameter IMAGE_LIVES = "lives.mif";
	input CLOCK_50;
	input resetN;
	input negx, negy;
	input posx, posy;
	input backspace;
	output reg [7:0] x;
	output reg [6:0] y;
	output reg [2:0] color;
	output write_En;
	output wire collision;
	output [3:0] score;
	output [1:0] lives_lost;
	output test;
	
	
	/*************************************************************/
	/*** DECLARE LOCAL WIRES *************************************/
	/*************************************************************/
	wire	gnd;
	wire	[2:0] mem_out_frog;
	wire    [2:0] mem_out_car;
	wire    [2:0] mem_out_score1;
	wire    [2:0] mem_out_score2;
	wire    [2:0] mem_out_score3;
	wire    [2:0] lives;
	wire	[2:0] black_color;
	wire    [2:0] red_color;
	wire    [2:0] green_color;
	wire	[BITS_TO_ADDRESS_IMAGE+IMAGE_ID_BITS-1:0] mem_address_frog;
	wire	[BITS_TO_ADDRESS_IMAGE+IMAGE_ID_BITS-1:0] mem_address_car;
	wire	[BITS_TO_ADDRESS_IMAGE+IMAGE_ID_BITS-1:0] mem_address_score1;
	wire	[BITS_TO_ADDRESS_IMAGE+IMAGE_ID_BITS-1:0] mem_address_score2;
	wire	[BITS_TO_ADDRESS_IMAGE+IMAGE_ID_BITS-1:0] mem_address_score3;
	wire	[BITS_TO_ADDRESS_IMAGE+IMAGE_ID_BITS-1:0] mem_address_lives;
	wire	[IMAGE_WIDTH_COUNTER_BITS - 1:0] x_counter;		// Frog
	wire	[IMAGE_HEIGHT_COUNTER_BITS - 1:0] y_counter;
	wire	[IMAGE_WIDTH_COUNTER_BITS - 1:0] x_counter1;	// Column 1
	wire	[IMAGE_HEIGHT_COUNTER_BITS - 1:0] y_counter1;
	wire	[IMAGE_WIDTH_COUNTER_BITS - 1:0] x_counter2;	// Column 2
	wire	[IMAGE_HEIGHT_COUNTER_BITS - 1:0] y_counter2;
	wire	[IMAGE_WIDTH_COUNTER_BITS - 1:0] x_counter3;
	wire	[IMAGE_HEIGHT_COUNTER_BITS - 1:0] y_counter3;
	wire	[IMAGE_WIDTH_COUNTER_BITS - 1:0] x_counter4;
	wire	[IMAGE_HEIGHT_COUNTER_BITS - 1:0] y_counter4;
	wire	enable_x, enable_y;
	wire enable_x1, enable_y1;
	wire enable_x2, enable_y2;
	wire enable_x3, enable_y3;
	wire enable_x4, enable_y4;
	wire	[7:0] x_current;	// Frog
	wire	[6:0] y_current;
	wire	[7:0] x_current1;	// Speed 1
	wire	[6:0] y_current1;
	wire	[7:0] x_current2;	// Speed 2
	wire	[6:0] y_current2;
	wire	[7:0] x_current3;	// Speed 3
	wire	[6:0] y_current3;
	wire	[7:0] x_current4;	// Speed 4
	wire	[6:0] y_current4;
	wire	enable_regs;
	wire	add_x;	// Frog
	wire	add_y;
	wire	add_x1;	// Speed 1
	wire	add_y1;
	wire	add_x2;	// Speed 2
	wire	add_y2;
	wire	add_x3;	// Speed 2
	wire	add_y3;
	wire	add_x4;	// Speed 2
	wire	add_y4;
	wire	toggle_x_dir, toggle_y_dir, enable_loc, erase;
	wire toggle_x_dir1, toggle_y_dir1, enable_loc1, erase1;
	wire toggle_x_dir2, toggle_y_dir2, enable_loc2, erase2;
	wire toggle_x_dir3, toggle_y_dir3, enable_loc3, erase3;
	wire toggle_x_dir4, toggle_y_dir4, enable_loc4, erase4;
	wire write_En1;	// Dummy wire
	wire write_En2;	// Dummy wire
	wire write_En3;	// Dummy wire
	wire write_En4;	// Dummy wire
	wire	[BITS_TO_ADDRESS_IMAGE-1:0] img_offset;
	wire	[BITS_TO_ADDRESS_IMAGE-1:0] img_offset1;
	wire	[BITS_TO_ADDRESS_IMAGE-1:0] img_offset_score1;
	wire	[BITS_TO_ADDRESS_IMAGE-1:0] img_offset_score2;
	wire	[BITS_TO_ADDRESS_IMAGE-1:0] img_offset_score3;
	wire	[BITS_TO_ADDRESS_IMAGE-1:0] img_offset_lives;
	
	
	/* These determines the new location of the top left corner of the image */
	reg		[7:0] new_x;	// Frog
	reg		[6:0] new_y;
	reg		[7:0] new_x1;	// Speed 1
	reg		[6:0] new_y1;
	reg		[7:0] new_x2;	// Speed 2
	reg		[6:0] new_y2;	
	reg		[7:0] new_x3;	// Speed 3
	reg		[6:0] new_y3;
	reg		[7:0] new_x4;	// Speed 4
	reg		[6:0] new_y4;
		
	/* This determines which image to draw. If you want to slow down the animation simply
	 * add a few bits to this set of wires. */
	reg		[IMAGE_ID_BITS-1:0] img_to_show;
	reg		[IMAGE_ID_BITS-1:0] img_to_show1;
	reg		[IMAGE_ID_BITS-1:0] img_to_show_score1; // determines which score to display
	reg		[IMAGE_ID_BITS-1:0] img_to_show_score2;
	reg		[IMAGE_ID_BITS-1:0] img_to_show_score3;
	reg		[IMAGE_ID_BITS-1:0] img_to_show_lives;

	/* The gnd signal is used as input to the WriteEnable port of memory. It is set to 0 so that the animation
	 * images are not altered. */
	assign	gnd = 1'b0;
	
	/* This a signal that defines black color, used when erasing the image.*/
	assign	black_color = 3'b000;
	assign	red_color = 3'b100;
	assign green_color = 3'b010;

	/*************************/
	/* Test Circuit Datapath */
	/*************************/
	
	/* First create RAM to store the animation. Have it initialized with the data describing 4 frames of the animation. */
	lpm_ram_dq my_ram_frog(.inclock(CLOCK_50), .outclock(CLOCK_50), .data(black_color),
						.address(mem_address_frog), .we(gnd), .q(mem_out_frog) );
		defparam my_ram_frog.LPM_FILE = IMAGE_FROG;
		defparam my_ram_frog.LPM_WIDTH = 3;
		defparam my_ram_frog.LPM_WIDTHAD = BITS_TO_ADDRESS_IMAGE+IMAGE_ID_BITS;
		defparam my_ram_frog.LPM_INDATA = "REGISTERED";
		defparam my_ram_frog.LPM_ADDRESS_CONTROL = "REGISTERED";
		defparam my_ram_frog.LPM_OUTDATA = "REGISTERED";

	lpm_ram_dq my_ram_car(.inclock(CLOCK_50), .outclock(CLOCK_50), .data(black_color),
						.address(mem_address_car), .we(gnd), .q(mem_out_car) );
		defparam my_ram_car.LPM_FILE = IMAGE_CAR;
		defparam my_ram_car.LPM_WIDTH = 3;
		defparam my_ram_car.LPM_WIDTHAD = BITS_TO_ADDRESS_IMAGE+IMAGE_ID_BITS;
		defparam my_ram_car.LPM_INDATA = "REGISTERED";
		defparam my_ram_car.LPM_ADDRESS_CONTROL = "REGISTERED";
		defparam my_ram_car.LPM_OUTDATA = "REGISTERED";
		
	lpm_ram_dq my_ram_score1(.inclock(CLOCK_50), .outclock(CLOCK_50), .data(black_color),
							 .address(mem_address_score1), .we(gnd), .q(mem_out_score1) );
		defparam my_ram_score1.LPM_FILE = IMAGE_SCORE1;
		defparam my_ram_score1.LPM_WIDTH = 3;
		defparam my_ram_score1.LPM_WIDTHAD = BITS_TO_ADDRESS_IMAGE+IMAGE_ID_BITS;
		defparam my_ram_score1.LPM_INDATA = "REGISTERED";
		defparam my_ram_score1.LPM_ADDRESS_CONTROL = "REGISTERED";
		defparam my_ram_score1.LPM_OUTDATA = "REGISTERED";
	
	lpm_ram_dq my_ram_score2(.inclock(CLOCK_50), .outclock(CLOCK_50), .data(black_color),
							 .address(mem_address_score2), .we(gnd), .q(mem_out_score2) );
		defparam my_ram_score2.LPM_FILE = IMAGE_SCORE2;
		defparam my_ram_score2.LPM_WIDTH = 3;
		defparam my_ram_score2.LPM_WIDTHAD = BITS_TO_ADDRESS_IMAGE+IMAGE_ID_BITS;
		defparam my_ram_score2.LPM_INDATA = "REGISTERED";
		defparam my_ram_score2.LPM_ADDRESS_CONTROL = "REGISTERED";
		defparam my_ram_score2.LPM_OUTDATA = "REGISTERED";
		
	lpm_ram_dq my_ram_score3(.inclock(CLOCK_50), .outclock(CLOCK_50), .data(black_color),
							 .address(mem_address_score3), .we(gnd), .q(mem_out_score3) );
		defparam my_ram_score3.LPM_FILE = IMAGE_SCORE3;
		defparam my_ram_score3.LPM_WIDTH = 3;
		defparam my_ram_score3.LPM_WIDTHAD = BITS_TO_ADDRESS_IMAGE+IMAGE_ID_BITS;
		defparam my_ram_score3.LPM_INDATA = "REGISTERED";
		defparam my_ram_score3.LPM_ADDRESS_CONTROL = "REGISTERED";
		defparam my_ram_score3.LPM_OUTDATA = "REGISTERED";
	
	lpm_ram_dq my_ram_lives(.inclock(CLOCK_50), .outclock(CLOCK_50), .data(black_color),
							 .address(mem_address_lives), .we(gnd), .q(mem_out_lives) );
		defparam my_ram_lives.LPM_FILE = IMAGE_LIVES;
		defparam my_ram_lives.LPM_WIDTH = 3;
		defparam my_ram_lives.LPM_WIDTHAD = BITS_TO_ADDRESS_IMAGE+IMAGE_ID_BITS;
		defparam my_ram_lives.LPM_INDATA = "REGISTERED";
		defparam my_ram_lives.LPM_ADDRESS_CONTROL = "REGISTERED";
		defparam my_ram_lives.LPM_OUTDATA = "REGISTERED";
				
	/* Create address for memory access */
	/* First define which image to draw, indicies 0-3. */
	assign mem_address_frog[BITS_TO_ADDRESS_IMAGE+IMAGE_ID_BITS -1 : BITS_TO_ADDRESS_IMAGE] = img_to_show;
	assign mem_address_car[BITS_TO_ADDRESS_IMAGE+IMAGE_ID_BITS -1 : BITS_TO_ADDRESS_IMAGE] = img_to_show1;
	assign mem_address_score1[BITS_TO_ADDRESS_IMAGE+IMAGE_ID_BITS -1 : BITS_TO_ADDRESS_IMAGE] = img_to_show_score1;
	assign mem_address_score2[BITS_TO_ADDRESS_IMAGE+IMAGE_ID_BITS -1 : BITS_TO_ADDRESS_IMAGE] = img_to_show_score2;
	assign mem_address_score3[BITS_TO_ADDRESS_IMAGE+IMAGE_ID_BITS -1 : BITS_TO_ADDRESS_IMAGE] = img_to_show_score3;
	assign mem_address_lives[BITS_TO_ADDRESS_IMAGE+IMAGE_ID_BITS -1 : BITS_TO_ADDRESS_IMAGE] = img_to_show_lives;
	
	/* Then compute which pixel out of an image to draw.*/
	assign img_offset = y_counter*IMAGE_WIDTH + x_counter;
	assign img_offset1 = y_counter1*IMAGE_WIDTH + x_counter1;
	assign img_offset_score1 = y_counter*IMAGE_WIDTH + x_counter;
	assign img_offset_score2 = y_counter*IMAGE_WIDTH + x_counter;
	assign img_offset_score3 = y_counter*IMAGE_WIDTH + x_counter;
	assign img_offset_lives = y_counter*IMAGE_WIDTH + x_counter;
	assign mem_address_frog[BITS_TO_ADDRESS_IMAGE-1:0] = img_offset;
	assign mem_address_car[BITS_TO_ADDRESS_IMAGE-1:0] = img_offset1;
	assign mem_address_score1[BITS_TO_ADDRESS_IMAGE-1:0] = img_offset_score1;
	assign mem_address_score2[BITS_TO_ADDRESS_IMAGE-1:0] = img_offset_score2;
	assign mem_address_score3[BITS_TO_ADDRESS_IMAGE-1:0] = img_offset_score3;
	assign mem_address_lives[BITS_TO_ADDRESS_IMAGE-1:0] = img_offset_lives;

	/* Create counters to index a particular pixel out of an animation image.
	 * Have them reset when they reach the end of the image line. */
	counter counter_x(.clock(CLOCK_50), .enable(enable_x), .resetN(resetN), .q(x_counter));
		defparam counter_x.WIDTH = IMAGE_WIDTH_COUNTER_BITS;
		defparam counter_x.RESET_VALUE = IMAGE_WIDTH;
	counter counter_y(.clock(CLOCK_50), .enable(enable_y), .resetN(resetN), .q(y_counter));
		defparam counter_y.WIDTH = IMAGE_HEIGHT_COUNTER_BITS;
		defparam counter_y.RESET_VALUE = IMAGE_HEIGHT;
	
	counter counter_x1(.clock(CLOCK_50), .enable(enable_x1), .resetN(resetN), .q(x_counter1));
		defparam counter_x1.WIDTH = IMAGE_WIDTH_COUNTER_BITS;
		defparam counter_x1.RESET_VALUE = IMAGE_WIDTH;
	counter counter_y1(.clock(CLOCK_50), .enable(enable_y1), .resetN(resetN), .q(y_counter1));
		defparam counter_y1.WIDTH = IMAGE_HEIGHT_COUNTER_BITS;
		defparam counter_y1.RESET_VALUE = IMAGE_HEIGHT;	
		
	counter counter_x2(.clock(CLOCK_50), .enable(enable_x2), .resetN(resetN), .q(x_counter2));
		defparam counter_x2.WIDTH = IMAGE_WIDTH_COUNTER_BITS;
		defparam counter_x2.RESET_VALUE = IMAGE_WIDTH;
	counter counter_y2(.clock(CLOCK_50), .enable(enable_y2), .resetN(resetN), .q(y_counter2));
		defparam counter_y2.WIDTH = IMAGE_HEIGHT_COUNTER_BITS;
		defparam counter_y2.RESET_VALUE = IMAGE_HEIGHT;	
		
	counter counter_x3(.clock(CLOCK_50), .enable(enable_x3), .resetN(resetN), .q(x_counter3));
		defparam counter_x3.WIDTH = IMAGE_WIDTH_COUNTER_BITS;
		defparam counter_x3.RESET_VALUE = IMAGE_WIDTH;
	counter counter_y3(.clock(CLOCK_50), .enable(enable_y3), .resetN(resetN), .q(y_counter3));
		defparam counter_y3.WIDTH = IMAGE_HEIGHT_COUNTER_BITS;
		defparam counter_y3.RESET_VALUE = IMAGE_HEIGHT;	
		
	counter counter_x4(.clock(CLOCK_50), .enable(enable_x4), .resetN(resetN), .q(x_counter4));
		defparam counter_x4.WIDTH = IMAGE_WIDTH_COUNTER_BITS;
		defparam counter_x4.RESET_VALUE = IMAGE_WIDTH;
	counter counter_y4(.clock(CLOCK_50), .enable(enable_y4), .resetN(resetN), .q(y_counter4));
		defparam counter_y4.WIDTH = IMAGE_HEIGHT_COUNTER_BITS;
		defparam counter_y4.RESET_VALUE = IMAGE_HEIGHT;			
	
		
	
	/* Create a register to store the current location of the top left corner of the image being moved around. 
	 */
	my_reg current_x(.d(new_x), .clock(CLOCK_50), .enable(enable_loc), .resetN(resetN), .q(x_current));
		defparam current_x.WIDTH = 8;
	my_reg current_y(.d(new_y), .clock(CLOCK_50), .enable(enable_loc), .resetN(resetN), .q(y_current));
		defparam current_y.WIDTH = 7;
		
	my_reg current_x1(.d(new_x1), .clock(CLOCK_50), .enable(enable_loc1), .resetN(resetN), .q(x_current1));
		defparam current_x1.WIDTH = 8;
	my_reg current_y1(.d(new_y1), .clock(CLOCK_50), .enable(enable_loc1), .resetN(resetN), .q(y_current1));
		defparam current_y1.WIDTH = 7;	
	
	my_reg current_x2(.d(new_x2), .clock(CLOCK_50), .enable(enable_loc2), .resetN(resetN), .q(x_current2));
		defparam current_x2.WIDTH = 8;
	my_reg current_y2(.d(new_y2), .clock(CLOCK_50), .enable(enable_loc2), .resetN(resetN), .q(y_current2));
		defparam current_y2.WIDTH = 7;	
	
	my_reg current_x3(.d(new_x3), .clock(CLOCK_50), .enable(enable_loc), .resetN(resetN), .q(x_current3));
		defparam current_x3.WIDTH = 8;
	my_reg current_y3(.d(new_y3), .clock(CLOCK_50), .enable(enable_loc), .resetN(resetN), .q(y_current3));
		defparam current_y3.WIDTH = 7;	
	
	my_reg current_x4(.d(new_x4), .clock(CLOCK_50), .enable(enable_loc), .resetN(resetN), .q(x_current4));
		defparam current_x2.WIDTH = 8;	
	my_reg current_y4(.d(new_y4), .clock(CLOCK_50), .enable(enable_loc), .resetN(resetN), .q(y_current4));
		defparam current_y4.WIDTH = 7;			


/*fsm for frogger movement*/

parameter A=3'b000,U=3'b001,D=3'b010,R=3'b100,L=3'b101,COLLISION=3'b111,X=3'b110;
reg [2:0] NS,CS;
reg addy,addx,neg,GAME_OVER;
reg collision_reset;//this will reset the position of the frog when it hits something
reg [1:0] lives_lost;
reg [3:0] score;
reg score_increase;
reg lives_decrease;
//up, down ,right will depend on the keyboard input
//checcking for collision will depend on the vga position


always @ (*)
begin
	case (CS)
	A:
	begin
		if(!backspace)NS<=X;
		else if(score == 12) NS <= X;
		else if(lives_lost == 2'b11) NS<=X;
		else if(collision) NS<=COLLISION;// check for collision and do the necessary next steps
		else if(!posy) NS<=U;
		else if(!negy) NS<=D;
		else if(!negx) NS<=L;
		else if(!posx) NS<=R;
		else NS<=A;
		addy<=1'b0;addx<=1'b0;neg<=1'b0;
		collision_reset<= 1'b0;
		lives_decrease<= 1'b0;
		GAME_OVER=1'b0;
	end
	U:
	begin
		addy<=1'b1;
		addx<=1'b0;
		neg<=1'b0;
		NS<=A;
		collision_reset<=1'b0;
		lives_decrease<= 1'b0;
		GAME_OVER=1'b0;
	end
	D:
	begin
		addy<=1'b1;
		addx<=1'b0;
		neg<=1'b1;
		NS<=A;
		collision_reset<=1'b0;
		lives_decrease<= 1'b0;
		GAME_OVER=1'b0;
	end
	R:
	begin
		addy<=1'b0;
		addx<=1'b1;
		neg<=1'b0;
		NS<=A;
		collision_reset<=1'b0;
		lives_decrease<= 1'b0;
		GAME_OVER=1'b0;
	end
	L:
	begin
		addy<=1'b0;
		addx<=1'b1;
		neg<=1'b1;
		NS<=A;
		collision_reset<=1'b0;
		lives_decrease<= 1'b0;
		GAME_OVER=1'b0;
	end
	COLLISION:
	begin
		addy<=1'b0;
		addx<=1'b0;
		neg<=1'b0;
		collision_reset<=1'b1;
		NS<=A;
		lives_decrease<= 1'b1;
		GAME_OVER=1'b0;
	end
	X:		//this state happens after the frog dies 3 times
	begin
		addy<=1'b0;
		addx<=1'b0;
		neg<=1'b0;
	    GAME_OVER=1'b1;
		NS <= A;
		collision_reset<=1'b1;
		lives_decrease<= 1'b0;
	end
	default
	begin
		NS<=A;
		addy<=1'b0;
		addx<=1'b0;
		neg<=1'b0;
		collision_reset<=1'b0;
		lives_decrease<= 1'b0;
		GAME_OVER=1'b0;
	end
	endcase
end


always @(posedge CLOCK_50)
	CS<=NS;
	
always @ (posedge score_increase or posedge GAME_OVER)
	if (GAME_OVER)
		begin
		score <= 1'b0;
		img_to_show_score1 = 1'b0;
		img_to_show_score2 = 1'b0;
		img_to_show_score3 = 1'b0;
		end
	else
		begin
		score <= score + 1'b1;
		if (score < 3)
		img_to_show_score1 = img_to_show_score1 + 1'b1;
		else if (score > 3 && score < 7)
		img_to_show_score2 = img_to_show_score2 + 1'b1;
		else if (score > 7 && score < 11)
		img_to_show_score3 = img_to_show_score3 + 1'b1;
		end
		
always @ (negedge tmp or posedge GAME_OVER)
	if(GAME_OVER)
		begin
		lives_lost<= 1'b0;
		img_to_show = + 1'b0;
		img_to_show_lives = 1'b0;
		end
	else
		begin
		img_to_show = img_to_show + 1'b1;
		lives_lost <= lives_lost + 1'b1;
		img_to_show_lives = img_to_show_lives + 1'b1;
		end

	


/*end of fsm for frogger*/

	/* Create adders to change (x_current,y_current) */
	
	/* Adders which control frog location */
	always @(*)
	begin
		if(collision_reset)
			begin
			score_increase <= 1'b0;
			new_x<= 0;
			end
		else if (x_current == 8'd160)
			begin
			score_increase <= 1'b1;
			new_x <= x_current + 3'b100;
			end
		else if (neg == 1 && x_current != 0 && addx==1 && x_current < 144)//(add_x == 1'b0)
			begin
			score_increase <= 1'b0;
			new_x <= x_current - 3'b100;//posx;
			end
		else if( neg==0 && addx==1)
			begin
			score_increase <= 1'b0;
			new_x <= x_current + 3'b100;
			end
		else
			begin
			score_increase <= 1'b0;
			new_x<=x_current;	
			end
	end
	reg tmp;
	always @(*)
	begin
		if(collision_reset)
			begin
			new_y<= 53;
			tmp <= 1'b0;
			end
		else if (y_current == 53)
			begin
			new_y <= 52;
			if (GAME_OVER)
				tmp <= 1'b0;
			else
				tmp <= 1'b1;
			end
		else if (neg == 0 && addy == 1)
			begin
			new_y <= y_current - 3'b100;
			tmp <= 1'b0;
			end
		else if(neg==1 && addy==1)
			begin
			new_y <= y_current + 3'b100;
			tmp <= 1'b0;
			end
		else
		begin
			tmp <= 1'b0;
			new_y <= y_current;
		end
	end
	
	/* Adders which control car/truck location/speed */
	
	always @(posedge CLOCK_50)
	begin
		new_x1 <= 0;
		if (GAME_OVER)
		new_y1 = 0;
		else if (score < 7)
		new_y1 <= y_current1 + 2'b01;
		else
		new_y1 <= y_current1 + 2'b10;
		
	end
	
	always @(posedge CLOCK_50)
	begin
		new_x2 <= 0;
		if (GAME_OVER)
		new_y2 = 0;
		else if (score < 5)
		new_y2 <= y_current2 + 2'b01;
		else
		new_y2 <= y_current2 + 2'b10;
	end
	
	always @(posedge CLOCK_50)
	begin
		new_x3 <= 0;
		if (GAME_OVER)
		new_y3 = 0;
		else if (score < 10)
			new_y3 <= y_current3 + 1'b1;
		else 
			new_y3 <= y_current3 + 2'b10;
	end
	
	always @(posedge CLOCK_50)
	begin
		new_x4 <= 0;
		if (GAME_OVER)
		new_y4 = 0;
		else if (score <3)
		new_y4 <= y_current4 + 2'b01;
		else if (score <10)
		new_y4 <= y_current4 + 2'b10;
		else if (score <11)
		new_y4 <= y_current4 + 3'b100;
		else
		new_y4 <= y_current4 + 2'b11;
	end

	function hit_detection;
		input integer x;
		input integer y;
		input [7:0] xcur;
		input [6:0] ycur;
		input [7:0] xcur1;
		input [6:0] ycur1;
		
		if (xcur < x + 16 && xcur + 16 > x)
			begin
				if ( ycur1 + y <= 111 && ycur < ycur1 + y + 16 && ycur + 16 > ycur1 + y ||
					 ycur1 + y > 111 && ycur < ycur1 + y - 120 + 9 && ycur + 16 > ycur1 + y - 120)
					hit_detection = 1;
				else
					hit_detection = 0;
			end
		else
		    hit_detection = 0;
	endfunction 
	
	
	assign collision =(hit_detection(18,0,x_current, y_current, x_current1, y_current1)|
					   hit_detection(34,0,x_current, y_current, x_current2, y_current2)|
					   hit_detection(34,40,x_current, y_current, x_current2, y_current2)|
					   hit_detection(90,60,x_current, y_current, x_current3, y_current3)| 
					   hit_detection(108,0,x_current, y_current, x_current4, y_current4)| 
					   hit_detection(108,18,x_current, y_current, x_current4, y_current4)| 
					   hit_detection(108,36,x_current, y_current, x_current4, y_current4));
		
	/* Create two T-Flip Flops to determine if the x/y coordinate should be increased or decreased by one
	 * the next time x_current, y_current are changed. Signals toggle_x_dir, toggle_y_dir will become 1
	 * for one clock cycle and will cause the state of the add_x, add_y FFs to toggle. When add_x is 0 x_current will
	 * increment, otherwise it will decrement. Similarly, when add_y is 0 y_current will
	 * increment, otherwise it will decrement.
	 */
	my_reg direction_x_t_FF(.d(~add_x), .clock(CLOCK_50), .enable(toggle_x_dir), .resetN(resetN), .q(add_x));
		defparam direction_x_t_FF.WIDTH = 1;
	my_reg direction_y_t_FF(.d(~add_y), .clock(CLOCK_50), .enable(toggle_y_dir), .resetN(resetN), .q(add_y));
		defparam direction_y_t_FF.WIDTH = 1;
		
	my_reg direction_x_t_FF1(.d(~add_x1), .clock(CLOCK_50), .enable(toggle_x_dir1), .resetN(resetN), .q(add_x1));
		defparam direction_x_t_FF1.WIDTH = 1;
	my_reg direction_y_t_FF1(.d(~add_y1), .clock(CLOCK_50), .enable(toggle_y_dir1), .resetN(resetN), .q(add_y1));
		defparam direction_y_t_FF1.WIDTH = 1;	
		
	my_reg direction_x_t_FF2(.d(~add_x2), .clock(CLOCK_50), .enable(toggle_x_dir2), .resetN(resetN), .q(add_x2));
		defparam direction_x_t_FF2.WIDTH = 1;
	my_reg direction_y_t_FF2(.d(~add_y2), .clock(CLOCK_50), .enable(toggle_y_dir2), .resetN(resetN), .q(add_y2));
		defparam direction_y_t_FF2.WIDTH = 1;	
		
	my_reg direction_x_t_FF3(.d(~add_x3), .clock(CLOCK_50), .enable(toggle_x_dir3), .resetN(resetN), .q(add_x3));
		defparam direction_x_t_FF3.WIDTH = 1;
	my_reg direction_y_t_FF3(.d(~add_y3), .clock(CLOCK_50), .enable(toggle_y_dir3), .resetN(resetN), .q(add_y3));
		defparam direction_y_t_FF3.WIDTH = 1;	
		
	my_reg direction_x_t_FF4(.d(~add_x4), .clock(CLOCK_50), .enable(toggle_x_dir4), .resetN(resetN), .q(add_x4));
		defparam direction_x_t_FF4.WIDTH = 1;
	my_reg direction_y_t_FF4(.d(~add_y4), .clock(CLOCK_50), .enable(toggle_y_dir4), .resetN(resetN), .q(add_y4));
		defparam direction_y_t_FF4.WIDTH = 1;			

	
	/*******************************************/
	/* Create the FSM to control this circuit. */
	/*******************************************/
	fsm my_fsm(	.clock(CLOCK_50), .resetN(resetN), .x_dir(add_x), .y_dir(add_y),
		.x_origin(x_current), .y_origin(y_current), .x_subimage(x_counter), .y_subimage(y_counter),
		.change_x_dir(toggle_x_dir), .change_y_dir(toggle_y_dir),
		.enable_x(enable_x), .enable_y(enable_y), .enable_loc(enable_loc),
		.plot_dot(write_En), .erase(erase));
		defparam my_fsm.IMAGE_WIDTH = IMAGE_WIDTH;
		defparam my_fsm.IMAGE_HEIGHT = IMAGE_HEIGHT;
		defparam my_fsm.IMAGE_WIDTH_COUNTER_BITS = IMAGE_WIDTH_COUNTER_BITS;
		defparam my_fsm.IMAGE_HEIGHT_COUNTER_BITS = IMAGE_HEIGHT_COUNTER_BITS;
		defparam my_fsm.SCREEN_WIDTH = SCREEN_WIDTH;
		defparam my_fsm.SCREEN_HEIGHT = SCREEN_HEIGHT;
	
	fsm my_fsm1(.clock(CLOCK_50), .resetN(resetN), .x_dir(add_x1), .y_dir(add_y1),
		.x_origin(x_current1), .y_origin(y_current1), .x_subimage(x_counter1), .y_subimage(y_counter1),
		.change_x_dir(toggle_x_dir1), .change_y_dir(toggle_y_dir1),
		.enable_x(enable_x1), .enable_y(enable_y1), .enable_loc(enable_loc1),
		.plot_dot(write_En1), .erase(erase1));
		defparam my_fsm1.IMAGE_WIDTH = IMAGE_WIDTH;
		defparam my_fsm1.IMAGE_HEIGHT = IMAGE_HEIGHT;
		defparam my_fsm1.IMAGE_WIDTH_COUNTER_BITS = IMAGE_WIDTH_COUNTER_BITS;
		defparam my_fsm1.IMAGE_HEIGHT_COUNTER_BITS = IMAGE_HEIGHT_COUNTER_BITS;
		defparam my_fsm1.SCREEN_WIDTH = SCREEN_WIDTH;
		defparam my_fsm1.SCREEN_HEIGHT = SCREEN_HEIGHT;	
		
	fsm my_fsm2(.clock(CLOCK_50), .resetN(resetN), .x_dir(add_x2), .y_dir(add_y2),
		.x_origin(x_current2), .y_origin(y_current2), .x_subimage(x_counter2), .y_subimage(y_counter2),
		.change_x_dir(toggle_x_dir2), .change_y_dir(toggle_y_dir2),
		.enable_x(enable_x2), .enable_y(enable_y2), .enable_loc(enable_loc2),
		.plot_dot(write_En2), .erase(erase2));
		defparam my_fsm2.IMAGE_WIDTH = IMAGE_WIDTH;
		defparam my_fsm2.IMAGE_HEIGHT = IMAGE_HEIGHT;
		defparam my_fsm2.IMAGE_WIDTH_COUNTER_BITS = IMAGE_WIDTH_COUNTER_BITS;
		defparam my_fsm2.IMAGE_HEIGHT_COUNTER_BITS = IMAGE_HEIGHT_COUNTER_BITS;
		defparam my_fsm2.SCREEN_WIDTH = SCREEN_WIDTH;
		defparam my_fsm2.SCREEN_HEIGHT = SCREEN_HEIGHT;	
		
	fsm my_fsm3(.clock(CLOCK_50), .resetN(resetN), .x_dir(add_x3), .y_dir(add_y3),
		.x_origin(x_current3), .y_origin(y_current3), .x_subimage(x_counter3), .y_subimage(y_counter3),
		.change_x_dir(toggle_x_dir3), .change_y_dir(toggle_y_dir3),
		.enable_x(enable_x3), .enable_y(enable_y3), .enable_loc(enable_loc3),
		.plot_dot(write_En3), .erase(erase3));
		defparam my_fsm3.IMAGE_WIDTH = IMAGE_WIDTH;
		defparam my_fsm3.IMAGE_HEIGHT = IMAGE_HEIGHT;
		defparam my_fsm3.IMAGE_WIDTH_COUNTER_BITS = IMAGE_WIDTH_COUNTER_BITS;
		defparam my_fsm3.IMAGE_HEIGHT_COUNTER_BITS = IMAGE_HEIGHT_COUNTER_BITS;
		defparam my_fsm3.SCREEN_WIDTH = SCREEN_WIDTH;
		defparam my_fsm3.SCREEN_HEIGHT = SCREEN_HEIGHT;	
		
	fsm my_fsm4(.clock(CLOCK_50), .resetN(resetN), .x_dir(add_x4), .y_dir(add_y4),
		.x_origin(x_current4), .y_origin(y_current4), .x_subimage(x_counter4), .y_subimage(y_counter4),
		.change_x_dir(toggle_x_dir4), .change_y_dir(toggle_y_dir4),
		.enable_x(enable_x4), .enable_y(enable_y4), .enable_loc(enable_loc4),
		.plot_dot(write_En4), .erase(erase4));
		defparam my_fsm4.IMAGE_WIDTH = IMAGE_WIDTH;
		defparam my_fsm4.IMAGE_HEIGHT = IMAGE_HEIGHT;
		defparam my_fsm4.IMAGE_WIDTH_COUNTER_BITS = IMAGE_WIDTH_COUNTER_BITS;
		defparam my_fsm4.IMAGE_HEIGHT_COUNTER_BITS = IMAGE_HEIGHT_COUNTER_BITS;
		defparam my_fsm4.SCREEN_WIDTH = SCREEN_WIDTH;
		defparam my_fsm4.SCREEN_HEIGHT = SCREEN_HEIGHT;			
	/*******************************************/
	/* Create outputs for the circuit.         */
	/*******************************************/
	
	/* The color is either black, when the image is being erased, or corresponds to the color
	 * of the appropriate pixel as it read from memory. 
	 */
	 
	 reg [3:0] chk;
	 always @ (posedge CLOCK_50)
		begin
			if (chk == 0)
				begin
				x <= x_current + x_counter;
				y <= y_current + y_counter;
				color <= (erase == 1'b1) ? black_color : mem_out_frog;
				chk <= chk + 1;
				end
			else if (chk == 1)
				begin
				x <= x_current1 + x_counter1 + 18;
				y <= y_current1 + y_counter1 + 0;
				color <= (erase1 == 1'b1) ? black_color : mem_out_car;
				chk <= chk+1;
				end
			else if (chk == 2)
				begin
					x <= x_current2 + x_counter2 + 34;
					y <= y_current2 + y_counter2 + 0;
					color <= (erase1 == 1'b1) ? black_color : mem_out_car;
					chk <= chk + 1;
				end	
			else if (chk == 3)
				begin
					x <= x_current2 + x_counter2 + 34;
					y <= y_current2 + y_counter2 + 40;
					color <= (erase1 == 1'b1) ? black_color : mem_out_car;
					chk <= chk + 1;
				end		
			else if (chk == 4)
				begin
					x <= x_current3 + x_counter3 + 90;
					y <= y_current3 + y_counter3 + 60;
					color <= (erase2 == 1'b1) ? black_color : mem_out_car;
					chk <= chk + 1;
				end	
			else if (chk == 5)
				begin
					x <= x_current4 + x_counter4 + 108;
					y <= y_current4 + y_counter4 + 0;
					color <= (erase2 == 1'b1) ? black_color : mem_out_car;
					chk <= chk + 1;
				end	
			else if (chk == 6)
				begin
					x <= x_current4 + x_counter4 + 108;
					y <= y_current4 + y_counter4 + 18;
					color <= (erase2 == 1'b1) ? black_color : mem_out_car;
					chk <= chk + 1;
				end	
			else if (chk == 7)
				begin
					x <= x_current4 + x_counter4 + 108;
					y <= y_current4 + y_counter4 + 36;
					color <= (erase2 == 1'b1) ? black_color : mem_out_car;
					chk <= chk + 1;
				end		
			else if (chk == 8)
				begin
					x <= x_counter2 + 128;
					y <= y_counter2 + 2;
					if (score <= 3)
					color <= (erase2 == 1'b1) ? black_color : mem_out_score1;
					else if (score <= 7)
					color <= (erase2 == 1'b1) ? black_color : mem_out_score2;
					else if (score <= 11)
					color <= (erase2 == 1'b1) ? black_color : mem_out_score3;
					else
					color <= black_color;
					chk <= chk + 1;
				end	
			else if (chk == 9)
				begin
					x <= x_counter1 + 145;
					y <= y_counter1;
					color <= (erase2 == 1'b1) ? black_color : mem_out_lives;
					chk <= 0;
				end	
		end

endmodule


/*************************************************************************************************/
/** HERE IS THE FINITE STATE MACHINE FOR THE DESIGN **********************************************/
/*************************************************************************************************/
module fsm (clock, resetN, x_dir, y_dir, x_origin, y_origin, x_subimage, y_subimage, change_x_dir, change_y_dir, enable_x, enable_y, enable_loc, plot_dot, erase);
	parameter IMAGE_WIDTH = 16;
	parameter IMAGE_WIDTH_COUNTER_BITS = 4;
	parameter IMAGE_HEIGHT = 16;
	parameter IMAGE_HEIGHT_COUNTER_BITS = 4;
	parameter SCREEN_WIDTH = 160;
	parameter SCREEN_HEIGHT = 120;
	parameter DELAY_DURATION = 1000000;
	input clock;
	input resetN;
	input x_dir, y_dir;
	input [7:0] x_origin;
	input [6:0] y_origin;
	input [IMAGE_WIDTH_COUNTER_BITS-1:0] x_subimage;
	input [IMAGE_HEIGHT_COUNTER_BITS-1:0] y_subimage;

	output reg change_x_dir;
	output reg change_y_dir;
	output enable_x;
	output enable_y;
	output enable_loc;
	output plot_dot;
	output erase;

	reg [3:0] current_state;
	reg [3:0] next_state;
	reg erase_state;

	wire vcc;
	wire [19:0] delay_counter;

	parameter WAIT_STATE = 4'b0000;
	parameter MOVE_ORIGIN = 4'b0001;
	parameter WAIT_FIRST_CYCLE = 4'b010;
	parameter WAIT_SECOND_CYCLE = 4'b011;
	parameter WAIT_THIRD_CYCLE = 4'b0100;
	parameter WAIT_FOURTH_CYCLE = 4'b0101;
	parameter WAIT_FIFTH_CYCLE = 4'b0110;
	parameter WAIT_SIXTH_CYCLE = 4'b0111;
	parameter WAIT_SEVENTH_CYCLE = 4'b1000;
	parameter WAIT_EIGHTH_CYCLE = 4'b1001;
	parameter WAIT_NINTH_CYCLE = 4'b1010;
	parameter WAIT_TENTH_CYCLE = 4'b1011;
	parameter DRAW_DOT = 4'b1101;
	parameter INCREMENT_X = 4'b1110;
	parameter INCREMENT_Y = 4'b1111;

	assign vcc = 1'b1;

	/* Delay counter. Basically wait 1 million clock cycles before changing the image. This will make the
	 * dude move 50 times a second.
	 * To avoid flickering use VSYNC instead of this counter.
	 */
	counter delay(.clock(clock), .resetN(resetN), .enable(vcc), .q(delay_counter));
		defparam delay.WIDTH = 20;
		defparam delay.RESET_VALUE = DELAY_DURATION;

	/* State Transitions - The idea is to first erase the image, move the top-left corner (ie. origin)
	 * and then draw the image. To do this, we just draw the image twice, once with all black colour,
	 * the other time with the actual image from memory. */
	always @(current_state or resetN or delay_counter or x_subimage or y_subimage or erase_state)
	begin
		case (current_state)
			/* Reset state */
			WAIT_STATE: if (delay_counter == 1'b0)
						next_state <= WAIT_FIRST_CYCLE; 
					else
						next_state <= WAIT_STATE;

			/* Move the top left corner of the image. */
			MOVE_ORIGIN: next_state <= WAIT_FIRST_CYCLE;
			
			WAIT_FIRST_CYCLE: next_state <= WAIT_SECOND_CYCLE;
			WAIT_SECOND_CYCLE: next_state <= WAIT_THIRD_CYCLE;
			WAIT_THIRD_CYCLE: next_state <= WAIT_FOURTH_CYCLE;
			WAIT_FOURTH_CYCLE: next_state <= WAIT_FIFTH_CYCLE;
			WAIT_FIFTH_CYCLE: next_state <= WAIT_SIXTH_CYCLE;
			WAIT_SIXTH_CYCLE: next_state <= WAIT_SEVENTH_CYCLE;
			WAIT_SEVENTH_CYCLE: next_state <= WAIT_EIGHTH_CYCLE;
			WAIT_EIGHTH_CYCLE: next_state <= WAIT_NINTH_CYCLE;
			WAIT_NINTH_CYCLE: next_state <= WAIT_TENTH_CYCLE;
			WAIT_TENTH_CYCLE: next_state <= DRAW_DOT;
			DRAW_DOT: next_state <= INCREMENT_X;
			INCREMENT_X:	if (x_subimage == IMAGE_WIDTH - 1)
								next_state <= INCREMENT_Y;
							else
								next_state <= WAIT_FIRST_CYCLE;
			INCREMENT_Y:	if ((x_subimage == 'b0) && (y_subimage == IMAGE_HEIGHT - 1))
							begin
								if (erase_state == 1'b1)
								begin
									/* If I was erasing then move the origin and draw new image. */
									next_state = MOVE_ORIGIN;
								end
								else
								begin
									/* Otherwise go to the WAIT_STATE and hold until the next frame (approximately) */
									next_state <= WAIT_STATE;
								end
							end
							else
								next_state <= WAIT_FIRST_CYCLE;
			/* Other cases are don't cares. */
			default: next_state <= 3'bxxx;				
		endcase
	end

	/* State Variables */
	always @(posedge clock or negedge resetN)
	begin
		if (resetN == 1'b0)
			current_state <= WAIT_STATE;
		else
			current_state <= next_state;
	end

	/* Erase state */
	always @(posedge clock or negedge resetN)
	begin
		if (resetN == 1'b0)
			erase_state <= 1'b1;
		else
		begin
			if (current_state == MOVE_ORIGIN)
				erase_state <= 1'b0;
			else if (current_state == WAIT_STATE)
				erase_state <= 1'b1;
		end
	end

	/* Create State Outputs */
	always @(current_state or x_dir or y_dir or x_origin or y_origin)
	begin
		case (current_state)
			MOVE_ORIGIN:
				begin
					change_x_dir = 1'b0;
					change_y_dir = 1'b0;				
					if (x_dir == 1'b0)
					begin
						if (x_origin + IMAGE_WIDTH == SCREEN_WIDTH - 1)
							change_x_dir = 1'b1;
					end
					else
					begin
						if (x_origin == 8'd1)
							change_x_dir = 1'b1;
					end
					if (y_dir == 1'b0)
					begin
						if (y_origin + IMAGE_HEIGHT == SCREEN_HEIGHT - 1)
							change_y_dir = 1'b1;
					end
					else
					begin
						if (y_origin == 7'd1)
							change_y_dir = 1'b1;
					end
				end
			default: begin
					change_x_dir = 1'b0;
					change_y_dir = 1'b0;
				   end					
		endcase
	end

	assign plot_dot = 1; // (current_state == DRAW_DOT);
	assign enable_loc = (current_state == MOVE_ORIGIN);
	assign enable_x = (current_state == INCREMENT_X);
	assign enable_y = (current_state == INCREMENT_Y);
	assign erase = erase_state;
endmodule


/*****************************************************/
/** Here are some helper modules                    **/
/*****************************************************/
module counter(clock, enable, resetN, q);
	parameter WIDTH = 4;
	parameter RESET_VALUE = 8;

	input clock;
	input resetN;
	input enable;
	output [WIDTH-1:0]q;
	reg [WIDTH-1:0]q;

	always @(posedge clock or negedge resetN)
	begin
		if (resetN == 1'b0)
			q <= 'b0;
		else
		begin
			if (enable == 1'b1)
			begin
				if (q == RESET_VALUE - 1)
					q <= 'b0;
				else
					q <= q+1'b1;
			end
		end
	end
endmodule

module my_reg(d, clock, enable, resetN, q);
	parameter WIDTH = 4;

	input clock;
	input resetN;
	input enable;
	input [WIDTH-1:0]d;
	output [WIDTH-1:0]q;
	reg [WIDTH-1:0]q;

	always @(posedge clock or negedge resetN)
	begin
		if (resetN == 1'b0)
			q <= 'b0;
		else
		begin
			if (enable == 1'b1)
				q <= d;
		end
	end
endmodule
