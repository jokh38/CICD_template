"""Core functionality for {{cookiecutter.project_name}}."""


def greet(name: str) -> str:
    """
    Return a greeting message.

    Args:
        name: The name to greet.

    Returns:
        A greeting message.
    """
    return f"Hello, {name}!"


def add(a: int, b: int) -> int:
    """
    Add two integers together.

    Args:
        a: First integer.
        b: Second integer.

    Returns:
        The sum of a and b.
    """
    return a + b


def multiply(a: int, b: int) -> int:
    """
    Multiply two integers together.

    Args:
        a: First integer.
        b: Second integer.

    Returns:
        The product of a and b.
    """
    return a * b