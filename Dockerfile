FROM golang:bullseye as base
WORKDIR $GOPATH/src
COPY . .
RUN go mod download && go mod verify && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /main .

FROM alpine
RUN adduser \
  --disabled-password \
  --gecos "" \
  --home "/home" \
  --shell "/sbin/nologin" \
  --no-create-home \
  --uid 65532 \
  main-user
USER main-user:main-user
COPY --from=base /main .
CMD ["./main"]