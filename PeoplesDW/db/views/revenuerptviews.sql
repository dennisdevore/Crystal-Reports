
CREATE OR REPLACE VIEW REVENURPTBACKOUTVIEW ( INVTYPE,
CODE, DESCR, ABBREV ) AS
select 'A' as invtype,code,descr,abbrev from backoutaccessorial
union
select 'M' as invtype,code,descr,abbrev from backoutmisc
union
select 'R' as invtype,code,descr,abbrev from backoutreceipt
union
select 'S' as invtype,code,descr,abbrev from backoutrenewal;

comment on table REVENURPTBACKOUTVIEW is '$Id';


CREATE OR REPLACE VIEW APRBLDINVDTLVIEW ( BILLSTATUS,
FACILITY, CUSTID, ORDERID, ITEM,
LOTNUMBER, ACTIVITY, ACTIVITYDATE, HANDLING,
INVOICE, INVDATE, INVTYPE, PO,
LPID, ENTEREDQTY, ENTEREDUOM, ENTEREDRATE,
ENTEREDAMT, CALCEDQTY, CALCEDUOM, CALCEDRATE,
CALCEDAMT, MINIMUM, BILLEDQTY, BILLEDRATE,
BILLEDAMT, EXPIREGRACE, STATUSRSN, EXCEPTRSN,
COMMENT1, LASTUSER, LASTUPDATE, STATUSUSER,
STATUSUPDATE, LOADNO, STOPNO, SHIPNO,
BILLMETHOD, ORDERITEM, ORDERLOT, SHIPID,
USEINVOICE, WEIGHT, MODUOM ) AS
select BILLSTATUS, FACILITY, CUSTID, ORDERID, ITEM, LOTNUMBER, ACTIVITY, ACTIVITYDATE, HANDLING, INVOICE,INVDATE, 	INVTYPE,PO,LPID, ENTEREDQTY,ENTEREDUOM, ENTEREDRATE,ENTEREDAMT, CALCEDQTY, CALCEDUOM,
	CALCEDRATE, CALCEDAMT, MINIMUM, BILLEDQTY, BILLEDRATE, BILLEDAMT, EXPIREGRACE, STATUSRSN, EXCEPTRSN, 		COMMENT1,LASTUSER,LASTUPDATE,STATUSUSER,STATUSUPDATE, LOADNO,STOPNO,SHIPNO,BILLMETHOD,ORDERITEM,ORDERLOT, 		SHIPID,USEINVOICE,WEIGHT,MODUOM
from invoicedtl where billstatus in (2,3);

comment on table APRBLDINVDTLVIEW is '$Id';


CREATE OR REPLACE VIEW REVENUEDTLRPTVIEW ( REVTYPE,
REVTYPEDESCR, REVSUBTYPE, REVSUBTYPEDESCR, INVOICE,
FACILITY, CUSTID, INVDATE, ACTIVITY,
BILLEDQTY, BILLEDAMT, REVENUEGROUP, FIRSTOFMONTH,
FIRSTOFWEEK, TRUELINK ) AS
select c.abbrev as revtype,c.descr as revtypedescr,d.abbrev as revsubtype,d.descr as revsubtypedescr,
	 invoice,facility,custid,invdate,activity,
	   billedqty,billedamt, revenuegroup,   zdtc.firstOfMonth(invdate) as firstofmonth ,
	 zdtc.firstOfWeekSunToSat(invdate) as firstOfWeek,
	1 as truelink
from aprbldinvdtlview a, activity b, revenuereportgroups c,invoicetypes d
where a.activity = b.code and
	  invtype = 'A' and
	  invtype = d.code and
	  b.revenuegroup = c.code and
	  b.revenuegroup  in
	  (select code from revenurptbackoutview
	  		  where invtype = 'A')
union all
select c.abbrev as revtype,c.descr as revtypedescr,null as revsubtype,null as revsubtypedescr,
	 invoice,facility,custid,invdate,activity,
	billedqty,billedamt, revenuegroup,   zdtc.firstOfMonth(invdate) as firstofmonth,
	zdtc.firstOfWeekSunToSat(invdate) as firstOfWeek,
	1 as truelink
from aprbldinvdtlview a, activity b, invoicetypes c
where a.activity = b.code and
	  invtype = 'A' and
	  invtype = c.code and
	  b.revenuegroup  not in
	  (select code from revenurptbackoutview
	  		  where invtype = 'A')
union all
select c.abbrev as revtype,c.descr as revtypedescr,d.abbrev as revsubtype,d.descr as revsubtypedescr,
	 invoice,facility,custid,invdate,activity,
	  billedqty,billedamt, revenuegroup,   zdtc.firstOfMonth(invdate) as firstofmonth ,
	 zdtc.firstOfWeekSunToSat(invdate) as firstOfWeek,
	1 as truelink
from aprbldinvdtlview a, activity b, revenuereportgroups c,invoicetypes d
where a.activity = b.code and
	  invtype = 'M' and
	  invtype = d.code and
	  b.revenuegroup = c.code and
	  b.revenuegroup  in
	  (select code from revenurptbackoutview
	  		  where invtype = 'M')
union all
select c.abbrev as revtype,c.descr as revtypedescr,null as revsubtype,null as revsubtypedescr,
	invoice,facility,custid,invdate,activity,
	billedqty,billedamt, revenuegroup,   zdtc.firstOfMonth(invdate) as firstofmonth,
	zdtc.firstOfWeekSunToSat(invdate) as firstOfWeek,
	1 as truelink
from aprbldinvdtlview a, activity b, invoicetypes c
where a.activity = b.code and
	  invtype = 'M' and
	  invtype = c.code and
	  b.revenuegroup  not in
	  (select code from revenurptbackoutview
	  		  where invtype = 'M')		
union all
select c.abbrev as revtype,c.descr as revtypedescr,d.abbrev as revsubtype,d.descr as revsubtypedescr,
	 invoice,facility,custid,invdate,activity,
	   billedqty,billedamt, revenuegroup,   zdtc.firstOfMonth(invdate) as firstofmonth ,
	zdtc.firstOfWeekSunToSat(invdate) as firstOfWeek,
	1 as truelink
from aprbldinvdtlview a, activity b, revenuereportgroups c,invoicetypes d
where a.activity = b.code and
	  invtype = 'R' and
	  invtype = d.code and
	  b.revenuegroup = c.code and
	  b.revenuegroup  in
	  (select code from revenurptbackoutview
	  		  where invtype = 'R')
union all
select c.abbrev as revtype,c.descr as revtypedescr,null as revsubtype,null as revsubtypedescr,
	invoice,facility,custid,invdate,activity,
	billedqty,billedamt, revenuegroup,   zdtc.firstOfMonth(invdate) as firstofmonth,
	zdtc.firstOfWeekSunToSat(invdate) as firstOfWeek,
	1 as truelink
from aprbldinvdtlview a, activity b, invoicetypes c
where a.activity = b.code and
	  invtype = 'R' and
	  invtype = c.code and
	  b.revenuegroup  not in
	  (select code from revenurptbackoutview
	  		  where invtype = 'R')					  	
union all
select c.abbrev as revtype,c.descr as revtypedescr,d.abbrev as revsubtype,d.descr as revsubtypedescr,
	 invoice,facility,custid,invdate,activity,
	 billedqty,billedamt, revenuegroup,   zdtc.firstOfMonth(invdate) as firstofmonth,
	zdtc.firstOfWeekSunToSat(invdate) as firstOfWeek,
	1 as truelink
from aprbldinvdtlview a, activity b, revenuereportgroups c,invoicetypes d
where a.activity = b.code and
	  invtype = 'S' and
	  invtype = d.code and
	  b.revenuegroup = c.code and
	  b.revenuegroup  in
	  (select code from revenurptbackoutview
	  		  where invtype = 'S')
union all
select c.abbrev as revtype,c.descr as revtypedescr,null as revsubtype,null as revsubtypedescr,
	invoice,facility,custid,invdate,activity,
	billedqty,billedamt, revenuegroup,   zdtc.firstOfMonth(invdate) as firstofmonth,
	zdtc.firstOfWeekSunToSat(invdate) as firstOfWeek,
	1 as truelink
from aprbldinvdtlview a, activity b, invoicetypes c
where a.activity = b.code and
	  invtype = 'S' and
	  invtype = c.code and
	  b.revenuegroup  not in
	  (select code from revenurptbackoutview
	  		  where invtype = 'S')	
union all
select c.abbrev as revtype,c.descr as revtypedescr,null as revsubtype,null as revsubtypedescr,
	invoice,facility,custid,invdate,activity,
	billedqty * -1,billedamt * -1, revenuegroup,   zdtc.firstOfMonth(invdate) as firstofmonth,
	zdtc.firstOfWeekSunToSat(invdate) as firstOfWeek,
	1 as truelink
from aprbldinvdtlview a, activity b, invoicetypes c
where a.activity = b.code and
	  invtype = 'C' and
	  invtype = c.code;

comment on table REVENUEDTLRPTVIEW is '$Id';


CREATE OR REPLACE VIEW LABORCNTRPTVIEW ( REVTYPE,
REVTYPEDESCR, REVSUBTYPE, REVSUBTYPEDESCR, INVOICE,
FACILITY, CUSTID, INVDATE, ACTIVITY,
BILLEDQTY, BILLEDAMT, REVENUEGROUP, FIRSTOFMONTH,
FIRSTOFWEEK, TRUELINK ) AS
select REVTYPE,REVTYPEDESCR,REVSUBTYPE,REVSUBTYPEDESCR,INVOICE,FACILITY,CUSTID,
	INVDATE,ACTIVITY,BILLEDQTY,BILLEDAMT,REVENUEGROUP,FIRSTOFMONTH,FIRSTOFWEEK,TRUELINK
	from revenuedtlrptview
where revtype in
(select rtrim(code) from
 laborreportcountgroups);

comment on table LABORCNTRPTVIEW is '$Id';


CREATE OR REPLACE VIEW LABORDTLRPTVIEW ( REVTYPE,
REVTYPEDESCR, REVSUBTYPE, REVSUBTYPEDESCR, INVOICE,
FACILITY, CUSTID, INVDATE, ACTIVITY,
BILLEDQTY, BILLEDAMT, REVENUEGROUP, FIRSTOFMONTH,
FIRSTOFWEEK, TRUELINK ) AS select REVTYPE,REVTYPEDESCR,REVSUBTYPE,REVSUBTYPEDESCR,INVOICE,FACILITY,
	CUSTID,INVDATE,ACTIVITY,BILLEDQTY,BILLEDAMT,REVENUEGROUP,FIRSTOFMONTH,FIRSTOFWEEK,TRUELINK
	from revenuedtlrptview
where revtype in
	(select rtrim(code) from laborreportgroups);

comment on table LABORDTLRPTVIEW is '$Id';


exit;

