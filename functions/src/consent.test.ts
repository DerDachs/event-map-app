import assert from "node:assert/strict";
import { test } from "node:test";
import { hasPlanConsent, requirePlanConsent } from "./consent.js";

test("accepts a granted consent for the current version", () => {
  assert.equal(hasPlanConsent({ planConsent: { granted: true, version: 1 } }), true);
  assert.equal(hasPlanConsent({ planConsent: { granted: true, version: 2 } }), true);
});

test("rejects missing, withdrawn or malformed consent", () => {
  assert.equal(hasPlanConsent(undefined), false);
  assert.equal(hasPlanConsent({}), false);
  assert.equal(hasPlanConsent({ planConsent: { granted: false, version: 1 } }), false);
  assert.equal(hasPlanConsent({ planConsent: { granted: "true", version: 1 } }), false);
  assert.equal(hasPlanConsent({ planConsent: { granted: true } }), false);
  assert.equal(hasPlanConsent({ planConsent: { granted: true, version: 0 } }), false);
});

test("requirePlanConsent throws failed-precondition without consent", () => {
  assert.throws(() => requirePlanConsent({}), (e: { code?: string }) => e.code === "failed-precondition");
  assert.doesNotThrow(() => requirePlanConsent({ planConsent: { granted: true, version: 1 } }));
});
