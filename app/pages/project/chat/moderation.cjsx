React = require 'react'
stingyFirebase = require '../../../lib/stingy-firebase'
FirebaseList = require '../../../components/firebase-list'
Comment = require './comment'

module.exports = React.createClass
  displayName: 'ProjectChatModeration'

  render: ->
    commentsRef = stingyFirebase.child "projects/#{@props.project.id}/comments"

    <div className="content-container">
      <FirebaseList items={commentsRef.orderByChild('flagged').equalTo true}>{(key, comment) =>
        <div key={key}>
          <Comment comment={comment} reference={commentsRef.child key} />
          <button type="button" className="major-button" onClick={@handleUnflag.bind this, key}>Unflag</button>{' '}
          <button type="button" className="dangerous-button" onClick={@handleDelete.bind this, key}>Delete</button>
          <hr />
        </div>
      }</FirebaseList>
    </div>

  handleUnflag: (key) ->
    stingyFirebase.child("projects/#{@props.project.id}/comments/#{key}/flagged").set false

  handleDelete: (key, e) ->
    if e.shiftKey or confirm 'Really delete this comment?'
      stingyFirebase.child("projects/#{@props.project.id}/comments/#{key}").remove()