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
    django:
        restart: always
        image: yieldpointadmin/gdp_django
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
        image: yieldpointadmin/gdp_ember
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

write_compose_1() {
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
    django:
        restart: always
        image: yieldpointadmin/gdp_django
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
        image: yieldpointadmin/gdp_ember
        container_name: ember
        ports:
            - "80:80"
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

if [ "$password" = "$password2" ]; then
    if [ "$userName" = "" ]; then
	userName="yieldpoint"
	password="YPfuture"
        credentials="eWllbGRwb2ludDpZUGZ1dHVyZQ=="
    else
        credentials=$(echo -n "$userName:$password" | base64)
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

    write_reboot

    cd /opt/yieldpoint/gdp/

    write_compose_1

    docker-compose up -d

    docker exec -it ember htpasswd -b -c /etc/apache2/.htpasswd $userName $password
    docker exec -it django htpasswd -b -c /etc/apache2/.htpasswd $userName $password

    sleep 3

    docker exec -it django /bin/bash /var/www/html/passchange.sh $userName $password #for new GDP
    #docker exec -it $djangoContainer /bin/bash #for old GDP

    write_compose_2
    
    docker-compose down
    docker-compose up -d


    printf "\n"
    printf "You should now have access to the GDP.\n"
    printf "Username: $userName\n"
else
    stty echo
    printf "Passwords do not match, please try again.\n"
fi