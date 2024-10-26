# TPC-H

## PostgreSQL

### 1. PostgreSQL Github 소스 코드로 빌드

**wget으로 tar 파일 직접 다운로드**

```bash
wget https://github.com/postgres/postgres/archive/refs/heads/master.zip -O postgres-master.zip
```
<br>

**압축 해제**

```bash
sudo unzip postgres-master.zip
cd postgres-master
```
<br>

**필요한 패키지 설치**

```bash
sudo apt-get update -y
sudo apt-get install build-essential libreadline-dev zlib1g-dev flex bison
```
<br>

**PostgreSQL 빌드**

```bash
sudo ./configure
sudo make
```
<br>

**빌드 후 설치**

```bash
sudo make install
```
<br>

**환경변수 설정**

```bash
export PATH=/usr/local/pgsql/bin:$PATH
```
<br>

### 2. PostgreSQL 설정

**데이터 디렉토리 생성 및 초기화**

```bash
sudo mkdir /usr/local/pgsql/data
sudo chown work /usr/local/pgsql/data
sudo chmod 700 /usr/local/pgsql/data
/usr/local/pgsql/bin/initdb -D /usr/local/pgsql/data
```
<br>

**서버 서비스 시작**

```bash
/usr/local/pgsql/bin/pg_ctl -D /usr/local/pgsql/data -l ./log.txt start
```
`-D`: 데이터 디렉토리 경로 지정 <br>
`-l`: 로그파일 경로 지정
<br>

**PostgreSQL CLI 도구 접속**

```bash
/usr/local/pgsql/bin/psql -d postgres
```
`-d`: 데이터베이스 이름
<br>

### 3. PostgreSQL 유저 생성

**데이터베이스 목록 보기**

```sql
postgres=# \l
```
<br>

**유저 목록 조회**

```sql
postgres=# SELECT * FROM PG_USER;
```
<br>

**슈퍼 유저로 유저 생성**

```sql
postgres=# CREATE USER tpch PASSWORD 'password' SUPERUSER;
```
`USER` 뒤는 유저 이름<br>
`PASSWORD` 뒤는 비밀번호
<br>

**특정 유저로 데이터베이스 접속**

```bash
/usr/local/pgsql/bin/psql -d postgres -U tpch
```
`-d`: 접속할 데이터베이스 이름<br>
`-U`: 접속할 유저 이름
<br>

### 4. Build dbgen 및 데이터 생성

**tpch-dbgen 다운로드 및 설치**

```bash
sudo git clone https://github.com/electrum/tpch-dbgen.git
sudo cd tpch-dbgen
sudo make
```
<br>

**PostgreSQL 내 tpch 데이터베이스 생성**

```bash
/usr/local/pgsql/bin/psql -d postgres -U tpch
```
<br>

```sql
postgres=# CREATE DATABASE tpch;
```
<br>

데이터베이스 CLI 접속 후 데이터베이스 생성

**TPC-H 데이터 생성**

```bash
sudo ./dbgen -s 1
```
<br>

`-s`: scale factor로 1은 8.6M (1GB)

데이터를 포함한 `.tbl` 파일을 생성

**TPC-H 테이블 생성**

```bash
/usr/local/pgsql/bin/psql -U tpch -d tpch -f dss.ddl
```
<br>

**데이터 삽입 전 전처리**

```
1|Customer#000000001|IVhzIApeRb ot,c,E|15|25-989-741-2988|711.56|BUILDING|to the even, regular platelets. regular, ironic epitaphs nag e|
2|Customer#000000002|XSTf4,NCwDVaWNe6tEgvwfmRchLXak|13|23-768-687-3665|121.65|AUTOMOBILE|l accounts. blithely ironic theodolites integrate boldly: caref|
3|Customer#000000003|MG9kdTD2WBHm|1|11-719-748-3364|7498.12|AUTOMOBILE| deposits eat slyly ironic, even instructions. express foxes detect slyly. blithely even accounts abov|
```
무슨 이유인지는 모르겠으나 생성된 `tbl` 파일을 보면 맨 마지막에 구분자 `|`가 하나 더 붙어있음<br>
이를 제거해주어야 함<br>
아래 코드를 포함한 `clean_tbl_files.sh` shell script 파일을 생성
<br>

```bash
#!/bin/bash

# 작업 디렉토리 설정
WORK_DIR="/home/work/hoeun/tpch-dbgen"

# tpch-dbgen 디렉토리로 이동
cd "$WORK_DIR" || exit 1

# 모든 .tbl 파일에 대해 마지막 | 제거
for file in *.tbl; do
    # 새로운 파일 이름 정의
    cleaned_file="${file%.tbl}_cleaned.tbl"
    
    # 마지막 | 제거하고 새 파일에 저장
    sed 's/|$//' "$file" > "$cleaned_file"
    
    # 완료 메시지 출력
    echo "Processed $file -> $cleaned_file"
done

echo "All files processed. '_cleaned.tbl' files created for each table."
```
1. 작업 디렉토리 설정: `WORK_DIR` 변수에 `tpch-dbgen` 디렉토리 경로를 설정
2. 루프 실행: `for` 루프를 통해 디렉토리 내 모든 `.tbl` 파일을 찾아 반복적으로 처리
3. 새 파일 생성: `sed 's/|$//' "$file" > "$cleaned_file"` 명령으로 각 `.tbl` 파일의 마지막 `|`를 제거한 후 `_cleaned.tbl` 파일에 저장
<br>

실행 권한 부여 후 shell script 실행

```bash
sudo chmod +x clean_tbl_files.sh
sudo ./clean_tbl_files.sh
```
<br>

### 5. 데이터베이스에 데이터 삽입

아래 코드는 각 `tbl` 파일을 데이터베이스에 로드하는 shell script 코드

**아래 코드로 `load_tpch_data.sh` 파일을 생성**

```bash
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
```
<br>

**권한 부여 후 실행**

```bash
sudo chmod +x load_tpch_data.sh
sudo ./load_tpch_data.sh
```
<br>

**데이터 삽입 확인**

```sql
postgres=# \dt
```
테이블 목록 조회
<br>

각 테이블별로 데이터 개수 확인
```sql
postgres=# select count(*) from customer;
```

```
 count 
-------
  1500
(1 row)
```
<br>

### 6. Primary Key 및 인덱스 생성

**기본키와 주요 필드에 대해 인덱스를 설정**

```sql
-- 기본 키 설정
ALTER TABLE nation ADD CONSTRAINT pk_nation PRIMARY KEY (n_nationkey);
ALTER TABLE region ADD CONSTRAINT pk_region PRIMARY KEY (r_regionkey);
ALTER TABLE part ADD CONSTRAINT pk_part PRIMARY KEY (p_partkey);
ALTER TABLE supplier ADD CONSTRAINT pk_supplier PRIMARY KEY (s_suppkey);
ALTER TABLE partsupp ADD CONSTRAINT pk_partsupp PRIMARY KEY (ps_partkey, ps_suppkey);
ALTER TABLE customer ADD CONSTRAINT pk_customer PRIMARY KEY (c_custkey);
ALTER TABLE orders ADD CONSTRAINT pk_orders PRIMARY KEY (o_orderkey);
ALTER TABLE lineitem ADD CONSTRAINT pk_lineitem PRIMARY KEY (l_orderkey, l_linenumber);

-- 주요 필드에 인덱스 설정
-- customer 테이블: 조인 및 조건 검색에 자주 사용되는 c_nationkey
CREATE INDEX idx_customer_nationkey ON customer (c_nationkey);

-- orders 테이블: 자주 조회되는 c_custkey (customer와 조인), o_orderdate (날짜 범위 검색)
CREATE INDEX idx_orders_custkey ON orders (o_custkey);
CREATE INDEX idx_orders_orderdate ON orders (o_orderdate);

-- lineitem 테이블: 자주 조회되는 필드 l_partkey, l_suppkey, l_shipdate (날짜 범위 검색)
CREATE INDEX idx_lineitem_partkey ON lineitem (l_partkey);
CREATE INDEX idx_lineitem_suppkey ON lineitem (l_suppkey);
CREATE INDEX idx_lineitem_shipdate ON lineitem (l_shipdate);

-- partsupp 테이블: part 및 supplier와의 조인에 자주 사용되는 ps_suppkey
CREATE INDEX idx_partsupp_suppkey ON partsupp (ps_suppkey);

-- supplier 테이블: nation과의 조인에 사용되는 s_nationkey
CREATE INDEX idx_supplier_nationkey ON supplier (s_nationkey);
```
<br>

### 7. 쿼리 실행 테스트

**아래 SQL은 TPC-H 테스트 쿼리 1번**

```sql
-- $ID$
-- TPC-H/TPC-R Pricing Summary Report Query (Q1)
-- Functional Query Definition
-- Approved February 1998
select
	l_returnflag,
	l_linestatus,
	sum(l_quantity) as sum_qty,
	sum(l_extendedprice) as sum_base_price,
	sum(l_extendedprice * (1 - l_discount)) as sum_disc_price,
	sum(l_extendedprice * (1 - l_discount) * (1 + l_tax)) as sum_charge,
	avg(l_quantity) as avg_qty,
	avg(l_extendedprice) as avg_price,
	avg(l_discount) as avg_disc,
	count(*) as count_order
from
	lineitem
where
	l_shipdate <= date '1998-12-01' - interval '30' day
group by
	l_returnflag,
	l_linestatus
order by
	l_returnflag,
	l_linestatus;
```
<br>

**터미널(bash)에서 SQL 쿼리 파일 실행**

```bash
/usr/local/pgsql/bin/psql -d tpch -U tpch -f /home/work/hoeun/tpch-dbgen/queries/1m.sql
```

```
 l_returnflag | l_linestatus |  sum_qty  | sum_base_price | sum_disc_price  |    sum_charge     |       avg_qty       |     avg_price      |        avg_disc        | count_order 
--------------+--------------+-----------+----------------+-----------------+-------------------+---------------------+--------------------+------------------------+-------------
 A            | F            | 380456.00 |   532348211.65 |  505822441.4861 |  526165934.000839 | 25.5751546114546921 | 35785.709306937349 | 0.05008133906964237698 |       14876
 N            | F            |   8971.00 |    12384801.37 |   11798257.2080 |   12282485.056933 | 25.7787356321839080 | 35588.509683908046 | 0.04775862068965517241 |         348
 N            | O            | 762399.00 |  1068912195.35 | 1015777009.0088 | 1056539479.035050 | 25.4582762881089926 | 35693.464966440712 | 0.04992854042141115972 |       29947
 R            | F            | 381449.00 |   534594445.35 |  507996454.4067 |  528524219.358903 | 25.5971681653469333 | 35874.006532680177 | 0.04982753992752650651 |       14902
(4 rows)
```
<br>

**`EXPLAIN ANALYZE` 사용**

```sql
postgres=# 
EXPLAIN ANALYZE
select
	l_returnflag,
	l_linestatus,
	sum(l_quantity) as sum_qty,
	sum(l_extendedprice) as sum_base_price,
	sum(l_extendedprice * (1 - l_discount)) as sum_disc_price,
	sum(l_extendedprice * (1 - l_discount) * (1 + l_tax)) as sum_charge,
	avg(l_quantity) as avg_qty,
	avg(l_extendedprice) as avg_price,
	avg(l_discount) as avg_disc,
	count(*) as count_order
from
	lineitem
where
	l_shipdate <= date '1998-12-01' - interval '30' day
group by
	l_returnflag,
	l_linestatus
order by
	l_returnflag,
	l_linestatus;
```

```
                                                                  QUERY PLAN                                                         
          
-----------------------------------------------------------------------------------------------------------------------------------------------
 Finalize GroupAggregate  (cost=3853.03..3854.66 rows=6 width=236) (actual time=29.661..31.281 rows=4 loops=1)
   Group Key: l_returnflag, l_linestatus
   ->  Gather Merge  (cost=3853.03..3854.17 rows=10 width=236) (actual time=29.637..31.241 rows=8 loops=1)
         Workers Planned: 1
         Workers Launched: 1
         ->  Sort  (cost=2853.02..2853.04 rows=6 width=236) (actual time=27.949..27.950 rows=4 loops=2)
               Sort Key: l_returnflag, l_linestatus
               Sort Method: quicksort  Memory: 26kB
               Worker 0:  Sort Method: quicksort  Memory: 26kB
               ->  Partial HashAggregate  (cost=2852.81..2852.94 rows=6 width=236) (actual time=27.923..27.929 rows=4 loops=2)
                     Group Key: l_returnflag, l_linestatus
                     Batches: 1  Memory Usage: 24kB
                     Worker 0:  Batches: 1  Memory Usage: 24kB
                     ->  Parallel Seq Scan on lineitem  (cost=0.00..1618.46 rows=35267 width=25) (actual time=0.010..3.918 rows=30036 loops=2)
                           Filter: (l_shipdate <= '1998-11-01 00:00:00'::timestamp without time zone)
                           Rows Removed by Filter: 51
 Planning Time: 0.182 ms
 Execution Time: 31.329 ms
(18 rows)
```
<br>