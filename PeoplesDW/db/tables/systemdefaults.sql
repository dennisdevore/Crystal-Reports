--
-- $Id$
--
drop table systemdefaults;

create table systemdefaults
(defaultid varchar2(36)
,defaultvalue varchar2(255)
,lastuser varchar2(12)
,lastupdate date
);

create unique index systemdefaults_unique
   on systemdefaults(defaultid);
