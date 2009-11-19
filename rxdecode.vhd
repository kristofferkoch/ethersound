-----------------------------------------------------------------------------
--    Module for decoding received frames.
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

entity rxdecode is
    Port ( sysclk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           data : in  STD_LOGIC_VECTOR (7 downto 0);
           data_dv : in  STD_LOGIC;
           data_end : in  STD_LOGIC;
           data_err : in  STD_LOGIC;
           audio : out  STD_LOGIC_VECTOR (23 downto 0);
           audio_dv : out  STD_LOGIC;
			  
			  cmd:out unsigned(15 downto 0);
			  cmd_len:out unsigned(7 downto 0);
			  cmd_d:out std_logic_vector(7 downto 0);
			  cmd_dv:out std_logic;
			  
			  debug: out std_logic_vector(7 downto 0)
			);
end rxdecode;

architecture Behavioral of rxdecode is
	type state_t is (Idle, rxDest, rxSource, rxType, rxMagic, rxCmd, rxCmdLen, rxCmdParam, rxAudio, Drop);
	signal state:state_t;
	signal counter:integer range 0 to 255;
	type byte_ary is array (0 to 6) of std_logic_vector(7 downto 0); --7 bytes = 3 bytes audio + 4 bytes CRC
	signal inbuf:byte_ary;
	signal cmd_s:unsigned(7 downto 0);
begin
	audio <= inbuf(0) & inbuf(1) & inbuf(2);
	process(sysclk) is
		variable audio_dv_v:std_logic;
	begin
		if rising_edge(sysclk) then
			if reset = '1' then
				state <= Idle;
				debug <= (OTHERS => '1');
				audio_dv <= '0';
				inbuf <= (OTHERS => (OTHERS => '0'));
			else
				audio_dv_v := '0';
				case state is
					when rxDest =>
						debug(0) <= '0';
						if data_end = '1' then
							state <= Idle;
						elsif data_dv = '1' then
							if data = x"ff" then
								if counter = 0 then
									state <= rxSource;
									counter <= 5;
								else
									counter <= counter - 1;
								end if;
							else
								state <= Drop;
							end if;
						end if;
					when rxSource =>
						debug(1) <= '0';
						if data_end = '1' then
							state <= Idle;
						elsif data_dv = '1' then
							if counter = 0 then
								state <= rxType;
								counter <= 1;
							else
								counter <= counter - 1;
							end if;
						end if;
					when rxType =>
						debug(2) <= '0';
						if data_end = '1' then
							state <= Idle;
						elsif data_dv = '1' then
							if counter = 0 then
								if data = x"b5" then
									state <= rxMagic;
									counter <= 1;
								else
									state <= Drop;
								end if;
							else --counter = 1
								if data /= x"88" then
									state <= Drop;
								end if;
								counter <= counter - 1;
							end if;
						end if;
					when RxMagic =>
						if data_end = '1' then
							state <= Idle;
						elsif data_dv = '1' then
							if counter = 0 then
								if data = x"0d" then
									state <= rxCmd;
									counter <= 1;
								else
									state <= Drop;
								end if;
							else --counter = 1
								if data /= x"f0" then
									state <= Drop;
								end if;
								counter <= counter - 1;
							end if;
						end if;
					when rxCmd =>
						debug(3) <= '0';
						cmd_dv <= '0';
						if data_end = '1' then
							state <= Idle;
						elsif data_dv = '1' then
							if counter = 0 then
								if cmd_s = x"00" and data = x"00" then
									state <= rxAudio;
									counter <= 8;
								else
									cmd(15 downto 8) <= cmd_s;
									cmd(7 downto 0) <= unsigned(data);
									state <= rxCmdLen;
								end if;
							else --counter = 1
								cmd_s(7 downto 0) <= unsigned(data);
							end if;
						end if;
					when rxCmdLen =>
						debug(5) <= '0';
						if data_end = '1' then
							state <= Idle;
						elsif data_dv = '1' then
							cmd_len <= unsigned(data);
							counter <= to_integer(unsigned(data));
							state <= rxCmdParam;
						end if;					
					when rxCmdParam =>
						debug(6) <= '0';
						if data_end = '1' then
							state <= Idle;
						elsif data_dv = '1' then
							cmd_dv <= '1';
							cmd_d <= data;
							if counter = 0 then
								state <= rxCmd;
							else
								counter <= counter - 1;
							end if;
						else
							cmd_dv <= '0';
						end if;
					when rxAudio =>
						debug(4) <= '0';
						if data_end = '1' and data_err = '0' then
							--Last 4 bytes was crc. Discard them.
							-- that is, counter should be 1 (1 crc-byte in framebuf)
							-- and 3 crc-bytes in framebuf2
							state <= Idle;
						elsif data_end = '1' and data_err = '1' then
							--Premature data-end. Discard current frame
							state <= Idle;
						elsif data_dv = '1' then
							inbuf(6) <= data;
							for i in 5 downto 0 loop
								inbuf(i) <= inbuf(i+1);
							end loop;
							if counter = 0 then
								counter <= 2;
							else
								counter <= counter - 1;
								if counter = 2 then
									audio_dv_v := '1';
								end if;
							end if;
						end if;					
					when Drop =>
						debug(7) <= '0';
						if data_end = '1' then
							state <= Idle;
						end if;
					when others => --Idle
						if data_dv = '1' then
							debug <= (OTHERS => '1');
							if data = x"ff" then
								state <= rxDest;
								counter <= 4;
							else
								state <= Drop;
							end if;
						end if;
				end case;
				audio_dv <= audio_dv_v;
			end if;
		end if;
	end process;

end Behavioral;

