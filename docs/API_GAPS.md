# Backend gaps: what the app needs and how to build it

Checked against `Hostel-Management-Backend-Nodejs` at commit `0d28668` (5 Nov 2026), plus the
uncommitted edits listed in section 1. When an endpoint is missing, the data-source method throws
`ApiPendingException` (search the code for `TODO(api)`) and the screen shows "Coming soon".

## 1. Backend edits made for the app and for staging (uncommitted, please review)

### Bugs fixed

| Area | Bug | Fix |
| --- | --- | --- |
| Attendance | Check-ins were saved on the **UTC** date, and "marked today?" checked the UTC date. | Both use the IST calendar date (`currentDateForDb()` in `dates.utils.js`). |
| Attendance | The window checks in `markAttendance` were commented out, and the splash `canMarkAttendance` had a testing override. | Check-ins outside the window get `422` ("Attendance window not open yet" or "…closed"). `canMarkAttendance` is true only when the window is open, nothing is marked today, and a photo exists. |
| Attendance | A second check-in on the same day crashed with a 500 (unique constraint). | It returns `409` "Attendance is already marked for today", checked before the face match runs. |
| Attendance | If the face server was down or slow, the request hung or failed with a 500. | Timeouts (5 s health, 20 s verify). Any failure gives `503` "Face verification is unavailable right now". The URL is set by `FACE_VERIFICATION_URL`. |
| Auth | `change_password` compared bcrypt hashes for equality and saved an un-awaited hash. | Uses `bcrypt.compare` and awaits the hash. |
| Auth | Login and forgot password were case-sensitive on email. | Email lookups are case-insensitive, and new emails are saved in lowercase. |
| Auth | Forgot password told anyone whether an email had an account. | It always answers "If this email belongs to an active account, a password reset link has been sent". |
| Students | If the activation email failed, creating the student returned an error even though the student was saved. | The student is created and the response includes `activationEmailSent: false`. The app tells the admin to use Resend. |
| Students | Updating a student with their own email, contact or room failed with "already exists" or "room full". | Their own record and current room are excluded from those checks. |
| Students | Moving a student to their current room, or into a full room, wasn't handled correctly. | Same room gives `409`, and a full room is checked with `>=`. |
| Students | A `PENDING_ACTIVATION` student could be set to `ACTIVE` without setting a password. | That change gives `409`. |
| Students | The status response leaked the password hash. | It returns only `id`, `email` and `status`. |
| Leave | `reviewedAt` was never set. | It is set when a leave is approved or rejected. |
| Events | An event could end before it starts. | `422` "The event must end after it starts". |
| Hostel | The attendance window could close before it opens. | `422` when start ≥ end. (A window that crosses midnight isn't supported.) |
| Media | Any user could get upload or download URLs for any image. | Students can upload only attendance images, and download only event images and their own photo. |
| Errors | 500 responses leaked internal messages, and Prisma errors became 500s. | Unknown errors return a generic message (logged on the server). P2002 → `409`, P2025 → `404`. |
| CORS | Origins were hardcoded. | `CORS_ORIGINS` (comma-separated), with localhost as the default. |
| Rooms | `room.service.js` imported a Prisma runtime internal it didn't use. | Removed. |

### Attendance and face matching (6 Nov)

| Area | Change |
| --- | --- |
| Face server (`hostel-management-faceverification`) | The percentage is now **calibrated**: 65%+ trusted (green), 30–65% check (yellow), under 30% likely someone else (red). Before, it was cosine × 100, so genuine matches often showed 40–70%. Also fixed: RGB input, 5-point alignment, largest face used, flip averaging, parallel requests. See its README. |
| Face server | Accepts `reference_images` (recent trusted selfies) so a new beard, moustache or haircut doesn't drop the score. They can raise the score only a little above the registered-photo score. |
| `markAttendance` | Sends up to 3 selfies from the last 30 days that scored 80%+ as references. A selfie with no clear face or with someone else in it gets `422` (retake, nothing saved). An unusable registered photo gets `409` "Student's image has no clear face". Before, both were saved as 0%. |
| Attendance list | Face filter accepts `lt`/`gt` too. "Below 65%" uses `lt`, since 65 counts as trusted. The present list is ordered newest first, or lowest match first when filtering below a value; before, there was no order, so pages could repeat rows. |
| Attendance summary | The Present/Absent counts ignore the face and outside-hostel filters. Before, filtering "below 65%" made the Absent count jump. |

### Student photo check (6 Nov, later)

| Area | Change |
| --- | --- |
| Face server | New `POST /face/check`: one clear, sharp, well-lit, upright, front-facing face, big enough and inside the frame. It returns `issues` (e.g. `NO_FACE`, `BLURRY`, `TOO_DARK`, `NOT_FACING_CAMERA`, `FACE_TOO_SMALL`, `PHOTO_SIDEWAYS`), each an error or a warning, with a plain message. |
| Backend | New `POST /students/image_check` `{ studentImageKey }` (admin) returns `{ ok, status, message, issues }`. `createStudent` and a photo change in `updateStudentProfile` refuse a rejected photo (`422`). If the face server is down, the photo is accepted. |
| App | The student form uploads and checks the photo as soon as it's picked. It shows "Photo looks good", tips (warnings) or "This photo can't be used" with the reasons and a Retake button, and won't save a rejected photo. |
| Face server accuracy | Sideways/upside-down photos are turned upright (they used to score a genuine match at ~0%). Selfies far too dark, blurry, small or turned away get a retake (`LOW_QUALITY_CAPTURE`, 422) instead of a misleading score. 100% now needs cosine 0.80 (was 0.70), so good matches spread over 75–95% instead of many showing 100%. |

Distance: `calculateDistanceFromHostelInMeters` (haversine) is correct. It matches reference distances (Bengaluru–Chennai 290.2 km). It's the straight-line distance, so it's shorter than the road distance Google Maps shows.

### New behaviour

- **Student splash** (`GET /students/splash_screen`) also returns `attendanceWindowState`,
  `todayAttendance`, `hasProfilePhoto` and `approvedLeaveToday`.
- **Admin leave detail** (`GET /leave_applications/:id`) includes the student's details.
- **Mess bills**
  - Admins can create, edit and publish bills only for **this month and next month** (IST). Any
    other month gives `422`, and a second bill for the same month gives `409`.
  - The amount must be positive. The last date can't be in the past or before the bill's month.
  - `GET /mess_fee/mess_bill` is newest first. Each bill includes `canEdit`, `canPublish` and `canDelete`.
- **`GET /mess_fee/my_bills`** (STUDENT): published bills of the student's hostel, newest first,
  plus how to pay:

  ```json
  "data": {
    "bills": [{ "id": 4, "month": "NOVEMBER", "year": 2026, "amount": "3000", "lastDate": "2026-11-10T00:00:00.000Z", "status": "PUBLISHED", "paidAt": null }],
    "paymentInfo": {
      "onlinePaymentAvailable": false,
      "message": "Online mess fee payment will be available soon. For now, please visit the hostel office and pay there.",
      "officeHours": [
        { "shift": "SHIFT_1", "label": "Shift 1 students", "opensAt": "14:00", "closesAt": "16:00" },
        { "shift": "SHIFT_2", "label": "Shift 2 students", "opensAt": "09:00", "closesAt": "11:00" }
      ]
    }
  }
  ```

  The office hours are in `src/modules/mess-fees/mess-fee.constants.js`. `paidAt` stays `null`
  until payments are recorded (3.1).

### Staging checklist

- New optional env vars: `CORS_ORIGINS` and `FACE_VERIFICATION_URL` (see the new `.env.example`).
- The attendance window is now enforced. To test check-ins at any hour, set the window in
  Hostel settings (for example 00:00–23:59), then set the real times back.
- No schema changes and no migrations.

## 2. Already done in the backend (your commit `0d28668`), now used by the app

- `POST /auth/change_password`: wired to Change password, with an inline error for a wrong
  current password.
- `user.status`, `department` and `room` on the student list and detail: status badges,
  Pending-activation and Suspended notices.
- `id` and `studentImageKey` of students in a room: room detail rows show photos and open the student.
- `hostel.id` in the admin splash: Hostel settings loads directly.
- Student `id` on absent attendance rows: absent students open their page.

## 3. Not built yet (left for later)

### 3.1 Recording payments (admin)

`MessFeePayment` exists in the schema, but no API writes to it. Until it does, the app never shows
a bill as paid or unpaid.

- `POST /mess_fee/mess_bill/:id/payments` `{ studentProfileId }` marks a cash payment as received.
- `GET /mess_fee/mess_bill/:id/payments?status=paid|unpaid` lists who has and hasn't paid.
- Then add `_count: { select: { messFeePayments: true } }` to `GET /mess_fee/mess_bill`, so the
  published bill card can show "142 paid · 106 yet to pay".

### 3.2 Online payment

- A payment gateway (for example Razorpay):
  - `POST /mess_fee/mess_bill/:id/pay` creates an order.
  - A webhook verifies the payment and creates the `MessFeePayment` row.
- Then set `onlinePaymentAvailable: true` and update the `TODO(api)` in
  `lib/features/student/fees/presentation/fees_screen.dart`.

### 3.3 Push notifications

The announcement form saves `pushNotification`, but nothing is sent yet.

- Add `firebase_messaging` to the app.
- Add `POST /devices { fcmToken, platform }` to store device tokens per user.
- When an announcement is created with `pushNotification: true`, send it to that hostel's
  students with `firebase-admin`.

## 4. Smaller backend items still open

1. **Optional links can't be cleared.** The announcement `linkUrl` and event `eventLink` schemas
   reject `null` and `""`, so a saved link can only be replaced. Use `.nullable()`.
2. **The events list ignores `page`/`pageSize`.** The app asks for 100 and doesn't page.
3. **Change password keeps other sessions signed in.** Optionally revoke the user's other
   `AuthSession` rows after a change.
4. **Attendance windows can't cross midnight** (for example 23:00–01:00).
5. **Face match percentages saved before 6 Nov** are on the old scale (cosine × 100) and read lower than new ones.

## 5. Email links into the app

The emails link to `ourhostel://setup-password?token=…&mode=welcome|reset`. The app registers the
`ourhostel` scheme on Android and iOS and opens the Set password screen.

Some email apps (Gmail web, for example) don't make custom-scheme links tappable. For production,
switch to https links:

1. Use an https link in the emails, for example `https://ourhostel.in/setup-password?token=…&mode=welcome`.
   The router already accepts the `/setup-password` path.
2. Android App Links:
   - Host `/.well-known/assetlinks.json` (package `in.ourhostel.our_hostel`).
   - Add an `intent-filter` with `android:autoVerify="true"` for that host to `AndroidManifest.xml`.
3. iOS Universal Links:
   - Host `apple-app-site-association` (bundle `in.ourhostel.ourHostel`).
   - Add Associated Domains (`applinks:ourhostel.in`).
