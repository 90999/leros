--
--  Copyright 2011 Martin Schoeberl <masca@imm.dtu.dk>,
--                 Technical University of Denmark, DTU Informatics. 
--  All rights reserved.
--
--  License: TBD, BSD style requested, decision pending.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.leros_types.all;

-- fetch and decode stage

entity leros_fedec is
	port  (
		clk : in std_logic;
		reset : in std_logic;
		din : in fedec_in_type;
		dout : out fedec_out_type
	);
end leros_fedec;

architecture rtl of leros_fedec is

	signal imin : im_in_type;
	signal imout : im_out_type;
	
	signal zf : std_logic;
	
	signal pc, pc_next : unsigned(IM_BITS-1 downto 0);
	signal decode : decode_type;

begin

	imin.rdaddr <= std_logic_vector(pc_next);
	
	im: entity work.leros_im port map(
		clk, reset, imin, imout
	);

	dec: entity work.leros_decode port map(
		imout.data(15 downto 8), decode
	);
	
-- DM address selection
process(decode, din, imout)
	variable addr : std_logic_vector(15 downto 0);
begin
	addr := std_logic_vector(unsigned(din.dm_data) + unsigned(imout.data(7 downto 0)));
	-- MUX for indirect load/store (from unregistered decode)
	if decode.indls='1' then
		dout.dm_addr <= addr(DM_BITS-1 downto 0);
	else
		-- If DM > 256 zero extend the varidx
		dout.dm_addr <= imout.data(DM_BITS-1 downto 0);
	end if;

end process;

-- branch 
process(din, decode, imout, pc, zf)
begin
	-- should be checked in ModelSim
	if unsigned(din.accu)=0 then
		zf <= '1';
	else
		zf <= '0';
	end if;
	
	-- shall we do the branch in the ex stage so
	-- we will have a real branch delay slot?
	-- branch
	pc_next <= pc+1;
	if decode.br_op='1' and zf='0' then
		-- now just do a bnz
		pc_next <= pc + unsigned(resize(signed(imout.data(7 downto 0)), IM_BITS));
	end if;
	
end process;
	
-- pc register
process(clk, reset)
begin
	if reset='1' then
		pc <= (others => '0');
	elsif rising_edge(clk) then
		pc <= pc_next;
		dout.dec <= decode;
--		if decode.add_sub='1' then
		-- sign extension depends on loadh?????
		if decode.loadh='1' then
			dout.imm(7 downto 0) <= (others => '0');
			dout.imm(15 downto 8) <= imout.data(7 downto 0);
		else
			dout.imm <= std_logic_vector(resize(signed(imout.data(7 downto 0)), 16));
		end if;
--		else
--			immr(7 downto 0) <= imout.data(7 downto 0);
--			immr(15 downto 0) <= (others => '0');
--		end if;
	end if;
end process;

end rtl;