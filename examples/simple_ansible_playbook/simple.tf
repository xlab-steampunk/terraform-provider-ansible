terraform {
  required_providers {
    ansible = {
      source  = "ansible/ansible"
      version = "~> 1.0.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}


# ===============================================
# Create a docker image using a Dockerfile
# ===============================================
resource "docker_image" "julia" {
  name = "alpine:latest"
  build {
    context    = "."
    dockerfile = "Dockerfile"
  }
}

resource "docker_container" "julia_the_first" {
  image             = docker_image.julia.image_id
  name              = "julia-the-first"
  must_run          = true

  # Make sure that this docker doesn't stop running
  command = [
    "sleep",
    "infinity"
  ]
}


# ===============================================
#  Create docker containers to use as our hosts
# ===============================================
resource "docker_container" "julia_the_second" {
  image             = docker_image.julia.image_id
  name              = "julia-the-second"
  must_run          = true

  # Make sure that this docker doesn't stop running
  command = [
    "sleep",
    "infinity"
  ]
}

resource "ansible_playbook" "example" {
  ansible_playbook_binary = "ansible-playbook"  # this parameter is optional, default is "ansible-playbook"
  playbook                = "simple-playbook.yml"

  # Inventory configuration
  name   = docker_container.julia_the_first.name  # name of the host to use for inventory configuration
  groups = ["playbook-group-1", "playbook-group-2"]  # list of groups to add our host to

  # Ansible vault
  vault_password_file = "vault-password-file.txt"
  vault_id            = "examplevault"
  vault_files = [
    "vault-encrypted.yml",
  ]

  # Play control
  # Configure our playbook execution, to run only tasks with specified tags.
  # in this example, we have only one tag; "tag1".
  tags = [
    "tag1"
  ]

  # Limit this playbook to run only on the host named "julia-the-first"
  limit = [
    docker_container.julia_the_first.name
  ]
  check_mode = false
  diff_mode  = false
  var_files = [
    "var-file.yml"
  ]

  # Connection configuration and other vars
  extra_vars = {
    ansible_hostname   = docker_container.julia_the_first.name
    ansible_connection = "docker"
  }

  replayable = true
  verbosity  = 3  # set the verbosity level of the debug output for this playbook
}

resource "ansible_playbook" "example_2" {
  playbook = "simple-playbook.yml"

  # inventory configuration
  name   = docker_container.julia_the_second.name
  groups = ["playbook-group-2"]

  # ansible vault
  vault_password_file = "vault-password-file.txt"
  vault_id            = "examplevault"
  vault_files = [
    "vault-encrypted.yml",
  ]

  # play control
  tags = [
    "tag2"
  ]
  limit = [
    docker_container.julia_the_second.name
  ]
  check_mode = false
  diff_mode  = false
  var_files = [
    "var-file.yml"
  ]

  # connection configuration and other vars
  extra_vars = {
    ansible_hostname   = docker_container.julia_the_second.name
    ansible_connection = "docker"
    injected_var = ""
  }
}