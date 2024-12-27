library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity SpiMaster is 
    generic (
        MAX_CLK_COUNT : integer := 24;
        CLK_DIVIDER_COUNT : integer := 500
    );
    port (
        i_clk_100MHz         : in std_ulogic; -- 100 MHz System Clock
        i_nrst_async         : in std_ulogic;
        i_trigger_conversion : in std_ulogic; -- Triggers Transaction 
        i_data_out           : in std_ulogic; -- MISO (data from ADC) 
        channel              : in std_ulogic_vector(2 downto 0); -- (D2 D1 D0) "ADDED THIS INPUT"
        o_spi_cs             : out std_ulogic; -- chip select
        o_spi_clk            : out std_ulogic; -- spi clock 50 KHz
        o_spi_data_in        : out std_ulogic; -- MOSI (data to ADC)
        o_result_valid       : out std_ulogic; 
        o_adc_result         : out std_ulogic_vector(11 downto 0) -- 12 bit data resolution 
    );
end entity SpiMaster;

architecture RTL of SpiMaster is 
    -- signals for clk division from 100MHz to 100 KHz
    signal clk_div : std_ulogic := '0';
    signal clk_div_count : integer range 0 to CLK_DIVIDER_COUNT-1 := 0;
    -- signal to convert the asynchronous version of i_trigger to a synchronous version
    signal sync_trigger : std_ulogic := '0';
    -- signals for spi clk gen which would be 50 KHz
    signal spi_cs : std_ulogic := '1';
    signal spi_clk : std_ulogic := '0';
    signal spi_cs_delay : std_ulogic := '0';
    shared variable  step_count : integer range 0 to 24 := 0;
    -- signals deal with the writing of data to the slave via the mosi line
    signal spi_data_in : std_ulogic := '0';
    signal mosi_data : std_ulogic_vector(10 downto 0) := (others => '0');
    -- signal buffer deals with the reading of data from the slave via miso line by shifting old data 
    signal miso_data : std_ulogic_vector(11 downto 0) := (others => '0');
    signal adc_result : std_ulogic_vector(11 downto 0) := (others => '0');
    signal result_valid : std_ulogic := '0';
    
    begin 

        proc_clk_div : process(i_clk_100MHz,i_nrst_async) 
            begin 
                if(i_nrst_async = '0') then 
                    clk_div <= '0';
                    clk_div_count <= 0;
                elsif(rising_edge(i_clk_100MHz)) then 
                    if (clk_div_count = CLK_DIVIDER_COUNT-1) then 
                        clk_div <= not clk_div;
                        clk_div_count <= 0;
                    else 
                        clk_div_count <= clk_div_count + 1;
                    end if;
                end if;
        end process proc_clk_div;

        proc_spi_clk : process(clk_div,i_nrst_async,spi_clk)
                begin
                    if (i_nrst_async = '0') then 
                        spi_cs <= '1';
                        spi_clk <= '0';
                        spi_data_in <= '0';
                        mosi_data <= (others => '0');
                        miso_data <= (others => '0');
                        adc_result <= (others => '0');
                        result_valid <= '0';
                    elsif(rising_edge(clk_div)) then 
                        sync_trigger <= i_trigger_conversion;
                        if (spi_cs = '1') then
                            spi_clk <= '0';
                            if (sync_trigger = '1') then 
                                spi_cs <= '0';
                                spi_cs_delay <= '1';
                            end if;
                        elsif (spi_cs = '0' and spi_cs_delay = '1') then 
                            step_count := 0;
                            spi_clk <= '0';
                            spi_cs_delay <= '0';
                        elsif (spi_cs = '0' and spi_cs_delay = '0') then
                            spi_clk <= not spi_clk;
                            if (step_count = MAX_CLK_COUNT ) then 
                                    spi_cs <= '1';
                                    spi_clk <= '0';
                            end if; 
                        end if;
                    end if;

                    if (rising_edge(spi_clk)) then 
                            step_count := step_count + 1;
                    end if;
                    
                    case step_count is
                    when 0 =>
                        result_valid <= '0';
                        miso_data <= (others => '0');
                        mosi_data <= "00000" & "11" & channel & '0';
                    when 1 =>
                        
                        if (falling_edge(spi_clk)) then
                            spi_data_in <= mosi_data(10);
                            mosi_data <= mosi_data(9 downto 0) & '0';
                        end if;
                    when 2 to 11 =>
                        if (falling_edge(spi_clk)) then
                            spi_data_in <= mosi_data(10);
                            mosi_data <= mosi_data(9 downto 0) & '0';
                        end if;
                    when 12 =>
                            null;
                    when 13 to 24 =>
                        if (rising_edge(spi_clk)) then 
                            miso_data <= miso_data(10 downto 0) & i_data_out;
                        end if;
                        if (falling_edge(spi_clk)) then 
                            if (step_count = MAX_CLK_COUNT) then 
                                adc_result <= miso_data;
                                result_valid <= '1';
                            end if;
                        end if;
                    when others =>
                            null;
                end case; 

        end process proc_spi_clk;
        o_spi_cs <= spi_cs;
        o_spi_clk <= spi_clk;
        o_spi_data_in <= spi_data_in;
        o_adc_result <= adc_result;
        o_result_valid <= result_valid;
end architecture RTL;
