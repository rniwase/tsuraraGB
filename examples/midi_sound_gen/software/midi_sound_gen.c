#include <gb/gb.h>
#include <stdio.h>
#include <string.h>
#include <gbdk/console.h>
#include "tgb.h"

const char hex[] = "0123456789ABCDEF";

const uint8_t wavpat[16] = {
  0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF,
  0xFE, 0xDC, 0xBA, 0x98, 0x76, 0x54, 0x32, 0x10
};

typedef struct {
  uint16_t frq;
  uint8_t amp;
  uint8_t amp_prv;
  uint8_t act;
} NR;

NR nr[4];
int8_t nr_amp_delta;

void printhex4(uint8_t n) {
  putchar(hex[n & 0x0F]);
}

void printhex8(uint8_t n) {
  printf("%hx", n);
}

void printhex12(uint16_t n) {
  putchar(hex[*((uint8_t *)&n + 1) & 0x0F]);
  printf("%hx", (uint8_t)n);
}

void printhex16(uint16_t n) {
  printf("%x", n);
}

void write_nrx2(uint8_t ch_count) NAKED {
  ch_count;
  __asm
  ld  c, a
  ld  a, #0x2f
  sub  a, c
  ld  b, #0x00
  ld  hl, #jtbl
  add  hl, bc
  add  hl, bc
  ld  c, (hl)
  inc  hl
  ld  h, (hl)
  ld  l, c
  ld  a, #0x08
  jp  (hl)
jtbl:
  .dw  48$
  .dw  47$
  .dw  46$
  .dw  45$
  .dw  44$
  .dw  43$
  .dw  42$
  .dw  41$
  .dw  40$
  .dw  39$
  .dw  38$
  .dw  37$
  .dw  36$
  .dw  35$
  .dw  34$
  .dw  33$
  .dw  32$
  .dw  31$
  .dw  30$
  .dw  29$
  .dw  28$
  .dw  27$
  .dw  26$
  .dw  25$
  .dw  24$
  .dw  23$
  .dw  22$
  .dw  21$
  .dw  20$
  .dw  19$
  .dw  18$
  .dw  17$
  .dw  16$
  .dw  15$
  .dw  14$
  .dw  13$
  .dw  12$
  .dw  11$
  .dw  10$
  .dw  9$
  .dw  8$
  .dw  7$
  .dw  6$
  .dw  5$
  .dw  4$
  .dw  3$
  .dw  2$
  .dw  1$
1$:
  ldh  (_NR42_REG), a
2$:
  ldh  (_NR42_REG), a
3$:
  ldh  (_NR42_REG), a
4$:
  ldh  (_NR42_REG), a
5$:
  ldh  (_NR42_REG), a
6$:
  ldh  (_NR42_REG), a
7$:
  ldh  (_NR42_REG), a
8$:
  ldh  (_NR42_REG), a
9$:
  ldh  (_NR42_REG), a
10$:
  ldh  (_NR42_REG), a
11$:
  ldh  (_NR42_REG), a
12$:
  ldh  (_NR42_REG), a
13$:
  ldh  (_NR42_REG), a
14$:
  ldh  (_NR42_REG), a
15$:
  ldh  (_NR42_REG), a
16$:
  ret
17$:
  ldh  (_NR22_REG), a
18$:
  ldh  (_NR22_REG), a
19$:
  ldh  (_NR22_REG), a
20$:
  ldh  (_NR22_REG), a
21$:
  ldh  (_NR22_REG), a
22$:
  ldh  (_NR22_REG), a
23$:
  ldh  (_NR22_REG), a
24$:
  ldh  (_NR22_REG), a
25$:
  ldh  (_NR22_REG), a
26$:
  ldh  (_NR22_REG), a
27$:
  ldh  (_NR22_REG), a
28$:
  ldh  (_NR22_REG), a
29$:
  ldh  (_NR22_REG), a
30$:
  ldh  (_NR22_REG), a
31$:
  ldh  (_NR22_REG), a
32$:
  ret
33$:
  ldh  (_NR12_REG), a
34$:
  ldh  (_NR12_REG), a
35$:
  ldh  (_NR12_REG), a
36$:
  ldh  (_NR12_REG), a
37$:
  ldh  (_NR12_REG), a
38$:
  ldh  (_NR12_REG), a
39$:
  ldh  (_NR12_REG), a
40$:
  ldh  (_NR12_REG), a
41$:
  ldh  (_NR12_REG), a
42$:
  ldh  (_NR12_REG), a
43$:
  ldh  (_NR12_REG), a
44$:
  ldh  (_NR12_REG), a
45$:
  ldh  (_NR12_REG), a
46$:
  ldh  (_NR12_REG), a
47$:
  ldh  (_NR12_REG), a
48$:
  ret
  __endasm;
}

void update_sound(void) {
  // MIDI CH 0 -> NR1 Square
  nr[0].frq = tgb_nrfreq(((uint16_t)CH0_NOTE_NUM << 9) + ((int16_t)(CH0_PITCHBEND - 8192) >> 3));
  nr[0].amp = tgb_mult16x16(CH0_NOTE_VEL, CH0_CC_VOL) >> 10;
  nr[0].act = (nr[0].amp_prv == 0) & (nr[0].amp != 0);

  if (nr[0].act) {
    NR12_REG = ((0xF & nr[0].amp) << 4) | 0x08;
  } else {
    if (nr[0].amp == 0) {
      NR12_REG = 0x00;
    } else {
      nr_amp_delta = nr[0].amp - nr[0].amp_prv;
      write_nrx2(nr_amp_delta & 0x0F);
    }
  }

  NR13_REG = (uint8_t)nr[0].frq;
  NR14_REG = (nr[0].act << 7) | (*((uint8_t *)(&nr[0].frq) + 1));

  // MIDI CH 1 -> NR2 Square
  nr[1].frq = tgb_nrfreq(((uint16_t)CH1_NOTE_NUM << 9) + ((int16_t)(CH1_PITCHBEND - 8192) >> 3));
  nr[1].amp = tgb_mult16x16(CH1_NOTE_VEL, CH1_CC_VOL) >> 10;
  nr[1].act = (nr[1].amp_prv == 0) & (nr[1].amp != 0);

  if (nr[1].act) {
    NR22_REG = ((0xF & nr[1].amp) << 4) | 0x08;
  } else {
    if (nr[1].amp == 0) {
      NR22_REG = 0x00;
    } else {
      nr_amp_delta = nr[1].amp - nr[1].amp_prv;
      write_nrx2((nr_amp_delta & 0x0F) | 0x10);
    }
  }

  NR23_REG = (uint8_t)nr[1].frq;
  NR24_REG = (nr[1].act << 7) | (*((uint8_t *)(&nr[1].frq) + 1));

  // MIDI CH 2 -> NR3 Wave
  nr[2].frq = tgb_nrfreq(((uint16_t)CH2_NOTE_NUM << 9) + ((int16_t)(CH2_PITCHBEND - 8192) >> 3));
  nr[2].amp = tgb_mult16x16(CH2_NOTE_VEL, CH2_CC_VOL) >> 12;

  NR32_REG = (4 - nr[2].amp) << 5;
  NR33_REG = (uint8_t)nr[2].frq;
  NR34_REG = (*((uint8_t *)(&nr[2].frq) + 1));

  // MIDI CH 3 -> NR4 Noise
  nr[3].frq = tgb_nrfreq(((uint16_t)CH3_NOTE_NUM << 9) + ((int16_t)(CH3_PITCHBEND - 8192) >> 3));  // FIX IT
  nr[3].amp = tgb_mult16x16(CH3_NOTE_VEL, CH3_CC_VOL) >> 10;
  nr[3].act = (nr[3].amp_prv == 0) & (nr[3].amp != 0);

  if (nr[3].act) {
    NR42_REG = ((0xF & nr[3].amp) << 4) | 0x08;
  } else {
    if (nr[3].amp == 0) {
      NR42_REG = 0x00;
    } else {
      nr_amp_delta = nr[3].amp - nr[3].amp_prv;
      write_nrx2((nr_amp_delta & 0x0F) | 0x20);
    }
  }

  NR43_REG = (uint8_t)nr[3].frq;  // FIX IT
  NR44_REG = nr[3].act << 7;

  nr[0].amp_prv = nr[0].amp;
  nr[1].amp_prv = nr[1].amp;
  nr[3].amp_prv = nr[3].amp;
}

void main(void) {
  nr[0].frq = 0;
  nr[1].frq = 0;
  nr[2].frq = 0;
  nr[3].frq = 0;
  nr[0].amp = 0;
  nr[1].amp = 0;
  nr[2].amp = 0;
  nr[3].amp = 0;
  nr[0].amp_prv = 0;
  nr[1].amp_prv = 0;
  nr[2].amp_prv = 0;
  nr[3].amp_prv = 0;
  nr[0].act = 0;
  nr[1].act = 0;
  nr[2].act = 0;
  nr[3].act = 0;

  NR52_REG = 0x80;  // Enable sound
  NR50_REG = 0x77;  // Set master volume
  NR51_REG = 0xFF;  // Set output route

  NR11_REG = 0x80;  // Set duty
  NR21_REG = 0x00;  // Set duty

  NR30_REG = 0x00;  // Disable wave channel

  memcpy(PCM_SAMPLE, wavpat, 16);  // Set wave pattern

  NR30_REG = 0x80;  // Enable wave channel

  NR34_REG = 0x80;  // Trigger wave channel
  NR34_REG = 0x00;

  gotoxy(0, 0);
  printf(  // 20x18
    "MIDI Sound Generator"
    "                    "
    "MIDI CH0 CH1 CH2 CH3"
    "Act   --  --  --  --"
    "Nt#   --  --  --  --"
    "Vel   --  --  --  --"
    "PB  ----------------"
    "CC7   --  --  --  --"
    "                    "
    "NR   Sq1 Sq2 Wav Noi"
    "Frq  --- --- --- ---"
    "Amp    -   -   -   -"
  );

  CRITICAL {
    add_TIM(update_sound);
  }

  TMA_REG = 0x00U;  // Set TMA to divide clock by 0x100
  // TAC_REG = 0x07U;  // Set clock to 16384 Hertz
  TAC_REG = 0x06U;  // Set clock to 65536 Hertz
  set_interrupts(TIM_IFLAG);  // Handle TIM interrupts

  while (1) {
    gotoxy( 6,  3); printf(CH0_NOTE_ACT ? "ON" : "--");
    gotoxy(10,  3); printf(CH1_NOTE_ACT ? "ON" : "--");
    gotoxy(14,  3); printf(CH2_NOTE_ACT ? "ON" : "--");
    gotoxy(18,  3); printf(CH3_NOTE_ACT ? "ON" : "--");

    gotoxy( 6,  4); printhex8(CH0_NOTE_NUM);
    gotoxy(10,  4); printhex8(CH1_NOTE_NUM);
    gotoxy(14,  4); printhex8(CH2_NOTE_NUM);
    gotoxy(18,  4); printhex8(CH3_NOTE_NUM);

    gotoxy( 6,  5); printhex8(CH0_NOTE_VEL);
    gotoxy(10,  5); printhex8(CH1_NOTE_VEL);
    gotoxy(14,  5); printhex8(CH2_NOTE_VEL);
    gotoxy(18,  5); printhex8(CH3_NOTE_VEL);

    gotoxy( 4,  6); printhex16(CH0_PITCHBEND);
    gotoxy( 8,  6); printhex16(CH1_PITCHBEND);
    gotoxy(12,  6); printhex16(CH2_PITCHBEND);
    gotoxy(16,  6); printhex16(CH3_PITCHBEND);

    gotoxy( 6,  7); printhex8(CH0_CC_VOL);
    gotoxy(10,  7); printhex8(CH1_CC_VOL);
    gotoxy(14,  7); printhex8(CH2_CC_VOL);
    gotoxy(18,  7); printhex8(CH3_CC_VOL);

    gotoxy( 5, 10); printhex12(nr[0].frq);
    gotoxy( 9, 10); printhex12(nr[1].frq);
    gotoxy(13, 10); printhex12(nr[2].frq);
    gotoxy(17, 10); printhex12(nr[3].frq);

    gotoxy( 7, 11); printhex4(nr[0].amp);
    gotoxy(11, 11); printhex4(nr[1].amp);
    gotoxy(15, 11); printhex4(nr[2].amp);
    gotoxy(19, 11); printhex4(nr[3].amp);
  }
}
