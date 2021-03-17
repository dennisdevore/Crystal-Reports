--
-- $Id$
--
update custitem
	set cube = cube * 1728;

update custitemuom
	set cube = cube * 1728;
commit;


update batchtasks
	set cube = qty * zci.item_cube(custid, item, uom);
commit;


begin
	for od in (select D.rowid, H.custid
   					from orderdtl D, orderhdr H
                  where D.orderid = H.orderid
                    and D.shipid = H.shipid) loop
		update orderdtl
			set cubeorder = qtyorder * zci.item_cube(od.custid, item, uom),
				 cubecommit = qtycommit * zci.item_cube(od.custid, item, uom),
			    cubeship = qtyship * zci.item_cube(od.custid, item, uom),
			    cubetotcommit = qtytotcommit * zci.item_cube(od.custid, item, uom),
			    cubercvd = qtyrcvd * zci.item_cube(od.custid, item, uom),
			    cubercvdgood = qtyrcvdgood * zci.item_cube(od.custid, item, uom),
			    cubercvddmgd = qtyrcvddmgd * zci.item_cube(od.custid, item, uom),
			    cubepick = qtypick * zci.item_cube(od.custid, item, uom),
			    cube2sort = qty2sort * zci.item_cube(od.custid, item, uom),
			    cube2pack = qty2pack * zci.item_cube(od.custid, item, uom),
			    cube2check = qty2check * zci.item_cube(od.custid, item, uom)
      	where rowid = od.rowid;
	end loop;
end;
/
commit;


begin
	for od in (select D.rowid, H.custid
   					from neworderdtl D, neworderhdr H
                  where D.orderid = H.orderid
                    and D.shipid = H.shipid) loop
		update neworderdtl
			set cubeorder = qtyorder * zci.item_cube(od.custid, item, uom)
      	where rowid = od.rowid;
	end loop;
end;
/
commit;


begin
	for od in (select D.rowid, H.custid
   					from oldorderdtl D, oldorderhdr H
                  where D.orderid = H.orderid
                    and D.shipid = H.shipid) loop
		update oldorderdtl
			set cubeorder = qtyorder * zci.item_cube(od.custid, item, uom)
      	where rowid = od.rowid;
	end loop;
end;
/
commit;


update subtasks
	set cube = qty * zci.item_cube(custid, item, uom);
commit;


update tasks T
	set cube = (select sum(S.cube) from subtasks S where S.taskid = T.taskid);
commit;


update loadstopship L
	set cubeorder = (select sum(O.cubeorder) from orderhdr O
    			where O.loadno = L.loadno and O.stopno=L.stopno),
   	 cubeship = (select sum(O.cubeship) from orderhdr O
            where O.loadno = L.loadno and O.stopno=L.stopno),
     	 cubercvd = (select sum(O.cubercvd) from orderhdr O
            where O.loadno = L.loadno and O.stopno=L.stopno);
commit;
