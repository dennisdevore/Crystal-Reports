--
-- $Id$
--
alter table irisshipex modify (trackingno varchar2(30));
alter table multishipdtl modify (trackid varchar2(30));
alter table multishipdtl modify (rmatrackingno varchar2(30));
alter table orderhdr modify (returntrackingno varchar2(30));
alter table pklrequest_header modify (returntrackingno varchar2(30));
alter table rcptnote944ideex modify (origtrackingno varchar2(30));
alter table shippingplate modify (trackingno varchar2(30));
alter table shippingplate modify (rmatrackingno varchar2(30));
alter table shippingplatehistory modify (trackingno varchar2(30));
alter table worldshipdtl modify (trackid varchar2(30));
alter table worldshipdtl modify (rmatrackingno varchar2(30));
exit;
