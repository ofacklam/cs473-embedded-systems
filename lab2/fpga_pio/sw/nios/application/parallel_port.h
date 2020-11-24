/*
 * parallel_port.h
 *
 *  Created on: Nov 24, 2020
 *      Author: vm
 */

#ifndef PARALLEL_PORT_H_
#define PARALLEL_PORT_H_

#include "io.h"

#define IORD_PARALLELPORT_DIRECTION(base) 			IORD_8DIRECT(base, 0)
#define IOWR_PARALLELPORT_DIRECTION(base, value) 	IOWR_8DIRECT(base, 0, value)

#define IORD_PARALLELPORT_PIN(base) 				IORD_8DIRECT(base, 1)

#define IORD_PARALLELPORT_PORT(base) 				IORD_8DIRECT(base, 2)
#define IOWR_PARALLELPORT_PORT(base, value) 		IOWR_8DIRECT(base, 2, value)

#define IOWR_PARALLELPORT_SET(base, value) 			IOWR_8DIRECT(base, 3, value)

#define IOWR_PARALLELPORT_CLR(base, value) 			IOWR_8DIRECT(base, 4, value)

#endif /* PARALLEL_PORT_H_ */
