-----------------------------------------------------------------------------
--    Module for transfering data from the 25MHz phy-clock nibble domain to 
--    50MHz byte clock-domain. Also strips away preamble and SFD.
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

use work.crc.all;

entity rxsync is
	Generic (reset_en:std_logic:='1');
    Port ( sysclk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           rx_clk : in  STD_LOGIC;
           rxd : in  STD_LOGIC_VECTOR (3 downto 0);
           rx_dv : in  STD_LOGIC;
           data : out  STD_LOGIC_VECTOR (7 downto 0);
			  data_end : out std_logic;
			  data_err : out std_logic;
           data_dv : out  STD_LOGIC;
			  crc_ok: out std_logic;
			  
			  debug:out std_logic_vector(7 downto 0)
			);
end rxsync;

architecture Behavioral of rxsync is
	signal rst:std_logic;
	-- rx_clk clockdomain
	--  inreg latches rxd on rising rx_clk
	signal inreg:std_logic_vector(3 downto 0);
	signal inbytereg:std_logic_vector(8 downto 0);
	signal crcreg, nextcrc:std_logic_vector(31 downto 0);
	signal crcnibble:std_logic_vector(3 downto 0);
	signal eod, err, crc:std_logic:='0';
	signal dv_ccd:std_logic:='0';

	type state_t is (Idle, Preamble, SFD, data0, data1);
	signal state:state_t:=Idle;
	
	-- sysclk clockdomain
	signal dv_sync:std_logic_vector(2 downto 0);
	signal dv_edge:std_logic;
	
begin
	rst <= reset_en and reset;
	nextcrc <=		Crc32_4(rxd, crcreg, '1')	when state = Data0 or state = Data1
				else	(OTHERS => '1');
				
	fsm:process(rx_clk) is
		variable eod_v, err_v, crc_v:std_logic;
	begin
		if rising_edge(rx_clk) then
			if rst = '1' then
				state <= Idle;
				err <= '0';
				eod <= '0';
				crc <= '0';
				debug(3 downto 0) <= (OTHERS => '1');
			else
				if err = '1' and eod = '0' then
					eod_v := '1';
					err_v := '1';
				else
					eod_v := '0';
					err_v := '0';
				end if;
				crc_v := '0';
				case state is
					when Preamble =>
						debug(0) <= '0';
						if rx_dv = '1' then
							if rxd = x"5" then
								state <= SFD;
							end if;
						else
							state <= Idle;
						end if;
					when SFD =>
						debug(1) <= '0';
						if rx_dv = '1' then
							if rxd = x"d" then
								state <= data0;
							elsif rxd /= x"5" then
								state <= Preamble;
							end if;
						else
							state <= Idle;
						end if;
					when data0 =>
						debug(2) <= '0';
						if rx_dv = '1' then
							state <= data1;
						else
							eod_v := '1';
							if crcreg = x"12345678" then
								crc_v := '1';
							end if;
							state <= Idle;
						end if;
					when data1 =>
						debug(3) <= '0';
						if rx_dv = '1' then
							state <= data0;
						else
							err_v := '1';
							state <= Idle;
						end if;
					when others => --Idle
						if rx_dv = '1' then
							if rxd = x"5" then
								state <= SFD;
							else
								state <= Preamble;
							end if;
						end if;
				end case;
				err <= err_v;
				eod <= eod_v;
				crc <= crc_v;
			end if;
		end if;
	end process;
	process(rx_clk) is
	begin
		if rising_edge(rx_clk) then
			if rst = '1' then
				inreg <= (OTHERS => '0');
				inbytereg <= (OTHERS => '0');
				dv_ccd <= '0';
				crcreg <= (OTHERS => '1');
			else
				crcreg <= nextcrc;
				inreg <= rxd;
				if eod = '1' then
					inbytereg <= "1000000" & crc & err;
					dv_ccd <= not dv_ccd;
				elsif state = data1 then
					inbytereg <= '0' & rxd & inreg;
					dv_ccd <= not dv_ccd;
				end if;
			end if;
		end if;
	end process;
	
	process(sysclk) is
		variable data_dv_v, data_err_v, data_end_v, crc_ok_v:std_logic;
	begin
		if rising_edge(sysclk) then
			if rst = '1' then
				dv_sync <= (OTHERS => '0');
				data_dv <= '0';
				data_end <= '0';
				data_err <= '0';
				data <= (OTHERS => '0');
				debug(7 downto 4) <= (OTHERS => '1');
			else
				dv_sync(0) <= dv_ccd;
				dv_sync(1) <= dv_sync(0);
				dv_sync(2) <= dv_sync(1);
				
				data_dv_v := '0';
				data_err_v := '0';
				data_end_v := '0';
				crc_ok_v := '0';
				if dv_edge = '1' then
					if inbytereg(8) = '0' then
						data <= inbytereg(7 downto 0);
						data_dv_v := '1';
						debug(4) <= '0';
					else 
						data_err_v := inbytereg(0);
						crc_ok_v := inbytereg(1);
						data_end_v := '1';
						debug(5) <= '0';
					end if;
				end if;
				data_dv <= data_dv_v;
				data_err <= data_err_v;
				crc_ok <= crc_ok_v;
				data_end <= data_end_v;
			end if;
		end if;
	end process;
	dv_edge <= dv_sync(1) xor dv_sync(2);
end Behavioral;

