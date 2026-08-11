:- module(r15_sales, []).

/** <module> Rule 15 -- sales restrictions.

    "If a ticket includes travel to/from/via Cuba it may not also include
    flight segments for travel on American Airlines / American Eagle ... or
    Alaska Airlines / Horizon Air, due to U.S. Government restrictions."
*/

:- use_module('../geo').
:- use_module('../annotate').
:- use_module('../carriers').
:- use_module('../phrasing').

:- multifile validate:violation/2.
:- multifile validate:check/2.

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
    listed_and(CubaAirports, Places),
    format(atom(Msg),
           'The journey goes to Cuba (~w) and also uses ~w on segment ~w. Rule 15 does not allow both on one ticket.',
           [Places, U, CarrierSeg]).

% A journey to Cuba with no carrier named cannot be cleared. The restriction is
% about who flies it, and the Miami-Havana sector that puts most itineraries
% into Cuba is American in practice -- so "it does not use American or Alaska"
% is not something this report may say about an itinerary that names no carrier
% at all. This is an omission in the data rather than a limit of the input mode,
% which is what makes it indeterminate rather than not_checked: a routing may
% carry carriers, and once it does this rule answers.
validate:violation(A, v(cuba_us_carrier, '15', indeterminate, Msg,
                        [segments(Unknown), airports(CubaAirports)])) :-
    cuba_airports(A, CubaAirports),
    CubaAirports \== [],
    % Already settled the other way: a named American segment decides the rule,
    % and the segments that stayed blank cannot unsettle it.
    \+ restricted_us_segment(A, _, _),
    uncarried_segments(A, Unknown),
    Unknown \== [],
    listed_and(CubaAirports, Places),
    segments_phrase(Unknown, Where),
    format(atom(Msg),
           'The journey goes to Cuba (~w), and no carrier is given for ~w. Rule 15 bars American and Alaska from a Cuba ticket, so this cannot be settled until those segments name one.',
           [Places, Where]).

uncarried_segments(A, Ns) :-
    findall(N, ( ann_seg(A, S),
                 S.type == flight,
                 S.marketing == unknown,
                 S.operating == unknown,
                 N = S.n ),
            Ns).

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

% Rule 15 is about Cuba, so an itinerary that does not go there has nothing for
% it to measure. Reporting a clean pass on the carrier half alone would read as
% a restriction cleared rather than one never engaged.
validate:check(A, Check) :-
    cuba_airports(A, Cuba),
    (   Cuba == []
    ->  Check = chk_na(cuba_us_carrier, '15', 'Cuba and US carriers',
                       'The journey does not go to Cuba.')
    ;   findall(U, ( restricted_us_segment(A, _, C), iata(C, U) ), Carriers0),
        sort(Carriers0, Carriers),
        listed(Cuba, Places),
        uncarried_segments(A, Unknown),
        (   Carriers == [], Unknown \== []
        ->  segments_phrase(Unknown, Where),
            format(atom(Detail),
                   'The journey goes to Cuba (~w). No carrier is given for ~w, so this rule has nothing to read.',
                   [Places, Where])
        ;   Carriers == []
        ->  format(atom(Detail),
                   'The journey goes to Cuba (~w). It does not use American or Alaska.',
                   [Places])
        ;   listed_and(Carriers, List),
            format(atom(Detail),
                   'The journey goes to Cuba (~w). It also uses ~w. Rule 15 does not allow both.',
                   [Places, List])
        ),
        Check = chk(cuba_us_carrier, '15', 'Cuba and US carriers', Detail,
                    [cuba_us_carrier])
    ).

% Ticket stock is a separate section 15 provision and does not depend on the
% routing, so it is reported as a warning against the marketing carriers used.
validate:violation(A, v(jq_stock_conflict, '15', warning, Msg, [segments([N])])) :-
    jetstar_segment(A, N),
    format(atom(Msg),
           'Segment ~w is QF marketed and JQ operated, so IB and WY ticket stock cannot be used for this ticket.',
           [N]).

jetstar_segment(A, N) :-
    ann_seg(A, S),
    S.type == flight,
    S.marketing == qf,
    S.operating == jq,
    N = S.n.

% Reported as a measurement rather than declared not applicable: every ticket
% has stock, so "which stock may be used" is always an answer this report owes.
validate:check(A, chk(jq_stock_conflict, '15', 'Ticket stock', Detail,
                      [jq_stock_conflict])) :-
    findall(N, jetstar_segment(A, N), Segs),
    (   Segs == []
    ->  Detail = 'No flight is sold by QF and flown by JQ. So any airline on the section 15 list may issue the ticket.'
    ;   segments_phrase(Segs, Where),
        format(atom(Detail),
               'QF sells ~w and JQ flies it. So IB and WY may not issue the ticket.',
               [Where])
    ).
