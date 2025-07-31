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

## Firestore Rules

Security rules for Firestore reside in `firestore.rules`. After updating the rules, deploy them with:

```bash
firebase deploy --only firestore:rules
```

Customers now have an `availableDeals` subcollection which restricts access so a user can only read or write their own deals:

```
match /Customers/{userId}/availableDeals/{docId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

## Packaging a Release

To bundle the cloud functions, iOS source and any available PDF documentation into a single archive run:

```bash
bash scripts/package_release.sh
```

The script produces `SmartDeal_release.zip` in the repository root containing the `functions/`, `Application/`, `Controllers/`, `Common/` and `Resources/` directories along with any `*.pdf` files it finds.

## Tests

There are currently no automated tests for the Firebase functions. Running `npm test` inside the `functions/` directory prints a simple message so continuous integration tools don't fail.

## Evaluating Smart Deals

The `functions/index.js` file exposes a callable Cloud Function named
`evaluateRules` which checks a list of rule objects against provided business
data. The evaluation logic relies on a set of **trigger handlers** located in
`functions/triggerHandlers.js`.

### Available Trigger Handlers

| Trigger Type      | Description                                                                                                              |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------ |
| `public_holiday`  | Triggered when `businessData.publicHolidays` includes today's date or `businessData.isPublicHoliday` is `true`.           |
| `weather_cold`    | Fires when `businessData.temperature` is less than or equal to the rule's `threshold` value.                              |
| `news_keyword`    | Looks for `rule.keyword` inside the array `businessData.newsHeadlines`.                                                   |
| `surplus_stock`   | Checks if `businessData.stock` is greater than the rule `threshold`.                                                      |
| `expiration_soon` | Triggered when `businessData.expirationDate` is within `threshold` days from today.                                       |
| `low_sales`       | Fires when `businessData.sales` is below the rule `threshold`.                                                            |
| `birthday`        | Evaluates to `true` if today's date matches `businessData.birthday`.                                                      |

### Example Usage

Call the `evaluateRules` function from your client with a payload similar to the
following to test the rule system:

```json
{
  "rules": [
    { "documentId": "rule1", "triggerType": "weather_cold", "threshold": 5 },
    { "documentId": "rule2", "triggerType": "surplus_stock", "threshold": 50 }
  ],
  "businessData": {
    "temperature": 3,
    "stock": 80
  }
}
```

The function responds with a list of results showing whether each rule was
triggered based on the provided business data.

## EPOS Provider Configuration

SmartDeal integrates with multiple EPOS systems through adapter modules. Each
business stores credentials in the Firestore document:

```
businesses/{businessId}/settings/eposConfig
```

The configuration object must contain at least a `provider` field specifying one
of the supported providers (`square`, `lightspeed`, `clover`, `toast`,
`shopify`, `vend`, `eposnow`). The remaining fields depend on the provider but
typically include:

- `apiKey` or `accessToken` – authentication token issued by the EPOS provider
- `storeId` or `locationId` – identifier for the store or location
- `merchantId` – merchant account identifier if required

Adapters read these values via `adapter.config` inside Cloud Functions. Update
the `eposConfig` document with the required keys for your provider before using
any EPOS features.

### Provider Specific Fields

- **Square**: `apiKey` (Square access token), `locationId`
- **Lightspeed**: `apiKey` (OAuth token), `accountId`
- **Clover**: `apiKey`, `merchantId`
- **Toast**: `apiKey`, `restaurantId`
- **Shopify**: `apiKey` (private app token), `shop` (e.g. `myshop.myshopify.com`)
- **Vend**: `apiKey`, `outletId`
- **EposNow**: `apiKey`, `businessId`
