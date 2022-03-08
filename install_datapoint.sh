#!/usr/bin/env bash

write_compose_m() {
cat > "/opt/yieldpoint/gdp/docker-compose.yml" <<- EndOfFile
version: '3'

volumes:
    pg_data:
    influx_data:
    django_logs:
services:
    postgres:
        restart: always
        image: $sourceAddress/gdp_postgres
        container_name: postgres
        volumes:
            - pg_data:/var/lib/postgresql/data
        ports:
            - "5432:5432"
    migrate:
        image: $sourceAddress/gdp_migrate
        container_name: migrate
        depends_on:
            - postgres
    django:
        restart: always
        image: $sourceAddress/gdp_django
        container_name: django
        environment:
            KAFKA_SERVER: $kafkaIP
            KAFKA_METHOD: $outputMethod
        ports:
            - "8000:8000"
        volumes:
            - django_logs:/var/log/apache2
            - django_logs:/var/log/gdp
        depends_on:
            - postgres
    influx:
        restart: always
        image: $sourceAddress/gdp_influx
        container_name: influx
        volumes:
            - influx_data:/var/lib/influxdb
        ports:
            - "8086:8086"
        depends_on:
            - django
EndOfFile
}

kafkaIP="NoServer"

outputMethod="string"

sourceAddress="yieldpointadmin"

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

    stty echo

    apt install -y curl
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt update
    apt-cache policy docker-ce
    apt install -y docker-ce
    curl -L https://github.com/docker/compose/releases/download/1.17.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    mkdir /opt/yieldpoint/
    mkdir /opt/yieldpoint/gdp/
    cd /opt/yieldpoint/gdp/

    write_compose_m

    docker-compose up -d

    sleep 20

    djangoContainer=$(echo -n $(echo -n | docker ps -f name=django | awk '{print $1}') | awk '{print $2}')

    docker exec -it $djangoContainer htpasswd -b -c /etc/apache2/.htpasswd $userName $password

    docker exec -it $djangoContainer /bin/bash /var/www/html/passchange.sh $userName $password #for new GDP

    printf "\n"
    printf "You should now have access to the GDP.\n"
    printf "Server IP: $serverIP\n"
    printf "Username: $userName\n"

else
    stty echo
    printf "Passwords do not match, please try again.\n"
fi
