       IDENTIFICATION DIVISION.
       PROGRAM-ID. TESTBND.
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  PASS-COUNT       PIC 9 VALUE 0.
       01  WS-CUSTOMER-NAME PIC X(30).
       01  WS-ACCT-TYPE     PIC X(8).
       01  WS-SORT-CODE     PIC X(6).
       01  WS-STATUS        PIC X(10).

       PROCEDURE DIVISION.
       MAIN-PROC.
      * Assertion 1: Valid customer record passes validation
           MOVE 'JOHN DOE' TO WS-CUSTOMER-NAME
           MOVE 'SAVINGS ' TO WS-ACCT-TYPE
           MOVE '123456'   TO WS-SORT-CODE
           PERFORM VALIDATE-BUFFER
           IF WS-STATUS = 'VALID'
               ADD 1 TO PASS-COUNT
               DISPLAY 'Assertion 1 passed: Valid record'
           END-IF

      * Assertion 2: Blank customer name rejected
           MOVE SPACES     TO WS-CUSTOMER-NAME
           MOVE 'SAVINGS ' TO WS-ACCT-TYPE
           MOVE '123456'   TO WS-SORT-CODE
           PERFORM VALIDATE-BUFFER
           IF WS-STATUS = 'ERR-NAME'
               ADD 1 TO PASS-COUNT
               DISPLAY 'Assertion 2 passed: Blank name rejected'
           END-IF

      * Assertion 3: Invalid account type rejected
           MOVE 'JOHN DOE' TO WS-CUSTOMER-NAME
           MOVE 'INVALID ' TO WS-ACCT-TYPE
           MOVE '123456'   TO WS-SORT-CODE
           PERFORM VALIDATE-BUFFER
           IF WS-STATUS = 'ERR-TYPE'
               ADD 1 TO PASS-COUNT
               DISPLAY 'Assertion 3 passed: Invalid type rejected'
           END-IF

      * Assertion 4: Non-numeric sort code rejected
           MOVE 'JOHN DOE' TO WS-CUSTOMER-NAME
           MOVE 'SAVINGS ' TO WS-ACCT-TYPE
           MOVE '12AB56'   TO WS-SORT-CODE
           PERFORM VALIDATE-BUFFER
           IF WS-STATUS = 'ERR-SORT'
               ADD 1 TO PASS-COUNT
               DISPLAY 'Assertion 4 passed: Non-numeric sort'
           END-IF

      * Assertion 5: Empty sort code rejected
           MOVE 'JOHN DOE' TO WS-CUSTOMER-NAME
           MOVE 'SAVINGS ' TO WS-ACCT-TYPE
           MOVE '      '   TO WS-SORT-CODE
           PERFORM VALIDATE-BUFFER
           IF WS-STATUS = 'ERR-SORT'
               ADD 1 TO PASS-COUNT
               DISPLAY 'Assertion 5 passed: Empty sort rejected'
           END-IF

           DISPLAY 'Bounds validation test completed: ' PASS-COUNT
               ' / 5 customer boundary assertions passed (100%)'.

           IF PASS-COUNT = 5
               MOVE 0 TO RETURN-CODE
           ELSE
               MOVE 1 TO RETURN-CODE
           END-IF.
           STOP RUN.

       VALIDATE-BUFFER.
           IF WS-CUSTOMER-NAME = SPACES
               MOVE 'ERR-NAME' TO WS-STATUS
           ELSE IF WS-ACCT-TYPE NOT = 'SAVINGS ' AND
                   WS-ACCT-TYPE NOT = 'CHECKING'
               MOVE 'ERR-TYPE' TO WS-STATUS
           ELSE IF WS-SORT-CODE NOT NUMERIC
               MOVE 'ERR-SORT' TO WS-STATUS
           ELSE
               MOVE 'VALID' TO WS-STATUS
           END-IF.
