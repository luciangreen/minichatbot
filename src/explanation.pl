:- module(explanation,
    [ explain_prediction/3
    ]).

:- use_module(prediction).

explain_prediction(Known, Pair, Explanation) :-
    candidate_explanation(Known, Pair, Explanation).
