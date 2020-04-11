FROM golang:1.6.2-alpine

ENV        SCOLLECTOR_VERSION="0.5.0-rc3"

RUN        apk add --update go git
RUN        go get -d bosun.org/cmd/scollector

WORKDIR    /go/src/bosun.org/cmd/bosun
RUN        git checkout ${SCOLLECTOR_VERSION}

WORKDIR    /go
RUN        go install bosun.org/cmd/scollector
RUN        mkdir -p /scollector
COPY       run.sh /scollector/
RUN        chmod +x /scollector/run.sh

CMD ["/scollector/run.sh"]
