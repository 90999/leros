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
--USE ieee.numeric_std.ALL;
 
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
			ser_rxd : in std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
	signal ser_rxd : std_logic := '0';

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
			 ser_txd => ser_txd
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
		rstx <= '1';
		
      wait for 100 ns;	

		rstx <= '0';
      wait for clk_period*10;


      -- insert stimulus here 

      wait;
   end process;

END;
