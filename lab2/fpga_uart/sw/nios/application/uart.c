/*
 * uart.c
 *
 *  Created on: Nov 27, 2020
 *      Author: Oliver Facklam
 */

#include "uart.h"

/*********************************************
 * Functions for reading / writing UART registers
 *********************************************/
uint8_t readCtrlA() {
	return IORD_8DIRECT(CUSTOMUART_0_BASE, 0);
}

void writeCtrlA(uint8_t data) {
	IOWR_8DIRECT(CUSTOMUART_0_BASE, 0, data);
}

uint8_t readCtrlB() {
	return IORD_8DIRECT(CUSTOMUART_0_BASE, 1);
}

void writeCtrlB(uint8_t data) {
	IOWR_8DIRECT(CUSTOMUART_0_BASE, 1, data);
}

uint8_t readRXdata() {
	return IORD_8DIRECT(CUSTOMUART_0_BASE, 2);
}

uint8_t readTXdata() {
	return IORD_8DIRECT(CUSTOMUART_0_BASE, 3);
}

void writeTXdata(uint8_t data) {
	IOWR_8DIRECT(CUSTOMUART_0_BASE, 3, data);
}

/*************************************
 * Internal storage & helper functions
 *************************************/

ReceiveHandler receiveData = 0;
Buffer TXbuffer = {.head = 0, .tail = 0}; // https://stackoverflow.com/a/13706854

uint8_t log_(uint8_t in) {
	uint8_t log = 7;
	while(!(in & 0x80)) {
		in = in << 1;
		log--;
	}
	return log;
}

/***************
 * API functions
 ***************/

void setBaudRate(uint32_t clkFreq, uint8_t clkDiv, uint32_t baudRate) {
	uint8_t ticksPerBit = clkFreq / (clkDiv * baudRate);
	uint8_t div = log_(clkDiv);

	uint8_t ctrlA = readCtrlA();
	ctrlA &= ~CTRLA_CLKDIV_MASK;
	ctrlA |= (div << CTRLA_CLKDIV_OFF) & CTRLA_CLKDIV_MASK;
	writeCtrlA(ctrlA);

	writeCtrlB(ticksPerBit);
}

void setParity(bool parityEnable, bool parityOdd) {
	uint8_t parity = (parityEnable << CTRLA_PARITYENABLE_OFF) | (parityOdd << CTRLA_PARITYODD_OFF);

	uint8_t ctrlA = readCtrlA();
	ctrlA &= ~CTRLA_PARITY_MASK;
	ctrlA |= parity & CTRLA_PARITY_MASK;
	writeCtrlA(ctrlA);
}

void run() {
	while(1) {
		// Poll CTRLA flags
		uint8_t ctrla = readCtrlA();

		// if TX ready
		if(ctrla & CTRLA_TXREADY_MASK) {
			if(!isEmpty(&TXbuffer)) {
				uint8_t data = popByte(&TXbuffer);
				writeTXdata(data);
			}
		}

		// if RX available
		if(ctrla & CTRLA_RXAVAILABLE_MASK) {
			uint8_t data = readRXdata();
			if(receiveData)
				receiveData(data);
		}
	}
}

void sendData(uint8_t data) {
	if(!isFull(&TXbuffer)) {
		pushByte(&TXbuffer, data);
	}
}

void registerReceiveHandler(ReceiveHandler handler) {
	receiveData = handler;
}

void print(char *buf) {
	while(*buf) {
		sendData(*buf);
		buf++;
	}
}

