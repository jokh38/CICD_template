#include <iostream>
#include "{{cookiecutter.project_slug}}/library.hpp"

int main() {
    std::cout << "Hello, {{cookiecutter.project_name}}!" << std::endl;

    {{cookiecutter.project_namespace}}::Library lib;
    lib.hello();

    int result = lib.add(5, 3);
    std::cout << "5 + 3 = " << result << std::endl;

    return 0;
}
