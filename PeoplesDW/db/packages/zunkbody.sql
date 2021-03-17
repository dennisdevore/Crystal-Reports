create or replace package body alps.unknown as
--
-- $Id$
--


-- Public procedures


procedure add_unknown_item(in_custid   in varchar2,
                           in_item     in varchar2,
                           in_user     in varchar2,
                           out_message out varchar2) is
   cnt integer;
   des custitem.descr%type;
   abb custitem.abbrev%type;
begin
   out_message := null;

   select count(1) into cnt
      from custitem
      where custid = in_custid
        and item = in_item;

   if (cnt = 0) then
      if (in_item = UNK_RCPT_ITEM) then
         des := 'Unknown Receipt';
         abb := 'Unknown Rcpt';
      else
         des := 'Unknown Return';
         abb := 'Unknown Rtn';
      end if;
      insert into custitem
         (custid, item, descr, abbrev, status, rategroup,
          baseuom, lastuser, lastupdate, lotrequired, serialrequired,
          user1required, user2required, user3required, mfgdaterequired,
          expdaterequired, nodamaged, countryrequired, weightcheckrequired,
          ordercheckrequired)
      values
         (in_custid, in_item, des, abb, 'INAC', 'NONE',
          'EA', in_user, sysdate, 'N', 'N',
          'N', 'N', 'N', 'N',
          'N', 'N', 'N', 'N',
          'N');
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end add_unknown_item;


procedure build_unknown_lp(in_lpid           in varchar2,
                           in_facility       in varchar2,
                           in_location       in varchar2,
                           in_custid         in varchar2,
                           in_item           in varchar2,
                           in_qty            in number,
                           in_uom            in varchar2,
                           in_user           in varchar2,
                           in_loadno         in number,
                           in_stopno         in number,
                           in_shipno         in number,
                           in_orderid        in number,
                           in_shipid         in number,
                           in_invstatus      in varchar2,
                           in_lpstatus       in varchar2,
                           in_disposition    in varchar2,
                           in_po             in varchar2,
                           in_recmethod      in varchar2,
                           in_inventoryclass in varchar2,
                           in_condition      in varchar2,
                           out_message       out varchar2) is
begin
   out_message := null;

   insert into plate
      (lpid, item, custid, facility, location, status,
       unitofmeasure, quantity, type, creationdate, lastoperator, lastuser,
       lastupdate, invstatus, qtyentered, itementered, uomentered, inventoryclass,
       loadno, stopno, shipno, orderid, shipid, qtyrcvd,
       recmethod, disposition, po, condition,
       parentfacility, parentitem)
   values
      (in_lpid, in_item, in_custid, in_facility, in_location, in_lpstatus,
       in_uom, in_qty, 'PA', sysdate, in_user, in_user,
       sysdate, in_invstatus, in_qty, in_item, in_uom, in_inventoryclass,
       in_loadno, in_stopno, in_shipno, in_orderid, in_shipid, in_qty,
       in_recmethod, in_disposition, in_po, in_condition,
       in_facility, in_item);

   zunk.add_unknown_item(in_custid, in_item, in_user, out_message);

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end build_unknown_lp;


procedure del_unknown_lp(in_lpid       in varchar2,
                         in_item       in varchar2,
                         in_user       in varchar2,
                         out_message   out varchar2) is
   cursor c_lp is
      select type, custid, quantity, lotnumber, unitofmeasure,
             invstatus, inventoryclass
         from plate
         where lpid = in_lpid
           and item = in_item;
   lp c_lp%rowtype;
   cursor c_kids is
      select lpid, custid, quantity, lotnumber, unitofmeasure,
             invstatus, inventoryclass
         from plate
         where item = in_item
           and type = 'PA'
         start with lpid = in_lpid
         connect by prior lpid = parentlpid;
   rowfound boolean;
   err varchar(1);
   msg varchar(80);
begin
   out_message := null;

   open c_lp;
   fetch c_lp into lp;
   rowfound := c_lp%found;
   close c_lp;

   if not rowfound then
      return;
   end if;

   if (lp.type = 'PA') then
      zrf.decrease_lp(in_lpid, lp.custid, in_item, lp.quantity, lp.lotnumber,
            lp.unitofmeasure, in_user, null, lp.invstatus, lp.inventoryclass, err, out_message);
      return;
   end if;

   for k in c_kids loop
      zrf.decrease_lp(k.lpid, k.custid, in_item, k.quantity, k.lotnumber,
            k.unitofmeasure, in_user, null, k.invstatus, k.inventoryclass, err, msg);
      if ((err != 'N') or (msg is not null)) then
         out_message := msg;
         return;
      end if;
   end loop;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end del_unknown_lp;


procedure empty_unknown_lp(in_lpid       in varchar2,
                           in_user       in varchar2,
                           out_message   out varchar2) is
   cursor c_kids is
      select lpid
         from plate
         start with lpid = in_lpid
         connect by prior lpid = parentlpid;
   msg varchar(80) := null;
begin
   out_message := null;

-- delete plate and all children
   for k in c_kids loop
      zlp.plate_to_deletedplate(k.lpid, in_user, null, msg);
      if (msg is not null) then
         out_message := msg;
         return;
      end if;
   end loop;

-- remove plate from deleted table since we are going to "reuse" the lpid
   delete from deletedplate
      where lpid = in_lpid;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end empty_unknown_lp;


end unknown;
/

show errors package body unknown;
exit;
