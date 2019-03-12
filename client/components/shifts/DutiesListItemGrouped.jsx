import React, { Fragment, Component } from 'react'

import { T } from '../common/i18n'
import { DutiesListItem } from './DutiesListItem.jsx'
import { DutiesListItemDate } from './DutiesListItemDate.jsx'
import { SignupModal } from './SignupModal.jsx'

// TODO can't seem to use hooks in a component mounted by Blaze template
export class DutiesListItemGrouped extends Component {
  constructor(props) {
    super(props)
    this.state = {
      modalOpen: false,
    }
    this.showModal = show => this.setState({ modalOpen: show })
  }

  render() {
    const { duty } = this.props
    const { modalOpen } = this.state
    // TODO move higher when React has spread enough and make general e.g. specify duty in callback
    // const [modalOpen, showModal] = useState(false)
    return (
      <Fragment>
        <SignupModal duty={duty} modalOpen={modalOpen} showModal={this.showModal} />
        <DutiesListItem duty={duty} />
        <div className="row no-gutters pt-2 align-items-center">
          {duty.type === 'project'
            ? <DutiesListItemDate {...duty} />
            : (
              <Fragment>
                <div className="col">
                  <div className="btn-action">
                    <h5 className="mb-0">{ duty.length } <T>shift_length_hours</T></h5>
                  </div>
                </div>
                <div className="col">
                  <button
                    className="btn btn-action btn-primary"
                    type="button"
                    onClick={() => this.showModal(true)}
                  >
                    <T>choose_shifts</T>
                  </button>
                </div>
              </Fragment>
            )}
        </div>
      </Fragment>
    )
  }
}
