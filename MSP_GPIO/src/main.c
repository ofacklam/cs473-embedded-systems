/**
 * main.c
 */

// Standard inclusions
#include <stdio.h>
#include "msp.h"

// Custom defined files
#include "time.h"
#include "io.h"
#include "pwm.h"
#include "adc.h"


/**
 * Manipulation 1 -- software PWM
 */
void manip_1() {
	int duty_cycle = 10, max_cycle = 1000;

	// setup port
	P2->DIR = 0xFF;
	P2->OUT = 0x00;

	//Clear & set up timer A0
	TIMER_A0->CTL &= ~(TIMER_A_CTL_MC_MASK | TIMER_A_CTL_ID_MASK
			| TIMER_A_CTL_SSEL_MASK);
	TIMER_A0->CTL |= TIMER_A_CTL_MC__CONTINUOUS | TIMER_A_CTL_SSEL__SMCLK;

	pwm_sw(&P2->OUT, 4, duty_cycle, max_cycle, TIMER_A0); // infinite loop
}

/**
 * Manipulation 2 -- strobe effect
 */
void manip_2() {
	int period = 10000;
	int bits[] = {0, 1, 2};

	// setup port
	P2->DIR = 0xFF;
	P2->OUT = 0x00;

	strobe_effect(&P2->OUT, bits, 3, period);
}

/**
 * Manipulation 3 -- software PWM with timer waiting
 */
void manip_3() {
	P2->DIR = 0xFF;
	P2->OUT = 0x00;

	pwm_wait(&P2->OUT, 4, 50, 150, TIMER_A0);
}

/**
 * Manipulation 4 -- hardware PWM to drive the servo
 */
void manip_4() {
	// vary the angle of servo over time
	int resolution = 100;
	int period = 4000; //ms
	int value = 0;

	pwm_hw_fixed_init(0);

	while(1) {
		float duty = 0.05 + 0.05 * value / resolution;

		pwm_hw_fixed_update(duty);
		timer_wait(period / resolution, TIMER_A1);

		value = (value + 1) % resolution;
	}
}

/**
 * Manipulation 5 -- periodic interrupt to toggle a pin
 */
void toggle_output() {
	P2->OUT ^= BIT(4);
}

void manip_5() {
	P2->DIR = 0xFF;
	P2->OUT = 0x00;
	periodic_interrupt(50, toggle_output);
}

/**
 * Manipulation 6 -- periodic interrupt to trigger ADC conversion to trigger value printing
 */
void trigger_conversion() {
	adc_conversion_enable();
	adc_conversion_start();
}

void print_value(int value) {
	printf("%d\n", value);
}

void manip_6() {
	// ADC inputs
	adc_setup(ADC14_CTL0_SSEL__SMCLK, ADC14_CTL0_SHS_0, ADC14_CTL1_RES__14BIT, ADC14_CTL0_CONSEQ_0); // software trigger, single conversion
	adc_memory_setup(0, 13, 5); // A13 to memory idx 0
	port_to_adc(0, &P4->SEL0, &P4->SEL1); // P4.0 is A13

	// Interrupts for conversion finish
	adc_irq_handler(print_value);
	adc_interrupts_enable();

	// Set up periodic conversion
	adc_conversion_enable();
	periodic_interrupt(1000, trigger_conversion);
}

/**
 * Manipulation 7 -- periodic interrupt to trigger ADC conversion to update PWM duty cycle for servo
 */
void update_pwm(int value) {
	// Calculate new PWM duty cycle (between 0.05 and 0.1)
	float duty = 0.05 + 0.05 * value / (BIT(14) - 1);
	pwm_hw_fixed_update(duty);
}

void manip_7() {
	// ADC inputs
	adc_setup(ADC14_CTL0_SSEL__SMCLK, ADC14_CTL0_SHS_0, ADC14_CTL1_RES__14BIT, ADC14_CTL0_CONSEQ_0); // software trigger, single conversion
	adc_memory_setup(0, 13, 5); // A13 to memory idx 0
	port_to_adc(0, &P4->SEL0, &P4->SEL1); // P4.0 is A13

	// Interrupts for conversion finish
	adc_irq_handler(update_pwm);
	adc_interrupts_enable();

	// Set up initial PWM for servo
	pwm_hw_fixed_init(0.05);

	// Set up periodic conversion
	periodic_interrupt(50, trigger_conversion);
}

void manip_7bis() {
	// ADC inputs
	adc_setup(ADC14_CTL0_SSEL__SMCLK, ADC14_CTL0_SHS_7, ADC14_CTL1_RES__14BIT, ADC14_CTL0_CONSEQ_2); // timer A3 C1 trigger, repeat single channel
	adc_memory_setup(0, 13, 5); // A13 to memory idx 0
	port_to_adc(0, &P4->SEL0, &P4->SEL1); // P4.0 is A13

	// Interrupts for conversion finish
	adc_irq_handler(update_pwm);
	adc_interrupts_enable();

	// Set up initial PWM for servo
	pwm_hw_fixed_init(0.05);

	// Set up periodic conversion with timer A3 C1 triggering the conversion
	adc_conversion_enable();
	timer_pwm_setup(TIMER_A3, 1, 50, 0.5); // don't care about duty cycle
}

void main(void) {
	WDT_A->CTL = WDT_A_CTL_PW | WDT_A_CTL_HOLD;		// stop watchdog timer

	dco_setup(DCO_FREQ);
	dco_to_master(M_DIV, SM_DIV);

	manip_7();
	while(1);
}
