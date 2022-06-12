prepare:
	mkdir -p gitrepos

build:
	docker build --no-cache -t local-sonar-history-runner .

run:
	bash ./full-scan-repos.sh
