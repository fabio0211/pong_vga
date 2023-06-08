library IEEE;
use IEEE.std_logic_1164.all;

entity seven_segment is
	port( input: in integer range 0 to 9;
			seg_out: out std_logic_vector (7 downto 0));
end seven_segment;

architecture sev_seg of seven_segment is
signal yt: std_logic_vector(7 downto 0);
	begin
			process (input)
				begin 
						case input is
						when 0 => yt <= "00111111";
						when 1 => yt <= "00000110";
						when 2 => yt <= "01011011";
						when 3 => yt <= "01001111";
						when 4 => yt <= "01100110";
						when 5 => yt <= "01101101";
						when 6 => yt <= "01111101";
						when 7 => yt <= "00000111";
						when 8 => yt <= "01111111";
						when others =>yt <= "01110111";
						end case;
					end process;
					seg_out<= not yt;
				end sev_seg;
				
						