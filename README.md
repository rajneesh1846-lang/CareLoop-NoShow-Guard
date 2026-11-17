CareLoop Clinics — No-Show Guard
Public GitHub repository: https://github.com/rajneesh1846-lang/CareLoop-NoShow-Guard
Business question
Which appointments are most likely to be missed, why do patients miss them, and what should CareLoop do first?

This end-to-end project cleans booking data from eight outpatient clinics, analyses appointment no-shows with SQL, builds an evening-before risk model, and classifies patient follow-up notes using Gemini with structured-response validation.
Four-line project summary
1. Part 1 — Python: Cleaned 990 appointments from 1,020 raw rows; 218 were no-shows (22.0%).
2. Part 2 — SQL: Appointments booked 31+ days ahead had a 60.5% no-show rate versus 16.2% for those booked 1–7 days ahead.
3. Part 3 — Machine learning: Selected logistic regression using training cross-validation (CV ROC-AUC 0.7737); the 0.35 threshold produced 0.789 test ROC-AUC, 0.571 precision, 0.571 recall, and 49 flagged appointments in the 198-row test set.
4. Part 4 — GenAI: Analysed 10 follow-up notes (9 valid AI classifications, 1 blank note skipped); 5/10 appointments had no reminder, including both classified forgot_or_no_reminder.
Recommended action
CareLoop should start a targeted evening-before confirmation-call pilot for appointments with high predicted risk, prioritising long lead times and previous missed visits, while checking why scheduled reminders were not sent. In the cleaned data, 218 of 990 appointments were missed (22.0%). The no-show rate rose from 16.2% for bookings made 1–7 days ahead to 60.5% for bookings made 31+ days ahead. Gomti Nagar Care Point had the highest observed clinic rate (33.3%, 90 bookings), while Hadapsar Care Centre had 39 missed visits out of 143 appointments (27.3%). Among the 10 illustrative follow-up notes, 5 related to bookings with no reminder, and both notes labelled forgot_or_no_reminder had reminder_sent = No. Start by validating reminder delivery, calling the highest-risk bookings within staff capacity, and monitoring confirmed attendance, call volume, and unused slots before scaling.
Model choice and operating threshold
The model predicts the probability of a no-show on the evening before the appointment, after reminders have been sent or skipped. The features are age, distance, fee, lead time, previous no-shows, whether a reminder was sent, booking channel, and visit type (11 columns after one-hot encoding). IDs, clinic, gender, dates, and status were not used as predictors. The dataset was split 792 training / 198 test appointments using test_size=0.2, random_state=42, without reshuffling the cleaned CSV. Always predicting attendance would yield 0.7525 accuracy on the test set.

Model selection used 5-fold ROC-AUC on training data only:
Candidate	Training CV ROC-AUC
Logistic regression (scaling within each fold)	0.7737
Tuned random forest (200 trees, max depth 3)	0.7673
Random forest (100 trees)	0.7466
Decision tree (max depth 3)	0.6784


The logistic-regression model won by training cross-validation, not by consulting test-set performance. Out-of-fold training probabilities were then used to compare thresholds:
Threshold	Precision	Recall	F1	Training bookings flagged
0.50	0.575	0.249	0.347	73
0.35	0.513	0.467	0.489	154


The 0.35 threshold had the higher F1 and better recall. In the single final test evaluation, it yielded precision 0.571, recall 0.571, ROC-AUC 0.789, and 49 flagged appointments. In practice, a clinic should set its contact threshold according to evening call capacity and the cost of an empty doctor slot relative to an unnecessary call.
SQL findings
- Clinic-level variation: Gomti Nagar Care Point (Lucknow) had 33.3% no-shows but only 90 bookings; it was therefore excluded from the ≥95-booking comparison. Among clinics meeting that threshold, Hadapsar Care Centre (Pune) had 27.3% (39/143) and Malviya Nagar Clinic (Jaipur) had 26.8% (38/142).
- Lead-time bands: 1–7 days 63/390 = 16.2%; 8–14 days 53/304 = 17.4%; 15–30 days 76/253 = 30.0%; 31+ days 26/43 = 60.5%.
- Monthly changes: January 24.8%, February 20.5%, March 20.4%, April 20.9%, May 23.7%, and June 21.2%. May rose 2.8 percentage points relative to April.
- Database checks: 8 clinics, 990 appointments, 218 no-shows. A duplicate appointment_id='A0001' insert generated the expected unique-constraint error.
GenAI review and prompt comparison
The first 10 call-centre notes were classified into six permitted categories: forgot_or_no_reminder, distance_or_transport, cost_or_fee, illness_or_emergency, work_or_schedule, and other. Pydantic rejects missing required fields and confidence outside the interval 0–1; note N004 was blank and therefore skipped without an API request.
Root cause	Reminder No	Reminder Yes	Total
forgot_or_no_reminder	2	0	2
distance_or_transport	1	1	2
work_or_schedule	1	1	2
cost_or_fee	0	1	1
illness_or_emergency	0	1	1
other	1	1	2
Total	5	5	10


In a four-call prompt comparison, the basic V1 prompt returned 0/2 allowed labels: it generated free-form phrases for N007 and N009. The CRAFT V2 prompt returned 2/2 allowed labels (forgot_or_no_reminder and other). This supports V2 for controlled-format extraction, but a two-note comparison does not establish general accuracy. The run included an HTTP 503 API error and a later successful retry for N010; the API-call tally must include both failed and successful attempts.
Limitations
1. Small, illustrative note sample: Only 10 notes were examined, so reason counts cannot estimate real clinic-wide causes or prevalence.
2. Data leakage in preprocessing: Task 1.3 cleaning medians, quartiles, and outlier caps were calculated across all 990 rows before splitting; a production pipeline should estimate them on training data only.
3. Potential patient overlap: A random split can place bookings for the same patient in both training and test sets, overstating prospective performance.
4. Random rather than chronological evaluation: A real deployment should train on historical appointments and validate against future dates, ideally including new patients and clinics.
5. Observational data: Association of reminders or lead time with no-shows does not show causality. Clinic comparisons are also affected by differing sample sizes.
6. Operational threshold: The chosen 0.35 threshold optimised training F1 among two candidates; deployment needs call-capacity and cost-based calibration.
Files and reproducibility
File	Purpose
data/appointments.csv	Original appointment export (unchanged)
data/clinics.csv	Original clinic master (unchanged)
data/followup_notes.csv	Original patient follow-up notes (unchanged)
01_ingest_clean.ipynb	CSV ingest, data cleaning, NumPy features, live clinic temperature enrichment and SQL export
rejected_rows.json	Rows rejected during the standard-library CSV parsing exercise
appointments_clean.csv	Cleaned 990-row, 16-column appointment table
clinics_enriched.csv	Eight clinics with Open-Meteo first-hour temperature readings
load_data.sql	Eight clinic inserts followed by 990 appointment inserts
02_queries.sql	SQLite-compatible schema, verification, clinic, lead-time, monthly, and rank queries
03_model.ipynb	Baseline, logistic regression, trees, forest, training CV, threshold selection and final test
test_risk_scores.csv	198 test appointment IDs, outcomes, risk probabilities and risk flags
04_genai.ipynb	Gemini JSON schema, Pydantic checks, first-ten-note extraction and prompt comparison
notes_analysed.csv	10 note classifications, validations and original raw replies where captured


Run sequence: In Google Colab, run 01_ingest_clean.ipynb on the original data, producing the cleaned outputs. Create the two SQLite tables and execute load_data.sql, then use 02_queries.sql for analysis. Run 03_model.ipynb on appointments_clean.csv, preserving the sorted row order. Finally, run 04_genai.ipynb on followup_notes.csv and merge the first ten extracted notes with appointments_clean.csv. Temperature data from Open-Meteo changes with the execution date. The Gemini API needs a separately provided key at run time and may return slightly different classifications or experience transient rate limits.

Security and integrity: Never commit API keys or notebook outputs containing secrets. Before uploading, search the entire Gemini notebook for key fragments. Any source response stored in raw_response should be preserved verbatim from response.text; a JSON reserialization is not byte-for-byte equivalent. Do not fabricate unavailable historical raw text. Verify this field before final submission and document any unrecoverable earlier replies honestly.
