:- module(r19_discounts, []).

/** <module> Rule 19 -- children and infants.

    The arithmetic itself is informational and lives in pricing.pl; what is
    checkable here is eligibility.
*/

:- use_module('../geo').
:- use_module('../annotate').
:- use_module('../phrasing').
:- use_module('../../data/limits').

:- multifile validate:violation/2.
:- multifile validate:check/2.

validate:check(A, chk(passengers, '19', 'Children and infants', Detail,
                      [unaccompanied_child, infant_russia_origin,
                       infant_age_unstated, infant_turns_two, infant_too_old,
                       child_age_out_of_range])) :-
    findall(T, ( member(P, A.passengers), T = P.type ), Types),
    Types \== [],
    msort(Types, Sorted),
    clumped(Sorted, Counts),
    findall(Part, ( member(Type-N, Counts), quantity(N, Type, Part) ), Parts),
    listed_and(Parts, Party),
    (   ( memberchk(child, Types) ; memberchk(infant, Types) )
    ->  limit(child_min_age, MinAge),
        limit(child_max_age, MaxAge),
        format(atom(Detail),
               'The booking is for ~w. The child discount is for ages ~w to ~w. A child or infant must travel with an adult.',
               [Party, MinAge, MaxAge])
    ;   format(atom(Detail), 'The booking is for ~w. No child or infant rules apply.', [Party])
    ).

% "Unaccompanied children are not accepted for transportation using the
% oneworld Explorer fare."
validate:violation(A, v(unaccompanied_child, '19', error, Msg, [])) :-
    member(P, A.passengers),
    memberchk(P.type, [child, infant]),
    \+ ( member(Q, A.passengers), Q.type == adult ),
    format(atom(Msg),
           'The booking contains a child or infant with no accompanying adult; unaccompanied children are not accepted on this fare.',
           []).

% "For travel commencing in Russia, an infant under 2 without a seat is not
% permitted. A full Child fare must be purchased for the entire journey."
validate:violation(A, v(infant_russia_origin, '19', error, Msg, [country('RU')])) :-
    A.origin \== unknown,
    airport_country(A.origin, 'RU'),
    member(P, A.passengers),
    P.type == infant,
    format(atom(Msg),
           'Travel commences in Russia, where an infant under 2 without a seat is not permitted; a full child fare must be purchased for the entire journey.',
           []).

% "If an infant reaches two years of age after travel has commenced but before
% travel is complete, a full child fare ticket must be purchased for the entire
% journey." Age is optional input, so this is a warning when it is absent.
validate:violation(A, v(infant_age_unstated, '19', warning, Msg, [])) :-
    member(P, A.passengers),
    P.type == infant,
    P.age == unknown,
    format(atom(Msg),
           'An infant is booked without an age; if the infant turns 2 before travel is complete a full child fare is required for the entire journey.',
           []).

% The same clause, for an infant who is under 2 now. The input carries an age
% and not a date of birth, so a one-year-old who turns 2 next month and one who
% turned 1 last week are the same value here. On a fare whose journey may run a
% full twelve months the first is a live case rather than a remote one, and the
% consequence -- a full child fare for the entire journey, bought retroactively
% -- is expensive enough to be worth saying out loud. Reported as a warning
% because it is a question about a date nobody supplied, not a rule broken.
validate:violation(A, v(infant_turns_two, '19', warning, Msg, [age(Age), max(Max)])) :-
    member(P, A.passengers),
    P.type == infant,
    Age = P.age,
    integer(Age),
    limit(child_min_age, Max),
    Age =:= Max - 1,
    format(atom(Msg),
           'An infant is booked at age ~w; if they reach ~w before travel is complete a full child fare is required for the entire journey.',
           [Age, Max]).

validate:violation(A, v(infant_too_old, '19', error, Msg, [age(Age), max(Max)])) :-
    member(P, A.passengers),
    P.type == infant,
    Age = P.age,
    integer(Age),
    limit(child_min_age, Max),
    Age >= Max,
    format(atom(Msg),
           'A passenger is booked as an infant at age ~w; the infant fare applies under ~w years of age.',
           [Age, Max]).

validate:violation(A, v(child_age_out_of_range, '19', error, Msg,
                        [age(Age), min(Min), max(Max)])) :-
    member(P, A.passengers),
    P.type == child,
    Age = P.age,
    integer(Age),
    limit(child_min_age, Min),
    limit(child_max_age, Max),
    \+ between(Min, Max, Age),
    format(atom(Msg),
           'A passenger is booked as a child at age ~w; the child discount applies to ages ~w-~w.',
           [Age, Min, Max]).
