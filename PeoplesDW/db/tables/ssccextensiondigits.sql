--
-- $Id: ssccextensiondigits.sql 2441 2007-12-28 18:04:19Z ed $
--
create table ssccextensiondigits (
    code              varchar2(12) not null,
    descr             varchar2(32) not null,
    abbrev            varchar2(12) not null,
    dtlupdate         varchar2(1),
    lastuser          varchar2(12),
    lastupdate        date
);

alter table ssccextensiondigits add (
  constraint pk_extension_digit
  primary key (code)
);

insert into tabledefs (codemask , tableid, hdrupdate, dtlupdate, lastuser, lastupdate)
values( '>Aaaa;0;_', 'ssccextensiondigits', 'Y','Y', 'SYNAPSE', SYSDATE);

insert into ssccextensiondigits values (0, 'Extension Digit 0','ExtDigit0','Y','SYNAPSE',sysdate);
insert into ssccextensiondigits values (4, 'Extension Digit 4','ExtDigit4','Y','SYNAPSE',sysdate);

commit;

exit;
