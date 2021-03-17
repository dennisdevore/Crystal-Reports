--
-- $Id$
--
CREATE or replace PACKAGE ZCYCLECOUNT
IS

PROCEDURE generate_cycle_count
(in_location in varchar2
,in_facility in varchar2
,in_userid in varchar2
,in_custid in varchar2 default null
,in_item in varchar2 default null
,in_itemvelocity in varchar2 default null 
,out_msg  IN OUT varchar2
);

PROCEDURE generate_cc_load_order
(in_loadno   in number
,in_orderid  in number
,in_facility in varchar2
,in_userid in varchar2
,out_msg  IN OUT varchar2
);

PROCEDURE execute_job
(in_descr in varchar2
,in_facility in varchar2);

PROCEDURE enqueue(
jobid OUT integer,
what IN varchar2,
startdate IN date,
interval IN varchar2
);

PROCEDURE setbroken(
  jobid in integer,
  broken in boolean,
  next_date in date
);


END zcyclecount;
/
-- exit;
