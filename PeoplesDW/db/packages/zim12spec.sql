--
-- $Id$
--
create or replace PACKAGE alps.zimportproc12

is

function definc_by_name
(in_name varchar2
) return integer;

procedure import_format_header
(IN_NAME VARCHAR2
,IN_TARGETALIAS VARCHAR2
,IN_DEFFILENAME VARCHAR2
,IN_DATEFORMAT VARCHAR2
,IN_DEFTYPE CHAR
,IN_FLOATDECIMALS NUMBER
,IN_AMOUNTDECIMALS NUMBER
,IN_LINELENGTH NUMBER
,IN_AFTERPROCESSPROC VARCHAR2
,IN_BEFOREPROCESSPROC VARCHAR2
,IN_AFTERPROCESSPROCPARAMS VARCHAR2
,IN_BEFOREPROCESSPROCPARAMS VARCHAR2
,IN_TIMEFORMAT VARCHAR2
,IN_INCLUDECRLF CHAR
,IN_SEPARATEFILES CHAR
,IN_SIP_FORMAT_YN CHAR
,IN_TRIM_LEADING_SPACES_YN CHAR
,IN_ORDER_ATTACHMENT_IMPORT_YN CHAR
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_format_line
(IN_NAME VARCHAR2
,IN_LINEINC NUMBER
,IN_PARENT NUMBER
,IN_TYPE NUMBER
,IN_IDENTIFIER VARCHAR2
,IN_DELIMITER VARCHAR2
,IN_LINEALIAS VARCHAR2
,IN_PROCNAME VARCHAR2
,IN_DELIMITEROFFSET NUMBER
,IN_AFTERPROCESSPROCNAME VARCHAR2
,IN_HEADERTRAILERFLAG CHAR
,IN_ORDERBYCOLUMNS VARCHAR2
,IN_DELIMITEROFFSETTYPE NUMBER
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_format_chunk
(IN_NAME VARCHAR2
,IN_LINEINC NUMBER
,IN_CHUNKINC NUMBER
,IN_CHUNKTYPE NUMBER
,IN_PARAMNAME VARCHAR2
,IN_OFFSET NUMBER
,IN_LENGTH NUMBER
,IN_DEFVALUE VARCHAR2
,IN_DESCRIPTION VARCHAR2
,IN_LKTABLE VARCHAR2
,IN_LKFIELD VARCHAR2
,IN_LKKEY VARCHAR2
,IN_MAPPINGS LONG
,IN_PARENTLINEPARAM VARCHAR2
,IN_CHUNKDECIMALS CHAR
,IN_FIELDPREFIX VARCHAR2
,IN_SUBSTRING_POSITION NUMBER
,IN_SUBSTRING_LENGTH NUMBER
,IN_NO_FIELDPREFIX_ON_NULL VARCHAR2
,IN_FROM_ANOTHER_CHUNK VARCHAR2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_format_proc
(IN_NAME VARCHAR2
,IN_LINEINC NUMBER
,IN_PARAMNAME VARCHAR2
,IN_CHUNKINC NUMBER
,IN_DEFVALUE VARCHAR2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

end zimportproc12;
/
show error package zimportproc12;
--exit;
