-----------------------------------------------------------------------------
--    Module for configuring the phy to 100Mbit full-duplex through the
--    MDC-interface (connect to the miim-module)
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

entity phy_ctrl is
    Port ( 
		sysclk		: in std_logic;
		reset			: in std_logic;
		
		data_i		: in std_logic_vector(7 downto 0);
		data_i_v		: in std_logic;
		
		miim_addr	: out std_logic_vector(4 downto 0);
		miim_data_i	: out std_logic_vector(15 downto 0);
		miim_data_i_e : out std_logic;
		miim_data_o	: in std_logic_vector(15 downto 0);
		miim_data_o_e : out std_logic;
		miim_busy	: in std_logic
	);
end phy_ctrl;

architecture RTL of phy_ctrl is
	type miim_state_t is (set_reg0, set_reg4, 
		wait_miim, wait_miim1,
		vfy_reg0, vfy_reg0_1, vfy_reg4, vfy_reg4_1,
		poll_link, poll_link_1, miim_reset_st);
	signal miim_state, miim_after_wait:miim_state_t;
	constant PHY_SET_REG0    :std_logic_vector(15 downto 0):="0011000100000000";
	constant PHY_SET_REG0_MSK:std_logic_vector(15 downto 0):="1101111010000000";
	constant PHY_SET_REG4    :std_logic_vector(15 downto 0):="0000000100000001";
	constant PHY_SET_REG4_MSK:std_logic_vector(15 downto 0):="0000000100000000";
	
	signal miim_reset:std_logic:='0';
	signal miim_rdy:std_logic;
begin
	-- This state-machine configures and verifies
	-- the PHY to auto-negotiate 100Base-TX Full-duplex
	-- Sets miim_rdy when link is up. When miim_reset is
	-- asserted, a soft reset is done
	miim_ctrl_fsm:process(sysclk, reset) is
	begin
		if rising_edge(sysclk) then
			if reset = '1' then
				miim_state <= wait_miim1;
				miim_after_wait <= set_reg0;
				miim_addr <= (OTHERS => '0');
				miim_data_i	  <= (OTHERS => '0');
				miim_data_i_e <= '0';
				miim_data_o_e <= '0';
				--debug <= (OTHERS => '1');
				miim_rdy <= '0';
			else
			if miim_reset = '1' then
				miim_after_wait <= miim_reset_st;
				miim_rdy <= '0';
			else 
			case miim_state is
				when miim_reset_st =>
					miim_addr <= std_logic_vector(to_unsigned(0, 5));
					miim_data_i <= "1000000000000000";
					miim_data_i_e <= '1';
					miim_state <= wait_miim;
					miim_after_wait <= set_reg0;
				when set_reg0 =>
					miim_addr <= std_logic_vector(to_unsigned(0, 5));
					miim_data_i <= PHY_SET_REG0;
					miim_data_i_e <= '1';
					miim_state <= wait_miim;
					miim_after_wait <= set_reg4;
				when set_reg4 =>
					miim_addr <= std_logic_vector(to_unsigned(4, 5));
					miim_data_i <= PHY_SET_REG4;
					miim_data_i_e <= '1';
					miim_state <= wait_miim;
					miim_after_wait <= vfy_reg0;
				when vfy_reg0 =>
					miim_addr <= std_logic_vector(to_unsigned(0, 5));
					miim_data_o_e <= '1';
					miim_state <= wait_miim;
					miim_after_wait <= vfy_reg0_1;
				when vfy_reg0_1 =>
					if (miim_data_o and PHY_SET_REG0_MSK) = (PHY_SET_REG0 and PHY_SET_REG0_MSK) then
						miim_state <= vfy_reg4;
					else
						miim_state <= set_reg0; --reset
					end if;
				when vfy_reg4 =>
					miim_addr <= std_logic_vector(to_unsigned(4, 5));
					miim_data_o_e <= '1';
					miim_state <= wait_miim;
					miim_after_wait <= vfy_reg4_1;
				when vfy_reg4_1 =>
					if (miim_data_o and PHY_SET_REG4_MSK) = (PHY_SET_REG4  and PHY_SET_REG4_MSK) then
						miim_state <= poll_link;
					else
						miim_state <= set_reg0; --reset
					end if;
				when poll_link =>
					miim_addr <= std_logic_vector(to_unsigned(1, 5));
					miim_data_o_e <= '1';
					miim_state <= wait_miim;
					miim_after_wait <= poll_link_1;
				when poll_link_1 =>
--					debug(0) <= miim_data_o(14); -- 100Base-TX FD 	(1)
--					debug(1) <= miim_data_o(5); -- Auto-neg comp 	(1)
--					debug(2) <= miim_data_o(4); -- remote fault 		(0)
--					debug(3) <= miim_data_o(3); -- able to autoneg	(1)
--					debug(4) <= miim_data_o(2); -- link status		(1)
--					debug(5) <= miim_data_o(1); -- jabber detect		(0)
--					debug(6) <= miim_data_o(0); -- extended cap		(1)
--					debug(7) <= '0';
					miim_rdy <= miim_data_o(14) and miim_data_o(2);
					miim_state <= poll_link;
				when wait_miim =>
					if miim_busy = '1' then
						miim_state <= wait_miim1;
					end if;
				when wait_miim1 =>
					miim_data_i_e <= '0';
					miim_data_o_e <= '0';
					if miim_busy = '0' then
						miim_state <= miim_after_wait;
					end if;
			end case;
			end if;
			end if;
		end if;
	end process;
end RTL;

