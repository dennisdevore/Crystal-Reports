create or replace view impexpdefview
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
INCLUDECRLF
)
as
select
new.definc,
decode(nvl(new.name,'x'),nvl(old.name,'x'),'SAME ' || new.name,nvl(new.name,'(null)')),
decode(nvl(new.targetalias,'x'),nvl(old.targetalias,'x'),null,nvl(new.targetalias,'(null)')),
decode(nvl(new.deffilename,'x'),nvl(old.deffilename,'x'),null,nvl(new.deffilename,'(null)')),
decode(nvl(new.dateformat,'x'),nvl(old.dateformat,'x'),null,nvl(new.dateformat,'(null)')),
decode(nvl(new.deftype,'x'),nvl(old.deftype,'x'),null,nvl(new.deftype,'(null)')),
decode(nvl(new.floatdecimals,0),nvl(old.floatdecimals,0),null,new.floatdecimals),
decode(nvl(new.amountdecimals,0),nvl(old.amountdecimals,0),null,new.amountdecimals),
decode(nvl(new.linelength,0),nvl(old.linelength,0),null,new.linelength),
decode(nvl(new.afterprocessproc,'x'),nvl(old.afterprocessproc,'x'),null,nvl(new.afterprocessproc,'(null)')),
decode(nvl(new.beforeprocessproc,'x'),nvl(old.beforeprocessproc,'x'),null,nvl(new.beforeprocessproc,'(null)')),
decode(nvl(new.afterprocessprocparams,'x'),nvl(old.afterprocessprocparams,'x'),null,nvl(new.afterprocessprocparams,'(null)')),
decode(nvl(new.beforeprocessprocparams,'x'),nvl(old.beforeprocessprocparams,'x'),null,nvl(new.beforeprocessprocparams,'(null)')),
decode(nvl(new.timeformat,'x'),nvl(old.timeformat,'x'),null,nvl(new.timeformat,'(null)')),
decode(nvl(new.includecrlf,'x'),nvl(old.includecrlf,'x'),null,nvl(new.includecrlf,'(null)'))
from oldexp_definitions old, impexp_definitions new
where new.definc = old.definc;

comment on table impexpdefview is '$Id$';

create or replace view impexplinview
(
DEFINC,
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
ORDERBYCOLUMNS
)
as
select
new.definc,
new.lineinc,
decode(nvl(new.parent,0),nvl(old.parent,0),null,new.parent),
decode(nvl(new.type,0),nvl(old.type,0),null,new.type),
decode(nvl(new.identifier,'x'),nvl(old.identifier,'x'),null,nvl(new.identifier,'(null)')),
decode(nvl(new.delimiter,'x'),nvl(old.delimiter,'x'),null,nvl(new.delimiter,'(null)')),
decode(nvl(new.linealias,'x'),nvl(old.linealias,'x'),null,nvl(new.linealias,'(null)')),
decode(nvl(new.procname,'x'),nvl(old.procname,'x'),null,nvl(new.procname,'(null)')),
decode(nvl(new.delimiteroffset,0),nvl(old.delimiteroffset,0),null,new.delimiteroffset),
decode(nvl(new.afterprocessprocname,'x'),nvl(old.afterprocessprocname,'x'),null,nvl(new.afterprocessprocname,'(null)')),
decode(nvl(new.headertrailerflag,'x'),nvl(old.headertrailerflag,'x'),null,nvl(new.headertrailerflag,'(null)')),
decode(nvl(new.orderbycolumns,'x'),nvl(old.orderbycolumns,'x'),null,nvl(new.orderbycolumns,'(null)'))
from oldexp_lines old, impexp_lines new
where new.definc = old.definc
  and new.lineinc = old.lineinc;

comment on table impexplinview is '$Id$';

create or replace view impexpchuview
(
DEFINC,
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
CHUNKDECIMALS
)
as
select
new.definc,
new.lineinc,
new.chunkinc,
decode(nvl(new.chunktype,0),nvl(old.chunktype,0),null,new.chunktype),
decode(nvl(new.paramname,'x'),nvl(old.paramname,'x'),null,nvl(new.paramname,'(null)')),
decode(nvl(new.offset,0),nvl(old.offset,0),null,new.offset),
decode(nvl(new.length,0),nvl(old.length,0),null,new.length),
decode(nvl(new.defvalue,'x'),nvl(old.defvalue,'x'),null,nvl(new.defvalue,'(null)')),
decode(nvl(new.description,'x'),nvl(old.description,'x'),null,nvl(new.description,'(null)')),
decode(nvl(new.lktable,'x'),nvl(old.lktable,'x'),null,nvl(new.lktable,'(null)')),
decode(nvl(new.lkfield,'x'),nvl(old.lkfield,'x'),null,nvl(new.lkfield,'(null)')),
decode(nvl(new.lkkey,'x'),nvl(old.lkkey,'x'),null,nvl(new.lkkey,'(null)')),
new.mappings,
decode(nvl(new.parentlineparam,'x'),nvl(old.parentlineparam,'x'),null,nvl(new.parentlineparam,'(null)')),
decode(nvl(new.chunkdecimals,'x'),nvl(old.chunkdecimals,'x'),null,nvl(new.chunkdecimals,'(null)'))
from oldexp_chunks old, impexp_chunks new
where new.definc = old.definc
  and new.lineinc = old.lineinc
  and new.chunkinc = old.chunkinc;

comment on table impexpchuview is '$Id$';

create or replace view impexpaftview
(
DEFINC,
LINEINC,
PARAMNAME,
CHUNKINC,
DEFVALUE
)
as
select
new.definc,
new.lineinc,
new.paramname,
decode(nvl(new.chunkinc,0),nvl(old.chunkinc,0),null,new.chunkinc),
decode(nvl(new.defvalue,'x'),nvl(old.defvalue,'x'),null,nvl(new.defvalue,'(null)'))
from oldexp_afterprocessprocparams old, impexp_afterprocessprocparams new
where new.definc = old.definc
  and new.lineinc = old.lineinc
  and new.paramname = old.paramname;
  
comment on table impexpaftview is '$Id$';
  
exit;

