#! /bin/sh

# Update pre-commit if there is a git repository
if [ -d .git ]; then
    pre-commit autoupdate
fi

exit 0
