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
RUN apk add --update \
        bash \
        ca-certificates \
        curl \
        jq \
        git \
        openssl \
    && rm /var/cache/apk/*

# Install docker-gen
#RUN curl -L https://github.com/jwilder/docker-gen/releases/download/${DOCKER_GEN_VERSION}/docker-gen-alpine-linux-armhf-${DOCKER_GEN_VERSION}.tar.gz \
#    | tar -C /usr/local/bin -xz
#    # Install docker-gen
RUN git clone https://github.com/jwilder/docker-gen.git \
 && cd docker-gen \
 && make get-deps \
 && make

# Install simp_le
COPY --from=builder /docker-letsencrypt-nginx-proxy-companion/install_simp_le.sh /app/install_simp_le.sh
RUN chmod +rx /app/install_simp_le.sh && sync && /app/install_simp_le.sh && rm -f /app/install_simp_le.sh

COPY --from=builder /docker-letsencrypt-nginx-proxy-companion/app/ /app/

WORKDIR /app

ENTRYPOINT [ "/bin/bash", "/app/entrypoint.sh" ]
CMD [ "/bin/bash", "/app/start.sh" ]
