create or replace package body alps.zcatchweight as
--
-- $Id$
--


-- Private functions


function uom_to_uom
   (in_custid   in varchar2,
    in_item     in varchar2,
    in_qty      in number,
    in_from_uom in varchar2,
    in_to_uom   in varchar2,
    in_skips    in varchar2,
    in_level    in integer)
return number
is
   l_qty number := -1;
   l_level number;
   errmsg VARCHAR2(200);
begin

   l_level := in_level;
   
   zbut.from_uom_to_uom(in_custid, in_item, in_qty, in_to_uom, in_from_uom, in_skips, l_level,
      l_qty, errmsg);

   if (errmsg <> 'OKAY') then
      l_qty := -1;
   end if;

   return l_qty;

exception
   when OTHERS then
      return -1;
end uom_to_uom;


-- Public functions


function item_avg_weight
   (in_custid in varchar2,
    in_item   in varchar2,
    in_uom    in varchar2)
return number
is
	cursor c_cwt is
     	select uom,
      		 nvl(totqty, 0) as qty,
             totweight as weight
         from custitemcatchweight
         where custid = in_custid
           and item = in_item;
	cwt c_cwt%rowtype;
   l_weight plate.weight%type := 0;
   l_factor number;
begin
	open c_cwt;
   fetch c_cwt into cwt;
   close c_cwt;

   if nvl(cwt.qty, 0) > 0 then
      l_factor := uom_to_uom(in_custid, in_item, 1, cwt.uom, in_uom, '', 1);
      if l_factor != -1 then
         l_weight := l_factor * cwt.weight / cwt.qty;
      end if;
	end if;

   return l_weight;

exception
   when OTHERS then
      return 0;
end item_avg_weight;


function lp_item_weight
   (in_lpid   in varchar2,
    in_custid in varchar2,
    in_item   in varchar2,
    in_uom    in varchar2)
return number
is
	cursor c_lp is
   	select weight, quantity, unitofmeasure
      	from plate
         where lpid = in_lpid;
	lp c_lp%rowtype;
   l_found boolean;
   l_weight plate.weight%type := 0;
   l_factor number;
begin
	open c_lp;
  	fetch c_lp into lp;
   l_found := c_lp%found;
  	close c_lp;
  	if l_found and (lp.quantity > 0) then
      l_factor := uom_to_uom(in_custid, in_item, 1, lp.unitofmeasure, in_uom, '', 1);
      if l_factor != -1 then
         l_weight := l_factor * lp.weight / lp.quantity;
      end if;
	end if;

  	if l_weight = 0 then
		l_weight := zci.item_weight(in_custid, in_item, in_uom);
	end if;

   return l_weight;
end lp_item_weight;


function ship_lp_item_weight
   (in_lpid   in varchar2,
    in_custid in varchar2,
    in_item   in varchar2,
    in_uom    in varchar2)
return number
is
	cursor c_slp is
   	select weight, quantity, unitofmeasure
      	from shippingplate
         where lpid = in_lpid;
	slp c_slp%rowtype;
   l_found boolean;
   l_weight plate.weight%type := 0;
   l_factor number;
begin
	open c_slp;
  	fetch c_slp into slp;
   l_found := c_slp%found;
  	close c_slp;
  	if l_found and (slp.quantity > 0) then
      l_factor := uom_to_uom(in_custid, in_item, 1, slp.unitofmeasure, in_uom, '', 1);
      if l_factor != -1 then
         l_weight := l_factor * slp.weight / slp.quantity;
      end if;
	end if;

  	if l_weight = 0 then
		l_weight := zci.item_weight(in_custid, in_item, in_uom);
	end if;

   return l_weight;
end ship_lp_item_weight;


function maxleftoverweight
return number
is
   l_value number := 999999999;
begin
   select nvl(defaultvalue,999999999) into l_value
      from systemdefaults
      where defaultid = 'MAXLEFTOVERWEIGHT';
   return l_value;

exception
   when OTHERS then
      return 999999999;
end maxleftoverweight;


-- Public procedures


procedure set_item_catch_weight
   (in_custid   in varchar2,
    in_item     in varchar2,
    in_orderid  in number,
    in_shipid   in number,
    in_qty      in number,
    in_uom      in varchar2,
    in_weight   in number,
    in_user     in varchar2,
    out_message out varchar2)
is
   cursor c_itv(p_custid varchar2, p_item varchar2) is
      select baseuom, use_catch_weights
         from custitemview
         where custid = p_custid
           and item = p_item;
   itv c_itv%rowtype;
   cursor c_cwt(p_custid varchar2, p_item varchar2) is
      select orderid, shipid, uom, rowid
         from custitemcatchweight
         where custid = p_custid
           and item = p_item;
   cwt c_cwt%rowtype;
   cursor c_oh(p_orderid number, p_shipid number) is
   	select entrydate
      	from orderhdr
         where orderid = p_orderid
           and shipid = p_shipid;
	prev_oh c_oh%rowtype := null;
   new_oh c_oh%rowtype := null;
   l_found boolean;
   l_baseuomqty number;
   l_msg varchar2(255);
begin
   out_message := null;

   open c_itv(in_custid, in_item);
   fetch c_itv into itv;
 	l_found := c_itv%found;
   close c_itv;

   if (l_found) and (itv.use_catch_weights = 'Y') then
   	zbut.translate_uom(in_custid, in_item, in_qty, in_uom, itv.baseuom,
      		l_baseuomqty, l_msg);
	   if l_msg = 'OKAY' then
		   open c_cwt(in_custid, in_item);
   		fetch c_cwt into cwt;
   		l_found := c_cwt%found;
	   	close c_cwt;

			if not l_found then
      		insert into custitemcatchweight
   				(custid, item, orderid, shipid, uom,
            	 totqty, totweight, lastuser, lastupdate)
				values
   	      	(in_custid, in_item, in_orderid, in_shipid, itv.baseuom,
					 l_baseuomqty, in_weight, in_user, sysdate);
      	elsif ((cwt.orderid = in_orderid) and (cwt.shipid = in_shipid))
			    or ((in_orderid = 0) and (in_shipid = 0)) then
--				same order or loc load/fill
				if cwt.uom = itv.baseuom then
   	   	   update custitemcatchweight
      	   	   set totqty = totqty + l_baseuomqty,
         	          totweight = totweight + in_weight,
            	       lastuser = in_user,
               	    lastupdate = sysdate
					   where rowid = cwt.rowid;
				else
--				someone changed the baseuom
      		   update custitemcatchweight
         		   set uom = itv.baseuom,
	         	       totqty = l_baseuomqty,
   	                totweight = in_weight,
      	             lastuser = in_user,
         	          lastupdate = sysdate
					   where rowid = cwt.rowid;
				end if;
			else
--				different order - ignore if older than current
   			open c_oh(cwt.orderid, cwt.shipid);
   			fetch c_oh into prev_oh;
   			close c_oh;
   			open c_oh(in_orderid, in_shipid);
   			fetch c_oh into new_oh;
   			close c_oh;
				if new_oh.entrydate > prev_oh.entrydate then
      		   update custitemcatchweight
         		   set orderid = in_orderid,
            	       shipid = in_shipid,
                      uom = itv.baseuom,
	         	       totqty = l_baseuomqty,
   	                totweight = in_weight,
      	             lastuser = in_user,
         	          lastupdate = sysdate
					   where rowid = cwt.rowid;
				end if;
			end if;
		end if;
	end if;

   out_message := 'OKAY';

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end set_item_catch_weight;


procedure adjust_shippingplate_weight
	(in_lpid      in varchar2,
    in_weight    in number,
    in_user      in varchar2,
    out_parentlp out varchar2,
    out_message  out varchar2)
is
	cursor c_sp is
   	select type, fromlpid, parentlpid, weight, status, orderid, shipid,
      		 orderitem, orderlot, loadno, stopno, shipno, custid
      	from shippingplate
         where lpid = in_lpid;
	sp c_sp%rowtype;
   l_found boolean;
   l_weight plate.weight%type;
begin
   out_message := null;
   out_parentlp := '(none)';

	open c_sp;
  	fetch c_sp into sp;
   l_found := c_sp%found;
  	close c_sp;
  	if not l_found then
   	out_message := 'Plate not found';
		return;
	end if;

	if sp.status not in ('S', 'L', 'FA') then
   	out_message := 'Invalid plate status';
		return;
	end if;

	update shippingplate
   	set weight = in_weight,
          lastuser = in_user,
          lastupdate = sysdate
		where lpid = in_lpid;

	if sp.type = 'F' then
	   update plate
      	set weight = in_weight,
         	 lastuser = in_user,
             lastupdate = sysdate
			where lpid = sp.fromlpid;
	elsif sp.type != 'P' then
      select nvl(sum(weight), 0) into l_weight
   	   from shippingplate
         where type in ('F','P')
         start with lpid = in_lpid
         connect by prior lpid = parentlpid;
		if in_weight < l_weight then
      	out_message := 'Wt < child LP total';
         return;
		end if;
	end if;

	if sp.parentlpid is not null then
	   update shippingplate
   	   set weight = weight + in_weight - sp.weight,
             lastuser = in_user,
             lastupdate = sysdate
		   where lpid = sp.parentlpid;
		out_parentlp := sp.parentlpid;
	end if;

   update orderdtl
      set weightpick = nvl(weightpick, 0)+in_weight-sp.weight,
     	    weight2sort = decode(nvl(weight2sort, 0), 0, 0, weight2sort+in_weight-sp.weight),
     	    weight2check = decode(nvl(weight2check, 0), 0, 0, weight2check+in_weight-sp.weight),
     	    weight2pack = decode(nvl(weight2pack, 0), 0, 0, weight2pack+in_weight-sp.weight),
     	    weightship = decode(sp.status, 'L', nvl(weightship, 0)+in_weight-sp.weight, weightship),
          lastuser = in_user,
          lastupdate = sysdate
     	where orderid = sp.orderid
        and shipid = sp.shipid
        and item = sp.orderitem
        and nvl(lotnumber, '(none)') = nvl(sp.orderlot, '(none)');

   if sp.status = 'L' then
	   update loadstopship
   	  	set weightship = nvl(weightship, 0)+in_weight-sp.weight,
            weightship_kgs = nvl(weightship_kgs,0)
                           + nvl(zwt.from_lbs_to_kgs(sp.custid,in_weight),0)
                           - nvl(zwt.from_lbs_to_kgs(sp.custid,sp.weight),0),
		        lastuser = in_user,
      		  lastupdate = sysdate
		   where loadno = sp.loadno
         and stopno = sp.stopno
		     and shipno = sp.shipno;
	end if;

	out_message := 'OKAY';

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end adjust_shippingplate_weight;


procedure process_weight_difference
   (in_lpid           in varchar2,
    in_picked_weight  in number,
    in_prev_lp_weight in number,
    in_user           in varchar2,
    in_picktype       in varchar2,
    out_message       out varchar2)
is
   cursor c_lp(p_lpid varchar2) is
   	select *
      	from plate
         where lpid = p_lpid;
   cursor c_dlp(p_lpid varchar2) is
   	select *
      	from deletedplate
         where lpid = p_lpid;
	lp c_lp%rowtype := null;
   cursor c_itv(p_custid varchar2, p_item varchar2) is
      select min0qtysuspenseweight
         from custitemview
         where custid = p_custid
           and item = p_item;
   itv c_itv%rowtype := null;
   l_newlpid plate.lpid%type;
   l_msg varchar2(80);
   l_weight plate.weight%type := 0;
   l_found boolean;
begin
   out_message := null;

   if in_picked_weight <= 0 then
      return;
   end if;

   open c_lp(in_lpid);
   fetch c_lp into lp;
	l_found := c_lp%found;
   close c_lp;

-- taking everything
   if in_picktype = 'F' then
      if in_picked_weight != lp.weight then
	      update plate
            set weight = in_picked_weight,
             	 lastuser = in_user,
                lastoperator = in_user,
                lastupdate = sysdate
	         where lpid = in_lpid;

         if lp.type = 'MP' then
            update plate
               set weight = in_picked_weight * weight / lp.weight,
             	    lastuser = in_user,
                   lastoperator = in_user,
                   lastupdate = sysdate
	            where parentlpid = in_lpid;
         end if;

         l_weight := lp.weight - in_picked_weight;
      end if;

   elsif l_found then   -- plate still exists

--    just suspend (no plate updates) if weight would go negative
      if in_picked_weight > in_prev_lp_weight then
         l_weight := in_prev_lp_weight - in_picked_weight;

--    just update the plate
      elsif in_picked_weight < in_prev_lp_weight then
         update plate
            set weight = in_prev_lp_weight - in_picked_weight,
     	 	       lastuser = in_user,
                lastoperator = in_user,
                lastupdate = sysdate
            where lpid = in_lpid;

         if lp.type = 'MP' then
            update plate
               set weight = (in_prev_lp_weight - in_picked_weight) * weight / lp.weight,
             	    lastuser = in_user,
                   lastoperator = in_user,
                   lastupdate = sysdate
	            where parentlpid = in_lpid;
         end if;

      end if;

   else

-- plate is deleted, but we should be able to get the generic data from
-- the deletedplate table
      open c_dlp(in_lpid);
      fetch c_dlp into lp;
      close c_dlp;
      l_weight := in_prev_lp_weight - in_picked_weight;
   end if;
   if abs(l_weight) = 0 then
      return;
   end if;

   if lp.unitofmeasure is null then
      lp.unitofmeasure := zci.baseuom(lp.custid, lp.item);
   end if;

   open c_itv(lp.custid, lp.item);
   fetch c_itv into itv;
   close c_itv;
   if itv.min0qtysuspenseweight is null then
      begin
         select nvl(defaultvalue,0) into itv.min0qtysuspenseweight
            from systemdefaults
            where defaultid = 'MIN0QTYSUSPENSEWEIGHT';
      exception
         when OTHERS then
            itv.min0qtysuspenseweight := 0;
      end;
   end if;

   if abs(l_weight) >= itv.min0qtysuspenseweight then
     	zrf.get_next_lpid(l_newlpid, l_msg);
  	   if l_msg is not null then
     	   out_message := l_msg;
	   else
           if nvl(lp.loadno, 0) = 0
            and lp.anvdate is null then
            lp.anvdate := lp.creationdate;
           end if;

		   insert into plate
			   (lpid, item, custid, facility, location,
             status, holdreason, unitofmeasure, quantity, type,
             serialnumber, lotnumber, creationdate, manufacturedate, expirationdate,
             expiryaction, lastcountdate, po, recmethod, condition,
             lastoperator, fifodate, countryof, useritem1, useritem2,
             useritem3, disposition, lastuser, lastupdate, invstatus,
             qtyentered, itementered, uomentered, inventoryclass, loadno,
             stopno, shipno, orderid, shipid, weight,
             adjreason, qtyrcvd, controlnumber, qcdisposition, fromlpid,
             parentfacility, parentitem, prevlocation, anvdate)
		   values
			   (l_newlpid, lp.item, lp.custid, lp.facility, 'SUSPENSE',
             'A', lp.holdreason, lp.unitofmeasure, 0, 'PA',
             lp.serialnumber, lp.lotnumber, sysdate, lp.manufacturedate, lp.expirationdate,
             lp.expiryaction, lp.lastcountdate, lp.po, lp.recmethod, lp.condition,
             in_user, lp.fifodate, lp.countryof, lp.useritem1, lp.useritem2,
             lp.useritem3, lp.disposition, in_user, sysdate, 'SU',
             lp.qtyentered, lp.itementered, lp.uomentered, lp.inventoryclass, lp.loadno,
             lp.stopno, lp.shipno, lp.orderid, lp.shipid, l_weight,
             lp.adjreason, lp.qtyrcvd, lp.controlnumber, lp.qcdisposition, in_lpid,
             lp.facility, lp.item, lp.location, lp.anvdate);
	   end if;
   else
      l_newlpid := in_lpid;
   end if;

   l_msg := 'OKAY';
   if abs(l_weight) >= itv.min0qtysuspenseweight then
      zbill.add_asof_inventory(lp.facility, lp.custid, lp.item, lp.lotnumber,
            lp.unitofmeasure, sysdate, 0, l_weight, 'Suspense', 'AD', lp.inventoryclass,
            'SU', lp.orderid, lp.shipid, l_newlpid, in_user, l_msg);
   end if;
   if l_weight != 0 and l_msg = 'OKAY' then
--- insure item and uom are not null
      zbill.add_asof_inventory(lp.facility, lp.custid, lp.item, lp.lotnumber,
            lp.unitofmeasure, sysdate, 0, -l_weight, 'Suspense', 'AD', lp.inventoryclass,
            lp.invstatus, lp.orderid, lp.shipid, l_newlpid, in_user, l_msg);
   end if;
   if l_msg != 'OKAY' then
      out_message := l_msg;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end process_weight_difference;


procedure add_item_lot_catch_weight
   (in_facility  in varchar2,
    in_custid    in varchar2,
    in_item      in varchar2,
    in_lotnumber in varchar2,
    in_weight    in number,
    out_message  out varchar2)
is
   cursor c_itv(p_custid varchar2, p_item varchar2) is
      select use_catch_weights
         from custitemview
         where custid = p_custid
           and item = p_item;
   itv c_itv%rowtype;
   l_found boolean;
begin
   out_message := null;

   open c_itv(in_custid, in_item);
   fetch c_itv into itv;
 	l_found := c_itv%found;
   close c_itv;

   if (l_found) and (itv.use_catch_weights = 'Y') then
      update custitemlotcatchweight
         set totweight = totweight + in_weight
         where facility = in_facility
           and custid = in_custid
           and item = in_item
           and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)');
      if sql%rowcount = 0 then
		   insert into custitemlotcatchweight
	         (facility, custid, item, lotnumber, totweight)
			values
  	      	(in_facility, in_custid, in_item, in_lotnumber, in_weight);
      end if;
   end if;

   out_message := 'OKAY';

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end add_item_lot_catch_weight;


end zcatchweight;
/

show errors package body zcatchweight;
exit;
