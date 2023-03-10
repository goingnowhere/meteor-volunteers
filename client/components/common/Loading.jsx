import React from 'react'

export function Loading({ className }) {
  return (
    <div className={`d-flex align-items-center justify-content-center ${className ?? ''}`}>
      <div className="spinner-border" role="status">
        <span className="sr-only">Loading...</span>
      </div>
    </div>
  )
}
