/*
 * adc.h
 *
 *  Created on: Oct 16, 2020
 *      Author: ofacklam
 */

#ifndef SRC_ADC_H_
#define SRC_ADC_H_

#include "msp.h"
#include "time.h"

typedef void(*AdcHandler)(int);

void adc_setup(uint32_t clk_src, uint32_t trigger, uint32_t resolution_mode, uint32_t conversion_mode);
void adc_memory_setup(int idx, int channel, int sample_time_us);

void adc_interrupts_enable();
void adc_irq_handler(AdcHandler fun);

void adc_conversion_enable();
void adc_conversion_disable();
void adc_conversion_start();

#endif /* SRC_ADC_H_ */
