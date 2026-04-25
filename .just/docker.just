set working-directory := '..'

up:
    docker compose up -d --wait

down:
    docker compose down

restart: down up
