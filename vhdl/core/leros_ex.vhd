--
--  Copyright 2011 Martin Schoeberl <masca@imm.dtu.dk>,
--                 Technical University of Denmark, DTU Informatics. 
--  All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
-- 
--    1. Redistributions of source code must retain the above copyright notice,
--       this list of conditions and the following disclaimer.
-- 
--    2. Redistributions in binary form must reproduce the above copyright
--       notice, this list of conditions and the following disclaimer in the
--       documentation and/or other materials provided with the distribution.
-- 
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER ``AS IS'' AND ANY EXPRESS
-- OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
-- OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN
-- NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
-- DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
-- ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
-- THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-- 
-- The views and conclusions contained in the software and documentation are
-- those of the authors and should not be interpreted as representing official
-- policies, either expressed or implied, of the copyright holder.
-- 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.leros_types.all;

-- Some fmax number with Cyclone EP1C12C6
--
--	Memory is with rdaddr in clock process, rddata combinational
--		which is the 'normal' memory configuration, but Quartus
--		adds path through logic for read during write
--	fully registered on-chip memory 256 MHz
--	only input registers, output goes to a LC register (with reset): 165 MHz
--	plus a 16-bit adder: 147 MHz
--	more in ALU + opd mux: 135 MHz
--
--	Memory with rddata in clock process, rdaddr combinational
--		what does this model in read during write? Probably the
--		old value.
--	only input registers, output goes to a LC register (with reset): 256 MHz
--	plus a 16-bit adder: 166 MHz
--	more in ALU (add/sub) and opd mux between imm and DM output: 148 MHz


entity leros_ex is
	port  (
		clk : in std_logic;
		reset : in std_logic;
		din : in fedec_out_type;
		ioin : in io_in_type;
		dout : out ex_out_type;
		dcache_in : in dm_cache_in_type;
		dcache_out : out dm_cache_out_type
	);
end leros_ex;

architecture rtl of leros_ex is

	-- the accu
	signal accu, opd  : unsigned(31 downto 0);
	signal log, arith, a_mux : unsigned (31 downto 0);
	
	signal wrdata, rddata : std_logic_vector(31 downto 0);
	signal wraddr, rdaddr : std_logic_vector(DM_BITS-1 downto 0);
	
	signal wraddr_dly : std_logic_vector(DM_BITS-1 downto 0);
	signal pc_dly : std_logic_vector(IM_BITS-1 downto 0);
	
	signal rdaddr_indr, wraddr_indr : std_logic;
	signal zf : std_logic;
	
begin

	dout.accu <= std_logic_vector(accu) after 100 ps;
	dout.dm_data <= rddata after 100 ps;
	dout.zf <= zf after 100 ps;
	rdaddr <= din.dm_addr after 100 ps;
	
	--TODO: pretty sure this is all wrong. dec is cycle delayed decode
	rdaddr_indr <= din.decode.indls and not din.decode.store after 100 ps;
	-- address for the write needs one cycle delay
	wraddr <= wraddr_dly after 100 ps;
	wraddr_indr <= din.dec.indls and din.dec.store  after 100 ps;
	
--todo add high word	
process(din, rddata)
begin
	if din.dec.sel_imm='1' then
		opd <= unsigned(din.imm) after 100 ps;
	else
		-- a MUX for IO will be added
		opd <= unsigned(rddata) after 100 ps;
	end if;
end process;

-- that's the ALU	
process(din, accu, opd, log, arith, ioin)
begin
	if din.dec.add_sub='0' then
		arith <= accu + opd after 100 ps;
	else
		arith <= accu - opd after 100 ps;
	end if;

	if din.dec.op = op_ld or din.dec.loadhl = '1' or din.dec.loadhh = '1' then
			log <= opd after 100 ps;
	elsif din.dec.op = op_and then
			log <= accu and opd after 100 ps;
	elsif din.dec.op = op_or then
			log <= accu or opd after 100 ps;
	else
			log <= accu xor opd after 100 ps;
	end if;
	
	if din.dec.log_add='0' then
		if din.dec.shr='1' then
			a_mux <= '0' & accu(31 downto 1) after 100 ps;
		else
			if din.dec.inp='1' then
				a_mux <= unsigned(ioin.rddata) after 100 ps;
			else
				a_mux <= log after 100 ps;
			end if;
		end if;
	else
		a_mux <= arith after 100 ps;
	end if;
		
end process;

-- a MUX between 'normal' data and the PC for jal
process(din, accu, pc_dly)
begin
	if din.dec.jal='1' then
		wrdata(IM_BITS-1 downto 0) <= pc_dly after 100 ps;
		wrdata(31 downto IM_BITS) <= (others => '0') after 100 ps;
	else
		wrdata <= std_logic_vector(accu) after 100 ps;
	end if;
end process;	


process(clk, reset)
begin
	if reset='1' then
		accu <= (others => '0');
--		dout.outp <= (others => '0');
	elsif rising_edge(clk) then
		if din.valid = '1' then
			if din.dec.al_ena = '1' then
				accu(7 downto 0) <= a_mux(7 downto 0) after 100 ps;
			end if;
			if din.dec.ah_ena = '1' then
				accu(15 downto 8) <= a_mux(15 downto 8) after 100 ps;
			end if;
			if din.dec.ahl_ena = '1' then
				accu(23 downto 16) <= a_mux(23 downto 16) after 100 ps;
			end if;
			if din.dec.ahh_ena = '1' then
				accu(31 downto 24) <= a_mux(31 downto 24) after 100 ps;
			end if;
			wraddr_dly <= din.dm_addr after 100 ps;
			pc_dly <= din.pc after 100 ps;
			if unsigned(a_mux(15 downto 0)) = 0 then
				zf <= '1' after 100 ps;
			else
				zf <= '0' after 100 ps;
			end if;
				-- a simple output port for the hello world example
	--		if din.dec.outp='1' then
	--			dout.outp <= std_logic_vector(accu);
	--		end if;
		end if;
	end if;
end process;

	dcache: entity work.leros_dcache port map(
		clk, reset, din.valid, din.dec.store,wraddr,rdaddr,wraddr_indr,rdaddr_indr,wrdata,rddata,dout.dmiss,dcache_in,dcache_out
	);

	
end rtl;