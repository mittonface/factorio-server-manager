ENV_FILE ?= .env
include $(ENV_FILE)
export

run: 
	docker build -t factorio .
	docker run -d -p 34197:34197/udp  --name factorio --env-file $(ENV_FILE) factorio
stop:
	docker stop $$(docker ps -q --filter ancestor=factorio) || true
	docker rm $$(docker ps -a -q --filter ancestor=factorio) || true