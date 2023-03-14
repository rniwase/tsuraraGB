#include <gb/gb.h>
#include <stdio.h>
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

typedef struct {
  uint8_t note_act;
  uint8_t note_num;
  uint8_t note_vel;
} MIDI;

void get_midi(MIDI* m, uint8_t ch) {
  m->note_act = *(uint8_t *)(NOTE_ACT + (ch << 4));
  m->note_num = *(uint8_t *)(NOTE_NUM + (ch << 4));
  m->note_vel = *(uint8_t *)(NOTE_VEL + (ch << 4));
}

void printn8(uint8_t n) {
  printf("%c", hex[0xF & (n >> 4)]);
  printf("%c", hex[0xF & (n)]);
}

void printn16(uint16_t n) {
  printf("%c", hex[0xF & (n >> 12)]);
  printf("%c", hex[0xF & (n >> 8)]);
  printf("%c", hex[0xF & (n >> 4)]);
  printf("%c", hex[0xF & (n)]);
}

void main() {
  MIDI midi[2];
  uint16_t freq[2] = {0, 0};
  uint8_t amp[2] = {0, 0};
  uint8_t amp_prev[2] = {0, 0};

  NR52_REG = 0x80;  // Enable sound
  NR50_REG = 0x77;  // Set master volume
  NR51_REG = 0xFF;  // Set output route

  NR11_REG = 0x00;
  NR21_REG = 0x80;

  gotoxy(0, 0);
  printf("MIDI Sound Generator");

  while (1) {
    // --------
    get_midi(&midi[0], 0);

    gotoxy(0, 1);
    if (midi[0].note_act) {
      printf("ON");
      amp[0] = (midi[0].note_vel) >> 3;
    } else {
      printf("--");
      amp[0] = 0;
    }

    if ((midi[0].note_num > 97) || (midi[0].note_num < 24)) {
      amp[0] = 0;
    } else {
      freq[0] = freqs[midi[0].note_num - 24u];
    }

    gotoxy(0, 2);
    printn8(midi[0].note_vel);
    gotoxy(0, 3);
    printn8(midi[0].note_num);

    NR12_REG = (0xF & amp[0]) << 4;
    NR13_REG = (UBYTE)freq[0];

    if (amp_prev[0] != amp[0]) {
      NR14_REG = 0x80 | (*((UBYTE *)(&freq[0]) + 1));
    } else {
      NR14_REG = freq[0] >> 8;
    }

    amp_prev[0] = amp[0];    

    // --------
    get_midi(&midi[1], 1);

    gotoxy(0, 4);
    if (midi[1].note_act) {
      printf("ON");
      amp[1] = (midi[1].note_vel) >> 3;
    } else {
      printf("--");
      amp[1] = 0;
    }

    if ((midi[1].note_num > 97) || (midi[1].note_num < 24)) {
      amp[1] = 0;
    } else {
      freq[1] = freqs[midi[1].note_num - 24u];
    }

    gotoxy(0, 5);
    printn8(midi[1].note_vel);
    gotoxy(0, 6);
    printn8(midi[1].note_num);

    NR22_REG = (0xF & amp[1]) << 4;
    NR23_REG = (UBYTE)freq[1];

    if (amp_prev[1] != amp[1]) {
      NR24_REG = 0x80 | (*((UBYTE *)(&freq[1]) + 1));
    } else {
      NR24_REG = freq[1] >> 8;
    }

    amp_prev[1] = amp[1];   
  }
}
