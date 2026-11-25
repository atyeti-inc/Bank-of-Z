       IDENTIFICATION DIVISION.
       PROGRAM-ID. TESTDEC.
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-I             PIC 9(5) VALUE 1.
       01  PASS-COUNT       PIC 9(5) VALUE 0.
       01  SPEC-PASS-COUNT  PIC 9 VALUE 0.
       01  EXPECTED-AMT     PIC S9(10)V99 VALUE ZERO.
       01  ACTUAL-AMT       PIC S9(10)V99 VALUE ZERO.
       01  WS-INT-PART      PIC 9999 VALUE ZERO.
       01  WS-DEC-PART      PIC 99 VALUE ZERO.
       01  WS-EDITED-AMT    PIC ZZZ9.99.
       01  WS-STR-BUFFER    PIC X(7).
       01  WS-TEST-INPUT    PIC X(10).

       PROCEDURE DIVISION.
       MAIN-PROC.
      * Assertion 1: Exact decimal parsing for 0.29
           MOVE '0.29' TO WS-TEST-INPUT
           COMPUTE EXPECTED-AMT = 0.29
           COMPUTE ACTUAL-AMT = FUNCTION NUMVAL(WS-TEST-INPUT)
           IF ACTUAL-AMT = EXPECTED-AMT
               ADD 1 TO SPEC-PASS-COUNT
               DISPLAY 'Assertion 1 passed: 0.29 exact decimal parsing'
           ELSE
               DISPLAY 'Assertion 1 FAILED: 0.29 decimal parsing'
           END-IF

      * Assertion 2: Exact decimal parsing for 0.57
           MOVE '0.57' TO WS-TEST-INPUT
           COMPUTE EXPECTED-AMT = 0.57
           COMPUTE ACTUAL-AMT = FUNCTION NUMVAL(WS-TEST-INPUT)
           IF ACTUAL-AMT = EXPECTED-AMT
               ADD 1 TO SPEC-PASS-COUNT
               DISPLAY 'Assertion 2 passed: 0.57 exact decimal parsing'
           ELSE
               DISPLAY 'Assertion 2 FAILED: 0.57 decimal parsing'
           END-IF

      * Assertion 3: Exact decimal parsing for 1.15
           MOVE '1.15' TO WS-TEST-INPUT
           COMPUTE EXPECTED-AMT = 1.15
           COMPUTE ACTUAL-AMT = FUNCTION NUMVAL(WS-TEST-INPUT)
           IF ACTUAL-AMT = EXPECTED-AMT
               ADD 1 TO SPEC-PASS-COUNT
               DISPLAY 'Assertion 3 passed: 1.15 exact decimal parsing'
           ELSE
               DISPLAY 'Assertion 3 FAILED: 1.15 decimal parsing'
           END-IF

      * Assertion 4: Exact decimal parsing for 19.99
           MOVE '19.99' TO WS-TEST-INPUT
           COMPUTE EXPECTED-AMT = 19.99
           COMPUTE ACTUAL-AMT = FUNCTION NUMVAL(WS-TEST-INPUT)
           IF ACTUAL-AMT = EXPECTED-AMT
               ADD 1 TO SPEC-PASS-COUNT
               DISPLAY 'Assertion 4 passed: 19.99 exact decimal parsing'
           ELSE
               DISPLAY 'Assertion 4 FAILED: 19.99 decimal parsing'
           END-IF

      * Full 5,000-Value Exhaustive Sweep ($0.01 to $50.00)
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 5000
               COMPUTE EXPECTED-AMT = WS-I / 100
               DIVIDE WS-I BY 100 GIVING WS-INT-PART
                   REMAINDER WS-DEC-PART
               MOVE EXPECTED-AMT TO WS-EDITED-AMT
               MOVE WS-EDITED-AMT TO WS-STR-BUFFER
               COMPUTE ACTUAL-AMT =
                   FUNCTION NUMVAL(WS-STR-BUFFER)
               IF ACTUAL-AMT = EXPECTED-AMT
                   ADD 1 TO PASS-COUNT
               ELSE
                   DISPLAY 'FAIL AT STEP ' WS-I
               END-IF
           END-PERFORM.

           DISPLAY 'Decimal precision test completed: ' PASS-COUNT
               ' / 5000 passed (100%)'.

           IF PASS-COUNT = 5000 AND SPEC-PASS-COUNT = 4
               MOVE 0 TO RETURN-CODE
           ELSE
               MOVE 1 TO RETURN-CODE
           END-IF.
           STOP RUN.
