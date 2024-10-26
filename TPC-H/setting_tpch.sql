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