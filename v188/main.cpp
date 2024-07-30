#include <cstdint>
#include <cstdio>

#include "V188.h"
#include "V188___024root.h"

static std::array<uint8_t, 1024 * 1024> memory;

struct state_t {
  uint16_t ax   ;
  uint16_t cx   ;
  uint16_t dx   ;
  uint16_t bx   ;
  uint16_t sp   ;
  uint16_t bp   ;
  uint16_t si   ;
  uint16_t di   ;
  uint16_t es   ;
  uint16_t cs   ;
  uint16_t ss   ;
  uint16_t ds   ;
  uint16_t fs   ;
  uint16_t gs   ;
  uint16_t flags;
  uint16_t ip   ;

  uint32_t oMRd;
  uint32_t oMWr;
  uint32_t oPRd;
  uint32_t oPWr;
};

static state_t state;

static void dumpReg(const char* name, const uint16_t ref, uint16_t &old) {
  if (ref != old) {
    printf("%15s %04x => %04x\n", name, old, ref);
    old = ref;
  }
}

static void dumpState(V188& rtl) {
  dumpReg("ax   ", uint16_t(rtl.rootp->top__DOT__ax), state.ax);
  dumpReg("cx   ", uint16_t(rtl.rootp->top__DOT__cx), state.cx);
  dumpReg("dx   ", uint16_t(rtl.rootp->top__DOT__dx), state.dx);
  dumpReg("bx   ", uint16_t(rtl.rootp->top__DOT__bx), state.bx);
  dumpReg("sp   ", uint16_t(rtl.rootp->top__DOT__sp), state.sp);
  dumpReg("bp   ", uint16_t(rtl.rootp->top__DOT__bp), state.bp);
  dumpReg("si   ", uint16_t(rtl.rootp->top__DOT__si), state.si);
  dumpReg("di   ", uint16_t(rtl.rootp->top__DOT__di), state.di);
  dumpReg("es   ", uint16_t(rtl.rootp->top__DOT__es), state.es);
  dumpReg("cs   ", uint16_t(rtl.rootp->top__DOT__cs), state.cs);
  dumpReg("ss   ", uint16_t(rtl.rootp->top__DOT__ss), state.ss);
  dumpReg("ds   ", uint16_t(rtl.rootp->top__DOT__ds), state.ds);
//  dumpReg("fs   ", uint16_t(rtl.rootp->top__DOT__fs), state.fs);
//  dumpReg("gs   ", uint16_t(rtl.rootp->top__DOT__gs), state.gs);
  dumpReg("flags", uint16_t(rtl.rootp->top__DOT__flags), state.flags);
  dumpReg("ip   ", uint16_t(rtl.rootp->top__DOT__ip   ), state.ip   );
}

static void memWrite(uint32_t addr, void* src, uint32_t size) {
  memcpy(memory.data() + addr, src, size);
}

static bool memLoadCom(const char* path) {
  FILE* fd = fopen(path, "rb");
  if (!fd) {
    return false;
  }
  // get the filesize
  fseek(fd, 0, SEEK_END);
  size_t size = ftell(fd);
  fseek(fd, 0, SEEK_SET);
  // load location
  const uint32_t pos = 0x100;
  // read into memory
  const size_t read = fread(memory.data() + pos, 1, size, fd);
  fclose(fd);
  return read == size;
}

int main(int argc, char **args) {

  Verilated::commandArgs(argc, args);

  V188 rtl;
  memory.fill(0x90);

  memWrite(0xffff0, "\xEA\x00\x01\x00\x00", 5);
  memWrite(0x100,   "\xB8\x21\x43\x48\x50", 5);

  for (uint32_t i = 0; i < 100; ++i) {
    rtl.iClk ^= 1;
    rtl.eval();

    if (rtl.iClk == 0) {
      continue;
    }

    rtl.iReset = (i > 10);
    rtl.iReady = 1;

    // port read
    if (rtl.oPRd != state.oPRd) {
      state.oPRd = rtl.iPRd = rtl.oPRd;
      rtl.iPData = 0xcc;
      printf("%u: <%03x> => %02x\n", i, rtl.oPort, rtl.iPData);
    }

    // port write
    if (rtl.oPWr != state.oPWr) {
      state.oPWr = rtl.iPWr = rtl.oPWr;
      printf("%u: <%03x> <= %02x\n", i, rtl.oPort, rtl.oPData);
    }

    // memory read
    if (rtl.oMRd != state.oMRd) {
      state.oMRd = rtl.oMRd;
      rtl.iMData = memory[rtl.oAddr];
      printf("%u: [%06x] => %02x\n", i, rtl.oAddr, rtl.iMData);
    }

    // memory write
    if (rtl.oMWr != state.oMWr) {
      state.oMWr = rtl.oMWr;
      memory[rtl.oAddr] = rtl.oMData;
      printf("%u: [%06x] <= %02x\n", i, rtl.oAddr, rtl.oMData);
    }

//    if (rtl.rootp->top__DOT__state == (1 << 4)) {
      dumpState(rtl);
//    }
  }

  return 0;
}
