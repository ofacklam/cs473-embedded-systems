#include <stdio.h>
#include <stdbool.h>
#include <unistd.h>

#include "system.h"
#include "io.h"
#include "i2c/i2c.h"
#include "image.h"

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
#define NUM_BUF 	4


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
 * Memory read / write
 *******************************************/

uint16_t get_pixel(uint32_t base, uint32_t row_idx, uint32_t col_idx, uint32_t width) {
	uint32_t addr = HPS_0_BRIDGES_BASE + base + 2 * (row_idx*width + col_idx);
	return IORD_16DIRECT(addr, 0);
}

void set_pixel(uint32_t base, uint32_t row_idx, uint32_t col_idx, uint32_t width, uint16_t val) {
	uint32_t addr = HPS_0_BRIDGES_BASE + base + 2 * (row_idx*width + col_idx);
	return IOWR_16DIRECT(addr, 0, val);
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

void set_memory(uint32_t begin, uint32_t numRows, uint32_t numCols) {
	for(uint32_t i = 0; i < numRows; i++) {
		for(uint32_t j = 0; j < numCols; j++) {
			set_pixel(begin, i, j, numCols, 0xf800);
		}
	}
}

/**
 * From https://rosettacode.org/wiki/Bitmap/Write_a_PPM_file#C
 */
void print_to_file(char idx, uint32_t begin, uint32_t numRows, uint32_t numCols) {
	char* filename = "/mnt/host/imagex.ppm";
	filename[15] = ('0' + idx);
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


/***************************************
 * Programming LCD controller and LCD screen
 ***************************************/

void LCD_WR_REG(uint16_t command) {
    IOWR_32DIRECT(LCD_CONTROLLER_0_BASE, 0x04 *4, command);
    usleep(1);
}

void LCD_WR_DATA(uint16_t data) {
    IOWR_32DIRECT(LCD_CONTROLLER_0_BASE, 0x05 *4, data);
    usleep(1);
}

void enable_lcd_controller_display() {
    IOWR_32DIRECT(LCD_CONTROLLER_0_BASE, 0x00, 1);
    printf("%d ", IORD_32DIRECT(LCD_CONTROLLER_0_BASE, 0x00));
}

void disable_lcd_controller_display() {
    IOWR_32DIRECT(LCD_CONTROLLER_0_BASE, 0x00, 0);
    printf("%d ", IORD_32DIRECT(LCD_CONTROLLER_0_BASE, 0x00));
}

void set_buffer_address(uint32_t n) {
    IOWR_32DIRECT(LCD_CONTROLLER_0_BASE, 0x03 *4, n);
    printf("%d ", IORD_32DIRECT(LCD_CONTROLLER_0_BASE, 0x03));
}

void set_fps(uint32_t n) {
    IOWR_32DIRECT(LCD_CONTROLLER_0_BASE, 0x01 *4, n);
    printf("%d ", IORD_32DIRECT(LCD_CONTROLLER_0_BASE, 0x01));
}


/***************************************
 * Utils function
 ***************************************/

void Delay_Ms(int time_ms) {
    usleep(time_ms * 1000);
    return;
}

void print_starting_image() {
	int colors[] = {0x0000, 0xf800, 0x001f,0x07E0};
	for (int iter = 0; iter < 3; iter++) {
		for(int i = 0; i < img_size; i++) {
			for (int j = 0; j < img[img_size-i-1]; j++) {
				LCD_WR_DATA(colors[iter + i%2]);
			}
		}
	}
}


/***************************************
 * LCD controller init
 ***************************************/

void init_LCD() {
	set_buffer_address(BUF_START);

    Delay_Ms(120); // Delay 120 ms
    LCD_WR_REG(0x0011); //Exit Sleep
    Delay_Ms(300); // "It will be necessary to wait 5msec before sending next command"

    LCD_WR_REG(0x00CF); // Power Control B
        LCD_WR_DATA(0x0000); // Always 0x00
        LCD_WR_DATA(0x0081); //
        LCD_WR_DATA(0X00c0);
    LCD_WR_REG(0x00ED); // Power on sequence control
        LCD_WR_DATA(0x0064); // Soft Start Keep 1 frame
        LCD_WR_DATA(0x0003); //
        LCD_WR_DATA(0X0012);
        LCD_WR_DATA(0X0081);
    LCD_WR_REG(0x00E8); // Driver timing control A
        LCD_WR_DATA(0x0085);
        LCD_WR_DATA(0x0001);
        LCD_WR_DATA(0x0798);
    LCD_WR_REG(0x00CB); // Power control A
        LCD_WR_DATA(0x0039);
        LCD_WR_DATA(0x002C);
        LCD_WR_DATA(0x0000);
        LCD_WR_DATA(0x0034);
        LCD_WR_DATA(0x0002);
    LCD_WR_REG(0x00F7); // Pump ratio control
        LCD_WR_DATA(0x0020);
    LCD_WR_REG(0x00EA); // Driver timing control B
        LCD_WR_DATA(0x0000);
        LCD_WR_DATA(0x0000);
    LCD_WR_REG(0x00B1); // Frame Control (In Normal Mode)
        LCD_WR_DATA(0x0000);
        LCD_WR_DATA(0x001b); // DIVA register
    LCD_WR_REG(0x00B6); // Display Function Control
        LCD_WR_DATA(0x000A);
        LCD_WR_DATA(0x00A2);

    LCD_WR_REG(0x00C0); // Power control 1
        LCD_WR_DATA(0x0005); // VRH[5:0]
    LCD_WR_REG(0x00C1); // Power control 2
        LCD_WR_DATA(0x0011); // SAP[2:0];BT[3:0]
    LCD_WR_REG(0x00C5); //VCM control 1
        LCD_WR_DATA(0x0045); //3F
        LCD_WR_DATA(0x0045); //3C
    LCD_WR_REG(0x00C7); //VCM control 2
        LCD_WR_DATA(0X00a2);
    LCD_WR_REG(0x0036); // Memory Access Control (MADCTL) --> also the printing order on the screen
        LCD_WR_DATA(0x0068);// BGR order
    LCD_WR_REG(0x00F2); // Enable 3G
        LCD_WR_DATA(0x0000); // 3Gamma Function Disable
    LCD_WR_REG(0x0026); // Gamma Set
        LCD_WR_DATA(0x0001); // Gamma curve selected

    LCD_WR_REG(0x00E0); // Positive Gamma Correction, Set Gamma
        LCD_WR_DATA(0x000F);
        LCD_WR_DATA(0x0026);
        LCD_WR_DATA(0x0024);
        LCD_WR_DATA(0x000b);
        LCD_WR_DATA(0x000E);
        LCD_WR_DATA(0x0008);
        LCD_WR_DATA(0x004b);
        LCD_WR_DATA(0X00a8);
        LCD_WR_DATA(0x003b);
        LCD_WR_DATA(0x000a);
        LCD_WR_DATA(0x0014);
        LCD_WR_DATA(0x0006);
        LCD_WR_DATA(0x0010);
        LCD_WR_DATA(0x0009);
        LCD_WR_DATA(0x0000);
    LCD_WR_REG(0X00E1); //Negative Gamma Correction, Set Gamma
        LCD_WR_DATA(0x0000);
        LCD_WR_DATA(0x001c);
        LCD_WR_DATA(0x0020);
        LCD_WR_DATA(0x0004);
        LCD_WR_DATA(0x0010);
        LCD_WR_DATA(0x0008);
        LCD_WR_DATA(0x0034);
        LCD_WR_DATA(0x0047);
        LCD_WR_DATA(0x0044);
        LCD_WR_DATA(0x0005);
        LCD_WR_DATA(0x000b);
        LCD_WR_DATA(0x0009);
        LCD_WR_DATA(0x002f);
        LCD_WR_DATA(0x0036);
        LCD_WR_DATA(0x000f);
    LCD_WR_REG(0x002A); // Column Address Set (0 to 239)
        LCD_WR_DATA(0x0000);
        LCD_WR_DATA(0x0000);
        LCD_WR_DATA(0x0001);
        LCD_WR_DATA(0x003f);
    LCD_WR_REG(0x002B); // Page Address Set (0 to 319)
        LCD_WR_DATA(0x0000);
        LCD_WR_DATA(0x0000);
        LCD_WR_DATA(0x0000);
        LCD_WR_DATA(0x00ef);
    LCD_WR_REG(0x003A); // COLMOD: Pixel Format Set
        LCD_WR_DATA(0x0055);
    LCD_WR_REG(0x00f6); // Interface Control
        LCD_WR_DATA(0x0001); // restart at beginning when an entire frame is sent
        LCD_WR_DATA(0x0030); // EPF & MDT
        LCD_WR_DATA(0x0000); // DM & RIM
    LCD_WR_REG(0x0029); // display on

    // WARNING : set next pixel to beginning of the frame
    LCD_WR_REG(0x002c); // 0x2C --> last command before sending pixels (Memory Write)
}


/*****************************************
 * Main program
 *****************************************/

int main() {

	// initialize the camera
	init_camera_hardware(false, false);
	Delay_Ms(2000);
	init_camera_controller();

	// initialize the lcd controller
	disable_lcd_controller_display();
	set_fps(25);
	init_LCD();

	// display the initial picture
	print_starting_image();

	// start displaying the image of the camera
	enable_lcd_controller_display();

	return 0;
}
