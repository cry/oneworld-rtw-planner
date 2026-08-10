:- module(carriers,
          [ eligible_carrier/1,
            eligible_carriers/1,
            ticketing_stock/1,
            permitted_operator/2,
            affiliate/3,
            carrier_name/2
          ]).

/** <module> 4(j) carrier eligibility, affiliates and codeshare policy.
*/

term_expansion(carriers(List), Facts) :-
    findall(eligible_carrier(C), member(C, List), Facts).

:- discontiguous eligible_carrier/1.

carriers([aa, as, at, ay, ba, cx, fj, ib, jl, mh, nu, qf, qr, rj, ul, wy]).

carrier_name(aa, 'American Airlines').
carrier_name(as, 'Alaska Airlines').
carrier_name(at, 'Royal Air Maroc').
carrier_name(ay, 'Finnair').
carrier_name(ba, 'British Airways').
carrier_name(cx, 'Cathay Pacific').
carrier_name(fj, 'Fiji Airways').
carrier_name(ib, 'Iberia').
carrier_name(jl, 'Japan Airlines').
carrier_name(mh, 'Malaysia Airlines').
carrier_name(nu, 'Japan Transocean Air').
carrier_name(qf, 'Qantas').
carrier_name(qr, 'Qatar Airways').
carrier_name(rj, 'Royal Jordanian').
carrier_name(ul, 'SriLankan Airlines').
carrier_name(wy, 'Oman Air').
carrier_name(jq, 'Jetstar').
carrier_name(qq, 'Alliance Airlines').

%! eligible_carriers(-Sorted) is det.
eligible_carriers(Cs) :- findall(C, eligible_carrier(C), Cs0), sort(Cs0, Cs).

%! ticketing_stock(?Carrier) is nondet.
%  Section 15 lists the permitted ticket stock, and that list omits MH.
ticketing_stock(C) :- eligible_carrier(C), C \== mh.

%! affiliate(?Parent, ?Code, ?Name) is nondet.
%  4(j) permits travel on these affiliated airlines. Only affiliates with their
%  own IATA designator are listed: those that operate under the parent's code
%  (BA Euroflyer, Fiji Link, the QantasLink operators, Royal Air Maroc Express)
%  are already covered by eligible_carrier/1 on the operating field.
affiliate(as, qx, 'Horizon Air').
affiliate(as, oo, 'SkyWest Airlines').
affiliate(aa, mq, 'Envoy Air').
affiliate(aa, pt, 'Piedmont Airlines').
affiliate(aa, oh, 'PSA Airlines').
affiliate(aa, yx, 'Republic Airways').
affiliate(aa, oo, 'SkyWest Airlines').
affiliate(ba, cj, 'BA CityFlyer').
affiliate(ay, n7, 'Nordic Regional Airlines').
affiliate(ib, yw, 'Air Nostrum').
affiliate(ib, i2, 'Iberia Express').
affiliate(jl, xm, 'J-Air').
affiliate(jl, hac, 'Hokkaido Air System').
affiliate(jl, jc, 'Japan Air Commuter').

%! permitted_operator(+Marketing, +Operating) is semidet.
%  "Travel on any [eligible] codeshare service operated by [an eligible
%  carrier] is permitted. Other codeshare services are not permitted, with the
%  exception of QF codeshare services operated by Jetstar (JQ) and QF services
%  operated by Alliance Airlines (QQ)."
permitted_operator(M, O) :-
    eligible_carrier(M),
    (   eligible_carrier(O)
    ;   affiliate(M, O, _)
    ;   M == qf, memberchk(O, [jq, qq])
    ),
    !.
