create or replace package body alps.zimportproc12 as
--
-- $Id$
--

function definc_by_name
(in_name varchar2
) return integer is

workinc impexp_definitions.definc%type;

begin

select definc
  into workinc
  from impexp_definitions
 where rtrim(upper(name)) = rtrim(upper(in_name));

return workinc;

exception when others then
  return sqlcode;
end definc_by_name;

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
) is

cursor curCurrentDefInc is
  select definc
    from impexp_definitions
   where rtrim(upper(name)) = rtrim(upper(in_name));

workinc impexp_definitions.definc%type;
cntRows integer;

begin

out_errorno := 0;
out_msg := '';

workinc := 0;
open curCurrentDefInc;
fetch curCurrentDefInc into workinc;
close curCurrentDefinc;

if workinc <> 0 then
  delete from impexp_afterprocessprocparams
   where definc = workinc;
  delete from impexp_chunks
   where definc = workinc;
  delete from impexp_lines
   where definc = workinc;
  delete from impexp_definitions
   where definc = workinc;
else
  workinc := 1;
  while (1=1)
  loop
    select count(1)
      into cntRows
      from impexp_definitions
     where definc = workinc;
    if cntRows = 0 then
      exit;
    end if;
    workinc := workinc + 1;
  end loop;
  delete from impexp_afterprocessprocparams
   where definc = workinc;
  delete from impexp_chunks
   where definc = workinc;
  delete from impexp_lines
   where definc = workinc;
end if;

insert into IMPEXP_DEFINITIONS
(DEFINC
,NAME
,TARGETALIAS
,DEFFILENAME
,DATEFORMAT
,DEFTYPE
,FLOATDECIMALS
,AMOUNTDECIMALS
,LINELENGTH
,AFTERPROCESSPROC
,BEFOREPROCESSPROC
,AFTERPROCESSPROCPARAMS
,BEFOREPROCESSPROCPARAMS
,TIMEFORMAT
,INCLUDECRLF
,SEPARATEFILES
,SIP_FORMAT_YN
,TRIM_LEADING_SPACES_YN
,ORDER_ATTACHMENT_IMPORT_YN
) values
(workinc
,IN_NAME
,IN_TARGETALIAS
,IN_DEFFILENAME
,IN_DATEFORMAT
,IN_DEFTYPE
,IN_FLOATDECIMALS
,IN_AMOUNTDECIMALS
,IN_LINELENGTH
,IN_AFTERPROCESSPROC
,IN_BEFOREPROCESSPROC
,IN_AFTERPROCESSPROCPARAMS
,IN_BEFOREPROCESSPROCPARAMS
,IN_TIMEFORMAT
,IN_INCLUDECRLF
,IN_SEPARATEFILES
,IN_SIP_FORMAT_YN
,IN_TRIM_LEADING_SPACES_YN
,IN_ORDER_ATTACHMENT_IMPORT_YN
);

out_msg := 'OKAY';

exception when others then
  out_msg := 'zioh ' || sqlerrm;
  out_errorno := sqlcode;
end import_format_header;

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
) is

workinc impexp_definitions.definc%type;

begin

out_errorno := 0;
out_msg := '';

workinc := zim12.definc_by_name(IN_NAME);
if workinc <= 0 then
  out_errorno := -1;
  out_msg := 'Definition not found: ' || IN_NAME || '(' || workinc || ')';
  return;
end if;

insert into IMPEXP_LINES
(DEFINC
,LINEINC
,PARENT
,TYPE
,IDENTIFIER
,DELIMITER
,LINEALIAS
,PROCNAME
,DELIMITEROFFSET
,AFTERPROCESSPROCNAME
,HEADERTRAILERFLAG
,ORDERBYCOLUMNS
,DELIMITEROFFSETTYPE
) values
(workinc
,IN_LINEINC
,IN_PARENT
,IN_TYPE
,IN_IDENTIFIER
,IN_DELIMITER
,IN_LINEALIAS
,IN_PROCNAME
,IN_DELIMITEROFFSET
,IN_AFTERPROCESSPROCNAME
,IN_HEADERTRAILERFLAG
,IN_ORDERBYCOLUMNS
,IN_DELIMITEROFFSETTYPE
);

out_msg := 'OKAY';

exception when others then
  out_msg := 'ifl ' || sqlerrm;
  out_errorno := sqlcode;
end import_format_line;

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
) is

workinc impexp_definitions.definc%type;

begin

out_errorno := 0;
out_msg := '';

workinc := zim12.definc_by_name(IN_NAME);
if workinc <= 0 then
  out_errorno := -1;
  out_msg := 'Definition not found: ' || IN_NAME || '(' || workinc || ')';
  return;
end if;

insert into IMPEXP_CHUNKS
(DEFINC
,LINEINC
,CHUNKINC
,CHUNKTYPE
,PARAMNAME
,OFFSET
,LENGTH
,DEFVALUE
,DESCRIPTION
,LKTABLE
,LKFIELD
,LKKEY
,MAPPINGS
,PARENTLINEPARAM
,CHUNKDECIMALS
,FIELDPREFIX
,SUBSTRING_POSITION
,SUBSTRING_LENGTH
,NO_FIELDPREFIX_ON_NULL_VALUE
,FROM_ANOTHER_CHUNK_DESCRIPTION
) values
(workinc
,IN_LINEINC
,IN_CHUNKINC
,IN_CHUNKTYPE
,IN_PARAMNAME
,IN_OFFSET
,IN_LENGTH
,IN_DEFVALUE
,IN_DESCRIPTION
,IN_LKTABLE
,IN_LKFIELD
,IN_LKKEY
,IN_MAPPINGS
,IN_PARENTLINEPARAM
,IN_CHUNKDECIMALS
,IN_FIELDPREFIX
,IN_SUBSTRING_POSITION
,IN_SUBSTRING_LENGTH
,IN_NO_FIELDPREFIX_ON_NULL
,IN_FROM_ANOTHER_CHUNK
);

out_msg := 'OKAY';

exception when others then
  out_msg := 'ifc ' || sqlerrm;
  out_errorno := sqlcode;
end import_format_chunk;

procedure import_format_proc
(IN_NAME VARCHAR2
,IN_LINEINC NUMBER
,IN_PARAMNAME VARCHAR2
,IN_CHUNKINC NUMBER
,IN_DEFVALUE VARCHAR2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

workinc impexp_definitions.definc%type;

begin

out_errorno := 0;
out_msg := '';

workinc := zim12.definc_by_name(IN_NAME);
if workinc <= 0 then
  out_errorno := -1;
  out_msg := 'Definition not found: ' || IN_NAME || '(' || workinc || ')';
  return;
end if;

insert into IMPEXP_AFTERPROCESSPROCPARAMS
(DEFINC
,LINEINC
,PARAMNAME
,CHUNKINC
,DEFVALUE
) values
(workinc
,IN_LINEINC
,IN_PARAMNAME
,IN_CHUNKINC
,IN_DEFVALUE
);

out_msg := 'OKAY';

exception when others then
  out_msg := 'ifp ' || sqlerrm;
  out_errorno := sqlcode;
end import_format_proc;

end zimportproc12;
/
show error package body zimportproc12;
--exit;

