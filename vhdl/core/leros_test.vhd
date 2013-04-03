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
			dcreq_write : out std_logic;
			dcrden : out std_logic;
			dcwren : out std_logic;
			dcdout : out std_logic_vector(31 downto 0);
			dcdata : in std_logic_vector(31 downto 0);
			dcempty : in std_logic;
			dcack : in std_logic
        );
    END COMPONENT;
    
	type IMEM_STATE_T is (WAIT_FOR_REQ,TRANSFER_WRITE,TRANSFER);
	signal state : IMEM_STATE_T := WAIT_FOR_REQ;
	signal dstate : IMEM_STATE_T := WAIT_FOR_REQ;

	-- the data ram
	constant nwords : integer := 2 ** 14;
	type ram_type is array(0 to nwords-1) of std_logic_vector(31 downto 0);
	signal dm : ram_type := (others => (others => '0'));
	signal dm2 : ram_type := (others => (others => '0'));
	

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
	signal dcreq_write : std_logic;
	signal dcrden : std_logic;
	signal dcwren : std_logic;
	signal dcdout : std_logic_vector(31 downto 0);
	signal dcdata : std_logic_vector(31 downto 0);
	signal dcempty : std_logic;
	signal dcack : std_logic;
	signal got_wren : std_logic;

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
			 dcreq_write => dcreq_write,
			 dcrden => dcrden,
			 dcwren => dcwren,
			 dcdout => dcdout,
			 dcdata => dcdata,
			 dcempty => dcempty,
			 dcack => dcack
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
				dcack <= '0' after 100 ps;
				got_wren <= '0' after 100 ps;
				if dcreq = '1' then
					if dcreq_write = '1' then
						dcack <= '1' after 100 ps;
						dstate <= TRANSFER_WRITE after 100 ps;
					else
						dstate <= TRANSFER after 100 ps;
					end if;
					dlen <= dclen after 100 ps;
					daddr <= dcaddr(26 downto 2) after 100 ps;
					dcount <= "000000" after 100 ps;
				end if;
			elsif  dstate = TRANSFER_WRITE then
				if dcwren = '1' then
					dm2(to_integer(unsigned(daddr)+unsigned(dcount))) <= dcdout after 100 ps;
					dcount <= std_logic_vector(unsigned(dcount)+1) after 100 ps;
					got_wren <= '1' after 100 ps;
				else
					if got_wren = '1' then
						dstate <= WAIT_FOR_REQ after 100 ps;
					end if;
				end if;
			else
				if dcount <= dlen then
						dcdata <= dm2(to_integer(unsigned(daddr)+unsigned(dcount))) after 100 ps;
						dcempty <= '0' after 100 ps;
					if dcrden='1' then
						if dcount < dlen then
							dcdata <= dm2(to_integer(unsigned(daddr)+unsigned(dcount)+1)) after 100 ps;
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
dm(1) <= X"29042100";
dm(2) <= X"21093001";
dm(3) <= X"40000000";
dm(4) <= X"00000000";
dm(5) <= X"50012000";
dm(6) <= X"20037000";
dm(7) <= X"70015001";
dm(8) <= X"00002001";
dm(9) <= X"30010902";
dm(10) <= X"214C0000";
dm(11) <= X"2D002900";
dm(12) <= X"30032F00";
dm(13) <= X"29022106";
dm(14) <= X"2F002D00";
dm(15) <= X"40000000";
dm(16) <= X"21650000";
dm(17) <= X"21063003";
dm(18) <= X"2D002902";
dm(19) <= X"00002F00";
dm(20) <= X"00004000";
dm(21) <= X"30032172";
dm(22) <= X"29022106";
dm(23) <= X"2F002D00";
dm(24) <= X"40000000";
dm(25) <= X"216F0000";
dm(26) <= X"21063003";
dm(27) <= X"2D002902";
dm(28) <= X"00002F00";
dm(29) <= X"00004000";
dm(30) <= X"30032173";
dm(31) <= X"29022106";
dm(32) <= X"2F002D00";
dm(33) <= X"40000000";
dm(34) <= X"210D0000";
dm(35) <= X"21063003";
dm(36) <= X"2D002902";
dm(37) <= X"00002F00";
dm(38) <= X"00004000";
dm(39) <= X"3003210A";
dm(40) <= X"29022106";
dm(41) <= X"2F002D00";
dm(42) <= X"40000000";
dm(43) <= X"21100000";
dm(44) <= X"2D002902";
dm(45) <= X"00002F00";
dm(46) <= X"00004000";
dm(47) <= X"30032174";
dm(48) <= X"29022106";
dm(49) <= X"2F002D00";
dm(50) <= X"40000000";
dm(51) <= X"21EE0000";
dm(52) <= X"2D002900";
dm(53) <= X"00002F00";
dm(54) <= X"00004000";
dm(55) <= X"30032175";
dm(56) <= X"29022106";
dm(57) <= X"2F002D00";
dm(58) <= X"40000000";
dm(59) <= X"212B0000";
dm(60) <= X"2D002901";
dm(61) <= X"00002F00";
dm(62) <= X"00004000";
dm(63) <= X"30032176";
dm(64) <= X"29022106";
dm(65) <= X"2F002D00";
dm(66) <= X"40000000";
dm(67) <= X"21740000";
dm(68) <= X"2D002901";
dm(69) <= X"00002F00";
dm(70) <= X"00004000";
dm(71) <= X"30032177";
dm(72) <= X"29022106";
dm(73) <= X"2F002D00";
dm(74) <= X"40000000";
dm(75) <= X"21BD0000";
dm(76) <= X"2D002901";
dm(77) <= X"00002F00";
dm(78) <= X"00004000";
dm(79) <= X"30032178";
dm(80) <= X"29022106";
dm(81) <= X"2F002D00";
dm(82) <= X"40000000";
dm(83) <= X"210A0000";
dm(84) <= X"21523003";
dm(85) <= X"2D002902";
dm(86) <= X"00002F00";
dm(87) <= X"00004000";
dm(88) <= X"38002002";
dm(89) <= X"30032179";
dm(90) <= X"29022106";
dm(91) <= X"2F002D00";
dm(92) <= X"40000000";
dm(93) <= X"21D30000";
dm(94) <= X"2D002902";
dm(95) <= X"00002F00";
dm(96) <= X"00004000";
dm(97) <= X"3003217A";
dm(98) <= X"29022106";
dm(99) <= X"2F002D00";
dm(100) <= X"40000000";
dm(101) <= X"213D0000";
dm(102) <= X"2D002903";
dm(103) <= X"00002F00";
dm(104) <= X"00004000";
dm(105) <= X"3003217B";
dm(106) <= X"29022106";
dm(107) <= X"2F002D00";
dm(108) <= X"40000000";
dm(109) <= X"20020000";
dm(110) <= X"48003800";
dm(111) <= X"20010000";
dm(112) <= X"0D020000";
dm(113) <= X"00003001";
dm(114) <= X"60015001";
dm(115) <= X"50013003";
dm(116) <= X"30006000";
dm(117) <= X"00004000";
dm(118) <= X"00000000";
dm(119) <= X"20000000";
dm(120) <= X"70005001";
dm(121) <= X"50012002";
dm(122) <= X"20037001";
dm(123) <= X"70025001";
dm(124) <= X"50012004";
dm(125) <= X"20057003";
dm(126) <= X"70045001";
dm(127) <= X"50012006";
dm(128) <= X"20077005";
dm(129) <= X"70065001";
dm(130) <= X"50012008";
dm(131) <= X"20017007";
dm(132) <= X"09080000";
dm(133) <= X"00003001";
dm(134) <= X"00002001";
dm(135) <= X"30010D08";
dm(136) <= X"50010000";
dm(137) <= X"30086007";
dm(138) <= X"60065001";
dm(139) <= X"50013007";
dm(140) <= X"30066005";
dm(141) <= X"60045001";
dm(142) <= X"50013005";
dm(143) <= X"30046003";
dm(144) <= X"60025001";
dm(145) <= X"50013003";
dm(146) <= X"30026001";
dm(147) <= X"60005001";
dm(148) <= X"40003000";
dm(149) <= X"00000000";
dm(150) <= X"50012000";
dm(151) <= X"20027000";
dm(152) <= X"70015001";
dm(153) <= X"50012003";
dm(154) <= X"20047002";
dm(155) <= X"70035001";
dm(156) <= X"50012005";
dm(157) <= X"20067004";
dm(158) <= X"70055001";
dm(159) <= X"50012007";
dm(160) <= X"20087006";
dm(161) <= X"70075001";
dm(162) <= X"50012009";
dm(163) <= X"200A7008";
dm(164) <= X"70095001";
dm(165) <= X"00002001";
dm(166) <= X"3001090A";
dm(167) <= X"20010000";
dm(168) <= X"0D0A0000";
dm(169) <= X"00003001";
dm(170) <= X"60095001";
dm(171) <= X"5001300A";
dm(172) <= X"30096008";
dm(173) <= X"60075001";
dm(174) <= X"50013008";
dm(175) <= X"30076006";
dm(176) <= X"60055001";
dm(177) <= X"50013006";
dm(178) <= X"30056004";
dm(179) <= X"60035001";
dm(180) <= X"50013004";
dm(181) <= X"30036002";
dm(182) <= X"60015001";
dm(183) <= X"50013002";
dm(184) <= X"30006000";
dm(185) <= X"00004000";
dm(186) <= X"20000000";
dm(187) <= X"70005001";
dm(188) <= X"50012002";
dm(189) <= X"20037001";
dm(190) <= X"70025001";
dm(191) <= X"50012004";
dm(192) <= X"20057003";
dm(193) <= X"70045001";
dm(194) <= X"50012006";
dm(195) <= X"20077005";
dm(196) <= X"70065001";
dm(197) <= X"50012008";
dm(198) <= X"20097007";
dm(199) <= X"70085001";
dm(200) <= X"5001200A";
dm(201) <= X"20017009";
dm(202) <= X"090A0000";
dm(203) <= X"00003001";
dm(204) <= X"00002001";
dm(205) <= X"30010D0A";
dm(206) <= X"50010000";
dm(207) <= X"300A6009";
dm(208) <= X"60085001";
dm(209) <= X"50013009";
dm(210) <= X"30086007";
dm(211) <= X"60065001";
dm(212) <= X"50013007";
dm(213) <= X"30066005";
dm(214) <= X"60045001";
dm(215) <= X"50013005";
dm(216) <= X"30046003";
dm(217) <= X"60025001";
dm(218) <= X"50013003";
dm(219) <= X"30026001";
dm(220) <= X"60005001";
dm(221) <= X"40003000";
dm(222) <= X"00000000";
dm(223) <= X"50012000";
dm(224) <= X"20027000";
dm(225) <= X"70015001";
dm(226) <= X"50012003";
dm(227) <= X"20047002";
dm(228) <= X"70035001";
dm(229) <= X"50012005";
dm(230) <= X"20067004";
dm(231) <= X"70055001";
dm(232) <= X"50012007";
dm(233) <= X"20087006";
dm(234) <= X"70075001";
dm(235) <= X"50012009";
dm(236) <= X"200A7008";
dm(237) <= X"70095001";
dm(238) <= X"00002001";
dm(239) <= X"3001090A";
dm(240) <= X"20010000";
dm(241) <= X"0D0A0000";
dm(242) <= X"00003001";
dm(243) <= X"60095001";
dm(244) <= X"5001300A";
dm(245) <= X"30096008";
dm(246) <= X"60075001";
dm(247) <= X"50013008";
dm(248) <= X"30076006";
dm(249) <= X"60055001";
dm(250) <= X"50013006";
dm(251) <= X"30056004";
dm(252) <= X"60035001";
dm(253) <= X"50013004";
dm(254) <= X"30036002";
dm(255) <= X"60015001";
dm(256) <= X"50013002";
dm(257) <= X"30006000";
dm(258) <= X"00004000";
dm(259) <= X"23013C00";
dm(260) <= X"49FD0000";
dm(261) <= X"38012003";
dm(262) <= X"00002000";
dm(263) <= X"00004000";
dm(264) <= X"20000000";
dm(265) <= X"70005001";
dm(266) <= X"50012003";
dm(267) <= X"20017001";
dm(268) <= X"09020000";
dm(269) <= X"00003001";
dm(270) <= X"30032173";
dm(271) <= X"29022106";
dm(272) <= X"2F002D00";
dm(273) <= X"40000000";
dm(274) <= X"20010000";
dm(275) <= X"0D020000";
dm(276) <= X"00003001";
dm(277) <= X"60015001";
dm(278) <= X"50013003";
dm(279) <= X"30006000";
dm(280) <= X"00004000";
dm(281) <= X"00000000";
dm(282) <= X"00000000";
dm(283) <= X"00000000";
dm(284) <= X"00000000";
dm(285) <= X"00000000";
dm(286) <= X"00000000";
dm(287) <= X"00000000";
dm(288) <= X"00000000";
dm(289) <= X"00000000";
dm(290) <= X"00000000";
dm(291) <= X"00000000";
dm(292) <= X"00000000";
dm(293) <= X"00000000";
dm(294) <= X"00000000";
dm(295) <= X"00000000";
dm(296) <= X"00000000";
dm(297) <= X"20000000";
dm(298) <= X"70005001";
dm(299) <= X"50012003";
dm(300) <= X"20047001";
dm(301) <= X"70025001";
dm(302) <= X"00002001";
dm(303) <= X"30010903";
dm(304) <= X"20030000";
dm(305) <= X"491E0000";
dm(306) <= X"00000D01";
dm(307) <= X"3003491B";
dm(308) <= X"29022152";
dm(309) <= X"2F002D00";
dm(310) <= X"40000000";
dm(311) <= X"20020000";
dm(312) <= X"30040000";
dm(313) <= X"00002003";
dm(314) <= X"30030D01";
dm(315) <= X"29022152";
dm(316) <= X"2F002D00";
dm(317) <= X"40000000";
dm(318) <= X"20020000";
dm(319) <= X"30030804";
dm(320) <= X"20030000";
dm(321) <= X"30020000";
dm(322) <= X"00002001";
dm(323) <= X"30010D03";
dm(324) <= X"50010000";
dm(325) <= X"30046002";
dm(326) <= X"60015001";
dm(327) <= X"50013003";
dm(328) <= X"30006000";
dm(329) <= X"00004000";
dm(330) <= X"20000000";
dm(331) <= X"70005001";
dm(332) <= X"50012003";
dm(333) <= X"20047001";
dm(334) <= X"70025001";
dm(335) <= X"00002001";
dm(336) <= X"30010903";
dm(337) <= X"21000000";
dm(338) <= X"50030804";
dm(339) <= X"21017000";
dm(340) <= X"50030804";
dm(341) <= X"21027001";
dm(342) <= X"50030804";
dm(343) <= X"21037002";
dm(344) <= X"50030804";
dm(345) <= X"21047003";
dm(346) <= X"50030804";
dm(347) <= X"21057004";
dm(348) <= X"50030804";
dm(349) <= X"21067005";
dm(350) <= X"50030804";
dm(351) <= X"21077006";
dm(352) <= X"50030804";
dm(353) <= X"20017007";
dm(354) <= X"0D030000";
dm(355) <= X"00003001";
dm(356) <= X"60025001";
dm(357) <= X"50013004";
dm(358) <= X"30036001";
dm(359) <= X"60005001";
dm(360) <= X"40003000";
dm(361) <= X"00000000";
dm(362) <= X"50012000";
dm(363) <= X"20037000";
dm(364) <= X"70015001";
dm(365) <= X"50012004";
dm(366) <= X"20017002";
dm(367) <= X"09030000";
dm(368) <= X"00003001";
dm(369) <= X"29042180";
dm(370) <= X"2F002D00";
dm(371) <= X"21003003";
dm(372) <= X"21943004";
dm(373) <= X"2D002902";
dm(374) <= X"00002F00";
dm(375) <= X"00004000";
dm(376) <= X"29062003";
dm(377) <= X"21143003";
dm(378) <= X"21943004";
dm(379) <= X"2D002902";
dm(380) <= X"00002F00";
dm(381) <= X"00004000";
dm(382) <= X"00002001";
dm(383) <= X"30010D03";
dm(384) <= X"50010000";
dm(385) <= X"30046002";
dm(386) <= X"60015001";
dm(387) <= X"50013003";
dm(388) <= X"30006000";
dm(389) <= X"00004000";
dm(390) <= X"20000000";
dm(391) <= X"70005001";
dm(392) <= X"50012003";
dm(393) <= X"20047001";
dm(394) <= X"70025001";
dm(395) <= X"00002001";
dm(396) <= X"30010903";
dm(397) <= X"21000000";
dm(398) <= X"30032904";
dm(399) <= X"29052100";
dm(400) <= X"20033004";
dm(401) <= X"70005004";
dm(402) <= X"09012004";
dm(403) <= X"20033004";
dm(404) <= X"30030D01";
dm(405) <= X"4AF60000";
dm(406) <= X"20010000";
dm(407) <= X"0D030000";
dm(408) <= X"00003001";
dm(409) <= X"60025001";
dm(410) <= X"50013004";
dm(411) <= X"30036001";
dm(412) <= X"60005001";
dm(413) <= X"40003000";
dm(414) <= X"00000000";
dm(415) <= X"50012000";
dm(416) <= X"20037000";
dm(417) <= X"70015001";
dm(418) <= X"50012004";
dm(419) <= X"20057002";
dm(420) <= X"70035001";
dm(421) <= X"00002001";
dm(422) <= X"30010904";
dm(423) <= X"210C0000";
dm(424) <= X"2D002903";
dm(425) <= X"00002F00";
dm(426) <= X"00004000";
dm(427) <= X"29042100";
dm(428) <= X"2F002D00";
dm(429) <= X"21003003";
dm(430) <= X"30042905";
dm(431) <= X"30052100";
dm(432) <= X"60005004";
dm(433) <= X"30052605";
dm(434) <= X"09012004";
dm(435) <= X"20033004";
dm(436) <= X"30030D01";
dm(437) <= X"4AF50000";
dm(438) <= X"30022005";
dm(439) <= X"00002001";
dm(440) <= X"30010D04";
dm(441) <= X"50010000";
dm(442) <= X"30056003";
dm(443) <= X"60025001";
dm(444) <= X"50013004";
dm(445) <= X"30036001";
dm(446) <= X"60005001";
dm(447) <= X"40003000";
dm(448) <= X"00000000";
dm(449) <= X"00000000";
dm(450) <= X"00000000";
dm(451) <= X"00000000";
dm(452) <= X"00000000";
dm(453) <= X"00000000";
dm(454) <= X"00000000";
dm(455) <= X"00000000";



END;

