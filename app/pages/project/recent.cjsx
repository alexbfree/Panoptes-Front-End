counterpart = require 'counterpart'
React = require 'react'
talkClient = require 'panoptes-client/lib/talk-client'
apiClient = require 'panoptes-client/lib/api-client'
{Link} = require 'react-router'
Translate = require 'react-translate-component'
Comment = require '../../talk/comment'
Loading = require '../../components/loading-indicator'
{timestamp} = require '../../talk/lib/time'
getSubjectLocation = require '../../lib/get-subject-location'
Thumbnail = require '../../components/thumbnail'
PromiseRenderer = require '../../components/promise-renderer'
CollectionPreview = require '../../collections/preview'
classNames = require 'classnames'

counterpart.registerTranslations 'en',
  recentPage:
    title: 'Recent Updates on %(projectName)s'

RecentPage = React.createClass
  displayName: 'ProjectRecent'

  componentDidMount: ->
    @getMoreTextComments()
    @getMoreSubjectComments()
    @getMoreCollections()
    if @props.project?
      document.documentElement.classList.add 'on-secondary-page'

  componentWillUnmount: ->
    if @props.project?
      document.documentElement.classList.remove 'on-secondary-page'

  getInitialState: ->
    subject_comments: []
    text_comments: []
    collections: []
    subject_comments_page: 0
    text_comments_page: 0
    collections_page: 0
    text_comments_all_loaded: false
    subject_comments_all_loaded: false
    collections_all_loaded: false
    subject_comments_loading: true
    text_comments_loading: true
    collections_loading: true

  paramsForSubjectComments: (page = 1) ->
    params =
      sort: '-created_at'
      page: page
      page_size: 2
      focus_type: "Subject"
      section: "project-#{ @props.project.id }"
    params

  # TODO add params.focus_id = ""
  paramsForTextComments: (page = 1) ->
    params =
      sort: '-created_at'
      page: page
      page_size: 2
      section: "project-#{ @props.project.id }"
    params

  getMoreTextComments: ->
    text_comments_page = @state.text_comments_page + 1
    text_comments = @state.text_comments
    text_comments_all_loaded = @state.text_comments_all_loaded
    previous_text_comments_length = text_comments.length
    params = @paramsForTextComments(text_comments_page)
    talkClient.type('comments').get(params).then (comments) =>
      meta = comments[0]?.getMeta() or { }
      text_comments_loading = false
      newTC = 0
      for comment in comments
        if not comment.is_deleted
          if comment.focus_id is ""
            newTC += 1
            text_comments.push comment
      if meta?.next_page is null
        text_comments_all_loaded = true
      @setState {text_comments, text_comments_page, text_comments_all_loaded, text_comments_loading}
      if text_comments.length == previous_text_comments_length and not text_comments_all_loaded
        # if none of the comments were text comments, go to next page (only if there is one)
        @getMoreTextComments()

  getMoreSubjectComments: ->
    subject_comments_page = @state.subject_comments_page + 1
    params = @paramsForSubjectComments(subject_comments_page)
    subject_comments_all_loaded = @state.subject_comments_all_loaded
    talkClient.type('comments').get(params).then (comments) =>
      meta = comments[0]?.getMeta() or { }
      subject_comments_loading = false
      subject_comments = @state.subject_comments
      for comment in comments
        if not comment.is_deleted
          subject_comments.push comment
      if meta?.next_page is null
        subject_comments_all_loaded = true
      @setState {subject_comments, subject_comments_page, subject_comments_loading, subject_comments_all_loaded}


  renderSubjectComment: (comment) ->
    <span key={comment.id}>
      <PromiseRenderer
        promise={
          apiClient.type('subjects').get(comment.focus_id)
        }
        then={(subject) =>
          <Thumbnail src={getSubjectLocation(subject).src} width={100} />
        }
        catch={null}
        />
      <p>{timestamp(comment.created_at)}
        {if comment.is_reply
          <span>
            {' '}(reply to comment {comment.reply_id})
          </span>}: - {comment.body}
      </p>
    </span>

  renderTextComment: (comment) ->
    <p key={comment.id}>{timestamp(comment.created_at)}
      {if comment.is_reply
        <span>
          {' '}(reply to comment {comment.reply_id})
        </span>}: - {comment.body}
    </p>

  paramsForCollections: (page = 1) ->
    params =
      sort: '-created_at'
      page: page
      page_size: 1
      project_ids: @props.project.id
      include:'owner'
      favorite: false
    params

  getMoreCollections: ->
    collections_page = @state.collections_page + 1
    params = @paramsForCollections(collections_page)
    collections_all_loaded = @state.collections_all_loaded
    apiClient.type('collections').get(params).then (new_collections) =>
      meta = new_collections[0]?.getMeta() or { }
      collections_loading = false
      collections = @state.collections
      for collection in new_collections
        collections.push collection
      if meta?.next_page is null
        collections_all_loaded = true
      @setState {collections, collections_page, collections_loading, collections_all_loaded}

  renderCollection: (collection) ->
    <CollectionPreview project={@props.project} key={"collection-#{ collection.id }"} collection={collection} />

  render: ->
    classes = classNames {
      "secondary-page":true
      "all-resources-page": true
      "has-project-context": @props.project?
    }
    <div className={classes}>
      <section className="hero recent-hero">
        <div className="hero-container">
          <Translate component="h1" content={"recentPage.title"} projectName={@props.project?.display_name}/>
        </div>
      </section>
      <section className="project-recent-content project-text-content in-project-context">
        <div className="project-recents resources-container">
         <div className="recent-comments-page-body">
            <div className="left-col col">
              <div className="col-section-top col-section">
                <h1>Subject based posts</h1>
                <div className="talk-discussion-comments">
                  {if @state.subject_comments_loading
                    <Loading />
                  else
                    if @state.subject_comments.length == 0
                      <p className="nothing-found">No Subject based posts found.</p>
                    else
                      <span>
                        {@state.subject_comments.map @renderSubjectComment}
                        <div className="paginator">
                          <button
                            className="paginator-next"
                            onClick={@getMoreSubjectComments}
                            disabled={@state.subject_comments_all_loaded}>
                            Load more...
                          </button>
                        </div>
                      </span>}
                </div>
              </div>
            </div>
            <div className="right-col col">
              <div className="col-section-top col-section">
                <h1>Text based posts</h1>
                <div className="talk-discussion-comments">
                  {if @state.text_comments_loading
                    <Loading />
                  else
                    if @state.text_comments.length == 0
                      <p className="nothing-found">No Text based posts found.</p>
                    else
                      <span>
                        {@state.text_comments.map @renderTextComment}
                        <div className="paginator">
                          <button
                            className="paginator-next"
                            onClick={@getMoreTextComments}
                            disabled={@state.text_comments_all_loaded}>
                            Load more...
                          </button>
                        </div>
                      </span>}
                </div>
              </div>
              <hr />
              <div className="col-section-bottom col-section">
                <h1>Collections</h1>
                <div className="recent-collections">
                  {if @state.collections_loading
                    <Loading />
                  else
                    if @state.collections.length == 0
                      <p className="nothing-found">No collections found.</p>
                    else
                      <span>
                        {@state.collections.map @renderCollection}
                        <div className="paginator">
                          <button
                            className="paginator-next"
                            onClick={@getMoreCollections}
                            disabled={@state.collections_all_loaded}>
                            Load more...
                          </button>
                        </div>
                      </span>}
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>
    </div>

module.exports = RecentPage