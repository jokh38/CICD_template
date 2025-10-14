cmake_minimum_required(VERSION 3.20)
project({{cookiecutter.project_slug}} VERSION 0.1.0 LANGUAGES CXX)

# C++ standard
set(CMAKE_CXX_STANDARD {{cookiecutter.cpp_standard}})
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Export compile commands for clang-tidy
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Compiler warnings
if(MSVC)
    add_compile_options(/W4 /WX)
else()
    add_compile_options(-Wall -Wextra -Wpedantic -Werror)
endif()

# Dependencies
include(FetchContent)
{% if cookiecutter.testing_framework == "gtest" %}
FetchContent_Declare(
  googletest
  URL https://github.com/google/googletest/archive/refs/tags/v1.14.0.tar.gz
)
# For Windows: Prevent overriding the parent project's compiler/linker settings
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)
{% else %}
find_package({{cookiecutter.testing_framework}} REQUIRED)
{% endif %}

# Library
add_library({{cookiecutter.project_slug}}_lib
    src/library.cpp
)

target_include_directories({{cookiecutter.project_slug}}_lib
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
)

# Executable
add_executable({{cookiecutter.project_slug}}
    src/main.cpp
)

target_link_libraries({{cookiecutter.project_slug}}
    PRIVATE {{cookiecutter.project_slug}}_lib
)

# Tests
enable_testing()
add_subdirectory(tests)
