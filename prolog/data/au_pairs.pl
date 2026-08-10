:- module(au_pairs, [au_restricted_pair/2, au_pair_set/2]).

/** <module> 4(l) Australian city pairs.

    "Within Australia -- only one nonstop/single plane service flight is
    permitted between any of the following sets of points." The cap is per set,
    not per city pair, so the set name is carried through to the violation.
*/

%! au_pair_set(?SetName, ?Members) is nondet.
au_pair_set(bme, bme-[bne, mel, syd]).
au_pair_set(drw, drw-[cbr, mel, syd]).
au_pair_set(kta, kta-[bne, mel, syd]).
au_pair_set(per, per-[bne, cbr, cns, syd, mel]).

%! au_restricted_pair(+From, +To, -SetName) is semidet.
%  Direction-independent.
au_restricted_pair(From-To, Set) :-
    au_pair_set(Set, Hub-Others),
    (   From == Hub, memberchk(To, Others)
    ;   To == Hub, memberchk(From, Others)
    ),
    !.
