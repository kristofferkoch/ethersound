library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;
 
ENTITY tb_timer IS
END tb_timer;
 
ARCHITECTURE behavior OF tb_timer IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT timer
    PORT(
         reset : IN  std_logic;
         sysclk : IN  std_logic;
         load : IN  unsigned(63 downto 0);
         load_en : IN  std_logic;
         time_o : OUT  unsigned(63 downto 0);
         ppm : IN  signed(9 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal reset : std_logic := '0';
   signal sysclk : std_logic := '0';
   signal load : unsigned(63 downto 0) := (others => '0');
   signal load_en : std_logic := '0';
   signal ppm : signed(9 downto 0) := (others => '0');

 	--Outputs
   signal time_o : unsigned(63 downto 0);

   -- Clock period definitions
   constant sysclk_period : time := 20 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: timer PORT MAP (
          reset => reset,
          sysclk => sysclk,
          load => load,
          load_en => load_en,
          time_o => time_o,
          ppm => ppm
        );

   -- Clock process definitions
   sysclk_process :process
   begin
		sysclk <= '0';
		wait for sysclk_period/2;
		sysclk <= '1';
		wait for sysclk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      reset <= '1';
		ppm <= to_signed(-1, 10);
		load_en <= '0';
      wait for 100 ns;	
		reset <= '0';
      wait for sysclk_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
