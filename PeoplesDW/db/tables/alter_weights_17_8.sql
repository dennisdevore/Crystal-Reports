--
-- $Id$
--

alter table asncartondtl modify
(weight number(17,8)
);

alter table asofinvact modify
(weight number(17,8)
);

alter table asofinvactitem modify
(weight number(17,8)
);

alter table asofinvactlot modify
(weight number(17,8)
);

alter table asofinventory modify
(currentweight number(17,8)
,previousweight number(17,8)
);

alter table asofinventorydtl modify
(weightadjustment number(17,8)
);

alter table batchtasks modify
(weight number(17,8)
);

alter table bill_lot_renewal modify
(weight number(17,8)
);

alter table bolrequest_tmpcarrier modify
(itemweight number(17,8)
);

alter table bolrequest_carrier modify
(itemweight number(18,8)
);

alter table bolrequest_carrier_items modify
(itemweight number(17,8)
);

alter table bolrequest_order modify
(weightshipped number(17,8)
);

alter table bolrequest_tmporder modify
(weightshipped number(17,8)
);

alter table cartontypes modify
(maxweight number(17,8)
);

alter table custitem modify
(tareweight number(17,8)
,weight number(17,8)
);

alter table custitemcatchweight modify
(totweight number(19,8)
);

alter table custitemuom modify
(tareweight number(17,8)
,weight number(17,8)
);

alter table deletedplate modify
(weight number(17,8)
);

alter table dre_asofinvactlot modify
(weight number(17,8)
);

alter table import_plate modify
(weight number(17,8)
);

alter table invadjactivity modify
(adjweight number(17,8)
);

alter table invoicedtl modify
(weight number(17,8)
,enteredweight number(17,8)
);

alter table irisshipex modify
(weight number(17,8)
);

alter table loads modify
(weightorder number(17,8)
,weightrcvd number(17,8)
,weightship number(17,8)
);

alter table loadstop modify
(weightorder number(17,8)
,weightrcvd number(17,8)
,weightship number(17,8)
);

alter table loadstopship modify
(weightorder number(17,8)
,weightrcvd number(17,8)
,weightship number(17,8)
);

alter table location modify
(weightlimit number(17,8)
);

alter table multishipdtl modify
(actweight number(17,8)
,estweight number(17,8)
);

alter table neworderdtl modify
(weightorder number(17,8)
);

alter table neworderhdr modify
(weightorder number(17,8)
);

alter table oldorderdtl modify
(weightorder number(17,8)
);

alter table oldorderhdr modify
(weightorder number(17,8)
);

alter table orderdtl modify
(weight2check number(17,8)
,weight2pack number(17,8)
,weight2sort number(17,8)
,weightcommit number(17,8)
,weightorder number(17,8)
,weightpick number(17,8)
,weightrcvd number(17,8)
,weightrcvdgood number(17,8)
,weightrcvddmgd number(17,8)
,weightship number(17,8)
,weighttotcommit number(17,8)
);

alter table orderdtlrcpt modify
(weight number(17,8)
);

alter table orderhdr modify
(weight2check number(17,8)
,weight2pack number(17,8)
,weight2sort number(17,8)
,weightcommit number(17,8)
,weightorder number(17,8)
,weightpick number(17,8)
,weightrcvd number(17,8)
,weightship number(17,8)
,weighttotcommit number(17,8)
);

alter table pending_charges modify
(weight number(17,8)
);

alter table pklrequest_header modify
(weight2check number(17,8)
,weight2pack number(17,8)
,weight2sort number(17,8)
,weightcommit number(17,8)
,weightorder number(17,8)
,weightpick number(17,8)
,weightrcvd number(17,8)
,weightship number(17,8)
,weighttotcommit number(17,8)
);

alter table pklrequest_detail modify
(weight2check number(17,8)
,weight2pack number(17,8)
,weight2sort number(17,8)
,weightcommit number(17,8)
,weightorder number(17,8)
,weightpick number(17,8)
,weightrcvd number(17,8)
,weightrcvddmgd number(17,8)
,weightrcvdgood number(17,8)
,weightship number(17,8)
,weighttotcommit number(17,8)
);

alter table plate modify
(weight number(17,8)
);

alter table platehistory modify
(weight number(17,8)
);

alter table rcptnote944ideex modify
(snweight number(17,8)
);

alter table shipnote856hdrex modify
(weight number(17,8)
);

alter table shippingplate modify
(weight number(17,8)
);

alter table shippingplatehistory modify
(weight number(17,8)
);

alter table subtasks modify
(weight number(17,8)
);

alter table tasks modify
(weight number(17,8)
);

alter table unitofstorage modify
(weightlimit number(17,8)
);

alter table waves modify
(weightcommit number(17,8)
,weightorder number(17,8)
,weight number(17,8)
);

alter table weber_case_labels modify
(itemweight number(17,8)
);

alter table weber_case_labels_temp modify
(itemweight number(17,8)
);

alter table worldshipdtl modify
(actweight number(17,8)
,estweight number(17,8)
);

alter table zinvsumrpt modify
(weight number(17,8)
,weighttotal number(20,8)
);

exit;

