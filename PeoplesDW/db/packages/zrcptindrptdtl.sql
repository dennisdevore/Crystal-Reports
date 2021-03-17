-- Individual Receiving Report - productivity

create or replace package zrcptindrpt_dtlpkg
   as type zrcptindrpt_dtl_type is ref cursor return zrcptindrpt_dtl%rowtype;
end zrcptindrpt_dtlpkg;
/


create or replace procedure zrcptindrpt_dtlproc
   (zrcptindrpt_dtl_cursor in out zrcptindrpt_dtlpkg.zrcptindrpt_dtl_type,
    in_sessionid in number,
    in_begdate   in date,
    in_enddate   in date)
is
--
-- $Id$
--
begin

   open zrcptindrpt_dtl_cursor for
      select *
         from zrcptindrpt_dtl
         where sessionid = in_sessionid
         order by userid, uom;

end zrcptindrpt_dtlproc;
/


show errors package zrcptindrpt_dtlpkg;
show errors procedure zrcptindrpt_dtlproc;
exit;
