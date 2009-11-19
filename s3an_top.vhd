-----------------------------------------------------------------------------
--    Top module for implementing hwpulse on Xilinx Spartan 3 Starter Kit 
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

entity s3an_top is
--	generic(
--		MAC:std_logic_vector(47 downto 0):=x"010B5E000000"
--	);
	port (
		-- Clock-input from crystal osc
		clk_50m	: in std_logic;
		-- Leds on the board. Nice for debugging.
		led		: out std_logic_vector(7 downto 0);
		
		-- Pins for MDIO-interfacing the PHY
		e_nrst	: out std_logic;
		e_mdc		: out std_logic;
		e_mdio	: inout std_logic;
		
		-- Pins for receiving data from the PHY
		e_rx_clk	: in std_logic;
		e_rxd		: in std_logic_vector(3 downto 0);
		e_rx_dv	: in std_logic;
		
		-- Pins for sending data to the PHY
		e_tx_clk : in std_logic;
		e_txd		: out std_logic_vector(3 downto 0);
		e_tx_en  : out std_logic;
		
		-- Button used as a reset-button
		btn_south : in std_logic;
		
		-- Rudimentary delta-sigma modulated digital sound outputs.
		-- Without analog lowpass-filter.
		-- Sounds like crap, but is easy to plug headphones into.
		aud_l:out std_logic;
		aud_r:out std_logic
		
	);
end s3an_top;

architecture Behavioral of s3an_top is
	component miim
		generic (
			DIVISOR		: integer;
			PHYADDR		: std_logic_vector(4 downto 0)
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
	end component;
	component phy_ctrl
		port (
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
	end component;
	 COMPONENT txsync
    PORT(
         sysclk : IN  std_logic;
         reset : IN  std_logic;
         tx_clk : IN  std_logic;
         txd : OUT  std_logic_vector(3 downto 0);
         tx_dv : OUT  std_logic;
         data : IN  std_logic_vector(7 downto 0);
         data_send : IN  std_logic;
         data_req : OUT  std_logic;
			debug:out std_logic_vector(7 downto 0)
        );
    END COMPONENT;
	 component packetgen is
			Port ( sysclk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           rate_pulse : in  STD_LOGIC;
           edata_o : out  STD_LOGIC_VECTOR (7 downto 0);
           edata_o_v : out  STD_LOGIC;
           edata_o_req : in  STD_LOGIC;
           debug : out  STD_LOGIC_VECTOR (7 downto 0));
	end component;
	COMPONENT rxsync
    PORT(
         sysclk : IN  std_logic;
         reset : IN  std_logic;
         rx_clk : IN  std_logic;
         rxd : IN  std_logic_vector(3 downto 0);
         rx_dv : IN  std_logic;
         data : OUT  std_logic_vector(7 downto 0);
         data_end : OUT  std_logic;
         data_err : OUT  std_logic;
         data_dv : OUT  std_logic;
			debug: out std_logic_vector(7 downto 0)
        );
    END COMPONENT;
	 COMPONENT rxdecode
		Port ( sysclk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           data : in  STD_LOGIC_VECTOR (7 downto 0);
           data_dv : in  STD_LOGIC;
           data_end : in  STD_LOGIC;
           data_err : in  STD_LOGIC;
           audio : out  STD_LOGIC_VECTOR (23 downto 0);
           audio_dv : out  STD_LOGIC;
			debug: out std_logic_vector(7 downto 0)
        );
	 END COMPONENT;
    COMPONENT deltasigmadac
    PORT(
         sysclk : IN  std_logic;
         reset : IN  std_logic;
         audio : IN  std_logic_vector(23 downto 0);
         audio_dv : IN  std_logic;
         audio_left : OUT  std_logic;
         audio_right : OUT  std_logic;
			rate_pulse:out std_logic;
			debug: out std_logic_vector(7 downto 0)
        );
    END COMPONENT;
	component clocking is
		Port (
			clk_in	: in std_logic;
			rst		: in std_logic;
			clk1x		: out std_logic;
			clk_div	: out std_logic;
			lock		: out std_logic
		);
	end component;
	--Signals for clock and reset logic. lock comes when the DCM thinks it is stable
	signal sysclk, lock, nreset, reset:std_logic;

	signal e_mdc_s:std_logic:='0';
	signal miim_addr:std_logic_vector(4 downto 0):=(OTHERS => '0');
	signal miim_data_i, miim_data_o:std_logic_vector(15 downto 0):=(OTHERS => '0');
	signal miim_data_i_e, miim_data_o_e, miim_busy:std_logic:='0';
	
	signal rx_data_o:std_logic_vector(7 downto 0):=(OTHERS => '0');
	signal rx_data_v, rx_frame_end, rx_frame_err:std_logic:='0';
	
	signal audio:std_logic_vector(23 downto 0);
	signal audio_dv,rate_pulse:std_logic;
	
	signal ctrl_data:std_logic_vector(7 downto 0):=(OTHERS => '0');
	signal ctrl_data_v:std_logic:='0';
	
	signal edata_o:std_logic_vector(7 downto 0);
	signal edata_o_v, edata_o_req:std_logic;
begin
	e_mdc <= e_mdc_s;

	
	reset <= not lock or btn_south;-- or btn_south;
	nreset <= not reset;
	e_nrst <= nreset;
	clocking_inst : clocking port map (
			clk_in => clk_50m,
			rst => btn_south,
			clk1x => sysclk,
			clk_div => open,
			lock => lock
		);
	miim_inst : miim generic map(
			DIVISOR => 21,--50000,
			PHYADDR => "00000"
		) port map (
			sysclk	=> sysclk,
			reset		=> reset,
			addr		=> miim_addr,
			data_i	=> miim_data_i,
			data_i_e => miim_data_i_e,
			data_o	=> miim_data_o,
			data_o_e => miim_data_o_e,
			busy		=> miim_busy,
			miim_clk => e_mdc_s,
			miim_d	=> e_mdio
		);
	rxsyncer : rxsync port map (
			sysclk => sysclk,
			reset	=> reset,
		
			rx_clk => e_rx_clk,
			rxd	=> e_rxd,
			rx_dv => e_rx_dv,
			--phy_rx_err	: in std_logic;
			
			data => rx_data_o,
			data_dv => rx_data_v,
			data_end	=> rx_frame_end,
			data_err => rx_frame_err,
			
			debug => open
		);
	rxdecoder:rxdecode PORT MAP (
			sysclk => sysclk,
			reset => reset,
			data => rx_data_o,
			data_dv => rx_data_v,
			data_end => rx_frame_end,
			data_err => rx_frame_err,
			audio => audio,
			audio_dv => audio_dv,
			debug => open
		);	
	phy_ctrl_inst : phy_ctrl port map (
			sysclk => sysclk,
			reset	=> reset,
			
			data_i => ctrl_data,
			data_i_v	=> ctrl_data_v,
			
			miim_addr => miim_addr,
			miim_data_i	=> miim_data_i,
			miim_data_i_e => miim_data_i_e,
			miim_data_o	=> miim_data_o,
			miim_data_o_e => miim_data_o_e,
			miim_busy => miim_busy
		);
	dac: deltasigmadac PORT MAP (
          sysclk => sysclk,
          reset => reset,
          audio => audio,
          audio_dv => audio_dv,
          audio_left => aud_l,
          audio_right => aud_r,
			 rate_pulse => rate_pulse,
			 debug => open
        );
	txsyncer:txsync port map (
			sysclk => sysclk,
			reset => reset,
			tx_clk => e_tx_clk,
			txd => e_txd,
			tx_dv => e_tx_en,
			data => edata_o,
			data_send => edata_o_v,
			data_req => edata_o_req,
			debug => led
		);
	gen: packetgen port map (
			sysclk => sysclk,
			reset => reset,
			rate_pulse => rate_pulse,
			edata_o => edata_o,
			edata_o_v => edata_o_v,
			edata_o_req => edata_o_req,
			debug => open
		);
end Behavioral;
