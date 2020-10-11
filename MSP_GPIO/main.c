#include "msp.h"
#include <stdio.h>

#define DCO_FREQ 3000
#define M_DIV 1
#define SM_DIV 4

/**
 * main.c
 */
typedef struct {
	uint16_t active;
	uint16_t period;
} Timing;

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
void setup_dco(int khz) {
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
void use_dco_master(int m_clk_div, int s_clk_div) {
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
 * Creates a single period of duty cycling on the given port/bit (must be initialized to output mode)
 * Returns the timing measurements of the duty cycle
 */
Timing pwm_soft_period(uint8_t volatile *out, int bit, int active, int period) {
	int i, time_start, time_end_on, time_end_off;

	// ON duty cycle
	time_start = TIMER_A0->R;
	*out |= BIT(bit);
	for (i = 0; i < active; i++);

	// OFF duty cycle
	time_end_on = TIMER_A0->R;
	*out &= ~BIT(bit);
	for (i = 0; i < period - active; i++);

	time_end_off = TIMER_A0->R;

	Timing t;
	t.active = time_end_on - time_start;
	t.period = time_end_off - time_start;
	return t;
}

/**
 * Creates an infinite loop software duty cycle
 * PORT and TIMER_A0 must be set up
 */
void pwm_soft(uint8_t volatile *out, int bit, int active, int period) {
	while (1) {
		int i, total_active = 0, total_period = 0, num_periods = 1000;

		for (i = 0; i < num_periods; i++) {
			Timing t = pwm_soft_period(out, bit, active, period);
			total_active += t.active;
			total_period += t.period;
		}

		printf("On for %d cycles, out of total period of %d cycles :)\n",
				total_active / num_periods, total_period / num_periods);
	}
}

void manip_1() {
	int duty_cycle = 10, max_cycle = 1000;

	// setup port
	P2->DIR = 0xFF;
	P2->OUT = 0x00;

	//Clear & set up timer A0
	TIMER_A0->CTL &= ~(TIMER_A_CTL_MC_MASK | TIMER_A_CTL_ID_MASK
			| TIMER_A_CTL_SSEL_MASK);
	TIMER_A0->CTL |= TIMER_A_CTL_MC__CONTINUOUS | TIMER_A_CTL_SSEL__SMCLK;

	pwm_soft(&P2->OUT, 4, duty_cycle, max_cycle);
}

/**
 * Create a strobe effect by rotation a 1 on the given bits for the given port
 */
void strobe_effect(uint8_t volatile *out, int* bits, int num, int period) {
	int i, c;
	uint8_t mask = 0;
	for(i = 0; i < num; i++)
		mask |= BIT(bits[i]);

	while(1) {
		for(i = 0; i < num; i++) {
			// Turn off everything
			*out &= ~mask;
			// Turn on correct bit
			*out |= BIT(bits[i]);
			// Wait for period
			for(c = 0; c < period; c++);
		}
	}
}

void manip_2() {
	int period = 10000;
	int bits[] = {0, 1, 2};

	// setup port
	P2->DIR = 0xFF;
	P2->OUT = 0x00;

	strobe_effect(&P2->OUT, bits, 3, period);
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
 * Setup timer
 */
void set_timer_input(Timer_A_Type* T, uint16_t mode, uint16_t source, int div_id, int div_idex) {
	uint16_t ctl_id = (div_id << TIMER_A_CTL_ID_OFS) & TIMER_A_CTL_ID_MASK;
	uint16_t ex0_idex = (div_idex - 1) & TIMER_A_EX0_IDEX_MASK;

	// set input, mode & divider ID
	T->CTL &= ~(TIMER_A_CTL_MC_MASK | TIMER_A_CTL_ID_MASK | TIMER_A_CTL_SSEL_MASK);
	T->CTL |= mode | source | ctl_id;

	// set second divider
	T->EX0 = ex0_idex;
}

/**
 * Extended wait function: takes an amount of milliseconds as argument, as well as the timer
 */
void wait_timer(int ms, Timer_A_Type* T) {
	// get cycle count
	int div_id, div_idex;
	int num_cycles = calculate_cycles(ms, &div_id, &div_idex);

	if(num_cycles < 0)
		return;

	// reset timer
	T->CTL |= TIMER_A_CTL_CLR;

	// setup inputs
	set_timer_input(T, TIMER_A_CTL_MC__CONTINUOUS, TIMER_A_CTL_SSEL__SMCLK, div_id, div_idex);

	// set compare mode, clear interrupt flag
	T->CCTL[0] &= ~(TIMER_A_CCTLN_CCIFG | TIMER_A_CCTLN_CAP);

	// set value
	T->CCR[0] = num_cycles;

	// poll interrupt flag
	while(!(T->CCTL[0] & TIMER_A_CCTLN_CCIFG));

	// clear flag
	T->CCTL[0] &= ~TIMER_A_CCTLN_CCIFG;
	return;
}

/**
 * Standard wait function: argument is time in milliseconds
 * Uses TIMER_A0
 */
void wait(int ms) {
	return wait_timer(ms, TIMER_A0);
}

/**
 * Edit PWM duty cycle
 */
void set_pwm_duty(Timer_A_Type* T, int idx, float duty_cycle) {
	// idx between CCR1 and CCR4
	if(idx < 1 || idx > 4)
		return;

	// duty between 0 and 1
	if(duty_cycle < 0 || duty_cycle > 1)
		return;

	T->CCR[idx] = duty_cycle * T->CCR[0];
}

/**
 * Set the timer block to UP mode, with the specified period
 */
int timer_block_mode_up(Timer_A_Type* T, int period) {
	// get cycle count for period
	int div_id, div_idex;
	int num_cycles = calculate_cycles(period, &div_id, &div_idex);
	if(num_cycles < 0)
		return -1;

	// setup input
	set_timer_input(T, TIMER_A_CTL_MC__UP, TIMER_A_CTL_SSEL__SMCLK, div_id, div_idex);
	// clear interrupt flag & set compare mode
	T->CCTL[0] &= ~(TIMER_A_CCTLN_CCIFG | TIMER_A_CCTLN_CAP);
	// EQU0 for max value
	T->CCR[0] = num_cycles;

	return 0;
}

/**
 * Create PWM on timer output
 */
void pwm_timer_setup(Timer_A_Type* T, int idx, int width, float duty_cycle) {
	// idx between CCR1 and CCR4
	if(idx < 1 || idx > 4)
		return;

	// reset timer
	T->CTL |= TIMER_A_CTL_CLR;

	// set timer block to up mode, with specified width
	if(timer_block_mode_up(T, width) < 0)
		return;

	// EQUn for active value
	set_pwm_duty(T, idx, duty_cycle);

	// outmod -> reset/set
	T->CCTL[idx] &= ~TIMER_A_CCTLN_OUTMOD_MASK;
	T->CCTL[idx] |= TIMER_A_CCTLN_OUTMOD_7;
}

/**
 * Link module output to port
 */
void use_module_port(uint8_t volatile *dir, uint8_t volatile *sel0, uint8_t volatile *sel1, int bit) {
	// select module
	*sel1 &= ~BIT(bit);
	*sel0 |= BIT(bit);

	*dir |= BIT(bit); // activate output
}

/**
 * Set up PWM on a specific port / bit
 * Port can be 2 or 7, bits in range [4..7]
 */
void pwm_hard_timer(int port, int bit, int width, float duty_cycle, int init) {
	if(port != 2 && port != 7)
		return;

	if(bit < 4 || bit >= 8)
		return;

	uint8_t volatile *sel0, *sel1, *dir;
	Timer_A_Type* timer;
	int timer_ccr_idx;

	if(port == 2) {
		sel0 = &P2->SEL0;
		sel1 = &P2->SEL1;
		dir = &P2->DIR;
		timer = TIMER_A0;
		timer_ccr_idx = bit - 3;
	}
	if(port == 7) {
		sel0 = &P7->SEL0;
		sel1 = &P7->SEL1;
		dir = &P7->DIR;
		timer = TIMER_A1;
		timer_ccr_idx = 8 - bit;
	}

	if(init) {
		pwm_timer_setup(timer, timer_ccr_idx, width, duty_cycle);
		use_module_port(dir, sel0, sel1, bit);
	} else {
		set_pwm_duty(timer, timer_ccr_idx, duty_cycle);
	}
}

/**
 * Sets up a PWM on pin 2.4, with a fixed width of 20ms
 * Uses timer A0
 */
void pwm_hard_timer_fixed(float duty_cycle) {
	return pwm_hard_timer(2, 4, 20, duty_cycle, 1);
}

void set_pwm_hard_timer_fixed_duty(float duty_cycle) {
	return pwm_hard_timer(2, 4, 20, duty_cycle, 0);
}

void manip_3() {
	P2->DIR = 0xFF;
	P2->OUT = 0x00;

	while(1) {
		P2->OUT |= 16;
		wait(50);
		P2->OUT &= ~16;
		wait(100);
	}
}

void manip_4() {
	// vary the angle of servo over time
	int resolution = 100;
	int period = 4000; //ms
	int value = 0;

	pwm_hard_timer_fixed(0);

	while(1) {
		float duty = 0.05 + 0.05 * value / resolution;

		set_pwm_hard_timer_fixed_duty(duty);
		wait_timer(period / resolution, TIMER_A1);

		value = (value + 1) % resolution;
	}
}

void periodic_interrupt(int period) {
	Timer_A_Type* T = TIMER_A0;
	IRQn_Type irq = TA0_0_IRQn;

	if(timer_block_mode_up(T, period) < 0)
		return;

	// enable CCR interrupts triggers
	T->CCTL[0] |= TIMER_A_CCTLN_CCIE;

	// enable interrupt handling
	NVIC_EnableIRQ(irq);
	NVIC_SetPriority(irq, 4);
}

void adc_conversion_start();
void TA0_0_IRQHandler(void) {
	// Clear interrupt flag before doing anything
	TIMER_A0->CCTL[0] &= ~TIMER_A_CCTLN_CCIFG;

	P2->OUT ^= BIT(4);
	adc_conversion_start();
}

void manip_5() {
	P2->DIR = 0xFF;
	P2->OUT = 0x00;
	periodic_interrupt(50);
}

void adc_setup(uint32_t clk_src, uint32_t trigger, uint32_t resolution_mode) {
	// Turn ADC on, clear conversion
	ADC14->CTL0 |= ADC14_CTL0_ON;
	ADC14->CTL0 &= ~ADC14_CTL0_ENC;

	// Select pulse mode, single conversion
	ADC14->CTL0 |= ADC14_CTL0_SHP;
	ADC14->CTL0 &= ~ADC14_CTL0_CONSEQ_MASK;

	// Select clock
	ADC14->CTL0 &= ~ADC14_CTL0_SSEL_MASK;
	ADC14->CTL0 |= (clk_src & ADC14_CTL0_SSEL_MASK);

	// Select trigger signal
	ADC14->CTL0 &= ~ADC14_CTL0_SHS_MASK;
	ADC14->CTL0 |= (trigger & ADC14_CTL0_SHS_MASK);

	// Select resolution
	ADC14->CTL1 &= ~ADC14_CTL1_RES_MASK;
	ADC14->CTL1 |= (resolution_mode & ADC14_CTL1_RES_MASK);
}

int calculate_adc_timer_mode(int sample_time) {
	int modes[] = {4, 8, 16, 32, 64, 96, 128, 192};

	int min_cycles = 1 + sample_time * DCO_FREQ / (1000*SM_DIV); // sample_time in us, freq in khz
	int mode = 8;

	while(mode > 0 && min_cycles <= modes[mode-1])
		mode--;

	return mode;
}

void adc_memory_setup(int idx, int channel, int sample_time) {
	// Single-ended mode, with ref (Vcc, Vss)
	ADC14->MCTL[idx] &= ~ADC14_MCTLN_DIF;
	ADC14->MCTL[idx] &= ~ADC14_MCTLN_VRSEL_MASK;

	// Select timer mode
	int mode = calculate_adc_timer_mode(sample_time);
	if(mode < 0 || mode > 7)
		return;

	int mask, ofs;
	if(idx <= 7 || idx >= 24) {
		mask = ADC14_CTL0_SHT0_MASK;
		ofs = ADC14_CTL0_SHT0_OFS;
	} else {
		mask = ADC14_CTL0_SHT1_MASK;
		ofs = ADC14_CTL0_SHT1_OFS;
	}
	ADC14->CTL0 &= ~mask;
	ADC14->CTL0 |= (mode << ofs) & mask;

	// Select channel
	ADC14->MCTL[idx] &= ~ADC14_MCTLN_INCH_MASK;
	ADC14->MCTL[idx] |= channel & ADC14_MCTLN_INCH_MASK;

	// Set conversion address to this memory
	ADC14->CTL1 &= ~ADC14_CTL1_CSTARTADD_MASK;
	ADC14->CTL1 |= (idx << ADC14_CTL1_CSTARTADD_OFS) & ADC14_CTL1_CSTARTADD_MASK;

	// Enable interrupt for this memory
	ADC14->CLRIFGR0 |= 1 << idx;
	ADC14->IER0 |= 1 << idx;
}

void adc_interrupts_enable() {
	NVIC_EnableIRQ(ADC14_IRQn);
	NVIC_SetPriority(ADC14_IRQn, 4);
}

void adc_conversion_enable() {
	ADC14->CTL0 |= ADC14_CTL0_ENC;
}

void adc_conversion_disable() {
	ADC14->CTL0 &= ~ADC14_CTL0_ENC;
}

void adc_conversion_start() {
	ADC14->CTL0 |= ADC14_CTL0_SC;
}

void use_port_adc(int bit, uint8_t volatile *sel_0, uint8_t volatile *sel_1) {
	// both select bits to 1, to minimize parasitics & enable ADC input
	*sel_0 |= BIT(bit);
	*sel_1 |= BIT(bit);
}

void ADC14_IRQHandler(void) {
	// Read interrupt vector & get memory index
	int int_nb = ADC14->IV;
	int idx = int_nb/2 - 6;

	// if not a conversion finish, simply clear flags
	if(idx < 0 || idx > 31) {
		ADC14->IV = 0;
		return;
	}

	// Reading the value resets the interrupt
	int value = ADC14->MEM[idx];
	printf("%d\n", value);
}

void manip_6() {
	adc_setup(ADC14_CTL0_SSEL__SMCLK, ADC14_CTL0_SHS_0, ADC14_CTL1_RES__14BIT); // software trigger
	adc_memory_setup(0, 0, 5); // A0 to memory idx 0
	use_port_adc(5, &P5->SEL0, &P5->SEL1); // P5.5 is A0

	adc_interrupts_enable();
	adc_conversion_enable();
	periodic_interrupt(1000);
}

void main(void) {
	WDT_A->CTL = WDT_A_CTL_PW | WDT_A_CTL_HOLD;		// stop watchdog timer

	setup_dco(DCO_FREQ);
	use_dco_master(M_DIV, SM_DIV);

	manip_6();
	while(1);
}
