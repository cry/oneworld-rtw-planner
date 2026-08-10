:- module(validate,
          [ validate/2,
            validate_annotated/3,
            violation/2,
            not_checked/2,
            severity_rank/2,
            verdict_of/2
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
*/

:- use_module(annotate).
:- use_module(pricing).

:- multifile violation/2.
:- discontiguous violation/2.

:- multifile not_checked/2.
:- discontiguous not_checked/2.

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

validate_ann(A, report(Verdict, Violations, Fare, Skipped)) :-
    findall(V, violation(A, V), Found),
    append(A.input_errors, Found, All),
    sort(All, Deduped),
    order_for_display(Deduped, Violations),
    verdict_of(Violations, Verdict),
    findall(NC, not_checked(A, NC), Skipped0),
    sort(Skipped0, Skipped1),
    order_not_checked(Skipped1, Skipped),
    fare(A, Fare).

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
    map_list_to_pairs([nc(R, C, _), C-R]>>true, NCs, Pairs),
    keysort(Pairs, Keyed),
    pairs_values(Keyed, Sorted).

display_key(v(Rule, Citation, Severity, _, Evidence), key(Rank, Seg, Citation, Rule)) :-
    severity_rank(Severity, Rank),
    (   memberchk(segments([S|_]), Evidence)
    ->  Seg = S
    ;   Seg = 0
    ).
