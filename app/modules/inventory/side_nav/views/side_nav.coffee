UserLi = require 'modules/users/views/user_li'
UsersList = require 'modules/users/views/users_list'
UserProfile = require './user_profile'
GroupsList = require 'modules/network/views/groups_list'
Group = require 'modules/network/views/group'
UsersSearch = require 'modules/network/plugins/users_search'
headersData = require '../lib/headers'

module.exports = Marionette.LayoutView.extend
  id: 'innerNav'
  template: require './templates/side_nav'

  regions:
    one: '#one'
    groupsList: '#groupsList'
    membersList: '#membersList'
    mainUser: '#mainUser'

  behaviors:
    PreventDefault: {}

  ui:
    two: '#two'

    friendsSection: '#usersListHeader, #usersList'
    usersList: '#usersList'
    usersToggler: '#usersListHeader .listToggler'

    groupsSection: '#groupsListHeader, #groupsList'
    groupsList: '#groupsList'
    groupsToggler: '#groups .listToggler'

    publicSection: '#publicListHeader, #publicList'
    publicList: '#publicList'
    publicToggler: '#public .listToggler'

    membersSection: '#membersListHeader, #membersList'
    membersList: '#membersList'
    membersToggler: '#members .listToggler'
    memberSearch: '#memberSearch'

    nearby: 'li.nearby'
    last: 'li.last'

    togglers: '.toggler'

  initialize: ->
    @initPlugins()
    @listenTo app.vent,
      'sidenav:show:base': @showBase.bind(@)
      'sidenav:show:user': @showUser.bind(@)
      'sidenav:show:group': @showGroup.bind(@)

    @lazyMemberFilter = _.debounce @updateMemberFilter, 100

  initPlugins: ->
    UsersSearch.call @

  events:
    'keyup #memberField': 'lazyMemberFilter'
    'click .listHeader': 'toggleListHeader'
    'click #nearby': 'showInventoryNearby'
    'click #last': 'showInventoryLast'

  serializeData: ->
    _.extend headersData,
      smallScreen: _.smallScreen()

  showBase: (active)->
    @_listReady = false
    @_usersListShown = false
    @_groupsListShown = false
    @_publicListShown = false

    @showMainUser()

    @ui.two.show()
    @ui.membersSection.hide()
    @ui.memberSearch.hide()

    @ui.publicSection.removeClass 'force-hidden'
    @ui.publicSection.show()

    @ui.groupsSection.removeClass 'force-hidden'
    @ui.groupsSection.show()

    @ui.friendsSection.removeClass 'force-hidden'
    @ui.friendsSection.show()

    switch active
      when 'last', 'nearby' then @ui[active].addClass 'active'

    if _.smallScreen()
      app.request 'waitForUserData'
      .then @initBaseSmallScreen.bind(@)

    else
      @showUsersList()
      @showPublicList()
      app.request 'waitForUserData'
      .then @showGroupsList.bind(@)
      # useful in case the screen is resized
      .then @initBaseSmallScreen.bind(@)

  initBaseSmallScreen: ->
    @_listReady = true
    @ui.togglers.show()

  showUser: (userModel)->
    @ui.two.hide()
    @one.show new UserProfile {model: userModel}

  showMainUser: ->
    @mainUser.show new UserLi {model: app.user}

  showUsersList: ->
    @_usersListShown = true
    @ui.friendsSection.show()
    @showUsersSearchBase()
    @adjustHeight app.users.friends, @ui.usersList

  showGroupsList: ->
    @_groupsListShown = true
    @ui.groupsSection.show()
    @groupsList.show new GroupsList
      collection: app.user.groups.mainUserMember

    @adjustHeight app.user.groups.mainUserMember, @ui.groupsList

  # if either the users or groups list is way less populated that the other
  # display:flex will make it appear quite small, thus the need to make sure
  # it has a minimal descent size
  adjustHeight: (collection, $el)->
    if collection.length > 1
      { offsetHeight, scrollHeight } = $el[0]
      if scrollHeight > offsetHeight then $el.addClass 'expend'

  showPublicList: ->
    @_publicListShown = true
    @ui.publicSection.show()

  showGroup: (groupModel)->
    @_membersListShown = false
    @_currentGroup = groupModel
    if _.smallScreen()
      @one.show new Group
        model: groupModel
        highlighted: true
    else
      # shown by inventory::prepareGroupItemsList
      @showMembersList()
      @ui.userSearch.hide()
      @ui.memberSearch.show()


    @ui.groupsSection.hide()
    @ui.friendsSection.hide()

    @ui.membersSection.removeClass 'force-hidden'
    @ui.membersSection.show()

    @setGroupHeader groupModel
    @initBaseSmallScreen()

  showMembersList: ->
    @_membersListShown = true
    @membersList.show new UsersList
      collection: @_currentGroup.members
      textFilter: true
      emptyViewMessage: "can't find any group member with that name"

  updateMemberFilter: (e)->
    text = e.currentTarget.value
    @membersList.currentView.trigger 'filter:text', text

  setGroupHeader: (group)->
    @ui.usersListHeader.find('.header').text _.i18n('group members')

  # used for smallScreens only
  toggleListHeader: (e)->
    # checking @_listReady as we don't want the toggler to be toggled
    # before lists are ready as it would be out of sync
    if @_listReady and _.smallScreen()
      { id } = e.currentTarget

      switch id
        when 'usersListHeader'
          # toggleUserSearch need to be before toggleList as will alter @_usersListShown
          @toggleUserSearch()
          @toggleList 'users', @_usersListShown

        when 'groupsListHeader'
          @toggleList 'groups', @_groupsListShown

        when 'membersListHeader'
          @toggleList 'members', @_membersListShown
          @ui.memberSearch.toggle()

        when 'publicListHeader'
          @toggleList 'public', @_publicListShown

        else _.error id, 'unknown list header'

  toggleList: (name, shown)->
    if shown
      @ui["#{name}List"].slideToggle 200
      @ui["#{name}Toggler"].toggle()
    else
      # showing the view will override display:none rules
      # we just miss the slide effect then
      @showList name
      @ui["#{name}Toggler"].toggle()

  showList: (name)->
    switch name
      when 'users' then @showUsersList()
      when 'groups' then @showGroupsList()
      when 'members' then @showMembersList()
      when 'public' then @showPublicList()
      else _.error name, 'unknown list'

  toggleUserSearch: ->
    if @_usersListShown then @ui.userSearch.toggle()
    else @ui.userSearch.show()

  showInventoryNearby: -> app.execute 'show:inventory:nearby'
  showInventoryLast: -> app.execute 'show:inventory:last'
