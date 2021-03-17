--
-- $Id$
--
CREATE TABLE pronostatus (
  CODE        VARCHAR2 (12)  NOT NULL,
  DESCR       VARCHAR2 (32)  NOT NULL,
  ABBREV      VARCHAR2 (12)  NOT NULL,
  DTLUPDATE   VARCHAR2 (1),
  LASTUSER    VARCHAR2 (12),
  LASTUPDATE  DATE ) ;


CREATE UNIQUE INDEX pronostatus_idx ON
  pronostatus(CODE) ;

insert into tabledefs(tableid,hdrupdate,dtlupdate,codemask,lastuser,lastupdate)
  values('PronoStatus','Y','Y','>A;0;_','SYSTEM',sysdate);

insert into pronostatus
    values('U','Unused','Unused','N','SYSTEM',sysdate);
insert into pronostatus
    values('A','Assigned','Assigned','N','SYSTEM',sysdate);
insert into pronostatus
    values('X','Cancelled','Cancelled','N','SYSTEM',sysdate);


commit;

--exit;

