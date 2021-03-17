alter table lateshipreasons
  modify (code   not null)
  modify (descr  not null)
  modify (abbrev not null);
  
create unique index lateshipreasons_idx on lateshipreasons(code);

/
