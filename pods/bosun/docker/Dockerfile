#FROM alpine
FROM debian:stretch-slim

#ENV        SCOLLECTOR_VERSION="0.5.0-rc3"

#RUN        apk add --update wget
RUN apt update && apt install -y wget rsyslog

RUN wget https://github.com/bosun-monitor/bosun/releases/download/0.8.0-preview/bosun-linux-amd64
RUN chmod 755 bosun-linux-amd64

COPY bosun.toml /
COPY dev.sample.conf /
#WORKDIR    /go/src/bosun.org/cmd/bosun
#RUN        git checkout ${SCOLLECTOR_VERSION}

#WORKDIR    /go
#RUN        go install bosun.org/cmd/bosun
#RUN        mkdir -p /scollector
#COPY       run.sh /scollector/
#RUN        chmod +x /scollector/run.sh

#CMD ["/scollector/run.sh"]
#CMD tail -f /dev/null
CMD ["/bosun-linux-amd64"]
