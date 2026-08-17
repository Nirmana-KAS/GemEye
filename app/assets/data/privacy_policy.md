# GemEye Privacy Policy

**Last updated: August 2026**

This Privacy Policy describes how GemEye ("the App", "we", "us", or "our") collects, uses, stores, and protects your information when you use the GemEye automated blue sapphire colour grading application.

By using GemEye, you agree to the collection and use of information in accordance with this policy.

---

## 1. Data Collection

We collect the following types of data:

- **Account Information:** Name, email address, and authentication credentials when you register or sign in via Google Sign-In or email/password.
- **Stone Images:** Photographs of gemstones captured through the app for colour grading analysis.
- **Grading Data:** Colour grade results, confidence scores, colour values (L\*a\*b\*, HSB), and associated metadata.
- **Calibration Data:** Colour Calibration Card (CCC) images and calibration parameters used to ensure device-independent colour accuracy.
- **Device Information:** Device model, operating system version, and camera specifications for calibration and diagnostic purposes.
- **Usage Data:** App usage patterns, feature interactions, and grading history for improving the user experience.

## 2. Data Usage

Your data is used exclusively for the following purposes:

- **Colour Grading Analysis:** Stone images are processed solely for the purpose of automated colour grading using our machine learning models. Images are analysed to extract colour features and determine the GEMCLOUD grade.
- **Calibration:** CCC card images are used to compute colour correction matrices for your specific device and lighting conditions.
- **Certificate Generation:** Grading results are used to generate digital grading certificates.
- **Service Improvement:** Aggregated, anonymised usage statistics may be used to improve the app's accuracy and user experience.
- **Account Management:** Account information is used to authenticate you and manage your grading history.

## 3. Data Storage

- **User Accounts and Grading Records:** Stored securely on **MongoDB Atlas** (cloud-hosted MongoDB) with encryption at rest and in transit (TLS 1.2+).
- **Stone Images:** Stored on **Amazon Web Services S3** (AWS S3) with server-side encryption (AES-256). Images are stored in private buckets accessible only through authenticated, time-limited presigned URLs.
- **Authentication Data:** Managed by **Firebase Authentication** with industry-standard security practices.
- **Local Data:** Sensitive local data (authentication tokens, calibration parameters) is stored using encrypted storage (flutter_secure_storage) on your device.

## 4. Data Sharing

We are committed to protecting your privacy:

- **Your stone images are never shared with third parties.**
- **Your data is never sold** to any third party, under any circumstances.
- **No advertising:** We do not use your data for advertising purposes.
- **No third-party analytics:** We do not share your data with third-party analytics providers.
- **Limited access:** Only authorised personnel involved in maintaining and improving the GemEye service have access to stored data, and only when necessary for technical support or service improvement.

## 5. Data Retention

- **Active Accounts:** Your data is retained for as long as your account is active.
- **Grading History:** Grading records and associated images are retained until you choose to delete them.
- **Deleted Items:** When you delete a grading record, the associated stone image is permanently removed from AWS S3 within 30 days.
- **Account Deletion:** Upon account deletion, all personal data, grading records, and stone images are permanently deleted within 30 days.

## 6. Data Deletion

You have full control over your data:

- **Delete Individual Records:** You can delete any grading record (including its stone image) from the Grading History screen at any time.
- **Delete All Data:** You can delete all your grading data from the Settings screen under "Delete All Grading Data".
- **Delete Account:** You can request full account deletion from the Settings screen under "Delete Account". This permanently removes your account, all grading records, all stone images, and all certificates.
- **Immediate Effect:** Deletion requests take effect immediately in the app. Backend cleanup (S3 image removal) completes within 30 days.

## 7. Image Ownership

- **You retain full ownership** of all stone images you capture using GemEye.
- We claim no intellectual property rights over your images.
- Images are stored solely for the purpose of providing grading services to you.
- You may export, share, or delete your images at any time.

## 8. AI Processing

- Stone images are processed by our **cloud-deployed AI models** (hosted on AWS Lambda) for the sole purpose of colour grading.
- Images are transmitted securely (HTTPS/TLS) to the processing endpoint.
- **Images are not stored beyond the grading request.** Once the colour grade is determined and the result is returned, the image data in the processing pipeline is discarded.
- The AI models do not learn from or retain individual images. Model training is performed separately using controlled datasets and does not use user-submitted images.
- Grad-CAM visualisations (attention maps) are generated during processing and returned with the grade result but are not stored on the server.

## 9. Security

We implement appropriate technical and organisational measures to protect your data:

- All data transmission uses HTTPS with TLS 1.2 or higher.
- Database access is restricted by IP whitelist and authentication.
- AWS resources are secured with IAM roles and least-privilege access policies.
- Sensitive local data is encrypted using platform-specific secure storage.
- We do not store passwords — authentication is handled by Firebase Authentication.

## 10. Children's Privacy

GemEye is not intended for use by children under the age of 16. We do not knowingly collect personal information from children under 16.

## 11. Changes to This Policy

We may update this Privacy Policy from time to time. Changes will be posted within the app, and the "Last updated" date will be revised accordingly. Continued use of the app after changes constitutes acceptance of the updated policy.

## 12. Contact

If you have any questions or concerns about this Privacy Policy or your data, please contact us:

- **Email:** support@gemeye.app
- **Developer:** Nirmana K.A.S.
- **Organisation:** Orava (Pvt) Ltd., Sri Lanka
