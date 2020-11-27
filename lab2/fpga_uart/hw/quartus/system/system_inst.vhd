	component system is
		port (
			clk_clk                 : in  std_logic := 'X'; -- clk
			reset_reset_n           : in  std_logic := 'X'; -- reset_n
			customuart_0_trx_out_rx : in  std_logic := 'X'; -- rx
			customuart_0_trx_out_tx : out std_logic         -- tx
		);
	end component system;

	u0 : component system
		port map (
			clk_clk                 => CONNECTED_TO_clk_clk,                 --                  clk.clk
			reset_reset_n           => CONNECTED_TO_reset_reset_n,           --                reset.reset_n
			customuart_0_trx_out_rx => CONNECTED_TO_customuart_0_trx_out_rx, -- customuart_0_trx_out.rx
			customuart_0_trx_out_tx => CONNECTED_TO_customuart_0_trx_out_tx  --                     .tx
		);

