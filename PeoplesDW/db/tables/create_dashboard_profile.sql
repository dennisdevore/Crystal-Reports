
--drop table dashboard_profile;

create table alps.dashboard_profile
(
    code       number not null,
	  name	   varchar2(100) not null, 	
    descr      varchar2(100) null,
    timeframe char(20),
    compare_timeframe char(20),
    historical_average char(20),
    all_customers char(1),
    all_facilities char(1),
    facilities_ids varchar2(4000),
    customers_ids varchar2(4000),
    lastuser   varchar2(12) null,
    lastupdate date null
);

create unique index dashboard_profile_idx on 
    dashboard_profile(code);

alter table dashboard_profile add (
     constraint pk_dashboard_profile  primary key (code));

commit;

exit;
