--
-- $Id$
--
DROP TABLE vics_bol_types;

CREATE TABLE vics_bol_types (
  CODE        VARCHAR2 (12)  NOT NULL,
  DESCR       VARCHAR2 (32)  NOT NULL,
  ABBREV      VARCHAR2 (12)  NOT NULL,
  DTLUPDATE   VARCHAR2 (1),
  LASTUSER    VARCHAR2 (12),
  LASTUPDATE  DATE ) ;


CREATE UNIQUE INDEX vics_bol_types_IDX ON
  vics_bol_types(CODE) ;

insert into tabledefs(tableid,hdrupdate,dtlupdate,codemask,lastuser,lastupdate)
  values('Vics_Bol_Types','N','N','>Aaaa;0;_','SYSTEM',sysdate);

insert into vics_bol_types
values ('MAST', 'Master Bill of Lading','Master','N','SYSTEM',sysdate);
insert into vics_bol_types
values ('STOP', 'Memo Bill of Lading','Stop','N','SYSTEM',sysdate);
insert into vics_bol_types
values ('SHIP', 'Shipment Bill of Lading','Shipment','N','SYSTEM',sysdate);
insert into vics_bol_types
values ('POME', 'PO Memo Bill of Lading','PO Memo','N','SYSTEM',sysdate);

commit;

--exit;

