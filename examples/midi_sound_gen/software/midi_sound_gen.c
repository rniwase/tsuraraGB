#include <gb/gb.h>
#include <stdio.h>
#include <string.h>
#include <gbdk/console.h>

#define NOTE_ACT    0xB000U
#define NOTE_NUM    0xB001U
#define NOTE_VEL    0xB002U

const uint16_t freqs[] = {
  // C    C#     D    D#     E     F    F#     G    G#     A    A#     B   // Oct
    44,  156,  262,  363,  457,  547,  631,  710,  786,  854,  923,  986,  // 0
  1046, 1102, 1155, 1205, 1253, 1297, 1339, 1379, 1417, 1452, 1486, 1517,  // 1
  1546, 1575, 1602, 1627, 1650, 1673, 1694, 1714, 1732, 1750, 1767, 1783,  // 2
  1798, 1812, 1825, 1837, 1849, 1860, 1871, 1881, 1890, 1899, 1907, 1915,  // 3
  1923, 1930, 1936, 1943, 1949, 1954, 1959, 1964, 1969, 1974, 1978, 1982,  // 4
  1985, 1988, 1992, 1995, 1998, 2001, 2004, 2006, 2009, 2011, 2013, 2015,  // 5
  2017
};

const char hex[] = "0123456789ABCDEF";

const uint8_t wavpat[16] = {
  0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF,
  0xFE, 0xDC, 0xBA, 0x98, 0x76, 0x54, 0x32, 0x10
  // 0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77,
  // 0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF
};

typedef struct {
  uint8_t note_act;
  uint8_t note_num;
  uint8_t note_vel;
} MIDI;

MIDI midi[3];

uint16_t freq[3];
uint8_t amp[3];
uint8_t amp_prev[3];

void get_midi(MIDI* m, uint8_t ch) {
  m->note_act = *(uint8_t *)(NOTE_ACT + (ch << 4));
  m->note_num = *(uint8_t *)(NOTE_NUM + (ch << 4));
  m->note_vel = *(uint8_t *)(NOTE_VEL + (ch << 4));
}

void printhex(uint16_t n, uint8_t d) {
  int8_t i;
  for (i = d - 1; i >= 0; i--)
    printf("%c", hex[0xF & (n >> (i << 2))]);
}

void tim() {
  uint8_t i;
  
  for (i = 0; i < 3; i++) {
    get_midi(&midi[i], i);

    if (midi[i].note_act) {
      amp[i] = (midi[i].note_vel) >> 3;
    } else {
      amp[i] = 0;
    }

    if ((midi[i].note_num > 97) || (midi[i].note_num < 24)) {
      amp[i] = 0;
    } else {
      freq[i] = freqs[midi[i].note_num - 24u];
    }
  }

  amp[2] = (4 - (amp[2] >> 2)) & 0x3;

  NR12_REG = (0xF & amp[0]) << 4;
  NR22_REG = (0xF & amp[1]) << 4;
  NR32_REG = (0xF & amp[2]) << 5;

  NR13_REG = (UBYTE)freq[0];
  NR23_REG = (UBYTE)freq[1];
  NR33_REG = (UBYTE)freq[2];

  NR14_REG = ((amp_prev[0] != amp[0]) << 7) | (*((UBYTE *)(&freq[0]) + 1));
  NR24_REG = ((amp_prev[1] != amp[1]) << 7) | (*((UBYTE *)(&freq[1]) + 1));
  NR34_REG = ((amp_prev[2] != amp[2]) << 7) | (*((UBYTE *)(&freq[2]) + 1));

  for (i = 0; i < 3; i++)
    amp_prev[i] = amp[i];
}

void main() {
  freq[0] = 0;
  freq[1] = 0;
  freq[2] = 0;
  amp[0] = 0;
  amp[1] = 0;
  amp[2] = 0;
  amp_prev[0] = 0;
  amp_prev[1] = 0;
  amp_prev[2] = 0;

  NR52_REG = 0x80;  // Enable sound
  NR50_REG = 0x77;  // Set master volume
  NR51_REG = 0xFF;  // Set output route

  NR11_REG = 0x00;  // Set duty
  NR21_REG = 0x80;  // Set duty

  NR30_REG = 0x00;  // Disable wave channel

  memcpy(PCM_SAMPLE, wavpat, 16);  // Set wave pattern

  NR30_REG = 0x80;  // Enable wave channel

  gotoxy(0, 0);
  printf(  // 20x18
    "MIDI Sound Generator"
    "                    "
    "     Sq1 Sq2 Wav Noi"
    "Nt#   --  --  --  --"
    "Frq  --- --- --- ---"
    "Vel   --  --  --  --"
    "Env    -   -   -   -"
    "Act   --  --  --  --"
  );

  CRITICAL {
    add_TIM(tim);
  }

  TMA_REG = 0x00U;  // Set TMA to divide clock by 0x100
  TAC_REG = 0x07U;  // Set clock to 16384 Hertz 
  set_interrupts(TIM_IFLAG);  // Handle TIM interrupts

  while (1) {
    gotoxy(6, 3);
    printhex(midi[0].note_num, 2);
    gotoxy(10, 3);
    printhex(midi[1].note_num, 2);
    gotoxy(14, 3);
    printhex(midi[2].note_num, 2);

    gotoxy(5, 4);
    printhex(freq[0], 3);
    gotoxy(9, 4);
    printhex(freq[1], 3);
    gotoxy(13, 4);
    printhex(freq[2], 3);

    gotoxy(6, 5);
    printhex(midi[0].note_vel, 2);
    gotoxy(10, 5);
    printhex(midi[1].note_vel, 2);
    gotoxy(14, 5);
    printhex(midi[2].note_vel, 2);

    gotoxy(7, 6);
    printhex(amp[0], 1);
    gotoxy(11, 6);
    printhex(amp[1], 1);
    gotoxy(15, 6);
    printhex(amp[2], 1);

    gotoxy(6, 7);
    if (midi[0].note_act) {
      printf("ON");
    } else {
      printf("--");
    }
    gotoxy(10, 7);
    if (midi[1].note_act) {
      printf("ON");
    } else {
      printf("--");
    }
    gotoxy(14, 7);
    if (midi[2].note_act) {
      printf("ON");
    } else {
      printf("--");
    }
  }
}
