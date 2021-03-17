create or replace PACKAGE BODY alps.zmstrplt
IS
--
-- $Id$
--

FUNCTION plate_mstrplt
(in_lpid IN varchar2
) return varchar2 is

cursor curParentLip(in_lip varchar2) is
  select parentlpid
    from plate
   where lpid = in_lip;
pl curParentLip%rowtype;

strLpid plate.lpid%type;
cntLoop integer;

begin

strLpid := in_lpid;
pl.ParentLpid := 'x';
cntLoop := 0;
while (cntLoop < 64)
loop
  open curParentLip(strLpid);
  fetch curParentLip into pl;
  if curParentLiP%notfound then
    close curParentLiP;
    exit;
  end if;
  close curParentLiP;
  if pl.parentlpid is null then
   exit;
  end if;
  strLpid := pl.parentlpid;
  cntLoop := cntLoop + 1;
end loop;

return strLpid;

exception when others then
  return in_lpid;
end plate_mstrplt;

FUNCTION plate_item
(in_lpid IN varchar2
) return varchar2 is

out_item plate.item%type;

begin

select item
  into out_item
  from plate
 where lpid = in_lpid;

return out_item;

exception when others then
  return null;
end plate_item;

FUNCTION plate_custid
(in_lpid IN varchar2
) return varchar2 is

out_custid plate.custid%type;

begin

select custid
  into out_custid
  from plate
 where lpid = in_lpid;

return out_custid;

exception when others then
  return null;
end plate_custid;

FUNCTION plate_location
(in_lpid IN varchar2
) return varchar2 is

out_location plate.location%type;

begin

select location
  into out_location
  from plate
 where lpid = in_lpid;

return out_location;

exception when others then
  return null;
end plate_location;

FUNCTION plate_status
(in_lpid IN varchar2
) return varchar2 is

out_status plate.status%type;

begin

select status
  into out_status
  from plate
 where lpid = in_lpid;

return out_status;

exception when others then
  return null;
end plate_status;

FUNCTION plate_qty
(in_lpid IN varchar2
) return number is

out_qty plate.quantity%type;

begin

select quantity
  into out_qty
  from plate
 where lpid = in_lpid;

return out_qty;

exception when others then
  return null;
end plate_qty;

FUNCTION plate_weight
(in_lpid IN varchar2
) return number is

out_weight plate.weight%type;

begin

select weight
  into out_weight
  from plate
 where lpid = in_lpid;

return out_weight;

exception when others then
  return null;
end plate_weight;

FUNCTION shipplate_mstrplt
(in_lpid IN varchar2
) return varchar2 is

cursor curParentLip(in_lip varchar2) is
  select parentlpid
    from shippingplate
   where lpid = in_lip;
pl curParentLip%rowtype;

strLpid plate.lpid%type;
cntLoop integer;

begin

strLpid := in_lpid;
pl.ParentLpid := 'x';
cntLoop := 0;
while (cntLoop < 64)
loop
  open curParentLip(strLpid);
  fetch curParentLip into pl;
  if curParentLiP%notfound then
    close curParentLiP;
    exit;
  end if;
  close curParentLiP;
  if pl.parentlpid is null then
   exit;
  end if;
  strLpid := pl.parentlpid;
  cntLoop := cntLoop + 1;
end loop;

return strLpid;

exception when others then
  return in_lpid;
end shipplate_mstrplt;

FUNCTION shipplate_mstrplt_label
(in_lpid IN varchar2
) return varchar2 is

cursor curParentLip(in_lip varchar2) is
  select parentlpid,
         fromlpid
    from shippingplate
   where lpid = in_lip;
pl curParentLip%rowtype;

strLpid plate.lpid%type;
cntLoop integer;

begin

strLpid := in_lpid;
pl.ParentLpid := 'x';
cntLoop := 0;
while (cntLoop < 64)
loop
  open curParentLip(strLpid);
  fetch curParentLip into pl;
  if curParentLiP%notfound then
    close curParentLiP;
    exit;
  end if;
  close curParentLiP;
  if pl.parentlpid is null then
   exit;
  end if;
  strLpid := pl.parentlpid;
  cntLoop := cntLoop + 1;
end loop;

if pl.fromlpid is not null then
  return pl.fromlpid;
else
  return strLpid;
end if;

exception when others then
  return in_lpid;
end shipplate_mstrplt_label;

FUNCTION shipplate_item
(in_lpid IN varchar2
) return varchar2 is

out_item shippingplate.item%type;

begin

select item
  into out_item
  from shippingplate
 where lpid = in_lpid;

return out_item;

exception when others then
  return null;
end shipplate_item;

FUNCTION shipplate_custid
(in_lpid IN varchar2
) return varchar2 is

out_custid shippingplate.custid%type;

begin

select custid
  into out_custid
  from shippingplate
 where lpid = in_lpid;

return out_custid;

exception when others then
  return null;
end shipplate_custid;

FUNCTION shipplate_location
(in_lpid IN varchar2
) return varchar2 is

out_location shippingplate.location%type;

begin

select location
  into out_location
  from shippingplate
 where lpid = in_lpid;

return out_location;

exception when others then
  return null;
end shipplate_location;

FUNCTION shipplate_status
(in_lpid IN varchar2
) return varchar2 is

out_status shippingplate.status%type;

begin

select status
  into out_status
  from shippingplate
 where lpid = in_lpid;

return out_status;

exception when others then
  return null;
end shipplate_status;

FUNCTION shipplate_qty
(in_lpid IN varchar2
) return number is

out_qty shippingplate.quantity%type;

begin

select quantity
  into out_qty
  from shippingplate
 where lpid = in_lpid;

return out_qty;

exception when others then
  return null;
end shipplate_qty;

FUNCTION shipplate_weight
(in_lpid IN varchar2
) return number is

out_weight shippingplate.weight%type;

begin

select weight
  into out_weight
  from shippingplate
 where lpid = in_lpid;

return out_weight;

exception when others then
  return null;
end shipplate_weight;

FUNCTION shipplate_trackingno
(in_lpid IN varchar2
) return varchar2 is

out_trackingno shippingplate.trackingno%type;

begin

select trackingno
  into out_trackingno
  from shippingplate
 where lpid = in_lpid;

return out_trackingno;

exception when others then
  return null;
end shipplate_trackingno;

FUNCTION shipplate_type
(in_lpid IN varchar2
) return varchar2 is

out_type shippingplate.type%type;

begin

select type
  into out_type
  from shippingplate
 where lpid = in_lpid;

return out_type;

exception when others then
  return null;
end shipplate_type;

FUNCTION shipplate_fromlpid
(in_lpid IN varchar2
) return varchar2 is

out_fromlpid shippingplate.fromlpid%type;

begin

select fromlpid
  into out_fromlpid
  from shippingplate
 where lpid = in_lpid;

return out_fromlpid;

exception when others then
  return null;
end shipplate_fromlpid;

FUNCTION shipplate_invclass
(in_lpid IN varchar2
) return varchar2 is

out_invclass shippingplate.inventoryclass%type;

begin

select inventoryclass
  into out_invclass
  from shippingplate
 where lpid = in_lpid;

return out_invclass;

exception when others then
  return null;
end shipplate_invclass;

end zmstrplt;
/
show error package body zmstrplt;
exit;
