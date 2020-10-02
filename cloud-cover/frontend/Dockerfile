FROM php:7.4.7-apache

RUN pecl install redis && docker-php-ext-enable redis

RUN pear channel-discover pear.nrk.io
RUN pear install nrk/Predis

ADD guestbook.php /var/www/html/guestbook.php
ADD controllers.js /var/www/html/controllers.js
ADD index.html /var/www/html/index.html
