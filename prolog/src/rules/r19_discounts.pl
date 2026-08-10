:- module(r19_discounts, []).

/** <module> Rule 19 -- children and infants.

    The arithmetic itself is informational and lives in pricing.pl; what is
    checkable here is eligibility.
*/

:- use_module('../geo').
:- use_module('../annotate').
:- use_module('../../data/limits').

:- multifile validate:violation/2.

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
