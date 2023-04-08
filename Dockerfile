FROM golang:1.20 as prebuild
ARG TARGETARCH

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
RUN apt-get -y install build-essential gcc g++ cmake autoconf wget bison libncurses-dev ccache curl git libgeos-dev tzdata apt-transport-https lsb-release ca-certificates bazel-bootstrap yarn nodejs python

FROM  prebuild as build
ARG VERSION

RUN /bin/bash -c "mkdir -p $(go env GOPATH)/src/github.com/cockroachdb && \
    cd $(go env GOPATH)/src/github.com/cockroachdb"
WORKDIR /go/src/github.com/cockroachdb
RUN /bin/bash -c "git clone --branch ${VERSION} https://github.com/cockroachdb/cockroach"
WORKDIR /go/src/github.com/cockroachdb/cockroach
RUN /bin/bash -c "git submodule update --init --recursive"
RUN export NODE_OPTIONS=--max-old-space-size=7500 && \
    /bin/bash -c "make build"
RUN /bin/bash -c "make install"

FROM debian:bullseye-slim
RUN useradd -ms /bin/bash cockroach && \
    apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y libc6 ca-certificates tzdata hostname tar curl && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /cockroach/cockroach-data /usr/local/lib/cockroach /licenses && \
    chown -R cockroach /cockroach/
WORKDIR /cockroach/
ENV PATH=/cockroach:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
COPY --from=build /usr/local/bin/cockroach /cockroach/cockroach
COPY --from=build /go/native/*/geos/lib/libgeos.so /go/native/*/geos/lib/libgeos_c.so /usr/local/lib/cockroach/

VOLUME [ "/cockroach/cockroach-data" ]

USER cockroach

HEALTHCHECK CMD curl --fail http://localhost:8080/health || exit 1

EXPOSE 36257 26257 8080
CMD ["/cockroach/cockroach"]