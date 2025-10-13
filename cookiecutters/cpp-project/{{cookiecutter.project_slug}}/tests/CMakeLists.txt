add_executable(test_example test_example.cpp)
target_link_libraries(test_example
    PRIVATE {{cookiecutter.project_slug}}_lib
    PRIVATE {{cookiecutter.testing_framework}}::{{cookiecutter.testing_framework}}
)

add_test(NAME ExampleTest COMMAND test_example)
