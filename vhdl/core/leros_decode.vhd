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

-- decode logic

entity leros_decode is
	port  (
		instr : in std_logic_vector(7 downto 0);
		dec : out decode_type
	);
end leros_decode;

architecture rtl of leros_decode is

begin

process(instr)
begin
	-- some defaults
	dec.op <= op_ld after 100 ps;
	dec.al_ena <= '0' after 100 ps;
	dec.ah_ena <= '0' after 100 ps;
	dec.ahl_ena <= '0' after 100 ps;
	dec.ahh_ena <= '0' after 100 ps;
	dec.log_add <= '0' after 100 ps;
	dec.add_sub <= '0' after 100 ps;
	dec.shr <= '0' after 100 ps;
	dec.sel_imm <= '0' after 100 ps;
	dec.store <= '0' after 100 ps;
	dec.outp <= '0' after 100 ps;
	dec.inp <= '0' after 100 ps;
	-- used in decode, not in ex
	dec.br_op <= '0' after 100 ps;
	dec.jal <= '0' after 100 ps;
	dec.loadh <= '0' after 100 ps;
	dec.loadhl <= '0' after 100 ps;
	dec.loadhh <= '0' after 100 ps;
	dec.indls<= '0' after 100 ps;	
	
	-- start decoding
	dec.add_sub <= instr(2) after 100 ps;
	dec.sel_imm <= instr(0) after 100 ps;
	-- bit 1 and 2 partially unused
	case instr(7 downto 3) is
		when "00000" =>		-- nop
		when "00001" =>		-- add, sub
			dec.al_ena <= '1' after 100 ps;
			dec.ah_ena <= '1' after 100 ps;
			dec.ahl_ena <= '1' after 100 ps;
			dec.ahh_ena <= '1' after 100 ps;
			dec.log_add <= '1' after 100 ps;
		when "00010" =>		-- shr
			dec.al_ena <= '1' after 100 ps;
			dec.ah_ena <= '1' after 100 ps;
			dec.ahl_ena <= '1' after 100 ps;
			dec.ahh_ena <= '1' after 100 ps;
			dec.shr <= '1' after 100 ps;
		when "00011" =>		-- reserved
			null;
		when "00100" =>		-- alu
			dec.al_ena <= '1' after 100 ps;
			dec.ah_ena <= '1' after 100 ps;
			dec.ahl_ena <= '1' after 100 ps;
			dec.ahh_ena <= '1' after 100 ps;
		when "00101" =>		-- loadh*
			if instr(2 downto 1) = "11" then
				dec.loadhh <= '1' after 100 ps;
				dec.ahh_ena <= '1' after 100 ps;
			elsif instr(2 downto 1) = "10" then
				dec.loadhl <= '1' after 100 ps;
				dec.ahl_ena <= '1' after 100 ps;	
			else
				dec.loadh <= '1' after 100 ps;
				dec.ah_ena <= '1' after 100 ps;
			end if;
		when "00110" =>		-- store
			dec.store <= '1' after 100 ps;
		when "00111" =>		-- I/O
			if instr(2)='0' then
				dec.outp <= '1' after 100 ps;
			else
				dec.al_ena <= '1' after 100 ps;
				dec.ah_ena <= '1' after 100 ps;
				dec.ahl_ena <= '1' after 100 ps;
				dec.ahh_ena <= '1' after 100 ps;
				dec.inp <= '1' after 100 ps;
			end if;
		when "01000" =>		-- jal
			dec.jal <= '1' after 100 ps;
			dec.store <= '1' after 100 ps;
		when "01001" =>		-- branch
			dec.br_op <= '1' after 100 ps;
		when "01010" =>		-- loadaddr
			null;
		when "01100" =>		-- load indirect
			dec.al_ena <= '1' after 100 ps;
			dec.ah_ena <= '1' after 100 ps;
			dec.ahl_ena <= '1' after 100 ps;
			dec.ahh_ena <= '1' after 100 ps;
			dec.indls <= '1' after 100 ps;
		when "01110" =>		-- store indirect
			dec.indls <= '1' after 100 ps;
			dec.store <= '1' after 100 ps;
		when others =>
			null;
	end case;

	case instr(2 downto 1) is
		when "00" =>
			dec.op <= op_ld after 100 ps;
		when "01" =>
			dec.op <= op_and after 100 ps;
		when "10" =>
			dec.op <= op_or after 100 ps;
		when "11" =>
			dec.op <= op_xor after 100 ps;
		when others =>
			null;
	end case;
end process;

end rtl;