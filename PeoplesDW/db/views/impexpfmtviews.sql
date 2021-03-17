create or replace view impexpfmt_header_view
(
DEFINC,
NAME,
TARGETALIAS,
DEFFILENAME,
DATEFORMAT,
DEFTYPE,
FLOATDECIMALS,
AMOUNTDECIMALS,
LINELENGTH,
AFTERPROCESSPROC,
BEFOREPROCESSPROC,
AFTERPROCESSPROCPARAMS,
BEFOREPROCESSPROCPARAMS,
TIMEFORMAT,
INCLUDECRLF,
SEPARATEFILES,
CUSTID,
SIP_FORMAT_YN,
TRIM_LEADING_SPACES_YN,
ORDER_ATTACHMENT_IMPORT_YN
)
as
select
DEFINC,
NAME,
TARGETALIAS,
DEFFILENAME,
DATEFORMAT,
DEFTYPE,
FLOATDECIMALS,
AMOUNTDECIMALS,
LINELENGTH,
AFTERPROCESSPROC,
BEFOREPROCESSPROC,
AFTERPROCESSPROCPARAMS,
BEFOREPROCESSPROCPARAMS,
TIMEFORMAT,
INCLUDECRLF,
SEPARATEFILES,
upper(NAME),
SIP_FORMAT_YN,
TRIM_LEADING_SPACES_YN,
ORDER_ATTACHMENT_IMPORT_YN
from impexp_definitions;

comment on table impexpfmt_header_view is '$Id$';

create or replace view impexpfmt_line_view
(
DEFINC,
NAME,
LINEINC,
PARENT,
TYPE,
IDENTIFIER,
DELIMITER,
LINEALIAS,
PROCNAME,
DELIMITEROFFSET,
AFTERPROCESSPROCNAME,
HEADERTRAILERFLAG,
ORDERBYCOLUMNS,
DELIMITEROFFSETTYPE
)
as
select
l.DEFINC,
h.name,
l.LINEINC,
l.PARENT,
l.TYPE,
l.IDENTIFIER,
l.DELIMITER,
l.LINEALIAS,
l.PROCNAME,
l.DELIMITEROFFSET,
l.AFTERPROCESSPROCNAME,
l.HEADERTRAILERFLAG,
l.ORDERBYCOLUMNS,
l.DELIMITEROFFSETTYPE
from impexp_definitions h, impexp_lines l
where l.definc = h.definc;

comment on table impexpfmt_line_view is '$Id$';

create or replace view impexpfmt_chunk_view
(
DEFINC,
NAME,
LINEINC,
CHUNKINC,
CHUNKTYPE,
PARAMNAME,
OFFSET,
LENGTH,
DEFVALUE,
DESCRIPTION,
LKTABLE,
LKFIELD,
LKKEY,
MAPPINGS,
PARENTLINEPARAM,
CHUNKDECIMALS,
FIELDPREFIX,
SUBSTRING_POSITION,
SUBSTRING_LENGTH,
NO_FIELDPREFIX_ON_NULL_VALUE,
FROM_ANOTHER_CHUNK_DESCRIPTION
)
as
select
c.DEFINC,
h.name,
c.LINEINC,
c.CHUNKINC,
c.CHUNKTYPE,
c.PARAMNAME,
c.OFFSET,
c.LENGTH,
c.DEFVALUE,
c.DESCRIPTION,
c.LKTABLE,
c.LKFIELD,
c.LKKEY,
c.MAPPINGS,
c.PARENTLINEPARAM,
c.CHUNKDECIMALS,
c.FIELDPREFIX,
c.SUBSTRING_POSITION,
c.SUBSTRING_LENGTH,
c.NO_FIELDPREFIX_ON_NULL_VALUE,
C.FROM_ANOTHER_CHUNK_DESCRIPTION
from impexp_definitions h, impexp_chunks c
where c.definc = h.definc;

comment on table impexpfmt_chunk_view is '$Id$';

create or replace view impexpfmt_proc_view
(
DEFINC,
name,
LINEINC,
PARAMNAME,
CHUNKINC,
DEFVALUE
)
as
select
a.DEFINC,
h.name,
a.LINEINC,
a.PARAMNAME,
a.CHUNKINC,
a.DEFVALUE
from impexp_definitions h, impexp_afterprocessprocparams a
where a.definc = h.definc;

comment on table impexpfmt_proc_view is '$Id$';

exit;
