:- module(r15_sales, []).

/** <module> Rule 15 -- sales restrictions.

    "If a ticket includes travel to/from/via Cuba it may not also include
    flight segments for travel on American Airlines / American Eagle ... or
    Alaska Airlines / Horizon Air, due to U.S. Government restrictions."
*/

:- use_module('../geo').
:- use_module('../annotate').
:- use_module('../carriers').

:- multifile validate:violation/2.

% Reported once per offending carrier segment, not once per time a Cuban
% airport appears: a single stop shows up as both an arrival and the next
% departure, which would otherwise report the same conflict twice.
validate:violation(A, v(cuba_us_carrier, '15', error, Msg,
                        [segments([CarrierSeg]), carrier(U),
                         airports(CubaAirports)])) :-
    cuba_airports(A, CubaAirports),
    CubaAirports \== [],
    restricted_us_segment(A, CarrierSeg, Carrier),
    iata(Carrier, U),
    format(atom(Msg),
           'The itinerary touches Cuba (~w) and also carries ~w on segment ~w; rule 15 does not allow both on one ticket.',
           [CubaAirports, U, CarrierSeg]).

cuba_airports(A, Airports) :-
    findall(U, ( ann_airport(A, Airport),
                 airport_country(Airport, 'CU'),
                 iata(Airport, U) ),
            Airports).

restricted_us_segment(A, N, Carrier) :-
    ann_seg(A, S),
    S.type == flight,
    N = S.n,
    ( Carrier = S.marketing ; Carrier = S.operating ),
    Carrier \== unknown,
    restricted_carrier(Carrier).

restricted_carrier(aa).
restricted_carrier(as).
restricted_carrier(C) :- affiliate(aa, C, _).
restricted_carrier(C) :- affiliate(as, C, _).

% Ticket stock is a separate section 15 provision and does not depend on the
% routing, so it is reported as a warning against the marketing carriers used.
validate:violation(A, v(jq_stock_conflict, '15', warning, Msg, [segments([N])])) :-
    ann_seg(A, S),
    S.type == flight,
    S.marketing == qf,
    S.operating == jq,
    N = S.n,
    format(atom(Msg),
           'Segment ~w is QF marketed and JQ operated, so IB and WY ticket stock cannot be used for this ticket.',
           [N]).
