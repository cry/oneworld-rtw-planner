:- module(r07_max_stay, []).

/** <module> Rule 7 -- maximum stay.

    "Return travel from the last stopover point must commence no later than 12
    months after departure."
*/

:- use_module('../annotate').
:- use_module('../itinerary').
:- use_module('../phrasing').
:- use_module('../../data/limits').

:- multifile validate:violation/2.
:- multifile validate:not_checked/2.
:- multifile validate:check/2.

validate:not_checked(A, nc(max_stay, '7',
                           'Return travel from the last stopover must commence within 12 months of departure, but a routing-only itinerary carries no dates to measure it against.')) :-
    A.mode == routing.

% Tested against the 12-month anniversary rather than a whole-month count: a
% return commencing 20 Sep 2027 on a journey that departed 1 Sep 2026 is late,
% but is only twelve whole months, so counting months lets it through and keeps
% letting it through until a thirteenth month completes.
validate:violation(A, v(max_stay, '7', error, Msg,
                        [segments([1, N]), elapsed(Elapsed), max(Max)])) :-
    max_stay_span(A, N, Dep, Onward),
    limit(max_stay_months, Max),
    dt_beyond_months(Dep, Onward, Max),
    elapsed_phrase(Dep, Onward, Elapsed),
    dt_plus_months(Dep, Max, Deadline),
    dt_words(Deadline, By),
    format(atom(Msg),
           'The flight on from the last stopover (segment ~w) leaves ~w after the first flight. It had to leave by ~w.',
           [N, Elapsed, By]).

validate:violation(A, v(max_stay, '7', indeterminate, Msg, [])) :-
    A.mode == full,
    A.segments \== [],
    \+ max_stay_span(A, _, _, _),
    max_stay_gap(A, Reason),
    limit(max_stay_months, Max),
    format(atom(Msg),
           'The ~w-month maximum stay could not be checked: ~w.', [Max, Reason]).

% An itinerary with no stopover at all is not an unanswered question -- there
% is no return travel from a last stopover for the 12 months to run to -- and
% rule 8 already reports the absence. Only a missing *time* leaves rule 7 with
% a question it cannot answer.
max_stay_gap(A, 'no departure time was given for the first segment') :-
    \+ departure(A, _),
    !.
max_stay_gap(A, 'the onward flight from the last stopover carries no departure time') :-
    last_stopover_onward(A, _).

%! max_stay_span(+A, -N, -Dep, -Onward) is semidet.
%  The two instants rule 7 measures between, and the segment the second belongs
%  to. Fails when either is missing, which is what max_stay_gap/2 explains.
max_stay_span(A, N, Dep, Onward) :-
    departure(A, Dep),
    last_stopover_onward(A, N),
    ann_seg(A, S),
    S.n == N,
    Onward = S.dep,
    Onward \== unknown.

departure(A, Dep) :-
    A.segments = [First|_],
    Dep = First.dep,
    Dep \== unknown.

%! last_stopover_onward(+A, -N) is semidet.
%  The segment whose departure the 12 months is measured to: the onward flight
%  from the last stopover that ticketed travel resumes from by air. A stopover
%  followed only by a surface sector has no return travel to time -- under 4(g)
%  that crossing is the passenger's own arrangement and carries no schedule --
%  so the search steps back to the last stopover that does.
last_stopover_onward(A, N) :-
    findall(Num,
            ( ann_point(A, P),
              P.kind == stopover,
              Num is P.after + 1,
              ann_seg(A, S),
              S.n == Num,
              S.type == flight
            ),
            Onward),
    Onward \== [],
    last(Onward, N).

%! elapsed_phrase(+From, +To, -Phrase) is det.
%  "12 months and 19 days". Months alone cannot say how far past a limit a
%  journey ran, which is the only interesting thing about a journey that is.
elapsed_phrase(From, To, Phrase) :-
    dt_months_between(From, To, Months),
    dt_plus_months(From, Months, Anniversary),
    dt_days_between(Anniversary, To, Days0),
    Days is truncate(Days0),
    (   Months =:= 0
    ->  quantity(Days, 'day', Phrase)
    ;   quantity(Months, 'month', MonthPart),
        (   Days =:= 0
        ->  Phrase = MonthPart
        ;   quantity(Days, 'day', DayPart),
            format(atom(Phrase), '~w and ~w', [MonthPart, DayPart])
        )
    ).

validate:check(A, Check) :-
    A.segments \== [],
    limit(max_stay_months, Max),
    % The middle branch tests max_stay_gap/2, the same predicate the
    % indeterminate violation is built from, so the register cannot call the
    % rule inapplicable in a run where it fired.
    (   max_stay_span(A, N, Dep, Onward)
    ->  elapsed_phrase(Dep, Onward, Elapsed),
        dt_plus_months(Dep, Max, Deadline),
        dt_words(Deadline, By),
        format(atom(Detail),
               '~w pass between the first flight and the flight on from the last stopover (segment ~w). That flight had to leave by ~w.',
               [Elapsed, N, By]),
        Check = chk(max_stay, '7', 'Maximum stay', Detail, [max_stay])
    ;   max_stay_gap(A, Reason)
    ->  format(atom(Detail),
               'The flight on from the last stopover must leave within ~w months of the first flight. It cannot be checked here, because ~w.',
               [Max, Reason]),
        Check = chk(max_stay, '7', 'Maximum stay', Detail, [max_stay])
    ;   Check = chk_na(max_stay, '7', 'Maximum stay',
                       'No stopover is followed by a flight, so there is no return travel for the 12 months to run to.')
    ).
