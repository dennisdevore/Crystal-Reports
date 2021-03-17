create or replace PACKAGE BODY alps.zallplate
IS
--
-- $Id$
--

FUNCTION expiration_date
(in_lpid IN varchar2
) return date is

out_data plate.expirationdate%type;

begin

begin
  select expirationdate
    into out_data
    from plate
   where lpid = in_lpid;
exception when no_data_found then
  select expirationdate
    into out_data
    from deletedplate
   where lpid = in_lpid;
end;

return out_data;

exception when others then
  return null;
end expiration_date;

FUNCTION expiry_action
(in_lpid IN varchar2
) return varchar2 is

out_data plate.expiryaction%type;

begin

begin
  select expiryaction
    into out_data
    from plate
   where lpid = in_lpid;
exception when no_data_found then
  select expiryaction
    into out_data
    from deletedplate
   where lpid = in_lpid;
end;

return out_data;

exception when others then
  return null;
end expiry_action;

FUNCTION po
(in_lpid IN varchar2
) return varchar2 is

out_data plate.po%type;

begin

begin
  select po
    into out_data
    from plate
   where lpid = in_lpid;
exception when no_data_found then
  select po
    into out_data
    from deletedplate
   where lpid = in_lpid;
end;

return out_data;

exception when others then
  return null;
end po;

FUNCTION rec_method
(in_lpid IN varchar2
) return varchar2 is

out_data plate.recmethod%type;

begin

begin
  select recmethod
    into out_data
    from plate
   where lpid = in_lpid;
exception when no_data_found then
  select recmethod
    into out_data
    from deletedplate
   where lpid = in_lpid;
end;

return out_data;

exception when others then
  return null;
end rec_method;

FUNCTION condition
(in_lpid IN varchar2
) return varchar2 is

out_data plate.condition%type;

begin

begin
  select condition
    into out_data
    from plate
   where lpid = in_lpid;
exception when no_data_found then
  select condition
    into out_data
    from deletedplate
   where lpid = in_lpid;
end;

return out_data;

exception when others then
  return null;
end condition;

FUNCTION last_operator
(in_lpid IN varchar2
) return varchar2 is

out_data plate.lastoperator%type;

begin

begin
  select lastoperator
    into out_data
    from plate
   where lpid = in_lpid;
exception when no_data_found then
  select lastoperator
    into out_data
    from deletedplate
   where lpid = in_lpid;
end;

return out_data;

exception when others then
  return null;
end last_operator;

FUNCTION last_task
(in_lpid IN varchar2
) return varchar2 is

out_data plate.lasttask%type;

begin

begin
  select lasttask
    into out_data
    from plate
   where lpid = in_lpid;
exception when no_data_found then
  select lasttask
    into out_data
    from deletedplate
   where lpid = in_lpid;
end;

return out_data;

exception when others then
  return null;
end last_task;

FUNCTION fifo_date
(in_lpid IN varchar2
) return date is

out_data plate.fifodate%type;

begin

begin
  select fifodate
    into out_data
    from plate
   where lpid = in_lpid;
exception when no_data_found then
  select fifodate
    into out_data
    from deletedplate
   where lpid = in_lpid;
end;

return out_data;

exception when others then
  return null;
end fifo_date;

end zallplate;
/
show error package body zallplate;
exit;
