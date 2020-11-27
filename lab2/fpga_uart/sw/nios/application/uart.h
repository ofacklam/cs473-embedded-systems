/*
 * uart.h
 *
 *  Created on: Nov 27, 2020
 *      Author: Oliver Facklam
 */

#ifndef UART_H_
#define UART_H_

#include <stdint.h>
#include <stdbool.h>
#include "system.h"
#include "io.h"
#include "buffer.h"

/*************************************
 * Constants for register manipulation
 *************************************/
#define CTRLA_RXAVAILABLE_MASK 	0x01
#define CTRLA_TXREADY_MASK 		0x02

#define CTRLA_PARITY_MASK 		0x0c
#define CTRLA_PARITYENABLE_OFF	2
#define CTRLA_PARITYODD_OFF 	3

#define CTRLA_CLKDIV_MASK		0x70
#define CTRLA_CLKDIV_OFF		4

/**************************************
 * UART API
 **************************************/
#define BAUDRATE 500000

typedef void (*ReceiveHandler)(uint8_t data);

void setBaudRate(uint32_t clkFreq, uint8_t clkDiv, uint32_t baudRate);
void setParity(bool parityEnable, bool parityOdd);

void run();

void sendData(uint8_t data);
void registerReceiveHandler(ReceiveHandler handler);

void print(char *buf);

#endif /* UART_H_ */

