/*
 * io.c
 *
 *  Created on: Oct 15, 2020
 *      Author: ofacklam
 */
#include "io.h"


/**
 * Create a strobe effect by rotating a 1 on the given bits for the given port
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


/**
 * Link module output to port
 */
void module_to_port(uint8_t volatile *dir, uint8_t volatile *sel0, uint8_t volatile *sel1, int bit) {
	// select module
	*sel1 &= ~BIT(bit);
	*sel0 |= BIT(bit);

	*dir |= BIT(bit); // activate output
}


/**
 * Link port to ADC input channel
 */
void port_to_adc(int bit, uint8_t volatile *sel_0, uint8_t volatile *sel_1) {
	// both select bits to 1, to minimize parasitics & enable ADC input
	*sel_0 |= BIT(bit);
	*sel_1 |= BIT(bit);
}
