:- module(validate,
          [ validate/2,
            validate_annotated/3,
            violation/2,
            not_checked/2,
            check/2,
            severity_rank/2,
            verdict_of/2,
            citation_key/2
          ]).

/** <module> The findall driver and the rule registry.

    Each rule is a clause of violation/2 that *succeeds when the rule is
    broken* and binds a term describing the breakage. That inversion is the
    single most important design decision in this codebase: a naive
    `valid(I) :- rule1(I), rule2(I), ...` gives a bare "no" with no
    explanation, whereas backtracking over violation/2 enumerates every
    violation of every rule in one pass, each carrying its own evidence.

    Violation shape:

        v(RuleId, Citation, Severity, Message, Evidence)

    Severity is one of:

      error          definitely invalid
      warning        probably invalid, or subject to carrier discretion
      indeterminate  cannot be decided from the input

    `indeterminate` exists so that an itinerary entered without timestamps is
    never reported clean. It is not a passing grade.

    There is a second registry, not_checked/2, for rules a *mode* puts out of
    reach rather than an omission in the data. A routing-only itinerary has no
    calendar at all, so rules 6 and 7 have nothing to measure; calling that
    `indeterminate` would make every routing-only check indeterminate and drain
    the severity of its meaning. Instead those rules are named in the report as
    not checked. The distinction is: `indeterminate` means "you left something
    out that this rule needs", not_checked means "this rule is not answerable
    from the kind of input you gave". Neither is a pass, and both are rendered.

        nc(RuleId, Citation, Reason)

    A third registry, check/2, is the counterpart to both: it states what each
    rule *measured*, whether or not the rule was broken. "No rule was broken"
    is a claim about coverage that a reader has no way to audit, and a cap the
    itinerary sits one under is exactly what a fare-construction tool is asked.
    A check clause reports the measurement and nothing else:

        chk(CheckId, Citation, Label, Detail, Covers)
        chk_na(CheckId, Citation, Label, Reason)

    Covers names the violation ids this measurement decides. The *outcome* is
    never stated by the check clause; validate_ann/2 derives it from the
    violations the same run produced, so a check can never disagree with the
    verdict printed above it. chk_na is for a rule nothing in the itinerary
    engages -- 4(l) with no Australian sectors -- which is a different thing
    from a rule that passed, and a different thing again from one that could
    not be run.

        check(CheckId, Citation, Label, Outcome, Detail)

    Outcome is pass, fail, warning, indeterminate, not_checked or
    not_applicable.
*/

:- use_module(annotate).
:- use_module(pricing).

:- multifile violation/2.
:- discontiguous violation/2.

:- multifile not_checked/2.
:- discontiguous not_checked/2.

:- multifile check/2.
:- discontiguous check/2.

%! validate(+Itin, -Report) is det.
validate(Itin, Report) :-
    annotate(Itin, A),
    validate_ann(A, Report).

%! validate_annotated(+Itin, -Report, -Annotated) is det.
%  Same result, but hands back the annotation pass so a caller can serialize it
%  alongside the report. The web UI needs it to draw the route and to show why
%  a rule fired.
validate_annotated(Itin, Report, A) :-
    annotate(Itin, A),
    validate_ann(A, Report).

validate_ann(A, report(Verdict, Violations, Fare, Skipped, Checks)) :-
    findall(V, violation(A, V), Found),
    append(A.input_errors, Found, All),
    sort(All, Deduped),
    order_for_display(Deduped, Violations),
    verdict_of(Violations, Verdict),
    findall(NC, not_checked(A, NC), Skipped0),
    sort(Skipped0, Skipped1),
    order_not_checked(Skipped1, Skipped),
    checks_of(A, Violations, Skipped, Checks),
    fare(A, Fare).

% --- the check register ----------------------------------------------------

% An itinerary with an unresolvable airport or a gap between two segments is
% not yet the itinerary anyone asked about, and rules measured over it would
% report caps and counts for a journey the reader did not submit. Sixteen lines
% of "ok" under two input errors is the most misleading thing this report could
% say, so the register is withheld until the input parses.
checks_of(A, _, _, []) :-
    A.input_errors \== [],
    !.
% list_to_set/2 rather than sort/2, and a sort key of the citation alone: within
% one rule the checks then come out in the order the rule module declares them,
% which is the order the rule text reads in. Sorting by check id instead would
% put 4(h)'s free-segment caps before its segment count.
checks_of(A, Violations, Skipped, Checks) :-
    findall(C, check(A, C), Raw),
    list_to_set(Raw, Distinct),
    maplist(check_outcome(Violations, Skipped), Distinct, Decided),
    order_checks(Decided, Checks).

check_outcome(_, _, chk_na(Id, Citation, Label, Reason),
              check(Id, Citation, Label, not_applicable, Reason)) :- !.
check_outcome(Violations, Skipped, chk(Id, Citation, Label, Detail, Covers),
              check(Id, Citation, Label, Outcome, Detail)) :-
    check_status(Violations, Skipped, Covers, Outcome).

% Worst first, so a check covering both an error and a warning reads as failed.
check_status(Violations, _, Covers, Outcome) :-
    findall(Rank-Severity,
            ( member(v(Rule, _, Severity, _, _), Violations),
              memberchk(Rule, Covers),
              severity_rank(Severity, Rank) ),
            Ranked),
    Ranked \== [],
    !,
    keysort(Ranked, [_-Worst|_]),
    outcome_of(Worst, Outcome).
check_status(_, Skipped, Covers, not_checked) :-
    member(nc(Rule, _, _), Skipped),
    memberchk(Rule, Covers),
    !.
check_status(_, _, _, pass).

outcome_of(error,         fail).
outcome_of(indeterminate, indeterminate).
outcome_of(warning,       warning).

%! severity_rank(?Severity, ?Rank) is nondet.
severity_rank(error,         0).
severity_rank(indeterminate, 1).
severity_rank(warning,       2).

%! verdict_of(+Violations, -Verdict) is det.
%  Warnings alone do not invalidate an itinerary, but an undecidable rule does
%  prevent a `valid` verdict.
verdict_of(Vs, invalid) :-
    memberchk(v(_, _, error, _, _), Vs), !.
verdict_of(Vs, indeterminate) :-
    memberchk(v(_, _, indeterminate, _, _), Vs), !.
verdict_of(_, valid).

% sort/2 above orders by rule id, which is stable but not useful to read.
% Present the report worst-first, then in itinerary order.
order_for_display(Vs, Sorted) :-
    map_list_to_pairs(display_key, Vs, Pairs),
    keysort(Pairs, Keyed),
    pairs_values(Keyed, Sorted).

% sort/2 above orders these by rule id too; the reader expects rule order.
order_not_checked(NCs, Sorted) :-
    map_list_to_pairs([nc(R, C, _), Key-R]>>citation_key(C, Key), NCs, Pairs),
    keysort(Pairs, Keyed),
    pairs_values(Keyed, Sorted).

% keysort/2 is stable, so ties keep declaration order.
order_checks(Cs, Sorted) :-
    map_list_to_pairs([check(_, C, _, _, _), Key]>>citation_key(C, Key), Cs, Pairs),
    keysort(Pairs, Keyed),
    pairs_values(Keyed, Sorted).

%! citation_key(+Citation, -Key) is det.
%  Rule order, not alphabetical order. Citations are atoms like '4(a),4(b)' and
%  '15', and sorting those as text files rule 15 between rule 0 and rule 4.
citation_key(Citation, Number-Citation) :-
    atom_codes(Citation, Codes),
    leading_digits(Codes, Digits),
    (   Digits == []
    ->  Number = 999
    ;   number_codes(Number, Digits)
    ).

leading_digits([C|T], [C|Ds]) :- code_type(C, digit), !, leading_digits(T, Ds).
leading_digits(_, []).

% The citation goes in through citation_key/2 for the same reason it does in the
% two orderings above: compared as text, rule 15 sorts between rule 0 and rule 4,
% so two violations at the same severity and the same segment came out in ASCII
% order of their citation rather than in rule order.
display_key(v(Rule, Citation, Severity, _, Evidence), key(Rank, Seg, Key, Rule)) :-
    severity_rank(Severity, Rank),
    citation_key(Citation, Key),
    (   memberchk(segments([S|_]), Evidence)
    ->  Seg = S
    ;   Seg = 0
    ).
