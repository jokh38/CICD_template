#include "{{cookiecutter.project_slug}}/library.hpp"
#include <iostream>

namespace {{cookiecutter.project_slug}} {

void Library::hello() {
    std::cout << "Hello from {{cookiecutter.project_name}} library!" << std::endl;
}

int Library::add(int a, int b) {
    return a + b;
}

} // namespace {{cookiecutter.project_slug}}