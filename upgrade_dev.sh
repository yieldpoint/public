#!/usr/bin/env bash
write_reboot() {
cat > "/home/ubuntu/reboot.sh" <<- EndOfFile
cd /opt/yieldpoint/gdp
docker-compose down
# docker rmi -f gdp_django_dev
# docker rmi -f gdp_ember_dev
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
        image: yieldpointadmin/gdp_migrate
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
            - django_logs:/var/log/apache2
            - django_logs:/var/log/gdp
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
cp ./dump.sql ./dump.sql_backup
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