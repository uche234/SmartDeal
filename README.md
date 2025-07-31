# SmartDeal

This repository contains the iOS client and Firebase Cloud Functions for the SmartDeal project.

## Deploying Firebase Functions

The Firebase functions are located in the `functions/` directory. To deploy only the functions run:

```bash
firebase deploy --only functions
```

Ensure that you have initialized Firebase for this project and are logged in using the Firebase CLI before running the deployment command.
