--
-- $Id: import_204_load.sql 1 2005-05-26 12:20:03Z ed $
--
create table import_204_load
(importfileid varchar2(255)
,seq varchar2(9)
,func varchar2(2)
,facility varchar2(3)
,shipmentid varchar2(40)
,carrier varchar2(4)
,billoflading varchar2(40)
,custid varchar2(10)
,shiptype char(1)
,shipterms varchar2(3)
,appointmentdate date
,comment1 clob
,ldpassthruchar01 varchar2(255)
,ldpassthruchar02 varchar2(255)
,ldpassthruchar03 varchar2(255)
,ldpassthruchar04 varchar2(255)
,ldpassthruchar05 varchar2(255)
,ldpassthruchar06 varchar2(255)
,ldpassthruchar07 varchar2(255)
,ldpassthruchar08 varchar2(255)
,ldpassthruchar09 varchar2(255)
,ldpassthruchar10 varchar2(255)
,ldpassthruchar11 varchar2(255)
,ldpassthruchar12 varchar2(255)
,ldpassthruchar13 varchar2(255)
,ldpassthruchar14 varchar2(255)
,ldpassthruchar15 varchar2(255)
,ldpassthruchar16 varchar2(255)
,ldpassthruchar17 varchar2(255)
,ldpassthruchar18 varchar2(255)
,ldpassthruchar19 varchar2(255)
,ldpassthruchar20 varchar2(255)
,ldpassthruchar21 varchar2(255)
,ldpassthruchar22 varchar2(255)
,ldpassthruchar23 varchar2(255)
,ldpassthruchar24 varchar2(255)
,ldpassthruchar25 varchar2(255)
,ldpassthruchar26 varchar2(255)
,ldpassthruchar27 varchar2(255)
,ldpassthruchar28 varchar2(255)
,ldpassthruchar29 varchar2(255)
,ldpassthruchar30 varchar2(255)
,ldpassthruchar31 varchar2(255)
,ldpassthruchar32 varchar2(255)
,ldpassthruchar33 varchar2(255)
,ldpassthruchar34 varchar2(255)
,ldpassthruchar35 varchar2(255)
,ldpassthruchar36 varchar2(255)
,ldpassthruchar37 varchar2(255)
,ldpassthruchar38 varchar2(255)
,ldpassthruchar39 varchar2(255)
,ldpassthruchar40 varchar2(255)
,ldpassthrudate01 date
,ldpassthrudate02 date
,ldpassthrudate03 date
,ldpassthrudate04 date
,ldpassthrunum01 number(16,4)
,ldpassthrunum02 number(16,4)
,ldpassthrunum03 number(16,4)
,ldpassthrunum04 number(16,4)
,ldpassthrunum05 number(16,4)
,ldpassthrunum06 number(16,4)
,ldpassthrunum07 number(16,4)
,ldpassthrunum08 number(16,4)
,ldpassthrunum09 number(16,4)
,ldpassthrunum10 number(16,4)
,created timestamp
);
create index import_204_load_idx
on import_204_load(importfileid, shipmentid);
create index import_204_load_created_idx
on import_204_load(created);

exit;
