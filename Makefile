LOGIN       = ${USER}
DATA_PATH   = /home/$(LOGIN)/data

ENV_FILE    = srcs/.env
COMPOSE     = docker compose -f srcs/docker-compose.yml


all: check-config build up

check-config:
	@test -f $(ENV_FILE) || (echo "Missing $(ENV_FILE) -- create srcs/.env and fill it in." && exit 1)
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

fclean:
	@$(COMPOSE) down -v --rmi all
	@sudo rm -rf $(DATA_PATH)

re: fclean all
