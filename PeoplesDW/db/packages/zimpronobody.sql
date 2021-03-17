create or replace PACKAGE BODY alps.zimportprocprono
IS
--
-- $Id$
--

PROCEDURE import_prono
(in_carrier  IN varchar2
,in_zone     IN varchar2
,in_prono    IN varchar2
,out_errorno IN OUT number
,out_msg     IN OUT varchar2
)

is

cursor curCarrier is
   select carrier
     from carrier
    where carrier = in_carrier;
ca curCarrier%rowtype;

cursor curProNo is
  select *
    from carrierprono
   where carrier = in_carrier
     and zone = in_zone
     and prono = in_prono;
pn curProNo%rowtype;


begin

out_errorno := 0;
out_msg := 'OKAY';

ca := null;
open curCarrier;
fetch curCarrier into ca;
close curCarrier;
if ca.carrier is null then
  out_errorno := 1;
  out_msg := 'Invalid Carrier Code ' || in_carrier;
  return;
end if;

if rtrim(in_zone) is null then
  out_errorno := 4;
  out_msg := 'Zone value is required';
  return;
end if;

if rtrim(in_prono) is null then
  out_errorno := 2;
  out_msg := 'Pro Number value is required';
  return;
end if;

pn := null;
open curProNo;
fetch curProNo into pn;
close curProNo;
if pn.prono is not null then
  out_errorno := 3;
  out_msg := 'Duplicate Pro Number value ' || in_prono;
  return;
end if;

pn.seq := zprono.max_prono_seq(in_carrier,in_zone) + 1;

insert into carrierprono
(carrier,seq,prono,assign_status,lastuser,lastupdate,zone)
values
(in_carrier,pn.seq,in_prono,'U','IMPEXP',sysdate,in_zone);

exception when others then
  out_errorno := sqlcode;
  out_msg := substr(sqlerrm,1,80);
end import_prono;

end zimportprocprono;
/
show error package body zimportprocprono;
--exit;
