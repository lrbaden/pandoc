# syntax=docker/dockerfile:1


FROM pandoc/latex:latest as builder

ARG RELEASE="2.0.0"
ARG URL="https://github.com/Wandmalfarbe/pandoc-latex-template/releases/download/v${RELEASE}/Eisvogel-${RELEASE}.tar.gz"

# Set work directory
WORKDIR /usr/src/

# Copy context
COPY . .

# install dependencies
RUN tlmgr update --self && \
    tlmgr install $(cat requirements.txt | tr -s [:space:] ' ') && \
    mkdir -p scripts/ && \
    wget -q "https://raw.githubusercontent.com/lrbaden/memoir-mgr/main/scripts/compile_partials.sh" -O scripts/compile_partials.sh && \
    chmod -R +x scripts

# download Eisvogel template
RUN mkdir -p "eisvogel/"  && \  
    wget -q "$URL" -O - | tar xz -C "eisvogel/"



FROM pandoc/latex:latest 

ARG TEMPLATE="/root/.local/share/pandoc/templates/eisvogel.latex"

# Copy source from builder
COPY --from=builder --chown=root /opt/texlive/ /opt/texlive/
COPY --from=builder --chown=root /usr/src/eisvogel/eisvogel.latex "$TEMPLATE"
COPY --from=builder --chown=root /usr/src/eisvogel/examples/ /data/
COPY --from=builder --chown=root /usr/src/scripts/ /usr/src/scripts/

# Create symlink
RUN for f in $(ls /usr/src/scripts/*.sh); do \
        fname="${f##*/}"; name="${fname%.sh}"; link="/usr/local/bin/$name"; \
        ln -s  "$f" "$link"; done

# Create entrypoint
RUN echo -e '#! /bin/sh\n\nexec "$@"' > /entrypoint.sh && \
    chmod 755 /entrypoint.sh

#  Set entrypoint
ENTRYPOINT [ "/entrypoint.sh" ]
