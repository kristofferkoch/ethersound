-----------------------------------------------------------------------------
--    Delta-sigma modulator
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

entity deltasigmachannel is
	Generic(N:integer:=10);
    Port ( sysclk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           data : in  STD_LOGIC_VECTOR (N-1 downto 0);
           ds : out  STD_LOGIC);
end deltasigmachannel;

architecture Behavioral of deltasigmachannel is
	signal deltaAdder, sigmaAdder, sigmaReg, deltaB:unsigned(N+1 downto 0);
	
	constant zeros:std_logic_vector(N-1 downto 0):= (OTHERS => '0');
	signal hbit:std_logic;
begin
	hbit <= sigmaReg(N+1);
	deltaB <= unsigned(hbit & hbit & zeros);
	deltaAdder <= unsigned(data) + deltaB;
	sigmaAdder <= deltaAdder + sigmaReg;
	process(sysclk) is
	begin
		if rising_edge(sysclk) then
			if reset = '1' then
				ds <= '0';
				sigmaReg <= unsigned("01" & zeros);
			else
				sigmaReg <= sigmaAdder;
				ds <= sigmaReg(N+1);
			end if;
		end if;
	end process;

end Behavioral;

