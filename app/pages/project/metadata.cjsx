React = require 'react'

module?.exports = React.createClass
  displayName: 'ProjectMetadata'

  getTotalSubjectCountForAllActiveWorkflows: (project) ->
    project.get('workflows', active: true).then (workflows) =>
      count = 0
      if workflows.length > 0
        for workflow in workflows
          count += workflow.subjects_count
      console.log 'Total Active Subjects: ' + count
      count
    project.subjects_count # until we have the accurate value, just display the total existing subjects

  propTypes:
    project: React.PropTypes.object

  render: ->
    {project} = @props

    <div className="project-metadata content-container">
      <div className="project-metadata-header">
        <span>{project.display_name}</span>{' '}
        <span>Statistics</span>
      </div>

      <div className="project-metadata-stats">
        <div className="project-metadata-stat">
          <div>{project.classifiers_count.toLocaleString()}</div>
          <div>Registered Volunteers</div>
        </div>

        <div className="project-metadata-stat">
          <div>{project.classifications_count.toLocaleString()}</div>
          <div>Classifications</div>
        </div>

        <div className="project-metadata-stat">
          <div>{ @getTotalSubjectCountForAllActiveWorkflows(project).toLocaleString() }</div>
          <div>Subjects</div>
        </div>

        <div className="project-metadata-stat">
          <div>{project.retired_subjects_count.toLocaleString()}</div>
          <div>Retired Subjects</div>
        </div>
      </div>
    </div>
