#!/bin/bash
# Developer: Sonny Mir
# License: MIT 
# Written for all my brothers and sisters <3.
# This script manages the installation and uninstallation of PostgreSQL and the pgvector extension.
# Usage:
# ./script_name.sh install    # To install PostgreSQL and optionally pgvector.
# ./script_name.sh uninstall  # To uninstall PostgreSQL.


install_postgresql() {
    echo "Installing PostgreSQL..."
    sudo apt-get update || { echo "Failed to update packages list"; exit 1; }
    sudo apt-get install -y postgresql postgresql-contrib || { echo "Failed to install PostgreSQL"; exit 1; }

    sudo systemctl start postgresql || { echo "Failed to start PostgreSQL"; exit 1; }
    sudo systemctl enable postgresql || { echo "Failed to enable PostgreSQL"; exit 1; }

    # Prompt for username and password in magenta color
    echo -e "\033[35mEnter the username for the PostgreSQL superuser:\033[0m"
    read username
    echo -e "\033[35mEnter the password for the PostgreSQL superuser:\033[0m"
    read -s password
    echo


    sudo -u postgres sh -c "cd /tmp && psql -c \"CREATE ROLE $username WITH SUPERUSER CREATEDB CREATEROLE LOGIN PASSWORD '$password';\"" || { echo "Failed to create PostgreSQL role"; exit 1; }


    local version_dir=$(ls /etc/postgresql)
    sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" "/etc/postgresql/${version_dir}/main/postgresql.conf" || { echo "Failed to configure PostgreSQL to listen on all IP addresses"; exit 1; }


    echo "host all all 0.0.0.0/0 md5" | sudo tee -a "/etc/postgresql/${version_dir}/main/pg_hba.conf" || { echo "Failed to update pg_hba.conf"; exit 1; }

    sudo systemctl restart postgresql || { echo "Failed to restart PostgreSQL"; exit 1; }
    echo "PostgreSQL installation and configuration complete."


    echo -e "\033[35mWould you like to install the pgvector extension? (yes/no):\033[0m"
    read install_pgvector
    if [[ "$install_pgvector" == "yes" ]]; then
        install_pgvector
    fi
}


install_pgvector() {
    echo "Installing pgvector..."
    sudo apt-get install -y postgresql-15-pgvector || { echo "Failed to install pgvector"; exit 1; }
    sudo systemctl restart postgresql || { echo "Failed to restart PostgreSQL after installing pgvector"; exit 1; }
    echo "pgvector installation complete."
}


uninstall_postgresql() {
    echo "Uninstalling PostgreSQL..."
    sudo systemctl stop postgresql || { echo "Failed to stop PostgreSQL"; exit 1; }
    sudo apt-get purge -y postgresql postgresql-contrib postgresql-common || { echo "Failed to purge PostgreSQL packages"; exit 1; }
    sudo apt-get autoremove -y || { echo "Failed to remove obsolete packages"; exit 1; }
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
