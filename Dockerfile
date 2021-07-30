FROM ubuntu:20.04

RUN apt update && apt install -y postfix sasl2-bin && \
    groupadd smtp

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 25
ENTRYPOINT /entrypoint.sh
