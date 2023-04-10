import React from 'react'

export function TextField({
  error,
  label,
  registerProps,
  type = 'text',
}) {
  return (
    <div className="form-group">
      <label htmlFor={registerProps.name}>{label}</label>
      <input {...registerProps} type={type} className="form-control" />
      {error && (
        <div className='form-text text-danger'>
          {error}
        </div>
      )}
    </div>
  )
}
