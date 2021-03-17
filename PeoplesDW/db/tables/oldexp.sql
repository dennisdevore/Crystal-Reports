--
-- $Id$
--
create table oldexp_AFTERPROCESSPROCPARAMS (
DEFINC NUMBER(4) not null,
LINEINC NUMBER(4) not null,
PARAMNAME VARCHAR2(25) not null,
CHUNKINC NUMBER(4),
DEFVALUE VARCHAR2(35)
);
create table oldexp_CHUNKS (
DEFINC NUMBER(4) not null,
LINEINC NUMBER(4) not null,
CHUNKINC NUMBER(4) not null,
CHUNKTYPE NUMBER(2),
PARAMNAME VARCHAR2(25),
OFFSET NUMBER(8),
LENGTH NUMBER(8),
DEFVALUE VARCHAR2(35),
DESCRIPTION VARCHAR2(35),
LKTABLE VARCHAR2(35),
LKFIELD VARCHAR2(35),
LKKEY VARCHAR2(35),
MAPPINGS LONG,
PARENTLINEPARAM VARCHAR2(35),
CHUNKDECIMALS CHAR(1)
);
create table oldexp_DEFINITIONS (
DEFINC NUMBER(4) not null,
NAME VARCHAR2(35) not null,
TARGETALIAS VARCHAR2(35) not null,
DEFFILENAME VARCHAR2(200),
DATEFORMAT VARCHAR2(20),
DEFTYPE CHAR(1),
FLOATDECIMALS NUMBER(4),
AMOUNTDECIMALS NUMBER(4),
LINELENGTH NUMBER(8),
AFTERPROCESSPROC VARCHAR2(35),
BEFOREPROCESSPROC VARCHAR2(35),
AFTERPROCESSPROCPARAMS VARCHAR2(1000),
BEFOREPROCESSPROCPARAMS VARCHAR2(1000),
TIMEFORMAT VARCHAR2(20),
INCLUDECRLF CHAR(1)
);
create table oldexp_LINES (
DEFINC NUMBER(4) not null,
LINEINC NUMBER(4) not null,
PARENT NUMBER(2),
TYPE NUMBER(2),
IDENTIFIER VARCHAR2(15),
DELIMITER VARCHAR2(1),
LINEALIAS VARCHAR2(35),
PROCNAME VARCHAR2(35),
DELIMITEROFFSET NUMBER(4),
AFTERPROCESSPROCNAME VARCHAR2(35),
HEADERTRAILERFLAG CHAR(1),
ORDERBYCOLUMNS VARCHAR2(255)
);
exit;
