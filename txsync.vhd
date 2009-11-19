-----------------------------------------------------------------------------
--    Module for transmitting data from the 50MHz byte-format to the 25MHz
--    PHY nibble-format. Adds preamble, SFD and CRC.
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

entity txsync is
    Port ( sysclk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           tx_clk : in  STD_LOGIC;
           txd : out  STD_LOGIC_VECTOR (3 downto 0);
           tx_dv : out  STD_LOGIC;
           data : in  STD_LOGIC_VECTOR (7 downto 0);
           data_send : in  STD_LOGIC;
           data_req : out  STD_LOGIC;
			  debug:out std_logic_vector(7 downto 0)
		);
end txsync;

architecture RTL of txsync is
  
	signal byte_latch:std_logic_vector(7 downto 0):=(OTHERS => '0');
	signal req:std_logic:='0';
	signal req_ccd:std_logic_vector(2 downto 0):=(OTHERS => '0');
	
	type state_t is (Idle, IdleWait, Preamble, SFD, Data0, Data1, stCRC);
	signal state, nextstate:state_t:=Idle;
	signal count:integer range 0 to 14:=0;
	
	signal rst:std_logic;
	
	signal tx_dv_d:std_logic;
	signal crcnibble, txd_d:std_logic_vector(3 downto 0);
	signal crc, nextcrc:std_logic_vector(31 downto 0);
begin
	rst <= reset;
	data_req <= '1' when req_ccd(2) /= req_ccd(1) else '0';
	
	req_synchronizer:process(sysclk) is
	begin
		if rising_edge(sysclk) then
			if rst = '1' then
				req_ccd <= (OTHERS => '0');
			else
				req_ccd(0) <= req;
				req_ccd(1) <= req_ccd(0);
				req_ccd(2) <= req_ccd(1);
			end if;
		end if;
	end process;
	
	crcnibble(0) <= crc(31);
	crcnibble(1) <= crc(30);
	crcnibble(2) <= crc(29);
	crcnibble(3) <= crc(28);
	txd_d <=		x"5"							when state = Preamble
			else	x"d"							when state = SFD
			else	byte_latch(3 downto 0)	when state = Data0
			else	byte_latch(7 downto 4)	when state = Data1
			else	not crcnibble				when state = stCRC
			else	"0000";
	tx_dv_d <= '1' when state /= Idle and state /= IdleWait else '0';
	txreg:process(tx_clk) begin
		if rising_edge(tx_clk) then
			if rst = '1' then
				txd <= "0000";
				tx_dv <= '0';
			else
				txd <= txd_d;
				tx_dv <= tx_dv_d;
			end if;
		end if;
	end process;
	nextcrc <=		Crc32_4(txd_d, crc, '1')	when state = Data0 or state = Data1
				else	Crc32_4("0000", crc, '0')	when state = stCRC
				else	(OTHERS => '1');
				
	nextstate <= 	IdleWait	when (state = Idle and data_send = '0')
				else	Preamble	when (state = Idle or (state=Preamble and count /= 0))
				else	SFD		when state = Preamble
				else	Data0		when (state = SFD or (state = Data1 and data_send = '1'))
				else	Data1		when state = Data0 
				else	stCRC		when (state = Data1 or (state=stCRC and count /= 0))
				else	Idle;
	process(tx_clk) begin
		if rising_edge(tx_clk) then
			if rst = '1' then
				crc <= (OTHERS => '1');
				state <= Idle;
				byte_latch <= x"00";
				req <= '0';
			else
				crc <= nextcrc;
				state <= nextstate;
				if state = Idle then
					count <= 14;
				elsif state = Data1 or state = Data0 then
					count <= 7;
				elsif count /= 0 then
					count <= count - 1;
				end if;
				if state = IdleWait or state = Data1 then
					byte_latch <= data;
					req <= not req;
				end if;
			end if;
		end if;
	end process;
end RTL;