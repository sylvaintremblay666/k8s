FROM golang:alpine as builder

RUN apk add --update go git bash make gcc libc-dev
RUN go get -d github.com/google/cadvisor

WORKDIR /go/src/github.com/google/cadvisor
RUN make build

FROM alpine
COPY --from=builder /go/src/github.com/google/cadvisor/cadvisor .

CMD ["/cadvisor", "-logtostderr"]
