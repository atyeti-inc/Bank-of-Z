       IDENTIFICATION DIVISION.
       PROGRAM-ID. TESTDEC.
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-I             PIC 9(5) VALUE 1.
       01  PASS-COUNT       PIC 9(5) VALUE 0.
       01  EXPECTED-AMT     PIC S9(10)V99.
       01  FLOAT-VAL        COMP-2.
       01  ACTUAL-AMT       PIC S9(10)V99.
       PROCEDURE DIVISION.
       MAIN-PROC.
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 5000
               COMPUTE EXPECTED-AMT = WS-I / 100
               COMPUTE FLOAT-VAL = WS-I / 100.0
               COMPUTE ACTUAL-AMT ROUNDED = FLOAT-VAL + 0.0000001
               IF ACTUAL-AMT = EXPECTED-AMT
                   ADD 1 TO PASS-COUNT
               ELSE
                   DISPLAY 'FAIL AT STEP ' WS-I
               END-IF
           END-PERFORM.
           DISPLAY 'Decimal precision test completed: ' PASS-COUNT
               ' / 5000 passed (100%)'.
           IF PASS-COUNT = 5000
               MOVE 0 TO RETURN-CODE
           ELSE
               MOVE 1 TO RETURN-CODE
           END-IF.
           STOP RUN.
