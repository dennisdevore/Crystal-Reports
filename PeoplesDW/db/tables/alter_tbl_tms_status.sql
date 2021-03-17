--
-- $Id$
--
DROP TABLE tms_status;

CREATE TABLE tms_status (
  CODE        VARCHAR2 (12)  NOT NULL,
  DESCR       VARCHAR2 (32)  NOT NULL,
  ABBREV      VARCHAR2 (12)  NOT NULL,
  DTLUPDATE   VARCHAR2 (1),
  LASTUSER    VARCHAR2 (12),
  LASTUPDATE  DATE ) ;


CREATE UNIQUE INDEX tms_status_IDX ON
  tms_status(CODE) ;

delete from tabledefs where tableid = 'TMS_Status';


insert into tabledefs(tableid,hdrupdate,dtlupdate,codemask,lastuser,lastupdate)
  values('TMS_Status','Y','Y','>A;0;_','SYSTEM',sysdate);

insert into tms_status 
    values('1','Not Optimized','Not Opt','N','SUP',sysdate);
insert into tms_status
    values('2','Optimizing','Optimizing','N','SUP',sysdate);
insert into tms_status
    values('3','Optimized','Optimized','N','SUP',sysdate);
insert into tms_status
    values('4','Released For Picking','Released','N','SUP',sysdate);
insert into tms_status
    values('X','Not Applicable','Not Appl','N','SUP',sysdate);


commit;

exit;

