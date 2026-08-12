:- module(r05_booking, []).

/** <module> Rule 5(b) -- booking codes.

    Section 5(b) publishes, per carrier, the class an Explorer fare books into
    in each cabin. A ticket sold in some other code is not this fare.

    The rule is checkable only when the itinerary says what class it was sold
    in, which is optional. That is deliberately *not* `indeterminate`: an
    itinerary written as a routing has no place to put a booking code at all,
    and treating a fare notation as an incomplete segment table would make every
    routing undecidable over a field the notation cannot express. What the
    register says instead is that there was no code to read -- see the chk_na at
    the foot of this file. The moment one segment names a class, every segment
    that names one is measured.

    Three outcomes, because 5(b) has three kinds of class in it:

      * the applicable code for the cabin -- ok;
      * a code the notes permit only in a stated case -- also ok, and recorded
        in the register with the case it leans on;
      * anything else -- an error.

    The second used to be a warning and is not one. "For flights where First or
    Business Class is not offered or available, passengers may travel in a lower
    class, in the applicable booking code for that lower class" is a permission
    the tariff grants, and a ticket sold under it is a correct ticket. The
    condition is about what the *flight* offers -- a seat map, which no
    itinerary carries -- but it is also a condition the airline's own inventory
    settled at the moment of sale: the code is in the itinerary because a seat
    in it was sold. There is nothing here for a traveller to fix, and a warning
    that cannot be acted on is noise in front of the ones that can.

    What the case is still worth saying, so it is said where statements of fact
    belong: the check register names the segments and the note they rely on. The
    outcome of the check is unaffected, which is the point.
*/

:- use_module('../geo').
:- use_module('../annotate').
:- use_module('../carriers').
:- use_module('../phrasing').
:- use_module('../../data/booking_codes').
:- use_module(library(apply)).

:- multifile validate:violation/2.
:- multifile validate:check/2.

% --- reading a segment -----------------------------------------------------

%! classed_flight(+A, -S) is nondet.
%  A flown segment that states the class it was sold in. Surface sectors are
%  excluded: nobody sells them and 5(b) has no column for them.
classed_flight(A, S) :-
    ann_seg(A, S),
    S.type == flight,
    S.booking_class \== unknown.

%! row_for(+S, -Carrier, -Scope) is semidet.
%  Which 5(b) row a segment is read against. The *marketing* carrier decides
%  it, because 5(b) is about the code the fare is sold in and the seller is who
%  sells it -- unlike 4(j), which turns on who operates.
%
%  Scope is `any` unless the carrier publishes separate domestic rows.
row_for(S, Carrier, Scope) :-
    Carrier = S.marketing,
    Carrier \== unknown,
    carrier_has_codes(Carrier),
    (   sector_scope(S.from_country, S.to_country, Wanted),
        booking_code(Carrier, Wanted, _, _)
    ->  Scope = Wanted
    ;   Scope = any
    ).

% --- what 5(b) permits -----------------------------------------------------

%! applicable(+Carrier, +Scope, +Cabin, +Class) is semidet.
applicable(Carrier, Scope, Cabin, Class) :-
    cabin_column(Cabin, Column),
    booking_code(Carrier, Scope, Column, Class),
    !.
% An economy Explorer fare buys premium economy through section 12's per-sector
% surcharge rather than through a fare basis of its own, so the premium cabin
% codes are codes an economy fare books into. src/pricing.pl already prices the
% surcharge for the whole journey; this is the same arrangement seen per
% segment.
applicable(Carrier, _, economy, Class) :-
    premium_economy_code(Carrier, Class).

%! conditional(+S, +Carrier, +Scope, +Cabin, +Class, -Reason) is nondet.
%  A code the notes to 5(b) permit, but only where something about the flight
%  is true that an itinerary cannot show.
conditional(_, Carrier, Scope, Cabin, Class, lower_class-Reason) :-
    lower_column(Cabin, Column),
    booking_code(Carrier, Scope, Column, Class),
    column_cabin_word(Column, Lower),
    cabin_word(Cabin, Word),
    article(Word, lower, Fare),
    format(atom(Reason),
           'it is the ~w code, which ~w fare may use only where ~w is not offered or not available on that flight',
           [Lower, Fare, Word]).
% Carrier-free, deliberately: it is the same permission whichever airline the
% ticket is on, and naming one in the sentence would make two sectors under one
% permission read as two different permissions.
conditional(_, Carrier, _, business, Class, business_alternate-Reason) :-
    business_alternate_code(Carrier, Class),
    Reason = 'section 5(b) lets a DONE Business fare book B, or H on AA, in place of the applicable code'.
conditional(_, _, _, first, Class, first_alternate-Reason) :-
    first_alternate_code(Class),
    Reason = 'a First fare may book Y only where the applicable lower-class code is unavailable'.
% The exception is written "for services within the Middle East", so it is a
% fact about the sector and not about the carrier: a QR flight from Doha to
% Bangkok is not within the Middle East and A is not open to it. Both endpoints
% have to be in the zone -- which is the same zone 4(c)(b) and the section 12
% surcharge band are written in, and the reason geo.pl tracks it at all.
conditional(S, Carrier, _, business, Class, middle_east-Reason) :-
    middle_east_business_code(Carrier, Class),
    S.from_zone == middle_east,
    S.to_zone == middle_east,
    Reason = 'the 5(b) exception allows it on QR for services within the Middle East where no Business Class is offered, which does not apply where Business exists but is merely unavailable'.

% "Lower" in fare order. First falls back through both business columns and
% then economy; business falls back to economy; economy has nothing below it.
lower_column(first,    business_done).
lower_column(first,    business_ione3).
lower_column(first,    economy).
lower_column(business, economy).

cabin_word(first,    'First').
cabin_word(business, 'Business').
cabin_word(economy,  'Economy').

% The cabin a column belongs to. data/booking_codes.pl names the columns in
% full -- "Business on a DONE fare" -- which is what the register wants and too
% much for the middle of a sentence about falling back to a lower cabin.
column_cabin_word(first,          'First').
column_cabin_word(business_done,  'Business').
column_cabin_word(business_ione3, 'Business').
column_cabin_word(economy,        'Economy').

% --- violations ------------------------------------------------------------

% Aggregated, on the same reasoning marketing_carrier_missing gives in
% r04_routing.pl: a fare sold in the wrong code on six sectors is one thing gone
% wrong, and six near-identical sentences bury whatever else the report has to
% say. One violation per distinct case, never one per segment.
validate:violation(A, v(booking_code, '5(b)', error, Msg,
                        [segments(Ns), sold(Sold), expected(Expected)])) :-
    findall(N-Given-U-Exp,
            (   classed_flight(A, S),
                N = S.n,
                row_for(S, Carrier, Scope),
                Class = S.booking_class,
                \+ applicable(Carrier, Scope, A.cabin, Class),
                \+ conditional(S, Carrier, Scope, A.cabin, Class, _),
                upcase_atom(Class, Given),
                iata(Carrier, U),
                expected_phrase(Carrier, Scope, A.cabin, Exp)
            ),
            Wrong),
    Wrong \== [],
    findall(N, member(N-_-_-_, Wrong), Ns),
    sold_phrase(Wrong, Sold),
    cabin_word(A.cabin, Word),
    article(Word, lower, Fare),
    (   Wrong = [_-_-_-Expected]
    ->  segments_phrase(Ns, upper, Where),
        format(atom(Msg),
               '~w is sold in ~w. ~w Explorer fare books into ~w; section 5(b) does not name that code.',
               [Where, Sold, Fare, Expected])
    ;   Expected = 'the applicable code',
        segments_phrase(Ns, upper, Where),
        format(atom(Msg),
               '~w are sold in ~w. Section 5(b) names none of those for ~w Explorer fare on those carriers.',
               [Where, Sold, Fare])
    ).

%! conditional_note(+A, ?Kind, -Note) is nondet.
%  One sentence per permission leaned on, for the register. Grouped by the case
%  that permits the code rather than by the segment, on the reasoning
%  marketing_carrier_missing gives in r04_routing.pl: two sectors under one
%  permission are one fact, and two sectors under different permissions stay
%  two.
conditional_note(A, Kind, Note) :-
    conditional_kind(Kind),
    findall(N-Given-U,
            (   classed_flight(A, S),
                N = S.n,
                row_for(S, Carrier, Scope),
                Class = S.booking_class,
                \+ applicable(Carrier, Scope, A.cabin, Class),
                once(conditional(S, Carrier, Scope, A.cabin, Class, Kind-_)),
                upcase_atom(Class, Given),
                iata(Carrier, U)
            ),
            Hits),
    Hits \== [],
    once(( classed_flight(A, S0), row_for(S0, C0, Sc0), Class0 = S0.booking_class,
           conditional(S0, C0, Sc0, A.cabin, Class0, Kind-Reason) )),
    findall(N, member(N-_-_, Hits), Ns),
    findall(N-G-U-none, member(N-G-U, Hits), Padded),
    sold_phrase(Padded, Sold),
    segments_phrase(Ns, upper, Where),
    length(Ns, Count),
    agree(Count, 'is', 'are', Is),
    format(atom(Note),
           '~w ~w sold in ~w rather than the applicable code. That is allowed: ~w. The fare for the highest class used applies.',
           [Where, Is, Sold, Reason]).

conditional_kind(lower_class).
conditional_kind(business_alternate).
conditional_kind(first_alternate).
conditional_kind(middle_east).

% "H on AA", "H on AA and B on BA". The code and the carrier stay together
% because either alone is not enough to look the row up.
sold_phrase(Rows, Phrase) :-
    findall(Item,
            ( member(_-Given-U-_, Rows), format(atom(Item), '~w on ~w', [Given, U]) ),
            Items0),
    list_to_set(Items0, Items),
    listed_and(Items, Phrase).

% A class was given and the row it should be read against could not be found.
% Reported once for the whole itinerary rather than per segment: the reason is
% the same each time and a per-segment version would bury the one fact worth
% having, which is which segments to fix.
validate:violation(A, v(booking_code_unreadable, '5(b)', indeterminate, Msg,
                        [segments(Ns)])) :-
    findall(N, ( classed_flight(A, S), \+ row_for(S, _, _), N = S.n ), Ns),
    Ns \== [],
    length(Ns, Count),
    segments_phrase(Ns, upper, Where),
    agree(Count, 'states', 'state', States),
    agree(Count, 'names', 'name', Names),
    format(atom(Msg),
           '~w ~w a booked class but ~w no carrier section 5(b) publishes codes for, so the class cannot be checked.',
           [Where, States, Names]).

%! expected_phrase(+Carrier, +Scope, +Cabin, -Phrase) is det.
%  The applicable code, written the way the table publishes it. Business has
%  two columns and they are usually different letters, so naming only one would
%  read as though the other were a violation.
expected_phrase(Carrier, Scope, business, Phrase) :-
    !,
    booking_code(Carrier, Scope, business_done, D0), upcase_atom(D0, D),
    booking_code(Carrier, Scope, business_ione3, I0), upcase_atom(I0, I),
    (   D == I
    ->  Phrase = D
    ;   format(atom(Phrase), '~w (or ~w on an IONE3 fare)', [D, I])
    ).
expected_phrase(Carrier, Scope, economy, Phrase) :-
    !,
    booking_code(Carrier, Scope, economy, L0), upcase_atom(L0, L),
    (   premium_economy_code(Carrier, P0)
    ->  upcase_atom(P0, P),
        format(atom(Phrase), '~w (or ~w with the section 12 premium economy surcharge)', [L, P])
    ;   Phrase = L
    ).
expected_phrase(Carrier, Scope, Cabin, Phrase) :-
    cabin_column(Cabin, Column),
    booking_code(Carrier, Scope, Column, C0),
    upcase_atom(C0, Phrase).

% --- the register ----------------------------------------------------------

% An itinerary that states no class at all engages nothing here. That is `n/a`
% rather than `undecided` for the reason given at the top of this file: the
% class is optional input, and a routing has nowhere to write one.
validate:check(A, chk_na(booking_code, '5(b)', 'Booking codes', Reason)) :-
    \+ classed_flight(A, _),
    flights(A, Flights),
    (   Flights == 0
    ->  Reason = 'The journey has no flight segments, so no class is sold.'
    ;   Reason = 'No segment states the class it is sold in, so there is no code to read against the 5(b) table.'
    ).

validate:check(A, chk(booking_code, '5(b)', 'Booking codes', Detail,
                      [booking_code, booking_code_unreadable])) :-
    classed_flight(A, _),
    flights(A, Flights),
    tally(A, Stated, Counts),
    cabin_word(A.cabin, Word),
    article(Word, lower, Fare),
    plural(Flights, 'flight', Flight),
    findall(Part, register_part(Counts, Part), Parts),
    listed_and(Parts, Tail),
    format(atom(Head), '~w of ~w ~w state the class sold, on ~w fare. ~w.',
           [Stated, Flights, Flight, Fare, Tail]),
    findall(Note, conditional_note(A, _, Note), Notes),
    atomic_list_concat([Head|Notes], ' ', Detail).

% One clause per outcome, in the order a reader wants them: what went wrong
% first, then what is merely conditional, then what is fine.
register_part(Counts, Part) :-
    member(Outcome-Phrase,
           [ wrong-'not a code 5(b) names',
             conditional-'a code 5(b) allows only in a stated case',
             unreadable-'on no carrier with published codes',
             applicable-'the applicable code' ]),
    memberchk(Outcome-N, Counts),
    N > 0,
    agree(N, 'is', 'are', Is),
    format(atom(Part), '~w ~w ~w', [N, Is, Phrase]).

tally(A, Stated, Counts) :-
    findall(Outcome,
            ( classed_flight(A, S), segment_outcome(A, S, Outcome) ),
            Outcomes),
    length(Outcomes, Stated),
    findall(What-N,
            ( member(What, [wrong, conditional, unreadable, applicable]),
              count(What, Outcomes, N) ),
            Counts).

segment_outcome(A, S, Outcome) :-
    (   \+ row_for(S, _, _)
    ->  Outcome = unreadable
    ;   row_for(S, Carrier, Scope),
        Class = S.booking_class,
        (   applicable(Carrier, Scope, A.cabin, Class)
        ->  Outcome = applicable
        ;   conditional(S, Carrier, Scope, A.cabin, Class, _)
        ->  Outcome = conditional
        ;   Outcome = wrong
        )
    ).

count(What, List, N) :- include(==(What), List, Hits), length(Hits, N).

flights(A, N) :-
    findall(S, ( ann_seg(A, S), S.type == flight ), Ss),
    length(Ss, N).
