dockerfiles
===========
forked from Neerav Kumar https://github.com/neeravkumar/dockerfiles/blob/master/alpine-openrc/Dockerfile to make a fat docker container for armhf odroid c1 with nginx and php5

Installation https://forum.armbian.com/index.php/topic/490-docker-on-armbian/?p=23514
sudo docker build -t armhf-alpine-orvfms .
sudo docker run --rm -it --net=host -p 80:80 --name alpine-openrc armhf-alpine-orvfms
sudo docker run -d --net=host -p 80:80 --name alpine-openrc armhf-alpine-orvfms

