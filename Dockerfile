# USAGE:
#   git config --global core.pager "docker run --rm -i diff-so-fancy| less --tabs=4 -RFX"

FROM alpine
MAINTAINER Volker <lists.volker@gmail.com>

RUN apk --no-cache add perl ncurses git

ADD third_party/diff-highlight/diff-highlight /usr/local/bin/diff-highlight
ADD diff-so-fancy /usr/local/bin/diff-so-fancy

ENV TERM=vt100

ENTRYPOINT [ "/usr/local/bin/diff-so-fancy" ]
