import React, {
  useCallback,
  useContext,
  useState,
} from 'react'
import { useTracker } from 'meteor/react-meteor-data'
import { MultiSelect } from 'react-multi-select-component'
import { t } from '../common/i18n'
import { reactContext } from '../../clientInit'
import { SignupsList } from '../shifts/SignupsList.jsx'

export function FilteredSignupList({ initialShiftType }) {
  const Volunteers = useContext(reactContext)
  const [dutyType, setDutyType] = useState(initialShiftType || 'all')
  const [filters, setFilters] = useState({})
  const { quirks, skills } = useTracker(() => {
    return {
      skills: Volunteers.collections.utils.getSkillsList(),
      quirks: Volunteers.collections.utils.getQuirksList(),
    }
  }, [Volunteers])
  const changeFilter = useCallback((filter) => selected => {
    setFilters({
      ...filters,
      [filter]: selected.length > 0 ? selected.map(({ value }) => value) : undefined,
    })
  }, [filters])

  return (
    <>
      <div className="row no-gutters">
        <select
          id='typeSelect'
          className='col-md-6 col-lg-3'
          value={dutyType}
          onChange={(event) => {
            setDutyType(event.currentTarget.value)
          }}
        >
          <option value="all">{t('all_shifts')}</option>
          <option value="event">{t('event_shifts')}</option>
          <option value="build">{t('build')}</option>
          <option value="strike">{t('strike')}</option>
        </select>
        <MultiSelect
          options={skills}
          value={(filters.skills || []).map(value => ({ value, label: value }))}
          onChange={changeFilter('skills')}
          hasSelectAll={false}
          disableSearch
          overrideStrings={{
            allItemsAreSelected: t('skills'),
            selectSomeItems: t('skills'),
          }}
          className="col-md-6 col-lg-3"
        />
        <MultiSelect
          options={quirks}
          value={(filters.quirks || []).map(value => ({ value, label: value }))}
          onChange={changeFilter('quirks')}
          hasSelectAll={false}
          disableSearch
          overrideStrings={{
            allItemsAreSelected: t('quirks'),
            selectSomeItems: t('quirks'),
          }}
          className="col-md-6 col-lg-3"
        />
        <MultiSelect
          options={['essential', 'important', 'normal'].map(value => ({ value, label: value }))}
          value={(filters.priorities || []).map(value => ({ value, label: value }))}
          onChange={changeFilter('priorities')}
          hasSelectAll={false}
          disableSearch
          overrideStrings={{
            allItemsAreSelected: t('priorities'),
            selectSomeItems: t('priorities'),
          }}
          className="col-md-6 col-lg-3"
        />
      </div>
        <SignupsList
          dutyType={dutyType}
          filters={filters}
        />
    </>
  )
}
