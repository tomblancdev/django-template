#! /bin/sh

# Install pre-commit if there is a git repository
if [ -d .git ]; then
    pre-commit install
fi

# Install poetry
poetry install

exit 0
