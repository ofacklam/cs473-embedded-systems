/*
 * time.h
 *
 *  Created on: Oct 15, 2020
 *      Author: ofacklam
 */

#ifndef SRC_TIME_H_
#define SRC_TIME_H_

#include "msp.h"
#include <stdio.h>

#define DCO_FREQ 3000
#define M_DIV 1
#define SM_DIV 4

// A way to communicate software timing measurements
typedef struct {
	uint16_t active;
	uint16_t period;
} Timing;

// Type of timer callback functions
typedef void(*TimerHandler)(void);

// Clock system setup
void dco_setup(int khz);
void dco_to_master(int m_clk_div, int s_clk_div);

// Timer-based idle waiting
int timer_wait(int ms, Timer_A_Type* T);
int wait(int ms); // Convenience function with timer A0

// Timer output management
void timer_pwm_setup(Timer_A_Type* T, int idx, int width, float duty_cycle);
void timer_pwm_duty(Timer_A_Type* T, int idx, float duty_cycle);

// Interrupts on timer A3
void timer_irq_handler(TimerHandler fun);
void periodic_interrupt(int period, TimerHandler fun);

#endif /* SRC_TIME_H_ */
