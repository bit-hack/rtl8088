#include <stdio.h>
#include <memory>

#include <verilated.h>

#include "external/udis86/udis86.h"

#include "V8088.h"
#include "V8088___024root.h"

struct memory_t {

  static const uint32_t addrTop = 1024 * 1024;

  bool loadBios(const char *path) {
    FILE *fd = fopen(path, "rb");
    if (!fd) {
      return false;
    }
    // get the filesize
    fseek(fd, 0, SEEK_END);
    size_t size = ftell(fd);
    fseek(fd, 0, SEEK_SET);
    // load location
    const uint32_t pos = addrTop - size;
    // read into memory
    const size_t read = fread(memory.get() + pos, 1, size, fd);
    fclose(fd);
    return read == size;
  }

  bool init(const char *biosPath) {
    memory.reset(new uint8_t[addrTop]);
    memset(memory.get(), 0x90, addrTop);
    if (!loadBios(biosPath)) {
      return false;
    }
    return true;
  }

  uint8_t read(uint32_t addr) const {
    return memory[addr];
  }

  void write(uint32_t addr, uint8_t data) {
    memory[addr] = data;
  }

  std::unique_ptr<uint8_t[]> memory;
};

struct cpu_t {

  static const uint64_t clockRatio = 16;

  cpu_t(memory_t &mem)
    : memory(mem) {
  }

  void onCpuClock() {
    tState = rtl.ale_o ? 0 : tState + 1;

    dump();

    if (rtl.ale_o) {
      latchAddr = rtl.ad_o;
    }
    if (rtl.den_o) {
      if (!rtl.iom_o && !rtl.rd_o) {
        rtl.ad_i = onMemRead(latchAddr);
      }
      if (rtl.iom_o && !rtl.rd_o) {
        rtl.ad_i = onPortRead(latchAddr);
      }
    }
    if (rtl.dtr_o) {
      if (!rtl.iom_o && !rtl.wr_o) {
        onMemWrite(latchAddr, rtl.ad_o);
      }
      if (rtl.iom_o && !rtl.wr_o) {
        onPortWrite(latchAddr, rtl.ad_i);
      }
    }
  }

  void dump() {
    uint32_t pc =  rtl.rootp->top__DOT__cpu__DOT__biu__DOT__pfq_addr_out +
                  (rtl.rootp->top__DOT__cpu__DOT__biu__DOT__biu_register_cs << 4);
#if 0
    if (rtl.ale_o) {
      printf("pc: %05x\n", pc);
    }
    printf("t%d a:%05x di:%02x ale:%d wr:%d rd:%d iom:%d dtr:%d den:%d\n",
      tState,
      rtl.ad_o,
      rtl.ad_i,
      rtl.ale_o,
      rtl.wr_o,
      rtl.rd_o,
      rtl.iom_o,
      rtl.dtr_o,
      rtl.den_o);
#endif
  }

  uint8_t onMemRead(uint32_t addr) {
    printf("- mem read %05x\n", addr);
    return memory.read(addr);
  }

  void onMemWrite(uint32_t addr, uint8_t data) {
    printf("- mem write %05x %02x\n", addr, data);
    memory.write(addr, data);
  }

  uint8_t onPortRead(uint32_t addr) {
    printf("- port read %04x\n", addr);
    return 0;
  }

  void onPortWrite(uint32_t addr, uint8_t data) {
    printf("- port write %04x %02x\n", addr, data);
  }

  void tick() {
    ++clocks;
    // update clock signals
    rtl.clk_i     =  clocks               & 1;
    rtl.clk_cpu_i = (clocks / clockRatio) & 1;
    // reset signal
    rtl.rst_i = (clocks >= 4 && clocks <= 64);
    rtl.eval();
    // detect rising edge of cpu clock
    if (!cpuClkDelay && rtl.clk_cpu_i) {
      onCpuClock();
    }
    cpuClkDelay = rtl.clk_cpu_i;
  }

  bool init() {
    clocks      = 0;
    cpuClkDelay = 0;
    tState      = 0;
    rtl.ad_i    = 0x90;  // nop
    rtl.intr_i  = 0;
    rtl.test_i  = 1;
    rtl.nmi_i   = 0;
    rtl.ready_i = 1;
    return true;
  }

  memory_t &memory;

  uint32_t latchAddr;

  int tState;
  uint64_t clocks;
  int cpuClkDelay;
  V8088 rtl;
};

int main(int argc, char **args) {

  Verilated::commandArgs(argc, args);

  memory_t mem;
  if (!mem.init("landmark.bin")) {
    return 1;
  }

  cpu_t cpu { mem };
  if (!cpu.init()) {
    return 1;
  }

  for (int i = 0; i < 200000; ++i) {
    cpu.tick();
  }

  return 0;
}
