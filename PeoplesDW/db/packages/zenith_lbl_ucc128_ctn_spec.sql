--
-- $Id: zenith_case_labels_spec.sql 2408 2007-11-05 21:47:25Z bobw $
--
create or replace package zenith_lbl_ucc128_ctn as

FUNCTION get_seq
(in_lpid IN varchar2
) return integer;

FUNCTION get_seqof
(in_lpid IN varchar2
) return integer;



end zenith_lbl_ucc128_ctn;
/

show error package zenith_lbl_ucc128_ctn;
exit;
