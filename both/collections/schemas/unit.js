import { checkNpmVersions } from 'meteor/tmeasday:check-npm-versions'
import SimpleSchema from 'simpl-schema'
import { t } from '../../utils/i18n'

checkNpmVersions({ 'simpl-schema': '1.x' }, 'goingnowhere:volunteers')

SimpleSchema.extendOptions(['autoform'])

const unitPolicy = ['public', 'private']

export const initUnitSchemas = (utils) => {
  const CommonUnit = new SimpleSchema({
    parentId: {
      type: String,
      autoform: {
        type: 'hidden',
      },
    },
    name: {
      type: String,
      label: () => t('name'),
      autoform: {
        afFieldHelpText: () => t('name_help_team'),
      },
    },
    skills: {
      type: Array,
      label: () => t('skills'),
      optional: true,
      autoform: {
        type: 'select2',
        options: utils.getSkillsList,
        afFieldHelpText: () => t('skills_help_team'),
        afFieldInput: {
          multiple: true,
          select2Options() {
            return {
              tags: true,
              width: '100%',
            }
          },
        },
      },
    },
    'skills.$': String,
    quirks: {
      type: Array,
      label: () => t('quirks'),
      optional: true,
      autoform: {
        type: 'select2',
        options: utils.getQuirksList,
        afFieldHelpText: () => t('quirks_help_team'),
        afFieldInput: {
          multiple: true,
          select2Options() {
            return {
              tags: true,
              width: '100%',
            }
          },
        },
      },
    },
    'quirks.$': String,
    description: {
      type: String,
      label: () => t('description'),
      optional: true,
      autoform: {
        rows: 5,
        afFieldHelpText: () => t('description_help_team'),
      },
    },
    // TODO: the unit policy should lock the policy of all entities below
    email: {
      type: String,
      optional: true,
      autoform: {
        label: () => t('public_email'),
        afFieldHelpText: () => t('public_email_help'),
      },
    },
    policy: {
      type: String,
      label: () => t('policy'),
      allowedValues: unitPolicy,
      defaultValue: 'public',
      autoform: {
        afFieldHelpText: () => t('policy_help_team'),
      },
    },
  })

  return {
    team: new SimpleSchema(CommonUnit)
      .extend({
        location: {
          type: String,
          label: () => t('location'),
          optional: true,
          autoform: {
            type: 'select2',
            options: utils.getLocationList,
            afFieldHelpText: () => t('location_help_team'),
            afFieldInput: {
              select2Options: () => ({
                tags: true,
                width: '100%',
                placeholder: t('select_location'),
                allowClear: true,
              })
              ,
            },
          },
        },
      }),

    department: new SimpleSchema(CommonUnit),

    division: new SimpleSchema(CommonUnit)
    // a division (a top level unit) has 'top' as parentId
      .extend({
        parentId: {
          type: String,
          defaultValue: 'TopEntity',
          autoform: {
            type: 'hidden',
          },
        },
      }),
  }
}
