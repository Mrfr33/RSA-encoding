----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 25.10.2017 11:43:12
-- Design Name:
-- Module Name: RSACore - Behavioral
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
use IEEE.numeric_std.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity RSACore is
    Port (
        Clk    : in std_logic;
        Resetn : in std_logic;

        -- Control signals
        InitRsa      : in std_logic;
        StartRsa     : in std_logic;
        CoreFinished : out std_logic;

        -- Data busses
        DataIn  : in std_logic_vector (31 downto 0);
        DataOut : out std_logic_vector (31 downto 0)
    );
end RSACore;

architecture core of RSACore is
    signal init_reg_en     : std_logic;
    signal input_reg_en    : std_logic;
    signal output_reg_en   : std_logic;
    signal output_reg_load : std_logic;
    signal crypt_en        : std_logic;
begin

    datapath : entity work.RSADatapath port map(
        Clk             => Clk,
        Resetn          => Resetn,

        DataIn          => DataIn,
        init_reg_en     => init_reg_en,
        input_reg_en    => input_reg_en,

        DataOut         => DataOut,
        output_reg_en   => output_reg_en,
        output_reg_load => output_reg_load,
        crypt_en        => crypt_en
    );

    controller : entity work.RSAControl port map(
        Clk             => Clk,
        Resetn          => Resetn,

        InitRsa         => InitRsa,
        StartRsa        => StartRsa,

        CoreFinished    => CoreFinished,
        init_reg_en     => init_reg_en,
        input_reg_en    => input_reg_en,
        output_reg_en   => output_reg_en,
        output_reg_load => output_reg_load,
        crypt_en        =>  crypt_en
    );

end core;
