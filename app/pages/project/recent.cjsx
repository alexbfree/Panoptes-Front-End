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
    @getFirstComments()

  getInitialState: ->
    subject_notes: []
    discussion_posts: []
    subject_notes_page: 1
    discussion_posts_page: 1
    loading: true

  commentParams: (page) ->
    params = sort: '-created_at', page: page
    params.page_size = 20
    params.subject_default = null
    params.section = "project-#{ @props.project.id }"
    params

  getFirstComments: (page = 1) ->
    talkClient.type('comments').get(@commentParams(page)).then (comments) =>
      loading = false
      text_comments = []
      subject_comments = []
      for comment in comments
        if not comment.is_deleted
          if comment.focus_type is "Subject"
            subject_comments.push comment
          else
            text_comments.push comment
      @setState {subject_comments, text_comments, loading}


#  getMoreSubjectComments: (page = 1) ->
#    talkClient.type('comments').get(@commentParams(page)).then (comments) =>
#      loading = false
#      subject_notes = []
#      discussion_posts = []
#      for comment in comments
#        if not comment.is_deleted
#          if comment.focus_type is "Subject"
#            subject_comments.push comment
#          else
#            text_comments.push comment
#      @setState {subject_comments, text_comments, loading}

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
              </div>
              <h1>Subject based posts</h1>
              <div className="talk-discussion-comments">
                {@state.subject_comments.map @renderSubjectComment}
              </div>
            </div>}
        </div>
      </section>
    </div>

module.exports = RecentPage