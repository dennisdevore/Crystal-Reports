alter table parceltracking modify trackingno not null;

create unique index ptpk on parceltracking(trackingno);

alter table parceltracking
  add constraint pk_parceltracking primary key (trackingno);
  
exit;
