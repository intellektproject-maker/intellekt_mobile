# Marks Entry – Test and Release Checklist

Scope: Regular Batch and Test Batch marks entry on the `test` branch only.

## Execution cycle

1. [ ] Confirm both repositories are on the `test` branch and the testing API/database URL is configured.
2. [ ] Run `flutter pub get`.
3. [ ] Run `flutter analyze`.
4. [ ] Run `flutter test`.
5. [ ] Set the test backend URL explicitly and build the APK (the test branch no longer falls back to production):

   ```powershell
   $env:TEST_API_URL = "https://<your-test-service>.up.railway.app"
   flutter build apk --release --dart-define="API_BASE_URL=$env:TEST_API_URL"
   ```
6. [ ] Install the APK and execute the cases below in order.
7. [ ] For every failure: record the case ID, inspect server logs privately, fix only the related test-branch code, rerun the failed case and its regression group, then rebuild and retest.
8. [ ] Whenever marks-entry requirements or implementation change, update this checklist in the same `test`-branch change.
9. [ ] Do not merge to `main` or production unless all required cases pass and the owner explicitly approves the merge.

## Regular Batch – test code and student loading

| ID | Scenario | Expected result |
|---|---|---|
| RB-01 | Enter a valid, unique code such as `S12M100C8` | Board, class, subject, maximum marks and chapter are resolved and shown from validated data |
| RB-02 | Use a valid CBSE code | Board resolves to CBSE and only matching database students load |
| RB-03 | Use a valid ISC code | Board resolves to ISC and only matching database students load |
| RB-04 | Enter an empty code | Helpful validation; no API submission |
| RB-05 | Enter a malformed code | Helpful validation; no students load |
| RB-06 | Use an unsupported board prefix | Code rejected |
| RB-07 | Use a class outside the supported code format | Code rejected |
| RB-08 | Use an invalid subject letter | Code rejected |
| RB-09 | Use maximum marks 0 | Code rejected |
| RB-10 | Use maximum marks 1000 or more | Code rejected |
| RB-11 | Use any non-empty text or number after `C` in the test code (for example `C8`, `Ccombined`, `CABC`) | Suffix is accepted; it does not force the Chapter field value |
| RB-12 | Enter Chapter `0`, negative value, or text other than `combined` | Chapter validation blocks saving |
| RB-13 | Enter Chapter `1`, `99`, or `combined` | Accepted; Chapter value is saved and returned when the test is loaded again |
| RB-14 | Use a code already in the tests table | Show “This test code is already taken”; no marks saved |
| RB-15 | Use a code already present in marks history | Duplicate rejected |
| RB-16 | Code class/board has no matching database students | Friendly no-students message |
| RB-17 | Subject is not configured in database | Code rejected without saving |
| RB-18 | Students exist but are not enrolled in the decoded subject | They are not loaded |
| RB-19 | Database contains students from other classes/boards/subjects | Only eligible students appear |
| RB-20 | Database contains non-Regular Batch student records | Non-Regular Batch records are excluded |

## Regular Batch – marks input and submission

| ID | Scenario | Expected result |
|---|---|---|
| RB-21 | Enter mark 0 | Accepted |
| RB-22 | Enter mark equal to test maximum | Accepted |
| RB-23 | Enter a normal whole-number mark | Accepted |
| RB-24 | Enter lowercase `a` | Automatically becomes uppercase `A` |
| RB-25 | Enter uppercase `A` | Accepted as absent |
| RB-26 | Enter any other letter | Rejected by input formatter |
| RB-27 | Enter a special character | Rejected |
| RB-28 | Enter a negative number | Rejected |
| RB-29 | Enter a decimal value | Rejected |
| RB-30 | Enter 100000 | Accepted by field range; server also checks the test maximum |
| RB-31 | Enter 100001 | Rejected |
| RB-32 | Paste mixed invalid text | Invalid paste rejected; prior value retained |
| RB-33 | Leave one student blank while entering marks for another student | Only the entered student is submitted; blank student remains pending |
| RB-34 | Leave all students blank | Save blocked; no database write |
| RB-35 | Enter a mark above the test maximum | Save blocked with a clear message |
| RB-36 | Mark one or more students absent | Absent confirmation lists names and roll numbers |
| RB-37 | No absent students | Absent popup skipped |
| RB-38 | Cancel absent confirmation | No database write; all marks retained |
| RB-39 | Continue absent confirmation, then cancel final confirmation | No database write; all marks retained |
| RB-40 | Confirm submission | Test details and all student marks save atomically |
| RB-41 | Force database failure during save | Entire transaction rolls back; entries remain on screen |
| RB-42 | Tap Save repeatedly while request is pending | Only one submission is sent |
| RB-43 | Submit duplicate student roll numbers through API | Backend rejects request |
| RB-44 | Omit one eligible student through API | Backend rejects request |
| RB-45 | Include a student from another class/board/subject through API | Backend rejects request |
| RB-46 | Submit the same test code after a successful save | Duplicate test code rejected |
| RB-47 | Faculty ID is missing or invalid | Access denied; no data write |
| RB-48 | Load students, then attempt to change the code without using Change test code | Code stays read-only; Change test code clears the loaded list before a new code is entered |
| RB-49 | Enter Chapter as a positive number or `combined` (any capitalization) | Accepted and persisted; other text, zero and negative values are rejected |
| RB-50 | Enter Portions as descriptive text | Portions are saved to the test record and shown again when the test code is loaded |
| RB-51 | Open Regular Batch Enter Marks Test Code input | Test Code field has no placeholder text |
| RB-52 | Use a test code suffix after `C` that contains letters or mixed text and numbers | Valid non-empty suffix is accepted; Chapter field validation remains separate |

## Test Batch – subject, test code and registered students

| ID | Scenario | Expected result |
|---|---|---|
| TB-01 | Open Test Batch Enter Marks | Subject dropdown loads from posted, eligible tests |
| TB-02 | Select Mathematics | Only Mathematics test codes appear |
| TB-03 | Select Physics | Only Physics test codes appear |
| TB-04 | Change subject after selecting a test | Previous code, students and marks are cleared |
| TB-05 | Select a valid posted test code | Test details and registered students load |
| TB-06 | Test code is malformed or mismatches posted test details | Test is not offered or backend rejects it |
| TB-07 | Test has no registered students | Helpful no-registered-students message |
| TB-08 | Registration status is Cancelled | Student is excluded |
| TB-09 | Student belongs to another Test Series | Student is excluded |
| TB-10 | Student has the wrong subject | Student is excluded |
| TB-11 | Student subject is Both | Student is eligible for the selected subject |
| TB-12 | Student belongs to another class | Student is excluded |
| TB-13 | Student belongs to another board | Student is excluded |
| TB-14 | Posted test is Draft or Cancelled | Test is unavailable for marks entry |
| TB-15 | Manual marks entry is disabled | Test is unavailable for marks entry |
| TB-16 | Marks are already finalized | Test is unavailable for another submission |
| TB-17 | Faculty ID is missing or invalid | Access denied; no data write |

## Test Batch – marks input and submission

| ID | Scenario | Expected result |
|---|---|---|
| TB-18 | Enter 0 or a valid whole number | Accepted |
| TB-19 | Enter lowercase `a` | Automatically becomes `A` |
| TB-20 | Enter uppercase `A` | Accepted as absent |
| TB-21 | Enter invalid letters or special characters | Rejected |
| TB-22 | Enter negative or decimal marks | Rejected |
| TB-23 | Enter more than 100000 | Rejected |
| TB-24 | Enter marks above the posted test maximum | Save blocked |
| TB-25 | Leave some registered students blank and enter marks for only one student | One student’s marks can be submitted; blank students remain pending and do not block the submission |
| TB-26 | Mark absent students | Confirmation lists absent names and roll numbers |
| TB-27 | Cancel absent or final confirmation | No database write; entered marks retained |
| TB-28 | Submit marks for one or several selected/changed registered students | Only submitted student records save in one transaction; remaining registered students can be submitted later |
| TB-29 | Force a database failure mid-save | All inserted marks roll back |
| TB-30 | Submit only a subset of registered students through API | Backend accepts the subset if every submitted roll number is registered and unique; no omitted student is required |
| TB-31 | Include an unregistered student through API | Backend rejects request |
| TB-32 | Submit duplicate roll numbers through API | Backend rejects request |
| TB-33 | Submit marks a second time | Duplicate/finalized submission rejected |
| TB-34 | Tap Save repeatedly while request is pending | Only one submission is sent |
| TB-35 | All registered students have saved marks | Test marks status becomes finalized and success message appears |
| TB-36 | Submit one student whose mark is already saved without edit approval | Backend rejects overwrite; faculty must use the approved edit flow |
| TB-37 | Submit one new student while other registered students already have saved marks | New student’s mark saves; unrelated saved marks do not block it |
| TB-38 | Submit a roll number not registered for the selected test code | Backend rejects that record; no partial transaction is committed |
| TB-39 | Open Test Batch Enter Marks and inspect Board dropdown | Board options are fetched from distinct database board values; no hardcoded board list is used for this screen |
| TB-40 | Open Test Batch Enter Marks and inspect Class dropdown | Class options are fetched from distinct database class values; no hardcoded class list is used for this screen |
| TB-41 | Add a class or board value to the testing database and reload mark-entry options | The new value appears in the relevant dropdown without a code change |

## Error-message and resilience checks

- [ ] No raw HTTP status, SQL error, stack trace, exception text, or backend error code is shown in the APK.
- [ ] Duplicate Regular Batch test code shows the exact duplicate-code message.
- [ ] Network timeout shows a friendly connection message.
- [ ] Server or database failure says marks could not be saved and confirms entries are retained.
- [ ] Authorization failure uses a friendly access message.
- [ ] A retry after failure does not lose student input.
- [ ] Loading indicators stop after success or failure.
- [ ] No success message appears before the database transaction commits.

## Regression checks – must remain unchanged

- [ ] Regular Student login and dashboard.
- [ ] Test Batch login and dashboard.
- [ ] Regular Student marks viewing and history.
- [ ] Test Batch marks viewing and result display.
- [ ] Regular Student attendance.
- [ ] Test Batch attendance.
- [ ] Test Batch registration and one-test-per-day rule.
- [ ] Test Batch posting and test settings.
- [ ] Faculty navigation and access.
- [ ] Student profiles, notifications and unrelated APIs.
- [ ] Existing database records are not deleted or migrated unnecessarily.

## Build and approval gate

- [ ] `flutter analyze` passes.
- [ ] `flutter test` passes, including marks input formatter tests.
- [ ] Release APK builds using the test API/database only.
- [ ] Required test cases pass on device.
- [ ] Failed cases are fixed and rerun with relevant regression cases.
- [ ] Confirm no commits or deployment changes were made to `main` or production.
- [ ] Share test results and APK for owner review.
- [ ] Merge only after explicit approval.
