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

configure_postgresql_conf() {
    # Get the major version of PostgreSQL
    pg_version=$(psql -V | awk '{print $3}' | cut -d. -f1)

    # Adjust path based on PostgreSQL version
    config_path="/etc/postgresql/$pg_version/main/postgresql.conf"

    # Ensure listen_addresses is set to '*' to allow connections from any IP address
    if [[ -f "$config_path" ]]; then
        echo "Configuring listen_addresses in postgresql.conf to allow all IP addresses..."
        sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" "$config_path" || { echo "Failed to configure listen_addresses in postgresql.conf"; exit 1; }
        echo "listen_addresses configured successfully in postgresql.conf."
    else
        echo "PostgreSQL configuration file not found at $config_path"
        exit 1
    fi
}

configure_pg_hba() {
    # Get the major version of PostgreSQL
    pg_version=$(psql -V | awk '{print $3}' | cut -d. -f1)

    # Adjust path based on PostgreSQL version
    hba_path="/etc/postgresql/$pg_version/main/pg_hba.conf"

    # Ensure md5 authentication is enabled and allow all IP connections
    if [[ -f "$hba_path" ]]; then
        echo "Configuring pg_hba.conf to allow connections from any IP with md5 authentication..."
        sudo sed -i "s/local   all             postgres                                peer/local   all             postgres                                md5/g" "$hba_path" || { echo "Failed to configure pg_hba.conf for local connections"; exit 1; }

        # Allow connections from all IP addresses (IPv4)
        echo "host    all             all             0.0.0.0/0               md5" | sudo tee -a "$hba_path" || { echo "Failed to add entry for all IPv4 addresses"; exit 1; }

        # Optional: Allow non-SSL connections from all IP addresses (remove this line if SSL is required)
        echo "hostnossl    all             all             0.0.0.0/0               md5" | sudo tee -a "$hba_path" || { echo "Failed to add non-SSL entry"; exit 1; }

        # Allow connections from all IPv6 addresses (optional)
        echo "host    all             all             ::/0               md5" | sudo tee -a "$hba_path" || { echo "Failed to add entry for all IPv6 addresses"; exit 1; }

        echo "pg_hba.conf configured successfully."
    else
        echo "PostgreSQL configuration file not found at $hba_path"
        exit 1
    fi
}

set_postgres_password() {
    # Prompt for setting the postgres user password
    echo -e "\033[35mEnter the password you want to set for the 'postgres' superuser:\033[0m"
    read -s postgres_password

    # Set password for postgres superuser
    sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$postgres_password';" || { echo "Failed to set password for postgres user"; exit 1; }

    echo "Password for postgres user has been set successfully."
}

install_postgresql() {
    echo "Installing PostgreSQL..."
    sudo apt update || { echo "Failed to update packages list"; exit 1; }
    sudo apt install -y postgresql postgresql-contrib || { echo "Failed to install PostgreSQL"; exit 1; }

    sudo systemctl start postgresql || { echo "Failed to start PostgreSQL"; exit 1; }
    sudo systemctl enable postgresql || { echo "Failed to enable PostgreSQL"; exit 1; }

    # Configure postgresql.conf for all IP addresses
    configure_postgresql_conf

    # Configure pg_hba.conf for md5 password authentication and external connections
    configure_pg_hba

    # Set password for postgres user
    set_postgres_password

    # Restart PostgreSQL to apply password and config changes
    sudo systemctl restart postgresql || { echo "Failed to restart PostgreSQL"; exit 1; }

    echo "PostgreSQL installation and configuration complete."
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

        # Ask if the user wants to install pgvector
        echo -e "\033[35mWould you like to install the pgvector extension? (yes/no):\033[0m"
        read install_pgvector
        if [[ "$install_pgvector" == "yes" ]]; then
            add_postgresql_repository
            install_pgvector
        fi
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
