#FROM gcr.io/educative-exec-env/educative-ubuntu-microvm:latest
FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive

## installing docker and docker compose, required for Chapter 4,5,6
#RUN apt-get update && apt-get install -y docker.io &&\
# apt-get install -y curl && apt-get install -y wget &&\
# curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose && ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose


#RUN apt-get update &&\
#    apt-get install -y wget make gcc gnupg2 lsof &&\
#    apt install -y postgresql postgresql-contrib &&\
#    rm -rf /var/lib/apt/lists/* 

RUN wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb &&\
    dpkg -i erlang-solutions_2.0_all.deb || true


RUN  apt-get update
# && apt-get -y install tmux

RUN apt install -y nodejs &&\
    apt install -y npm &&\
    apt-get install -y inotify-tools

RUN apt-get install -y erlang 22.0 &&\
   apt-get install -y elixir 

RUN   mix local.hex --force &&\
     mix local.rebar --force 

RUN mix archive.install hex phx_new 1.5.12

COPY . /code

#EXPOSE 4040

#ENTRYPOINT ["service","docker","start"]

