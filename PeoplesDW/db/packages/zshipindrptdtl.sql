-- Individual Shipping Report - productivity

create or replace package zshipindrpt_dtlpkg
   as type zshipindrpt_dtl_type is ref cursor return zshipindrpt_dtl%rowtype;
end zshipindrpt_dtlpkg;
/


create or replace procedure zshipindrpt_dtlproc
   (zshipindrpt_dtl_cursor in out zshipindrpt_dtlpkg.zshipindrpt_dtl_type,
    in_sessionid in number,
    in_begdate   in date,
    in_enddate   in date)
is
--
-- $Id$
--
begin

   open zshipindrpt_dtl_cursor for
      select *
         from zshipindrpt_dtl
         where sessionid = in_sessionid
         order by userid, baseuom;

end zshipindrpt_dtlproc;
/


show errors package zshipindrpt_dtlpkg;
show errors procedure zshipindrpt_dtlproc;
exit;
