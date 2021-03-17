--
-- $Id$
--
alter table customer add
(wavetemplate varchar2(36)
,outconfirmonline char(1)
,outconfirmbatch char(1)
,outconfirmonlinemap varchar2(255)
,outconfirmbatchmap varchar2(255)
,outconfirmonlinewhen char(1)
,outconfirmbatchwhen char(1)
,outackonline char(1)
,outackbatch char(1)
,outackonlinemap varchar2(255)
,outackbatchmap varchar2(255)
,outackonlinewhen char(1)
,outackbatchwhen char(1)
);

exit;
