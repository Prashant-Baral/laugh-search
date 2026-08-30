FROM docker.io/searxng/searxng:latest

COPY searxng/settings.yml /etc/searxng/settings.yml

COPY searxng/assets/favicon.png /usr/local/searxng/searx/static/themes/simple/img/favicon.png
COPY searxng/assets/favicon.png /usr/local/searxng/searx/static/themes/simple/img/favicon.ico
COPY searxng/assets/logo.png    /usr/local/searxng/searx/static/themes/simple/img/logo.svg
COPY searxng/assets/logo.png    /usr/local/searxng/searx/static/themes/simple/img/searxng.png
COPY searxng/assets/logo.png    /usr/local/searxng/searx/static/themes/simple/img/searxng.svg

COPY searxng/assets/favicon-wrapped.svg     /usr/local/searxng/searx/static/themes/simple/img/favicon.svg
COPY searxng/assets/favicon-wrapped.svg.gz  /usr/local/searxng/searx/static/themes/simple/img/favicon.svg.gz
COPY searxng/assets/favicon-wrapped.svg.br  /usr/local/searxng/searx/static/themes/simple/img/favicon.svg.br
