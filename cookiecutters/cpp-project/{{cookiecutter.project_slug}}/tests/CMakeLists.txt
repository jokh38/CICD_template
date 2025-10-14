add_executable(test_example test_example.cpp)
target_link_libraries(test_example
    PRIVATE {{cookiecutter.project_slug}}_lib
{% if cookiecutter.testing_framework == "gtest" %}
    PRIVATE gtest
    PRIVATE gtest_main
{% else %}
    PRIVATE {{cookiecutter.testing_framework}}::{{cookiecutter.testing_framework}}
{% endif %}
)

add_test(NAME ExampleTest COMMAND test_example)
