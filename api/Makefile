start:
	docker-compose up --build

build:
	docker build -t asia-northeast1-docker.pkg.dev/chum-312212/food-additive/api:latest .

push:
	docker push asia-northeast1-docker.pkg.dev/chum-312212/food-additive/api:latest
	gcloud run deploy --image asia-northeast1-docker.pkg.dev/chum-312212/food-additive/api:latest --platform=managed --project=chum-312212
