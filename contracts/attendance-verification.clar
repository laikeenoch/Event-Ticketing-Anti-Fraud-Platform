;; Attendance Verification Contract
;; Confirms ticket usage at events and prevents double-entry fraud

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-INPUT (err u101))
(define-constant ERR-NOT-FOUND (err u102))
(define-constant ERR-TICKET-USED (err u106))
(define-constant ERR-EVENT-EXPIRED (err u105))

;; Data Variables
(define-data-var next-verification-id uint u1)

;; Data Maps
(define-map attendance-records
  { verification-id: uint }
  {
    ticket-id: uint,
    event-id: uint,
    attendee: principal,
    verified-at: uint,
    verified-by: principal,
    entry-point: (string-ascii 50),
    verification-method: (string-ascii 20)
  }
)

(define-map event-attendance
  { event-id: uint }
  {
    total-verified: uint,
    verification-start: uint,
    verification-end: uint,
    active: bool
  }
)

(define-map ticket-verification-status
  { ticket-id: uint }
  {
    verified: bool,
    verification-id: uint,
    attempts: uint,
    last-attempt: uint
  }
)

(define-map authorized-verifiers
  { event-id: uint, verifier: principal }
  {
    authorized: bool,
    role: (string-ascii 20),
    authorized-at: uint
  }
)

(define-map verification-checkpoints
  { event-id: uint, checkpoint: (string-ascii 50) }
  {
    active: bool,
    verifications-count: uint,
    created-at: uint
  }
)

;; Public Functions

;; Initialize attendance verification for an event
(define-public (initialize-event-verification (event-id uint) (verification-start uint) (verification-end uint))
  (let
    (
      (caller tx-sender)
    )
    ;; In production, verify caller is event organizer

    ;; Validate time parameters
    (asserts! (< verification-start verification-end) ERR-INVALID-INPUT)
    (asserts! (>= verification-start block-height) ERR-INVALID-INPUT)

    ;; Initialize event attendance tracking
    (map-set event-attendance
      { event-id: event-id }
      {
        total-verified: u0,
        verification-start: verification-start,
        verification-end: verification-end,
        active: true
      }
    )

    (ok true)
  )
)

;; Authorize a verifier for an event
(define-public (authorize-verifier (event-id uint) (verifier principal) (role (string-ascii 20)))
  (let
    (
      (caller tx-sender)
    )
    ;; In production, verify caller is event organizer

    ;; Validate role
    (asserts! (or (is-eq role "scanner") (is-eq role "admin") (is-eq role "security")) ERR-INVALID-INPUT)

    ;; Authorize verifier
    (map-set authorized-verifiers
      { event-id: event-id, verifier: verifier }
      {
        authorized: true,
        role: role,
        authorized-at: block-height
      }
    )

    (ok true)
  )
)

;; Create verification checkpoint
(define-public (create-checkpoint (event-id uint) (checkpoint (string-ascii 50)))
  (let
    (
      (caller tx-sender)
    )
    ;; In production, verify caller is event organizer or authorized verifier

    ;; Create checkpoint
    (map-set verification-checkpoints
      { event-id: event-id, checkpoint: checkpoint }
      {
        active: true,
        verifications-count: u0,
        created-at: block-height
      }
    )

    (ok true)
  )
)

;; Verify ticket attendance
(define-public (verify-attendance (ticket-id uint) (event-id uint) (entry-point (string-ascii 50)))
  (let
    (
      (caller tx-sender)
      (verification-id (var-get next-verification-id))
    )
    ;; Check if verifier is authorized
    (match (map-get? authorized-verifiers { event-id: event-id, verifier: caller })
      auth-record
      (begin
        (asserts! (get authorized auth-record) ERR-NOT-AUTHORIZED)

        ;; Check if event verification is active
        (match (map-get? event-attendance { event-id: event-id })
          event-att
          (begin
            (asserts! (get active event-att) ERR-EVENT-EXPIRED)
            (asserts! (>= block-height (get verification-start event-att)) ERR-EVENT-EXPIRED)
            (asserts! (<= block-height (get verification-end event-att)) ERR-EVENT-EXPIRED)

            ;; Check if ticket hasn't been verified already
            (match (map-get? ticket-verification-status { ticket-id: ticket-id })
              status
              (begin
                (asserts! (not (get verified status)) ERR-TICKET-USED)
                ;; Update attempt count
                (map-set ticket-verification-status
                  { ticket-id: ticket-id }
                  (merge status {
                    attempts: (+ (get attempts status) u1),
                    last-attempt: block-height
                  })
                )
              )
              ;; First verification attempt
              (map-set ticket-verification-status
                { ticket-id: ticket-id }
                {
                  verified: false,
                  verification-id: u0,
                  attempts: u1,
                  last-attempt: block-height
                }
              )
            )

            ;; Create attendance record
            (map-set attendance-records
              { verification-id: verification-id }
              {
                ticket-id: ticket-id,
                event-id: event-id,
                attendee: tx-sender,
                verified-at: block-height,
                verified-by: caller,
                entry-point: entry-point,
                verification-method: "manual"
              }
            )

            ;; Mark ticket as verified
            (map-set ticket-verification-status
              { ticket-id: ticket-id }
              {
                verified: true,
                verification-id: verification-id,
                attempts: (default-to u1 (get attempts (map-get? ticket-verification-status { ticket-id: ticket-id }))),
                last-attempt: block-height
              }
            )

            ;; Update event attendance count
            (map-set event-attendance
              { event-id: event-id }
              (merge event-att { total-verified: (+ (get total-verified event-att) u1) })
            )

            ;; Update checkpoint count
            (match (map-get? verification-checkpoints { event-id: event-id, checkpoint: entry-point })
              checkpoint-data
              (map-set verification-checkpoints
                { event-id: event-id, checkpoint: entry-point }
                (merge checkpoint-data { verifications-count: (+ (get verifications-count checkpoint-data) u1) })
              )
              true
            )

            ;; Increment next verification ID
            (var-set next-verification-id (+ verification-id u1))

            (ok verification-id)
          )
          ERR-NOT-FOUND
        )
      )
      ERR-NOT-AUTHORIZED
    )
  )
)

;; Bulk verify multiple tickets (for efficiency)
(define-public (bulk-verify-attendance (ticket-ids (list 50 uint)) (event-id uint) (entry-point (string-ascii 50)))
  (let
    (
      (caller tx-sender)
    )
    ;; Check if verifier is authorized
    (match (map-get? authorized-verifiers { event-id: event-id, verifier: caller })
      auth-record
      (begin
        (asserts! (get authorized auth-record) ERR-NOT-AUTHORIZED)
        ;; Process each ticket (simplified implementation)
        (fold verify-single-ticket ticket-ids (ok (list)))
      )
      ERR-NOT-AUTHORIZED
    )
  )
)

;; Helper function for bulk verification
(define-private (verify-single-ticket (ticket-id uint) (acc (response (list 50 uint) uint)))
  (match acc
    success-list
    (match (verify-attendance ticket-id u1 "bulk-entry")
      verification-id (ok (unwrap! (as-max-len? (append success-list verification-id) u50) (err u999)))
      error acc
    )
    error acc
  )
)

;; Revoke verifier authorization
(define-public (revoke-verifier (event-id uint) (verifier principal))
  (let
    (
      (caller tx-sender)
    )
    ;; In production, verify caller is event organizer

    ;; Revoke authorization
    (match (map-get? authorized-verifiers { event-id: event-id, verifier: verifier })
      auth-record
      (begin
        (map-set authorized-verifiers
          { event-id: event-id, verifier: verifier }
          (merge auth-record { authorized: false })
        )
        (ok true)
      )
      ERR-NOT-FOUND
    )
  )
)

;; End event verification
(define-public (end-event-verification (event-id uint))
  (let
    (
      (caller tx-sender)
    )
    ;; In production, verify caller is event organizer

    ;; Deactivate event verification
    (match (map-get? event-attendance { event-id: event-id })
      event-att
      (begin
        (map-set event-attendance
          { event-id: event-id }
          (merge event-att { active: false })
        )
        (ok true)
      )
      ERR-NOT-FOUND
    )
  )
)

;; Read-only Functions

;; Get attendance record
(define-read-only (get-attendance-record (verification-id uint))
  (map-get? attendance-records { verification-id: verification-id })
)

;; Get event attendance summary
(define-read-only (get-event-attendance (event-id uint))
  (map-get? event-attendance { event-id: event-id })
)

;; Check if ticket is verified
(define-read-only (is-ticket-verified (ticket-id uint))
  (match (map-get? ticket-verification-status { ticket-id: ticket-id })
    status (get verified status)
    false
  )
)

;; Get ticket verification status
(define-read-only (get-ticket-verification-status (ticket-id uint))
  (map-get? ticket-verification-status { ticket-id: ticket-id })
)

;; Check if verifier is authorized
(define-read-only (is-authorized-verifier (event-id uint) (verifier principal))
  (match (map-get? authorized-verifiers { event-id: event-id, verifier: verifier })
    auth-record (get authorized auth-record)
    false
  )
)

;; Get checkpoint statistics
(define-read-only (get-checkpoint-stats (event-id uint) (checkpoint (string-ascii 50)))
  (map-get? verification-checkpoints { event-id: event-id, checkpoint: checkpoint })
)

;; Get next verification ID
(define-read-only (get-next-verification-id)
  (var-get next-verification-id)
)
