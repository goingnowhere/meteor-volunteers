// TODO convert this from old blaze/coffeescript version:

// Template.teamShiftsRota.bindI18nNamespace('goingnowhere:volunteers')
// Template.teamShiftsRota.onCreated () ->
//   template = this
//   teamId = template.data._id
//   template.shifts = new ReactiveVar([])
//   template.grouping = new ReactiveVar(new Set())
//   template.shiftUpdateDep = new Tracker.Dependency
//   share.templateSub(template,"Signups.byTeam",teamId,'shift')
//   template.autorun () ->
//     if template.subscriptionsReady()
//       sel = {parentId: teamId}
//       template.shifts.set(getShifts(sel))

// Template.teamShiftsRota.helpers
//   'groupedShifts': () ->
//     _.chain(Template.instance().shifts.get())
//     .map((s) -> _.extend(s,{ startday: moment(s.start).format("MM-DD-YY")}) )
//     .groupBy('startday')
//     .map((v1,k1) ->
//       day: k1
//       shifts: _.chain(v1)
//         .groupBy('rotaId')
//         .map((v,k) ->
//           title: v[0].title
//           rotaId: k
//           shifts: v
//         ).value()
//     ).value()

{/* <template name="teamShiftsRota">
  <div class="container">
    <div class="row">
      <div class="col">
        {{#each day in groupedShifts}}
          <div class="card">
            <div class="card-header"><h4 div="card-title">Shift for the day : {{day.day}}</h4></div>
            <div class="card-body">
              <table class="table">
                {{#each family in day.shifts}}
                <thead class="thead-default">
                  <tr class="shiftFamily table-active">
                    <td colspan="2"><h5>{{family.title}}</h5></td>
                  </tr>
                </thead>
                <tbody>
                  {{#each shift in family.shifts }}
                    <tr class="shift family-{{family.groupId}}" data-id="{{shift._id}}" data-type="{{shift.type}}">
                      <td> <h2>{{> React component=ShiftDateInline start=shift.start end=shift.end}} </h2></td>
                      <td>
                        {{#if $neq shift.needed 0}}
                          <span class="inline">{{shift.needed}} {{__ ".more_needed"}}</span>
                        {{else}}
                            {{__ ".full"}}
                        {{/if}}
                      </td>
                    </tr>
                    {{#if $gt shift.confirmed 0}}
                      <tr class="shift family-{{family.groupId}}">
                        <td colspan="2">
                          <ul>
                            {{#each signup in shift.signups }}
                              <li>
                                <!-- {{> Template.dynamic template=userInfoTemplate data=signup}} -->
								{{getUserName signup.userId}}  - <a href="mailto:{{getUserEmail signup.userId}}">{{getUserEmail signup.userId}}</a>
                              </li>
                            {{/each}}
                          </ul>
                        </td>
                      </tr>
                    {{/if}}
                  {{/each}}
                </tbody>
                {{/each}}
              </table>
            </div>
          </div>
        {{/each}}
      </div>
    </div>
  </div>
</template> */}
