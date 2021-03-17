--
-- $Id$
--
alter table batchtasks modify
(weight number(13,4)
);
alter table cartontypes modify
(maxweight number(13,4)
);
alter table custitem modify
(tareweight number(13,4)
,weight number(13,4)
);
alter table custitemuom modify
(tareweight number(13,4)
,weight number(13,4)
);
alter table deletedplate modify
(weight number(13,4)
);
alter table invoicedtl modify
(weight number(13,4)
);
alter table irisshipex modify
(weight number(13,4)
);
alter table loads modify
(weightorder number(13,4)
,weightrcvd number(13,4)
,weightship number(13,4)
);
alter table loadstop modify
(weightorder number(13,4)
,weightrcvd number(13,4)
,weightship number(13,4)
);
alter table loadstopship modify
(weightorder number(13,4)
,weightrcvd number(13,4)
,weightship number(13,4)
);
alter table location modify
(weightlimit number(13,4)
);
alter table multishipdtl modify
(actweight number(13,4)
,estweight number(13,4)
);
alter table neworderdtl modify
(weightorder number(13,4)
);
alter table neworderhdr modify
(weightorder number(13,4)
);
alter table oldorderdtl modify
(weightorder number(13,4)
);
alter table oldorderhdr modify
(weightorder number(13,4)
);
alter table orderdtl modify
(weight2check number(13,4)
,weight2pack number(13,4)
,weight2sort number(13,4)
,weightcommit number(13,4)
,weightorder number(13,4)
,weightpick number(13,4)
,weightrcvd number(13,4)
,weightrcvdgood number(13,4)
,weightrcvddmgd number(13,4)
,weightship number(13,4)
,weighttotcommit number(13,4)
);
alter table orderhdr modify
(weight2check number(13,4)
,weight2pack number(13,4)
,weight2sort number(13,4)
,weightcommit number(13,4)
,weightorder number(13,4)
,weightpick number(13,4)
,weightrcvd number(13,4)
,weightship number(13,4)
,weighttotcommit number(13,4)
);
alter table plate modify
(weight number(13,4)
);
alter table shipnote856hdrex modify
(weight number(13,4)
);
alter table shippingplate modify
(weight number(13,4)
);
alter table shippingplatehistory modify
(weight number(13,4)
);
alter table subtasks modify
(weight number(13,4)
);
alter table tasks modify
(weight number(13,4)
);
alter table unitofstorage modify
(weightlimit number(13,4)
);
alter table waves modify
(weightcommit number(13,4)
,weightorder number(13,4)
);
exit;

