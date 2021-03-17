--
-- $Id:  $
--
alter table facility add
(
    storage             char(1),
    pickingheavy        number(3),
    pickingmoderate     number(3),
    pickinglight        number(3),
    putawayheavy        number(3),
    putawaymoderate     number(3),
    putawaylight        number(3)
);

exit;
