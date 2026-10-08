FROM golang:1.26-alpine AS build
WORKDIR /src
COPY main.go .
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /hello main.go
FROM scratch
COPY --from=build /hello /hello
USER 10001:10001
EXPOSE 8080
ENTRYPOINT ["/hello"]
