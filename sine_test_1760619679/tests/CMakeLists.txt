add_executable(test_example test_example.cpp)
target_link_libraries(test_example
    PRIVATE sine_test_1760619679_lib

    PRIVATE gtest
    PRIVATE gtest_main

)

add_test(NAME ExampleTest COMMAND test_example)
