CREATE OR REPLACE VIEW RENEWALSVIEW ( FACILITY, 
CUSTID, RENEWAL ) AS select distinct
 F.facility
,C.custid
,D.nextrenewal
from  custbilldates D, customer C, Facility F
where (F.facility, C.custid) not in
     (select R.facility, R.custid
        from custlastrenewal R
       where R.facility = F.facility
         and R.custid = C.custid
         and R.lastrenewal = D.nextrenewal)
  and C.status = 'ACTV'
  and F.facilitystatus = 'A'
  and D.custid = C.custid
  and (zbut.check_asof(F.facility, C.custid, D.nextrenewal) like 'Y%' or
       zbut.check_expiregrace(F.facility, C.custid, D.nextrenewal) = 'Y');

-- exit;
