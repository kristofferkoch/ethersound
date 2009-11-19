library IEEE;
use IEEE.STD_LOGIC_1164.all;

package crc is
function CRC32_4  
    ( Data:  std_logic_vector(3 downto 0);
      CRC:   std_logic_vector(31 downto 0);
		Enable:std_logic)
    return std_logic_vector;

end crc;


package body crc is
 -- polynomial: (0 1 2 4 5 7 8 10 11 12 16 22 23 26 32)
  -- data width: 4
  -- convention: the first serial data bit is D(3)
  function CRC32_4  
    ( Data:  std_logic_vector(3 downto 0);
      CRC:   std_logic_vector(31 downto 0);
		Enable:std_logic)
    return std_logic_vector is

    variable D: std_logic_vector(3 downto 0);
    variable C: std_logic_vector(31 downto 0);
    variable NewCRC: std_logic_vector(31 downto 0);
	 variable E:std_logic;
  begin
		for i in 0 to 3 loop
			D(i) := Data(3-i);
		end loop;
    C := CRC;
	 E := Enable;

    NewCRC(0) := E and (D(0) xor C(28));
    NewCRC(1) := E and (D(1) xor D(0) xor C(28) xor C(29));
    NewCRC(2) := E and (D(2) xor D(1) xor D(0) xor C(28) xor C(29) xor C(30));
    NewCRC(3) := E and (D(3) xor D(2) xor D(1) xor C(29) xor C(30) xor C(31));
    NewCRC(4) := (E and (D(3) xor D(2) xor D(0) xor C(28) xor C(30) xor C(31))) xor C(0);
    NewCRC(5) := (E and (D(3) xor D(1) xor D(0) xor C(28) xor C(29) xor C(31))) xor C(1);
    NewCRC(6) := (E and (D(2) xor D(1) xor C(29) xor C(30))) xor C(2);
    NewCRC(7) := (E and (D(3) xor D(2) xor D(0) xor C(28) xor C(30) xor C(31))) xor C(3);
    NewCRC(8) := (E and (D(3) xor D(1) xor D(0) xor C(28) xor C(29) xor C(31))) xor C(4);
    NewCRC(9) := (E and (D(2) xor D(1) xor C(29) xor C(30))) xor C(5);
    NewCRC(10) := (E and (D(3) xor D(2) xor D(0) xor C(28) xor C(30) xor C(31))) xor C(6);
    NewCRC(11) := (E and (D(3) xor D(1) xor D(0) xor C(28) xor C(29) xor C(31))) xor C(7);
    NewCRC(12) := (E and (D(2) xor D(1) xor D(0) xor C(28) xor C(29) xor C(30))) xor C(8);
    NewCRC(13) := (E and (D(3) xor D(2) xor D(1) xor C(29) xor C(30) xor C(31))) xor C(9);
    NewCRC(14) := (E and (D(3) xor D(2) xor C(30) xor C(31))) xor C(10);
    NewCRC(15) := (E and (D(3) xor C(31))) xor C(11);
    NewCRC(16) := (E and (D(0) xor C(28))) xor C(12);
    NewCRC(17) := (E and (D(1) xor C(29))) xor C(13);
    NewCRC(18) := (E and (D(2) xor C(30))) xor C(14);
    NewCRC(19) := (E and (D(3) xor C(31))) xor C(15);
    NewCRC(20) := C(16);
    NewCRC(21) := C(17);
    NewCRC(22) := (E and (D(0) xor C(28))) xor C(18);
    NewCRC(23) := (E and (D(1) xor D(0) xor C(28) xor C(29))) xor C(19);
    NewCRC(24) := (E and (D(2) xor D(1) xor C(29) xor C(30))) xor C(20);
    NewCRC(25) := (E and (D(3) xor D(2) xor C(30) xor C(31))) xor C(21);
    NewCRC(26) := (E and (D(3) xor D(0) xor C(28) xor C(31))) xor C(22);
    NewCRC(27) := (E and (D(1) xor C(29))) xor C(23);
    NewCRC(28) := (E and (D(2) xor C(30))) xor C(24);
    NewCRC(29) := (E and (D(3) xor C(31))) xor C(25);
    NewCRC(30) := C(26);
    NewCRC(31) := C(27);

    return NewCRC;

  end CRC32_4;
end crc;
