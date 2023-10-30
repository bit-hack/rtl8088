cmake_minimum_required(VERSION 3.0)
project(V188)

find_package(verilator HINTS $ENV{VERILATOR_ROOT})
if (NOT verilator_FOUND)
  message(FATAL_ERROR "Verilator was not found.")
endif()

add_executable(vexample main.cpp)
verilate(vexample SOURCES top.v V188.v MyDiv.v TOP_MODULE top PREFIX V188 TRACE)
