/*

Sleety - 232 bytes intro by Frog
Released at Chaos Constructions'2021 Winter demo party
Written for STM32L100RCT6 ARM Cortex M3 chip (tested with STM32L100C-DISCO board) + any CRT oscilloscope with XY inputs.

If it won't run try switch off/on power (reset isn't enough)

http://enlight.ru/roi

*/

.syntax unified
.thumb
.cpu cortex-m3


// some of constants are for reference only
.equ	PERIPH_BASE         ,	0x40000000                  // Peripheral base address in the alias region
.equ	_AHB                ,	(PERIPH_BASE + 0x20000)     // Advanced High-speed Bus base   0x40000000 + 0x20000
.equ	_GPIO               ,	(_AHB + 0x0000)             // GPIO block base       0x40000000 + 0x20000 + 0x0000
.equ	_RCC                ,   (_AHB + 0x3800)             // Reset and Clock Config base

.equ	RCC_APB1ENR_DACEN   ,   0x20000000                  // DAC interface clock enable
.equ	RCC_APB1ENR         ,   (_RCC + 0x24)               // RCC APB1 peripheral clock enable register,
.equ	_APB1               ,   PERIPH_BASE                 // Advanced Peripheral Bus 1 base

.equ	_DAC                ,   (_APB1 + 0x7400)            // D/A config base
.equ	DAC_CR              ,   (_DAC + 0x00)               // DAC control register,
.equ	DAC_CR_EN1          ,   0x00000001                  // DAC channel1 enable
.equ	DAC_CR_EN2          ,   0x00010000                  // DAC channel2 enable
.equ	DAC_DHR12R1         ,  (_DAC + 0x08)                // DAC channel1 12-bit right-aligned data holding register,
.equ	DAC_DHR12R2         ,  (_DAC + 0x14)                // DAC channel2 12-bit right aligned data holding register,

.equ	_GPIOA              ,   (_GPIO + 0x0000)            // 0x40000000 + 0x20000 + 0x0000 + 0x0000 = 0x40020000

.equ	GPIOA_OSPEEDR       ,	(_GPIOA + 0x08)             // GPIOA output speed register,
.equ    GPIOA_MODER         ,	(_GPIOA + 0x00)             // GPIOA pin mode register,      0x40020000 + 0x00 = 0x40020000 (1073872896)
.equ	GPIO_MODER_MODER5_1 ,   0x00000800
.equ	GPIO_PUPDR_5        ,   (0x00000C00)

.equ	GPIOA_PUPDR         ,	(_GPIOA + 0x0C)             // GPIOA pull-up/pull-down register    0x40000000 + 0x20000 + 0x0000 + 0x0000 + 0x0C = 0x4002000c

.equ	GPIO_OSPEEDER_OSPEEDR5, 0x00000C00

    .section .ram

r_seed:	
	.word  // SRAM, 32 bit var (init value doesn't mind)


    .section .text


    .word       0x20005000	// stack address
    .word	    reset+1		// where to go after reset address


// table of 32 bit values to load into CPU registers
const:
    .word       0x40020000  // const        GPIOA_MODER, _GPIOA
    .word       0x40023800  // const+4      _RCC
    .word       0x40007400  // const+8      _DAC
	.word 	    r_seed      // const+12     ref to address in SRAM
    .word       0xaaaaaaab  // const+16
    .word       0x45e7b273  // const+20

reset:

//    PA5 pin push-pull
//    GPIOA->MODER |= GPIO_MODER_MODER5_1;
    ldr     r3, const   // GPIOA_MODER  (_GPIOA) 0x40020000
    ldr     r2, [r3]
    orr     r2, r2, #0x800
    str     r2, [r3]

//    GPIOA->OSPEEDR |= GPIO_OSPEEDER_OSPEEDR5;
    ldr     r2, [r3, #8] //GPIOA->OSPEEDR  ( GPIOA_MODER + 0x08 = 0x40020008 )
    orr     r2, r2, #0xc00
    str     r2, [r3, #8]

//    GPIOA->PUPDR &= ~GPIO_PUPDR_PUPDR5;
    ldr     r2, [r3, #0xc] // 0x4002000c
    bic     r2, r2, #0xc00
    str     r2, [r3, #0xc]

//    enable DAC clock
//    RCC->APB1ENR |= RCC_APB1ENR_DACEN;
    ldr     r2, const+4
    ldr     r3, [r2, 0x24]
    orr     r3, r3, #0x20000000
    str     r3, [r2, 0x24]

//    enable DAC1 (PA4 pin)
//    DAC->CR |= DAC_CR_EN1;  
    ldr     r3, const+8
    ldr     r2, [r3]
    orr     r2, r2, #1
    str     r2, [r3]

//    enable DAC2 (PA5 pin)
//    DAC->CR |= DAC_CR_EN2;  

    ldr     r2, [r3]
    orr     r2, r2, #0x10000
    str     r2, [r3]


// ----- start of loops -------

    movs    r5, #0
    mov     r4, r5          // d = 0;
    b       L7

L9:

    ldr     r2, const+12    // load r_seed from SRAM
    ldr     r3, [r2]
    adds	r3, r3, #1      // r_seed++
    str     r3, [r2]        // save r_seed to SRAM

L7:

    movs	r6, #0          // i = 0

L5:

    movw	r3, #4094
    cmp	    r6, r3          // then i=4095 goto L9
    bhi	    L9

//       DAC->DHR12R2 = random() % c - i; 

    bl	  random            // returns r_seed to r0

    udiv	r3, r0, r4
    mls	    r3, r4, r3, r0
    lsrs	r0, r6, #1
    mla	    r0, r4, r0, r3
    ldr	    r7, const+16    // 0xaaaaaaab -> r7
    umull	r2, r3, r7, r5
    add	    r0, r0, r3, lsr #2
    ldr	    r8, const+8     // DAC_DHR12R1  0x40007400 -> r8
    str	    r0, [r8, #8]    // set horizontal voltage via DAC_DHR12R1
    
    bl	    random          // returns r_seed to r0

    udiv	r3, r0, r4
    mls	    r3, r4, r3, r0
    subs	r3, r3, r6      // -i
    str	    r3, [r8, 0x14]  // set vertical voltage via DAC_DHR12R1. 0x40007400 + 0x14 = 0x40020014 

//       c %= 3; 

    adds	r3, r4, #1
    umull	r2, r4, r7, r3
    lsrs	r4, r4, #1
    add	    r4, r4, r4, lsl #1
    subs	r4, r3, r4

//       d %= 15000; 

    adds	r3, r5, #1
    ldr	    r5, const+20    // 0x45e7b273 -> r5
    umull	r2, r5, r5, r3  // unsigned (r5,r2) = r5 * r3
    lsrs	r5, r5, 0xc
    movw	r2, #15000
    mls	    r5, r2, r5, r3  // r5 = r3 - (r2 * r5).
    adds	r6, r6, #1
    b	    L5

// -------- returns pseudo random value using r_seed --------

random:  // not him, just a subroutine :)

    ldr	  r3, =r_seed	// get from SRAM: 0x20000000 -> r0
    ldr	  r0, [r3]

//  r_seed ^= (r_seed << 4 ); 
    eor	  r0, r0, r0, lsl #4

//   r_seed ^= (r_seed >> 1); 
    eor	  r0, r0, r0, lsr #1

    str	  r0, [r3]	// write back to SRAM intro r_seed (and also returns in r0)

    bx	  lr


