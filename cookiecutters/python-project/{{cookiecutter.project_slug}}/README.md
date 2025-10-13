# {{cookiecutter.project_name}}

{{cookiecutter.project_description}}

## Installation

```bash
pip install -e .[dev]
```

## Development

```bash
# Activate virtual environment
source .venv/bin/activate

# Install pre-commit hooks
pre-commit install

# Run tests
pytest

# Run linting
ruff check .
ruff format .
```

## Author

{{cookiecutter.author_name}} <{{cookiecutter.author_email}}>
