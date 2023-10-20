#!/usr/bin/env bash

# Check if directory exists, if not create it
if [ ! -d "/home/ubuntu/migration_backups" ]; then
  mkdir -p /home/ubuntu/migration_backups
fi

# Check if directory exists, if not create it
if [ ! -d "/opt/yieldpoint/gdp" ]; then
  mkdir -p /opt/yieldpoint/gdp
fi
cd /opt/yieldpoint/gdp

write_reboot() {
cat > "/home/ubuntu/reboot.sh" <<- EndOfFile
cd /opt/yieldpoint/gdp
docker-compose down
docker-compose up -d
EndOfFile
}


write_compose_2() {
cat > "/opt/yieldpoint/gdp/docker-compose.yml" <<- EndOfFile
version: '3'

volumes:
    pg_data:
    influx_data:
    django_logs:
    ember_logo:
    ember_data:
    alerts_data:
services:
    postgres:
        restart: always
        image: yieldpointadmin/gdp_postgres
        container_name: postgres
        volumes:
            - pg_data:/var/lib/postgresql/data
        ports:
            - "5432:5432"
    migrate:
        image: yieldpointadmin/gdp_migrate_dev
        container_name: migrate
        depends_on:
            - postgres
        volumes:
            - /home/ubuntu/migration_backups:/home/ubuntu/migration_backups
    django:
        restart: always
        image: yieldpointadmin/gdp_django_dev
        container_name: django
        ports:
            - "8000:8000"
        volumes:
            - /var/log/gdp:/var/log/apache2
            - /var/log/gdp:/var/log/gdp
        depends_on:
            - postgres
    ember:
        restart: always
        image: yieldpointadmin/gdp_ember_dev
        container_name: ember
        ports:
            - "80:80"
        environment:
            API_URL: $url:8000
        volumes:
            - ember_logo:/var/www/html/assets/images/customer_logo
            - ember_data:/etc/apache2/
        depends_on:
            - django
    alerts:
        restart: always
        image: yieldpointadmin/gdp_alerts
        container_name: alerts
        environment:
            SERVER_URL: $url
        volumes:
            - alerts_data:/app/token/
        depends_on:
            - django
    influx:
        restart: always
        image: yieldpointadmin/gdp_influx
        container_name: influx
        volumes:
            - influx_data:/var/lib/influxdb
        ports:
            - "8086:8086"
        depends_on:
            - django
EndOfFile
}

printf "Enter Server URL (eg. http://test.yieldpoint.com): "

read url

printf "Enter Username [Blank for defaults]: "

read userName

if [ "$userName" != "" ]; then

    stty -echo
    printf "Enter Password: "

    read password

    printf "\nConfirm Password: "

    read password2

    printf "\n"
else
    password="default"
    password2="default"
fi


mv docker-compose.yml docker-compose.yml.bak
write_reboot
write_compose_2

if [ $? -eq 0 ]; then
  echo "write_compose_2 was successful"
else
  echo "write_compose_2 failed"
  exit 1
fi

docker-compose pull migrate
docker-compose up migrate
docker-compose exec postgres pg_dump --clean -U yieldpoint -d gdp > dump.sql
docker-compose pull postgres
docker-compose down
docker volume rm gdp_pg_data
docker volume rm gdp_ember_data
docker-compose up -d postgres
sleep 15
docker-compose up migrate

# Directory where backups will be stored
backup_dir="/home/ubuntu/postgres_backups"
# Check if directory exists, if not create it
if [ ! -d "${backup_dir}" ]; then
  mkdir -p ${backup_dir}
fi

# Get the current date and time in the desired format
current_datetime=$(date +"%b_%d_%Y_%H_%M_%S")
# Create the backup file name with directory path
backup_filename="${backup_dir}/dump.sql_backup_${current_datetime}"
# Copy the dump.sql file to the new backup file
cp dump.sql ${backup_filename}

cp dump.sql /var/lib/docker/volumes/gdp_pg_data/_data/
docker-compose exec postgres bash -c 'cd /var/lib/postgresql/data ; psql -U yieldpoint -d gdp < dump.sql'

if [ "$password" = "$password2" ]; then
    if [ "$userName" = "" ]; then
	userName="yieldpoint"
	password="YPfuture"
        credentials="eWllbGRwb2ludDpZUGZ1dHVyZQ=="
    else
        credentials=$(echo -n "$userName:$password" | base64)
    fi

    stty echo  

    docker-compose up -d

    docker exec -it ember htpasswd -b -c /etc/apache2/.htpasswd $userName $password
    docker exec -it django htpasswd -b -c /etc/apache2/.htpasswd $userName $password

    sleep 3

    docker exec -it django /bin/bash /var/www/html/passchange.sh $userName $password #for new GDP

    printf "\n"
    printf "You should now have access to VantagePoint.\n"
    printf "Username: $userName\n"
else
    stty echo
    printf "Passwords do not match, please try again.\n"
fi