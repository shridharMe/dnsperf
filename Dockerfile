ARG BASE_IMAGE=ubuntu:22.04
FROM $BASE_IMAGE AS runtime_base
LABEL MAINTAINER="Shridhar Patil"
ENV DEBIAN_FRONTEND=noninteractive

# dnsperf's runtime depedencies
RUN apt-get update && apt-get install -y -qqq --no-install-recommends \
    libck0 \
    libldns3 \
    libnghttp2-14 \
    && rm -rf /var/lib/apt/lists/*

# separate image for build, will not be tagged at the end
FROM runtime_base AS build_stage
RUN apt-get update && apt-get install -y -qqq --no-install-recommends \
    autoconf \
    automake \
    build-essential \
    git \
    libck-dev \
    libldns-dev \
    libnghttp2-dev \
    libssl-dev \
    libtool \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# copy repo as build context
COPY . /dnsperf
WORKDIR /dnsperf
RUN ./autogen.sh
RUN ./configure --prefix=/usr/local
RUN make -j$(nproc)
RUN make install

# separate stage to download kubectl binary
FROM alpine:latest AS downloader
RUN apk --no-cache add curl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl

# copy only installed artifacts and throw away everything else
FROM runtime_base AS installed
COPY --from=build_stage /usr/local /usr/local
COPY --from=downloader /kubectl /usr/local/bin/kubectl

# Copy the performance test script and make it executable
COPY run-perf-test.sh /usr/local/bin/run-perf-test.sh
RUN chmod +x /usr/local/bin/run-perf-test.sh

ENTRYPOINT ["/usr/local/bin/run-perf-test.sh"]
