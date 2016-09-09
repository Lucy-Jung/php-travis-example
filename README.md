# dockerfile-nginx-phpfpm


## docker install
[docker for mac](https://download.docker.com/mac/stable/Docker.dmg)

## setup
```sh
docker pull yjkim0/php-travis
docker run -d -v `pwd`:/var/www --name php-travis yjkim0/php-travis
docker exec php-travis /bin/sh -c "cd /var/www; composer update"
docker exec php-travis /bin/sh -c "cd /var/www; ./vendor/bin/phpcs -sw --standard=PSR2 app"
docker exec php-travis /bin/sh -c "cd /var/www; ./vendor/bin/phpmd app text cleancode"
docker exec php-travis /bin/sh -c "cd /var/www; phpunit"
```
