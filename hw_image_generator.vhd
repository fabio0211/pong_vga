--------------------------------------------------------------------------------
--
--   FileName:         hw_image_generator.vhd
--   Dependencies:     none
--   Design Software:  Quartus II 64-bit Version 12.1 Build 177 SJ Full Version
--
--   HDL CODE IS PROVIDED "AS IS."  DIGI-KEY EXPRESSLY DISCLAIMS ANY
--   WARRANTY OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT NOT
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
--   PARTICULAR PURPOSE, OR NON-INFRINGEMENT. IN NO EVENT SHALL DIGI-KEY
--   BE LIABLE FOR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL
--   DAMAGES, LOST PROFITS OR LOST DATA, HARM TO YOUR EQUIPMENT, COST OF
--   PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY OR SERVICES, ANY CLAIMS
--   BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF),
--   ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION, OR OTHER SIMILAR COSTS.
--
--   Version History
--   Version 1.0 05/10/2013 Scott Larson
--     Initial Public Release
--    
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY hw_image_generator IS
  GENERIC(
    pixels_y :  INTEGER := 720;   
    pixels_x :  INTEGER := 450);  
  PORT(
	 clk, clk_adc, reset, start, restart: in std_logic; 
	 --joy: in std_logic_vector;
    disp_ena :  IN   STD_LOGIC;  --display enable ('1' = display time, '0' = blanking time)
    row      :  IN   INTEGER;    --row pixel coordinate
    column   :  IN   INTEGER;    --column pixel coordinate
    red      :  OUT  STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');  --red magnitude output to DAC
    green    :  OUT  STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');  --green magnitude output to DAC
    blue     :  OUT  STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0'); --blue magnitude output to DAC
	 HEX0_D : out std_logic_vector(7 downto 0); --porte display 7seg ------------aggiuunto
	 HEX3_D : out std_logic_vector(7 downto 0)); --porte display 7seg ------------aggiuunto
END hw_image_generator;

ARCHITECTURE behavior OF hw_image_generator IS
signal x1: integer:=pixels_x; 
signal y1:integer:= 20; --posizione orizzontale racchetta 1 
signal l: integer:= 15; --larghezza racchette
signal h: integer:=70; --altezza racchette
signal x2: integer:=pixels_x; 
signal y2:integer:= 1420; --posizione orizzontale racchetta 2 
signal xp: integer:=pixels_x; 
signal yp:integer:= pixels_y; 
signal r: integer:=10;
signal clk_i, rst: std_logic:='0'; 
signal counter: integer:=1; 
signal vx: integer:=5;
signal vy: integer:=5;
signal vr1: integer:=7;
signal vr2: integer:=7;
signal pt1, pt2: integer range 0 to 9:=0; --punteggio 
	signal joy1, joy2, ch2, ch3, ch4, ch5, ch6, ch7: std_logic_vector(11 downto 0);

	component unnamed is
	port (
		CLOCK : in  std_logic                     := '0'; --      clk.clk
		CH0   : out std_logic_vector(11 downto 0);        -- readings.CH0
		CH1   : out std_logic_vector(11 downto 0);        --         .CH1
		CH2   : out std_logic_vector(11 downto 0);        --         .CH2
		CH3   : out std_logic_vector(11 downto 0);        --         .CH3
		CH4   : out std_logic_vector(11 downto 0);        --         .CH4
		CH5   : out std_logic_vector(11 downto 0);        --         .CH5
		CH6   : out std_logic_vector(11 downto 0);        --         .CH6
		CH7   : out std_logic_vector(11 downto 0);        --         .CH7
		RESET : in  std_logic                     := '0'  --    reset.reset
	);
	end component unnamed;
	
	--7seg display
	component seven_segment is port( 
	 input: in integer range 0 to 9;
	 seg_out: out std_logic_vector (7 downto 0)
	 );
	 end component seven_segment;
	
BEGIN
    left_player_score_display  : seven_segment port map (pt1, HEX3_D); 
	 right_player_score_display : seven_segment port map (pt2, HEX0_D); 

	adc1: unnamed port map (clk_adc,joy1, joy2, ch2, ch3, ch4, ch5, ch6, ch7, reset);
	--clk divider 100hz
	process	(clk)
					begin
						if rising_edge(clk) then
							counter<=counter+1;
							if counter= 500000 then 
								clk_i<= not clk_i;
								counter<=1;
							end if;
						end if;
			end process; 

	--MOVIMENTO racchetta 1
	process(joy1, clk_i)
	begin
	if rising_edge(clk_i) then
	if (x1-h>20 and x1+h<880) then
		if (joy1 <="110111111111" and joy1>="000111111111") then 
		x1<=x1;
		vr1<=0;
		elsif (joy1 >"110111111111") 
		then x1<=x1-7;
		vr1<=-7;
		elsif (joy1<"000111111111") 
		then x1<=x1+7;
		vr1<=+7;
		end if;
		elsif (x1-h<=20) then x1<=x1+1;
		elsif (x1+h>=880) then x1<=x1-1;
		end if;
		end if;
	end process;

	--movimento racchetta 2
	process(joy2, clk_i)
	begin
	if rising_edge(clk_i) then
	if (x2-h>20 and x2+h<880) then
		if (joy2 <="110111111111" and joy2>="000111111111") then x2<=x2; 
		vr2<=0;
		elsif (joy2 >"110111111111") 
		then x2<=x2-7;
		vr2<=-7;
		elsif (joy2<"000111111111") 
		then x2<=x2+7;
		vr2<=+7;
		end if;
		elsif (x2-h<=20) then x2<=x2+1;
		elsif (x2+h>=880) then x2<=x2-1;
		end if; 
		end if;
	end process;
	
--disegno su schermo campo
	campo: process (disp_ena, row, column, start)
	begin
	IF(disp_ena = '1') THEN  
	--bordo campo
	if (row<=20 or row>=880) then
			red <= (OTHERS => '1');
        green  <= (OTHERS => '1');
        blue <= (OTHERS => '1');
		  	--palla ROSSA
			elsif (abs(row-xp)<r) and (abs(column-yp)<r) then
				red <= (OTHERS => '1');
				green  <= (OTHERS => '0');
				blue <= (OTHERS => '0');
				
				
				--pausa
		elsif ((column<=715 and column>=705)and(row>=430 and row<=470))then
			if (start='0')then 
					red <= (OTHERS => '1');
					green  <= (OTHERS => '1');
					blue <= (OTHERS => '1');
				end if;
					elsif ((column<=735 and column>=725)and(row>=430 and row<=470))then
			if (start='0')then 
					red <= (OTHERS => '1');
					green  <= (OTHERS => '1');
					blue <= (OTHERS => '1');
				end if;
									
					
			--racchetta 1
			elsif(abs(row-x1)<h AND abs(column-y1)<l) THEN
				red <= (OTHERS => '0');
				green  <= (OTHERS => '1');
				blue <= (OTHERS => '0');
				--racchetta 2
		  elsif(abs(row-x2)<h AND abs(column-y2)<l) THEN
				red <= (OTHERS => '1');
				green  <= (OTHERS => '1');
				blue <= (OTHERS => '0');
			
		  ELSE
				red <= (OTHERS => '0');
				green  <= (OTHERS => '0');
				blue <= (OTHERS => '0');
		end if;
	end if;
	end process campo;
	
	
	--posizione palla
	process(clk_i,rst, start, restart)
	begin
	
	if(rising_edge(clk_i)and(start='1')) then
		if ((rst='1')and(restart='1')) then
			vx<=5;
			vy<=5;
			pt1<=0;
			pt2<=0;
			rst<='0';
		 else 
		xp<=xp+vy;
		yp<=yp+vx;
		
		if(xp+r<=880 and xp-r>=20) then
			--rst<='0';
			--palla tocca racchetta1
			if(yp-r=35)and(xp<x1+h and xp>x1-h) then
			vy<=vy+vr1;
			vx<=-vx;
			yp<=yp+3*abs(vx);
			--palla tocca racchetta2
			elsif(yp+r=1405)and(xp<x2+h and xp>x2-h) then
			vy<=vy+vr2;
			vx<=-vx;
			yp<=yp-3*abs(vx);
			--punto a g2
			--elsif(yp-r<35)and(xp-r>x1+h or xp+r<x1-h) then
			elsif(yp-r<20) then
			if(pt2<3) then ------------aggiuunto
			pt2<=pt2+1;
			--rst<='1';
			xp<=pixels_x;
			yp<=pixels_y;
			vx<=5;
			vy<=5;
			else rst<='1';
			xp<=pixels_x;
			yp<=pixels_y;
					vx<=0;
					vy<=0;
			end if;
			--punto a g1
			--elsif(yp+r>1405)and(xp-r>x2+h or xp+r<x2-h) then
			elsif(yp+r>1420)then
			if(pt1<3) then ------------aggiuunto
			pt1<=pt1+1;
			--rst<='1';
			xp<=pixels_x;
			yp<=pixels_y;
			vx<=-5;
			vy<=5;
			else rst<='1';
					xp<=pixels_x;
					yp<=pixels_y;
					vx<=0;
					vy<=0;
			end if;
			end if;
		else
			vy<=-vy;
			if(xp-r<=20) then xp<=xp+abs(vy);
			elsif(xp+r>=880) then xp<=xp-abs(vy);
			end if;
			end if;
			end if;
		end if;
			end process;	
			
	

END behavior;