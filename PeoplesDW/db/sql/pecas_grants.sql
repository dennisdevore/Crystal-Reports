--
-- $Id$
--
grant execute on zbill to pecas;
grant execute on zbut to pecas;
grant execute on zci to pecas;
grant execute on zcl to pecas;
grant execute on zcus to pecas;
grant execute on cdata to pecas;
grant execute on zia to pecas;
grant execute on ziem to pecas;
grant execute on zimp to pecas;
grant execute on zimppecas to pecas;
grant execute on zlb to pecas;
grant execute on zmn to pecas;
grant execute on zms to pecas;
grant execute on zoe to pecas;
grant execute on zoh to pecas;
grant execute on zput to pecas;
grant execute on zqm to pecas;
grant execute on zrf to pecas;
grant execute on zsp to pecas;
grant execute on ztsk to pecas;
grant execute on zut to pecas;
grant execute on zwv to pecas;
grant select                        on allplateview to pecas;
grant select                        on appmsgs to pecas;
grant select                        on carrier to pecas;
grant select                        on carrierstageloc to pecas;
grant select                        on consignee to pecas;
grant select,update                 on customer to pecas;
grant select,update                 on custitem to pecas;
grant select                        on custitemlabelprofiles to pecas;
grant select                        on custitemview to pecas;
grant select,insert,update,delete   on custitemuom to pecas;
grant select,insert                 on deletedplate to pecas;
grant select                        on labelprofileline to pecas;
grant select                        on location to pecas;
grant select                        on loads to pecas;
grant select                        on loadsorderview to pecas;
grant select                        on loadflaglabels to pecas;
grant select                        on multishiphdr to pecas;
grant select,insert                 on multishipdtl to pecas;
grant select,update                 on orderhdr to pecas;
grant select,update                 on orderdtl to pecas;
grant select,insert                 on plate to pecas;
grant select                        on printer to pecas;
grant select,insert,update          on shippingplate to pecas;
grant select                        on spoolerqueues to pecas;
grant select,insert                 on subtasks to pecas;
grant select,insert,update          on tasks to pecas;

exit;
