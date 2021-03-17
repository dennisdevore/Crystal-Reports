Update Requests set Flag01 = 'I'
where ReqType = 'ImpExpReq' and Flag01 = 'Y';

Update Requests set Flag01 = 'E'
where ReqType = 'ImpExpReq' and 
(Flag01 = 'O' or Flag01 = 'P' or Flag01 = 'N');

Update Requests set Flag02 = 'N'
where ReqType = 'ImpExpReq' and Flag02 = 'Y';

Update Requests set Flag02 = 'S'
where ReqType = 'ImpExpReq' and Flag02 = 'O';

Update Requests set Flag02 = 'U'
where ReqType = 'ImpExpReq' and Flag02 = 'P';

commit;
