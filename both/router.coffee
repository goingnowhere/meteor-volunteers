share.initRouters = (eventName) ->
  Router.route "#{eventName}/dashboard/team/:_id",
    name: "teamEdit-#{eventName}"
    template: 'teamDayViewGrid'
    controller: SingleTeamController(eventName)

  Router.route "#{eventName}/dashboard/team/:_id/signups",
    name: "teamSignupsList-#{eventName}"
    template: 'teamSignupsList'
    controller: SingleTeamController(eventName)

  # Router.route "#{eventName}/team/edit/:_id",
  #   name: "teamEdit-#{eventName}"
  #   template: 'teamEdit'
  #   waitOn: () -> [ share.meteorSub("team") ]
  #   data: () ->
  #     if this.params && this.params._id && this.ready()
  #       share.Team.findOne(this.params._id)

  Router.route "#{eventName}/team/view/:_id",
    name: "teamView-#{eventName}"
    template: 'volunteersTeamView'
    waitOn: () -> [ share.meteorSub("team") ]
    data: () ->
      if this.params && this.params._id && this.ready()
        share.Team.findOne(this.params._id)

  Router.route "#{eventName}/division/add",
    name: "divisionAdd-#{eventName}"
    template: 'divisionView'

  Router.route "#{eventName}/division/edit/:_id",
    name: "divisionView-#{eventName}"
    template: 'divisionView'
    waitOn: () -> [ share.meteorSub("division") ]
    data: () ->
      if this.params && this.params._id && this.ready()
        share.Division.findOne(this.params._id)

  Router.route "#{eventName}/department/edit/:_id",
    name: "departmentView-#{eventName}"
    template: 'departmentView'
    waitOn: () -> [ share.meteorSub("department") ]
    data: () ->
      if this.params && this.params._id && this.ready()
        share.Department.findOne(this.params._id)
