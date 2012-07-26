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


--
--	leros_nexys2.vhd
--
--	top level for cycore borad with EP1C12
--
--	2011-02-20	creation
--
--


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.leros_types.all;

entity leros_nexys2 is
port (
	clk     : in std_logic;
	led     : out std_logic_vector(7 downto 0);
--	btn		: in std_logic_vector(3 downto 0);
--	rsrx	: in std_logic;
	rstx	: out std_logic;
	ser_txd : out std_logic;
	ser_rxd : in std_logic;
	icaddr : out std_logic_vector(IM_BITS downto 0);
	iclen : out std_logic_vector(5 downto 0);
	icreq : out std_logic;
	icrden : out std_logic;
	icdata : in std_logic_vector(31 downto 0);
	icempty : in std_logic
);
end leros_nexys2;

architecture rtl of leros_nexys2 is
   signal clk_int       : std_logic;

	signal int_res			: std_logic;
	signal res_cnt			: unsigned(2 downto 0) := "000";	-- for the simulation

	attribute altera_attribute : string;
	attribute altera_attribute of res_cnt : signal is "POWER_UP_LEVEL=LOW";

	signal ioout : io_out_type;
	signal ioin : io_in_type;
	
	signal outp 			: std_logic_vector(15 downto 0);
	
	signal icache_in : im_cache_in_type;
	signal icache_out : im_cache_out_type;
	
begin


	clk_int <= clk;
--
--	internal reset generation
--	should include the PLL lock signal
--

process(clk_int)
begin
	if rising_edge(clk_int) then
		if (res_cnt/="111") then
			res_cnt <= res_cnt+1 after 100 ps;
		end if;

		int_res <= not res_cnt(0) or not res_cnt(1) or not res_cnt(2) after 100 ps;
	end if;
end process;


	cpu: entity work.leros
		port map(clk_int, int_res, ioout, ioin, icache_in, icache_out);
		
	icaddr <= icache_out.addr;
	iclen <= icache_out.len;
	icreq <= icache_out.req;
	icrden <= icache_out.rden;
	icache_in.data <= icdata;
	icache_in.empty <= icempty;

	ua: entity work.uart generic map (
		clk_freq => 100000000,
		baud_rate => 11520000,
		txf_depth => 1,
		rxf_depth => 1
	)
	port map(
		clk => clk_int,
		reset => int_res,

		address => ioout.addr(0),
		wr_data => ioout.wrdata(15 downto 0),
		rd => ioout.rd,
		wr => ioout.wr,
		rd_data => ioin.rddata(15 downto 0),

		txd	 => ser_txd,
		rxd	 => ser_rxd
	);
	
	rstx <= '0'; -- just a default to make ISE happy
	
process(clk_int)
begin
	if rising_edge(clk_int) then
		if ioout.wr='1' then
			outp <= ioout.wrdata(15 downto 0) after 100 ps;
		end if;
		led <= outp(7 downto 0) after 100 ps;
	end if;
end process;


end rtl;
