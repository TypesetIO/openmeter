import "@typespec/http";
import "@typespec/rest";
import "@typespec/openapi3";

using TypeSpec.Http;
using TypeSpec.OpenAPI;

namespace OpenMeter;

@route("/api/v1/subjects")
@tag("Subjects")
interface Subjects {
  /**
   * List subjects.
   */
  @get
  @operationId("listSubjects")
  @summary("List subjects")
  list(): OpenMeter.Subject[] | OpenMeter.CommonErrors;

  /**
   * Get subject by ID or key.
   */
  @get
  @operationId("getSubject")
  @summary("Get subject")
  get(
    @path subjectIdOrKey: string,
  ): OpenMeter.Subject | OpenMeter.NotFoundError | OpenMeter.CommonErrors;

  /**
   * Upserts a subject. Creates or updates subject.
   *
   * If the subject doesn't exist, it will be created.
   * If the subject exists, it will be partially updated with the provided fields.
   */
  @post
  @operationId("upsertSubject")
  @summary("Upsert subject")
  upsert(
    @body subject: SubjectUpsert[],
  ): OpenMeter.Subject[] | OpenMeter.CommonErrors;

  /**
   * Delete subject by ID or key.
   */
  @delete
  @operationId("deleteSubject")
  @summary("Delete subject")
  delete(@path subjectIdOrKey: string): void | OpenMeter.CommonErrors;
}

/**
 * A subject is a unique identifier for a usage attribution by its key.
 * Subjects only exist in the concept of metering.
 * Subjects are optional to create and work as an enrichment for the subject key like displayName, metadata, etc.
 * Subjects are useful when you are reporting usage events with your own database ID but want to enrich the subject with a human-readable name or metadata.
 * For most use cases, a subject is equivalent to a customer.
 */
@friendlyName("Subject")
@example(#{
  id: "01G65Z755AFWAKHE12NY0CQ9FH",
  key: "customer-id",
  displayName: "Customer Name",
  metadata: #{ hubspotId: "123456" },
  stripeCustomerId: "cus_JMOlctsKV8",
})
model Subject {
  // Validator doesn't obey required for readOnly properties
  // See: https://github.com/stoplightio/spectral/issues/1274

  /**
   * A unique identifier for the subject.
   */
  @visibility(Lifecycle.Read)
  @example("01G65Z755AFWAKHE12NY0CQ9FH")
  id: ULID;

  /**
   * A unique, human-readable identifier for the subject.
   * This is typically a database ID or a customer key.
   */
  @example("customer-db-id-123")
  key: string;

  /**
   * A human-readable display name for the subject.
   */
  @example("Customer Name")
  displayName?: string | null;

  /**
   * Metadata for the subject.
   */
  @example(#{ hubspotId: "123456" })
  metadata?: Record<unknown> | null;

  /**
   * The start of the current period for the subject.
   */
  #deprecated "Use Stripe App instead"
  @example(DateTime.fromISO("2023-01-01T00:00:00Z"))
  currentPeriodStart?: DateTime;

  /**
   * The end of the current period for the subject.
   */
  #deprecated "Use Stripe App instead"
  @example(DateTime.fromISO("2023-02-01T00:00:00Z"))
  currentPeriodEnd?: DateTime;

  /**
   * The Stripe customer ID for the subject.
   */
  #deprecated "Use customer app instead"
  @example("cus_JMOlctsKV8")
  stripeCustomerId?: string | null;
}

/**
 * A subject is a unique identifier for a user or entity.
 */
@friendlyName("SubjectUpsert")
@example(#{
  key: "customer-id",
  displayName: "Customer Name",
  metadata: #{ hubspotId: "123456" },
  stripeCustomerId: "cus_JMOlctsKV8",
})
model SubjectUpsert is TypeSpec.Rest.Resource.ResourceCreateModel<Subject>;
