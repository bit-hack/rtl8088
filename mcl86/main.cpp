#include <stdio.h>
#include <memory>

#include <verilated.h>

#include "external/udis86/udis86.h"

#include "V8088.h"
#include "V8088___024root.h"

struct memory_t {

  static const uint32_t memSize = 1u << 20;

  bool loadCom(const char *path) {
    FILE *fd = fopen(path, "rb");
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
    const size_t read = fread(memory.get() + pos, 1, size, fd);
    fclose(fd);
    return read == size;
  }

  bool init(const char *comPath) {
    memory.reset(new uint8_t[memSize]);
    memset(memory.get(), 0xCC, memSize);
    //if (!loadCom(comPath)) {
    //  return false;
    //}
    return true;
  }

  uint8_t read(uint32_t addr) const {
    return memory[addr];
  }

  void dump_display(const char* path) {

    // 4Kb ram at 0xB0000

    const uint32_t address = 0xB0000;

    FILE *fd = fopen(path, "wb");
    if (!fd) {
      return;
    }

    const uint8_t* ptr = memory.get() + address;
    fwrite(ptr, 1, 4 * 1024, fd);
    fclose(fd);
  }

  void write(uint32_t addr, uint8_t data) {
    memory[addr] = data;
  }

  void write(uint32_t addr, void* src, uint32_t size) {
    memcpy(memory.get() + addr, src, size);
  }

  std::unique_ptr<uint8_t[]> memory;
};

struct cpu_t {

  cpu_t(memory_t &mem)
    : memory(mem) {
  }

  uint8_t onMemRead(uint32_t addr) {
    return memory.read(addr);
  }

  void onMemWrite(uint32_t addr, uint8_t data) {
    memory.write(addr, data);
  }

  void tick() {
    ++clocks;
    // update clock signals
    rtl.iClk = clocks & 1;
    rtl.eval();

    if (rtl.oSramWe == 1) {
      onMemWrite(rtl.iSramAddr, rtl.ioSramData);
    }
    else {
      rtl.ioSramData = onMemRead(rtl.iSramAddr);
    }
  }

  bool init() {
    clocks = 0;
    return true;
  }

  memory_t &memory;
  uint32_t latchAddr;
  int      tState;
  uint64_t clocks;
  V8088    rtl;
};

int main(int argc, char **args) {

  Verilated::commandArgs(argc, args);

  const char* path = "C:\\personal\\rtl8088\\mcl86\\tests\\OPCODE_7.COM";

  memory_t mem;
  if (!mem.init(path)) {
    return 1;
  }

  cpu_t cpu { mem };
  if (!cpu.init()) {
    return 1;
  }

  cpu.memory.write(0xffff0, "\xEA\x00\x01\x00\x00", 5);

  uint64_t max_cycles = 1ull << 32;
  for (uint64_t i = 0; i < max_cycles; ++i) {
    cpu.tick();
  }

  mem.dump_display("display.txt");

  return 0;
}
