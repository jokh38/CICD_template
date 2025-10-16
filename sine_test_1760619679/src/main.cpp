#include <iostream>
#include "sine_test_1760619679/library.hpp"

int main() {
    std::cout << "Hello, sine_test_1760619679!" << std::endl;

    sine_test_1760619679::Library lib;
    lib.hello();

    int result = lib.add(5, 3);
    std::cout << "5 + 3 = " << result << std::endl;

    return 0;
}
