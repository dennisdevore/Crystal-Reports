--
-- $Id$
--
alter table impexp_lines add DELIMITEROFFSET NUMBER(4, 0) DEFAULT 0;

alter table impexp_definitions add FLOATDECIMALS number (4,0) default 0;

alter table impexp_definitions add AMOUNTDECIMALS number (4,0) default 0;

alter table impexp_chunks add CHUNKDECIMALS char(1) default 'N';

alter table impexp_chunks modify LENGTH number(8,0);

alter table impexp_chunks modify OFFSET number(8,0);

alter table impexp_definitions add LINELENGTH NUMERIC(8,0) default 0;

alter table impexp_lines add AFTERPROCESSPROCNAME VARCHAR2(35);

CREATE TABLE ALPS.IMPEXP_AFTERPROCESSPROCPARAMS (
  DEFINC NUMBER(4, 0) NOT NULL,
  LINEINC NUMBER(4, 0) NOT NULL,
  PARAMNAME VARCHAR2(25) NOT NULL,
  CHUNKINC NUMBER(4, 0),
  DEFVALUE VARCHAR2(35)
);

ALTER TABLE ALPS.IMPEXP_AFTERPROCESSPROCPARAMS ADD CONSTRAINT PK_AFTERPROCESSPROCPARAMS  PRIMARY KEY (DEFINC, LINEINC, PARAMNAME);

ALTER TABLE ALPS.IMPEXP_LINES ADD HEADERTRAILERFLAG char(1) default'N';

alter table impexp_definitions add AFTERPROCESSPROC VARCHAR2(35);

alter table impexp_definitions add BEFOREPROCESSPROC VARCHAR2(35) ;

alter table impexp_definitions add AFTERPROCESSPROCPARAMS VARCHAR2(1000);

alter table impexp_definitions add BEFOREPROCESSPROCPARAMS VARCHAR2(1000);
