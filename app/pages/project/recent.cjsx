counterpart = require 'counterpart'
React = require 'react'
talkClient = require 'panoptes-client/lib/talk-client'
{Link} = require 'react-router'
Translate = require 'react-translate-component'
Comment = require '../../talk/comment'
Loading = require '../../components/loading-indicator'
{timestamp} = require '../../talk/lib/time'

counterpart.registerTranslations 'en',
  recentPage:
    title: 'Recent Updates'

RecentPage = React.createClass
  displayName: 'ProjectRecent'

  componentDidMount: ->
    @getMoreTextComments()
    @getMoreSubjectComments()

  getInitialState: ->
    subject_comments: []
    text_comments: []
    subject_comments_page: 1
    text_comments_page: 1
    text_comments_all_loaded: false
    subject_comments_all_loaded: false
    loading: true

#  paramsForAllComments: (page = 1) ->
#    params = sort: '-created_at', page: page
#    params.page_size = 3
#    params.subject_default = null
#    params.section = "project-#{ @props.project.id }"
#    params

  paramsForSubjectComments: (page = 1) ->
    params = sort: '-created_at', page: page
    params.page_size = 2
    params.focus_type = "Subject"
    params.section = "project-#{ @props.project.id }"
    params

  paramsForTextComments: (page = 1) ->
    params = sort: '-created_at', page: page
    params.page_size = 2
    # TODO add params.focus_id = ""
    params.section = "project-#{ @props.project.id }"
    params

#  getFirstComments: ->
#    talkClient.type('comments').get(@paramsForAllComments(1)).then (comments) =>
#      loading = false
#      text_comments = []
#      subject_comments = []
#      for comment in comments
#        if not comment.is_deleted
#          if comment.focus_type is "Subject"
#            subject_comments.push comment
#          else
#            text_comments.push comment
#      @setState {subject_comments, text_comments, loading}

  getMoreTextComments: ->
    text_comments_page = @state.text_comments_page + 1
    params = @paramsForTextComments(text_comments_page)
    talkClient.type('comments').get(params).then (comments) =>
      loading = false
      text_comments = @state.text_comments
      for comment in comments
        if not comment.is_deleted
          if comment.focus_id is ""
            text_comments.push comment
      if meta?.next_page is null
        text_comments_all_loaded = true
      @setState {text_comments, text_comments_page, text_comments_all_loaded, loading}

  getMoreSubjectComments: ->
    subject_comments_page = @state.subject_comments_page + 1
    params = @paramsForSubjectComments(subject_comments_page)
    talkClient.type('comments').get(params).then (comments) =>
      meta = comments[0]?.getMeta() or { }
      loading = false
      subject_comments = @state.subject_comments
      for comment in comments
        if not comment.is_deleted
          subject_comments.push comment
      if meta?.next_page is null
        subject_comments_all_loaded = true
      @setState {subject_comments, subject_comments_page, loading, subject_comments_all_loaded}

  renderSubjectComment: (comment) ->
    <pre key={comment.id}>Comment {comment.id} at {timestamp(comment.created_at)}
      {if comment.is_reply
        <span>
          {' '}(reply to comment {comment.reply_id})
        </span>}: - {comment.body}
        <span>
          {' '} about Subject {comment.focus_id}
        </span>
    </pre>

  renderTextComment: (comment) ->
    <pre key={comment.id}>Comment {comment.id} at {timestamp(comment.created_at)}
      {if comment.is_reply
        <span>
          {' '}(reply to comment {comment.reply_id})
        </span>}: - {comment.body}
    </pre>

  renderComment: (comment) ->
    if comment.focus_id
      @renderSubjectComment comment
    else
      @renderTextComment comment

  render: ->
    <div className="secondary-page all-resources-page">
      <section className="hero recent-hero">
        <div className="hero-container">
          <Translate component="h1" content={"recentPage.title"} />
        </div>
        <div className="talk-recents">
          <h1 className="talk-page-header">
            Recent Comments {"on #{ @state.boardTitle or @props.project?.display_name}"}
          </h1>
          {if @state.loading
            <Loading />
          else
            <div>
              <h1>Text based posts</h1>
              <div className="talk-discussion-comments">
                {@state.text_comments.map @renderTextComment}
                <div className="paginator">
                  <button
                    className="paginator-next"
                    onClick={@getMoreTextComments}
                    disabled={@state.text_comments_all_loaded}>
                    Load more...
                  </button>
                </div>
              </div>
              <h1>Subject based posts</h1>
              <div className="talk-discussion-comments">
                {@state.subject_comments.map @renderSubjectComment}
                <div className="paginator">
                  <button
                    className="paginator-next"
                    onClick={@getMoreSubjectComments}
                    disabled={@state.subject_comments_all_loaded}>
                    Load more...
                  </button>
                </div>
              </div>
            </div>}
        </div>
      </section>
    </div>

module.exports = RecentPage