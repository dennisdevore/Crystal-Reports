--
-- $Id$
--

ALTER TABLE PALLETHISTORY ADD ( 
  
  INPALLETS        NUMBER (7) ,
  OUTPALLETS	   NUMBER (7)
  ); 


update pallethistory
set inpallets = cnt, outpallets = 0
where cnt > 0;

update pallethistory
set outpallets = cnt * -1, inpallets = 0
where cnt < 0;


DROP INDEX PALLETHISTORY_CARRIER;


DROP INDEX PALLETHISTORY_CUSTOMER; 

DROP INDEX PALLETHISTORY_LOADNO;

DROP UNIQUE INDEX PALLETHISTORY_UNIQUE;


DROP TABLE PALLETHISTORYTEMP CASCADE CONSTRAINTS ; 

CREATE TABLE PALLETHISTORYTEMP ( 
  CUSTID      VARCHAR2 (10)  NOT NULL, 
  FACILITY    VARCHAR2 (3)  NOT NULL, 
  PALLETTYPE  VARCHAR2 (12)  NOT NULL, 
  ADJREASON   VARCHAR2 (12), 
  LOADNO      NUMBER (7), 
  LASTUSER    VARCHAR2 (12)  NOT NULL, 
  LASTUPDATE  DATE          NOT NULL, 
  CARRIER     VARCHAR2 (4)  NOT NULL, 
  COMMENT1    VARCHAR2 (80), 
  ORDERID     NUMBER (7), 
  SHIPID      NUMBER (2), 
  INPALLETS   NUMBER (7), 
  OUTPALLETS  NUMBER (7));


CREATE INDEX PALLETHISTORY_CARRIER ON 
  PALLETHISTORYTEMP(CARRIER, CUSTID, FACILITY); 


CREATE INDEX PALLETHISTORY_CUSTOMER ON 
  PALLETHISTORYTEMP(CUSTID, FACILITY, CARRIER); 

CREATE INDEX PALLETHISTORY_LOADNO ON 
  PALLETHISTORYTEMP(LOADNO, CUSTID, FACILITY); 

CREATE UNIQUE INDEX PALLETHISTORY_UNIQUE ON 
  PALLETHISTORYTEMP(CUSTID, FACILITY, PALLETTYPE, CARRIER, LASTUPDATE); 


-- add insert trigger to pallethistory temp

CREATE OR REPLACE TRIGGER pallethistorytemp_rai
after insert on pallethistorytemp
for each row
declare


  cursor pi(in_custid varchar2,
            in_facility varchar2,
            in_pallettype varchar2
            
            )
  is
    select cnt from palletinventory
     where custid    = in_custid
       and facility  = in_facility
       and pallettype = in_pallettype
       
       ;

  theCount INTEGER(7);

begin


  if not pi%isopen then
     open pi(:new.custid,:new.facility,
             :new.pallettype);
  end if;

  fetch pi into theCount;

  if pi%NOTFOUND then
      insert into palletinventory(
                     custid,
                     facility,
                     pallettype,
                     cnt
                     
             )
             values(
                     :new.custid,
                     :new.facility,
                     :new.pallettype,
                     :new.inpallets - :new.outpallets
                    
                     
             );
  else

      update palletinventory set cnt = theCount + (:new.inpallets - :new.outpallets)
       where custid = :new.custid
         and facility = :new.facility
         and pallettype = :new.pallettype;
         

  end if;

  close pi;

end;
/


insert into pallethistorytemp
SELECT
CUSTID,
FACILITY,
PALLETTYPE,
ADJREASON,
LOADNO,
LASTUSER,
LASTUPDATE,
CARRIER,
COMMENT1,
ORDERID,
SHIPID,
INPALLETS,
OUTPALLETS
FROM PALLETHISTORY;

commit;

drop table pallethistory;

rename pallethistorytemp to pallethistory;

drop trigger pallethistorytemp_rai;

exit;

