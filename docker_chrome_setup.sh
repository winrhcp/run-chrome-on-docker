#!/bin/bash

show() {
  echo -e "\033[1;35m$1\033[0m"
}

if ! [ -x "$(command -v curl)" ]; then
  show "curl is not installed. Please install it to continue."
  exit 1
else
  show "curl is already installed."
fi

IP=$(curl -s ifconfig.me)

read -p "Enter a username: " USERNAME
read -sp "Enter a password: " PASSWORD

CREDENTIALS_FILE="$HOME/vps-browser-credentials.json"
cat <<EOL > "$CREDENTIALS_FILE"
{
  "username": "$USERNAME",
  "password": "$PASSWORD"
}
EOL

show "Credentials saved to $CREDENTIALS_FILE."

if ! [ -x "$(command -v docker)" ]; then
  show "Docker is not installed. Installing Docker..."
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  if [ -x "$(command -v docker)" ]; then
    show "Docker installation was successful."
  else
    show "Docker installation failed."
    exit 1
  fi
else
  show "Docker is already installed."
fi

show "Pulling the latest Chromium Docker image..."
if ! docker pull linuxserver/chromium:latest; then
  show "Failed to pull the Chromium Docker image."
  exit 1
else
  show "Successfully pulled the Chromium Docker image."
fi

mkdir -p "$HOME/chromium/config"

if [ "$(docker ps -q -f name=browser)" ]; then
    show "The Chromium Docker container is already running."
else
    show "Running Chromium Docker Container..."
    docker run -d --name browser -e TITLE=VPSCHROME -e DISPLAY=:1 -e PUID=1000 -e PGID=1000 -e CUSTOM_USER="$USERNAME" -e PASSWORD="$PASSWORD" -e LANGUAGE=en_US.UTF-8 -v "$HOME/chromium/config:/config" -p 3210:3000 -p 3211:3001 --shm-size="1gb" --restart unless-stopped lscr.io/linuxserver/chromium:latest
    if [ $? -eq 0 ]; then
        show "Chromium Docker container started successfully."
    else
        show "Failed to start the Chromium Docker container."
    fi
fi

show "Click on this http://$IP:3210/ or https://$IP:3211/ to run the browser externally"
show "Input this username: $USERNAME in the browser"
show "Input this password: $PASSWORD in the browser"
show "Make sure to copy these credentials in order to access the browser externally. You can also get your this browser's credentials from $CREDENTIALS_FILE"
