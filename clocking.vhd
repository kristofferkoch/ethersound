-----------------------------------------------------------------------------
--    Module for 50Mhz clock-generating on a Spartan 3 for hwpulse 
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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


library UNISIM;
use UNISIM.VComponents.all;

entity clocking is
	Port (
		clk_in	: in std_logic;
		rst		: in std_logic;
		clk1x		: out std_logic;
		clk_div	: out std_logic;
		lock	: out std_logic
	);
end clocking;

architecture clocking_arch of clocking is
	signal gnd, clk_div_w, clk0_w, clkdv_w, clk1x_w:std_logic;
	signal lock_s:std_logic:='1';
begin
lock <= lock_s;
gnd <= '0';
clk_div <= clk_div_w;
clk1x <= clk1x_w;
DCM_inst : DCM_SP
	generic map (
		CLKDV_DIVIDE => 2.0, -- Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5
									 --     7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
		CLKFX_DIVIDE => 1,    -- Can be any interger from 1 to 32
		CLKFX_MULTIPLY => 4, -- Can be any Integer from 1 to 32
		CLKIN_DIVIDE_BY_2 => FALSE, -- TRUE/FALSE to enable CLKIN divide by two feature
		CLKIN_PERIOD => 20.0,           -- Specify period of input clock
		CLKOUT_PHASE_SHIFT => "NONE", -- Specify phase shift of NONE, FIXED or VARIABLE
		CLK_FEEDBACK => "1X",          -- Specify clock feedback of NONE, 1X or 2X
		DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS", -- SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or
															 --     an Integer from 0 to 15
		DFS_FREQUENCY_MODE => "LOW",      -- HIGH or LOW frequency mode for frequency synthesis
		DLL_FREQUENCY_MODE => "LOW",      -- HIGH or LOW frequency mode for DLL
		DUTY_CYCLE_CORRECTION => TRUE, -- Duty cycle correction, TRUE or FALSE
		FACTORY_JF => X"C080",           -- FACTORY JF Values
		PHASE_SHIFT => 0,         -- Amount of fixed phase shift from -255 to 255
		STARTUP_WAIT => FALSE) -- Delay configuration DONE until DCM_SP LOCK, TRUE/FALSE
	port map (
		CLK0 => clk0_w,      -- 0 degree DCM_SP CLK ouptput
		CLK180 => open, -- 180 degree DCM_SP CLK output
		CLK270 => open, -- 270 degree DCM_SP CLK output
		CLK2X => open,    -- 2X DCM_SP CLK output
		CLK2X180 => open, -- 2X, 180 degree DCM_SP CLK out
		CLK90 => open,    -- 90 degree DCM_SP CLK output
		CLKDV => clkdv_w,    -- Divided DCM_SP CLK out (CLKDV_DIVIDE)
		CLKFX => open,    -- DCM_SP CLK synthesis out (M/D)
		CLKFX180 => open, -- 180 degree CLK synthesis out
		LOCKED => lock_s, -- DCM_SP LOCK status output
		PSDONE => open, -- Dynamic phase adjust done output
		STATUS => open, -- 8-bit DCM_SP status bits output
		CLKFB => clk1x_w,    -- DCM_SP clock feedback
		CLKIN => clk_in,    -- Clock input (from IBUFG, BUFG or DCM_SP)
		PSCLK => gnd,    -- Dynamic phase adjust clock input
		PSEN => gnd,      -- Dynamic phase adjust enable input
		PSINCDEC => gnd, -- Dynamic phase adjust increment/decrement
		RST => rst         -- DCM_SP asynchronous reset input
	);
	
	u0_bufg: bufg
	port map (
		i => clk0_w,
		o => clk1x_w
	);
	u1_bufg: bufg
	port map (
		i => clkdv_w,
		o => clk_div_w
	);

end clocking_arch;

