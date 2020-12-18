#include <gb/gb.h>
#include <stdio.h>

volatile __sfr __at (0xFD) __current_rom_bank;
#define SET_ROM_BANK(n) ((__current_rom_bank = (n)), SWITCH_ROM_MBC1((n)))

#define WAIT_KEY_EVENT while(!joypad()); while(joypad());

void ROM_bank1(void) NONBANKED __preserves_regs(b, c, d, e) {
  SET_ROM_BANK(1);
  printf("ROM Bank: 1\n");
  WAIT_KEY_EVENT;
}

void ROM_bank2(void) NONBANKED __preserves_regs(b, c, d, e) {
  SET_ROM_BANK(2);
  printf("ROM Bank: 2\n");
  WAIT_KEY_EVENT;
}

void ROM_bank3(void) NONBANKED __preserves_regs(b, c, d, e) {
  SET_ROM_BANK(3);
  printf("ROM Bank: 3\n");
  WAIT_KEY_EVENT;
}

void ROM_bank4(void) NONBANKED __preserves_regs(b, c, d, e) {
  SET_ROM_BANK(4);
  printf("ROM Bank: 4\n");
  WAIT_KEY_EVENT;
}

void ROM_bank5(void) NONBANKED __preserves_regs(b, c, d, e) {
  SET_ROM_BANK(5);
  printf("ROM Bank: 5\n");
  WAIT_KEY_EVENT;
}

void ROM_bank6(void) NONBANKED __preserves_regs(b, c, d, e) {
  SET_ROM_BANK(6);
  printf("ROM Bank: 6\n");
  WAIT_KEY_EVENT;
}

void ROM_bank7(void) NONBANKED __preserves_regs(b, c, d, e) {
  SET_ROM_BANK(7);
  printf("ROM Bank: 7\n");
  WAIT_KEY_EVENT;
}

void main() {
  while (1) {
    ROM_bank1();
    ROM_bank2();
    ROM_bank3();
    ROM_bank4();
    ROM_bank5();
    ROM_bank6();
    ROM_bank7();
  }
}
