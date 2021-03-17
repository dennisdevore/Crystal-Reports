--
-- $Id$
--
create or replace package alps.pipeutility as


-- Public procedures


procedure flush_rf_user
   (in_facility in varchar2,
    in_user     in varchar2);


end pipeutility;
/

exit;
