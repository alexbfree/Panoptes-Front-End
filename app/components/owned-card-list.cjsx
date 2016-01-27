counterpart = require 'counterpart'
React = require 'react'
TitleMixin = require '../lib/title-mixin'
Translate = require 'react-translate-component'
apiClient = require 'panoptes-client/lib/api-client'
PromiseRenderer = require '../components/promise-renderer'
OwnedCard = require '../partials/owned-card'
{Link, State, Navigation} = require 'react-router'
Select = require 'react-select'
debounce = require 'debounce'

module.exports = React.createClass
  displayName: 'OwnedCardList'
  mixins: [State, Navigation]

  contextTypes:
    location: React.PropTypes.object
    # history: React.PropTypes.object

  propTypes:
    imagePromise: React.PropTypes.func.isRequired
    cardLink: React.PropTypes.func.isRequired
    translationObjectName: React.PropTypes.string.isRequired
    ownerName: React.PropTypes.string
    heroClass: React.PropTypes.string
    heroNav: React.PropTypes.node
    skipOwner: React.PropTypes.bool

    listPromise: React.PropTypes.object.isRequired
    onGridChange: React.PropTypes.func
    onSearch: React.PropTypes.object
    sortOptions: React.PropTypes.array

  componentDidMount: ->
    document.documentElement.classList.add 'on-secondary-page'

  componentWillUnmount: ->
    document.documentElement.classList.remove 'on-secondary-page'

  setPage: (page) ->
    @props.onGridChange page: page
  setSort: (newSort) ->
    @props.onGridChange {sort: newSort, page: 1}

  userForTitle: ->
    if @props.ownerName
      "#{@props.ownerName}'s"
    else
      'All'

  render: ->
    {location} = @props

    <div className="secondary-page all-resources-page">
      <section className={"hero #{@props.heroClass}"}>
        <div className="hero-container">
          <Translate component="h1" user={@userForTitle()} content={"#{@props.translationObjectName}.title"} />
          {if @props.heroNav?
            @props.heroNav}
        </div>
      </section>
      <section className="resources-container">
        <div>
          {this.props.children}
        </div>
        <PromiseRenderer promise={@props.listPromise}>{(ownedResources) =>
          if ownedResources?.length > 0
            meta = ownedResources[0].getMeta()
            <div>
              <div className="resource-results-counter card-list" style={{overflow: 'visible'}}> {if meta
                  pageStart = meta.page * meta.page_size - meta.page_size + 1
                  pageEnd = Math.min(meta.page * meta.page_size, meta.count)
                  count = meta.count
                  <Translate pageStart={pageStart} pageEnd={pageEnd} count={count} content="#{@props.translationObjectName}.countMessage" component="p" />
                  <p className="showing-with-link-para"><Translate pageStart={pageStart} pageEnd={pageEnd} count={count} content="#{@props.translationObjectName}.countMessage" /></p>}
                {if @props.onSearch
                  <Select
                    multi={false}
                    name="resourcesid"
                    placeholder="Name:"
                    searchPromptText="Search by name"
                    closeAfterClick={true}
                    asyncOptions={debounce(@props.onSearch.query, 200)}
                    onChange={@props.onSearch.navigate}
                    className="search card-search standard-input"
                  />}
                {if @props.sortOptions
                   <Select
                    multi={false}
                    name="sort_order"
                    placeholder="Sort By:"
                    searchPromptText="Select a sort order"
                    closeAfterClick={true}
                    className='standard-input search card-sort'
                    options={@props.sortOptions}
                    onChange={@setSort} />
                }
              </div>
              <div className="card-list">
                {for resource in ownedResources
                   <OwnedCard
                     key={resource.id}
                     resource={resource}
                     imagePromise={@props.imagePromise(resource)}
                     linkTo={@props.cardLink(resource)}
                     translationObjectName={@props.translationObjectName}
                     skipOwner={@props.skipOwner} />}
              </div>
              <nav>
                {if meta
                  <nav className="pagination">
                    {for page in [1..meta.page_count]
                      active = (page is +location.query.page) or (page is 1 and not location.search)
                      <a onClick={@setPage.bind null, page} key={page} className="pill-button" style={border: "2px solid" if page is 1 and window.location.search is ""}>{page}</a>}
                  </nav>}
              </nav>
            </div>
          else if ownedResources?.length is 0
            <div style={{padding: '2em'}}><h1 className='card-list' style={margin: '1em'}><Translate content="#{@props.translationObjectName}.notFoundMessage" component="p" /></h1></div>
          else
            <Translate content="#{@props.translationObjectName}.loadMessage" component="div" />
        }</PromiseRenderer>
      </section>
    </div>
