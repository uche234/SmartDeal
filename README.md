# SmartDeal

This repository contains the iOS client and Firebase Cloud Functions for the SmartDeal project.

See [SmartDealArchitecture.pdf](SmartDealArchitecture.pdf) for an overview of the Firestore collections, Cloud Functions and interfaces.

## Deploying Firebase Functions

The Firebase functions are located in the `functions/` directory. To deploy only the functions run:

```bash
firebase deploy --only functions
```

Ensure that you have initialized Firebase for this project and are logged in using the Firebase CLI before running the deployment command.

## Firestore Indexes

The project defines Firestore composite indexes in `firestore.indexes.json`. To deploy the indexes along with rules and functions run:

```bash
firebase deploy --only firestore:indexes
```

This will create the index on `users.businessId` required for querying users by business.

## Packaging a Release

To bundle the cloud functions, iOS source and any available PDF documentation into a single archive run:

```bash
bash scripts/package_release.sh
```

The script produces `SmartDeal_release.zip` in the repository root containing the `functions/`, `Application/`, `Controllers/`, `Common/` and `Resources/` directories along with any `*.pdf` files it finds.
