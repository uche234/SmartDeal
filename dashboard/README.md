# SmartDeal Dashboard

This simple web page provides a lightweight interface for reviewing smart deals
for a business. It fetches the document under `/smartDeals/{businessId}` and
lists each deal with options to approve, dismiss or edit the description.

The page uses the Firebase JavaScript SDK from a CDN so no build step is
required. Update the `firebaseConfig` object in `index.html` with your Firebase
project configuration and open the file in a browser.

## Features

* Load deals for a given business ID
* Edit the description of a deal and save it back to Firestore
* Approve a deal – marks it as approved and copies it to
  `businesses/{businessId}/activeDeal`
* Dismiss a deal – marks it as dismissed

Because the dashboard writes directly to Firestore, make sure your Firestore
rules allow the authenticated user to access these paths.
