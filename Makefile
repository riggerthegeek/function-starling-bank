DOCKER_IMG ?= function-starling-bank
DOCKER_MANIFEST_URL ?= https://6582-88013053-gh.circle-artifacts.com/1/work/build/docker-linux-amd64
DOCKER_USER ?= ""

TAG_NAME = ${DOCKER_IMG}
ifneq ($(DOCKER_USER), "")
TAG_NAME = ${DOCKER_USER}/${DOCKER_IMG}
endif

build:
	@echo "Building latest Docker images"
	docker build --file ./Dockerfile --tag ${TAG_NAME}:linux-amd64-latest .
	docker build --file ./Dockerfile.arm --tag ${TAG_NAME}:linux-arm-latest .
.PHONY: build

download-docker:
	@echo "Downloading docker client with manifest command"
	curl -L ${DOCKER_MANIFEST_URL} -o ./docker
	chmod +x ./docker
	./docker version
.PHONY: download-docker

publish:
	./docker version || make download-docker
	$(eval VERSION := $(shell make version))

	@echo "Tagging Docker images as v${VERSION}"
	docker tag ${TAG_NAME}:linux-amd64-latest ${TAG_NAME}:linux-amd64-${VERSION}
	docker tag ${TAG_NAME}:linux-arm-latest ${TAG_NAME}:linux-arm-${VERSION}

	@echo "Pushing images to Docker"
	docker push ${TAG_NAME}:linux-amd64-latest
	docker push ${TAG_NAME}:linux-amd64-${VERSION}
	docker push ${TAG_NAME}:linux-arm-latest
	docker push ${TAG_NAME}:linux-arm-${VERSION}

	@echo "Create Docker manifests"
	./docker -D manifest create "${TAG_NAME}:${VERSION}" \
		"${TAG_NAME}:linux-amd64-${VERSION}" \
		"${TAG_NAME}:linux-arm-${VERSION}"
	./docker -D manifest annotate "${TAG_NAME}:${VERSION}" "${TAG_NAME}:linux-arm-${VERSION}" --os=linux --arch=arm --variant=v6
	./docker -D manifest push "${TAG_NAME}:${VERSION}"

	./docker -D manifest create "${TAG_NAME}:latest" \
		"${TAG_NAME}:linux-amd64-latest" \
		"${TAG_NAME}:linux-arm-latest"
	./docker -D manifest annotate "${TAG_NAME}:latest" "${TAG_NAME}:linux-arm-latest" --os=linux --arch=arm --variant=v6
	./docker -D manifest push "${TAG_NAME}:latest"
.PHONY: publish

serve:
	docker run \
		-v ${PWD}/function:/home/node/function \
		-v ${PWD}/node_modules:/home/node_modules \
		-e "BASE_URL=${BASE_URL}" \
		-e "CLIENT_ID=${CLIENT_ID}" \
		-e "CLIENT_SECRET=${CLIENT_SECRET}" \
		-e "EXCHANGE_TOKENS=${EXCHANGE_TOKENS}" \
		-it --rm \
		${TAG_NAME}:linux-amd64-latest sh -c \
		"echo '${INPUT}' | node index.js"
.PHONY: serve

test:
	npm test
.PHONY: test

version:
	@echo $(shell ./node_modules/.bin/json -f ./package.json -a version)
.PHONY: version
