# oneworld Explorer validator.
#
#   docker build -t rtw-validator .
#   docker run --rm -p 8080:8080 rtw-validator
#
# Single stage on purpose: there is nothing to compile. The airport table is
# committed, so the build needs no network and the image is reproducible from
# the repository alone.

# Pinned rather than :stable, which moves. Check the digest into the repo with
#   docker buildx imagetools inspect swipl:10.0.2
# if you want the build to be reproducible across registry changes.
FROM swipl:10.0.2

# tini reaps zombies and forwards signals. SWI's daemon handles SIGTERM itself,
# so this is belt-and-braces for anything it spawns; drop it and use
# `docker run --init` if you prefer.
RUN apt-get update \
 && apt-get install -y --no-install-recommends tini curl \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# The order matters for layer caching: data changes rarely, rules change often.
COPY prolog/data   ./prolog/data
COPY prolog/tools  ./prolog/tools
COPY prolog/src    ./prolog/src
COPY prolog/load.pl prolog/server.pl prolog/daemon.pl prolog/cli.pl ./prolog/
COPY web           ./web

# Fail the build, not the first request, if anything does not load. This also
# reads web/index.html into the program -- see the note in server.pl -- so a
# missing UI is a build error rather than a 404 in production.
RUN swipl -g "use_module('/app/prolog/server')" -g "halt(0)" -t "halt(1)"

# The image ships no test suite or fixtures; run those in CI against the source
# tree. Nothing under /app needs to be writable, so the container can run with
# --read-only.
RUN useradd --uid 10001 --no-create-home --shell /usr/sbin/nologin rtw \
 && chown -R root:root /app && chmod -R a=rX /app
USER 10001

EXPOSE 8080

# --no-fork keeps the daemon in the foreground so Docker owns the lifecycle and
# SIGTERM reaches it. --stack-limit bounds a runaway query into a resource
# error instead of the OOM killer taking the whole container; workers inherit
# it from the main thread.
#
# Exec form, so swipl is the signalled process rather than a shell.
ENTRYPOINT ["/usr/bin/tini", "--", \
            "swipl", "--stack-limit=512m", "/app/prolog/daemon.pl", "--no-fork"]
CMD ["--port=8080", "--workers=16"]

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -fsS http://localhost:8080/api/health || exit 1
