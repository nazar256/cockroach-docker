FROM golang:1.19-bullseye as prebuild
RUN go version
RUN apt-get update
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -y upgrade
RUN ["/bin/bash", "-c", "curl -sL https://deb.nodesource.com/setup_12.x | bash -"]
RUN curl https://bazel.build/bazel-release.pub.gpg | apt-key add
RUN echo "deb https://storage.googleapis.com/bazel-apt stable jdk1.8" | tee /etc/apt/sources.list.d/bazel.list
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get -y update
RUN apt-get -y install build-essential gcc g++ cmake autoconf wget bison libncurses-dev ccache curl git libgeos-dev tzdata apt-transport-https lsb-release ca-certificates bazel* yarn nodejs

FROM  prebuild as build
ARG VERSION

RUN /bin/bash -c "mkdir -p $(go env GOPATH)/src/github.com/cockroachdb && \
    cd $(go env GOPATH)/src/github.com/cockroachdb"
WORKDIR /go/src/github.com/cockroachdb
RUN /bin/bash -c "git clone --branch ${VERSION} https://github.com/cockroachdb/cockroach"
WORKDIR /go/src/github.com/cockroachdb/cockroach
RUN /bin/bash -c "git submodule update --init --recursive"
RUN /bin/bash -c "make build"
RUN /bin/bash -c "make install"

FROM debian:bullseye-slim
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y libc6 ca-certificates tzdata hostname tar && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /cockroach/
ENV PATH=/cockroach:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
RUN mkdir -p /cockroach/ /usr/local/lib/cockroach /licenses
COPY --from=build /usr/local/bin/cockroach /cockroach/cockroach
COPY --from=build /go/native/*/geos/lib/libgeos.so /go/native/*/geos/lib/libgeos_c.so /usr/local/lib/cockroach/
EXPOSE 26257 8080
ENTRYPOINT ["/cockroach/cockroach"]