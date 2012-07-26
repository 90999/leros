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
dm(1) <= X"29042100";
dm(2) <= X"21093001";
dm(3) <= X"40000000";
dm(4) <= X"00000000";
dm(5) <= X"50012000";
dm(6) <= X"20037000";
dm(7) <= X"70015001";
dm(8) <= X"00002001";
dm(9) <= X"30010902";
dm(10) <= X"2901214c";
dm(11) <= X"2f032d02";
dm(12) <= X"21673003";
dm(13) <= X"40000000";
dm(14) <= X"30032165";
dm(15) <= X"00002167";
dm(16) <= X"21724000";
dm(17) <= X"21673003";
dm(18) <= X"40000000";
dm(19) <= X"3003216f";
dm(20) <= X"00002167";
dm(21) <= X"21734000";
dm(22) <= X"21673003";
dm(23) <= X"40000000";
dm(24) <= X"3003210d";
dm(25) <= X"00002167";
dm(26) <= X"210a4000";
dm(27) <= X"21673003";
dm(28) <= X"40000000";
dm(29) <= X"21710000";
dm(30) <= X"40000000";
dm(31) <= X"21740000";
dm(32) <= X"21673003";
dm(33) <= X"40000000";
dm(34) <= X"210a0000";
dm(35) <= X"21913003";
dm(36) <= X"2d002900";
dm(37) <= X"00002f00";
dm(38) <= X"00004000";
dm(39) <= X"30032175";
dm(40) <= X"00002167";
dm(41) <= X"00004000";
dm(42) <= X"38002002";
dm(43) <= X"00004800";
dm(44) <= X"00002001";
dm(45) <= X"30010d02";
dm(46) <= X"50010000";
dm(47) <= X"00006001";
dm(48) <= X"50013003";
dm(49) <= X"00006000";
dm(50) <= X"40003000";
dm(51) <= X"3c000000";
dm(52) <= X"00002301";
dm(53) <= X"200349fd";
dm(54) <= X"20003801";
dm(55) <= X"40000000";
dm(56) <= X"00000000";
dm(57) <= X"50012000";
dm(58) <= X"20037000";
dm(59) <= X"70015001";
dm(60) <= X"00002001";
dm(61) <= X"30010902";
dm(62) <= X"30032173";
dm(63) <= X"00002167";
dm(64) <= X"00004000";
dm(65) <= X"00002001";
dm(66) <= X"30010d02";
dm(67) <= X"50010000";
dm(68) <= X"00006001";
dm(69) <= X"50013003";
dm(70) <= X"00006000";
dm(71) <= X"40003000";
dm(72) <= X"00000000";
dm(73) <= X"50012000";
dm(74) <= X"20037000";
dm(75) <= X"70015001";
dm(76) <= X"50012004";
dm(77) <= X"20017002";
dm(78) <= X"09030000";
dm(79) <= X"20033001";
dm(80) <= X"491e0000";
dm(81) <= X"00000d01";
dm(82) <= X"3003491b";
dm(83) <= X"29002191";
dm(84) <= X"2f002d00";
dm(85) <= X"40000000";
dm(86) <= X"20020000";
dm(87) <= X"30040000";
dm(88) <= X"00002003";
dm(89) <= X"30030d01";
dm(90) <= X"29002191";
dm(91) <= X"2f002d00";
dm(92) <= X"40000000";
dm(93) <= X"20020000";
dm(94) <= X"30030804";
dm(95) <= X"20030000";
dm(96) <= X"30020000";
dm(97) <= X"00002001";
dm(98) <= X"30010d03";
dm(99) <= X"50010000";
dm(100) <= X"00006002";
dm(101) <= X"50013004";
dm(102) <= X"00006001";
dm(103) <= X"50013003";
dm(104) <= X"00006000";
dm(105) <= X"40003000";
dm(106) <= X"00000000";
dm(107) <= X"00000000";
dm(108) <= X"00000000";
dm(109) <= X"00000000";
dm(110) <= X"00000000";
dm(111) <= X"00000000";




END;
