-----------------------------------------------------------------------------
--    Rudimentary "DAC" for ouputting sound on the spartan3 starter kit
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


entity deltasigmadac is
    Port ( sysclk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           audio : in  STD_LOGIC_VECTOR (23 downto 0);
           audio_dv : in  STD_LOGIC;
           audio_left : out  STD_LOGIC;
           audio_right : out  STD_LOGIC;
			  rate_pulse:out std_logic;
			  debug:out std_logic_vector(7 downto 0));
end deltasigmadac;

architecture Behavioral of deltasigmadac is
	constant channel_bits:integer:=10;
	constant fifo_sz:integer:=2048*4;
	component deltasigmachannel
		Generic(N:integer);
		Port ( sysclk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           data : in  STD_LOGIC_VECTOR (channel_bits-1 downto 0);
           ds : out  STD_LOGIC);
	end component;
	signal left,right:std_logic_vector(23 downto 0):=(OTHERS => '0');
	signal left_t, right_t:std_logic_vector(channel_bits-1 downto 0);
	
	signal next_left, next_right:std_logic_vector(23 downto 0);
	signal fifo_read:std_logic;
	
	type wstate_t is (Idle, Busy);
	signal wstate:wstate_t;
	
	signal bytecnt:integer range 0 to 2;
	signal fifo_w:std_logic;
	signal audio_slice, fifo_out:std_logic_vector(7 downto 0);
	type ram_t is array (0 to fifo_sz-1) of std_logic_vector(7 downto 0);
	signal fifo:ram_t:=(OTHERS => (OTHERS => '0'));
	signal wp,rp,fill:integer range 0 to fifo_sz-1;
	
	signal freq_count:integer range 0 to (50000000+48000-1);
	
	signal frame_pulse:std_logic;
	signal freq_count_wrap:integer range -50000000 to 48000-1;
	
	type readstate_t is (Idle, stPause, stRight, stLeft);
	signal readstate:readstate_t;
	signal readcnt:integer range 0 to 2;
begin
	rate_pulse <= frame_pulse;
	fifo_reader:process(sysclk) is
	begin
		if rising_edge(sysclk) then
			if reset = '1' then
				readstate <= Idle;
				readcnt <= 2;
				left <= (OTHERS => '0');
				right <= (OTHERS => '0');
				next_left <= (OTHERS => '0');
				next_right <= (OTHERS => '0');
				fifo_read <= '0';
				debug(7 downto 2) <= (OTHERS => '1');
			else
				case readstate is 
					when Idle =>
						if frame_pulse = '1' and fill >= 6 then
							readstate <= stPause;
							readcnt <= 2;
							fifo_read <= '1';
							debug(2) <= '1';
						else
							report "Frame skipped" severity warning;
							debug(2) <= '0';
						end if;
						left <= next_left;
						right <= next_right;
					when stPause =>
						readstate <= stLeft;
					when stLeft =>
						next_left(readcnt*8+7 downto readcnt*8) <= fifo_out;
						if readcnt = 0 then
							readstate <= stRight;
							readcnt <= 2;
						else
							readcnt <= readcnt - 1;
						end if;
					when stRight =>
						next_right(readcnt*8+7 downto readcnt*8) <= fifo_out;
						if readcnt = 0 then
							readstate <= Idle;
							readcnt <= 2;
						else
							if readcnt = 1 then
								fifo_read <= '0';
							end if;
							readcnt <= readcnt - 1;
						end if;
				end case;
			end if;
		end if;
	end process;
	freq_count_wrap <= freq_count - 50000000;
	frame_pulse <= '1' when freq_count_wrap >= 0 else '0';
	
	framerater:process(sysclk) is
	begin
		if rising_edge(sysclk) then
			if reset = '1' then
				freq_count <= 0;
			else
				if frame_pulse = '1' then
					report "Frame is flippin";
					freq_count <= freq_count_wrap + 48000;
				else
					--report "Increasing from " & integer'image(freq_count);
					freq_count <= freq_count + 48000;
				end if;
			end if;
		end if;
	end process;
	fifo_ctrl:process(sysclk) is
	begin
		if rising_edge(sysclk) then
			if reset = '1' then
				wp <= 0;
				rp <= 0;
				fill <= 0;
				debug(1 downto 0) <= (OTHERS => '1');
			else
				if fifo_w = '1' then
					if wp = fifo_sz-1 then
						wp <= 0;
					else
						wp <= wp + 1;
					end if;
				end if;
				if fifo_read = '1' then
					if rp = fifo_sz-1 then
						rp <= 0;
					else
						rp <= rp + 1;
					end if;
				end if;
				if fifo_w = '1' and fifo_read = '0' then
					if fill = fifo_sz-1 then
						report "Fifo overflow" severity warning;
						debug(1) <= '0';
					else
						debug(1) <= '1';
						fill <= fill + 1;
					end if;
				elsif fifo_w = '0' and fifo_read = '1' then
					if fill = 0 then
						debug(0) <= '0';
						report "Fifo underflow" severity warning;
					else
						debug(0) <= '1';
						fill <= fill - 1;
					end if;
				end if;
			end if;
		end if;
	end process;
	process(sysclk) is
	begin
		if rising_edge(sysclk) then
			if reset = '1' then
				wstate <= Idle;
				bytecnt <= 2;
				fifo_w <= '0';
			else
				case wstate is
					when Idle =>
						if audio_dv = '1' then
							wstate <= Busy;
							fifo_w <= '1';
						end if;
						bytecnt <= 2;
					when Busy =>
						if bytecnt = 0 then
							wstate <= Idle;
							bytecnt <= 2;
							fifo_w <= '0';
						else
							bytecnt <= bytecnt - 1;
						end if;
				end case;
			end if;
		end if;
	end process;
	audio_slice <= audio(bytecnt*8+7 downto bytecnt*8);
	ram:process(sysclk) is
	begin
		if rising_edge(sysclk) then
			if fifo_w = '1' then
				fifo(wp) <= audio_slice;
			end if;
			fifo_out <= fifo(rp);
		end if;
	end process;

	left_t  <= left(23 downto 24-channel_bits);
	right_t <= right(23 downto 24-channel_bits);
	left_dsc: deltasigmachannel generic map (
			N => channel_bits
		) Port map ( 
			sysclk => sysclk,
         reset => reset,
			data => left_t,
         ds => audio_left
		);
	right_dsc: deltasigmachannel generic map (
			N => channel_bits
		)  Port map ( 
			sysclk => sysclk,
         reset => reset,
			data => right_t,
			ds => audio_right
		);

end Behavioral;

