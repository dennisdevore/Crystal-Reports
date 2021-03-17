create or replace PACKAGE BODY alps.zvalidate
IS
--
-- $Id$
--

PROCEDURE validate_location
(in_facility IN varchar2
,in_locid IN varchar2
,in_loctype IN varchar2
,in_status IN varchar2
,in_msgprefix IN varchar2
,out_msg  IN OUT varchar2
) is

cursor Clocation(in_facility IN varchar2, in_location IN varchar2) is
  select nvl(loctype,'?') as loctype,
         nvl(status,'?') as status
    from location
   where facility = in_facility
     and locid = in_location;
lo Clocation%rowtype;
i integer;
statusfound boolean;

begin

open Clocation(in_facility, in_locid);
fetch Clocation into lo;
if Clocation%notfound then
  close Clocation;
  out_msg := in_msgprefix || ' not found: ' || in_locid;
  return;
end if;
close Clocation;

if rtrim(in_loctype) is not null then
  if lo.loctype <> in_loctype then
    out_msg := 'Invalid ' || in_msgprefix || ' type: ' || lo.loctype;
    return;
  end if;
end if;

if rtrim(in_status) is not null then
  statusfound := False;
  i := 1;
  while (i <= length(rtrim(in_status)))
  loop
    if substr(in_status,i,1) = lo.status then
      statusfound := True;
      exit;
    else
      i := i + 1;
    end if;
  end loop;
  if statusfound = False then
    out_msg := 'Invalid ' || in_msgprefix || ' status: ' || lo.status;
    return;
  end if;
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := substr(sqlerrm,1,80);
end validate_location;

PROCEDURE validate_carrier
(in_carrier IN varchar2
,in_carriertype IN varchar2
,in_carrierstatus IN varchar2
,out_msg  IN OUT varchar2
) is

cursor Ccarrier is
  select nvl(carrierstatus,'?') as carrierstatus,
         nvl(carriertype,'?') as carriertype
    from carrier
   where carrier = in_carrier;
ca Ccarrier%rowtype;

begin
  
open Ccarrier;
fetch Ccarrier into ca;
if Ccarrier%notfound then
  close Ccarrier;
  out_msg := 'Carrier not found: ' || in_carrier;
  return;
end if;
close Ccarrier;

if rtrim(in_carrierstatus) is not null then
  if ca.carrierstatus != in_carrierstatus then
    out_msg := 'Invalid Carrier status: ' || ca.carrierstatus;
    return;
  end if;
end if;

if rtrim(in_carriertype) is not null then
  if ca.carriertype != in_carriertype then
    out_msg := 'Invalid Carrier type: ' || ca.carriertype;
    return;
  end if;
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := substr(sqlerrm,1,80);
end validate_carrier;

end zvalidate;
/

exit;
