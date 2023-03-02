import { Meteor } from 'meteor/meteor'
import { useCallback, useEffect, useState } from 'react'
import { ValidatedMethod } from 'meteor/mdg:validated-method'

import { methodCallback } from './methodUtils'

/**
 * Takes a method name or validated method and arguments object
  * @returns [data or {}, isLoadComplete, reload]
  */
export const useMethodCallData = (method, methodArgs = {}, options = {}) => {
  const [data, setData] = useState()
  const cb = useCallback(methodCallback(setData), [])

  if (typeof method !== 'string' && !(method instanceof ValidatedMethod)) {
    console.error('Misused useMethodCallData hook, need to pass a valid method')
  }
  const reload = useCallback(() => {
    if (!options.holdCall) {
      if (typeof method === 'string') {
        Meteor.call(method, methodArgs, cb)
      } else if (method instanceof ValidatedMethod) {
        method.call(methodArgs, cb)
      }
    }
  // This seems to be the best way to avoid having to require the methodArgs object to be
  // wrapped in useMemo for every usage
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [method, cb, ...Object.keys(methodArgs), ...Object.values(methodArgs)])

  useEffect(reload, [reload])

  return [data || {}, !!data, reload]
}
