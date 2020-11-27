/*
 * buffer.h
 *
 *  Created on: Nov 27, 2020
 *      Author: Oliver Facklam
 */

#ifndef BUFFER_H_
#define BUFFER_H_

#include <stdint.h>
#include <stdbool.h>

#define BUFFER_SIZE 0x8000

typedef struct {
	uint8_t buffer[BUFFER_SIZE];
	uint32_t head; // next to pop
	uint32_t tail; // next to push
} Buffer;

void pushByte(Buffer *buf, uint8_t data);
uint8_t popByte(Buffer *buf);

uint32_t size(Buffer *buf);
bool isEmpty(Buffer *buf);
bool isFull(Buffer *buf);

#endif /* BUFFER_H_ */
