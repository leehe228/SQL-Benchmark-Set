#!/bin/bash

sudo mkdir /usr/local/pgsql/data
sudo chown work /usr/local/pgsql/data
sudo chmod 700 /usr/local/pgsql/data
/usr/local/pgsql/bin/initdb -D /usr/local/pgsql/data

# 서비스 시작
/usr/local/pgsql/bin/pg_ctl -D /usr/local/pgsql/data -l ./log.txt start

echo "PostgreSQL Initialized and Started."