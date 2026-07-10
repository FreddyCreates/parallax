cmake_minimum_required(VERSION 3.16)

project(parallax_ai_wallet_native VERSION 0.1.0 LANGUAGES C CXX)

option(PARALLAX_AIW_BUILD_TESTS "Build PARALLAX AI wallet native tests" ON)
option(PARALLAX_AIW_BUILD_EXAMPLES "Build PARALLAX AI wallet native examples" ON)

add_library(parallax_ai_wallet STATIC src/ai_wallet.c)
add_library(parallax::ai_wallet ALIAS parallax_ai_wallet)

target_include_directories(parallax_ai_wallet
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

target_compile_features(parallax_ai_wallet PUBLIC c_std_99)

target_compile_options(parallax_ai_wallet PRIVATE
  $<$<C_COMPILER_ID:GNU,Clang,AppleClang>:-Wall -Wextra -Wpedantic>
  $<$<C_COMPILER_ID:MSVC>:/W4>
)

add_library(parallax_ai_wallet_cpp INTERFACE)
add_library(parallax::ai_wallet_cpp ALIAS parallax_ai_wallet_cpp)

target_link_libraries(parallax_ai_wallet_cpp INTERFACE parallax_ai_wallet)
target_include_directories(parallax_ai_wallet_cpp INTERFACE
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:include>
)
target_compile_features(parallax_ai_wallet_cpp INTERFACE cxx_std_17)

if(PARALLAX_AIW_BUILD_EXAMPLES)
  add_executable(parallax_ai_wallet_demo examples/ai_wallet_demo.cpp)
  target_link_libraries(parallax_ai_wallet_demo PRIVATE parallax::ai_wallet_cpp)
endif()

if(PARALLAX_AIW_BUILD_TESTS)
  enable_testing()

  add_executable(parallax_ai_wallet_c_test tests/test_ai_wallet_c.c)
  target_link_libraries(parallax_ai_wallet_c_test PRIVATE parallax::ai_wallet)
  add_test(NAME parallax_ai_wallet_c_test COMMAND parallax_ai_wallet_c_test)

  add_executable(parallax_ai_wallet_cpp_test tests/test_ai_wallet_cpp.cpp)
  target_link_libraries(parallax_ai_wallet_cpp_test PRIVATE parallax::ai_wallet_cpp)
  add_test(NAME parallax_ai_wallet_cpp_test COMMAND parallax_ai_wallet_cpp_test)
endif()

install(TARGETS parallax_ai_wallet parallax_ai_wallet_cpp
  EXPORT parallax_ai_wallet_targets
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)

install(DIRECTORY include/ DESTINATION include)
install(EXPORT parallax_ai_wallet_targets
  NAMESPACE parallax::
  DESTINATION lib/cmake/parallax_ai_wallet
)
