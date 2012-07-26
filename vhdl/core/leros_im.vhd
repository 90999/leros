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

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

use work.leros_types.all;

-- instruction memory
-- write is ignored for now
-- the content should be generated by an assembler

entity leros_im is
	port  (
		clk : in std_logic;
		reset : in std_logic;
		din : in im_in_type;
		dout : out im_out_type;
		cache_in : in im_cache_in_type;
		cache_out : out im_cache_out_type
	);
end leros_im;

architecture rtl of leros_im is

COMPONENT instr_mem 
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    clkb : IN STD_LOGIC;
    web : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addrb : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    dinb : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END COMPONENT;

COMPONENT tag_mem 
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    clkb : IN STD_LOGIC;
    web : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addrb : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    dinb : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
END COMPONENT;

	type CACHE_STATE_T is (IDLE,WAIT_FOR_DATA,TRANSFER_DATA,DELAY);
	signal cache_state : CACHE_STATE_T := IDLE;

	signal areg				: std_logic_vector(IM_BITS-1 downto 0);
	signal latched_addr	: std_logic_vector(IM_BITS-1 downto 0);
	signal DOA				: std_logic_vector(15 downto 0);
	signal DIB				: std_logic_vector(31 downto 0);
	signal TAGO				: std_logic_vector(15 downto 0);
	signal TAGI				: std_logic_vector(15 downto 0);
	signal ADDRA   		: std_logic_vector(13 downto 0);
	signal ADDRB 			: std_logic_vector(13 downto 0);
	signal tag				: std_logic_vector(15 downto 0);
	signal WEB				: std_logic_vector(3 downto 0);
	
	signal gndv    		: std_logic_vector(31 downto 0);
	signal vccv    		: std_logic_vector(15 downto 0);
	
	signal cache_miss 	: std_logic;
	signal cache_wraddr 	: std_logic_vector(8 downto 0);
	signal cache_reqaddr	: std_logic_vector(IM_BITS-1 downto 0);
	signal words			: std_logic_vector(2 downto 0);
	signal req				: std_logic;

begin

gndv <= "00000000000000000000000000000000";
vccv <= "1111111111111111";

	dout.data <= DOA(15 downto 0) after 100 ps;
	
	ADDRA <= latched_addr(9 downto 0) & "0000" after 100 ps;
	tag <= TAGO(15 downto 0) after 100 ps;
	
	ADDRB <= cache_wraddr & "00000" after 100 ps;
	
	dout.valid <= '1' when cache_miss = '0' else '0' after 100 ps;
	
	cache_miss <= '1' when tag /= areg(25 downto 10) else '0' after 100 ps;
	
	--TODO: after a stall the icache is trying to clock the wrong address to output
	--and the tag comparison becomes invalid after the first clock
	
	process(clk)
	begin
		if clk='1' and clk'Event then
			--Otherwise we have trouble with the initial cache miss
			if cache_miss = '0' or reset = '1' then
				areg <= din.rdaddr after 100 ps;
			end if;
		end if;
	end process;
	
	latched_addr <= din.rdaddr when cache_miss = '0' else areg after 100 ps;
	
  IRAM_INST : instr_mem
  PORT MAP (
    clka => clk,
    wea => gndv(0 downto 0),
    addra => latched_addr(9 downto 0),
    dina => gndv(15 downto 0),
    douta => DOA,
    clkb => clk,
    web => WEB(0 downto 0),
    addrb => cache_wraddr,
    dinb => DIB
--    doutb => doutb
  );
	
	
 TAGRAM_INST : tag_mem
  PORT MAP (
    clka => clk,
    wea => gndv(0 downto 0),
    addra => latched_addr(9 downto 1),
    dina => gndv(15 downto 0),
    douta => TAGO,
    clkb => clk,
    web => WEB(0 downto 0),
    addrb => cache_wraddr,
    dinb => TAGI
--    doutb => doutb
  );
	
	--Memory subsystem uses byte addresses
	cache_out.addr <= cache_reqaddr & "0";
	
	TAGI <= cache_reqaddr(25 downto 10);
	
	cache_out.req <= '0' when reset = '1' else req;
	--Cache fill
	process(clk)
	begin
		if clk='1' and clk'Event then
			if reset='1' then
				--Serious problems are caused if we start requesting data while in reset
				cache_state <= IDLE after 100 ps;
				req <= '0' after 100 ps;
				cache_out.rden <= '0' after 100 ps;
			else
				if cache_state = IDLE then
					req <= '0' after 100 ps;
					cache_out.rden <= '0' after 100 ps;
					WEB <= "0000" after 100 ps;
					if cache_miss = '1' then
						--16 instructions, 8 dwords
						cache_reqaddr <= areg(IM_BITS-1 downto 4) & "0000" after 100 ps;
						req <= '1' after 100 ps;
						cache_out.len <= "000111" after 100 ps;
						cache_state <= WAIT_FOR_DATA after 100 ps;
						words <= "000";
					end if;
				elsif cache_state = WAIT_FOR_DATA then
					req <= '0' after 100 ps;
					if cache_in.empty = '0' then
						cache_state <= TRANSFER_DATA after 100 ps;
						cache_out.rden <= '1' after 100 ps;
					end if;
				elsif cache_state = TRANSFER_DATA then
					--write the crap into the imem and tag ram
					words <= std_logic_vector(unsigned(words)+1) after 100 ps;
					--TODO: why the leading zero?
					cache_wraddr <= '0' & cache_reqaddr(8 downto 4) & words;
					DIB <= cache_in.data after 100 ps;
					cache_out.rden <= '1' after 100 ps;
					WEB <= "1111" after 100 ps;
					if cache_in.empty = '1' then
						cache_out.rden <= '0' after 100 ps;
						cache_state <= DELAY after 100 ps;
						WEB <= "0000" after 100 ps;
					end if;
				else --if state = DELAY
					--Delay an extra cycle to make sure the new tags propagate to the other side of the cache
					cache_state <= IDLE after 100 ps;
				end if;
			end if;
		end if;
	end process;

end rtl;
