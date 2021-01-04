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
#include <unistd.h>

#include "system.h"
#include "io.h"
#include "cmos_sensor_output_generator/cmos_sensor_output_generator.h"

#define FRAME_FRAME 640
#define FRAME_LINE 20
#define LINE_FRAME 20
#define LINE_LINE 20

/**
 * From CMOS sensor demo
 */
void init_cmos_generator() {
	cmos_sensor_output_generator_dev cmos_sensor_output_generator
		  = CMOS_SENSOR_OUTPUT_GENERATOR_INST(CMOS_SENSOR_OUTPUT_GENERATOR_0);

	cmos_sensor_output_generator_init(&cmos_sensor_output_generator);
	cmos_sensor_output_generator_stop(&cmos_sensor_output_generator);

	cmos_sensor_output_generator_configure(&cmos_sensor_output_generator,
											 640,
											 480,
											 FRAME_FRAME,
											 FRAME_LINE,
											 LINE_LINE,
											 LINE_FRAME);

	cmos_sensor_output_generator_start(&cmos_sensor_output_generator);
}

/**
 * From memory access demo
 */
void print_memory(uint32_t begin, uint32_t numRows, uint32_t numCols) {
	for(uint32_t i = 0; i < numRows; i++) {
		for(uint32_t j = 0; j < numCols; j++) {
			uint32_t addr = HPS_0_BRIDGES_BASE + begin + 2 * (i*numCols + j);
			uint16_t pixelVal = IORD_16DIRECT(addr, 0);
			printf("%x ", pixelVal);
		}
		printf("\n");
	}
}

void init_camera_controller() {
	IOWR_32DIRECT(CAMERACONTROLLER_0_BASE, 0, 0x00); // base address 0x00
	IOWR_32DIRECT(CAMERACONTROLLER_0_BASE, 4, 0x20025800); // number of buffers 1, buffer length 0x25800
}

int main() {
	printf("Hello from Nios II!\n");

	init_cmos_generator();
	init_camera_controller();
	usleep(2000000);
	print_memory(0, 240, 320);

	return 0;
}
