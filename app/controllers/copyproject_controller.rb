class CopyprojectController < ApplicationController

  before_filter :find_project, :authorize, :only =>  :index

  def index
      @issue_custom_fields = IssueCustomField.sorted.to_a
      @trackers = Tracker.sorted.to_a
      @source_project = Project.find(params[:project_id])

      @project = Project.copy_from(@source_project)
      @project.identifier = Project.next_identifier if Setting.sequential_project_identifiers?

      rescue ActiveRecord::RecordNotFound
          render_404
  end

  def copy
    @source_project = Project.find(params[:id])
    if request.post?
      Mailer.with_deliveries(params[:notifications] == '1') do
        @project = Project.new
        @project.safe_attributes = params[:project]

        if @project.copy(@source_project, :only => params[:only])
          flash[:notice] = l(:notice_successful_create)
          redirect_to settings_project_path(@project)
        elsif !@project.new_record?
          # Project was created
          # But some objects were not copied due to validation failures
          # (eg. issues from disabled trackers)
          # TODO: inform about that
          redirect_to settings_project_path(@project)
        end
      end
    end

    rescue ActiveRecord::RecordNotFound
      render_404
  end
end
