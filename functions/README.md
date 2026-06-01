Deployment instructions

1. Install dependencies and login to Firebase:

```bash
cd functions
npm install
npm install -g firebase-tools
firebase login
```

2. Initialize functions (if you haven't) or ensure the project matches your Firebase project:

```bash
firebase init functions
# when prompted, choose the existing Firebase project and JavaScript
```

3. Deploy the function:

```bash
firebase deploy --only functions:sendAllocationNotifications
```

4. After deployment you'll get an HTTPS URL. Copy it and set it in the Flutter app at:

`lib/services/notification_service.dart` -> `functionsUrl` constant.

5. To call the function manually for testing (replace URL):

```bash
curl -X POST 'https://us-central1-YOUR_PROJECT.cloudfunctions.net/sendAllocationNotifications' \
  -H 'Content-Type: application/json' \
  -d '{"kampanyeId":"<KAMPANYE_ID>","kampanyeJudul":"Judul"}'
```
