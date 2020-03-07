FROM arm64v8/alpine as builder

RUN apk add --update \
        openssl \
        git \
    && rm /var/cache/apk/*


RUN git clone https://github.com/nginx-proxy/docker-letsencrypt-nginx-proxy-companion.git /docker-letsencrypt-nginx-proxy-companion


FROM arm64v8/alpine

ENV DEBUG=false \
    DOCKER_GEN_VERSION=0.7.4 \
    DOCKER_HOST=unix:///var/run/docker.sock

# Install packages required by the image
RUN apk add --update --no-cache \
        bash \
        ca-certificates \
        curl \
        jq \
        git \
        openssl \
        make \
        gcc \
        vim musl-dev go
RUN apk add --update 

ENV GO_VERSION 1.14

RUN wget https://dl.google.com/go/go${GO_VERSION}.linux-arm64.tar.gz \
  && tar -C /usr/local -xzf go${GO_VERSION}.linux-arm64.tar.gz \
  && rm go${GO_VERSION}.linux-arm64.tar.gz

# Configure Go
ENV GOPATH=/root/go
ENV PATH=${GOPATH}/bin:/usr/local/go/bin:$PATH
ENV GOBIN=$GOROOT/bin
RUN mkdir -p ${GOPATH}/src ${GOPATH}/bin
ENV GO111MODULE=on
RUN go version

# Install docker-gen
#RUN curl -L https://github.com/jwilder/docker-gen/releases/download/${DOCKER_GEN_VERSION}/docker-gen-alpine-linux-armhf-${DOCKER_GEN_VERSION}.tar.gz \
#    | tar -C /usr/local/bin -xz
#    # Install docker-gen

RUN git clone https://github.com/jwilder/docker-gen.git \
 && cd docker-gen 
RUN  go get -v -d github.com/BurntSushi/toml
RUN  go get -v -d golang.org/x/net
#RUN make get-deps \
RUN make 

# Install simp_le
COPY --from=builder /docker-letsencrypt-nginx-proxy-companion/install_simp_le.sh /app/install_simp_le.sh
RUN chmod +rx /app/install_simp_le.sh && sync && /app/install_simp_le.sh && rm -f /app/install_simp_le.sh

COPY --from=builder /docker-letsencrypt-nginx-proxy-companion/app/ /app/

WORKDIR /app

ENTRYPOINT [ "/bin/bash", "/app/entrypoint.sh" ]
CMD [ "/bin/bash", "/app/start.sh" ]
