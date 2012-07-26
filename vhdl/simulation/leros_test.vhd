--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   18:45:03 05/16/2012
-- Design Name:   
-- Module Name:   /opt/Xilinx/13.2/ISE_DS/pcie/pci454/leros_test.vhd
-- Project Name:  pci2
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: leros_nexys2
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;
 
ENTITY leros_test IS
END leros_test;
 
ARCHITECTURE behavior OF leros_test IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT leros_nexys2
    PORT(
         clk : IN  std_logic;
         led : OUT  std_logic_vector(7 downto 0);
         rstx : OUT  std_logic;
			ser_txd : out std_logic;
			ser_rxd : in std_logic;
			icaddr : out std_logic_vector(26 downto 0);
			iclen : out std_logic_vector(5 downto 0);
			icreq : out std_logic;
			icrden : out std_logic;
			icdata : in std_logic_vector(31 downto 0);
			icempty : in std_logic;
			dcaddr : out std_logic_vector(26 downto 0);
			dclen : out std_logic_vector(5 downto 0);
			dcreq : out std_logic;
			dcrden : out std_logic;
			dcdata : in std_logic_vector(31 downto 0);
			dcempty : in std_logic
        );
    END COMPONENT;
    
	type IMEM_STATE_T is (WAIT_FOR_REQ,TRANSFER);
	signal state : IMEM_STATE_T := WAIT_FOR_REQ;
	signal dstate : IMEM_STATE_T := WAIT_FOR_REQ;

	-- the data ram
	constant nwords : integer := 2 ** 13;
	type ram_type is array(0 to nwords-1) of std_logic_vector(31 downto 0);
	signal dm : ram_type := (others => (others => '0'));
	

   --Inputs
   signal clk : std_logic := '0';
	signal ser_rxd : std_logic := '0';
	
	signal icaddr : std_logic_vector(26 downto 0);
	signal addr : std_logic_vector(24 downto 0);
	signal iclen : std_logic_vector(5 downto 0);
	signal count : std_logic_vector(5 downto 0);
	signal len : std_logic_vector(5 downto 0);
	signal icreq : std_logic;
	signal icrden : std_logic;
	signal icdata : std_logic_vector(31 downto 0);
	signal icempty : std_logic;
	
	signal dcaddr : std_logic_vector(26 downto 0);
	signal daddr : std_logic_vector(24 downto 0);
	signal dclen : std_logic_vector(5 downto 0);
	signal dcount : std_logic_vector(5 downto 0);
	signal dlen : std_logic_vector(5 downto 0);
	signal dcreq : std_logic;
	signal dcrden : std_logic;
	signal dcdata : std_logic_vector(31 downto 0);
	signal dcempty : std_logic;

 	--Outputs
   signal led : std_logic_vector(7 downto 0);
   signal rstx : std_logic;
	signal ser_txd : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: leros_nexys2 PORT MAP (
          clk => clk,
          led => led,
          rstx => rstx,
			 ser_rxd => ser_rxd,
			 ser_txd => ser_txd,
			 icaddr => icaddr,
			 iclen => iclen,
			 icreq => icreq,
			 icrden => icrden,
			 icdata => icdata,
			 icempty => icempty,
			 dcaddr => dcaddr,
			 dclen => dclen,
			 dcreq => dcreq,
			 dcrden => dcrden,
			 dcdata => dcdata,
			 dcempty => dcempty
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
	
	process(clk)
	begin
		if clk='1' and clk'Event and rstx = '0' then
			if state = WAIT_FOR_REQ then
				icempty <= '1' after 100 ps;
				if icreq = '1' then
					state <= TRANSFER after 100 ps;
					len <= iclen after 100 ps;
					addr <= icaddr(26 downto 2) after 100 ps;
					count <= "000000" after 100 ps;
				end if;
			else
				if count <= len then
						icdata <= dm(to_integer(unsigned(addr)+unsigned(count))) after 100 ps;
						icempty <= '0' after 100 ps;
					if icrden='1' then
						if count < len then
							icdata <= dm(to_integer(unsigned(addr)+unsigned(count)+1)) after 100 ps;
						else
							icempty <= '1' after 100 ps;
							state <= WAIT_FOR_REQ after 100 ps;
						end if;
						count <= std_logic_vector(unsigned(count) + 1) after 100 ps;
					end if;
				else
					icempty <= '1' after 100 ps;
					state <= WAIT_FOR_REQ after 100 ps;
				end if;
			end if;
		end if;
	end process;
 
	process(clk)
	begin
		if clk='1' and clk'Event and rstx = '0' then
			if dstate = WAIT_FOR_REQ then
				dcempty <= '1' after 100 ps;
				if dcreq = '1' then
					dstate <= TRANSFER after 100 ps;
					dlen <= dclen after 100 ps;
					daddr <= dcaddr(26 downto 2) after 100 ps;
					dcount <= "000000" after 100 ps;
				end if;
			else
				if dcount <= dlen then
						dcdata <= dm(to_integer(unsigned(daddr)+unsigned(dcount))) after 100 ps;
						dcempty <= '0' after 100 ps;
					if dcrden='1' then
						if dcount < dlen then
							dcdata <= dm(to_integer(unsigned(daddr)+unsigned(dcount)+1)) after 100 ps;
						else
							dcempty <= '1' after 100 ps;
							dstate <= WAIT_FOR_REQ after 100 ps;
						end if;
						dcount <= std_logic_vector(unsigned(dcount) + 1) after 100 ps;
					end if;
				else
					dcempty <= '1' after 100 ps;
					dstate <= WAIT_FOR_REQ after 100 ps;
				end if;
			end if;
		end if;
	end process;
	
   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
	--	rstx <= '1';
		
      wait for 100 ns;	

	--	rstx <= '0';
      wait for clk_period*10;


      -- insert stimulus here 

      wait;
   end process;

dm(0) <= X"00000000";
dm(1) <= X"29002100";
dm(2) <= X"21093001";
dm(3) <= X"40000000";
dm(4) <= X"00000000";
dm(5) <= X"50012000";
dm(6) <= X"20037000";
dm(7) <= X"70015001";
dm(8) <= X"00002001";
dm(9) <= X"30010902";
dm(10) <= X"214c0000";
dm(11) <= X"2d022901";
dm(12) <= X"30032f03";
dm(13) <= X"290121f4";
dm(14) <= X"2f002d00";
dm(15) <= X"40000000";
dm(16) <= X"21650000";
dm(17) <= X"21f43003";
dm(18) <= X"2d002901";
dm(19) <= X"00002f00";
dm(20) <= X"00004000";
dm(21) <= X"30032172";
dm(22) <= X"290121f4";
dm(23) <= X"2f002d00";
dm(24) <= X"40000000";
dm(25) <= X"216f0000";
dm(26) <= X"21f43003";
dm(27) <= X"2d002901";
dm(28) <= X"00002f00";
dm(29) <= X"00004000";
dm(30) <= X"30032173";
dm(31) <= X"290121f4";
dm(32) <= X"2f002d00";
dm(33) <= X"40000000";
dm(34) <= X"210d0000";
dm(35) <= X"21f43003";
dm(36) <= X"2d002901";
dm(37) <= X"00002f00";
dm(38) <= X"00004000";
dm(39) <= X"3003210a";
dm(40) <= X"290121f4";
dm(41) <= X"2f002d00";
dm(42) <= X"40000000";
dm(43) <= X"21fe0000";
dm(44) <= X"2d002901";
dm(45) <= X"00002f00";
dm(46) <= X"00004000";
dm(47) <= X"30032174";
dm(48) <= X"290121f4";
dm(49) <= X"2f002d00";
dm(50) <= X"40000000";
dm(51) <= X"21a80000";
dm(52) <= X"2d002900";
dm(53) <= X"00002f00";
dm(54) <= X"00004000";
dm(55) <= X"290021fb";
dm(56) <= X"2f002d00";
dm(57) <= X"40000000";
dm(58) <= X"214e0000";
dm(59) <= X"2d002901";
dm(60) <= X"00002f00";
dm(61) <= X"00004000";
dm(62) <= X"290121a1";
dm(63) <= X"2f002d00";
dm(64) <= X"40000000";
dm(65) <= X"210a0000";
dm(66) <= X"21423003";
dm(67) <= X"2d002902";
dm(68) <= X"00002f00";
dm(69) <= X"00004000";
dm(70) <= X"30032175";
dm(71) <= X"290121f4";
dm(72) <= X"2f002d00";
dm(73) <= X"40000000";
dm(74) <= X"20020000";
dm(75) <= X"48003800";
dm(76) <= X"20010000";
dm(77) <= X"0d020000";
dm(78) <= X"00003001";
dm(79) <= X"60015001";
dm(80) <= X"30030000";
dm(81) <= X"60005001";
dm(82) <= X"30000000";
dm(83) <= X"00004000";
dm(84) <= X"20000000";
dm(85) <= X"70005001";
dm(86) <= X"50012002";
dm(87) <= X"20037001";
dm(88) <= X"70025001";
dm(89) <= X"50012004";
dm(90) <= X"20057003";
dm(91) <= X"70045001";
dm(92) <= X"50012006";
dm(93) <= X"20077005";
dm(94) <= X"70065001";
dm(95) <= X"50012008";
dm(96) <= X"20097007";
dm(97) <= X"70085001";
dm(98) <= X"5001200a";
dm(99) <= X"20017009";
dm(100) <= X"090a0000";
dm(101) <= X"00003001";
dm(102) <= X"00002001";
dm(103) <= X"30010d0a";
dm(104) <= X"50010000";
dm(105) <= X"00006009";
dm(106) <= X"5001300a";
dm(107) <= X"00006008";
dm(108) <= X"50013009";
dm(109) <= X"00006007";
dm(110) <= X"50013008";
dm(111) <= X"00006006";
dm(112) <= X"50013007";
dm(113) <= X"00006005";
dm(114) <= X"50013006";
dm(115) <= X"00006004";
dm(116) <= X"50013005";
dm(117) <= X"00006003";
dm(118) <= X"50013004";
dm(119) <= X"00006002";
dm(120) <= X"50013003";
dm(121) <= X"00006001";
dm(122) <= X"50013002";
dm(123) <= X"00006000";
dm(124) <= X"40003000";
dm(125) <= X"00000000";
dm(126) <= X"50012000";
dm(127) <= X"20027000";
dm(128) <= X"70015001";
dm(129) <= X"50012003";
dm(130) <= X"20047002";
dm(131) <= X"70035001";
dm(132) <= X"50012005";
dm(133) <= X"20067004";
dm(134) <= X"70055001";
dm(135) <= X"50012007";
dm(136) <= X"20087006";
dm(137) <= X"70075001";
dm(138) <= X"50012009";
dm(139) <= X"200a7008";
dm(140) <= X"70095001";
dm(141) <= X"00002001";
dm(142) <= X"3001090a";
dm(143) <= X"20010000";
dm(144) <= X"0d0a0000";
dm(145) <= X"00003001";
dm(146) <= X"60095001";
dm(147) <= X"300a0000";
dm(148) <= X"60085001";
dm(149) <= X"30090000";
dm(150) <= X"60075001";
dm(151) <= X"30080000";
dm(152) <= X"60065001";
dm(153) <= X"30070000";
dm(154) <= X"60055001";
dm(155) <= X"30060000";
dm(156) <= X"60045001";
dm(157) <= X"30050000";
dm(158) <= X"60035001";
dm(159) <= X"30040000";
dm(160) <= X"60025001";
dm(161) <= X"30030000";
dm(162) <= X"60015001";
dm(163) <= X"30020000";
dm(164) <= X"60005001";
dm(165) <= X"30000000";
dm(166) <= X"00004000";
dm(167) <= X"20000000";
dm(168) <= X"70005001";
dm(169) <= X"50012002";
dm(170) <= X"20037001";
dm(171) <= X"70025001";
dm(172) <= X"50012004";
dm(173) <= X"20057003";
dm(174) <= X"70045001";
dm(175) <= X"50012006";
dm(176) <= X"20077005";
dm(177) <= X"70065001";
dm(178) <= X"50012008";
dm(179) <= X"20097007";
dm(180) <= X"70085001";
dm(181) <= X"5001200a";
dm(182) <= X"20017009";
dm(183) <= X"090a0000";
dm(184) <= X"00003001";
dm(185) <= X"00002001";
dm(186) <= X"30010d0a";
dm(187) <= X"50010000";
dm(188) <= X"00006009";
dm(189) <= X"5001300a";
dm(190) <= X"00006008";
dm(191) <= X"50013009";
dm(192) <= X"00006007";
dm(193) <= X"50013008";
dm(194) <= X"00006006";
dm(195) <= X"50013007";
dm(196) <= X"00006005";
dm(197) <= X"50013006";
dm(198) <= X"00006004";
dm(199) <= X"50013005";
dm(200) <= X"00006003";
dm(201) <= X"50013004";
dm(202) <= X"00006002";
dm(203) <= X"50013003";
dm(204) <= X"00006001";
dm(205) <= X"50013002";
dm(206) <= X"00006000";
dm(207) <= X"40003000";
dm(208) <= X"00000000";
dm(209) <= X"50012000";
dm(210) <= X"20027000";
dm(211) <= X"70015001";
dm(212) <= X"50012003";
dm(213) <= X"20047002";
dm(214) <= X"70035001";
dm(215) <= X"50012005";
dm(216) <= X"20067004";
dm(217) <= X"70055001";
dm(218) <= X"50012007";
dm(219) <= X"20087006";
dm(220) <= X"70075001";
dm(221) <= X"50012009";
dm(222) <= X"200a7008";
dm(223) <= X"70095001";
dm(224) <= X"00002001";
dm(225) <= X"3001090a";
dm(226) <= X"20010000";
dm(227) <= X"0d0a0000";
dm(228) <= X"00003001";
dm(229) <= X"60095001";
dm(230) <= X"300a0000";
dm(231) <= X"60085001";
dm(232) <= X"30090000";
dm(233) <= X"60075001";
dm(234) <= X"30080000";
dm(235) <= X"60065001";
dm(236) <= X"30070000";
dm(237) <= X"60055001";
dm(238) <= X"30060000";
dm(239) <= X"60045001";
dm(240) <= X"30050000";
dm(241) <= X"60035001";
dm(242) <= X"30040000";
dm(243) <= X"60025001";
dm(244) <= X"30030000";
dm(245) <= X"60015001";
dm(246) <= X"30020000";
dm(247) <= X"60005001";
dm(248) <= X"30000000";
dm(249) <= X"00004000";
dm(250) <= X"23013c00";
dm(251) <= X"49fd0000";
dm(252) <= X"38012003";
dm(253) <= X"00002000";
dm(254) <= X"00004000";
dm(255) <= X"20000000";
dm(256) <= X"70005001";
dm(257) <= X"50012003";
dm(258) <= X"20017001";
dm(259) <= X"09020000";
dm(260) <= X"00003001";
dm(261) <= X"30032173";
dm(262) <= X"290121f4";
dm(263) <= X"2f002d00";
dm(264) <= X"40000000";
dm(265) <= X"20010000";
dm(266) <= X"0d020000";
dm(267) <= X"00003001";
dm(268) <= X"60015001";
dm(269) <= X"30030000";
dm(270) <= X"60005001";
dm(271) <= X"30000000";
dm(272) <= X"00004000";
dm(273) <= X"00000000";
dm(274) <= X"00000000";
dm(275) <= X"00000000";
dm(276) <= X"00000000";
dm(277) <= X"00000000";
dm(278) <= X"00000000";
dm(279) <= X"00000000";
dm(280) <= X"00000000";
dm(281) <= X"00000000";
dm(282) <= X"00000000";
dm(283) <= X"00000000";
dm(284) <= X"00000000";
dm(285) <= X"00000000";
dm(286) <= X"00000000";
dm(287) <= X"00000000";
dm(288) <= X"00000000";
dm(289) <= X"20000000";
dm(290) <= X"70005001";
dm(291) <= X"50012003";
dm(292) <= X"20047001";
dm(293) <= X"70025001";
dm(294) <= X"00002001";
dm(295) <= X"30010903";
dm(296) <= X"20030000";
dm(297) <= X"491e0000";
dm(298) <= X"00000d01";
dm(299) <= X"3003491b";
dm(300) <= X"29022142";
dm(301) <= X"2f002d00";
dm(302) <= X"40000000";
dm(303) <= X"20020000";
dm(304) <= X"30040000";
dm(305) <= X"00002003";
dm(306) <= X"30030d01";
dm(307) <= X"29022142";
dm(308) <= X"2f002d00";
dm(309) <= X"40000000";
dm(310) <= X"20020000";
dm(311) <= X"30030804";
dm(312) <= X"20030000";
dm(313) <= X"30020000";
dm(314) <= X"00002001";
dm(315) <= X"30010d03";
dm(316) <= X"50010000";
dm(317) <= X"00006002";
dm(318) <= X"50013004";
dm(319) <= X"00006001";
dm(320) <= X"50013003";
dm(321) <= X"00006000";
dm(322) <= X"40003000";
dm(323) <= X"00000000";
dm(324) <= X"00000000";
dm(325) <= X"00000000";
dm(326) <= X"00000000";
dm(327) <= X"00000000";


END;
