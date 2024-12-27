library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

library work;

entity tb is
end entity tb;
    
    architecture bhv of tb is
        signal clk : std_ulogic := '0';
        signal rst : std_ulogic := '0';
        signal trigger_conversion : std_ulogic := '0';
        signal data_out : std_ulogic := '0';
        signal channel : std_ulogic_vector(2 downto 0) := "000";  -- Added channel signal
        signal spi_cs : std_ulogic;
        signal spi_clk : std_ulogic;
        signal spi_data_in : std_ulogic;
        signal result_valid : std_ulogic;
        signal adc_result : std_ulogic_vector(11 downto 0); 
    
        begin 
    
        DUT_SpiMaster :  entity work.SpiMaster(RTL)
        port map (
                i_clk_100MHz => clk,
                i_nrst_async => rst,
                i_trigger_conversion => trigger_conversion,
                i_data_out => data_out,
                channel => channel,  -- Added channel port map
                o_spi_cs => spi_cs,
                o_spi_clk => spi_clk,
                o_spi_data_in => spi_data_in,
                o_result_valid => result_valid,
                o_adc_result => adc_result
            );
        
    
            proc_clock_gen : process is
                begin
                    wait for 5 ns;
                    clk <= not clk;
            end process proc_clock_gen; 
            
            proc_tb : process is
                begin
                    wait for 1250 ns;
                    rst <= '1';
                    wait for 250 ns;
                  
                    wait for 1000 ns;
                    channel <= "001";
                    wait for 200000 ns;
                    channel <= "010";
                    wait for 200000 ns;
                    channel <= "011";
                    wait for 200000 ns;
                    channel <= "100";
                    wait for 200000 ns;
                    channel <= "101";
                    wait for 200000 ns;
                    channel <= "110";
                    wait for 200000 ns;
                    channel <= "111"; 
                    wait for 1000000 ns;
                    
                    wait for 200000 ns;
                    channel <= "000";
                    wait for 2000 ns;
                    
                    wait for 200000 ns;
                    channel <= "101";
                    wait for 200000 ns;
                    channel <= "010";
                    wait for 200000 ns;
                    channel <= "001";
                    wait for 200000 ns;
                    channel <= "011";
                    wait for 200000 ns;
                    channel <= "100";
                    wait for 200000 ns;
                    channel <= "101";
                    wait for 200000 ns;
                    channel <= "110";
                    wait for 200000 ns;
                    channel <= "111"; 
                    wait for 100000 ns;
                    
                    wait for 2000 ns;
                    channel <= "000";
                    wait for 200000 ns;
                    
                    wait for 300000 ns;
                    rst <= '0';
                    wait for 50000 ns;
                    rst <= '1';
                    wait for 100000 ns;
                    
                    wait for 10000 ns;
                    channel <= "011";
                    wait for 100000 ns;
                    rst <= '0';
                    wait;
            end process proc_tb;
    
            proc_reading_miso : process is 
                begin 
                wait for 124565 ns;
                data_out <= not data_out;
            end process proc_reading_miso;
    
            proc_trigger : process is 
                    begin
                    wait for 100000 ns;
                    trigger_conversion <= not trigger_conversion;
                end process;
    
    end architecture bhv;