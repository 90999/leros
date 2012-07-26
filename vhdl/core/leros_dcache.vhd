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

entity leros_dcache is
	port  (
		clk : in std_logic;
		reset : in std_logic;
		valid : in std_logic;
		store : in std_logic;
		wraddr : in std_logic_vector(DM_BITS-1 downto 0);
		rdaddr : in std_logic_vector(DM_BITS-1 downto 0);
		wrindr : in std_logic;
		rdindr : in std_logic;
		wrdata : in std_logic_vector(31 downto 0);
		rddata : out std_logic_vector(31 downto 0);
		dmiss : out std_logic;
		cache_in : in dm_cache_in_type;
		cache_out : out dm_cache_out_type
	);
end leros_dcache;

architecture rtl of leros_dcache is

COMPONENT data_mem
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
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

	signal mem_wraddr, mem_rdaddr, cache_wraddr, dmem_wraddr : std_logic_vector(8 downto 0);
	signal reg_we, cache_we, tag_we : std_logic_vector(3 downto 0);
	signal rddata_cache, rddata_reg, dmem_wrdata, cache_din : std_logic_vector(31 downto 0);
	signal gndv,vccv : std_logic_vector(31 downto 0);
	signal rdaddrq,wraddrq : std_logic_vector(DM_BITS-1 downto 0);
	signal latched_rdaddr,latched_wraddr : std_logic_vector(DM_BITS-1 downto 0);
	signal wrtago,rdtago,tagi : std_logic_vector(15 downto 0);
	signal rdmiss,wrmiss,dmissint : std_logic;
	
	signal cache_reqaddr	: std_logic_vector(IM_BITS-2 downto 0);
	signal words			: std_logic_vector(2 downto 0);
	signal req, cache_write, cache_sel : std_logic;
	signal validq : std_logic := '0';
	signal rdindrq, wrindrq : std_logic;
	signal stall : std_logic;

begin

	vccv <= X"FFFFFFFF";
	gndv <= X"00000000";
	
	--TODO: we almost need to pipeline writes because the tag isn't known until
	--after the cycle that could clobber data


	latched_rdaddr <= rdaddr when rdmiss='0' else rdaddrq after 100 ps;
	latched_wraddr <= wraddr when wrmiss='0' else wraddrq after 100 ps;
	
	rdmiss <= '1' when rdaddrq(24 downto 9) /= rdtago and rdindrq = '1' else '0' after 100 ps;
	wrmiss <= '1' when wraddrq(24 downto 9) /= wrtago and wrindrq = '1' else '0' after 100 ps;
	--Force stall until cache line is fully read
	dmissint <= '1' when (rdmiss = '1' or wrmiss = '1' or stall = '1') and validq = '1' else '0' after 100 ps;
	dmiss <= dmissint;
	
	process(clk)
	begin
		if clk='1' and clk'Event then
		--TODO: why don't we stall this on icache miss?
			if dmissint = '0' then
				rdaddrq <= rdaddr after 100 ps;
				wraddrq <= wraddr after 100 ps;			
				validq <= '1' after 100 ps;
				rdindrq <= rdindr after 100 ps;
				wrindrq <= wrindr after 100 ps;
			end if;
		end if;
	end process;


	dmem_wraddr <= cache_wraddr when cache_sel = '1' else latched_wraddr(8 downto 0) after 100 ps;	
	mem_wraddr <= latched_wraddr(8 downto 0) after 100 ps;
	mem_rdaddr <= latched_rdaddr(8 downto 0) after 100 ps;
	
	dmem_wrdata <= cache_din when cache_sel = '1' else wrdata;
	

	reg_we <= "1111" when store = '1' and wrindr = '0' else "0000" after 100 ps;
	cache_we <= "1111" when (store = '1' and wrindr = '1') or cache_write = '1' else "0000" after 100 ps;
	tag_we <= "1111" when cache_write = '1' else "0000" after 100 ps;
	
	rddata <= rddata_cache when rdindrq = '1' else rddata_reg after 100 ps;

	DRAM_reg_inst : data_mem
	PORT MAP (
    clka => clk,
    wea => reg_we(0 downto 0),
    addra => mem_wraddr,
    dina => wrdata,
--    douta => douta,
    clkb => clk,
    web => gndv(0 downto 0),
    addrb => mem_rdaddr,
    dinb => gndv(31 downto 0),
    doutb => rddata_reg
	);

	DRAM_inst : data_mem
	PORT MAP (
    clka => clk,
    wea => cache_we(0 downto 0),
    addra => dmem_wraddr,
    dina => dmem_wrdata,
--    douta => douta,
    clkb => clk,
    web => gndv(0 downto 0),
    addrb => mem_rdaddr,
    dinb => gndv(31 downto 0),
    doutb => rddata_cache
	);
	
	TAGRAM_INST : tag_mem
	PORT MAP (
    clka => clk,
    wea => tag_we(0 downto 0),
    addra => dmem_wraddr,
    dina => tagi,
    douta => wrtago,
    clkb => clk,
    web => gndv(0 downto 0),
    addrb => mem_rdaddr,
    dinb => gndv(15 downto 0),
    doutb => rdtago
	);
	
	--TODO: in the event of a simultaneous read and write miss
	--we will have a serious problem if the accesses have different
	--tags that map to the same cache line
 
 	cache_out.req <= '0' when reset = '1' else req;
	--Memory subsystem uses byte addresses
	cache_out.addr <= cache_reqaddr & "00";
	tagi <= cache_reqaddr(24 downto 9);
	
	
	--Cache fill
	process(clk)
	begin
		if clk='1' and clk'Event then
			--We must wait for at least 1 instruction to get processed by the ALU
			if reset='1' or validq = '0' then
				--Serious problems are caused if we start requesting data while in reset
				cache_state <= IDLE after 100 ps;
				req <= '0' after 100 ps;
				cache_out.rden <= '0' after 100 ps;
				cache_write <= '0' after 100 ps;
				cache_sel <= '0' after 100 ps;
				stall <= '0';
			else
				if cache_state = IDLE then
					req <= '0' after 100 ps;
					cache_out.rden <= '0' after 100 ps;
					cache_write <= '0' after 100 ps;
					cache_sel <= '0' after 100 ps;
					stall <= '0' after 100 ps;

					--TODO: flush the line if its dirty
					if rdmiss = '1' then
						--8 dwords
						cache_reqaddr <= rdaddrq(IM_BITS-2 downto 3) & "000" after 100 ps;
					elsif wrmiss = '1' then
						cache_reqaddr <= wraddrq(IM_BITS-2 downto 3) & "000" after 100 ps;
					end if;
					
					if dmissint = '1' then
						req <= '1' after 100 ps;
						cache_out.len <= "000111" after 100 ps;
						cache_state <= WAIT_FOR_DATA after 100 ps;
						words <= "000" after 100 ps;
						stall <= '1' after 100 ps;
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
					cache_wraddr <= cache_reqaddr(8 downto 3) & words;
					cache_write <= '1' after 100 ps;
					cache_sel <= '1' after 100 ps;
					cache_din <= cache_in.data after 100 ps;
					cache_out.rden <= '1' after 100 ps;
--					WEB <= "1111" after 100 ps;
					if cache_in.empty = '1' then
						cache_out.rden <= '0' after 100 ps;
						cache_state <= DELAY after 100 ps;
--						WEB <= "0000" after 100 ps;
						cache_sel <= '0' after 100 ps;
						--if this was a write then get the cache to update
						if rdmiss='1' then
							cache_write <= '0' after 100 ps;
						end if;
					end if;
				else --if state = DELAY
					--Delay an extra cycle to make sure the new tags propagate to the other side of the cache
					cache_state <= IDLE after 100 ps;
					cache_write <= '0' after 100 ps;
					stall <= '0' after 100 ps;
				end if;
			end if;
		end if;
	end process;

	
end rtl;