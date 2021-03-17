--
-- $id: casthreshold
--

--drop table casthreshold cascade constraints ;
-- old table no longer needed 
drop table casthresholds; 

create table casthreshold ( 
  casnumber   varchar2 (12)  not null, 
  dea_weight  number(17,8),
  dhs_weight  number(17,8),
  psm_weight  number(17,8),
  rpm_weight  number(17,8),
  lastuser    varchar2 (12), 
  lastupdate  date);

insert into casthreshold
select code casnumber,
       to_number(abbrev) dea_weight,
       to_number(abbrev) dhs_weight,
       to_number(abbrev) psm_weight,
       to_number(abbrev) rmp_weight,
       lastuser,
       lastupdate
  from casthresholds;
       
create unique index casthreshold_idx on 
  casthreshold(casnumber);

delete from tabledefs where tableid='CASThresholds';

exit;

