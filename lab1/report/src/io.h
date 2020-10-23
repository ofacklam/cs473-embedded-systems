/*
 * io.h
 *
 *  Created on: Oct 15, 2020
 *      Author: ofacklam
 */

#ifndef SRC_IO_H_
#define SRC_IO_H_

#include "msp.h"

void strobe_effect(uint8_t volatile *out, int* bits, int num, int period);

void module_to_port(uint8_t volatile *dir, uint8_t volatile *sel0, uint8_t volatile *sel1, int bit);
void port_to_adc(int bit, uint8_t volatile *sel_0, uint8_t volatile *sel_1);

#endif /* SRC_IO_H_ */
