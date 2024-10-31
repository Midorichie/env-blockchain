;; Environmental Conservation Project Smart Contract
;; Initial Version: Transparent Funding and Impact Tracking

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-insufficient-funds (err u101))
(define-constant err-project-not-found (err u102))
(define-constant err-invalid-status (err u103))

;; Project Status Enum
(define-constant STATUS-PROPOSED u0)
(define-constant STATUS-APPROVED u1)
(define-constant STATUS-ACTIVE u2)
(define-constant STATUS-COMPLETED u3)
(define-constant STATUS-CLOSED u4)

;; Project Structure
(define-map projects
  { project-id: uint }
  {
    name: (string-utf8 100),
    description: (string-utf8 500),
    target-funding: uint,
    current-funding: uint,
    status: uint,
    owner: principal,
    impact-metrics: (list 10 { metric-name: (string-utf8 50), value: uint })
  }
)

;; Project Funding Tracking
(define-map project-contributions
  { project-id: uint, contributor: principal }
  { amount: uint }
)

;; Unique Project ID Counter
(define-data-var next-project-id uint u0)

;; Create a new conservation project
(define-public (create-conservation-project 
  (name (string-utf8 100))
  (description (string-utf8 500))
  (target-funding uint)
)
  (let 
    (
      (project-id (var-get next-project-id))
    )
    ;; Validate inputs
    (asserts! (> target-funding u0) err-insufficient-funds)
    
    ;; Create project
    (map-set projects 
      { project-id: project-id }
      {
        name: name,
        description: description,
        target-funding: target-funding,
        current-funding: u0,
        status: STATUS-PROPOSED,
        owner: tx-sender,
        impact-metrics: (list)
      }
    )
    
    ;; Increment project ID
    (var-set next-project-id (+ project-id u1))
    
    ;; Return project ID
    (ok project-id)
)

;; Contribute to a conservation project
(define-public (contribute-to-project 
  (project-id uint)
  (amount uint)
)
  (let 
    (
      (project (unwrap! (map-get? projects { project-id: project-id }) err-project-not-found))
      (current-contributions (default-to u0 
        (get amount 
          (map-get? project-contributions { project-id: project-id, contributor: tx-sender })
        )
      )
    )
    ;; Validate project is active and contribution is valid
    (asserts! (is-eq (get status project) STATUS-APPROVED) err-invalid-status)
    (asserts! (> amount u0) err-insufficient-funds)
    
    ;; Update project funding
    (map-set projects 
      { project-id: project-id }
      (merge project { 
        current-funding: (+ (get current-funding project) amount) 
      })
    )
    
    ;; Track individual contributions
    (map-set project-contributions 
      { project-id: project-id, contributor: tx-sender }
      { amount: (+ current-contributions amount) }
    )
    
    (ok true)
)

;; Add impact metrics for a completed project
(define-public (add-impact-metrics 
  (project-id uint)
  (metrics (list 10 { metric-name: (string-utf8 50), value: uint }))
)
  (let 
    (
      (project (unwrap! (map-get? projects { project-id: project-id }) err-project-not-found))
    )
    ;; Only project owner can add metrics
    (asserts! (is-eq tx-sender (get owner project)) err-owner-only)
    ;; Project must be completed
    (asserts! (is-eq (get status project) STATUS-COMPLETED) err-invalid-status)
    
    ;; Update project with impact metrics
    (map-set projects 
      { project-id: project-id }
      (merge project { impact-metrics: metrics })
    )
    
    (ok true)
)

;; View project details (public read-only function)
(define-read-only (get-project-details (project-id uint))
  (map-get? projects { project-id: project-id })
)