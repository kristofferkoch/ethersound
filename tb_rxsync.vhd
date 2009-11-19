-----------------------------------------------------------------------------
--    Testbench for rxsync 
--
--    Authors: 
--      -- Kristoffer E. Koch
-----------------------------------------------------------------------------
--    Copyright 2008 Authors
--
--    This file is part of hwpulse.
--
--    hwpulse is free software: you can redistribute it and/or modify
--    it under the terms of the GNU General Public License as published by
--    the Free Software Foundation, either version 3 of the License, or
--    (at your option) any later version.
--
--    hwpulse is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU General Public License for more details.
--
--    You should have received a copy of the GNU General Public License
--    along with hwpulse.  If not, see <http://www.gnu.org/licenses/>.
-----------------------------------------------------------------------------

LIBRARY ieee;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;
 
ENTITY tb_rxsync IS
END tb_rxsync;
 
ARCHITECTURE behavior OF tb_rxsync IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT rxsync
    PORT(
         sysclk : IN  std_logic;
         reset : IN  std_logic;
         rx_clk : IN  std_logic;
         rxd : IN  std_logic_vector(3 downto 0);
         rx_dv : IN  std_logic;
         data : OUT  std_logic_vector(7 downto 0);
         data_end : OUT  std_logic;
         data_err : OUT  std_logic;
         data_dv : OUT  std_logic;
			  debug:out std_logic_vector(7 downto 0)
        );
    END COMPONENT;
	 COMPONENT rxdecode
		Port ( sysclk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           data : in  STD_LOGIC_VECTOR (7 downto 0);
           data_dv : in  STD_LOGIC;
           data_end : in  STD_LOGIC;
           data_err : in  STD_LOGIC;
           audio : out  STD_LOGIC_VECTOR (23 downto 0);
           audio_dv : out  STD_LOGIC;
			  debug:out std_logic_vector(7 downto 0));
	 END COMPONENT;
    COMPONENT deltasigmadac
    PORT(
         sysclk : IN  std_logic;
         reset : IN  std_logic;
         audio : IN  std_logic_vector(23 downto 0);
         audio_dv : IN  std_logic;
         audio_left : OUT  std_logic;
         audio_right : OUT  std_logic
        );
    END COMPONENT;

   --Inputs
   signal sysclk : std_logic := '0';
   signal reset : std_logic := '0';
   signal rx_clk : std_logic := '0';
   signal rxd : std_logic_vector(3 downto 0) := (others => '0');
   signal rx_dv : std_logic := '0';

 	--Outputs
   signal data : std_logic_vector(7 downto 0);
   signal data_end : std_logic;
   signal data_err : std_logic;
   signal data_dv : std_logic;

   -- Clock period definitions
   constant sysclk_period : time := 20 ns;
   constant rx_clk_period : time := 40 ns;
	
	signal audio:std_logic_vector(23 downto 0);
	signal audio_dv,audio_left, audio_right:std_logic;
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: rxsync PORT MAP (
          sysclk => sysclk,
          reset => reset,
          rx_clk => rx_clk,
          rxd => rxd,
          rx_dv => rx_dv,
          data => data,
          data_end => data_end,
          data_err => data_err,
          data_dv => data_dv,
			 debug => open
        );
	uut2:rxdecode PORT MAP (
			sysclk => sysclk,
			reset => reset,
			data => data,
			data_dv => data_dv,
			data_end => data_end,
			data_err => data_err,
			audio => audio,
			audio_dv => audio_dv,
			debug => open
		);
	uut3: deltasigmadac PORT MAP (
          sysclk => sysclk,
          reset => reset,
          audio => audio,
          audio_dv => audio_dv,
          audio_left => audio_left,
          audio_right => audio_right
        );
   -- Clock process definitions
   sysclk_process :process
   begin
		sysclk <= '0';
		wait for sysclk_period/2;
		sysclk <= '1';
		wait for sysclk_period/2;
   end process;
 
   rx_clk_process :process
   begin
		rx_clk <= '0';
		wait for rx_clk_period/2;
		rx_clk <= '1';
		wait for rx_clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
		variable v:std_logic_vector(23 downto 0);
   begin		
		reset <= '1';
      wait for rx_clk_period*10;
		reset <= '0';
		wait for rx_clk_period;
		rx_dv <= '1';
		-- Preamble:
		rxd <= x"5";wait for rx_clk_period;
		rxd <= x"d";wait for rx_clk_period;
		-- dest MAC:
		for i in 0 to 11 loop
			rxd <= x"F";wait for rx_clk_period;
		end loop;
		-- source MAC:
		for i in 0 to 11 loop
			rxd <= x"0";wait for rx_clk_period;
		end loop;
		
		-- type:
		rxd <= x"8";wait for rx_clk_period;
		rxd <= x"8";wait for rx_clk_period;
		rxd <= x"5";wait for rx_clk_period;
		rxd <= x"b";wait for rx_clk_period;
		
		-- End command:
		rxd <= x"0";wait for rx_clk_period;
		rxd <= x"0";wait for rx_clk_period;
		
		-- "Audio" data:
		for c in 64 to 127 loop
			v := std_logic_vector(to_unsigned(c, 7)) & "00000000000000000"; 
			report "Sending " & integer'image(c);
			rxd <= v(19 downto 16);wait for rx_clk_period;
			rxd <= v(23 downto 20);wait for rx_clk_period;
			rxd <= v(11 downto 8);wait for rx_clk_period;
			rxd <= v(15 downto 12);wait for rx_clk_period;
			rxd <= v(3 downto 0);wait for rx_clk_period;
			rxd <= v(7 downto 4);wait for rx_clk_period;
		end loop;
		report "Sender crc";
		-- "CRC":
		for i in 0 to 7 loop
			rxd <= x"F";wait for rx_clk_period;
		end loop;
		rx_dv <= '0';
		report "Ferdii med sending";
      wait;
   end process;

END;
