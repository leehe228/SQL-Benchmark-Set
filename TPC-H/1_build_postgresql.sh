#!/bin/bash

# postgresql tar 다운로드
sudo wget https://github.com/postgres/postgres/archive/refs/heads/master.zip -O postgres-master.zip

# 압축 해제
sudo unzip postgres-master.zip
cd postgres-master

# 필요한 패키지 설치
sudo apt-get update -y
sudo apt-get install build-essential libreadline-dev zlib1g-dev flex bison

# postgresql 빌드
sudo ./configure
sudo make

# 빌드 후 설치
sudo make install

# 환경변수 설정
export PATH=/usr/local/pgsql/bin:$PATH

echo "PostgreSQL installation complete."