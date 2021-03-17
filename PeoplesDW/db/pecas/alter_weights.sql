--
-- $Id$
--
alter table xchngactship modify
(weight number(17,8)
);

alter table load_flag_ctn modify
(weight number(20,8)
);

alter table load_flag_dtl modify
(weight number(20,8)
);

alter table load_flag_dtl_wk modify
(weight number(20,8)
);

alter table load_flag_hdr modify
(skid_weight number(20,8)
);

alter table skid_build modify
(weight number(20,8)
);

exit;
