library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity FIR_Filter_8Tap is
	
	generic( g_data_width : integer := 16;
				g_coefficient_width : integer := 16;
				g_path_delay : integer := 11);
	
	port( i_clk : in std_logic;
			i_rst : in std_logic;
			i_data : in std_logic_vector(g_data_width - 1 downto 0);			
			
			o_data : out std_logic_vector(g_data_width + g_coefficient_width + 2  downto 0);
			o_valid : out std_logic);

end FIR_Filter_8Tap;


architecture Behavioral of FIR_Filter_8Tap is

	type t_buffered_data is array (0 to 7) of signed(g_data_width - 1 downto 0);
	signal r_buffered_data : t_buffered_data := (others => (others => '0'));
	
	type t_coefficient is array (0 to 7) of signed(g_coefficient_width - 1 downto 0);
	constant c_coefficient : t_coefficient := (x"1111",
															 x"2222",
															 x"3333",
															 x"4444",
															 x"5555",
															 x"6666",
															 x"7777",
															 x"8888");
	
	type t_mult_result is array (0 to 7) of signed(g_data_width + g_coefficient_width - 1 downto 0);
	signal r_mult_result : t_mult_result := (others => (others => '0'));
	
	type t_sum_level1 is array (0 to 3) of signed(g_data_width + g_coefficient_width downto 0);
	signal r_sum_level1 : t_sum_level1 := (others => (others => '0'));
	
	type t_sum_level2 is array (0 to 1) of signed(g_data_width + g_coefficient_width + 1 downto 0);
	signal r_sum_level2 : t_sum_level2 := (others => (others => '0'));
	
	signal r_tap_pointer : integer range 0 to 7 := 0;
	
	signal r_edge_counter : integer range 0 to 10 := 0;
	signal r_valid : std_logic := '0';
	
	signal r_FIR_result : signed(g_data_width + g_coefficient_width + 2 downto 0) := (others => '0');

begin


	o_data <= std_logic_vector(r_FIR_result);
	o_valid <= r_valid;
	
	
	--------------------------------------------
	-- Buffering last 8 inputs into registers --
	--------------------------------------------
	p_buffering : process (i_clk, i_rst)
	begin

		if (i_rst = '1') then

			r_buffered_data <= (others => (others => '0'));
			r_tap_pointer <= 0;
			r_edge_counter <= 0;

		elsif (falling_edge(i_clk)) then
			
			r_edge_counter <= r_edge_counter + 1;
			
			if (r_tap_pointer /= 7) then
			
				r_valid <= '0';
				r_buffered_data(r_tap_pointer) <= signed(i_data);
				r_tap_pointer <= r_tap_pointer + 1;
			
			else
				
				if (r_edge_counter = 11) then
					r_valid <= '1';
				end if;
				
				for i in 0 to 6 loop
					r_buffered_data(i) <= r_buffered_data(i + 1);
				end loop;
				
				r_buffered_data(7) <= signed(i_data);
			
			end if;
			
		end if;
	end process p_buffering;
	
	
	-----------------------------------------------------------------
	-- Each buffered input multiplies by corresponding coefficient --
	-----------------------------------------------------------------
	p_multiplication : process (i_clk, i_rst)
	begin
	
		if (i_rst = '1') then
		
			r_mult_result <= (others => (others => '0'));
			
		elsif (falling_edge(i_clk)) then
			
			for i in 0 to 7 loop
				r_mult_result(i) <= r_buffered_data(i) * c_coefficient(i);
			end loop;
			
		end if;
		
	end process p_multiplication;


	-----------------------------------------------------
	-- Calculate result by adding multiplication terms --
	-----------------------------------------------------	
	p_sum_level1 : process (i_clk, i_rst)
	begin
		
		if (i_rst = '1') then
			
			r_sum_level1 <= (others => (others => '0'));
			
		elsif (falling_edge(i_clk)) then
			
			for i in 0 to 3 loop
				r_sum_level1(i) <= resize(r_mult_result(2*i), g_data_width + g_coefficient_width + 1) + resize(r_mult_result(2*i + 1), g_data_width + g_coefficient_width + 1);
			end loop;
		
		end if;
	
	end process p_sum_level1;
	
	
	p_sum_level2 : process (i_clk, i_rst)
	begin
		
		if (i_rst = '1') then
			
			r_sum_level2 <= (others => (others => '0'));
			
		elsif (falling_edge(i_clk)) then
			
			for i in 0 to 1 loop
				r_sum_level2(i) <= resize(r_sum_level1(2*i), g_data_width + g_coefficient_width + 2) + resize(r_sum_level1(2*i + 1), g_data_width + g_coefficient_width + 2);
			end loop;
		
		end if;
	
	end process p_sum_level2;
	
	
	p_result : process (i_clk, i_rst)
	begin
	
		if (i_rst = '1') then
			
			r_FIR_result <= (others => '0');
		
		elsif (falling_edge(i_clk)) then
			
			r_FIR_result <= resize(r_sum_level2(0), g_data_width + g_coefficient_width + 3) + resize(r_sum_level2(1), g_data_width + g_coefficient_width + 3);
			
		end if;
		
	end process p_result;

end Behavioral;

