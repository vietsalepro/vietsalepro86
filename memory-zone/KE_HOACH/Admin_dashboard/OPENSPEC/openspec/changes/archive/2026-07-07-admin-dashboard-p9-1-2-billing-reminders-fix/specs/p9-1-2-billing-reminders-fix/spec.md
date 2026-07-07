## MODIFIED Requirements

### Requirement: p9-1-billing-reminders
The system MUST fix the remaining P9.1.1 billing-reminders bugs so the Admin Dashboard can manage reminders end-to-end.

#### Scenario: authenticated RPC access
- **GIVEN** the system admin is authenticated via the frontend Supabase client
- **WHEN** the admin calls `set_billing_reminder_config` or `get_pending_billing_reminders`
- **THEN** the RPC executes successfully and returns the expected data

#### Scenario: empty milestones rejected
- **GIVEN** the system admin attempts to save billing reminder config
- **WHEN** the milestones array is empty `[]`, null, or contains non-positive values
- **THEN** the system rejects the request with a clear error

## ADDED Requirements

<!-- None. -->

## REMOVED Requirements

<!-- None. -->
