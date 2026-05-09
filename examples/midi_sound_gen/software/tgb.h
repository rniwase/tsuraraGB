#include <stdint.h>

#define CH0_NOTE_ACT    *( uint8_t *)0xB000U
#define CH0_NOTE_NUM    *( uint8_t *)0xB001U
#define CH0_NOTE_VEL    *( uint8_t *)0xB002U
#define CH0_CC_VOL      *( uint8_t *)0xB003U
#define CH0_PITCHBEND   *(uint16_t *)0xB004U

#define CH1_NOTE_ACT    *( uint8_t *)0xB010U
#define CH1_NOTE_NUM    *( uint8_t *)0xB011U
#define CH1_NOTE_VEL    *( uint8_t *)0xB012U
#define CH1_CC_VOL      *( uint8_t *)0xB013U
#define CH1_PITCHBEND   *(uint16_t *)0xB014U

#define CH2_NOTE_ACT    *( uint8_t *)0xB020U
#define CH2_NOTE_NUM    *( uint8_t *)0xB021U
#define CH2_NOTE_VEL    *( uint8_t *)0xB022U
#define CH2_CC_VOL      *( uint8_t *)0xB023U
#define CH2_PITCHBEND   *(uint16_t *)0xB024U

#define CH3_NOTE_ACT    *( uint8_t *)0xB030U
#define CH3_NOTE_NUM    *( uint8_t *)0xB031U
#define CH3_NOTE_VEL    *( uint8_t *)0xB032U
#define CH3_CC_VOL      *( uint8_t *)0xB033U
#define CH3_PITCHBEND   *(uint16_t *)0xB034U

#define MULT8x8_IN_A    *( uint8_t *)0xB800U
#define MULT8x8_IN_B    *( uint8_t *)0xB802U
#define MULT8x8_OUT     *(uint16_t *)0xB804U

#define MULT16x16_IN_A  *(uint16_t *)0xB800U
#define MULT16x16_IN_B  *(uint16_t *)0xB802U
#define MULT16x16_OUT   *(uint32_t *)0xB804U

#define NRFREQ_IN   *(uint16_t *)0xBC00U
#define NRFREQ_OUT  *(int16_t *)0xBC02U

inline uint32_t tgb_mult16x16(uint16_t a, uint16_t b) {
  MULT16x16_IN_A = a;
  MULT16x16_IN_B = b;
  return MULT16x16_OUT;
}

inline int16_t tgb_nrfreq(uint16_t note_num) {
  NRFREQ_IN = note_num;
  return NRFREQ_OUT;
}
