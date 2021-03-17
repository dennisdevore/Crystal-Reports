--
-- $Id$
--
insert into consigneecarriers
select consignee,'L' as shiptype,0 as fromweight, 9999999 as toweight, ltlcarrier as carrier,null as lastuser,sysdate as lastupdate from consignee 
where ltlcarrier is not null 
union 
select consignee,'T' as shiptype,0 as fromweight, 9999999 as toweight, tlcarrier as carrier, null as lastuser,sysdate as lastupdate from consignee 
where tlcarrier is not null 
union 
select consignee,'S' as shiptype,0 as fromweight, 9999999 as toweight, spscarrier as carrier,null as lastuser,sysdate as lastupdate  from consignee 
where spscarrier is not null 
union 
select consignee,'R' as shiptype,0 as fromweight, 9999999 as toweight,  railcarrier as carrier,null as lastuser,sysdate as lastupdate from consignee 
where railcarrier is not null;


insert into customercarriers
select custid,'L' as shiptype,0 as fromweight, 9999999 as toweight, ltlcarrier as carrier,null as lastuser,sysdate as lastupdate from customer 
where ltlcarrier is not null 
union 
select custid,'T' as shiptype,0 as fromweight, 9999999 as toweight, tlcarrier as carrier, null as lastuser,sysdate as lastupdate from customer 
where tlcarrier is not null 
union 
select custid,'S' as shiptype,0 as fromweight, 9999999 as toweight, spscarrier as carrier,null as lastuser,sysdate as lastupdate  from customer 
where spscarrier is not null 
union 
select custid,'R' as shiptype,0 as fromweight, 9999999 as toweight,  railcarrier as carrier,null as lastuser,sysdate as lastupdate from customer 
where railcarrier is not null;

commit;

exit;