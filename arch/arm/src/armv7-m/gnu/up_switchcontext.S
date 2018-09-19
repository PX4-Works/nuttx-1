/************************************************************************************
 * arch/arm/src/armv7-m/gnu/up_switchcontext.S
 *
 *   Copyright (C) 2009-2011, 2016 Gregory Nutt. All rights reserved.
 *   Author: Gregory Nutt <gnutt@nuttx.org>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 * 3. Neither the name NuttX nor the names of its contributors may be
 *    used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 ************************************************************************************/

/************************************************************************************
 * Included Files
 ************************************************************************************/

#include <nuttx/config.h>
#include <arch/irq.h>

#include "nvic.h"
#include "svcall.h"

/************************************************************************************
 * Pre-processor Definitions
 ************************************************************************************/

/************************************************************************************
 * Public Symbols
 ************************************************************************************/
	.bss
	.global	g_mav_task_stack
	.align	4
g_check_on_exit:
	.space  4
g_mav_task_stack:
	.space	1600
g_end_mav_task_stack:
	.text
	.syntax	unified
	.thumb
	.file	"up_switchcontext.S"

/************************************************************************************
 * Macros
 ************************************************************************************/

/************************************************************************************
 * Public Functions
 ************************************************************************************/

/************************************************************************************
 * Name: up_switchcontext
 *
 * Description:
 *   Save the current thread context and restore the specified context.
 *   Full prototype is:
 *
 *   void up_switchcontext(uint32_t *saveregs, uint32_t *restoreregs);
 *
 * Return:
 *   None
 *
 ************************************************************************************/


	.thumb_func
	.globl	up_switchcontext
	.type	up_switchcontext, function

up_switchcontext:

	/* Perform the System call with R0=1, R1=saveregs, R2=restoreregs */
	ldr     r2, =g_mavlink_task
	ldr     r2,[r2]
	add		r2, #120
	cmp     r0,r2 /*  is this the SAVE of the task ?*/
	bne     4f

	mov     r2,sp
	push    {r0-r3}
	mov 	r0,#400
	ldr     r1, =g_mav_task_stack

1:
	ldr		r3,[r2], #4
	str     r3,[r1], #4
	sub		r0, #1
	cmp		r0, #0
	bne		1b

	ldr     r2, =g_check_on_exit
	str     r0,[r2]
	pop     {r0-r3}
	b       4f
4:
	mov		r2, r1					/* R2: restoreregs */
	mov		r1, r0					/* R1: saveregs */
	mov		r0, #SYS_switch_context	/* R0: context switch */
	svc		0						/* Force synchronous SVCall (or Hard Fault) */

	push    {r1}
	mov     r1,r0
	pop     {r1}

	bx		lr
	.size	up_switchcontext, .-up_switchcontext
	.end

