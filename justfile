python-version := `cat .python-version`
venv-dir := ".venv"
python-cmd := venv-dir + "/bin/python"

_list:
    just --list --unsorted

_lock ENV:
    @sort -u requirements/{{ENV}}.in -o requirements/{{ENV}}.in
    @CUSTOM_COMPILE_COMMAND="just lock" {{python-cmd}} -m piptools compile --output-file requirements/locks/{{ENV}}.txt requirements/{{ENV}}.in

# Lock Python requirements with pip-tools.
lock: setup-venv _local-requirements _upgrade-pip
    @for env in main dev local; do \
        just _lock $env; \
    done

_sync ENV:
    @{{python-cmd}} -m piptools sync requirements/locks/{{ "{" }}{{ENV}}}.txt

_sync-dev: (_sync "main,dev")

_sync-local: (_sync "main,dev,local")

# Sync the environment with pip-tools.
sync ENV="local": setup-venv _local-requirements _upgrade-pip
    @just _sync-{{ENV}}

# Add a python dependency to main, dev or local and install it. Usually unpinned.
add-dependency ENV DEP: && lock sync
    @echo {{DEP}} >> requirements/{{ENV}}.in

# Update Python and create a virtual environment at .venv as needed.
[macos]
setup-venv:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ ! -f "{{venv-dir}}/bin/python" ]] || [[ "Python {{python-version}}" != "$(python -V)" ]]; then \
        if brew outdated | grep -q "^pyenv"; then
          brew upgrade pyenv
        fi
        pyenv install -s {{python-version}}
        python3 -m venv {{venv-dir}} --clear
    fi

# Add for linux support
# [linux]
# setup-venv:

# Add for windows support
# [windows]
# setup-venv:

_upgrade-pip:
    @{{python-cmd}} -m pip install -q --upgrade pip setuptools pip-tools

# Create the gitignored files for your own personal requirements
_local-requirements:
    @ [ -f requirements/local.in ] || echo "-c locks/dev.txt\n-c locks/main.txt" > requirements/local.in
    @ [ -f requirements/locks/local.txt ] || touch requirements/locks/local.txt
