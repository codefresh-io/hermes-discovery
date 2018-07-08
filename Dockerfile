#------ helm/kubectl ----
FROM dtzar/helm-kubectl:2.9.1 as helm

#------- hermes discovery ------
#
FROM alpine:3.8

RUN apk add --no-cache jq bash

COPY --from=helm /usr/local/bin/kubectl /usr/bin/

COPY discovery.sh /usr/bin
RUN chmod +x /usr/bin/discovery.sh

CMD ["/usr/bin/discovery.sh"]