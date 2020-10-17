/*
 * pwm.c
 *
 *  Created on: Oct 16, 2020
 *      Author: ofacklam
 */
#include "pwm.h"

/**
 * Creates a single period of duty cycling on the given port/bit (must be initialized to output mode)
 * Returns the timing measurements of the duty cycle
 */
Timing pwm_sw_period(uint8_t volatile *out, int bit, int active, int period, Timer_A_Type* T) {
	int i, time_start, time_end_on, time_end_off;

	// ON duty cycle
	time_start = T->R;
	*out |= BIT(bit);
	for (i = 0; i < active; i++);

	// OFF duty cycle
	time_end_on = T->R;
	*out &= ~BIT(bit);
	for (i = 0; i < period - active; i++);

	time_end_off = T->R;

	Timing t;
	t.active = time_end_on - time_start;
	t.period = time_end_off - time_start;
	return t;
}

/**
 * Creates an infinite loop software duty cycle
 * PORT and TIMER must be set up
 */
void pwm_sw(uint8_t volatile *out, int bit, int active, int period, Timer_A_Type* T) {
	while (1) {
		int i, total_active = 0, total_period = 0, num_periods = 1000;

		for (i = 0; i < num_periods; i++) {
			Timing t = pwm_sw_period(out, bit, active, period, T);
			total_active += t.active;
			total_period += t.period;
		}

		printf("On for %d cycles, out of total period of %d cycles :)\n",
				total_active / num_periods, total_period / num_periods);
	}
}


/**
 * Creates an infinite loop for waiting-based software duty cycle
 * PORT must be set up
 */
void pwm_wait(uint8_t volatile *out, int bit, int active_ms, int period_ms, Timer_A_Type* T) {
	while (1) {
		// ON duty cycle
		*out |= BIT(bit);
		timer_wait(active_ms, T);

		// OFF duty cycle
		*out &= ~BIT(bit);
		timer_wait(period_ms - active_ms, T);
	}
}


/**
 * Set up hardware PWM on a specific port / bit
 * Port can be 2 or 7, bits in range [4..7]
 */
void pwm_hw(int port, int bit, int width, float duty_cycle, int init) {
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
		timer_pwm_setup(timer, timer_ccr_idx, width, duty_cycle);
		module_to_port(dir, sel0, sel1, bit);
	} else {
		timer_pwm_duty(timer, timer_ccr_idx, duty_cycle);
	}
}


/**
 * Convenience functions for port 2.4, width 20ms
 */
void pwm_hw_fixed_init(float duty_cycle) {
	return pwm_hw(2, 4, 20, duty_cycle, 1);
}


void pwm_hw_fixed_update(float duty_cycle) {
	return pwm_hw(2, 4, 20, duty_cycle, 0);
}

