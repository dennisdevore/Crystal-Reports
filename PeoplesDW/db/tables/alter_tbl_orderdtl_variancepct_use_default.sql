--
-- $Id$
--
alter trigger orderdtl_biud disable;
alter table orderdtl add
(
 variancepct_use_default char(1) default 'Y'
);
alter trigger orderdtl_biud enable;

exit;


