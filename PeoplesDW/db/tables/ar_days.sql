--
-- $Id: ar_days.sql 2441 2007-12-28 18:04:19Z ed $
--
create table ar_days (
    code              varchar2(12) not null,
    descr             varchar2(32) not null,
    abbrev            varchar2(12) not null,
    dtlupdate         varchar2(1),
    lastuser          varchar2(12),
      lastupdate        date
);

insert into tabledefs (codemask , tableid, hdrupdate, dtlupdate, lastuser, lastupdate)
values( '>Aaaa;0;_', 'AR_DAYS', 'N','N', 'SYNAPSE', SYSDATE);

insert into ar_days (code, descr, abbrev, dtlupdate, lastuser,
                               lastupdate)
            values( 'DAYS', 'Peachtree Interface', '10', 'Y', 'SYNAPSE', sysdate);

exit;
