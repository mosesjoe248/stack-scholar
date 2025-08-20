;; Stack Scholar - Scholarship Management Smart Contract

;; Error constants
(define-constant ERR_NOT_REVIEWER (err u100))
(define-constant ERR_ALREADY_VOTED (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_ALREADY_EXISTS (err u103))
(define-constant ERR_UNAUTHORIZED (err u104))
(define-constant ERR_NOT_APPROVED (err u105))
(define-constant ERR_INSUFFICIENT_FUNDS (err u106))
(define-constant ERR_INVALID_AMOUNT (err u107))

;; Contract owner (deployer)
(define-constant contract-owner tx-sender)

;; Data variables
(define-data-var total-donations uint u0)
(define-data-var application-count uint u0)

;; Store reviewers as a data variable instead of define-set
(define-data-var reviewers (list 10 principal) (list))

;; Maps
(define-map applications 
  uint
  {
    student: principal,
    amount: uint,
    approved: bool,
    votes: uint,
    description: (string-utf8 500)
  }
)

(define-map votes 
  { app-id: uint, voter: principal }
  bool
)

;; Helper function to check if principal is in reviewers list
(define-private (is-reviewer (user principal))
  (is-some (index-of (var-get reviewers) user))
)

;; ---- DONATIONS ----
(define-public (donate (amount uint))
  (begin
    ;; Validate amount
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    ;; Transfer STX to contract
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    ;; Update total donations
    (var-set total-donations (+ (var-get total-donations) amount))
    (ok amount)
  )
)

;; ---- SET REVIEWERS (Admin only) ----
(define-public (set-reviewers (r-list (list 10 principal)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR_UNAUTHORIZED)
    (var-set reviewers r-list)
    (ok true)
  )
)

;; ---- ADD SINGLE REVIEWER ----
(define-public (add-reviewer (reviewer principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR_UNAUTHORIZED)
    (let ((current-reviewers (var-get reviewers)))
      (asserts! (is-none (index-of current-reviewers reviewer)) ERR_ALREADY_EXISTS)
      (var-set reviewers (unwrap! (as-max-len? (append current-reviewers reviewer) u10) (err u108)))
      (ok true)
    )
  )
)

;; ---- SUBMIT APPLICATION ----
(define-public (submit-application (amount uint) (description (string-utf8 500)))
  (let ((id (+ (var-get application-count) u1)))
    (begin
      ;; Validate amount
      (asserts! (> amount u0) ERR_INVALID_AMOUNT)
      ;; Check if contract has enough funds
      (asserts! (>= (var-get total-donations) amount) ERR_INSUFFICIENT_FUNDS)
      ;; Increment counter
      (var-set application-count id)
      ;; Store application
      (map-set applications id {
        student: tx-sender,
        amount: amount,
        approved: false,
        votes: u0,
        description: description
      })
      (ok id)
    )
  )
)

;; ---- VOTE ON APPLICATION ----
(define-public (vote (id uint))
  (begin
    ;; Check if user is a reviewer
    (asserts! (is-reviewer tx-sender) ERR_NOT_REVIEWER)
    ;; Check if already voted
    (asserts! (is-none (map-get? votes { app-id: id, voter: tx-sender })) ERR_ALREADY_VOTED)
    ;; Get application
    (match (map-get? applications id)
      app
        (begin
          ;; Record vote
          (map-set votes { app-id: id, voter: tx-sender } true)
          ;; Update vote count
          (map-set applications id (merge app {
            votes: (+ (get votes app) u1)
          }))
          (ok true)
        )
      ERR_NOT_FOUND
    )
  )
)

;; ---- APPROVE AND RELEASE FUNDS ----
(define-public (approve-and-release (id uint))
  (match (map-get? applications id)
    app
      (let ((vote-count (get votes app)))
        (begin
          ;; Check if enough votes (at least 3)
          (asserts! (>= vote-count u3) ERR_NOT_APPROVED)
          ;; Check if not already approved
          (asserts! (not (get approved app)) ERR_ALREADY_EXISTS)
          ;; Check if contract has enough funds
          (asserts! (>= (var-get total-donations) (get amount app)) ERR_INSUFFICIENT_FUNDS)
          ;; Transfer funds to student
          (try! (as-contract (stx-transfer? (get amount app) tx-sender (get student app))))
          ;; Update total donations
          (var-set total-donations (- (var-get total-donations) (get amount app)))
          ;; Mark as approved
          (map-set applications id (merge app { approved: true }))
          (ok true)
        )
      )
    ERR_NOT_FOUND
  )
)

;; ---- EMERGENCY WITHDRAW (Admin only) ----
(define-public (emergency-withdraw (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR_UNAUTHORIZED)
    (asserts! (<= amount (var-get total-donations)) ERR_INSUFFICIENT_FUNDS)
    (try! (as-contract (stx-transfer? amount tx-sender contract-owner)))
    (var-set total-donations (- (var-get total-donations) amount))
    (ok amount)
  )
)

;; ---- READ FUNCTIONS ----
(define-read-only (get-application (id uint))
  (map-get? applications id)
)

(define-read-only (has-voted (id uint) (voter principal))
  (map-get? votes { app-id: id, voter: voter })
)

(define-read-only (get-total-donations)
  (var-get total-donations)
)

(define-read-only (get-application-count)
  (var-get application-count)
)

(define-read-only (get-reviewers)
  (var-get reviewers)
)

(define-read-only (is-user-reviewer (user principal))
  (is-reviewer user)
)

(define-read-only (get-contract-balance)
  (stx-get-balance (as-contract tx-sender))
)

(define-read-only (get-vote-count (id uint))
  (match (map-get? applications id)
    app (some (get votes app))
    none
  )
)

;; Get all applications (limited to first 50 for gas efficiency)
(define-read-only (get-applications-summary)
  (let ((count (var-get application-count)))
    {
      total-count: count,
      total-donations: (var-get total-donations),
      contract-balance: (stx-get-balance (as-contract tx-sender))
    }
  )
)

