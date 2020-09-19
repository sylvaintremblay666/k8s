FROM alpine AS builder
RUN apk add build-base
WORKDIR /home
COPY ex.c .
RUN gcc "-DARCH=\"`uname -a`\"" ex.c -o ex
 
FROM alpine
WORKDIR /home
COPY --from=builder /home/ex .
ENTRYPOINT ["./ex"]
