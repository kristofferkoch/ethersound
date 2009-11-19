-----------------------------------------------------------------------------
--    Packet generator for hwpulse 
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



entity packetgen is
    Port ( sysclk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           rate_pulse : in  STD_LOGIC;
           edata_o : out  STD_LOGIC_VECTOR (7 downto 0);
           edata_o_v : out  STD_LOGIC;
           edata_o_req : in  STD_LOGIC;
           debug : out  STD_LOGIC_VECTOR (7 downto 0));
end packetgen;

architecture RTL of packetgen is
	type state_t is (Idle, txDest, txSource, txType, txCmd, txCmdLen, txCmdParam, Pad, stWait);
	signal state, retstate:state_t;
	signal framecounter,fcnt_buf:unsigned(63 downto 0);
	signal sendcount:integer range 0 to 511;
	signal cnt:integer range 0 to 7;
	signal remain:integer range 0 to 45;
	
	constant MAC:std_logic_vector(47 downto 0):=x"000a35002201";
begin
	fcnt:process(sysclk) is
	begin
		if rising_edge(sysclk) then
			if reset = '1' then
				framecounter <= to_unsigned(0, 64);
				sendcount <= 0;
			else
				if rate_pulse = '1' then
					framecounter <= framecounter + 1;
					if sendcount = 511 then
						sendcount <= 0;
					else
						sendcount <= sendcount + 1;
					end if;
				end if;
			end if;
		end if;
	end process;
	fsm:process(sysclk) is
	begin
		if rising_edge(sysclk) then
			if reset = '1' then
				state <= Idle;
				edata_o_v <= '0';
				edata_o <= (OTHERS => '0');
			else
				case state is
					when Idle =>
						if edata_o_req = '1' then
							edata_o_v <= '0';
						end if;
						if sendcount = 0 then
							state <= txDest;
						end if;
						remain <= 45;
						cnt <= 5;
					when txDest =>
						if edata_o_req = '1' then
							edata_o_v <= '1';
							edata_o <= x"ff";
							if cnt = 0 then
								retstate <= txSource;
								cnt <= 5;
							else
								cnt <= cnt - 1;								
								retstate <= state;
							end if;
							state <= stWait;
						end if;
					when stWait =>
						state <= retstate;
					when txSource =>
						if edata_o_req = '1' then
							edata_o_v <= '1';
							edata_o <= MAC(cnt*8+7 downto cnt*8);
							if cnt = 0 then
								state <= txType;
								cnt <= 1;
							else
								cnt <= cnt - 1;
							end if;
						end if;
					when txType =>
						if edata_o_req = '1' then
							edata_o_v <= '1';
							if cnt = 0 then
								edata_o <= x"b5";
								state <= txCmd;
							else
								edata_o <= x"88";
								cnt <= cnt - 1;
							end if;
						end if;
					when txCmd =>
						if edata_o_req = '1' then
							edata_o_v <= '1';
							edata_o <= x"01";
							state <= txCmdLen;
							remain <= remain - 1;
						end if;
					when txCmdLen =>
						if edata_o_req = '1' then
							edata_o_v <= '1';
							edata_o <= x"08";
							cnt <= 7;
							state <= txCmdParam;
							fcnt_buf <= framecounter;
							remain <= remain - 1;
						end if;
					when txCmdParam =>
						if edata_o_req = '1' then
							edata_o_v <= '1';
							remain <= remain - 1;
							edata_o <= std_logic_vector(fcnt_buf(cnt*8+7 downto cnt*8));
							if cnt = 0 then
								if remain /= 0 then
									state <= Pad;
								else
									state <= Idle;
								end if;
							else
								cnt <= cnt - 1;
							end if;
						end if;
					when Pad =>
						if edata_o_req = '1' then
							edata_o_v <= '1';
							edata_o <= x"00";
							if remain = 0 then
								state <= Idle;
							else
								remain <= remain - 1;
							end if;
						end if;
				end case;
			end if;
		end if;
	end process;

end RTL;

