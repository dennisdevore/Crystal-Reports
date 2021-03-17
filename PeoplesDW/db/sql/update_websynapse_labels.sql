--
-- $Id: update_websynapse_labels.sql 6638 2011-05-24 19:45:25Z eric $
--
update tbl_global_label_repository set en = 'Assigned customers', fr = 'Clients affecte'
where label_id = 114;
update tbl_global_label_repository set en = 'Restricted User'
where label_id = 130;
update tbl_global_label_repository set en = 'Item'
where label_id = 132;
update tbl_global_label_repository set en = 'Total Quantity'
where label_id = 142;
update tbl_global_label_repository set en = 'Available Quantity'
where label_id = 143;
update tbl_global_label_repository set en = 'Scheduled Ship Date'
where label_id = 164;
update tbl_global_label_repository set en = 'Bill To'
where label_id = 167;
update tbl_global_label_repository set en = 'Vendor Return'
where label_id = 179;
update tbl_global_label_repository set en = 'Orders Received'
where en = 'Orders Recieved';
update tbl_global_label_repository set en = 'Appointment Date',
fr='Date de rendez-vous'
where label_id = 556
and en != 'Appointment Date';

insert into tbl_global_label_repository(label_id,en)
values(338,'Select By');
insert into tbl_global_label_repository(label_id,en)
values(339,'Successfully deleted company - {0}.');
insert into tbl_global_label_repository(label_id,en)
values(340,'Company in use - Not deleted.');
insert into tbl_global_label_repository(label_id,en)
values(341,'Could not delete company.');
insert into tbl_global_label_repository(label_id,en)
values(342,'Group inuse - Not deleted.');
insert into tbl_global_label_repository(label_id,en)
values(343,'Successfully deleted user - {0}.');
insert into tbl_global_label_repository(label_id,en)
values(344,'Sitemanager required - Not deleted.');
insert into tbl_global_label_repository(label_id,en)
values(345,'Could not delete user.');
insert into tbl_global_label_repository(label_id,en)
values(346,'Order has been committed. No more items allowed.');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(347,5,'Kitting');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(348,5,'Merchandise Return');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(349,5,'Transfer');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(350,2,'Equals');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(351,2,'Starts With');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(352,2,'Contains');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(353,2,'Ends With');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(354,2,'Order Age');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(355,2,'Active Only');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(356,5,'Pro Number');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(357,5,'Alias');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(358,5,'Ship To ID');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(359,5,'Actual Ship Date');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(360,5,'Cancel After Date');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(361,5,'Delivery Requested Date');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(362,5,'Requested Ship Date');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(363,5,'Ship Not Before Date');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(364,5,'Ship Not After Date');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(365,5,'Cancel If Not Delivered By Date');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(366,5,'Do Not Deliver After Date');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(367,5,'Do Not Deliver Before Date');
insert into tbl_global_label_repository(label_id,en)
values(368,'Product Group');
insert into tbl_global_label_repository(label_id,en)
values(369,'No shipment records for this order.');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(370,5,'Ship To Contact');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(371,5,'Ship To Addr1');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(372,5,'Ship To Addr2');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(373,5,'Ship To City');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(374,5,'Ship To State');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(375,5,'Ship To Postal Code');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(376,5,'Ship To Country Code');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(377,5,'Ship To Phone');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(378,5,'Ship To Fax');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(379,5,'Ship To Email');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(380,5,'Max Cancel Status');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(381,5,'Status Update');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(382,5,'Pass Through');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(383,5,'Assigned Value');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(384,5,'Serial Number');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(385,5,'Crossdock');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(386,5,'Trailer');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(387,5,'UOM Ordered');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(388,5,'All Customers');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(389,5,'Item required when All Customers selected');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(390,5,'Equals required when All Customers selected');
insert into tbl_global_label_repository(label_id,label_type_id,en)
values(391,5,'Customer');
insert into tbl_global_label_repository values(393,5,0,'Cross Customer','Client en travers',0);
insert into tbl_global_label_repository values(394,5,0,'Shipment Weight','Poids de Chargement',0);
insert into tbl_global_label_repository values(395,5,0,'Service Class','Classe de Service',0);
insert into tbl_global_label_repository values(396,5,0,'Tracking Number','Numéro de suivi',0);
insert into tbl_global_label_repository values(397,5,0,'Backordered Quantity','Stock Quantité',0);
insert into tbl_global_label_repository values(398,5,0,'Report Type','Type de Rapport',0);
insert into tbl_global_label_repository values(399,3,0,'{0}Can not be entered when one time is selected.','{0}Ne peut pas être entré quand une fois est sélectionnée.',0);
insert into tbl_global_label_repository values(400,5,0,'Consignee SKU','SKU destinataire',0);
insert into tbl_global_label_repository values(401,5,0,'Use Expanded Fields','Utilisez élargi les champs',0);
insert into tbl_global_label_repository values(402,5,0,'Ship Date','Date d''expédition',0);
insert into tbl_global_label_repository values(403,5,0,'Expanded Fields','Les champs élargi',0);
insert into tbl_global_label_repository values(404,5,0,'HdrPassThruChar01','HdrPassThruChar01',0);
insert into tbl_global_label_repository values(405,5,0,'HdrPassThruChar02','HdrPassThruChar02',0);
insert into tbl_global_label_repository values(406,5,0,'HdrPassThruChar03','HdrPassThruChar03',0);
insert into tbl_global_label_repository values(407,5,0,'HdrPassThruChar04','HdrPassThruChar04',0);
insert into tbl_global_label_repository values(408,5,0,'HdrPassThruChar05','HdrPassThruChar05',0);
insert into tbl_global_label_repository values(409,5,0,'HdrPassThruChar06','HdrPassThruChar06',0);
insert into tbl_global_label_repository values(410,5,0,'HdrPassThruChar07','HdrPassThruChar07',0);
insert into tbl_global_label_repository values(411,5,0,'HdrPassThruChar08','HdrPassThruChar08',0);
insert into tbl_global_label_repository values(412,5,0,'HdrPassThruChar09','HdrPassThruChar09',0);
insert into tbl_global_label_repository values(413,5,0,'HdrPassThruChar10','HdrPassThruChar10',0);
insert into tbl_global_label_repository values(414,5,0,'HdrPassThruChar11','HdrPassThruChar11',0);
insert into tbl_global_label_repository values(415,5,0,'HdrPassThruChar12','HdrPassThruChar12',0);
insert into tbl_global_label_repository values(416,5,0,'HdrPassThruChar13','HdrPassThruChar13',0);
insert into tbl_global_label_repository values(417,5,0,'HdrPassThruChar14','HdrPassThruChar14',0);
insert into tbl_global_label_repository values(418,5,0,'HdrPassThruChar15','HdrPassThruChar15',0);
insert into tbl_global_label_repository values(419,5,0,'HdrPassThruChar16','HdrPassThruChar16',0);
insert into tbl_global_label_repository values(420,5,0,'HdrPassThruChar17','HdrPassThruChar17',0);
insert into tbl_global_label_repository values(421,5,0,'HdrPassThruChar18','HdrPassThruChar18',0);
insert into tbl_global_label_repository values(422,5,0,'HdrPassThruChar19','HdrPassThruChar19',0);
insert into tbl_global_label_repository values(423,5,0,'HdrPassThruChar20','HdrPassThruChar20',0);
insert into tbl_global_label_repository values(424,5,0,'HdrPassThruChar21','HdrPassThruChar21',0);
insert into tbl_global_label_repository values(425,5,0,'HdrPassThruChar22','HdrPassThruChar22',0);
insert into tbl_global_label_repository values(426,5,0,'HdrPassThruChar23','HdrPassThruChar23',0);
insert into tbl_global_label_repository values(427,5,0,'HdrPassThruChar24','HdrPassThruChar24',0);
insert into tbl_global_label_repository values(428,5,0,'HdrPassThruChar25','HdrPassThruChar25',0);
insert into tbl_global_label_repository values(429,5,0,'HdrPassThruChar26','HdrPassThruChar26',0);
insert into tbl_global_label_repository values(430,5,0,'HdrPassThruChar27','HdrPassThruChar27',0);
insert into tbl_global_label_repository values(431,5,0,'HdrPassThruChar28','HdrPassThruChar28',0);
insert into tbl_global_label_repository values(432,5,0,'HdrPassThruChar29','HdrPassThruChar29',0);
insert into tbl_global_label_repository values(433,5,0,'HdrPassThruChar30','HdrPassThruChar30',0);
insert into tbl_global_label_repository values(434,5,0,'HdrPassThruChar31','HdrPassThruChar31',0);
insert into tbl_global_label_repository values(435,5,0,'HdrPassThruChar32','HdrPassThruChar32',0);
insert into tbl_global_label_repository values(436,5,0,'HdrPassThruChar33','HdrPassThruChar33',0);
insert into tbl_global_label_repository values(437,5,0,'HdrPassThruChar34','HdrPassThruChar34',0);
insert into tbl_global_label_repository values(438,5,0,'HdrPassThruChar35','HdrPassThruChar35',0);
insert into tbl_global_label_repository values(439,5,0,'HdrPassThruChar36','HdrPassThruChar36',0);
insert into tbl_global_label_repository values(440,5,0,'HdrPassThruChar37','HdrPassThruChar37',0);
insert into tbl_global_label_repository values(441,5,0,'HdrPassThruChar38','HdrPassThruChar38',0);
insert into tbl_global_label_repository values(442,5,0,'HdrPassThruChar39','HdrPassThruChar39',0);
insert into tbl_global_label_repository values(443,5,0,'HdrPassThruChar40','HdrPassThruChar40',0);
insert into tbl_global_label_repository values(444,5,0,'HdrPassThruChar41','HdrPassThruChar41',0);
insert into tbl_global_label_repository values(445,5,0,'HdrPassThruChar42','HdrPassThruChar42',0);
insert into tbl_global_label_repository values(446,5,0,'HdrPassThruChar43','HdrPassThruChar43',0);
insert into tbl_global_label_repository values(447,5,0,'HdrPassThruChar44','HdrPassThruChar44',0);
insert into tbl_global_label_repository values(448,5,0,'HdrPassThruChar45','HdrPassThruChar45',0);
insert into tbl_global_label_repository values(449,5,0,'HdrPassThruChar46','HdrPassThruChar46',0);
insert into tbl_global_label_repository values(450,5,0,'HdrPassThruChar47','HdrPassThruChar47',0);
insert into tbl_global_label_repository values(451,5,0,'HdrPassThruChar48','HdrPassThruChar48',0);
insert into tbl_global_label_repository values(452,5,0,'HdrPassThruChar49','HdrPassThruChar49',0);
insert into tbl_global_label_repository values(453,5,0,'HdrPassThruChar50','HdrPassThruChar50',0);
insert into tbl_global_label_repository values(454,5,0,'HdrPassThruChar51','HdrPassThruChar51',0);
insert into tbl_global_label_repository values(455,5,0,'HdrPassThruChar52','HdrPassThruChar52',0);
insert into tbl_global_label_repository values(456,5,0,'HdrPassThruChar53','HdrPassThruChar53',0);
insert into tbl_global_label_repository values(457,5,0,'HdrPassThruChar54','HdrPassThruChar54',0);
insert into tbl_global_label_repository values(458,5,0,'HdrPassThruChar55','HdrPassThruChar55',0);
insert into tbl_global_label_repository values(459,5,0,'HdrPassThruChar56','HdrPassThruChar56',0);
insert into tbl_global_label_repository values(460,5,0,'HdrPassThruChar57','HdrPassThruChar57',0);
insert into tbl_global_label_repository values(461,5,0,'HdrPassThruChar58','HdrPassThruChar58',0);
insert into tbl_global_label_repository values(462,5,0,'HdrPassThruChar59','HdrPassThruChar59',0);
insert into tbl_global_label_repository values(463,5,0,'HdrPassThruChar60','HdrPassThruChar60',0);
insert into tbl_global_label_repository values(464,5,0,'HdrPassThruDate01','HdrPassThruDate01',0);
insert into tbl_global_label_repository values(465,5,0,'HdrPassThruDate02','HdrPassThruDate02',0);
insert into tbl_global_label_repository values(466,5,0,'HdrPassThruDate03','HdrPassThruDate03',0);
insert into tbl_global_label_repository values(467,5,0,'HdrPassThruDate04','HdrPassThruDate04',0);
insert into tbl_global_label_repository values(468,5,0,'HdrPassThruDoll01','HdrPassThruDoll01',0);
insert into tbl_global_label_repository values(469,5,0,'HdrPassThruDoll02','HdrPassThruDoll02',0);
insert into tbl_global_label_repository values(470,5,0,'HdrPassThruNum01','HdrPassThruNum01',0);
insert into tbl_global_label_repository values(471,5,0,'HdrPassThruNum02','HdrPassThruNum02',0);
insert into tbl_global_label_repository values(472,5,0,'HdrPassThruNum03','HdrPassThruNum03',0);
insert into tbl_global_label_repository values(473,5,0,'HdrPassThruNum04','HdrPassThruNum04',0);
insert into tbl_global_label_repository values(474,5,0,'HdrPassThruNum05','HdrPassThruNum05',0);
insert into tbl_global_label_repository values(475,5,0,'HdrPassThruNum06','HdrPassThruNum06',0);
insert into tbl_global_label_repository values(476,5,0,'HdrPassThruNum07','HdrPassThruNum07',0);
insert into tbl_global_label_repository values(477,5,0,'HdrPassThruNum08','HdrPassThruNum08',0);
insert into tbl_global_label_repository values(478,5,0,'HdrPassThruNum09','HdrPassThruNum09',0);
insert into tbl_global_label_repository values(479,5,0,'HdrPassThruNum10','HdrPassThruNum10',0);
insert into tbl_global_label_repository values(480,5,0,'DtlPassThruChar01','DtlPassThruChar01',0);
insert into tbl_global_label_repository values(481,5,0,'DtlPassThruChar02','DtlPassThruChar02',0);
insert into tbl_global_label_repository values(482,5,0,'DtlPassThruChar03','DtlPassThruChar03',0);
insert into tbl_global_label_repository values(483,5,0,'DtlPassThruChar04','DtlPassThruChar04',0);
insert into tbl_global_label_repository values(484,5,0,'DtlPassThruChar05','DtlPassThruChar05',0);
insert into tbl_global_label_repository values(485,5,0,'DtlPassThruChar06','DtlPassThruChar06',0);
insert into tbl_global_label_repository values(486,5,0,'DtlPassThruChar07','DtlPassThruChar07',0);
insert into tbl_global_label_repository values(487,5,0,'DtlPassThruChar08','DtlPassThruChar08',0);
insert into tbl_global_label_repository values(488,5,0,'DtlPassThruChar09','DtlPassThruChar09',0);
insert into tbl_global_label_repository values(489,5,0,'DtlPassThruChar10','DtlPassThruChar10',0);
insert into tbl_global_label_repository values(490,5,0,'DtlPassThruChar11','DtlPassThruChar11',0);
insert into tbl_global_label_repository values(491,5,0,'DtlPassThruChar12','DtlPassThruChar12',0);
insert into tbl_global_label_repository values(492,5,0,'DtlPassThruChar13','DtlPassThruChar13',0);
insert into tbl_global_label_repository values(493,5,0,'DtlPassThruChar14','DtlPassThruChar14',0);
insert into tbl_global_label_repository values(494,5,0,'DtlPassThruChar15','DtlPassThruChar15',0);
insert into tbl_global_label_repository values(495,5,0,'DtlPassThruChar16','DtlPassThruChar16',0);
insert into tbl_global_label_repository values(496,5,0,'DtlPassThruChar17','DtlPassThruChar17',0);
insert into tbl_global_label_repository values(497,5,0,'DtlPassThruChar18','DtlPassThruChar18',0);
insert into tbl_global_label_repository values(498,5,0,'DtlPassThruChar19','DtlPassThruChar19',0);
insert into tbl_global_label_repository values(499,5,0,'DtlPassThruChar20','DtlPassThruChar20',0);
insert into tbl_global_label_repository values(500,5,0,'DtlPassThruChar21','DtlPassThruChar21',0);
insert into tbl_global_label_repository values(501,5,0,'DtlPassThruChar22','DtlPassThruChar22',0);
insert into tbl_global_label_repository values(502,5,0,'DtlPassThruChar23','DtlPassThruChar23',0);
insert into tbl_global_label_repository values(503,5,0,'DtlPassThruChar24','DtlPassThruChar24',0);
insert into tbl_global_label_repository values(504,5,0,'DtlPassThruChar25','DtlPassThruChar25',0);
insert into tbl_global_label_repository values(505,5,0,'DtlPassThruChar26','DtlPassThruChar26',0);
insert into tbl_global_label_repository values(506,5,0,'DtlPassThruChar27','DtlPassThruChar27',0);
insert into tbl_global_label_repository values(507,5,0,'DtlPassThruChar28','DtlPassThruChar28',0);
insert into tbl_global_label_repository values(508,5,0,'DtlPassThruChar29','DtlPassThruChar29',0);
insert into tbl_global_label_repository values(509,5,0,'DtlPassThruChar30','DtlPassThruChar30',0);
insert into tbl_global_label_repository values(510,5,0,'DtlPassThruChar31','DtlPassThruChar31',0);
insert into tbl_global_label_repository values(511,5,0,'DtlPassThruChar32','DtlPassThruChar32',0);
insert into tbl_global_label_repository values(512,5,0,'DtlPassThruChar33','DtlPassThruChar33',0);
insert into tbl_global_label_repository values(513,5,0,'DtlPassThruChar34','DtlPassThruChar34',0);
insert into tbl_global_label_repository values(514,5,0,'DtlPassThruChar35','DtlPassThruChar35',0);
insert into tbl_global_label_repository values(515,5,0,'DtlPassThruChar36','DtlPassThruChar36',0);
insert into tbl_global_label_repository values(516,5,0,'DtlPassThruChar37','DtlPassThruChar37',0);
insert into tbl_global_label_repository values(517,5,0,'DtlPassThruChar38','DtlPassThruChar38',0);
insert into tbl_global_label_repository values(518,5,0,'DtlPassThruChar39','DtlPassThruChar39',0);
insert into tbl_global_label_repository values(519,5,0,'DtlPassThruChar40','DtlPassThruChar40',0);
insert into tbl_global_label_repository values(520,5,0,'DtlPassThruDate01','DtlPassThruDate01',0);
insert into tbl_global_label_repository values(521,5,0,'DtlPassThruDate02','DtlPassThruDate02',0);
insert into tbl_global_label_repository values(522,5,0,'DtlPassThruDate03','DtlPassThruDate03',0);
insert into tbl_global_label_repository values(523,5,0,'DtlPassThruDate04','DtlPassThruDate04',0);
insert into tbl_global_label_repository values(524,5,0,'DtlPassThruDoll01','DtlPassThruDoll01',0);
insert into tbl_global_label_repository values(525,5,0,'DtlPassThruDoll02','DtlPassThruDoll02',0);
insert into tbl_global_label_repository values(526,5,0,'DtlPassThruNum01','DtlPassThruNum01',0);
insert into tbl_global_label_repository values(527,5,0,'DtlPassThruNum02','DtlPassThruNum02',0);
insert into tbl_global_label_repository values(528,5,0,'DtlPassThruNum03','DtlPassThruNum03',0);
insert into tbl_global_label_repository values(529,5,0,'DtlPassThruNum04','DtlPassThruNum04',0);
insert into tbl_global_label_repository values(530,5,0,'DtlPassThruNum05','DtlPassThruNum05',0);
insert into tbl_global_label_repository values(531,5,0,'DtlPassThruNum06','DtlPassThruNum06',0);
insert into tbl_global_label_repository values(532,5,0,'DtlPassThruNum07','DtlPassThruNum07',0);
insert into tbl_global_label_repository values(533,5,0,'DtlPassThruNum08','DtlPassThruNum08',0);
insert into tbl_global_label_repository values(534,5,0,'DtlPassThruNum09','DtlPassThruNum09',0);
insert into tbl_global_label_repository values(535,5,0,'DtlPassThruNum10','DtlPassThruNum10',0);
insert into tbl_global_label_repository values(536,5,0,'DtlPassThruNum11','DtlPassThruNum11',0);
insert into tbl_global_label_repository values(537,5,0,'DtlPassThruNum12','DtlPassThruNum12',0);
insert into tbl_global_label_repository values(538,5,0,'DtlPassThruNum13','DtlPassThruNum13',0);
insert into tbl_global_label_repository values(539,5,0,'DtlPassThruNum14','DtlPassThruNum14',0);
insert into tbl_global_label_repository values(540,5,0,'DtlPassThruNum15','DtlPassThruNum15',0);
insert into tbl_global_label_repository values(541,5,0,'DtlPassThruNum16','DtlPassThruNum16',0);
insert into tbl_global_label_repository values(542,5,0,'DtlPassThruNum17','DtlPassThruNum17',0);
insert into tbl_global_label_repository values(543,5,0,'DtlPassThruNum18','DtlPassThruNum18',0);
insert into tbl_global_label_repository values(544,5,0,'DtlPassThruNum19','DtlPassThruNum19',0);
insert into tbl_global_label_repository values(545,5,0,'DtlPassThruNum20','DtlPassThruNum20',0);
insert into tbl_global_label_repository values(546,5,0,'Use Ship To One Time','Navire Utilisez à une fois',0);
insert into tbl_global_label_repository values(547,3,0,'Bill to can not be entered when use ship to one time is selected.','Projet de loi ne peut être conclu lorsque le navire utiliser pour une fois est sélectionné.',0);
insert into tbl_global_label_repository values(548,3,0,'Bill to one time can not be selected when use ship to one time is selected.','Le projet de loi à un moment donné ne peut pas être sélectionné lorsque le navire utiliser pour une fois est sélectionnée.',0);
insert into tbl_global_label_repository values(549,1,0,'Order successfully created.','Ordre créé avec succès.',0);
insert into tbl_global_label_repository values(550,1,0,'Order successfully updated.','Commander correctement mis à jour.',0);
insert into tbl_global_label_repository values(551,5,0,'Order Attachment','Ordonnance de saisie',0);
insert into tbl_global_label_repository values(552,5,0,'Commit Variance','Comité de la variance',0);
insert into tbl_global_label_repository values(553,5,0,'Qty. Commit','Quantité commis',0);
insert into tbl_global_label_repository values(554,5,0,'Qty. Pick','Quantité prélevée',0);
insert into tbl_global_label_repository values(555,5,0,'Pro/Tracking Numbers','Pro/Numéros de suivi',0);
insert into tbl_global_label_repository values(556,5,0,'Appointment Date','Date de rendez-vous',0);
insert into tbl_global_label_repository values(557,5,0,'Include','Inclure',0);
insert into tbl_global_label_repository values(558,5,0,'Exclude','Exclure',0);
insert into tbl_global_label_repository values(559,5,0,'Select Item','Sélectionnez l''élément',0);
insert into tbl_global_label_repository values(560,5,0,'Invalid Customer',null,0);
insert into tbl_global_label_repository values(561,5,0,'Duplicate Reference',null,0);
insert into tbl_global_label_repository values(562,5,0,'Duplicate Reference and PO number',null,0);

commit;

exit;
