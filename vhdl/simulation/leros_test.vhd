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
			icempty : in std_logic
        );
    END COMPONENT;
    
	type IMEM_STATE_T is (WAIT_FOR_REQ,TRANSFER);
	signal state : IMEM_STATE_T := WAIT_FOR_REQ;

	-- the data ram
	constant nwords : integer := 2 ** 10;
	type ram_type is array(0 to nwords-1) of std_logic_vector(31 downto 0);
	signal dm : ram_type;
	

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
			 icempty => icempty
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
dm(1) <= X"2901214c";
dm(2) <= X"2f032d02";
dm(3) <= X"212a3000";
dm(4) <= X"40010000";
dm(5) <= X"30002165";
dm(6) <= X"0000212a";
dm(7) <= X"21724001";
dm(8) <= X"212a3000";
dm(9) <= X"40010000";
dm(10) <= X"3000216f";
dm(11) <= X"0000212a";
dm(12) <= X"21734001";
dm(13) <= X"212a3000";
dm(14) <= X"40010000";
dm(15) <= X"3000210d";
dm(16) <= X"0000212a";
dm(17) <= X"210a4001";
dm(18) <= X"212a3000";
dm(19) <= X"40010000";
dm(20) <= X"00004800";
dm(21) <= X"23013c00";
dm(22) <= X"49fd0000";
dm(23) <= X"38012000";
dm(24) <= X"00002001";
dm(25) <= X"00004001";
dm(26) <= X"00000000";
dm(27) <= X"00000000";
dm(28) <= X"00000000";
dm(29) <= X"00000000";
dm(30) <= X"00000000";
dm(31) <= X"00000000";

END;
