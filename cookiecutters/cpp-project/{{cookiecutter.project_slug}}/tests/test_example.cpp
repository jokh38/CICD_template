#include <gtest/gtest.h>
#include "{{cookiecutter.project_slug}}/library.hpp"

TEST(ExampleTest, BasicTest) {
    EXPECT_EQ(1 + 1, 2);
}

TEST(ExampleTest, LibraryAddTest) {
    {{cookiecutter.project_slug}}::Library lib;
    EXPECT_EQ(lib.add(5, 3), 8);
    EXPECT_EQ(lib.add(-1, 1), 0);
    EXPECT_EQ(lib.add(0, 0), 0);
}

int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
