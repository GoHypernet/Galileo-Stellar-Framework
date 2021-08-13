# get the go executable 
FROM golang as go

# geth the Galileo IDE and auth setup
FROM hypernetlabs/galileo-ide:linux AS galileo-ide
	
# Final build stage
FROM stellar/stellar-core:latest

# enable noninteractive installation of deadsnakes/ppa
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata

# install node, python, go, java, and other tools
RUN apt update -y && apt install vim tmux curl zip unzip supervisor git software-properties-common -y && \
	add-apt-repository -y ppa:deadsnakes/ppa && \
	apt-get update -y && \
	apt-get install -y python3.8 python3-pip python3-dev libsecret-1-dev && \
    curl -fsSL https://deb.nodesource.com/setup_12.x | bash - && \
	apt install -y nodejs && \
	curl https://rclone.org/install.sh | bash 

# get the go runtime
COPY --from=go /go /go
COPY --from=go /usr/local/go /usr/local/go
ENV PATH $PATH:/usr/local/go/bin:/home/galileo:/home/galileo/.local/bin
ENV GOPATH=/usr/local/go

RUN go get -u github.com/bitnami/bcrypt-cli

# add galileo non-root user
RUN useradd -ms /bin/bash galileo
COPY .theia /home/galileo/.theia

# get the stellar config/rclone/rclone
COPY --chown=galileo stellar-core.cfg /home/galileo/stellar-core.cfg

# get the IDE
COPY --from=galileo-ide --chown=galileo /.galileo-ide /home/galileo/.galileo-ide

# get the Caddy server executables and stuff
COPY --from=galileo-ide --chown=galileo /caddy/caddy /usr/bin/caddy
COPY --from=galileo-ide --chown=galileo /caddy/header.html /etc/assets/header.html
COPY --from=galileo-ide --chown=galileo /caddy/users.json /etc/gatekeeper/users.json
COPY --from=galileo-ide --chown=galileo /caddy/auth.txt /etc/gatekeeper/auth.txt
COPY --from=galileo-ide --chown=galileo /caddy/settings.template /etc/gatekeeper/assets/settings.template
COPY --from=galileo-ide --chown=galileo /caddy/login.template /etc/gatekeeper/assets/login.template
COPY --from=galileo-ide --chown=galileo /caddy/custom.css /etc/assets/custom.css
COPY --chown=galileo rclone.conf /home/galileo/.config/rclone/rclone.conf
COPY --chown=galileo Caddyfile /etc/
RUN chmod -R a+rwx /tmp/

# switch to non-root user
USER galileo
WORKDIR /home/galileo/.galileo-ide
	
# get superviserd
COPY supervisord.conf /etc/

# rclone configuration file 
COPY rclone.conf /home/galileo/.config/rclone/rclone.conf

# set environment variable to look for plugins in the correct directory
ENV THEIA_MINI_BROWSER_HOST_PATTERN {{hostname}}
ENV THEIA_WEBVIEW_EXTERNAL_ENDPOINT={{hostname}}
ENV SHELL=/bin/bash \
    THEIA_DEFAULT_PLUGINS=local-dir:/home/galileo/.galileo-ide/plugins
ENV USE_LOCAL_GIT true
ENV GALILEO_RESULTS_DIR /home/galileo

# set login credintials and write them to text file
ENV USERNAME "a"
ENV PASSWORD "a"
RUN sed -i 's,"username": "","username": "'"$USERNAME"'",1' /etc/gatekeeper/users.json && \
    sed -i 's,"hash": "","hash": "'"$(echo -n "$(echo $PASSWORD)" | bcrypt-cli -c 10 )"'",1' /etc/gatekeeper/users.json

ENTRYPOINT ["sh", "-c", "supervisord"]