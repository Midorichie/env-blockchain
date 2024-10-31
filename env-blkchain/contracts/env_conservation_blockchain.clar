;; Enhanced Environmental Conservation Project Smart Contract
;; Version 2.0: Advanced Governance and Impact Verification

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-insufficient-funds (err u101))
(define-constant err-project-not-found (err u102))
(define-constant err-invalid-status (err u103))
(define-constant err-unauthorized (err u104))
(define-constant err-voting-period-active (err u105))

;; Expanded Project Status Enum
(define-constant STATUS-PROPOSED u0)
(define-constant STATUS-VOTING u1)
(define-constant STATUS-APPROVED u2)
(define-constant STATUS-FUNDING u3)
(define-constant STATUS-ACTIVE u4)
(define-constant STATUS-COMPLETED u5)
(define-constant STATUS-CLOSED u6)

;; Enhanced Project Structure with Governance Mechanisms
(define-map projects
  { project-id: uint }
  {
    name: (string-utf8 100),
    description: (string-utf8 500),
    target-funding: uint,
    current-funding: uint,
    status: uint,
    owner: principal,
    validators: (list 5 principal),
    voting-period-start: uint,
    voting-period-end: uint,
    impact-metrics: (list 10 { 
      metric-name: (string-utf8 50), 
      value: uint,
      validator-approvals: (list 5 principal)
    })
  }
)

;; Voting Mechanism
(define-map project-votes
  { project-id: uint, voter: principal }
  { vote: bool }
)

;; Impact Metric Verification Tracking
(define-map metric-verifications
  { project-id: uint, metric-index: uint }
  { validators-approved: (list 5 principal) }
)

;; Unique Project ID Counter
(define-data-var next-project-id uint u0)

;; Validator Registration
(define-map registered-validators 
  principal 
  { 
    reputation-score: uint, 
    total-projects-validated: uint 
  }
)

;; Create a new conservation project with advanced governance
(define-public (create-conservation-project 
  (name (string-utf8 100))
  (description (string-utf8 500))
  (target-funding uint)
  (proposed-validators (list 5 principal))
)
  (let 
    (
      (project-id (var-get next-project-id))
      (current-block-height block-height)
    )
    ;; Validate inputs
    (asserts! (> target-funding u0) err-insufficient-funds)
    (asserts! (> (len proposed-validators) u1) err-unauthorized)
    
    ;; Create project with voting mechanism
    (map-set projects 
      { project-id: project-id }
      {
        name: name,
        description: description,
        target-funding: target-funding,
        current-funding: u0,
        status: STATUS-PROPOSED,
        owner: tx-sender,
        validators: proposed-validators,
        voting-period-start: current-block-height,
        voting-period-end: (+ current-block-height u100), ;; 100 blocks voting period
        impact-metrics: (list)
      }
    )
    
    ;; Increment project ID
    (var-set next-project-id (+ project-id u1))
    
    ;; Return project ID
    (ok project-id)
)

;; Validator Voting Mechanism
(define-public (vote-on-project 
  (project-id uint)
  (vote bool)
)
  (let 
    (
      (project (unwrap! (map-get? projects { project-id: project-id }) err-project-not-found))
      (current-block-height block-height)
    )
    ;; Validate voting conditions
    (asserts! 
      (and 
        (>= current-block-height (get voting-period-start project))
        (<= current-block-height (get voting-period-end project))
      ) 
      err-voting-period-active
    )
    
    ;; Ensure voter is a designated validator
    (asserts! 
      (is-some (index-of (get validators project) tx-sender)) 
      err-unauthorized
    )
    
    ;; Record vote
    (map-set project-votes 
      { project-id: project-id, voter: tx-sender }
      { vote: vote }
    )
    
    ;; Check if project can be approved
    (if (is-project-approved project-id)
        (begin
          ;; Update project status to approved
          (map-set projects 
            { project-id: project-id }
            (merge project { status: STATUS-APPROVED })
          )
          (ok true)
        )
        (ok false)
    )
)

;; Helper function to check project approval
(define-private (is-project-approved (project-id uint)) 
  (let 
    (
      (project (unwrap! (map-get? projects { project-id: project-id }) false))
      (total-validators (len (get validators project)))
      (votes (filter-map 
        (lambda (validator) 
          (map-get? project-votes { project-id: project-id, voter: validator })
        ) 
        (get validators project)
      ))
      (approvals (len 
        (filter 
          (lambda (vote-info) 
            (get vote vote-info)
          ) 
          votes
        )
      ))
    )
    ;; Require 2/3 majority for approval
    (>= approvals (/ (* total-validators u2) u3))
)

;; Enhanced Contribution Mechanism with Milestone Tracking
(define-map project-milestones
  { project-id: uint }
  {
    total-milestones: uint,
    completed-milestones: uint,
    milestone-details: (list 5 {
      description: (string-utf8 100),
      funding-percentage: uint,
      is-completed: bool
    })
  }
)

;; Add Milestones to Project
(define-public (add-project-milestones 
  (project-id uint)
  (milestones (list 5 {
    description: (string-utf8 100), 
    funding-percentage: uint
  }))
)
  (let 
    (
      (project (unwrap! (map-get? projects { project-id: project-id }) err-project-not-found))
    )
    ;; Only project owner can add milestones
    (asserts! (is-eq tx-sender (get owner project)) err-owner-only)
    ;; Ensure milestones percentages sum to 100
    (asserts! 
      (is-eq 
        (fold + (map get-funding-percentage milestones) u0)
        u100
      ) 
      err-insufficient-funds
    )
    
    ;; Set milestones
    (map-set project-milestones 
      { project-id: project-id }
      {
        total-milestones: (len milestones),
        completed-milestones: u0,
        milestone-details: (map 
          (lambda (milestone) 
            {
              description: (get description milestone),
              funding-percentage: (get funding-percentage milestone),
              is-completed: false
            }
          ) 
          milestones
        )
      }
    )
    
    (ok true)
)

;; Utility function to get funding percentage
(define-private (get-funding-percentage (milestone { description: (string-utf8 100), funding-percentage: uint }))
  (get funding-percentage milestone)
)

;; Verify and Complete Project Milestones
(define-public (complete-project-milestone 
  (project-id uint)
  (milestone-index uint)
)
  (let 
    (
      (project (unwrap! (map-get? projects { project-id: project-id }) err-project-not-found))
      (milestones (unwrap! 
        (map-get? project-milestones { project-id: project-id }) 
        err-project-not-found
      ))
      (current-milestone (unwrap-panic 
        (element-at (get milestone-details milestones) milestone-index)
      ))
    )
    ;; Ensure only project owner can mark milestones
    (asserts! (is-eq tx-sender (get owner project)) err-owner-only)
    
    ;; Update milestone status
    (map-set project-milestones 
      { project-id: project-id }
      (merge milestones {
        completed-milestones: (+ (get completed-milestones milestones) u1),
        milestone-details: (replace 
          (get milestone-details milestones) 
          milestone-index 
          (merge current-milestone { is-completed: true })
        )
      })
    )
    
    (ok true)
)