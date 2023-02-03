export DOCKER_BUILDKIT=1
docker build -t aws-otel-flask-application --cache-from aws-otel-flask-application --build-arg BUILDKIT_INLINE_CACHE=1 .
