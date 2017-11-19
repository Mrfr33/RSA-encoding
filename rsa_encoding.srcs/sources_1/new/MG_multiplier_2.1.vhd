--------------------------------------------------------------
-- Perform Modular multiplication
-- Based on Montgomery multiplication
--------------------------------------------------------------


library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library lpm;
use lpm.lpm_components.all;

entity MG_multiplier is
    Generic ( SIZE : integer :=32
    );
    port (  A : in unsigned(SIZE-1 downto 0);
            B : in unsigned(SIZE-1 downto 0);
            N_mod : in unsigned(SIZE-1 downto 0);
            clk : in std_logic;
            lock : in std_logic;
            reset : in std_logic;
            mult_ended : out std_logic;
            product : out unsigned(SIZE-1 downto 0)
    );
end MG_multiplier;

architecture SpaceX of MG_multiplier is
  signal p_temp : unsigned(SIZE-1 downto 0) := (others => '0');
  signal step : integer :=0;
  signal A_mem : unsigned(SIZE-1 downto 0) := (others => '0');
  signal B_mem : unsigned(SIZE-1 downto 0) := (others => '0');
  signal N_mod_mem : unsigned(SIZE-1 downto 0) := (others => '0');

  begin
    --multiplier : process(clk,lock)
    multiplier : process(clk,lock,reset)
    begin
      --if  rising_edge(clk) then
      if reset = '0' and rising_edge(clk) then
        case step is
          when 0 => -- Locking Data
            if lock ='1' then
              p_temp <= (others => '0');
              B_mem <= B;
              A_mem <= Q;
              N_mod_mem <= N_mod;
              step <= 1;
              mult_ended <=0;
            end if;

          when 1 =>
          -- Checking cases to get 0 on the LSB of the addition result
            if A_mem(0) ='1' then
              if (p_temp(0) xor B_mem(0)) ='1' then
                p_temp <= unsigned(shift_right(unsigned(p_temp + B_mem + N_mod),1));
              else
                p_temp <= unsigned(shift_right(unsigned(p_temp + B_mem),1));
              end if;
            else
              if p_temp(0)='1' then
                p_temp <= unsigned(shift_right(unsigned(p_temp + N_mod),1)) ;
              else
                p_temp <= unsigned(shift_right(unsigned(p_temp),1));
              end if;
            end if;

            if N_mod_mem = to_unsigned(1,SIZE) then
              step <= 2;
            else
              step <= 1;
            end if;

            N_mod_mem <= unsigned(shift_right(unsigned(N_mod_mem),1));
            A_mem <= unsigned(shift_right(unsigned(A_mem),1));

          when 2 =>
          -- setting Outputs
            if (p_temp > N_mod) then
              product <= p_temp(SIZE-1 downto 0) - N;
            else
              product <= p_temp; --(SIZE-1 downto 0);
            end if;
            mult_ended <=1;
            step <=0;

          when others =>
            step <= '0';
          end case;
      end if;
    end process;
end SpaceX;
