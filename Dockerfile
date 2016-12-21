# image name: kadriansyah/ubuntu_14_04_db_mongo:v1
FROM ubuntu:14.04
MAINTAINER Kiagus Arief Adriansyah <kadriansyah@gmail.com>

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# creating user grumpycat
RUN useradd -ms /bin/bash grumpycat
RUN gpasswd -a grumpycat sudo

# Enable passwordless sudo for users under the "sudo" group
RUN sed -i.bkp -e 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers

# su as grumpycat
USER grumpycat
WORKDIR /home/grumpycat

# Add Public Key to New Remote User
RUN mkdir .ssh && chmod 700 .ssh
RUN echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDfji/gkqLV5YAC2UFuE4OK3XeGtCGzWdRUYpByVVk4MHiVseLq2gmi5MN+A8k6a4xYX4knse2Ps94Md4WfcA2dHjykLs5vqmK+CqLa+OI7Ls4C9LmY/S0RgQz+Fq4WO28vVwDjje3yG+1q5mP42y45sR5i9U0sF4KOVXI+gsysOZqJPmKEFBuFYrM7qxrMMj2raKw00Mqfw0e9o/n+5ycl/YPr7gN9OqzDAmI0Wkr1441zjpk7ygrjsW7tSKeP0HXRCb8yeE0rLXEmhO1HVa7NEzkCEknZT9GlqkxM1ZcBFZszOCsy2x2ZRuIcccFNYUDhdKAgv0xJNOyqpl3tvxPN kadriansyah@192.168.1.7" > /home/grumpycat/.ssh/authorized_keys
RUN chmod 600 .ssh/authorized_keys

# mongodb init script
COPY mongod /home/grumpycat/
RUN sudo mv /home/grumpycat/mongod /etc/init.d/mongod && sudo chmod 755 /etc/init.d/mongod

# configure sshd
RUN sudo apt-get update && sudo apt-get install -y openssh-server
RUN sudo sed -i 's/Port 22/Port 3006/' /etc/ssh/sshd_config
RUN sudo sed -i 's/PermitRootLogin without-password/PermitRootLogin no/' /etc/ssh/sshd_config

# Configure NTP Synchronization, htop, curl
RUN sudo apt-get update && sudo apt-get install -y ntp && sudo apt-get install -y htop && sudo apt-get install -y curl libcurl3 libcurl3-dev

# NodeJS Debian and Ubuntu based Linux distributions
RUN sudo sudo apt-get update && sudo apt-get install -y build-essential
RUN sudo curl -sL https://deb.nodesource.com/setup_4.x | sudo -E bash -
RUN sudo apt-get install -y nodejs

# install mongodb
RUN sudo apt-get update && sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6
RUN sudo echo "deb [ arch=amd64 ] http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list
RUN sudo apt-get update && sudo apt-get install -y mongodb-org

# # Create the MongoDB data directory
# USER root
# RUN mkdir -p /data/db
# RUN chown -R mongodb:mongodb /data

# Bind ip to accept external connections
RUN sudo sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf

# forward request and error logs to docker log collector
RUN sudo ln -sf /dev/stdout /var/log/mongodb/mongod.log && sudo ln -sf /dev/stderr /var/log/mongodb/mongod.log
COPY start_script.sh /home/grumpycat/
RUN sudo chown grumpycat.grumpycat /home/grumpycat/start_script.sh && sudo chmod 755 /home/grumpycat/start_script.sh
RUN echo 'export TERM=xterm' >> ~/.bashrc

# Expose port 27017 from the container to the host
EXPOSE 27017
ENTRYPOINT ["./start_script.sh"]
