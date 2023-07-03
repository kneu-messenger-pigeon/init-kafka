ARG GO_VERSION=${GO_VERSION:-1.19}

FROM --platform=${BUILDPLATFORM:-linux/amd64} golang:${GO_VERSION}-alpine AS builder
ARG TARGETOS
ARG TARGETARCH
ARG BUILDPLATFORM

RUN apk update && apk add --no-cache git
WORKDIR /src
COPY ./go.mod ./go.sum ./
RUN go mod download
COPY . .
# Build the binary.
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -ldflags="-w -s" -tags=nomsgpack -o /app .
RUN /app > /topics.list

FROM --platform=${BUILDPLATFORM:-linux/amd64} docker.io/bitnami/kafka:3.4-debian-11

ENV KAFKA_HOST kafka:9092
ADD init.sh /init.sh
COPY --from=builder /topics.list topics.list

ENTRYPOINT /init.sh
