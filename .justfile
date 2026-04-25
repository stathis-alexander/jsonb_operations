mod sorbet '.just/sorbet.just'
mod docker '.just/docker.just'

setup:
    @command -v asdf >/dev/null 2>&1 || { echo "error: asdf is not installed (see https://asdf-vm.com/)" >&2; exit 1; }
    @command -v docker >/dev/null 2>&1 || { echo "error: docker is not installed (see https://docs.docker.com/)" >&2; exit 1; }
    @command -v direnv >/dev/null 2>&1 || { echo "error: direnv is not installed (see https://direnv.net/)" >&2; exit 1; }
    bundle install
    git config core.hooksPath .githooks
    direnv allow .
    just docker up

lint:
    bundle exec rubocop -A

test:
    bundle exec rspec
