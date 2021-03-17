--
-- $Id$
--
drop table alps.customcode;

create table alps.customcode(
    businessevent   varchar2(4),
    code            varchar2(2000),
    lastuser        varchar2(12),
    lastupdate      date
);

create unique index customcode_be_idx on customcode(businessevent);

insert into customcode(businessevent, code, lastuser, lastupdate)
values('RECO','begin' || chr(13)||chr(10)||
'   pecas.zpecas.custom(:DAT);' || chr(13)||chr(10)||
'end;',
'SUP',sysdate);
insert into customcode(businessevent, code, lastuser, lastupdate)
values('IAJ','begin' || chr(13)||chr(10)||
'   pecas.zpecas.inv_adj(:DAT);' || chr(13)||chr(10)||
'end;',
'SUP',sysdate);
insert into customcode(businessevent, code, lastuser, lastupdate)
values('SHIP','begin' || chr(13)||chr(10)||
'   pecas.zpecas.ship_order(:DAT);'|| chr(13)||chr(10)||
'end;',
'SUP',sysdate);
insert into customcode(businessevent, code, lastuser, lastupdate)
values('CKLP','begin' || chr(13)||chr(10)||
'   pecas.zpecas.check_lpid(:DAT);' || chr(13)||chr(10)||
'end;',
'SUP',sysdate);
insert into customcode(businessevent, code, lastuser, lastupdate)
values('FPPP','begin' || chr(13)||chr(10)||
'   pecas.zprod.fetch_picked_load(:DAT);' || chr(13)||chr(10)||
'end;',
'SUP',sysdate);
insert into customcode(businessevent, code, lastuser, lastupdate)
values('SPLO','begin' || chr(13)||chr(10)||
'   pecas.zprod.split_order(:DAT);' || chr(13)||chr(10)||
'end;',
'SUP',sysdate);



-- exit;
