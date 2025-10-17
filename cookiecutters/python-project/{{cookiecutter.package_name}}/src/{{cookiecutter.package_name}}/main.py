"""Main module for {{cookiecutter.project_name}}."""

from .core import add, greet


def main() -> None:
    """Main entry point for the application."""
    print(greet("{{cookiecutter.project_name}}"))

    # Demonstrate the core functionality
    result = add(5, 3)
    print(f"5 + 3 = {result}")


if __name__ == "__main__":
    main()