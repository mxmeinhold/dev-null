FROM alpine:latest AS build
LABEL maintainer="Max Meinhold <mxmeinhold@gmail.com>"

RUN apk add --no-cache build-base bash

WORKDIR /usr/src/dev-null
COPY ./main.c Makefile ./
RUN make


FROM alpine:latest AS run
LABEL maintainer="Max Meinhold <mxmeinhold@gmail.com>"
ENV PORT=8080
EXPOSE 8080

WORKDIR /opt/dev-null/
COPY --from=build /usr/src/dev-null/dev-null .

USER 1001


CMD ["./dev-null"]
