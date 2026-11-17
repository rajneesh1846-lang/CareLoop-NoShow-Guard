# CareLoop Clinics — No-Show Guard

**GitHub Repository:** https://github.com/rajneesh1846-lang/CareLoop-NoShow-Guard

## About the Project

Missing a doctor's appointment may seem like a small issue, but for a clinic, it means wasted time, an empty appointment slot, and another patient potentially missing the chance to get treatment.

In this project, I worked with appointment data from eight outpatient clinics across six Indian cities. My aim was to understand which patients were more likely to miss their appointments, what factors were associated with no-shows, and how clinics could reduce them.

I divided the project into four parts: cleaning the data with Python, analysing patterns using SQL, building a machine-learning model, and using Gemini AI to understand patient follow-up notes.

The main question I wanted to answer was:

**Which appointments are most likely to be missed, why do patients miss them, and what should CareLoop do first?**

## Project Summary

Here's a quick overview of what I found in each part:

1. **Python:** I cleaned 1,020 appointment records and ended up with 990 usable appointments. Out of these, 218 were no-shows, giving an overall no-show rate of 22.0%.
2. **SQL:** Patients who booked more than 30 days in advance had a 60.5% no-show rate, compared with just 16.2% for patients who booked within seven days.
3. **Machine Learning:** Logistic Regression gave the best cross-validation result, with a ROC-AUC of 0.7737. Using a threshold of 0.35, the final model achieved 0.789 ROC-AUC on the test data and flagged 49 appointments.
4. **Generative AI:** I analysed 10 patient follow-up notes using Gemini. Nine received valid classifications, while one blank note was skipped. Five of these appointments had no reminder recorded.

## Part 1 — Data Cleaning with Python

The first step was getting the appointment data into a usable format.

The original dataset had 1,020 rows, but it wasn't completely clean. There were duplicate records, missing values, inconsistent booking-channel names, invalid ages, and unusually high fees.

I started by reading the CSV using Python's built-in `csv` module and handling rows that couldn't be converted into the required data types. After that, I used pandas and NumPy for the main cleaning process.

Some of the changes included:

- Removing 20 duplicate records.
- Standardising booking channels into App, Phone, and Walk-In.
- Converting appointment and booking dates into the proper format.
- Removing records with missing or invalid appointment dates or missing status values.
- Replacing five invalid ages and filling missing ages and distances with median values.
- Capping 26 extreme distance values and three unusually high fee values.

After cleaning, I had **990 appointments with 16 columns and no missing values** in the final exported dataset.

I also created two useful columns:

- `lead_days`: How many days in advance the appointment was booked.
- `no_show`: Whether the patient missed the appointment (1) or attended (0).

I used the Open-Meteo API to collect temperature information for all eight clinics and saved this separately as `clinics_enriched.csv`.

The cleaned data became the starting point for the SQL analysis and machine-learning model.

## Part 2 — SQL Analysis

Once the data was cleaned, I loaded it into SQLiteOnline.

I created separate tables for clinics and appointments, connected them using `clinic_id`, and verified that the database contained 8 clinics, 990 appointments, and 218 no-shows.

I also tested the primary-key constraint by trying to insert an appointment ID that already existed. SQLite rejected it, which confirmed that duplicate appointment IDs were not allowed.

### Which clinics had the most no-shows?

The results showed noticeable differences between clinics.

| Clinic | Appointments | No-shows | No-show rate |
|---|---:|---:|---:|
| Gomti Nagar Care Point | 90 | 30 | 33.3% |
| Hadapsar Care Centre | 143 | 39 | 27.3% |
| Malviya Nagar Clinic | 142 | 38 | 26.8% |
| Kothrud Family Clinic | 160 | 36 | 22.5% |

Gomti Nagar Care Point in Lucknow had the highest percentage of missed appointments, at 33.3%. However, it had only 90 bookings, so it didn't appear in the separate analysis that required at least 95 appointments.

Hadapsar Care Centre was another clinic that stood out. It had 39 no-shows out of 143 bookings, making it a useful place to investigate missed appointments.

### Does booking early make a difference?

This was one of the most interesting findings from the SQL analysis.

I grouped appointments based on how far in advance they were booked.

| Days booked in advance | Appointments | No-shows | No-show rate |
|---|---:|---:|---:|
| 1–7 days | 390 | 63 | 16.2% |
| 8–14 days | 304 | 53 | 17.4% |
| 15–30 days | 253 | 76 | 30.0% |
| 31+ days | 43 | 26 | 60.5% |

The difference was quite large.

Only 16.2% of appointments booked within a week were missed, but the rate increased to 60.5% for appointments booked more than a month in advance.

This suggests that patients who book far ahead might need additional reminders or confirmation calls as the appointment approaches. It doesn't necessarily mean booking early causes no-shows, but the relationship is worth paying attention to.

### Monthly no-show trends

I also checked whether missed appointments were increasing or decreasing over time.

| Month (2025) | No-show rate |
|---|---:|
| January | 24.8% |
| February | 20.5% |
| March | 20.4% |
| April | 20.9% |
| May | 23.7% |
| June | 21.2% |

January had the highest monthly rate at 24.8%, while March had the lowest at 20.4%.

May also showed an increase of 2.8 percentage points compared with April.

There wasn't a consistent increase or decrease across all six months. The rates fluctuated, so a longer period of data would be helpful before making conclusions about seasonal patterns.

## Part 3 — Predicting No-Shows with Machine Learning

After identifying patterns with SQL, I wanted to see whether I could predict which appointments were more likely to be missed.

I used features such as patient age, distance from the clinic, consultation fee, booking lead time, previous no-shows, reminder status, booking channel, and visit type.

After encoding categorical variables, the dataset had 11 model features.

I split the data into:

- **792 appointments for training**
- **198 appointments for testing**

I used `random_state=42` to keep the results reproducible.

### Starting with a baseline

Before training any models, I calculated what would happen if I simply predicted that every patient would attend.

That approach gave an accuracy of **75.25%**.

Although this sounds reasonably good, it would fail to identify every patient who actually missed an appointment.

This made it clear that accuracy alone wasn't enough. Recall, precision, and ROC-AUC were also important.

### Models I tested

I experimented with three main types of models:

1. Logistic Regression
2. Decision Tree
3. Random Forest

I also tested a depth-limited decision tree and tuned the Random Forest using GridSearchCV.

The unrestricted decision tree achieved 100% training accuracy, but its test accuracy was only 67.2%. This was a clear example of overfitting.

Restricting the tree to a maximum depth of three helped reduce that problem.

### Choosing the final model

Instead of selecting a model based on the test results, I compared their ROC-AUC scores using five-fold cross-validation on the training data.

| Model | Cross-validation ROC-AUC |
|---|---:|
| Logistic Regression | 0.7737 |
| Tuned Random Forest | 0.7673 |
| Random Forest | 0.7466 |
| Depth-3 Decision Tree | 0.6784 |

**Logistic Regression performed the best**, so I selected it as the final model.

The tuned Random Forest was close, but Logistic Regression had the slightly better cross-validation score.

### Choosing the prediction threshold

A model normally classifies an appointment as a likely no-show when its predicted probability is at least 0.50.

However, I also tested a lower threshold of 0.35 using out-of-fold predictions from the training data.

| Threshold | Precision | Recall | F1 score | Appointments flagged |
|---|---:|---:|---:|---:|
| 0.50 | 0.575 | 0.249 | 0.347 | 73 |
| 0.35 | 0.513 | 0.467 | 0.489 | 154 |

The 0.35 threshold gave better recall and a higher F1 score.

I chose this threshold because, from a clinic's point of view, missing a patient who is likely to skip an appointment can mean losing an entire consultation slot. Making one additional confirmation call has a much smaller operational cost.

### Final model performance

After selecting the model and threshold using training data, I evaluated it on the test set.

| Metric | Final result |
|---|---:|
| Model | Logistic Regression |
| Threshold | 0.35 |
| Test ROC-AUC | 0.789 |
| Precision | 0.571 |
| Recall | 0.571 |
| Test appointments | 198 |
| Appointments flagged | 49 |

The model identified 49 appointments for potential follow-up.

This doesn't mean the model is perfect. Its precision and recall show that some flagged patients would still attend and some actual no-shows would be missed.

However, it provides a starting point for helping clinic staff decide which appointments to confirm first.

In a real clinic, I would adjust the threshold based on how many calls the front desk can realistically handle each evening.

## Part 4 — Understanding Patient Reasons with Gemini AI

The machine-learning model helped identify appointments that might be missed, but it didn't explain the reasons behind individual no-shows.

For that, I used Gemini AI to analyse patient follow-up notes.

I worked with the first 10 notes from the dataset and asked Gemini to classify each note into one of six categories:

- `forgot_or_no_reminder`
- `distance_or_transport`
- `cost_or_fee`
- `illness_or_emergency`
- `work_or_schedule`
- `other`

I used a structured JSON response containing the root cause, confidence score, short summary, and recommended action.

I also used Pydantic to validate the responses and check that the root causes matched the allowed categories.

### Results from the notes

Out of the 10 notes, nine received valid AI classifications. One note, N004, was blank and was skipped without making an API request.

After merging the notes with the appointment data, I compared the reasons with whether a reminder had been sent.

| Reason | Reminder not sent | Reminder sent |
|---|---:|---:|
| Forgot / no reminder | 2 | 0 |
| Distance / transport | 1 | 1 |
| Work / schedule | 1 | 1 |
| Cost / fee | 0 | 1 |
| Illness / emergency | 0 | 1 |
| Other | 1 | 1 |

One finding stood out: **both notes classified as forgetting or not receiving a reminder belonged to appointments where `reminder_sent` was No**.

Five of the ten appointments had no reminder recorded.

This made reminder delivery an area worth investigating, although ten notes are not enough to draw conclusions about every patient across all clinics.

### Testing the validation

I deliberately tested two incorrect responses:

- One with a confidence score of 1.7, above the permitted maximum of 1.
- Another with the `recommended_action` field missing.

Pydantic rejected both as expected.

This was useful because AI responses should be checked before being used in reports or decision-making.

### Comparing two prompts

I also compared a simple prompt against a more detailed CRAFT prompt.

The simple prompt only asked Gemini to classify the note. The CRAFT version provided the context, role, task, expected tone, allowed categories, and JSON format.

I tested both on N007 and N009.

| Note | Basic prompt (V1) | CRAFT prompt (V2) |
|---|---|---|
| N007 | Free-form reason outside the allowed categories | `forgot_or_no_reminder` |
| N009 | Free-form reason outside the allowed categories | `other` |

The basic prompt returned no permitted category labels in these two tests, while the CRAFT prompt returned valid categories for both.

Based on this small comparison, I would prefer the CRAFT prompt for this task because it gives the model clearer instructions and produces classifications that fit the required format.

It is still a very small test, so I wouldn't claim that the detailed prompt is always more accurate in every situation.

During the analysis, I also encountered a temporary Gemini API error (HTTP 503) while processing N010. I retried that note successfully. The API-call count needs to include failed attempts as well as successful requests.

## My Recommendation for CareLoop Clinics

Based on the overall findings, I think CareLoop should start by improving appointment reminders and introducing confirmation calls for patients with a higher predicted risk of not attending.

There are a few reasons for this recommendation.

First, **218 out of 990 appointments were missed**, which means roughly one in five bookings resulted in a no-show.

Second, appointments booked more than 30 days ahead had a **60.5% no-show rate**, compared with 16.2% for bookings made within seven days. This makes long booking lead times an important factor to consider.

Third, certain clinics had higher rates than others. Gomti Nagar Care Point recorded 33.3% no-shows across 90 bookings, while Hadapsar Care Centre had 39 missed appointments out of 143 bookings.

Finally, the follow-up notes showed that five of the ten appointments had no reminder recorded, including both cases classified as forgetting or not receiving a reminder.

My suggestion would be to start with a small pilot rather than introduce the system across all clinics immediately.

The front desk could use the model's risk scores to identify appointments requiring confirmation, give more attention to patients who booked far in advance or missed visits previously, and check whether reminders are being delivered properly.

Over a few weeks, the clinics could track how many calls were made, how many patients confirmed their visits, and whether the number of empty appointment slots decreased.

If the pilot gives useful results, CareLoop could gradually expand it to other clinics.

## Limitations

There are several things I would improve before using this system in a real healthcare setting.

**1. Limited patient notes**

Only ten follow-up notes were analysed. They helped illustrate possible reasons for missed appointments, but they cannot represent the reasons across all eight clinics.

**2. Data preparation before splitting**

Some cleaning statistics, such as medians and outlier limits, were calculated using the complete cleaned dataset before the train/test split. For a production model, these should be calculated using training data only.

**3. Repeat patients in training and testing**

The same patient may have more than one appointment. Because I used a random split, appointments from the same patient could appear in both sets, potentially making the test performance look better than it would on completely new patients.

**4. Random split instead of time-based testing**

In a real setting, the model would be trained on previous appointments and used to predict future ones. Testing on later dates would provide a more realistic assessment.

**5. Association is not causation**

The data suggests that reminders and shorter booking lead times are associated with fewer no-shows, but this does not prove they directly cause better attendance.

**6. Practical limits on follow-up calls**

The 0.35 threshold was selected based on F1 score. A real clinic would also need to consider staffing, call volume, and the cost of empty appointment slots before deciding how many patients to contact.

## Project Files

All code, queries, and generated datasets are included in this repository.

| File | Description |
|---|---|
| `data/appointments.csv` | Original appointment data |
| `data/clinics.csv` | Original clinic details |
| `data/followup_notes.csv` | Original patient follow-up notes |
| `01_ingest_clean.ipynb` | Python data cleaning, validation, feature creation, and API enrichment |
| `rejected_rows.json` | Records rejected during the initial CSV parsing |
| `appointments_clean.csv` | Cleaned appointment data containing 990 rows |
| `clinics_enriched.csv` | Clinic data with temperature information from Open-Meteo |
| `load_data.sql` | SQL statements for loading the clinic and appointment tables |
| `02_queries.sql` | SQL queries used for analysing no-show patterns |
| `03_model.ipynb` | Machine-learning training, comparisons, tuning, and evaluation |
| `test_risk_scores.csv` | Risk predictions for the 198 test appointments |
| `04_genai.ipynb` | Gemini note analysis, JSON schema, validation, and prompt comparison |
| `notes_analysed.csv` | Results of the first ten patient follow-up notes |

## How to Run the Project

The project was developed using Google Colab and SQLiteOnline.

To reproduce the analysis:

1. Run `01_ingest_clean.ipynb` using the original datasets in the `data` folder. This creates the cleaned appointments data and clinic enrichment files.
2. Create the clinic and appointment tables in SQLiteOnline, load the records using `load_data.sql`, and run the analysis queries from `02_queries.sql`.
3. Run `03_model.ipynb` using `appointments_clean.csv` to train and compare the models and generate the risk scores.
4. Run `04_genai.ipynb` using the follow-up notes dataset and a Gemini API key entered securely at runtime.

The Open-Meteo temperature readings can change depending on when the notebook is run. Gemini's classifications may also vary, even with the same prompt.

For the Gemini data, original API response text should be captured directly from `response.text` when available. Some earlier responses in this project were reconstructed from parsed JSON, so those records should not be treated as exact copies of the original reply.

## What I Learned

This project helped me understand how different tools can be used together to solve one business problem.

Python helped me turn messy booking records into usable data. SQL made it easier to identify patterns across clinics and booking periods. Machine learning showed how those patterns could be used to estimate the risk of a missed appointment. Gemini helped convert unstructured patient notes into categories that could be compared with appointment information.

One of my biggest takeaways was that getting a good model score is only part of the work. The predictions also need to be useful for the people acting on them.

For CareLoop, the real value would come from helping the front desk use its limited time more effectively and reducing the number of appointment slots that go unused.

The model and AI classifications are starting points, not final decisions. I would want to test the recommendations with real clinic staff and measure whether they actually improve attendance before using the system more widely.
