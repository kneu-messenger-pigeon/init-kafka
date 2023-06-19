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

FROM docker.io/bitnami/kafka:3.3

ENV KAFKA_HOST kafka:9092
COPY --from=builder /topics.list topics.list

ADD init.sh /init.sh
ENTRYPOINT /init.sh
