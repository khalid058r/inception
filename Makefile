LOGIN       = kabouelf
DATA_PATH   = /home/$(LOGIN)/data

ENV_FILE    = srcs/.env
COMPOSE     = docker compose --env-file $(ENV_FILE) -f srcs/docker-compose.yml

.PHONY: all check-config build up down stop start restart logs ps clean fclean re

all: check-config build up

# Fail early with a clear message instead of letting compose error out deep
# in variable interpolation when a required local-only file is missing.
check-config:
	@test -f $(ENV_FILE) || (echo "Missing $(ENV_FILE) -- copy srcs/.env.example to srcs/.env and fill it in." && exit 1)
	@mkdir -p $(DATA_PATH)/wordpress $(DATA_PATH)/mariadb

build:
	@$(COMPOSE) build

up:
	@$(COMPOSE) up -d

down:
	@$(COMPOSE) down

stop:
	@$(COMPOSE) stop

start:
	@$(COMPOSE) start

restart: down up

logs:
	@$(COMPOSE) logs -f

ps:
	@$(COMPOSE) ps

clean: down

# Removes containers, network, images and named volumes, then wipes the
# host-side data directory. Destructive -- data is not recoverable after this.
fclean:
	@$(COMPOSE) down -v --rmi all
	@sudo rm -rf $(DATA_PATH)

re: fclean all
