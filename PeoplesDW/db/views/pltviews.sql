CREATE OR REPLACE VIEW PALLETHISTORYVIEW ( CUSTID, 
FACILITY, PALLETTYPE, ADJREASON, LOADNO, 
CNT, ADJUSTREASON, PALLETNAME, FACNAME, 
CUSTNAME ) as
select a.custid,a.facility,a.pallettype,nvl(a.adjreason,'NIL') as ADJREASON ,nvl(a.LOADNO,0) as LOADNO,a.inpallets - a.outpallets as cnt,  
 		nvl(b.descr,'NONE') as adjustreason,   
 		c.descr as palletname,    
	   d.name as facname,   
	   e.name as custname   
from pallethistory a, palletinvadjreason b, pallettypes c, facility d, customer e   
where a.adjreason = b.code(+) and    
	  a.pallettype = c.code and   
	  a.facility = d.facility and   
	  a.custid = e.custid;

comment on table PALLETHISTORYVIEW is '$Id$';
