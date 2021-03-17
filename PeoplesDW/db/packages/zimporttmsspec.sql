--
-- $Id$
--
CREATE OR REPLACE PACKAGE  zimportproctms
as

procedure begin_tmsexport
(in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_tmsexport
(in_viewsuffix IN varchar2,
out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_tmscustexport
(in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_tmscustexport
(in_viewsuffix IN varchar2,
out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2);


end zimportproctms; 
/