FROM debian:stable-slim

# Install stuff
RUN apt-get update \
    && apt-get install -y procps python3 python3-pip sudo vim \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3 1 \
    && printf '%%appuser ALL=(ALL:ALL) NOPASSWD:ALL\n' > /etc/sudoers.d/appuser

# Keeps Python from generating .pyc files in the container
ENV PYTHONDONTWRITEBYTECODE=1

# Turns off buffering for easier container logging
ENV PYTHONUNBUFFERED=1

# Do more Python stuff
RUN pip3 install Flask

WORKDIR /app
RUN mkdir src/
ADD main.py /app/src/

# Switching to a non-root user, please refer to https://aka.ms/vscode-docker-python-user-rights
RUN useradd -G sudo appuser -d /app \
    && chown -R appuser /app
USER appuser

CMD ["bash", "-c", "FLASK_APP=src/main.py flask run --host=0.0.0.0 --port=8080"]
