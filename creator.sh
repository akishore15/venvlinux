#!/bin/bash

echo "Welcome to VENVLinux's VENV creator!"
# Function to check if the user is in the sudo group
check_sudo_access() {
  if sudo -n true 2>/dev/null; then
    echo "You have sudo access."
  else
    echo "You do not have sudo access. Attempting to add you to the sudo group..."
    add_user_to_sudo
  fi
}

# Function to add the current user to the sudo group
add_user_to_sudo() {
  local username=$(whoami)

  echo "Adding $username to the sudo group. This requires admin privileges."
  su -c "usermod -aG sudo $username"

  if [ $? -eq 0 ]; then
    echo "Successfully added $username to the sudo group. Please log out and log back in for the changes to take effect."
    exit 0
  else
    echo "Failed to add $username to the sudo group. Please contact your administrator or try again with proper privileges."
    exit 1
  fi
}

# Function to check if Docker is installed
check_docker_installed() {
  if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Attempting to install Docker..."
    install_docker
  else
    echo "Docker is already installed."
  fi
}

# Function to install Docker
install_docker() {
  # Update the package list
  echo "Updating the package list..."
  sudo apt-get update -y

  # Install prerequisites for Docker
  echo "Installing prerequisites..."
  sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

  # Add Docker's official GPG key
  echo "Adding Docker's official GPG key..."
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

  # Add Docker's APT repository
  echo "Adding Docker's repository..."
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  # Update the package list again
  echo "Updating the package list again..."
  sudo apt-get update -y

  # Install Docker
  echo "Installing Docker..."
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io

  # Verify Docker installation
  if command -v docker &> /dev/null; then
    echo "Docker has been successfully installed."
  else
    echo "Docker installation failed. Please install Docker manually and try again."
    exit 1
  fi
}

# Function to pull the Docker image and create the container
create_container() {
  local distro=$1
  local tag=$2
  local container_name="venv"

  # Pull the Docker image
  echo "Pulling image ${distro}:${tag}..."
  docker pull "${distro}:${tag}"
  if [ $? -ne 0 ]; then
    echo "Failed to pull the image ${distro}:${tag}. Please check the distribution and tag."
    exit 1
  fi

  # Create and run the container
  echo "Creating and running the container '${container_name}'..."
  docker run -dit --name "${container_name}" "${distro}:${tag}"
  if [ $? -eq 0 ]; then
    echo "Container '${container_name}' created and running successfully."
  else
    echo "Failed to create and run the container '${container_name}'."
    exit 1
  fi
}

# Main script
echo "This script will help you create a Docker container named 'venv'."

# Check if the user has sudo access
check_sudo_access

# Check if Docker is installed (and install if not)
check_docker_installed

# Prompt the user for the Linux distribution and tag
read -p "Enter the Linux distribution (e.g., ubuntu, debian): " distro
read -p "Enter the tag for the distribution (e.g., latest, 20.04): " tag

# Validate inputs
if [[ -z "$distro" || -z "$tag" ]]; then
  echo "Both distribution and tag are required. Please try again."
  exit 1
fi

# Create the container
create_container "$distro" "$tag"
