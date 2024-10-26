#!/bin/bash

# PostgreSQL 설정
DB_NAME="tpch"
DB_USER="tpch"
DATA_DIR="/home/work/hoeun/tpch-dbgen"

# 테이블 파일과 대응되는 TPC-H 테이블 목록
tables=("nation" "region" "part" "supplier" "partsupp" "customer" "orders" "lineitem")

# 모든 테이블에 대해 데이터 삽입
for table in "${tables[@]}"; do
    cleaned_file="${DATA_DIR}/${table}_cleaned.tbl"
    
    # 파일이 존재하는지 확인하고 COPY 실행
    if [[ -f "$cleaned_file" ]]; then
        echo "Loading data into $table from $cleaned_file"
        /usr/local/pgsql/bin/psql -d "$DB_NAME" -U "$DB_USER" -c "\COPY $table FROM '$cleaned_file' DELIMITER '|'"
        echo "$table loaded successfully."
    else
        echo "File $cleaned_file does not exist. Skipping $table."
    fi
done

echo "All tables have been processed."