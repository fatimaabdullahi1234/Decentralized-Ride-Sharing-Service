;; Rider Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-registered (err u102))

;; Data Variables
(define-data-var rider-nonce uint u0)

;; Data Maps
(define-map riders
  { rider-id: uint }
  {
    name: (string-ascii 50),
    email: (string-ascii 50),
    rating: uint,
    total-ratings: uint
  }
)

;; Public Functions

;; Register a new rider
(define-public (register-rider (name (string-ascii 50)) (email (string-ascii 50)))
  (let
    (
      (rider-id (var-get rider-nonce))
    )
    (asserts! (is-none (map-get? riders { rider-id: rider-id })) err-already-registered)
    (map-set riders
      { rider-id: rider-id }
      {
        name: name,
        email: email,
        rating: u0,
        total-ratings: u0
      }
    )
    (var-set rider-nonce (+ rider-id u1))
    (ok rider-id)
  )
)

;; Rate a rider
(define-public (rate-rider (rider-id uint) (rating uint))
  (let
    (
      (rider (unwrap! (map-get? riders { rider-id: rider-id }) err-not-found))
    )
    (asserts! (and (>= rating u1) (<= rating u5)) (err u103))
    (map-set riders
      { rider-id: rider-id }
      (merge rider {
        rating: (/ (+ (* (get rating rider) (get total-ratings rider)) rating) (+ (get total-ratings rider) u1)),
        total-ratings: (+ (get total-ratings rider) u1)
      })
    )
    (ok true)
  )
)

;; Read-only Functions

;; Get rider details
(define-read-only (get-rider (rider-id uint))
  (ok (unwrap! (map-get? riders { rider-id: rider-id }) err-not-found))
)

;; Initialize contract
(begin
  (var-set rider-nonce u0)
)
