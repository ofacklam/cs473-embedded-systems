/*
 * Author: Oliver Facklam
 * Main source code for UART calculator
 */

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include "uart.h"

#define CLK_FREQ 50000000
#define MAX_INPUT_SIZE 10

/*****************
 * Welcome message
 *****************/
void testTX() {
	print("Welcome to the Custom UART Calculator\n");
}

/*****************************
 * Reception and parsing logic
 *****************************/
char numberBuffer[MAX_INPUT_SIZE+1];
uint8_t bufIdx = 0;

int num1 = 0, num2 = 0;

int finishNumber() {
	numberBuffer[bufIdx] = '\0';
	bufIdx = 0; // Reset buffer
	return atoi(numberBuffer); // Convert current number
}

void sendResult() {
	char buf[MAX_INPUT_SIZE + 4];
	sprintf(buf, "= %d\n", num1 + num2);
	print(buf);
}

void receiveChar(uint8_t data) {
	data &= 0x7f; // remove highest bit (all ASCII characters are < 128)

	if(data == '+') {
		num1 = finishNumber();
	} else if(data == '\r') {
		num2 = finishNumber();
		sendResult();
	} else {
		numberBuffer[bufIdx] = data;
		if(bufIdx < MAX_INPUT_SIZE - 1)
			bufIdx++;
	}
}

/*********************
 * Communication setup
 *********************/

int main() {
	setBaudRate(CLK_FREQ, 2, BAUDRATE);
	setParity(1, 0);
	registerReceiveHandler(receiveChar);

	testTX();
	run();

	return 0;
}

