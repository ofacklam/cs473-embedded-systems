/*
 * buffer.c
 *
 *  Created on: Nov 27, 2020
 *      Author: Oliver Facklam
 */

#include "buffer.h"

uint32_t size(Buffer *buf) {
	uint32_t h = buf->head;
	uint32_t t = buf->tail;
	if(t < h) {
		t += BUFFER_SIZE;
	}
	return t - h;
}

bool isEmpty(Buffer *buf) {
	return size(buf) == 0;
}
bool isFull(Buffer *buf) {
	return size(buf) == BUFFER_SIZE - 1;
}

void pushByte(Buffer *buf, uint8_t data) {
	if(isFull(buf))
		return;

	buf->buffer[buf->tail] = data;
	buf->tail = (buf->tail + 1) % BUFFER_SIZE;
}

uint8_t popByte(Buffer *buf) {
	if(isEmpty(buf))
		return 0;

	uint8_t data = buf->buffer[buf->head];
	buf->head = (buf->head + 1) % BUFFER_SIZE;
	return data;
}

