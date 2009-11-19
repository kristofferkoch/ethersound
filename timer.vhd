-----------------------------------------------------------------------------
--    Adjustable timer-module. Provides a monotonic increasing tunable
--    clock
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
USE ieee.numeric_std.ALL;

entity timer is
	Generic(F_SYS:real:=50.0e6);
	Port (
		reset : in  STD_LOGIC;
		sysclk : in  STD_LOGIC;
		load : in  unsigned (63 downto 0);
		load_en : in  STD_LOGIC;
		time_o : out  unsigned (63 downto 0);
		ppm : in  signed (9 downto 0)
	);
end timer;

architecture Behavioral of timer is
	constant PERIOD_ADD_R:real:=1048576.0e9/F_SYS;
	constant PERIOD_ADD:signed(29 downto 0):=to_signed(integer(PERIOD_ADD_R),30);
	constant PERIOD_MP_R:real:=1024.0e6/F_SYS;
	constant PERIOD_MP:signed(10 downto 0):=to_signed(integer(PERIOD_MP_R), 11);
	signal time_s:unsigned(83 downto 0); -- in nano-seconds/1024^2=~femto seconds
	signal correction:signed(20 downto 0);
	signal delta:unsigned(29 downto 0);
begin
	time_o <= time_s(83 downto 20);
	correction <= ppm*PERIOD_MP;
	delta <= unsigned(PERIOD_ADD + correction);
	process(reset, sysclk) is begin
		if rising_edge(sysclk) then
			if reset = '1' then
				time_s <= (OTHERS => '0');
			else
				if load_en = '1' then
					time_s(83 downto 20) <= load;
					time_s(19 downto 0) <= (OTHERS => '0');
				else
					time_s <= time_s + delta;
				end if;
			end if;
		end if;
	end process;

end Behavioral;
