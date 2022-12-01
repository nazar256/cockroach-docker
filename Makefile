COCKROACH_VERSION=v22.1.11

images:
	nice -n 19 docker buildx build --platform=linux/amd64,linux/arm64/v8 --build-arg=VERSION=$(COCKROACH_VERSION) -t dockerforclouds/cockroachdb:$(COCKROACH_VERSION) -t dockerforclouds/cockroachdb:latest --push .

builder: binfmt
	docker buildx create --name multiplatform --buildkitd-flags '--debug' --platform=linux/amd64,linux/arm/v5,linux/arm/v7,linux/arm64/v8,linux/386,linux/mips64le,linux/ppc64le,linux/s390x --driver-opt image=moby/buildkit:master --driver docker-container --bootstrap --use

binfmt:
	docker run --privileged --rm tonistiigi/binfmt --install all
