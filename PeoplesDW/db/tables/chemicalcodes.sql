--
-- $Id$
--
rename chemicalcodes to chemicalcodes_old;

create table chemicalcodes
(chemcode               varchar2(12) not null
,abbrev                 varchar2(12) not null
,propershippingname1    varchar2(255)
,propershippingname2    varchar2(255)
,chemicalconstituents   varchar2(255)
,primaryhazardclass     varchar2(12)
,secondaryhazardclass   varchar2(12)
,tertiaryhazardclass    varchar2(12)
,naergnumber            varchar2(36)
,dotbolcomment          varchar2(255)
,iatabolcomment         varchar2(255)
,imobolcomment          varchar2(255)
,otherdescr             varchar2(255)              
,unnum                  varchar2(20)
,packinggroup           varchar2(20)
,donotprintBOL          varchar2(1)
,lastuser               varchar2(12)
,lastupdate             date
);

drop index chemicalcodes_unique;
create unique index chemicalcodes_unique on chemicalcodes(chemcode);

-- exit;
