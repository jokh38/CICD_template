"""Example test module."""

from {{cookiecutter.package_name}} import add, greet, multiply


def test_example() -> None:
    """Example test case."""
    assert True


def test_greet() -> None:
    """Test the greet function."""
    result = greet("World")
    assert result == "Hello, World!"


def test_add() -> None:
    """Test the add function."""
    assert add(5, 3) == 8
    assert add(-1, 1) == 0
    assert add(0, 0) == 0


def test_multiply() -> None:
    """Test the multiply function."""
    assert multiply(5, 3) == 15
    assert multiply(-1, 1) == -1
    assert multiply(0, 5) == 0
