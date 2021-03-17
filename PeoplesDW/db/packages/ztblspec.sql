--
-- $Id: ztblspec.sql 3726 2009-08-07 18:35:24Z ed $
--

create or replace PACKAGE alps.ztable_maintenance
IS

PROCEDURE disable_fk_references
(in_table_name varchar2
);

PROCEDURE enable_fk_references
(in_table_name varchar2
);

PROCEDURE disable_triggers
(in_table_name varchar2
);

PROCEDURE enable_triggers
(in_table_name varchar2
);

PROCEDURE delete_validation_table_code
(in_table_name varchar2
,in_code_value varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

PROCEDURE purge_userheader
(in_userid varchar2
);

END ztable_maintenance;
/
exit;
