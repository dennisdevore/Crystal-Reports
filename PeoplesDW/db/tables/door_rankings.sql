drop table door_rankings;
create global temporary table door_rankings
(facility varchar2(3)
,loadno number
,doorloc varchar2(10)
,location varchar2(10)
,hops number(7)
,ranking number(7)
,lastuser varchar2(12)
,lastupdate date
) on commit preserve rows;
drop table door_item_class_summary;
create global temporary table door_item_class_summary
(loadno number
,custid varchar2(10)
,item varchar2(50)
,invclass varchar2(2)
,min_days_to_expiration number(4)
,qtyorder number(10)
,weight_entered_lbs number(10)
,weight_entered_kgs number(10)
,lastuser varchar2(12)
,lastupdate date
) on commit preserve rows;
exit;
