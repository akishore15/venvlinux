#!/bin/bash

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

# Function to build a Docker image with the HTTP server
build_image_with_file() {
  local distro=$1
  local tag=$2
  local dockerfile_dir="VENVLinuxBuild"

  echo "Preparing the Docker build directory..."
  mkdir -p "${dockerfile_dir}"
  cat <<EOF > "${dockerfile_dir}/Dockerfile"
FROM ${distro}:${tag}

# Install Python for the HTTP server
RUN apt-get update && apt-get install -y python3 && apt-get clean

# Add the LinuxLogo.svg to the container
COPY LinuxLogo.svg /LinuxLogo.svg

# Expose port 8000 for the HTTP server
EXPOSE 8000

# Start the HTTP server when the container runs
CMD ["python3", "-m", "http.server", "8000"]
EOF

  echo "Dockerfile created at ${dockerfile_dir}/Dockerfile."

  # Ensure the LinuxLogo.svg file exists
  if [ ! -f "LinuxLogo.svg" ]; then
    echo "LinuxLogo.svg not found in the current directory. Please ensure the file exists."
    exit 1
  fi

  # Copy the LinuxLogo.svg into build directory
  cp LinuxLogo.svg "${dockerfile_dir}/"

  # Build the Docker image
  echo "Building the Docker image..."
  docker build -t venv_image "${dockerfile_dir}"
  if [ $? -eq 0 ]; then
    echo "Docker image built successfully."
  else
    echo "Failed to build the Docker image."
    exit 1
  fi

  # Clean up build directory
  rm -rf "${dockerfile_dir}"
}

# Function to create and run the Docker container
create_and_run_container() {
  local container_name="venv"

  # Check if the container already exists
  if docker ps -a --format '{{.Names}}' | grep -w "${container_name}" &> /dev/null; then
    echo "A container named '${container_name}' already exists. Removing it..."
    docker rm -f "${container_name}"
  fi

  # Run the container
  echo "Creating and running the container '${container_name}'..."
  docker run -dit --name "${container_name}" -p 8000:8000 venv_image
  if [ $? -eq 0 ]; then
    echo "Container '${container_name}' is running. You can access LinuxLogo.svg at http://localhost:8000/LinuxLogo.svg"
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

# Build the Docker image
build_image_with_file "$distro" "$tag"

# Create and run the container
create_and_run_container
