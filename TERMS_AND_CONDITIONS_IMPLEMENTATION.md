# Terms and Conditions Implementation

## Overview
This implementation adds a terms and conditions popup check that validates user data for `policy_accept`, calls an API to get policy information, and shows exceptions based on the response.

## Components

### 1. UserModel Updates
- Added `policyAccept` field to track terms and conditions acceptance
- Updated `fromJson` and `toJson` methods to handle the new field

### 2. Terms and Conditions Popup (`lib/widgets/terms_conditions_popup.dart`)
- Displays static terms and conditions content
- Allows users to accept terms with a checkbox
- Calls API only when user accepts terms
- Handles loading states and error scenarios
- Prevents proceeding without acceptance

### 3. API Service (`lib/services/api_service.dart`)
- `updatePolicyAcceptance(bool accepted)`: Updates user's policy acceptance
- `hasAcceptedPolicy()`: Checks if user has already accepted terms

### 4. Auth Bloc Updates
- Added `AcceptPolicyRequested` event
- Added `PolicyAccepted` state
- Added `_acceptPolicy()` handler method

### 5. Start Page Integration
- Checks `policy_accept` field when start page loads
- Shows terms popup if `policy_accept` is null or false
- Only allows navigation to skin analysis after terms acceptance
- Handles errors and shows appropriate messages

## Flow

1. **Start Page Load**: When the start page loads, it checks user data for `policy_accept` field
2. **Static Popup Display**: If `policy_accept` is null/false, shows terms and conditions popup with static content
3. **User Acceptance**: User must check the acceptance checkbox to proceed
4. **API Call**: When accepted, calls API to update user's policy acceptance
5. **Local Update**: Updates local user data with acceptance status
6. **Continue Flow**: User can now navigate to skin analysis

## API Endpoints

### Update Policy Acceptance
```
POST /api/user/accept-policy
Headers: Authorization: Bearer {token}
Body: { "policy_accept": true/false }
Response: { "success": true, "message": "Policy updated" }
```

## Error Handling

- **API Errors**: Shows error messages in popup with retry option
- **Network Errors**: Displays user-friendly error messages
- **Authentication Errors**: Handles cases where user is not logged in
- **Critical Errors**: Shows snackbar notifications for critical issues

## Usage

The terms and conditions check is automatically integrated into the `StartPage`. When users navigate to the start page, the system will:

1. Check if the user has accepted terms and conditions
2. Show the popup if not accepted
3. Call the API when user accepts
4. Allow navigation to skin analysis after acceptance

The implementation is seamless and requires no additional setup.

## Testing

To test the implementation:

1. Set `policy_accept` to `null` or `false` in user data
2. Start the app - terms popup should appear
3. Accept terms - should proceed to profile completion
4. Check that `policy_accept` is updated in local storage
5. Restart app - terms popup should not appear again
