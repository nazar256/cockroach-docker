FROM golang:1.19-bullseye as prebuild
WORKDIR /home
ADD main.go .
RUN CGO_ENABLED=0 go build -o hello ./main.go

FROM alpine
COPY --from=prebuild /home/hello /hello
CMD ["/hello"]
