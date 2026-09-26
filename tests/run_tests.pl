:- initialization(main, main).

:- [ '/home/runner/work/minichatbot/minichatbot/tests/test_and.pl',
      '/home/runner/work/minichatbot/minichatbot/tests/test_dimensions.pl',
      '/home/runner/work/minichatbot/minichatbot/tests/test_learning.pl',
      '/home/runner/work/minichatbot/minichatbot/tests/test_prediction.pl',
      '/home/runner/work/minichatbot/minichatbot/tests/test_generalisation.pl',
      '/home/runner/work/minichatbot/minichatbot/tests/test_memory.pl',
      '/home/runner/work/minichatbot/minichatbot/tests/test_corrections.pl',
      '/home/runner/work/minichatbot/minichatbot/tests/test_bootstrap.pl'
   ].

main :-
    run_tests,
    halt.
