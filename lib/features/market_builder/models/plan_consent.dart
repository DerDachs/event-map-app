/// Version of the consent text below. Raise it whenever the wording changes;
/// the Cloud Function (functions/src/consent.ts) accepts this version and up.
const planConsentVersion = 1;

const planConsentTitle = 'Ich darf diesen Lageplan verwenden';

/// What the uploader confirms before a plan is uploaded. Have it reviewed
/// legally before the store release (see docs/roadmap.md, phase 1).
const planConsentText =
    'Ich bin Urheber oder Veranstalter des Plans oder habe die Erlaubnis dazu. '
    'cellarworks darf den Plan und die daraus erkannten Stände in Market Mate speichern, '
    'zur Erkennung der Stände an die KI Claude von Anthropic übermitteln und den Besuchern '
    'der App anzeigen. Ich kann das jederzeit widerrufen, der Markt wird dann entfernt.';

/// The record stored with a market: who confirmed which text, and when.
/// [at] is a server timestamp when written to Firestore.
Map<String, Object?> planConsentRecord({required String uid, required Object at}) => {
      'granted': true,
      'version': planConsentVersion,
      'at': at,
      'by': uid,
    };

/// The part the Cloud Function checks before it reads a plan.
Map<String, Object> planConsentRequest() => {'granted': true, 'version': planConsentVersion};

/// True if [data] (a market document) carries a valid consent record.
bool hasPlanConsent(Object? data) {
  if (data is! Map) return false;
  final consent = data['planConsent'];
  return consent is Map && consent['granted'] == true && consent['version'] is int;
}
