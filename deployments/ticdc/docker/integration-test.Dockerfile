# Specify the image architecture explicitly,
# otherwise it will not work correctly on other architectures.
FROM rockylinux:8 as downloader

ARG BRANCH
ENV BRANCH=$BRANCH

ARG COMMUNITY
ENV COMMUNITY=$COMMUNITY

ARG VERSION
ENV VERSION=$VERSION

ARG OS
ENV OS=$OS

ARG ARCH
ENV ARCH=$ARCH

USER root
WORKDIR /root/download

# Installing dependencies.
RUN dnf install -y \
    wget
COPY ./scripts/download-integration-test-binaries.sh .
# Download all binaries into bin dir.
RUN ./download-integration-test-binaries.sh $BRANCH $COMMUNITY $VERSION $OS $ARCH
RUN ls ./bin

# Download go into /usr/local dir.
ENV GOLANG_VERSION 1.23.0
ENV GOLANG_DOWNLOAD_URL https://dl.google.com/go/go$GOLANG_VERSION.linux-amd64.tar.gz
RUN curl -fsSL "$GOLANG_DOWNLOAD_URL" -o golang.tar.gz \
    && tar -C /usr/local -xzf golang.tar.gz \
    && rm golang.tar.gz

FROM rockylinux:8

USER root
WORKDIR /root

# Enable additional repositories for development tools.
RUN dnf install -y dnf-plugins-core
RUN dnf config-manager --set-enabled powertools

# Installing dependencies.
RUN dnf install -y \
    git \
    bash-completion \
    wget \
    which \
    gcc \
    make \
    curl \
    tar \
    glibc-devel \
    sudo \
    python3 \
    psmisc \
    procps-ng
# Enable EPEL repository for additional packages.
RUN dnf install -y epel-release
RUN dnf --enablerepo=epel install -y s3cmd
# Install MySQL client.
RUN dnf install -y https://repo.mysql.com/mysql80-community-release-el8-9.noarch.rpm
RUN rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022
# Enable MySQL 8.0 module and install the client.
# RUN dnf module enable -y mysql:8.0
# RUN dnf install -y mysql-community-client
# Install MariaDB client as a fallback for MySQL compatibility.
RUN dnf install -y mariadb-connector-c mariadb

# Install Java to run the schema registry for the Avro case.
RUN dnf install -y \
    java-1.8.0-openjdk \
    java-1.8.0-openjdk-devel

# Copy Go from downloader.
COPY --from=downloader /usr/local/go /usr/local/go
ENV GOPATH /go
ENV GOROOT /usr/local/go
ENV PATH $GOPATH/bin:$GOROOT/bin:$PATH

WORKDIR /go/src/github.com/pingcap/tiflow
COPY . .

RUN --mount=type=cache,target=/root/.cache/go-build,target=/go/pkg/mod make integration_test_build cdc
COPY --from=downloader /root/download/bin/* ./bin/
RUN --mount=type=cache,target=/root/.cache/go-build,target=/go/pkg/mod make check_third_party_binary
