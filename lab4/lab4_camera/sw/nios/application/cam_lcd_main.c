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
#include <stdbool.h>
#include <unistd.h>

#include "system.h"
#include "io.h"
//#include "cmos_sensor_output_generator/cmos_sensor_output_generator.h"
#include "i2c/i2c.h"

#define FRAME_FRAME 640
#define FRAME_LINE 20
#define LINE_FRAME 20
#define LINE_LINE 20

#define I2C_FREQ              (50000000) /* Clock frequency driving the i2c core: 50 MHz */
#define TRDB_D5M_I2C_ADDRESS  (0xba)

#define CAMCTRL_REG1_BUFNUM_OFFS 29
#define CAMCTRL_REG1_BUFSIZ_MASK 0x1fffffff

#define WIDTH 		320
#define HEIGHT 		240

#define BUF_START 	0x00
#define BUF_SIZE 	WIDTH * HEIGHT * 2
#define NUM_BUF 	1

/******************************************************
 * CMOS sensor
 ******************************************************/
/**
 * From CMOS sensor demo
 */
/*void init_cmos_generator() {
	cmos_sensor_output_generator_dev cmos_sensor_output_generator
		  = CMOS_SENSOR_OUTPUT_GENERATOR_INST(CMOS_SENSOR_OUTPUT_GENERATOR_0);

	cmos_sensor_output_generator_init(&cmos_sensor_output_generator);
	cmos_sensor_output_generator_stop(&cmos_sensor_output_generator);

	cmos_sensor_output_generator_configure(&cmos_sensor_output_generator,
											 2*WIDTH,
											 2*HEIGHT,
											 FRAME_FRAME,
											 FRAME_LINE,
											 LINE_LINE,
											 LINE_FRAME);

	cmos_sensor_output_generator_start(&cmos_sensor_output_generator);
}*/

/************************************************
 * Camera setup TRDB-D5M
 ************************************************/

/**
 * From I2C demo
 */
bool trdb_d5m_write(i2c_dev *i2c, uint8_t register_offset, uint16_t data) {
    uint8_t byte_data[2] = {(data >> 8) & 0xff, data & 0xff};

    int success = i2c_write_array(i2c, TRDB_D5M_I2C_ADDRESS, register_offset, byte_data, sizeof(byte_data));

    if (success != I2C_SUCCESS) {
        return false;
    } else {
        return true;
    }
}

bool trdb_d5m_read(i2c_dev *i2c, uint8_t register_offset, uint16_t *data) {
    uint8_t byte_data[2] = {0, 0};

    int success = i2c_read_array(i2c, TRDB_D5M_I2C_ADDRESS, register_offset, byte_data, sizeof(byte_data));

    if (success != I2C_SUCCESS) {
        return false;
    } else {
        *data = ((uint16_t) byte_data[0] << 8) + byte_data[1];
        return true;
    }
}

void init_camera_hardware(bool disableBLC, bool testPattern) {
	i2c_dev i2c = I2C_INST(I2C_0);
	i2c_init(&i2c, I2C_FREQ);

	// set image height (REG 3 row size)
	trdb_d5m_write(&i2c, 3, 8*HEIGHT-1);
	// set image width (REG 4 col size)
	trdb_d5m_write(&i2c, 4, 8*WIDTH-1);

	// set row binning (REG 34 row mode)
	trdb_d5m_write(&i2c, 34, 0x0033); // row skip 4x, row bin 4x
	// set row binning (REG 35 col mode)
	trdb_d5m_write(&i2c, 35, 0x0033); // col skip 4x, col bin 4x

	// (optional) disable black level calibration
	if(disableBLC) {
		trdb_d5m_write(&i2c, 32, 0x0000); // disable row-BLC
		trdb_d5m_write(&i2c, 75, 0x0000); // digital offset 0
		trdb_d5m_write(&i2c, 98, 0x0003); // disable BLC
		trdb_d5m_write(&i2c, 96, 0x0000); // analog offset 0
		trdb_d5m_write(&i2c, 97, 0x0000); // analog offset 0
		trdb_d5m_write(&i2c, 99, 0x0000); // analog offset 0
		trdb_d5m_write(&i2c, 100, 0x0000); // analog offset 0
	}

	// (optional) set test pattern mode
	if(testPattern) {
		trdb_d5m_write(&i2c, 161, 0x0aaa);
		trdb_d5m_write(&i2c, 162, 0x0aaa);
		trdb_d5m_write(&i2c, 163, 0x0aaa);
		trdb_d5m_write(&i2c, 164, 0x00a1);
		trdb_d5m_write(&i2c, 160, 0x0041); // color field
	}

}

/*******************************************
 * Memory readout
 *******************************************/

uint16_t get_pixel(uint32_t base, uint32_t row_idx, uint32_t col_idx, uint32_t width) {
	uint32_t addr = HPS_0_BRIDGES_BASE + base + 2 * (row_idx*width + col_idx);
	return IORD_16DIRECT(addr, 0);
}

/**
 * From memory access demo
 */
void print_memory(uint32_t begin, uint32_t numRows, uint32_t numCols) {
	for(uint32_t i = 0; i < numRows; i++) {
		for(uint32_t j = 0; j < numCols; j++) {
			uint16_t pixelVal = get_pixel(begin, i, j, numCols);
			printf("%x ", pixelVal);
		}
		printf("\n");
	}
}

/**
 * From https://rosettacode.org/wiki/Bitmap/Write_a_PPM_file#C
 */
void print_to_file(uint32_t begin, uint32_t numRows, uint32_t numCols) {
	char* filename = "/mnt/host/image.ppm";
	FILE *fp = fopen(filename, "wb");

	// Header
	(void) fprintf(fp, "P6\n%d %d\n255\n", numCols, numRows);

	// Body
	for(uint32_t row = 0; row < numRows; row++) {
		for(uint32_t col = 0; col < numCols; col++) {
			uint16_t pixelVal = get_pixel(begin, row, col, numCols);

			uint8_t colors[3];
			colors[0] = (pixelVal >> 8) & 0xf8;
			colors[1] = (pixelVal >> 3) & 0xfc;
			colors[2] = (pixelVal << 3) & 0xf8;

			(void) fwrite(colors, sizeof(uint8_t), 3, fp);
		}
	}

	(void) fclose(fp);
	printf("Done!\n");
}

/***************************************
 * Camera controller init
 ***************************************/

void init_camera_controller() {
	// REG0 = base address of buf0
	IOWR_32DIRECT(CAMERACONTROLLER_0_BASE, 0, BUF_START);

	// REG1 = number of buffers (3 bits) + size of buffers (29 bits)
	uint32_t reg1 = (NUM_BUF << CAMCTRL_REG1_BUFNUM_OFFS) | (BUF_SIZE & CAMCTRL_REG1_BUFSIZ_MASK);
	IOWR_32DIRECT(CAMERACONTROLLER_0_BASE, 4, reg1);
}


/*****************************************
 * Main program
 *****************************************/

int main() {
	printf("Hello from Nios II!\n");

	init_camera_hardware(true, true);
	usleep(1000000);

	init_camera_controller();
	usleep(2000000);

	print_to_file(BUF_START, HEIGHT, WIDTH);

	return 0;
}
