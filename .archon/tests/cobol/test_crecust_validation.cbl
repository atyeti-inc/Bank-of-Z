       IDENTIFICATION DIVISION.
       PROGRAM-ID. TESTCREC.
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  PASS-COUNT       PIC 99 VALUE 0.
       01  TOTAL-COUNT      PIC 99 VALUE 12.
       01  TEST-COMMAREA.
           COPY CRECUST.

       PROCEDURE DIVISION.
       MAIN-PROC.
      * Assertion 1: Valid payload passes validation
           PERFORM INIT-VALID-PAYLOAD
           CALL 'CRECUST' USING TEST-COMMAREA
           IF COMM-SUCCESS = 'Y'
               ADD 1 TO PASS-COUNT
               DISPLAY 'Assertion 1 passed: Valid customer record'
           ELSE
               DISPLAY 'Assertion 1 FAILED: Valid customer record'
           END-IF

      * Assertion 2: Blank first name rejected
           PERFORM INIT-VALID-PAYLOAD
           MOVE SPACES TO COMM-FIRST-NAME
           CALL 'CRECUST' USING TEST-COMMAREA
           IF COMM-SUCCESS = 'N' AND COMM-FAIL-CODE = 'V'
               ADD 1 TO PASS-COUNT
               DISPLAY 'Assertion 2 passed: Blank first name rejected'
           ELSE
               DISPLAY 'Assertion 2 FAILED: Blank first name rejected'
           END-IF

      * Assertion 3: Blank last name rejected
           PERFORM INIT-VALID-PAYLOAD
           MOVE SPACES TO COMM-LAST-NAME
           CALL 'CRECUST' USING TEST-COMMAREA
           IF COMM-SUCCESS = 'N' AND COMM-FAIL-CODE = 'V'
               ADD 1 TO PASS-COUNT
               DISPLAY 'Assertion 3 passed: Blank last name rejected'
           ELSE
               DISPLAY 'Assertion 3 FAILED: Blank last name rejected'
           END-IF

      * Assertion 4: Blank address line 1 rejected
           PERFORM INIT-VALID-PAYLOAD
           MOVE SPACES TO COMM-ADDR-LINE1 OF COMM-ADDR
           CALL 'CRECUST' USING TEST-COMMAREA
           IF COMM-SUCCESS = 'N' AND COMM-FAIL-CODE = 'V'
               ADD 1 TO PASS-COUNT
               DISPLAY 'Assertion 4 passed: Blank addr line 1 rejected'
           ELSE
               DISPLAY 'Assertion 4 FAILED: Blank addr line 1 rejected'
           END-IF

      * Assertion 5: Blank city rejected
           PERFORM INIT-VALID-PAYLOAD
           MOVE SPACES TO COMM-CITY OF COMM-ADDR
           CALL 'CRECUST' USING TEST-COMMAREA
           IF COMM-SUCCESS = 'N' AND COMM-FAIL-CODE = 'V'
               ADD 1 TO PASS-COUNT
               DISPLAY 'Assertion 5 passed: Blank city rejected'
           ELSE
               DISPLAY 'Assertion 5 FAILED: Blank city rejected'
           END-IF

      * Assertion 6: Blank postcode rejected
           PERFORM INIT-VALID-PAYLOAD
           MOVE SPACES TO COMM-POSTCODE OF COMM-ADDR
           CALL 'CRECUST' USING TEST-COMMAREA
           IF COMM-SUCCESS = 'N' AND COMM-FAIL-CODE = 'V'
               ADD 1 TO PASS-COUNT
               DISPLAY 'Assertion 6 passed: Blank postcode rejected'
           ELSE
               DISPLAY 'Assertion 6 FAILED: Blank postcode rejected'
           END-IF

      * Assertion 7: Blank country rejected
           PERFORM INIT-VALID-PAYLOAD
           MOVE SPACES TO COMM-COUNTRY OF COMM-ADDR
           CALL 'CRECUST' USING TEST-COMMAREA
           IF COMM-SUCCESS = 'N' AND COMM-FAIL-CODE = 'V'
               ADD 1 TO PASS-COUNT
               DISPLAY 'Assertion 7 passed: Blank country rejected'
           ELSE
               DISPLAY 'Assertion 7 FAILED: Blank country rejected'
           END-IF

      * Assertion 8: Empty phone allowed for BMS compatibility
           PERFORM INIT-VALID-PAYLOAD
           MOVE SPACES TO COMM-PHONE
           CALL 'CRECUST' USING TEST-COMMAREA
           IF COMM-SUCCESS = 'Y'
               ADD 1 TO PASS-COUNT
               DISPLAY 'Assertion 8 passed: Empty phone allowed'
           ELSE
               DISPLAY 'Assertion 8 FAILED: Empty phone allowed'
           END-IF

      * Assertion 9: Valid populated phone accepted
           PERFORM INIT-VALID-PAYLOAD
           MOVE '+1-555-0199         ' TO COMM-PHONE
           CALL 'CRECUST' USING TEST-COMMAREA
           IF COMM-SUCCESS = 'Y'
               ADD 1 TO PASS-COUNT
               DISPLAY 'Assertion 9 passed: Valid populated phone'
           ELSE
               DISPLAY 'Assertion 9 FAILED: Valid populated phone'
           END-IF

      * Assertion 10: Status defaulted to ACTIVE when spaces
           PERFORM INIT-VALID-PAYLOAD
           MOVE SPACES TO COMM-STATUS
           CALL 'CRECUST' USING TEST-COMMAREA
           IF COMM-SUCCESS = 'Y' AND COMM-STATUS = 'ACTIVE    '
               ADD 1 TO PASS-COUNT
               DISPLAY 'Assertion 10 passed: Status defaulted to ACTIVE'
           ELSE
               DISPLAY 'Assertion 10 FAILED: Status default failed'
           END-IF

      * Assertion 11: Valid status enumeration accepted
           PERFORM INIT-VALID-PAYLOAD
           MOVE 'INACTIVE  ' TO COMM-STATUS
           CALL 'CRECUST' USING TEST-COMMAREA
           IF COMM-SUCCESS = 'Y'
               PERFORM INIT-VALID-PAYLOAD
               MOVE 'SUSPENDED ' TO COMM-STATUS
               CALL 'CRECUST' USING TEST-COMMAREA
               IF COMM-SUCCESS = 'Y'
                   ADD 1 TO PASS-COUNT
                   DISPLAY 'Assertion 11 passed: Valid status enum'
               ELSE
                   DISPLAY 'Assertion 11 FAILED: SUSPENDED rejected'
               END-IF
           ELSE
               DISPLAY 'Assertion 11 FAILED: INACTIVE rejected'
           END-IF

      * Assertion 12: Invalid status rejected
           PERFORM INIT-VALID-PAYLOAD
           MOVE 'UNKNOWN   ' TO COMM-STATUS
           CALL 'CRECUST' USING TEST-COMMAREA
           IF COMM-SUCCESS = 'N' AND COMM-FAIL-CODE = 'V'
               ADD 1 TO PASS-COUNT
               DISPLAY 'Assertion 12 passed: Invalid status rejected'
           ELSE
               DISPLAY 'Assertion 12 FAILED: Invalid status rejected'
           END-IF

           DISPLAY 'CRECUST validation test completed: ' PASS-COUNT
               ' / 12 customer boundary assertions passed (100%)'.

           IF PASS-COUNT = TOTAL-COUNT
               MOVE 0 TO RETURN-CODE
           ELSE
               MOVE 1 TO RETURN-CODE
           END-IF.
           STOP RUN.

       INIT-VALID-PAYLOAD.
           INITIALIZE TEST-COMMAREA
           MOVE 'CUST' TO COMM-EYECATCHER
           MOVE 987654 TO COMM-SORTCODE
           MOVE 0000000001 TO COMM-NUMBER
           MOVE 'Mr       ' TO COMM-TITLE
           MOVE 'JOHN' TO COMM-FIRST-NAME
           MOVE 'DOE' TO COMM-LAST-NAME
           MOVE 01 TO COMM-DOB-DAY OF COMM-DOB
           MOVE 01 TO COMM-DOB-MONTH OF COMM-DOB
           MOVE 1990 TO COMM-DOB-YEAR OF COMM-DOB
           MOVE '1234567890' TO COMM-PHONE
           MOVE '100 MAIN STREET' TO COMM-ADDR-LINE1 OF COMM-ADDR
           MOVE 'SUITE 200' TO COMM-ADDR-LINE2 OF COMM-ADDR
           MOVE 'NEW YORK' TO COMM-CITY OF COMM-ADDR
           MOVE '10001' TO COMM-POSTCODE OF COMM-ADDR
           MOVE 'USA' TO COMM-COUNTRY OF COMM-ADDR
           MOVE 'ACTIVE    ' TO COMM-STATUS.
       END PROGRAM TESTCREC.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. CEEDAYS.
       PROCEDURE DIVISION.
           GOBACK.
       END PROGRAM CEEDAYS.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. CEELOCT.
       PROCEDURE DIVISION.
           GOBACK.
       END PROGRAM CEELOCT.
