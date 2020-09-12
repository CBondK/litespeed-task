FROM ubuntu:18.04

ARG PHP_VER=lsphp73

RUN apt-get update && apt-get install \
    wget                              \
    curl                              \
    cron                              \
    tzdata                            \
    ed                                \
    openssl                           \
    net-tools                         \
    unzip -y

RUN wget -O /etc/apt/trusted.gpg.d/lst_repo.gpg http://rpms.litespeedtech.com/debian/lst_repo.gpg && \
    wget -O - http://rpms.litespeedtech.com/debian/enable_lst_debian_repo.sh | bash

RUN apt-get install mysql-client $PHP_VER $PHP_VER-common $PHP_VER-mysql $PHP_VER-opcache            \
    $PHP_VER-curl $PHP_VER-json $PHP_VER-imagick $PHP_VER-redis $PHP_VER-memcached $PHP_VER-intl -y

EXPOSE 7080 80 443

COPY . .

RUN chmod +x ./configs/lsws-install.sh && bash ./configs/lsws-install.sh 
RUN chmod +x ./configs/wp-install.sh   && bash ./configs/wp-install.sh

COPY ./configs/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
WORKDIR /var/www/vhosts/
