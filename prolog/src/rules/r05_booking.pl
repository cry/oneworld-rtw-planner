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
      * a code the notes permit only in a stated case -- flagged, because the
        case is about what the *flight* offers and no itinerary can show that;
      * anything else -- an error.

    The second is the interesting one. "For flights where First or Business
    Class is not offered or available, passengers may travel in a lower class,
    in the applicable booking code for that lower class" makes a business fare
    ticketed in L legal on a flight with no business cabin and illegal on one
    that has it. The itinerary carries the route, not the seat map, so the
    report says which condition the code depends on and leaves the verdict
    valid -- the same posture rule 8 takes when a declared stop kind disagrees
    with the clock.
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
    (   sector_scope(S, Wanted), booking_code(Carrier, Wanted, _, _)
    ->  Scope = Wanted
    ;   Scope = any
    ).

% A sector that begins and ends in one country is that carrier's domestic
% network. Deliberately not annotate.pl's `international` field: that carries
% 4(f)'s USA/Canada exception, which has nothing to do with which 5(b) row a
% Finnish or Japanese domestic flight is sold under.
sector_scope(S, Scope) :-
    (   S.from_country \== unknown,
        S.from_country == S.to_country
    ->  Scope = domestic
    ;   Scope = international
    ).

% --- what 5(b) permits -----------------------------------------------------

%! cabin_column(?Cabin, ?Column) is nondet.
%  The fare's cabin against the columns of the 5(b) table. Business has two,
%  because the table publishes two and this validator reports the DONE one
%  while IONE3 exists in select markets -- see data/limits.pl.
cabin_column(first,    first).
cabin_column(business, business_done).
cabin_column(business, business_ione3).
cabin_column(economy,  economy).

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
conditional(_, Carrier, Scope, Cabin, Class, Reason) :-
    lower_column(Cabin, Column),
    booking_code(Carrier, Scope, Column, Class),
    column_cabin_word(Column, Lower),
    cabin_word(Cabin, Word),
    article(Word, lower, Fare),
    format(atom(Reason),
           'it is the ~w code, which ~w fare may use only where ~w is not offered or not available on that flight',
           [Lower, Fare, Word]).
conditional(_, Carrier, _, business, Class, Reason) :-
    business_alternate_code(Carrier, Class),
    iata(Carrier, U),
    format(atom(Reason),
           'section 5(b) lets a DONE Business fare book it on ~w in place of the applicable code',
           [U]).
conditional(_, _, _, first, Class, Reason) :-
    first_alternate_code(Class),
    Reason = 'a First fare may book Y only where the applicable lower-class code is unavailable'.
% The exception is written "for services within the Middle East", so it is a
% fact about the sector and not about the carrier: a QR flight from Doha to
% Bangkok is not within the Middle East and A is not open to it. Both endpoints
% have to be in the zone -- which is the same zone 4(c)(b) and the section 12
% surcharge band are written in, and the reason geo.pl tracks it at all.
conditional(S, Carrier, _, business, Class, Reason) :-
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

validate:violation(A, v(booking_code, '5(b)', error, Msg,
                        [segments([N]), carrier(U), given(Given),
                         expected(Expected)])) :-
    classed_flight(A, S),
    N = S.n,
    row_for(S, Carrier, Scope),
    Class = S.booking_class,
    \+ applicable(Carrier, Scope, A.cabin, Class),
    \+ conditional(S, Carrier, Scope, A.cabin, Class, _),
    iata(Carrier, U),
    upcase_atom(Class, Given),
    expected_phrase(Carrier, Scope, A.cabin, Expected),
    cabin_word(A.cabin, Word),
    article(Word, upper, Fare),
    format(atom(Msg),
           'Segment ~w is sold in ~w on ~w. ~w Explorer fare books into ~w; ~w is not a code section 5(b) names.',
           [N, Given, U, Fare, Expected, Given]).

validate:violation(A, v(booking_code_conditional, '5(b)', warning, Msg,
                        [segments([N]), carrier(U), given(Given),
                         expected(Expected)])) :-
    classed_flight(A, S),
    N = S.n,
    row_for(S, Carrier, Scope),
    Class = S.booking_class,
    \+ applicable(Carrier, Scope, A.cabin, Class),
    once(conditional(S, Carrier, Scope, A.cabin, Class, Reason)),
    iata(Carrier, U),
    upcase_atom(Class, Given),
    expected_phrase(Carrier, Scope, A.cabin, Expected),
    format(atom(Msg),
           'Segment ~w is sold in ~w on ~w rather than ~w. That is allowed: ~w. The fare for the highest class used applies.',
           [N, Given, U, Expected, Reason]).

% A class was given and the row it should be read against could not be found.
% Reported once for the whole itinerary rather than per segment: the reason is
% the same each time and a per-segment version would bury the one fact worth
% having, which is which segments to fix.
validate:violation(A, v(booking_code_unreadable, '5(b)', indeterminate, Msg,
                        [segments(Ns)])) :-
    findall(N, ( classed_flight(A, S), \+ row_for(S, _, _), N = S.n ), Ns),
    Ns \== [],
    length(Ns, Count),
    plural(Count, 'Segment', Word),
    listed_and(Ns, List),
    agree(Count, 'states', 'state', States),
    agree(Count, 'names', 'name', Names),
    format(atom(Msg),
           '~w ~w ~w a booked class but ~w no carrier section 5(b) publishes codes for, so the class cannot be checked.',
           [Word, List, States, Names]).

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
                      [booking_code, booking_code_conditional,
                       booking_code_unreadable])) :-
    classed_flight(A, _),
    flights(A, Flights),
    tally(A, Stated, Counts),
    cabin_word(A.cabin, Word),
    article(Word, lower, Fare),
    plural(Flights, 'flight', Flight),
    findall(Part, register_part(Counts, Part), Parts),
    listed_and(Parts, Tail),
    format(atom(Detail), '~w of ~w ~w state the class sold, on ~w fare. ~w.',
           [Stated, Flights, Flight, Fare, Tail]).

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
