-----------------------------------------------------------------------------
--    Module for interfacing the PHY MDC for the mdc 
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

entity miim is
	generic (
		DIVISOR		: integer := 30;
		PHYADDR		: std_logic_vector(4 downto 0) := "00000"
	);
	port (
		sysclk		: in std_logic;
		reset			: in std_logic;
		
		addr			: in std_logic_vector(4 downto 0);
		data_i		: in std_logic_vector(15 downto 0);
		data_i_e		: in std_logic;
		data_o		: out std_logic_vector(15 downto 0);
		data_o_e		: in std_logic;
		busy			: out std_logic;
		
		miim_clk		: out std_logic;
		miim_d		: inout std_logic
	);
end miim;

architecture RTL of miim is
	signal clkcount:integer range 0 to DIVISOR/2-1;
	signal miim_clk_s, negedge:std_logic;
	
	type state_t is (PRE, ST, OP, PHYAD, REGAD, TA, DATA, IDLE);
	signal state:state_t;
	signal op_read:std_logic;
	
	signal dreg:std_logic_vector(15 downto 0);
	signal areg:std_logic_vector(4 downto 0);
	signal cnt:integer range 0 to 31;
begin
	miim_clk <= miim_clk_s;
	negedge <= '1' when clkcount=0 and miim_clk_s = '1' else '0';
	--posedge <= '1' when clkcount=0 and miim_clk_s = '0' else '0';
	busy <= '1' when state /= IDLE else '0';
	clockgen: process(sysclk, reset) is
	begin
		if reset = '1' then
			miim_clk_s <= '0';
			clkcount <= 0;
		elsif rising_edge(sysclk) then
			if clkcount = 0 then
				clkcount <= DIVISOR/2 - 1;
				miim_clk_s <= not miim_clk_s;
			else
				clkcount <= clkcount - 1;
			end if;
		end if;
	end process clockgen;
	data_o <= dreg;
	fsm:process(sysclk, reset) is
	begin
		if rising_edge(sysclk) then
			if reset = '1' then
				state <= IDLE;
				miim_d <= 'Z';
				dreg <= (OTHERS => '0');
				op_read <= '0';
				areg <= (OTHERS => '0');
			else
			case state is
				when IDLE =>
					if negedge = '1' then
						miim_d <= 'Z';
					end if;
					if data_i_e = '1' or data_o_e = '1' then
						if data_i_e = '1' then
							dreg <= data_i;
							op_read <= '0';
						else
							--dreg <= (OTHERS => 'U'); -- debugging
							op_read <= '1';
						end if;
						areg <= addr;
						cnt <= 31;
						state <= PRE;
					end if;
				when PRE =>
					if negedge = '1' then
						miim_d <= 'Z'; --gets pulled up to '1'
						if cnt = 0 then
							state <= ST;
							cnt <= 1;
						else
							cnt <= cnt - 1;
						end if;
					end if;
				when ST =>
					if negedge = '1' then
						if cnt = 1 then -- first
							miim_d <= '0';
							cnt <= cnt - 1;
						else -- second
							miim_d <= '1';
							state <= OP;
							cnt <= 1;
						end if;
					end if;
				when OP =>
					if negedge = '1' then
						if cnt = 1 then
							miim_d <= op_read;
							cnt <= cnt - 1;
						else
							miim_d <= not op_read;
							state <= PHYAD;
							cnt <= 4;
						end if;
					end if;
				when PHYAD =>
					if negedge = '1' then
						miim_d <= PHYADDR(cnt);
						if cnt = 0 then
							state <= REGAD;
							cnt <= 4;
						else
							cnt <= cnt - 1;
						end if;
					end if;
				when REGAD =>
					if negedge = '1' then
						miim_d <= areg(cnt);
						if cnt = 0 then
							state <= TA;
							cnt <= 1;
						else
							cnt <= cnt - 1;
						end if;
					end if;
				when TA =>
					if negedge = '1' then
						if op_read = '1' then
							if cnt = 0 then
								assert miim_d = '0' report "MIIM: PHY did not pull down second TA-bit";
								state <= DATA;
								cnt <= 15;
							else --first 
								miim_d <= 'Z';
								cnt <= cnt - 1;
							end if;
						else
							if cnt = 0 then
								miim_d <= '0';
								state <= DATA;
								cnt <= 15;
							else --first
								miim_d <= '1';
								cnt <= cnt - 1;
							end if;
						end if;
					end if;
				when DATA =>
					if negedge = '1' then
						if op_read = '1' then
							assert miim_d = '1' or miim_d = '0' --tautology for implementation, but makes sense in simulation
								report "MIIM: PHY did not give good data bit " & integer'image(cnt);
							dreg(cnt) <= miim_d;
						else
							miim_d <= dreg(cnt);
						end if;
						if cnt = 0 then
							state <= IDLE;
							cnt <= 31;
						else
							cnt <= cnt - 1;
						end if;
					end if;
				end case;
				end if;
		end if;
	end process fsm;
	
end RTL;

