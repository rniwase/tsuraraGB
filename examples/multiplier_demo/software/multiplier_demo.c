#include <gbdk/platform.h>
#include <gbdk/console.h>

#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <rand.h>

#include "tgb.h"

uint8_t previous_keys = 0;
uint8_t keys = 0;
#define UPDATE_KEYS() previous_keys = keys; keys = joypad()
#define KEY_PRESSED(K) (keys & (K))
#define KEY_TICKED(K) ((keys & (K)) && !(previous_keys & (K)))

volatile bool is_vbl = false;
uint16_t total_ops = 0;
uint8_t ops_per_frame = 0;
uint16_t work_a, work_b;
uint32_t work_o = 0;
uint8_t  line = 7;

void vbl(void) {
  is_vbl = true;
}

void clear_op(void) {
  gotoxy(0, 7);
  printf(
    "                    "
    "                    "
    "                    "
    "                    "
    "                    "
    "                    "
    "                    "
    "                    "
    "                    "
    "                    "
    "                   "
  );
  ops_per_frame = 0;
  total_ops = 0;
}

void update_op_8x8(void) {
  total_ops += ops_per_frame;
  gotoxy(12,    3); printf("%u    ", total_ops);
  gotoxy(12,    4); printf("%hu  ", ops_per_frame);
  gotoxy( 1, line); printf("%hx", work_a);
  gotoxy( 6, line); printf("%hx", work_b);
  gotoxy(11, line); printf("%x", work_o);

  ops_per_frame = 0;

  if (line == 17) {
    line = 7;
  } else {
    line++;
  }

  UPDATE_KEYS();

  is_vbl = false;
  vsync();
  is_vbl = false;
}

void update_op_16x16(void) {
  total_ops += ops_per_frame;
  gotoxy(12,    3); printf("%u    ", total_ops);
  gotoxy(12,    4); printf("%hu  ", ops_per_frame);
  gotoxy( 1, line); printf("%x", work_a);
  gotoxy( 6, line); printf("%x", work_b);
  gotoxy(11, line); printf("%x%x", *((uint16_t *)&work_o + 1), *(uint16_t *)(&work_o));

  ops_per_frame = 0;

  if (line == 17) {
    line = 7;
  } else {
    line++;
  }

  UPDATE_KEYS();

  is_vbl = false;
  while(!is_vbl);
  is_vbl = false;
}

void main(void) {
  initrand(0xABCD);
  gotoxy(0, 0);

  printf(  // 20x18
    " Multiplier Demo    "
    "                    "
    " Mode               "
    " Total OP           "
    " OP / Frame         "
    "                    "
    " IN-A IN-B OUT      "
  );

  CRITICAL {
    add_VBL(vbl);
  }

  set_interrupts(VBL_IFLAG);

  while (1) {
    gotoxy(6, 2); printf("CPU 8x8bit   ");
    clear_op();
    UPDATE_KEYS();

    while (!KEY_TICKED(J_SELECT)) {
      work_a = rand();
      work_b = rand();
      work_o = (uint16_t)work_a * (uint16_t)work_b;
      ops_per_frame++;

      if (is_vbl) {
        update_op_8x8();
      }
    };

    gotoxy(6, 2); printf("FPGA 8x8bit  ");
    clear_op();
    UPDATE_KEYS();

    while (!KEY_TICKED(J_SELECT)) {
      work_a = rand();
      work_b = rand();
      work_o = tgb_mult8x8(work_a, work_b);
      ops_per_frame++;

      if (is_vbl) {
        update_op_8x8();
      }
    }

    gotoxy(6, 2); printf("CPU 16x16bit ");
    clear_op();
    UPDATE_KEYS();

    while (!KEY_TICKED(J_SELECT)) {
      work_a = randw();
      work_b = randw();
      work_o = (uint32_t)work_a * (uint32_t)work_b;
      ops_per_frame++;

      if (is_vbl) {
        update_op_16x16();
      }
    };

    gotoxy(6, 2); printf("FPGA 16x16bit");
    clear_op();
    UPDATE_KEYS();

    while (!KEY_TICKED(J_SELECT)) {
      work_a = randw();
      work_b = randw();
      work_o = tgb_mult16x16(work_a, work_b);
      ops_per_frame++;

      if (is_vbl) {
        update_op_16x16();
      }
    }

  }
}
