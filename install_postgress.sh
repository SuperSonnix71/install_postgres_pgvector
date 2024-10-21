#!/bin/bash
# Developer: Sonny Mir
# License: MIT 
# Written for all my brothers and sisters <3.
# This script manages the installation and uninstallation of PostgreSQL and the pgvector extension.
# Usage:
# ./script_name.sh install    # To install PostgreSQL and optionally pgvector.
# ./script_name.sh uninstall  # To uninstall PostgreSQL.


add_postgresql_repository() {
    echo "Adding PostgreSQL official repository..."
    # Add PostgreSQL's signing key
    wget -qO - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - || { echo "Failed to add PostgreSQL key"; exit 1; }

    # Add PostgreSQL Apt repository for your system
    sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' || { echo "Failed to add PostgreSQL repository"; exit 1; }

    # Update package list
    sudo apt update || { echo "Failed to update package lists after adding PostgreSQL repository"; exit 1; }

    echo "PostgreSQL repository added successfully."
}

install_postgresql() {
    echo "Installing PostgreSQL..."
    sudo apt update || { echo "Failed to update packages list"; exit 1; }
    sudo apt install -y postgresql postgresql-contrib || { echo "Failed to install PostgreSQL"; exit 1; }

    sudo systemctl start postgresql || { echo "Failed to start PostgreSQL"; exit 1; }
    sudo systemctl enable postgresql || { echo "Failed to enable PostgreSQL"; exit 1; }

    echo -e "\033[35mWould you like to create a new PostgreSQL superuser or use the default 'postgres' superuser? (new/postgres):\033[0m"
    read user_choice

    if [[ "$user_choice" == "new" ]]; then
        echo -e "\033[35mEnter the username for the new PostgreSQL superuser:\033[0m"
        read username
        echo -e "\033[35mEnter the password for the new PostgreSQL superuser:\033[0m"
        read -s password
        echo

        sudo -u postgres sh -c "cd /tmp && psql -c \"CREATE ROLE $username WITH SUPERUSER CREATEDB CREATEROLE LOGIN PASSWORD '$password';\"" || { echo "Failed to create PostgreSQL role"; exit 1; }

        echo "New superuser '$username' has been created."
    else
        echo "Using the default 'postgres' superuser account."
    fi

    # Get the major version of PostgreSQL
    pg_version=$(psql -V | awk '{print $3}' | cut -d. -f1)

    # Adjust path based on PostgreSQL version
    config_path="/etc/postgresql/$pg_version/main/postgresql.conf"
    hba_path="/etc/postgresql/$pg_version/main/pg_hba.conf"

    if [[ -f "$config_path" ]]; then
        sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" "$config_path" || { echo "Failed to configure PostgreSQL to listen on all IP addresses"; exit 1; }
        echo "host all all 0.0.0.0/0 md5" | sudo tee -a "$hba_path" || { echo "Failed to update pg_hba.conf"; exit 1; }

        sudo systemctl restart postgresql || { echo "Failed to restart PostgreSQL"; exit 1; }
        echo "PostgreSQL installation and configuration complete."
    else
        echo "PostgreSQL configuration file not found at $config_path"
        exit 1
    fi

    echo -e "\033[35mWould you like to install the pgvector extension? (yes/no):\033[0m"
    read install_pgvector
    if [[ "$install_pgvector" == "yes" ]]; then
        add_postgresql_repository
        install_pgvector
    fi
}


install_pgvector() {
    echo "Installing pgvector..."

    # Get the PostgreSQL version to install the correct pgvector package
    pg_version=$(psql -V | awk '{print $3}' | cut -d. -f1)

    # Determine the correct pgvector package based on PostgreSQL version
    if [[ "$pg_version" == "12" || "$pg_version" == "13" || "$pg_version" == "14" || "$pg_version" == "15" || "$pg_version" == "16" || "$pg_version" == "17" ]]; then
        sudo apt install -y "postgresql-$pg_version-pgvector" || { echo "Failed to install pgvector for PostgreSQL $pg_version"; exit 1; }
    else
        echo "Unsupported PostgreSQL version $pg_version. Unable to install pgvector."
        exit 1
    fi

    sudo systemctl restart postgresql || { echo "Failed to restart PostgreSQL after installing pgvector"; exit 1; }

    # Load the extension into the default postgres database
    sudo -u postgres psql -c "CREATE EXTENSION IF NOT EXISTS vector;" || { echo "Failed to create pgvector extension"; exit 1; }

    echo "pgvector installation complete."
}


uninstall_postgresql() {
    echo "Uninstalling PostgreSQL..."
    sudo systemctl stop postgresql || { echo "Failed to stop PostgreSQL"; exit 1; }
    sudo apt purge -y postgresql postgresql-contrib postgresql-common || { echo "Failed to purge PostgreSQL packages"; exit 1; }
    sudo apt autoremove -y || { echo "Failed to remove obsolete packages"; exit 1; }
    echo "PostgreSQL has been removed."
}


show_help() {
    echo "Usage: $0 {install|uninstall}"
    echo "install: Installs PostgreSQL and optionally the pgvector extension."
    echo "uninstall: Completely removes PostgreSQL and all its configurations."
}


case "$1" in
    install)
        install_postgresql
        ;;
    uninstall)
        uninstall_postgresql
        ;;
    help)
        show_help
        ;;
    *)
        show_help
        exit 1
        ;;
esac
