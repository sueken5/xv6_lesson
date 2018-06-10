.PHONY: docker-build
docker-build:
	docker build -t os-dev/xv6_lesson

.PHONY: docker-run
docker-run:
	sh ./docker-run.sh
