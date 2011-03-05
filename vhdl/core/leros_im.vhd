library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.leros_types.all;

-- instruction memory
-- write is ignored for now
-- the content should be generated by an assembler

entity leros_im is
	port  (
		clk : in std_logic;
		reset : in std_logic;
		din : in im_in_type;
		dout : out im_out_type
	);
end leros_im;

architecture rtl of leros_im is

	signal areg		: std_logic_vector(IM_BITS-1 downto 0);
	signal data		: std_logic_vector(15 downto 0);

begin

process(clk) begin

	if rising_edge(clk) then
		areg <= din.rdaddr;
	end if;

end process;

	dout.data <= data;
	
	rom: entity work.leros_rom port map(areg, data);
	
-- use generated table
-- process(areg) begin
-- 
-- 	case areg is
-- 
-- 		when X"00" => data <= X"0000"; -- never executed
-- 		when X"01" => data <= X"0805"; -- load imm
-- 		when X"02" => data <= X"0e01"; -- sub 1 
-- 		when X"03" => data <= X"0e01"; -- sub 1 
-- 		when X"04" => data <= X"f000"; -- nop
-- 		when X"05" => data <= X"10fe"; -- brnz
-- 		when X"06" => data <= X"f000"; -- nop
-- 		when X"07" => data <= X"0801"; -- load 1
-- 		when X"08" => data <= X"2000"; -- outp
-- 		when X"09" => data <= X"0805"; -- load imm
-- 		when X"0a" => data <= X"0e01"; -- sub 1 
-- 		when X"0b" => data <= X"0e01"; -- sub 1 
-- 		when X"0c" => data <= X"f000"; -- nop
-- 		when X"0d" => data <= X"10fe"; -- brnz
-- 		when X"0e" => data <= X"f000"; -- nop
-- 		when X"0f" => data <= X"0800"; -- load 0
-- 		when X"10" => data <= X"2000"; -- outp
-- 		when X"11" => data <= X"0801"; -- load imm
-- 		when X"12" => data <= X"f000"; -- nop
-- 		when X"13" => data <= X"10ee"; -- brnz
-- 		when others => data <= X"f000"; 
-- 	end case;
-- end process;

end rtl;