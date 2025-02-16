FROM python:3.12-bullseye AS builder

ARG USER=user
ARG USER_GROUP=user
ARG USER_PASSWORD
ARG USER_SUDO=false
ARG UID=1000
ARG GID=1000
ARG USER_SHELL=/bin/zsh


# Set environment variables
ENV ZSH_THEME=agnoster
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# Check if user is root
RUN if [ $(id -u) -eq 0 || ${USER} = "root" ]; then echo "Please do not run this container as root"; exit 1; fi

# updates and installs
RUN apt update && apt upgrade -y && apt install -y \
    git \
    zsh \
    sudo \
    curl \
    locales \
    locales-all \
    build-essential \
    mingw-w64 \
    gettext
RUN pip install --upgrade pip
# Create user
RUN groupadd -g ${GID} ${USER_GROUP} && \
    useradd -m -u ${UID} -g ${GID} -s ${USER_SHELL} ${USER} && \
    usermod -aG sudo ${USER} && \
    echo "${USER}:${USER_PASSWORD}" | chpasswd

# Enable sudo
RUN if [ ${USER_SUDO} = "true" ]; then usermod -aG sudo ${USER}; fi

# Install Oh My Zsh for root and user
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
    && sed -i "s/robbyrussell/"'$ZSH_THEME'"/g" /root/.zshrc;

USER ${USER}
# set the default shell for the user to zsh if the user is not root
RUN if [ $USER != "root" ]; \
    then \
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && \
    sed -i "s/robbyrussell/"'$ZSH_THEME'"/g" /home/$USER/.zshrc; \
    fi

USER root
# Set zsh as default shell for root
RUN chsh -s $(which zsh)
# Set zsh as default shell for user
RUN chsh -s $(which zsh) ${USER}

## POETRY installation
ARG POETRY_HOME=/etc/poetry
ARG POETRY_VERSION
ARG POETRY_VIRTUALENVS_IN_PROJECT=true
ENV POETRY_HOME=${POETRY_HOME}
ENV POETRY_VIRTUALENVS_IN_PROJECT=${POETRY_VIRTUALENVS_IN_PROJECT}

RUN if [ -z ${POETRY_VERSION} ]; then \
    curl -sSL https://install.python-poetry.org | python3 -; \
    else \
    curl -sSL https://install.python-poetry.org | python3 - --version ${POETRY_VERSION}; \
    fi

ENV PATH="${POETRY_HOME}/bin:${PATH}"


FROM builder AS development
# Set Arguments
ARG WORKSPACE=/workspace
ENV WORKSPACE=${WORKSPACE}

# Trust the user's workspace as git repository

## PRE-COMMIT installation
RUN pip install pre-commit

USER ${USER}
WORKDIR ${WORKSPACE}

RUN git config --global --add safe.directory ${WORKSPACE}
# Run a long-lived process
CMD tail -f /dev/null