# Docker container with Nginx 1.12.2, PHP 7.0, Ubuntu 16.04
## How run

```sh
sudo docker run -p 80:80 -p 443:443 -p 9000:9000 -v <path to application>:/basic/web raymondperminov/docker-nginx-php-yii
```
For example

```sh
sudo docker run -p 80:80 -p 443:443 -p 9000:9000 -v /home/user/app:/basic/web raymondperminov/docker-nginx-php-yii
```