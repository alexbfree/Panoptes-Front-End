counterpart = require 'counterpart'
React = require 'react'
TitleMixin = require '../lib/title-mixin'
apiClient = require 'panoptes-client/lib/api-client'
OwnedCardList = require '../components/owned-card-list'
Translate = require 'react-translate-component'
{Link, IndexLink} = require 'react-router'

counterpart.registerTranslations 'en',
  collectionsPage:
    title:
      generic: 'All\u00a0Collections'
      project:
        ownedBySelf: 'My\u00a0%(project)s\u00a0Collections'
        ownedByOther: '%(owner)s\'s\u00a0%(project)s\u00a0Collections'
        allOwners: '%(project)s\u00a0Collections'
      allProjects:
        ownedBySelf: 'My\u00a0Collections'
        ownedByOther: '%(owner)s\'s\u00a0Collections'
        allOwners: 'All\u00a0Collections'
    countMessage: 'Showing %(count)s collections'
    button: 'View Collection'
    loadMessage: 'Loading Collections'
    notFoundMessage: 'No Collections Found'
    myCollections: 'My\u00a0Collections'
    favorites: 'My\u00a0Favorites'
    viewOnZooniverseOrg: 'View on zooniverse.org'
    collections:
      project:
        allOwners: 'All\u00a0%(project)s\u00a0Collections'
        ownedBySelf: 'My\u00a0%(project)s\u00a0Collections'
        ownedByOther: '%(user)s\'s\u00a0%(project)s\u00a0Collections'
      allProjects:
        allOwners: 'All\u00a0Collections'
        ownedBySelf: 'All\u00a0My\u00a0Collections'
        ownedByOther: 'All\u00a0%(user)s\'s\u00a0Collections'

CollectionsNav = React.createClass
  displayName: 'CollectionsNav'

  renderWithProjectContext: ->
    <nav className="hero-nav">
      {if @props.viewingOwnCollections
        <Link to="/projects/#{@props.project.slug}/collections/#{@props.user.login}" activeClassName="active">
          <Translate content="collectionsPage.collections.project.ownedBySelf" user={@props.user.login} project={@props.nonBreakableProjectName} />
        </Link>}
      {if @props.viewingOwnCollections
        <Link to="/projects/#{@props.project.slug}/collections/#{@props.collectionOwnerName}/all" activeClassName="active">
          <Translate content="collectionsPage.collections.allProjects.ownedBySelf" user={@props.nonBreakableCollectionOwnerName} />
        </Link>}
      {if !@props.viewingOwnCollections
        <Link to="/projects/#{@props.project.slug}/collections/#{@props.collectionOwnerName}" activeClassName="active">
          <Translate content="collectionsPage.collections.project.ownedByOther" user={@props.nonBreakableCollectionOwnerName} project={@props.nonBreakableProjectName} />
        </Link>}
      {if !@props.viewingOwnCollections
        <Link to="/projects/#{@props.project.slug}/collections/#{@props.collectionOwnerName}/all" activeClassName="active">
          <Translate content="collectionsPage.collections.allProjects.ownedByOther" user={@props.nonBreakableCollectionOwnerName} project={@props.nonBreakableProjectName} />
        </Link>}
      <IndexLink to="/projects/#{@props.project.slug}/collections" activeClassName="active">
        <Translate content="collectionsPage.collections.project.allOwners" project={@props.nonBreakableProjectName} />
      </IndexLink>
      <Link to="/projects/#{@props.project.slug}/collections/all" activeClassName="active">
        <Translate content="collectionsPage.collections.allProjects.allOwners" />
      </Link>
      {if @props.user? and !@props.viewingOwnCollections
        <Link to="/projects/#{@props.project.slug}/collections/#{@props.user.login}/all" activeClassName="active">
          <Translate content="collectionsPage.collections.project.ownedBySelf" />
        </Link>}
      {if @props.user?
        <Link to="/projects/#{@props.project.slug}/favorites/#{@props.user.login}" activeClassName="active">
          <Translate content="collectionsPage.favorites" />
        </Link>}
      {if @props.removeProjectContextLink?
        <Link to="#{@props.removeProjectContextLink}">
          <Translate content="collectionsPage.viewOnZooniverseOrg" />
        </Link>}
    </nav>

  renderWithoutProjectContext: ->
    <nav className="hero-nav">
      <IndexLink to="/collections" activeClassName="active">
        <Translate content="collectionsPage.all" />
      </IndexLink>
      {if @props.user?
        <Link to="/collections/#{@props.user.login}" activeClassName="active">
          <Translate content="collectionsPage.myCollections" />
        </Link>}
      {if @props.user?
        <Link to="/favorites/#{@props.user.login}" activeClassName="active">
          <Translate content="collectionsPage.favorites" />
        </Link>}
    </nav>

  render: ->
    if @props.project? then @renderWithProjectContext() else @renderWithoutProjectContext()


List = React.createClass
  displayName: 'List'

  imagePromise: (collection) ->
    apiClient.type('subjects').get(collection_id: collection.id, page_size: 1)
      .then ([subject]) ->
        if subject?
          firstKey = Object.keys(subject.locations[0])[0]
          subject.locations[0][firstKey]
        else
          '/simple-avatar.jpg'

  cardLink: (collection) ->
    [owner, name] = collection.slug.split('/')
    if @props.project?
      "/projects/#{@props.project.slug}/collections/#{owner}/#{name}"
    else
      "/collections/#{owner}/#{name}"

  listCollections: (collectionOwner,project) ->
    filters = @getFiltersFromPath()
    query = {}
    for field, value of filters
      query[field] = value

    query.favorite = @props.favorite
    Object.assign query, @props.location.query

    apiClient.type('collections').get query

  # return the display name of the collection owner (just login name for now)
  getCollectionOwnerName: ->
    if @props.params?.collection_owner?
      return @props.params.collection_owner
    else
      return @props.params.owner

  getFiltersFromPath: ->
    # /projects/project_owner/project_name/collections/collection_owner/all -> All collection_owner's collections, viewed in context of project_name and collection_owner
    # /projects/project_owner/project_name/collections/collection_owner     -> All collection_owner's collections for project_name, viewed in context of project_name and collection_owner
    # /projects/project_owner/project_name/collections/all                  -> All collections, viewed in context of project_name
    # /projects/project_owner/project_name/collections/                     -> All collections for project_name, viewed in context of project_name
    # /collections/collection_owner                                         -> All collections by collection owner, no context
    # /collections/                                                         -> All collections for all users
    filters = {}
    pathParts = @props.location.pathname.split('/')
    [firstPart, ..., lastPart] = pathParts
    if firstPart == "projects" and pathParts.length < 6 and lastPart != "all"
      filters["project_ids"] = @props.project.id
    if firstPart == "collections" and pathParts.length == 2 and pathParts[1] != ""
      filters["owner"] = pathParts[1]
    if pathParts.length>4 and pathParts[3] == "collections" and pathParts[4] != "" and pathParts[4] != "all"
      filters["owner"] = pathParts[4]
    return filters

  checkIfViewingOwnCollections: ->
    return @props.user? and @props.user.login == @getCollectionOwnerName()

  getRemoveProjectContextLink: ->
    pathParts = @props.location.pathname.split('/')
    [first, ..., last] = pathParts
    if first == "projects"
      if last == "all"
        return pathParts[3...-1].join("/")
      else
        return pathParts[3...].join("/")

  render: ->
    if @props.project?
      @nonBreakableProjectName = @props.project.display_name.replace /\ /g, "\u00a0"
      @nonBreakableCollectionOwnerName = @getCollectionOwnerName().replace /\ /g, "\u00a0"

    <OwnedCardList
      {...@props}
      translationObjectName="collectionsPage"
      listPromise={@listCollections(@getCollectionOwnerName())}
      linkTo="collections"
      filter={@getFiltersFromPath()}
      heroNav={<CollectionsNav user={@props.user} filters={@getFiltersFromPath()} removeProjectContextLink={@getRemoveProjectContextLink()} nonBreakableCollectionOwnerName={@nonBreakableCollectionOwnerName} nonBreakableProjectName={@nonBreakableProjectName} project={@props.project} owner={@props.owner} viewingOwnCollections={@checkIfViewingOwnCollections()} collectionOwnerName={@getCollectionOwnerName()} />}
      heroClass="collections-hero"
      nonBreakableOwnerName={@nonBreakableCollectionOwnerName}
      nonBreakableProjectName={@nonBreakableProjectName}
      ownerName={@getCollectionOwnerName()}
      skipOwner={!@props.params?.owner}
      imagePromise={@imagePromise}
      cardLink={@cardLink} />

FavoritesList = React.createClass
  displayName: 'FavoritesPage'
  mixins: [TitleMixin]
  title: 'Favorites'

  render: ->
    props = Object.assign({}, @props, {favorite: true})
    <List {...props} />

CollectionsList = React.createClass
  displayName: 'CollectionsPage'
  mixins: [TitleMixin]
  title: 'Collections'

  render: ->
    props = Object.assign({}, @props, {favorite: false})
    <List {...props} />

module.exports = {FavoritesList, CollectionsList}
