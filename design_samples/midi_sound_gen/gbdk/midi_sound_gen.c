#include <gb/gb.h>
#include <stdio.h>
#include <gbdk/console.h>

UBYTE noteon_prev;
UBYTE noteon_now;
#define UPDATE_NOTEON() noteon_prev = noteon_now; noteon_now = *(UBYTE *)0xB000U
#define NOTE_ON() (noteon_now && !noteon_prev)
#define NOTE_OFF() (!noteon_now && noteon_prev)

const UWORD freqs[73] = {
 // C    C+   D    D+   E    F    F+   G    G+   A    A+   B // Oct
   44, 156, 262, 363, 457, 547, 631, 710, 786, 854, 923, 986,// 0
 1046,1102,1155,1205,1253,1297,1339,1379,1417,1452,1486,1517,// 1
 1546,1575,1602,1627,1650,1673,1694,1714,1732,1750,1767,1783,// 2
 1798,1812,1825,1837,1849,1860,1871,1881,1890,1899,1907,1915,// 3
 1923,1930,1936,1943,1949,1954,1959,1964,1969,1974,1978,1982,// 4
 1985,1988,1992,1995,1998,2001,2004,2006,2009,2011,2013,2015,// 5
 2017
};

void main() {
  UWORD freq;
  UBYTE vol;
  NR52_REG = 0x80U;  // Enable sound

  /* Sound channel 1 */
  // NR10_REG = 0x17U;
  // NR11_REG = 0x9FU;
  // NR12_REG = 0xF0U;
  // NR13_REG = 0x00FFU & freq_2;
  // NR14_REG = 0x40 | (freq_2 >> 8);

  /* Sound channel 2*/
  NR21_REG = (2 & 0x03) << 6;
  NR22_REG = 0xF0U;

  /* Sound channel 3 */
  // NR30_REG = 0x00U;
  // NR31_REG = 0x00U;
  // NR32_REG = 0x20U;
  // NR33_REG = 0xD6U;
  // NR34_REG = 0x46U;

  NR50_REG = 0x77U;  // Set master volume
  NR51_REG = 0xFFU;

  gotoxy(0, 0);
  printf("MIDI sound gen.");

  while (1) {

    if (NOTE_ON()) {
      NR22_REG = 0xF0U;  // min volume
      NR24_REG = 0x80U;
    }

    if (NOTE_OFF()){
      NR22_REG = 0x00U;  // zero volume, stop sound
    }

    freq = *(UBYTE *)0xB001U - 24;

    if (freq > 73) {
      freq = 72;
    }

    NR23_REG = 0x00FFU & freqs[freq];
    NR24_REG = (freqs[freq] >> 8);

    vol = *(UBYTE *)0xB003U;
    // vol = vol >> 4;

    // if (vol > 0) {
      // NR22_REG = (vol << 1) & 0xF0U;  // volume
      NR50_REG = (vol & 0x70) | ((vol >> 4) & 0x07);
    // } else {
      // NR22_REG = 0x10U;  // min volume
    // }

    UPDATE_NOTEON();
  }
}
