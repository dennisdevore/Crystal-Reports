--drop index freight_sum_by_class_unique;

create unique index freight_sum_by_class_unique
   on freight_summary_by_class(loadno, stopno, freight_class);
 
exit;
