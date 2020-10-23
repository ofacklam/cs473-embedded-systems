/*
 * adc.c
 *
 *  Created on: Oct 16, 2020
 *      Author: ofacklam
 */
#include "adc.h"


/**
 * Set up ADC inputs (pulse mode)
 */
void adc_setup(uint32_t clk_src, uint32_t trigger, uint32_t resolution_mode, uint32_t conversion_mode) {
	// Turn ADC on, clear conversion
	ADC14->CTL0 |= ADC14_CTL0_ON;
	adc_conversion_disable();

	// Select pulse mode
	ADC14->CTL0 |= ADC14_CTL0_SHP;

	// Conversion mode
	ADC14->CTL0 &= ~ADC14_CTL0_CONSEQ_MASK;
	ADC14->CTL0 |= (conversion_mode & ADC14_CTL0_CONSEQ_MASK);

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


/**
 * Calculate sample timer mode corresponding to given `sample_time` (in us)
 */
int calculate_adc_timer_mode(int sample_time) {
	int modes[] = {4, 8, 16, 32, 64, 96, 128, 192};

	int min_cycles = 1 + sample_time * DCO_FREQ / (1000*SM_DIV); // sample_time in us, freq in khz
	int mode = 8;

	while(mode > 0 && min_cycles <= modes[mode-1])
		mode--;

	return mode;
}


/**
 * Set up ADC memory control, link to input channel, enable interrupts for this memory
 */
void adc_memory_setup(int idx, int channel, int sample_time_us) {
	// Single-ended mode, with ref (Vcc, Vss)
	ADC14->MCTL[idx] &= ~ADC14_MCTLN_DIF;
	ADC14->MCTL[idx] &= ~ADC14_MCTLN_VRSEL_MASK;

	// Select timer mode
	int mode = calculate_adc_timer_mode(sample_time_us);
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


/**
 * Enable ADC->processor interrupts
 */
void adc_interrupts_enable() {
	NVIC_EnableIRQ(ADC14_IRQn);
	NVIC_SetPriority(ADC14_IRQn, 4);
}


/**
 * Global variable to store ADC callback function pointer
 */
AdcHandler adc_handler = NULL;


/**
 * ADC interrupt handler
 */
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

	// Call handler with value
	if(adc_handler)
		adc_handler(value);
}


/**
 * Set a new ADC callback
 */
void adc_irq_handler(AdcHandler fun) {
	adc_handler = fun;
}


/*
 * Functions for managing conversion process
 */
void adc_conversion_enable() {
	ADC14->CTL0 |= ADC14_CTL0_ENC;
}

void adc_conversion_disable() {
	ADC14->CTL0 &= ~ADC14_CTL0_ENC;
}

void adc_conversion_start() {
	ADC14->CTL0 |= ADC14_CTL0_SC;
}

