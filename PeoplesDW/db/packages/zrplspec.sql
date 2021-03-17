--
-- $Id$
--
create or replace package alps.replenishment as

procedure process_replenish_request
(in_reqtype           in varchar2
,in_facility          in varchar2
,in_custid            in varchar2
,in_item              in varchar2
,in_locid             in varchar2
,in_userid            in varchar2
,in_trace             in varchar2
,out_errorno          in out number
,out_msg              in out varchar2);

procedure process_loc_replenishment
(in_reqtype           in varchar2
,in_facility          in varchar2
,in_custid            in varchar2
,in_item              in varchar2
,in_locid             in varchar2
,in_userid            in varchar2
,in_trace             in varchar2
,out_errorno          in out number
,out_msg              in out varchar2);

procedure process_kit_replenishment
(in_reqtype           in varchar2
,in_facility          in varchar2
,in_custid            in varchar2
,in_item              in varchar2
,in_locid             in varchar2
,in_userid            in varchar2
,in_trace             in varchar2
,out_errorno          in out number
,out_msg              in out varchar2);

procedure submit_replenish_request
(in_reqtype           in varchar2
,in_facility          in varchar2
,in_custid            in varchar2
,in_item              in varchar2
,in_locid             in varchar2
,in_userid            in varchar2
,in_trace             in varchar2
);

function loc_balance
(in_facility          in varchar2
,in_custid            in varchar2
,in_item              in varchar2
,in_locid             in varchar2
) return number;

function task_balance
(in_facility          in varchar2
,in_custid            in varchar2
,in_item              in varchar2
,in_locid             in varchar2
) return number;

procedure assigned_item_replenish
(in_facility          in varchar2
,in_custid            in varchar2
,in_item              in varchar2
,in_locid             in varchar2
,out_newitem          out varchar2
,out_newcustid        out varchar2
,out_errorno          out number
,out_msg              out varchar2
);

procedure validate_pick_front_drop
(in_lpid              in varchar2
,in_facility          in varchar2
,in_drop_loc          in varchar2
,out_pf_loc           in out varchar2
,out_errorno          in out number
);

PRAGMA RESTRICT_REFERENCES (loc_balance, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (task_balance, WNDS, WNPS, RNPS);

end replenishment;
/
show error package replenishment;
exit;
