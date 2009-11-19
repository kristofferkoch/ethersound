----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    08:53:34 07/04/2008 
-- Design Name: 
-- Module Name:    txcrc - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity txcrc is
    Port ( sysclk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           data_o : out  STD_LOGIC_VECTOR (7 downto 0);
           data_send : out  STD_LOGIC;
           data_o_req : in  STD_LOGIC;
           data_i : in  STD_LOGIC_VECTOR (7 downto 0);
           data_i_v : in  STD_LOGIC;
           data_i_req : out  STD_LOGIC);
end txcrc;

architecture Behavioral of txcrc is
	function nextCRC32_D8 (
			Data:  std_logic_vector(7 downto 0);
			CRC:   std_logic_vector(31 downto 0) 
		) return std_logic_vector is
    variable D: std_logic_vector(7 downto 0);
    variable C: std_logic_vector(31 downto 0);
    variable NewCRC: std_logic_vector(31 downto 0);
  begin
--		D(0) := Data(7);
--		D(1) := Data(6);
--		D(2) := Data(5);
--		D(3) := Data(4);
--		D(4) := Data(3);
--		D(5) := Data(2);
--		D(6) := Data(1);
--		D(7) := Data(0);

		D(0) := Data(3);
		D(1) := Data(2);
		D(2) := Data(1);
		D(3) := Data(0);
		D(4) := Data(7);
		D(5) := Data(6);
		D(6) := Data(5);
		D(7) := Data(4);
		
		
		C := CRC;
		NewCRC(0) := D(6) xor D(0) xor C(24) xor C(30);
		NewCRC(1) := D(7) xor D(6) xor D(1) xor D(0) xor C(24) xor C(25) xor 
					  C(30) xor C(31);
		NewCRC(2) := D(7) xor D(6) xor D(2) xor D(1) xor D(0) xor C(24) xor 
					  C(25) xor C(26) xor C(30) xor C(31);
		NewCRC(3) := D(7) xor D(3) xor D(2) xor D(1) xor C(25) xor C(26) xor 
					  C(27) xor C(31);
		NewCRC(4) := D(6) xor D(4) xor D(3) xor D(2) xor D(0) xor C(24) xor 
					  C(26) xor C(27) xor C(28) xor C(30);
		NewCRC(5) := D(7) xor D(6) xor D(5) xor D(4) xor D(3) xor D(1) xor 
					  D(0) xor C(24) xor C(25) xor C(27) xor C(28) xor C(29) xor 
					  C(30) xor C(31);
		NewCRC(6) := D(7) xor D(6) xor D(5) xor D(4) xor D(2) xor D(1) xor 
					  C(25) xor C(26) xor C(28) xor C(29) xor C(30) xor C(31);
		NewCRC(7) := D(7) xor D(5) xor D(3) xor D(2) xor D(0) xor C(24) xor 
					  C(26) xor C(27) xor C(29) xor C(31);
		NewCRC(8) := D(4) xor D(3) xor D(1) xor D(0) xor C(0) xor C(24) xor 
					  C(25) xor C(27) xor C(28);
		NewCRC(9) := D(5) xor D(4) xor D(2) xor D(1) xor C(1) xor C(25) xor 
					  C(26) xor C(28) xor C(29);
		NewCRC(10) := D(5) xor D(3) xor D(2) xor D(0) xor C(2) xor C(24) xor 
						C(26) xor C(27) xor C(29);
		NewCRC(11) := D(4) xor D(3) xor D(1) xor D(0) xor C(3) xor C(24) xor 
						C(25) xor C(27) xor C(28);
		NewCRC(12) := D(6) xor D(5) xor D(4) xor D(2) xor D(1) xor D(0) xor 
						C(4) xor C(24) xor C(25) xor C(26) xor C(28) xor C(29) xor 
						C(30);
		NewCRC(13) := D(7) xor D(6) xor D(5) xor D(3) xor D(2) xor D(1) xor 
						C(5) xor C(25) xor C(26) xor C(27) xor C(29) xor C(30) xor 
						C(31);
		NewCRC(14) := D(7) xor D(6) xor D(4) xor D(3) xor D(2) xor C(6) xor 
						C(26) xor C(27) xor C(28) xor C(30) xor C(31);
		NewCRC(15) := D(7) xor D(5) xor D(4) xor D(3) xor C(7) xor C(27) xor 
						C(28) xor C(29) xor C(31);
		NewCRC(16) := D(5) xor D(4) xor D(0) xor C(8) xor C(24) xor C(28) xor 
						C(29);
		NewCRC(17) := D(6) xor D(5) xor D(1) xor C(9) xor C(25) xor C(29) xor 
						C(30);
		NewCRC(18) := D(7) xor D(6) xor D(2) xor C(10) xor C(26) xor C(30) xor 
						C(31);
		NewCRC(19) := D(7) xor D(3) xor C(11) xor C(27) xor C(31);
		NewCRC(20) := D(4) xor C(12) xor C(28);
		NewCRC(21) := D(5) xor C(13) xor C(29);
		NewCRC(22) := D(0) xor C(14) xor C(24);
		NewCRC(23) := D(6) xor D(1) xor D(0) xor C(15) xor C(24) xor C(25) xor 
						C(30);
		NewCRC(24) := D(7) xor D(2) xor D(1) xor C(16) xor C(25) xor C(26) xor 
						C(31);
		NewCRC(25) := D(3) xor D(2) xor C(17) xor C(26) xor C(27);
		NewCRC(26) := D(6) xor D(4) xor D(3) xor D(0) xor C(18) xor C(24) xor 
						C(27) xor C(28) xor C(30);
		NewCRC(27) := D(7) xor D(5) xor D(4) xor D(1) xor C(19) xor C(25) xor 
						C(28) xor C(29) xor C(31);
		NewCRC(28) := D(6) xor D(5) xor D(2) xor C(20) xor C(26) xor C(29) xor 
						C(30);
		NewCRC(29) := D(7) xor D(6) xor D(3) xor C(21) xor C(27) xor C(30) xor 
						C(31);
		NewCRC(30) := D(7) xor D(4) xor C(22) xor C(28) xor C(31);
		NewCRC(31) := D(5) xor C(23) xor C(29);

		return NewCRC;
	end nextCRC32_D8;

--	type state_t is (Idle, TX, st_CRC);
--	signal state:state_t;
--
--	signal ireg:std_logic_vector(7 downto 0);
--	signal counter:integer range 0 to 3;
--	signal crc, nextcrc:std_logic_vector(31 downto 0);
begin
data_o <= data_i when state = stCRC else crcmux;
--	nextcrc <= nextCRC32_D8(ireg, crc);
--	process(sysclk) is
--	begin
--		if rising_edge(sysclk) then
--			if reset = '1' then
--				data_i_req <= '0';
--				data_send <= '0';
--				state <= Idle;
--				crc <= (OTHERS => '1');
--				data_o <= (OTHERS => '0');
--			else
--			case state is
--				when TX =>
--					if data_o_req = '1' then
--						data_o <= ireg;
--						crc <= nextcrc;
--						data_send <= '1';
--						data_i_req <= '1';
--					else
--						data_i_req <= '0';
--					end if;
--					if data_i_v = '1' then
--						ireg <= data_i;
--					else
--						state <= st_CRC;
--						counter <= 3;
--						ireg <= (OTHERS => '0');
--					end if;
--				when st_CRC =>
--					if data_o_req = '1' then
--						--data_o <= crc(counter*8+7 downto counter*8);
--						data_o(7) <= not crc(counter*8);
--						data_o(6) <= not crc(counter*8+1);
--						data_o(5) <= not crc(counter*8+2);
--						data_o(4) <= not crc(counter*8+3);
--						data_o(3) <= not crc(counter*8+4);
--						data_o(2) <= not crc(counter*8+5);
--						data_o(1) <= not crc(counter*8+6);
--						data_o(0) <= not crc(counter*8+7);
--						
--						if counter = 0 then
--							state <= Idle;
--							data_i_req <= '1';
--						else
--							counter <= counter - 1;
--							data_i_req <= '0';
--						end if;
--					end if;
--				when others => --Idle
--					crc <= (OTHERS => '1');
--					if data_o_req = '1' then
--						data_send <= '0';
--					end if;
--					if data_i_v = '1' then
--						ireg <= data_i;
--						data_i_req <= '0';
--						state <= TX;
--					else
--						data_i_req <= '1';
--					end if;
--			end case;
--		end if;
--		end if;
--	end process;

end Behavioral;

