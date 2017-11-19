--------------------------------------------------------------
-- Entity Name : RSAEncrypt
-- Team : Flight 501
-- Work : Responsible of the Encryption
-- Use MG_multiplier.vhd
-- Description :
--------------------------------------------------------------


library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity RSAEncrypt is
  Generic(  SIZE : natural := 128);
  Port(     MESSAGE : in unsigned(SIZE-1 downto 0);
            KEY_E : in unsigned(SIZE-1 downto 0);
            MOD_N : in unsigned(SIZE-1 downto 0);
            clk : in std_logic;
            reset : in std_logic;
            CRYPT : out unsigned (SIZE-1 downto 0)
  );
end RSAEncrypt;

architecture Iss of RSAEncrypt is
  constant zero : unsigned(SIZE-1 downto 0) := (others => '0');
  constant K :unsigned (SIZE-1 downto 0) := "00000110010001101110000100100000101111011101110010111101100011001010101111001011011010101000010100001011000100011101101000011110";

  -- signals
  signal temp_A1,temp_A2 : unsigned(SIZE-1 downto 0) := (SIZE-1 downto 0 => '0');
  signal temp_B1, temp_B2 : unsigned(SIZE-1 downto 0) := (SIZE-1 downto 0 => '0');
  signal Mod_temp : unsigned(SIZE-1 downto 0) := (SIZE-1 downto 0 => '0');
  signal Out_temp : unsigned(SIZE-1 downto 0):= (SIZE-1 downto 0 => '0');
  signal MG1_out, MG2_out : unsigned(SIZE-1 downto 0) := (SIZE-1 downto 0 => '0');

  -- flags :
  signal lock1, lock2 : std_logic := '0'; -- locks are at '1' when the correspondant multiplier is used.// "lock ='1' <=> mult computing" & "lock='0' <=> data available"
  signal ready1, ready2 : std_logic := '0';
  -- for fsm :
  type STATE_TYPE is (LAUNCH_PENDING, SC_COMPUTING, SET_MULT12, GET_MULT12, LOOP_S1, LOOP_S2, SET_MULT_OUT, GET_MULT_OUT, LOOP_S3, MISSION_COMPLETE)
  signal state: STATE_TYPE := LAUNCH_PENDING

  component MG_multiplier
  Generic ( SIZE : integer :=32);
  Port (  A : in unsigned(SIZE-1 downto 0);
          B : in unsigned(SIZE-1 downto 0);
          N_mod : in unsigned(SIZE-1 downto 0);
          clk : in std_logic;
          lock : in std_logic;
          reset : in std_logic;
          mult_ended : in std_logic;
          product : out unsigned(SIZE-1 downto 0));
--  end component;
-- =================================================================================================================================
begin
-- start component
  MG1 : MG_multiplier
    Generic map(SIZE => SIZE);
    Port map( A => temp_A1,
              B => temp_B1,
              N_mod => Mod_temp,
              clk => clk,
              lock => lock1,
              reset => reset,
              mult_ended => ready1,
              product => MG1_out  );

  MG2 : MG_multiplier
    Generic map(SIZE => SIZE);
    Port map( A => temp_A2,
              B => temp_B2,
              N_mod => Mod_temp,
              clk => clk,
              lock => lock2,
              reset => reset,
              mult_ended => ready2,
              product => MG2_out  );

  CRYPT <= Out_temp;

-- ----------------------- Start Process ----------------------------------
  encryption : process(clk,MESSAGE,reset)
  -- VARIABLES INITIALIZATION
  variable count : integer := 0;
  variable shift_count : integer := 0;
  variable MSG_TMP : unsigned(SIZE-1 downto 0):= (SIZE-1 downto 0 => '0');
  variable P : unsigned(SIZE-1 downto 0):= (SIZE-1 downto 0 => '0');
  variable P_old : unsigned(SIZE-1 downto 0):= (SIZE-1 downto 0 => '0');
  variable R : unsigned(SIZE-1 downto 0):= (SIZE-1 downto 0 => '0');
  variable var_exp : unsigned(SIZE-1 downto 0);
  variable var_mod : unsigned(SIZE-1 downto 0);

  begin
  -- Reset
  if reset = '1' then
    -- Reseting variables
    count := '0';
    shift_count :='0';
    MSG_TMP := (others => '0');
  	P := (others => '0');
  	R := (others => '0');
  	var_exp := (others => '0');
  	var_mod := (others => '0');
  	Mod_temp <= (others => '0');

    state <= LAUNCH_PENDING; --Go back to the initializing state

  elsif rising_edge(clk) then


  -------------------- // FSM // -------------------------
  -- The FSM is used to design the process of encryption
  --
  --------------------------------------------------------
    case( state ) is
      when LAUNCH_PENDING => -- Waiting state
      if((MESSAGE = zero)) OR ((Mod_temp = MOD_N) AND (MSG_TMP = MESSAGE)) then
          state <= LAUNCH_PENDING;
      else
        var_mod := MOD_N;
        state <= SC_COMPUTING;
      end if;

      -- ======================================================================
    	when SC_COMPUTING =>   -- If MSB of modulus is not 1 then shift it left until a 1 is found and count how many times it was shifted
      	if(var_mod(SIZE-1) = '1')then;
      		var_exp := KEY_E;
      		Mod_temp <= MOD_N;
      		MSG_TMP := MESSAGE;
      		state <= SET_MULT12;
      	else
      		var_mod := (shift_left(var_mod,natural(1)));
      		shift_count := shift_count + 1;
      		state <= SC_COMPUTING;
      	end if;

    	-- ======================================================================
      when SET_MULT12 => -- Set up MG1 & MG2 for R and P Computations
      	if(unsigned(K) > zero)then
      		temp_A1 <= unsigned(K);
      		temp_B1 <= MSG_TMP;

      		temp_A2 <= unsigned(K);
      		temp_B2 <= to_unsigned(1,SIZE);

      		lock1 <= '1';
      		lock2 <= '1';

      		if(ready1 = '0') AND (ready2 = '0')then
      			state <= GET_MULT12;
      		end if;
      	else
      		state <= SET_MULT12;
      	end if;

      -- ======================================================================
      when GET_MULT12 => -- Assign the results of the computations
      	lock1 <= '0';
      	lock2 <= '0';

      	if((ready1 = '1') AND (ready2 = '1')) then
      		P_old := MG1_out;
      		R := MG2_out;
      		state <= LOOP_S1;
      	end if;
    	-- =====================================================================
    	when LOOP_S1 =>
    		temp_A1 <= P_old;
    		temp_B1 <= P_old;
    		lock1 <= '1';

    		if(ready1 = '0')then
    			state <= LOOP_S2;
    		end if;

    	-- ======================================================================
    	when LOOP_S2 => -- If LSB of the exponent is 1 then compute R, else go to LOOP_state 3
      	lock1 <= '0';
      	if(ready1 = '1')then
      		P := MG1_out;
      		if(var_exp(0) = '1')then
      			state <= SET_MULT_OUT;
      		else
      			state <= LOOP_S3;
      		end if;
      	end if;
      -- ======================================================================
    	when SET_MULT_OUT =>
    		temp_A2 <= R;
    		temp_B2 <= P_old;
    		lock2 <= '1';

    		if(ready2 = '0')then
    			state <= GET_MULT_OUT;
    		end if;

      -- ======================================================================
    	when GET_MULT_OUT =>
    		lock2 <= '0';
    		if(ready2 = '1') then
    			R <= MG2_out;
          lock1 <= '1';
      		if(ready1 ='0')then
      			state <= MISSION_COMPLETE;
      		end if;
    		end if;

      -- ======================================================================
      when LOOP_S3 => -- If the statement is true, it means that we have checked all bits in the exponent or exponent is zero and we compute the output
    		if (count = (SIZE-1)-shift_count) OR (var_exp = zero) then
    			temp_A1 <= to_unsigned(1,SIZE);
    			temp_B1 <= R;
          lock1 <= '1';
      		if(ready1 ='0')then
      			state <= MISSION_COMPLETE;
      		end if;

    		else    -- if the statement is false, then we shift the exponent right and increment count
    			var_exp := (shift_right(var_exp, natural(1)));
    			P_old := P;
    			count := count + 1;
    			state <= LOOP_S1;
    		end if;

      -- ======================================================================
    	--when s9 =>

    		--lock1 <= '1';
    		--if(ready1 ='0')then
    			--state <= MISSION_COMPLETE;
    		--end if;

      -- ======================================================================
      when MISSION_COMPLETE =>
    		lock1 <= '0';
    		if(ready1 = '1') then
    			Out_temp <= MG1_out;
          -- Reseting variables
          var_exp := (others => '0');
    			count := 0;
    			shift_count := 0;
    			P := (others => '0');
    			R := (others => '0');
    			var_mod := (others => '0');
          -- Back to start
    			state <= LAUNCH_PENDING;
    		end if;
    end case;
  end if;
end process;
end Iss;
