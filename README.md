# PostgreSQL Installation Script

## Description

This script automates the installation and uninstallation of PostgreSQL on Ubuntu systems, along with an optional extension, pgvector. It simplifies the PostgreSQL setup process, configuring the server to listen on all IP addresses and managing user roles with superuser privileges. Specifically designed for Ubuntu, this script is also suitable for other Debian-based distributions that use `apt-get` for package management.

## Developer

Developed by Sonny Mir.

## License

This script is released under the MIT License.

## Features

- **Install PostgreSQL**: Sets up PostgreSQL and its contrib packages, starts and enables the service, configures the server to listen on all IP addresses, and creates a superuser with specified credentials.
- **Optional pgvector Extension**: Offers the option to install the pgvector extension, enhancing PostgreSQL with vector database capabilities.
- **Uninstall PostgreSQL**: Removes PostgreSQL and all associated data and configurations.

## Usage

To use the script, run it with one of the following commands depending on the desired operation:

```
./install_postgress.sh install - Installs PostgreSQL and prompts whether to install the pgvector extension.`
```

```
./install_postgress.sh uninstall - Completely removes PostgreSQL and all its configurations.`
```

```
`./install_postgress help - Displays usage information.`
```

### Install Command

1. Updates the package list.
2. Installs PostgreSQL and its contrib packages.
3. Starts and enables PostgreSQL service.
4. Prompts for the superuser username and password (credentials are entered in a secure manner without displaying the password).
5. Sets up PostgreSQL to accept connections on all network interfaces.
6. Optionally installs the pgvector extension if the user agrees.

### Uninstall Command

1. Stops the PostgreSQL service.
2. Purges PostgreSQL packages and their dependencies.
3. Removes obsolete packages to clean up the system.

## System Requirements

- The script is intended for use on systems running Ubuntu or other Debian-based distributions that use `apt-get` for package management.
- Administrative (sudo) privileges are required to install and remove software packages.

## Notes

- This script should be run from a directory that the executing user has permissions to access, or it may result in permission errors.
- Ensure that you have internet access and your package lists are up to date to avoid errors during package installation.

## Dedication

Written for all my brothers and sisters ❤️.
