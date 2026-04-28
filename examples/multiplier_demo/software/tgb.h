#include <stdint.h>

#define MULT8x8_IN_A    *( uint8_t *)0xB000U
#define MULT8x8_IN_B    *( uint8_t *)0xB001U
#define MULT8x8_OUT     *(uint16_t *)0xB002U
#define MULT16x16_IN_A  *(uint16_t *)0xB004U
#define MULT16x16_IN_B  *(uint16_t *)0xB006U
#define MULT16x16_OUT   *(uint32_t *)0xB008U

inline uint16_t tgb_mult8x8(uint8_t a, uint8_t b) {
  MULT8x8_IN_A = a;
  MULT8x8_IN_B = b;
  return MULT8x8_OUT;
}

inline uint32_t tgb_mult16x16(uint16_t a, uint16_t b) {
  MULT16x16_IN_A = a;
  MULT16x16_IN_B = b;
  return MULT16x16_OUT;
}
