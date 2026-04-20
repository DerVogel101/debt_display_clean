// Keep this Auth0 Action secret aligned with AUTH0_FULL_NAME_CLAIM in the app/backend config.
const DEFAULT_FULL_NAME_CLAIM = 'https://debt-display.dervogel101.de/fullName';

function trimmedString(value) {
  if (typeof value !== 'string') {
    return null;
  }

  const trimmed = value.trim();
  return trimmed || null;
}

function resolveFullNameClaim(event) {
  const configuredClaim = trimmedString(event.secrets?.AUTH0_FULL_NAME_CLAIM);
  return configuredClaim || DEFAULT_FULL_NAME_CLAIM;
}

exports.onExecutePostLogin = async (event, api) => {
  const fullName = trimmedString(event.user?.user_metadata?.fullName);
  if (!fullName) {
    return;
  }

  const fullNameClaim = resolveFullNameClaim(event);

  api.idToken.setCustomClaim(fullNameClaim, fullName);
  api.accessToken.setCustomClaim(fullNameClaim, fullName);
};
