#!/bin/bash
sudo service mongod start && tail -f /var/log/mongodb/mongod.log
