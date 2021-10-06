#!/usr/bin/env bash

if [ "$(docker ps -a -f name=e621 | grep e621 | wc -l)" == "1" ]; then
    read -p "The container \"e621\" already exists, do you want to remove it? (y/N)? " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        echo "Exiting.."
        [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
    else
        echo "Removing.."
        docker stop e621
        docker rm e621
    fi
fi
docker run -p 127.3.6.21:80:80 -p 127.3.6.21:443:443 -v /opt/E621:/home/danbooru/danbooru -e RAILS_ENV=production --restart always --name e621 ubuntu:focal "/home/danbooru/danbooru/script/install_prod/install.sh"
