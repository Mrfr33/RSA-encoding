----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 01.11.2017 13:58:25
-- Design Name:
-- Module Name: RSADatapath - RTL
-- Project Name:
-- Target Devices:
-- Tool Versions:
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
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity RSADatapath is
    Generic (
          DATA_N  : natural := 128;
          KEYS_N  : natural := 128
    );
    Port (
           Clk    : in std_logic;
           Resetn : in std_logic;

           -- Interface in
           DataIn       : in std_logic_vector (31 downto 0);
           init_reg_en  : in std_logic;
           input_reg_en : in std_logic;
           crypt_en     : in std_logic;

           -- Interace out
           DataOut         : out std_logic_vector (31 downto 0);
           output_reg_en   : in std_logic;
           output_reg_load : in std_logic
   );
end RSADatapath;

architecture RTL of RSADatapath is
    -- Input related signals
    signal input_r, input_nxt : std_logic_vector(DATA_N - 1 downto 0);

    -- Keys and parameters related signals. Assuming keys and params are of
    -- equal length.
    signal keye_r, keye_nxt : std_logic_vector(KEYS_N - 1 downto 0);
    signal keyn_r, keyn_nxt : std_logic_vector(KEYS_N - 1 downto 0);
    signal parx_r, parx_nxt : std_logic_vector(KEYS_N - 1 downto 0);
    signal pary_r, pary_nxt : std_logic_vector(KEYS_N - 1 downto 0);

    -- Output related signals
    signal output_r, output_nxt : std_logic_vector(DATA_N - 1 downto 0);

    -- Encryption related signals and variables
    signal crypt_r : std_logic_vector(DATA_N - 1 downto 0);
begin
    DataOut <= output_r(31 downto 0);

    ----------------------------------------------------------------------------
    ---- Init
    -- The parameters and keys are assumed to be sent in 32-bit chunks with the
    -- least significant bits first and received in the order:
    -- KeyE, KeyN, ParX, ParY.
    ----------------------------------------------------------------------------
    init_assign : process(Clk, Resetn) begin
        if (Resetn = '0') then
            pary_r <= (others => '0');
            parx_r <= (others => '0');
            keyn_r <= (others => '0');
            keye_r <= (others => '0');
        elsif (Clk'event and Clk = '1') then
            if (init_reg_en = '1') then
                pary_r <= pary_nxt;
                parx_r <= parx_nxt;
                keyn_r <= keyn_nxt;
                keye_r <= keye_nxt;
            end if;
        end if;
    end process;

    init_ripple : process(DataIn, keye_r, keyn_r, parx_r, pary_r) begin
        pary_nxt <= DataIn & pary_r(127 downto 32);
        parx_nxt <= pary_r(31 downto 0) & parx_r(127 downto 32);
        keyn_nxt <= parx_r(31 downto 0) & keyn_r(127 downto 32);
        keye_nxt <= keyn_r(31 downto 0) & keye_r(127 downto 32);
    end process;

    ----------------------------------------------------------------------------
    ---- Input
    -- The input is assumed to be sent in 32-bit chunks with the least
    -- significant bits first.
    ----------------------------------------------------------------------------
    input_assign : process(Clk, Resetn) begin
        if (Resetn = '0') then
            input_r <= (others => '0');
        elsif (Clk'event and Clk = '1') then
            if (input_reg_en = '1') then
                input_r <= input_nxt;
            end if;
        end if;
    end process;

    input_ripple : process(DataIn, input_r) begin
        input_nxt <= DataIn & input_r(127 downto 32);
    end process;

    ----------------------------------------------------------------------------
    ---- En-/decryption
    -- crypt_1 uses a for loop and takes a lot of space but a very short time
    -- crypt_2 takes a long time but uses much less space
    ----------------------------------------------------------------------------
    -- crypt_1 : process(crypt_en, Resetn)
    --     variable C : unsigned(DATA_N - 1 downto 0);
    --     variable P : unsigned(DATA_N - 1 downto 0);
    --     variable n : unsigned(KEYS_N - 1 downto 0);
    -- begin
    --     if (Resetn = '0') then
    --         crypt_r <= (others => '0');
    --     elsif (crypt_en'event and crypt_en = '1') then
    --         C := (0 => '1', others => '0');
    --         P := unsigned(input_r);
    --         n := unsigned(keyn_r);
    --         for i in 0 to KEYS_N - 2 loop
    --             if (keye_r(i) = '1') then
    --                 C := (C * P) mod n;
    --             end if;
    --             P := (P * P) mod n;
    --         end loop;
    --         if (keye_r(KEYS_N-1) = '1') then
    --             C := (C * P) mod n;
    --         end if;
    --         crypt_r <= std_logic_vector(C);
    --     end if;
    -- end process;

    crypt_2 : process(Clk, Resetn)
        variable C : unsigned(DATA_N - 1 downto 0);
        variable P : unsigned(DATA_N - 1 downto 0);
        variable n : unsigned(KEYS_N - 1 downto 0);
        variable i : natural range 0 to KEYS_N;
    begin
        if (Resetn = '0') then
            crypt_r <= (others => '0');
            C       := (others => '0');
            P       := (others => '0');
            n       := (others => '0');
            i       := 0;
        elsif (Clk'event and Clk = '1') then
            if (crypt_en = '1') then
                if (i = 0) then
                    C := (0 => '1', others => '0');
                    P := unsigned(input_r);
                    n := unsigned(keyn_r);
                end if;
                if (i < KEYS_N - 1) then
                    if (keye_r(i) = '1') then
                        C := (C * P) mod n;
                    end if;
                    P := (P * P) mod n;
                    i := i + 1;
                elsif (i = KEYS_N - 1) then
                    if (keye_r(i) = '1') then
                        C := (C * P) mod n;
                    end if;
                    i := i + 1;
                end if;
                crypt_r <= std_logic_vector(C);
            else
                crypt_r <= crypt_r;
                C := (others => '0');
                P := (others => '0');
                n := (others => '0');
                i := 0;
            end if;
        end if;
    end process;


    ----------------------------------------------------------------------------
    ---- Output
    -- The out data is serially sent out in 32-bit chunks. After the answer is
    -- sent the output is 0.
    ----------------------------------------------------------------------------
    output_assign : process(Clk, Resetn) begin
        if (Resetn = '0') then
            output_r <= (others => '0');
        elsif (Clk'event and Clk = '1') then
            if (output_reg_en = '1') then
                output_r <= output_nxt;
            end if;
        end if;
    end process;

    output_ripple : process(crypt_r, output_r, output_reg_load) begin
        if (output_reg_load = '1') then
            output_nxt <= crypt_r;
        else
            output_nxt <= x"00000000" & output_r(127 downto 32);
        end if;
    end process;

end RTL;
