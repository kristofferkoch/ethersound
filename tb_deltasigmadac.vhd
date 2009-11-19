-----------------------------------------------------------------------------
--    Testbench for deltasigmadac 
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
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;
 
ENTITY tb_deltasigmadac IS
END tb_deltasigmadac;
 
ARCHITECTURE behavior OF tb_deltasigmadac IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
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
   signal audio : std_logic_vector(23 downto 0) := (others => '0');
   signal audio_dv : std_logic := '0';

 	--Outputs
   signal audio_left : std_logic;
   signal audio_right : std_logic;

   -- Clock period definitions
   constant sysclk_period : time := 20 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: deltasigmadac PORT MAP (
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
 

   -- Stimulus process
   stim_proc: process
   begin		
		reset <= '1';
      wait for sysclk_period*10;
		reset <= '0';
		wait for sysclk_period;
		
		
		audio_dv <= '1';
      audio <= x"123456";
		wait for sysclk_period;
		audio_dv <= '0';
		wait for sysclk_period*4;
		
		audio_dv <= '1';
      audio <= x"FFFFFF";
		wait for sysclk_period;
		audio_dv <= '0';
		wait for sysclk_period*4;
		
      wait;
   end process;

END;
