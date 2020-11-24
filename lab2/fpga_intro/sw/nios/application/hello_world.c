/*
 * "Hello World" example.
 *
 * This example prints 'Hello from Nios II' to the STDOUT stream. It runs on
 * the Nios II 'standard', 'full_featured', 'fast', and 'low_cost' example
 * designs. It runs with or without the MicroC/OS-II RTOS and requires a STDOUT
 * device in your system's hardware.
 * The memory footprint of this hosted application is ~69 kbytes by default
 * using the standard reference design.
 *
 * For a reduced footprint version of this template, and an explanation of how
 * to reduce the memory footprint for a given application, see the
 * "small_hello_world" template.
 *
 */

#include <stdio.h>
#include <inttypes.h>
#include "system.h"
#include "altera_avalon_pio_regs.h"

#define PROC_FREQ 100000 // 50 MHz (not really accurate)

int main() {
	printf("Hello from Nios II!\n");

	// No need to configure direction, hardware is already in OUTPUT mode

	uint8_t NUM_LEDS = 8;
	ulong FREQ = 1; // in Hz
	uint8_t bit = 0;
	while (1) {
		// Set next LED to ON
		bit = (bit+1) % NUM_LEDS;
		uint8_t data = 1 << bit;
		IOWR_ALTERA_AVALON_PIO_DATA(PIO_0_BASE, data);

		// Wait some cycles
		for(ulong i = 0; i < PROC_FREQ / FREQ; i++);
	}

	return 0;
}
