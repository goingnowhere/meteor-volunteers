import { Meteor } from 'meteor/meteor'
import { useCallback, useEffect, useState } from 'react'
import { ValidatedMethod } from 'meteor/mdg:validated-method'

import { methodCallback } from './methodUtils'

// TODO? Support custom error handling as well as displaying to the user?
/**
 * React hook to handle calling a method and making the return available to the component
 * @param {string | ValidatedMethod} method - A method name or ValidatedMethod object
 * @param {object} [methodArgs] - Args to pass to the method. Any nested objects will need to be
 * memoized to avoid re-running methods
 * @param {{ holdCall, default }} [options] - holdCall allows to prevent running the method until a
 * flag is true, for example when the args depend on another method call
 * @returns [data or {}, isLoadComplete, reload]
 */
export const useMethodCallData = (method, methodArgs = {}, options = {}) => {
  // TODO when reloading after input changes, does not re-enter a loading state which could be
  // confusing e.g. on noinfo dashboard
  const dfault = options.default || {}
  const [data, setData] = useState()
  // The function returned by methodCallback has unknown deps, but in fact it has none
  // eslint-disable-next-line react-hooks/exhaustive-deps
  const cb = useCallback(methodCallback((_err, dat) => setData(dat)), [])

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
  }, [method, cb, options.holdCall, ...Object.keys(methodArgs), ...Object.values(methodArgs)])

  useEffect(reload, [reload])

  return [data || dfault, !!data, reload]
}
