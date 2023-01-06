#!/usr/bin/env bash
write_reboot() {
cat > "/home/ubuntu/reboot.sh" <<- EndOfFile
cd /opt/yieldpoint/gdp
docker-compose down
docker-compose up -d
EndOfFile
}


write_compose_2() {
cat > "/opt/yieldpoint/gdp/docker-compose.yml" <<- EndOfFile
version: '2'

volumes:
    pg_data:
    alerts_data:
services:
    postgres:
        restart: always
        image: yieldpointadmin/gdp_postgres_dev
        container_name: postgres
        volumes:
            - pg_data:/var/lib/postgresql/data
        ports:
            - "5432:5432"
    migrate:
        image: yieldpointadmin/gdp_migrate
        container_name: migrate
        depends_on:
            - postgres
    django:
        restart: always
        image: yieldpointadmin/gdp_django
        container_name: django
        environment:
            KAFKA_SERVER: NoServer
            KAFKA_METHOD: JSON
            IOT_LOG: "true"
        ports:
            - "8000:8000"
            - "8443:8443"
        volumes:
            - /var/log/gdp/apache2:/var/log/apache2
            - /var/log/gdp:/var/log/gdp
            - /opt/yieldpoint/gdp/cert:/var/webcerts
        depends_on:
            - postgres
    influx:
        restart: always
        image: updates.yieldpoint.com:5000/gdp_influx
        container_name: influx
        volumes:
            - /var/lib/gdp/influx:/var/lib/influxdb
        ports:
            - "8086:8086"
#        depends_on:
#            - django
    alerts:
        restart: always
        image: yieldpointadmin/gdp_alerts
        container_name: alerts
        environment:
            SERVER_URL: "http://testtwo.yieldpoint.com"
        volumes:
            - alerts_data:/app/token
        ports:
            - "587:587"
            - "8080:8080"
        depends_on:
            - influx
    gdp_backup: #optional container
        restart: always
        image: updates.yieldpoint.com:5000/gdp_backup
        container_name: gdp_backup
        environment:
            GDP_BACKUP_HOST: 18.118.101.31
            GDP_BACKUP_USER: yieldpoint
            GDP_BACKUP_PASSWORD: YPfuture

            GDP_BACKUP_FORMAT: csv2
            GDP_BACKUP_IS_INCREMENTIVE: 1
            GDP_BACKUP_IS_NEW_FOLDER_PER_RUN: 0

            GDP_BACKUP_DIR: /var/lib/gdp/backups/data
            GDP_BACKUP_STATUS_FILE: /var/lib/gdp/backups/backup_status.csv

            GDP_BACKUP_CRON_PERIOD: "30 2 * * *"
        volumes:
            - /var/lib/gdp/backups:/var/lib/gdp/backups
            - /var/log/gdp:/var/log/gdp

EndOfFile
}

write_reboot

cd /opt/yieldpoint/gdp
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
cp dump.sql /var/lib/docker/volumes/gdp_pg_data/_data/
docker-compose exec postgres bash -c 'cd /var/lib/postgresql/data ; psql -U yieldpoint -d gdp < dump.sql'

mv docker-compose.yml docker-compose.yml.bak

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

if [ "$password" = "$password2" ]; then
    if [ "$userName" = "" ]; then
	userName="yieldpoint"
	password="YPfuture"
        credentials="eWllbGRwb2ludDpZUGZ1dHVyZQ=="
    else
        credentials=$(echo -n "$userName:$password" | base64)
    fi

    stty echo

    write_compose_2

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