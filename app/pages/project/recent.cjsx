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

  getMoreTextComments: ->
    text_comments_page = @state.text_comments_page + 1
    text_comments = @state.text_comments
    text_comments_all_loaded = @state.text_comments_all_loaded
    previous_text_comments_length = text_comments.length
    params = @paramsForTextComments(text_comments_page)
    talkClient.type('comments').get(params).then (comments) =>
      meta = comments[0]?.getMeta() or { }
      loading = false
      newTC = 0
      for comment in comments
        if not comment.is_deleted
          if comment.focus_id is ""
            newTC += 1
            text_comments.push comment
      if meta?.next_page is null
        text_comments_all_loaded = true
      @setState {text_comments, text_comments_page, text_comments_all_loaded, loading}
      if text_comments.length == previous_text_comments_length and not text_comments_all_loaded
        # if none of the comments were text comments, go to next page (only if there is one)
        @getMoreTextComments()

  getMoreSubjectComments: ->
    subject_comments_page = @state.subject_comments_page + 1
    params = @paramsForSubjectComments(subject_comments_page)
    subject_comments_all_loaded = @state.subject_comments_all_loaded
    talkClient.type('comments').get(params).then (comments) =>
      loading = false
      subject_comments = @state.subject_comments
      for comment in comments
        if not comment.is_deleted
          subject_comments.push comment
      if meta?.next_page is null
        subject_comments_all_loaded = true
      @setState {subject_comments, subject_comments_page, loading, subject_comments_all_loaded}

  renderSubjectComment: (comment) ->
    <span>
      <PromiseRenderer
        promise={
          apiClient.type('subjects').get(comment.focus_id)
        }
        then={(subject) =>
          <Thumbnail src={getSubjectLocation(subject).src} width={100} />
        }
        catch={null}
        />
      <pre key={comment.id}>Comment {comment.id} at {timestamp(comment.created_at)}
        {if comment.is_reply
          <span>
            {' '}(reply to comment {comment.reply_id})
          </span>}: - {comment.body}
          <span>
            {' '} about Subject {comment.focus_id}
          </span>
      </pre>
    </span>

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
                {if @state.text_comments.length == 0
                  <p className="no-comments-found">No Text based posts found.</p>
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
              <h1>Subject based posts</h1>
              <div className="talk-discussion-comments">
                {if @state.subject_comments.length == 0
                  <p className="no-comments-found">No Subject based posts found.</p>
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
            </div>}
        </div>
      </section>
    </div>

module.exports = RecentPage