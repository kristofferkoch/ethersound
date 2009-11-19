-----------------------------------------------------------------------------
--    Testbench for txsync
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

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
 
ENTITY tb_txsync IS
END tb_txsync;
 
ARCHITECTURE behavior OF tb_txsync IS 
  -- polynomial: (0 1 2 4 5 7 8 10 11 12 16 22 23 26 32)
  -- data width: 4
  -- convention: the first serial data bit is D(3)
  function nextCRC32_D4  
    ( Data:  std_logic_vector(3 downto 0);
      CRC:   std_logic_vector(31 downto 0) )
    return std_logic_vector is

    variable D: std_logic_vector(3 downto 0);
    variable C: std_logic_vector(31 downto 0);
    variable NewCRC: std_logic_vector(31 downto 0);

  begin
		for i in 0 to 3 loop
			D(i) := Data(3-i);
		end loop;
    C := CRC;

    NewCRC(0) := D(0) xor C(28);
    NewCRC(1) := D(1) xor D(0) xor C(28) xor C(29);
    NewCRC(2) := D(2) xor D(1) xor D(0) xor C(28) xor C(29) xor C(30);
    NewCRC(3) := D(3) xor D(2) xor D(1) xor C(29) xor C(30) xor C(31);
    NewCRC(4) := D(3) xor D(2) xor D(0) xor C(0) xor C(28) xor C(30) xor 
                 C(31);
    NewCRC(5) := D(3) xor D(1) xor D(0) xor C(1) xor C(28) xor C(29) xor 
                 C(31);
    NewCRC(6) := D(2) xor D(1) xor C(2) xor C(29) xor C(30);
    NewCRC(7) := D(3) xor D(2) xor D(0) xor C(3) xor C(28) xor C(30) xor 
                 C(31);
    NewCRC(8) := D(3) xor D(1) xor D(0) xor C(4) xor C(28) xor C(29) xor 
                 C(31);
    NewCRC(9) := D(2) xor D(1) xor C(5) xor C(29) xor C(30);
    NewCRC(10) := D(3) xor D(2) xor D(0) xor C(6) xor C(28) xor C(30) xor 
                  C(31);
    NewCRC(11) := D(3) xor D(1) xor D(0) xor C(7) xor C(28) xor C(29) xor 
                  C(31);
    NewCRC(12) := D(2) xor D(1) xor D(0) xor C(8) xor C(28) xor C(29) xor 
                  C(30);
    NewCRC(13) := D(3) xor D(2) xor D(1) xor C(9) xor C(29) xor C(30) xor 
                  C(31);
    NewCRC(14) := D(3) xor D(2) xor C(10) xor C(30) xor C(31);
    NewCRC(15) := D(3) xor C(11) xor C(31);
    NewCRC(16) := D(0) xor C(12) xor C(28);
    NewCRC(17) := D(1) xor C(13) xor C(29);
    NewCRC(18) := D(2) xor C(14) xor C(30);
    NewCRC(19) := D(3) xor C(15) xor C(31);
    NewCRC(20) := C(16);
    NewCRC(21) := C(17);
    NewCRC(22) := D(0) xor C(18) xor C(28);
    NewCRC(23) := D(1) xor D(0) xor C(19) xor C(28) xor C(29);
    NewCRC(24) := D(2) xor D(1) xor C(20) xor C(29) xor C(30);
    NewCRC(25) := D(3) xor D(2) xor C(21) xor C(30) xor C(31);
    NewCRC(26) := D(3) xor D(0) xor C(22) xor C(28) xor C(31);
    NewCRC(27) := D(1) xor C(23) xor C(29);
    NewCRC(28) := D(2) xor C(24) xor C(30);
    NewCRC(29) := D(3) xor C(25) xor C(31);
    NewCRC(30) := C(26);
    NewCRC(31) := C(27);

    return NewCRC;

  end nextCRC32_D4;
    -- Component Declaration for the Unit Under Test (UUT)
 
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
           debug : out  STD_LOGIC_VECTOR (7 downto 0)
        );
    END COMPONENT;


   --Inputs
   signal sysclk : std_logic := '0';
   signal reset : std_logic := '0';
   signal tx_clk : std_logic := '0';
   signal data : std_logic_vector(7 downto 0) := (others => '0');
   signal data_send : std_logic := '0';

 	--Outputs
   signal txd : std_logic_vector(3 downto 0);
   signal tx_dv : std_logic;
   signal data_req : std_logic;

   -- Clock period definitions
   constant sysclk_period : time := 22 ns;
   constant tx_clk_period : time := 40 ns;
 
	signal done:boolean:=false;
	signal pcount:integer;
	type rxstate_t is (Idle, Preamble, Data0, Data1);
	signal rxstate:rxstate_t;
	
	signal crc:std_logic_vector(31 downto 0);
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   sync: txsync PORT MAP (
          sysclk => sysclk,
          reset => reset,
          tx_clk => tx_clk,
          txd => txd,
          tx_dv => tx_dv,
          data => data,
          data_send => data_send,
          data_req => data_req,
			 debug => open
        );

   -- Clock process definitions
   sysclk_process :process
   begin
		if done then
			wait;
		else
			sysclk <= '0';
			wait for sysclk_period/2;
			sysclk <= '1';
			wait for sysclk_period/2;
		end if;
   end process;
 
   tx_clk_process :process
   begin
		if done then 
			wait;
		else
			tx_clk <= '0';
			wait for tx_clk_period/2;
			tx_clk <= '1';
			case rxstate is
				when Idle =>
					crc <= (OTHERS => '1');
					if tx_dv = '1' then
						if txd = x"5" then
							rxstate <= Preamble;
							pcount <= pcount + 1;
						else
							report "Received preamble other than 0x5.";
							rxstate <= Preamble;
						end if;
					else
						pcount <= 0;
					end if;
				when Preamble =>
					if tx_dv = '1' then
						if txd = x"d" then
							rxstate <= Data0;
						elsif txd = x"5" then
							pcount <= pcount + 1;
						else
							report "Received preamble other than 0x5 or 0xD.";
						end if;
					end if;
				when Data0 =>
					if tx_dv = '1' then
						rxstate <= Data1;
						crc <= nextCRC32_D4(txd, crc);
					else
						report "Frame transfer complete.";
						if crc = x"c704dd7b" then
							report "CRC ok";
						end if;
						rxstate <= Idle;
					end if;
				when Data1 =>
					if tx_dv = '1' then
						rxstate <= Data0;
						crc <= nextCRC32_D4(txd, crc);
					else
						report "Odd nibble received." severity warning;
						rxstate <= Idle;
					end if;
			end case;
			wait for tx_clk_period/2;
		end if;
   end process;
	
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100ms.
		reset <= '1';
		data_send <= '0';
      wait for sysclk_period*10;
		reset <= '0';
      
		-- insert stimulus here 
		if data_req = '1' then 
			wait until data_req = '0';
		end if;wait until data_req = '1';wait for sysclk_period;
		data_send <= '1';
		data <= x"ba";
		if data_req = '1' then 
			wait until data_req = '0';
		end if;wait until data_req = '1';wait for sysclk_period;
		data <= x"dc";
		if data_req = '1' then 
			wait until data_req = '0';
		end if;wait until data_req = '1';wait for sysclk_period;
		data_send <= '0';
      wait;
   end process;

END;
