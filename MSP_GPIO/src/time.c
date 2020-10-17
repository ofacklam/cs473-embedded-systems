/*
 * time.c
 *
 *  Created on: Oct 15, 2020
 *      Author: ofacklam
 */
#include "time.h"


/**
 * Log function
 */
uint8_t log2(uint8_t in) {
	int count = 7;

	if(in == 0)
		return 0;

	while(!(in & 0x80)) { // test MSB
		count--;
		in = in << 1;
	}
	return count;
}


/**
 * Set up the DCO clock
 */
void dco_setup(int khz) {
	if(khz < 1000 || khz >= 64000)
		return;

	// calculate correct frequency mode
	uint8_t mode = log2(khz/1000);
	uint32_t rsel = (mode << CS_CTL0_DCORSEL_OFS) & CS_CTL0_DCORSEL_MASK;
	int center_frq = ((1 << mode) + (1 << (mode+1))) * 500; // in khz

	// get calibration values
	uint32_t fcal = mode < 5 ? TLV->DCOIR_FCAL_RSEL04 : TLV->DCOIR_FCAL_RSEL5;
	float k = *((float*) (mode < 5 ? &TLV->DCOIR_CONSTK_RSEL04 : &TLV->DCOIR_CONSTK_RSEL5));

	// calculate tuning with formula
	uint16_t n_tune = (khz-center_frq) * (1 + k * (768-fcal)) / (khz * k);
	uint32_t tune = n_tune & CS_CTL0_DCOTUNE_MASK;

	// write-enable the clock system
	CS->KEY = CS_KEY_VAL;

	// write DCO tuning info
	CS->CTL0 &= ~(CS_CTL0_DCORSEL_MASK | CS_CTL0_DCOTUNE_MASK);
	CS->CTL0 |= rsel | tune;

	// lock
	CS->KEY = 0;
}


/**
 * Set system clocks
 */
void dco_to_master(int m_clk_div, int s_clk_div) {
	if(m_clk_div < 1 || m_clk_div > 128 || s_clk_div < 1 || s_clk_div > 128)
		return;

	// calculate division modes
	uint32_t divm = (log2(m_clk_div) << CS_CTL1_DIVM_OFS) & CS_CTL1_DIVM_MASK;
	uint32_t divs = (log2(s_clk_div) << CS_CTL1_DIVS_OFS) & CS_CTL1_DIVS_MASK;

	// write-enable CS
	CS->KEY = CS_KEY_VAL;

	// write selection and division
	CS->CTL1 &= ~(CS_CTL1_SELM_MASK | CS_CTL1_DIVM_MASK | CS_CTL1_SELS_MASK | CS_CTL1_DIVS_MASK);
	CS->CTL1 |= CS_CTL1_SELM__DCOCLK | divm | CS_CTL1_SELS__DCOCLK | divs;

	// lock
	CS->KEY = 0;
}


/**
 * Calculates number of clock cycles to get requested timeout, also sets dividers
 */
int calculate_cycles(int ms, int* div_id, int* div_idex) {
	// We use the SM_CLK for timing the delay
	int num_cycles = ms * DCO_FREQ / SM_DIV; // freq in khz

	// set up the dividers (div_1 is in log (0..3 --> 1..8), div_2 is in linear)
	int max_val = (1 << 16);
	int div_1 = 0, div_2 = 1;

	while(num_cycles >= max_val && div_1 < 3) {
		div_1++; // multiplies by 2
		num_cycles /= 2;
	}
	while(num_cycles >= max_val && div_2 < 8) {
		div_2 *= 2;
		num_cycles /= 2;
	}

	// not possible
	if(num_cycles >= max_val) {
		return -1;
	}

	*div_id = div_1;
	*div_idex = div_2;
	return num_cycles;
}


/**
 * Setup timer block
 */
void timer_block_setup(Timer_A_Type* T, uint16_t mode, uint16_t source, int div_id, int div_idex) {
	uint16_t ctl_id = (div_id << TIMER_A_CTL_ID_OFS) & TIMER_A_CTL_ID_MASK;
	uint16_t ex0_idex = (div_idex - 1) & TIMER_A_EX0_IDEX_MASK;

	// set input, mode & divider ID
	T->CTL &= ~(TIMER_A_CTL_MC_MASK | TIMER_A_CTL_ID_MASK | TIMER_A_CTL_SSEL_MASK);
	T->CTL |= mode | source | ctl_id;

	// set second divider
	T->EX0 = ex0_idex;
}


/**
 * Set the timer block to UP mode, with the specified period
 */
int timer_block_setup_mode_up(Timer_A_Type* T, int period) {
	// get cycle count for period
	int div_id, div_idex;
	int num_cycles = calculate_cycles(period, &div_id, &div_idex);
	if(num_cycles < 0)
		return -1;

	// setup input
	timer_block_setup(T, TIMER_A_CTL_MC__UP, TIMER_A_CTL_SSEL__SMCLK, div_id, div_idex);
	// clear interrupt flag & set compare mode
	T->CCTL[0] &= ~(TIMER_A_CCTLN_CCIFG | TIMER_A_CCTLN_CAP);
	// EQU0 for max value
	T->CCR[0] = num_cycles;

	return 0;
}


/**
 * Extended wait function: takes an amount of milliseconds as argument, as well as the timer
 */
int timer_wait(int ms, Timer_A_Type* T) {
	// get cycle count
	int div_id, div_idex;
	int num_cycles = calculate_cycles(ms, &div_id, &div_idex);

	if(num_cycles < 0)
		return -1;

	// reset timer
	T->CTL |= TIMER_A_CTL_CLR;

	// setup inputs
	timer_block_setup(T, TIMER_A_CTL_MC__CONTINUOUS, TIMER_A_CTL_SSEL__SMCLK, div_id, div_idex);

	// set compare mode, clear interrupt flag
	T->CCTL[0] &= ~(TIMER_A_CCTLN_CCIFG | TIMER_A_CCTLN_CAP);

	// set value
	T->CCR[0] = num_cycles;

	// poll interrupt flag
	while(!(T->CCTL[0] & TIMER_A_CCTLN_CCIFG));

	// clear flag
	T->CCTL[0] &= ~TIMER_A_CCTLN_CCIFG;
	return 0;
}


/**
 * Convenience function with timer A0
 */
int wait(int ms) {
	return timer_wait(ms, TIMER_A0);
}


/**
 * Create PWM on timer output
 */
void timer_pwm_setup(Timer_A_Type* T, int idx, int width, float duty_cycle) {
	// idx between CCR1 and CCR4
	if(idx < 1 || idx > 4)
		return;

	// reset timer
	T->CTL |= TIMER_A_CTL_CLR;

	// set timer block to up mode, with specified width
	if(timer_block_setup_mode_up(T, width) < 0)
		return;

	// EQUn for active value
	timer_pwm_duty(T, idx, duty_cycle);

	// outmod -> reset/set
	T->CCTL[idx] &= ~TIMER_A_CCTLN_OUTMOD_MASK;
	T->CCTL[idx] |= TIMER_A_CCTLN_OUTMOD_7;
}


/**
 * Edit PWM duty cycle
 */
void timer_pwm_duty(Timer_A_Type* T, int idx, float duty_cycle) {
	// idx between CCR1 and CCR4
	if(idx < 1 || idx > 4)
		return;

	// duty between 0 and 1
	if(duty_cycle < 0 || duty_cycle > 1)
		return;

	T->CCR[idx] = duty_cycle * T->CCR[0];
}


/**
 * Global variable to store timer callback function pointer
 */
TimerHandler timer_handler = NULL;


/**
 * Timer A3 interrupt handler -> calls callback
 */
void TA3_0_IRQHandler(void) {
	// Clear interrupt flag before doing anything
	TIMER_A3->CCTL[0] &= ~TIMER_A_CCTLN_CCIFG;

	// Call callback if one is set
	if(timer_handler)
		timer_handler();
}


/**
 * Set a new timer callback
 */
void timer_irq_handler(TimerHandler fun) {
	timer_handler = fun;
}


/**
 * Periodic interrupt, calling function fun
 * Uses timer A3
 */
void periodic_interrupt(int period, TimerHandler fun) {
	Timer_A_Type* T = TIMER_A3;
	IRQn_Type irq = TA3_0_IRQn;

	if(timer_block_setup_mode_up(T, period) < 0)
		return;

	// enable CCR interrupts triggers
	T->CCTL[0] |= TIMER_A_CCTLN_CCIE;

	// set handler
	timer_irq_handler(fun);

	// enable interrupt handling
	NVIC_EnableIRQ(irq);
	NVIC_SetPriority(irq, 4);
}

