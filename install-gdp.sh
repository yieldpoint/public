#!/usr/bin/env bash

write_compose_m_b() {
cat > "/opt/yieldpoint/gdp/docker-compose.yml" <<- EndOfFile
version: '3'

volumes:
    pg_data:
    influx_data:
    django_logs:
    ember_logo:
    ember_data:
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
    ember:
        restart: always
        image: $sourceAddress/gdp_ember
        container_name: ember
        environment:
            API_URL: http://$serverIP:8000
            API_CREDENTIALS: "$credentials"
        ports:
            - "80:80"
        volumes:
            - ember_logo:/var/www/html/assets/images/customer_logo
            - ember_data:/etc/apache2/
        depends_on:
            - django
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
    gdp_backup: #optional container
        restart: always
        image: $sourceAddress/gdp_backup
        container_name: gdp_backup
        environment:
            GDP_BACKUP_HOST: $backupIP
            GDP_BACKUP_USER: yieldpoint
            GDP_BACKUP_PASSWORD: YPfuture

            GDP_BACKUP_FORMAT: csv2
            GDP_BACKUP_IS_INCREMENTIVE: 1
            GDP_BACKUP_IS_NEW_FOLDER_PER_RUN: 0

            GDP_BACKUP_DIR: $backupDrive
            GDP_BACKUP_STATUS_FILE: /var/lib/gdp/backups/backup_status.csv

            GDP_BACKUP_CRON_PERIOD: "30 2 * * *"
        volumes:
            - /var/lib/gdp/backups:/var/lib/gdp/backups
            - /var/log/gdp:/var/log/gdp
EndOfFile
}

write_compose_m() {
cat > "/opt/yieldpoint/gdp/docker-compose.yml" <<- EndOfFile
version: '3'

volumes:
    pg_data:
    influx_data:
    django_logs:
    ember_logo:
    ember_data:
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
    ember:
        restart: always
        image: $sourceAddress/gdp_ember
        container_name: ember
        environment:
            API_URL: http://$serverIP:8000
            API_CREDENTIALS: "$credentials"
        ports:
            - "80:80"
        volumes:
            - ember_logo:/var/www/html/assets/images/customer_logo
            - ember_data:/etc/apache2/
        depends_on:
            - django
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

write_compose_b() {
cat > "/opt/yieldpoint/gdp/docker-compose.yml" <<- EndOfFile
version: '3'

volumes:
    pg_data:
    influx_data:
    django_logs:
    ember_logo:
    ember_data:
services:
    postgres:
        restart: always
        image: $sourceAddress/gdp_postgres
        container_name: postgres
        volumes:
            - pg_data:/var/lib/postgresql/data
        ports:
            - "5432:5432"
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
    ember:
        restart: always
        image: $sourceAddress/gdp_ember
        container_name: ember
        environment:
            API_URL: http://$serverIP:8000
            API_CREDENTIALS: "$credentials"
        ports:
            - "80:80"
        volumes:
            - ember_logo:/var/www/html/assets/images/customer_logo
            - ember_data:/etc/apache2/
        depends_on:
            - django
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
    gdp_backup: #optional container
        restart: always
        image: $sourceAddress/gdp_backup
        container_name: gdp_backup
        environment:
            GDP_BACKUP_HOST: $backupIP
            GDP_BACKUP_USER: yieldpoint
            GDP_BACKUP_PASSWORD: YPfuture

            GDP_BACKUP_FORMAT: csv2
            GDP_BACKUP_IS_INCREMENTIVE: 1
            GDP_BACKUP_IS_NEW_FOLDER_PER_RUN: 0

            GDP_BACKUP_DIR: $backupDrive
            GDP_BACKUP_STATUS_FILE: /var/lib/gdp/backups/backup_status.csv

            GDP_BACKUP_CRON_PERIOD: "30 2 * * *"
        volumes:
            - /var/lib/gdp/backups:/var/lib/gdp/backups
            - /var/log/gdp:/var/log/gdp
EndOfFile
}

write_compose() {
cat > "/opt/yieldpoint/gdp/docker-compose.yml" <<- EndOfFile
version: '3'

volumes:
    pg_data:
    influx_data:
    django_logs:
    ember_logo:
    ember_data:
services:
    postgres:
        restart: always
        image: $sourceAddress/gdp_postgres
        container_name: postgres
        volumes:
            - pg_data:/var/lib/postgresql/data
        ports:
            - "5432:5432"
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
    ember:
        restart: always
        image: $sourceAddress/gdp_ember
        container_name: ember
        environment:
            API_URL: http://$serverIP:8000
            API_CREDENTIALS: "$credentials"
        ports:
            - "80:80"
        volumes:
            - ember_logo:/var/www/html/assets/images/customer_logo
            - ember_data:/etc/apache2/
        depends_on:
            - django
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


printf "Is this a clean install or an update? [c/u]: "

read mode

if [ "$mode" = "u" ]; then

printf "Do you want to do a force shutdown of docker? [y/n]: "

read killDocker

else

killDocker='n'

fi

printf "Backup server? [y/n]: "

read backup

printf "Are you using Kafka? (y/n): "

read kafka

if [ "$kafka" = "y" ]; then

    printf "Enter kafka IP: "

    read kafkaIP

    printf "Output Method (JSON/string): "

    read outputMethod

else

    kafkaIP="NoServer"

    outputMethod="string"

fi

printf "DockerHub or YieldPoint as source for images [d/y]: "

read imageSrc

if [ "$imageSrc" = "d" ]; then

    sourceAddress="yieldpointadmin"

else

    sourceAddress="updates.yieldpoint.com:5000"

fi

printf "Enter VantagPoint IP: "

read serverIP

if [ "$backup" = "y" ]; then

    printf "Backup server IP [Default: $serverIP]: "

    read backupIP

    if [ "$backupIP" = "" ]; then
	
        backupIP=$serverIP

    fi

    printf "Backup drive location [Default: /var/lib/gdp/backups/data]: "

    read backupDrive

    if [ "$backupDrive" = "" ]; then

        backupDrive="/var/lib/gdp/backups/data"

    fi

fi

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

    if [ "$killDocker" = "y" ]; then
        docker kill $(docker ps -q)
        docker rm $(docker ps -a -q)
    else
        cd /opt/yieldpoint/gdp/
        docker-compose down
    fi

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


if [ "$mode" = "c" ]; then
    if [ "$backup" = "y" ]; then
        write_compose_b
    else
        write_compose
    fi
else
    if [ "$backup" = "y" ]; then
        write_compose_m_b
    else
        write_compose_m
    fi
fi


    if [ "$imageSrc" = "y" ]; then
        echo '{"insecure-registries" : ["0.0.0.0:5000", "updates.yieldpoint.com:5000"]}' > /etc/docker/daemon.json
        service docker restart
    fi
    docker-compose up -d

    emberContainer=$(echo -n $(echo -n | docker ps -f name=ember | awk '{print $1}') | awk '{print $2}')
    djangoContainer=$(echo -n $(echo -n | docker ps -f name=django | awk '{print $1}') | awk '{print $2}')

    docker exec -it $emberContainer htpasswd -b -c /etc/apache2/.htpasswd $userName $password
    docker exec -it $djangoContainer htpasswd -b -c /etc/apache2/.htpasswd $userName $password

    docker exec -it $djangoContainer /bin/bash /var/www/html/passchange.sh $userName $password #for new GDP
    #docker exec -it $djangoContainer /bin/bash #for old GDP

    printf "\n"
    printf "You should now have access to the GDP.\n"
    printf "Server IP: $serverIP\n"
    printf "Username: $userName\n"
    #echo "Password: $password\n"

if [ "$mode" = "c" ]; then
    if [ "$backup" = "y" ]; then
        write_compose_m_b
    else
        write_compose_m
    fi
fi

else
    stty echo
    printf "Passwords do not match, please try again.\n"
fi