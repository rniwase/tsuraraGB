#include <gbdk/platform.h>
#include <stdio.h>

#define WAIT_KEY_EVENT while(!joypad()); while(joypad());

void ROM_bank1(void) NONBANKED {
  SWITCH_ROM(1);
  printf("ROM Bank: 1\n");
  WAIT_KEY_EVENT;
}

void ROM_bank2(void) NONBANKED {
  SWITCH_ROM(2);
  printf("ROM Bank: 2\n");
  WAIT_KEY_EVENT;
}

void ROM_bank3(void) NONBANKED {
  SWITCH_ROM(3);
  printf("ROM Bank: 3\n");
  WAIT_KEY_EVENT;
}

void ROM_bank4(void) NONBANKED {
  SWITCH_ROM(4);
  printf("ROM Bank: 4\n");
  WAIT_KEY_EVENT;
}

void ROM_bank5(void) NONBANKED {
  SWITCH_ROM(5);
  printf("ROM Bank: 5\n");
  WAIT_KEY_EVENT;
}

void ROM_bank6(void) NONBANKED {
  SWITCH_ROM(6);
  printf("ROM Bank: 6\n");
  WAIT_KEY_EVENT;
}

void ROM_bank7(void) NONBANKED {
  SWITCH_ROM(7);
  printf("ROM Bank: 7\n");
  WAIT_KEY_EVENT;
}

void main(void) {
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
