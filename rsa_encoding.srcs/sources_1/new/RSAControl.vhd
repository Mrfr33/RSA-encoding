library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;

entity RSAControl is
    Generic (
           -- bits for the crypt counter register
           N : natural := 3;

           CRYPT_COUNT  : natural := 128;
           INIT_COUNT   : natural := 16;
           INPUT_COUNT  : natural := 4;
           OUTPUT_COUNT : natural := 4
    );
    Port (
           Clk    : in std_logic;
           Resetn : in std_logic;

           -- Interface in
           InitRsa  : in std_logic;
           StartRsa : in std_logic;

           -- Interface out
           CoreFinished    : out std_logic;
           init_reg_en     : out std_logic;
           input_reg_en    : out std_logic;
           output_reg_en   : out std_logic;
           output_reg_load : out std_logic;
           crypt_en        : out std_logic
    );
end RSAControl;

architecture RTL of RSAControl is
    signal init_r         : std_logic;
    signal init_reg_en_i  : std_logic;
    signal init_counter_r : unsigned(3 downto 0);

    signal start_r         : std_logic;
    signal input_reg_en_i  : std_logic;
    signal input_counter_r : unsigned(2 downto 0);

    signal crypt_en_r      : std_logic;
    signal crypt_counter_r : natural range 0 to CRYPT_COUNT;
    -- signal crypt_counter_r : unsigned(N downto 0);

    signal output_reg_en_r   : std_logic;
    signal output_reg_load_r : std_logic;
    signal output_counter_r  : unsigned(2 downto 0);
begin
    init_reg_en_i <= InitRsa or init_r;
    init_reg_en   <= init_reg_en_i;

    input_reg_en_i <= StartRsa or start_r;
    input_reg_en   <= input_reg_en_i;

    crypt_en <= crypt_en_r;

    output_reg_en   <= output_reg_en_r;
    output_reg_load <= output_reg_load_r;

    ----------------------------------------------------------------------------
    ---- Init
    -- init_r is 1 when the system is receiving the keys and user parameters.
    -- init_counter_r is incremented only when the system is receiving the keys
    -- and parameters.
    ----------------------------------------------------------------------------
    init_ctrl : process(Clk, Resetn) begin
        if (Resetn = '0') then
            init_r <= '0';
        elsif (Clk'event and Clk = '1') then
            if (InitRsa = '1') then
                init_r <= '1';
            elsif (init_counter_r = INIT_COUNT - 1) then
                init_r <= '0';
            else
                init_r <= init_r;
            end if;
        end if;
    end process;

    init_cnt : process(Clk, Resetn) begin
        if (Resetn = '0') then
            init_counter_r <= (others => '0');
        elsif (Clk'event and Clk = '1') then
            if (init_reg_en_i = '1') then
                init_counter_r <= init_counter_r + 1;
            else
                init_counter_r <= (others => '0');
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    ---- Input
    -- start_r is 1 when the system is receiving the message.
    -- input_counter_r is incremented only when the system is receiving the msg.
    ----------------------------------------------------------------------------
    input_ctrl : process(Clk, Resetn) begin
        if (Resetn = '0') then
            start_r <= '0';
        elsif (Clk'event and Clk = '1') then
            if (StartRsa = '1') then
                start_r <= '1';
            elsif (input_counter_r = INPUT_COUNT - 1) then
                start_r <= '0';
            else
                start_r <= start_r;
            end if;
        end if;
    end process;

    input_cnt : process(Clk, Resetn) begin
        if (Resetn = '0') then
            input_counter_r <= (others => '0');
        elsif (Clk'event and Clk = '1') then
            if (input_reg_en_i = '1') then
                input_counter_r <= input_counter_r + 1;
            else
                input_counter_r <= (others => '0');
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    ---- En-/decryption
    -- crypt_en_r is 1 when the encryption is performed.
    -- crypt_counter_r is only incremented during encryption.
    ----------------------------------------------------------------------------
    crypt_ctrl : process(Clk, Resetn) begin
        if (Resetn = '0') then
            crypt_en_r <= '0';
        elsif (Clk'event and Clk = '1') then
            if (input_counter_r = INPUT_COUNT - 1) then
                crypt_en_r <= '1';
            elsif (crypt_counter_r = CRYPT_COUNT - 1) then
                crypt_en_r <= '0';
            else
                crypt_en_r <= crypt_en_r;
            end if;
        end if;
    end process;

    crypt_cnt : process(Clk, Resetn) begin
        if (Resetn = '0') then
            crypt_counter_r <= 0;
        elsif (Clk'event and Clk = '1') then
            if (crypt_en_r = '1') then
                crypt_counter_r <= crypt_counter_r + 1;
            else
                crypt_counter_r <= 0;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    ---- Output
    -- output_reg_en_r is 1 when the encryption is performed and when the output
    -- sent.
    -- output_reg_load_r is 1 when the encryption is performed.
    -- When both of these registers are 1 then the result of the encryption is
    -- put on the output register. When only output_reg_en_r is 1 then the value
    -- of the output register is shifted out in 32-bit chunks.
    -- output_counter_r is only incremented when the value of the output
    -- register is shifted out.
    ----------------------------------------------------------------------------

    output_en_ctrl : process(Clk, Resetn) begin
        if (Resetn = '0') then
            output_reg_en_r <= '0';
        elsif (Clk'event and Clk = '1') then
            if (crypt_en_r = '1') then
                output_reg_en_r <= '1';
            elsif (output_counter_r = OUTPUT_COUNT - 1) then
                output_reg_en_r <= '0';
            else
                output_reg_en_r <= output_reg_en_r;
            end if;
        end if;
    end process;

    output_load_ctrl : process(Clk, Resetn) begin
        if (Resetn = '0') then
            output_reg_load_r <= '0';
        elsif (Clk'event and Clk = '1') then
            if (crypt_en_r = '1' and crypt_counter_r < CRYPT_COUNT - 1) then
                output_reg_load_r <= '1';
            -- elsif (crypt_en_r = '0') then
            elsif (crypt_counter_r = CRYPT_COUNT - 1) then
                output_reg_load_r <= '0';
            else
                output_reg_load_r <= output_reg_load_r;
            end if;
        end if;
    end process;

    output_cnt : process(Clk, Resetn) begin
        if (Resetn = '0') then
            output_counter_r <= (others => '0');
        elsif (Clk'event and Clk = '1') then
            if (output_reg_en_r = '1' and crypt_en_r = '0') then
                output_counter_r <= output_counter_r + 1;
            else
                output_counter_r <= (others => '0');
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    ---- CoreFinished
    -- CoreFinished is 0 when the system is doing any kind of work.
    ----------------------------------------------------------------------------
    process(Clk, Resetn) begin
        if (Resetn = '0') then
            CoreFinished <= '1';
        elsif (Clk'event and Clk = '1') then
            CoreFinished <= '1';
            if (init_reg_en_i = '1' and init_counter_r < INIT_COUNT - 1) then
                CoreFinished <= '0';
            elsif (input_reg_en_i = '1') then
                CoreFinished <= '0';
            elsif (crypt_en_r = '1' and crypt_counter_r < CRYPT_COUNT - 1) then
                CoreFinished <= '0';
            end if;
        end if;
    end process;

end RTL;
