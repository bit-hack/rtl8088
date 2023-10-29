cmake_minimum_required(VERSION 3.20)
project(project8088)

add_subdirectory(external/udis86)

file(GLOB V_SRC rtl/*.v rtl/cpu/*.v)

find_package(verilator HINTS $ENV{VERILATOR_ROOT})
add_executable(p88 main.cpp)

verilate(p88 SOURCES ${V_SRC} TOP_MODULE top)
