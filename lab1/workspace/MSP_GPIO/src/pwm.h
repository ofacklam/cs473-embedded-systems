/*
 * pwm.h
 *
 *  Created on: Oct 16, 2020
 *      Author: ofacklam
 */

#ifndef SRC_PWM_H_
#define SRC_PWM_H_

#include "time.h"
#include "io.h"

// Software PWM (infinite loop, port & timer must be set up)
void pwm_sw(uint8_t volatile *out, int bit, int active, int period, Timer_A_Type* T);

// Timer-waiting-based software PWM
void pwm_wait(uint8_t volatile *out, int bit, int active_ms, int period_ms, Timer_A_Type* T);

// Hardware PWM with timer output linked to specified pin
void pwm_hw(int port, int bit, int width, float duty_cycle, int init);
// Convenience functions for pin 2.4 and 20ms fixed width (timer A0)
void pwm_hw_fixed_init(float duty_cycle);
void pwm_hw_fixed_update(float duty_cycle);

#endif /* SRC_PWM_H_ */
